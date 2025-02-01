-- babelfish_redo/babelfish_chat_history/init.lua
-- Translate messages in chat history
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_chat_history")

---@type { [string]: { [string]: string } }
local chat_history = {}

local main_channel = "main"

local function record_message(name, channel, message)
    if not chat_history[channel] then
        chat_history[channel] = {}
    end

    chat_history[channel][name] = message
end

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    for channel, chn_data in pairs(chat_history) do
        chn_data[name] = nil
        if channel ~= main_channel and not next(chn_data) then
            chat_history[channel] = nil
        end
    end
end)

local format_base
babelfish.register_on_engine_ready(function()
    format_base = "[" .. babelfish.get_engine_label() .. " %s -> %s]: %s"
end)

local get_channel
local cmd_param
local is_player_subscribed_to_channel
local format_message

if core.global_exists("beerchat") then
    main_channel = beerchat.main_channel_name
    do
        local send_on_channel = beerchat.send_on_channel
        function beerchat.send_on_channel(msg, ...) -- luacheck: ignore
            if type(msg) ~= "table" then
                local arg = {...}
                msg = {name=msg, channel=arg[1], message=arg[2]}
            end
            msg._babelfish_raw_message = msg.message
            return send_on_channel(msg)
        end
    end
    beerchat.register_callback("before_send_on_channel", function(name, msg)
        record_message(name, msg.channel, msg._babelfish_raw_message or msg.message)
    end)
    cmd_param = S("<player name> [<channel name>]")
    get_channel = function(name)
        local channel = beerchat.get_player_channel(name)
        if channel then
            return channel
        else
            return beerchat.fix_player_channel(name, true)
        end
    end
    is_player_subscribed_to_channel = beerchat.is_player_subscribed_to_channel
    format_message = function(name, source, lang, translated, channel)
        local tmessage = string.format(format_base, source, lang, translated)
        do
            local data = {
                channel = channel,
                name = name,
                message = tmessage
            }
            beerchat.execute_callbacks("before_send", tname, tmessage, data)
            tmessage = data.message or tmessage
        end
        return tmessage
    end

else
    core.register_on_chat_message(function(name, message)
        record_message(name, main_channel, message)
    end)
    cmd_param = S("<player name>")
    get_channel = function() return main_channel end
    is_player_subscribed_to_channel = function(_, channel) return channel == main_channel end
    format_message = function(name, source, lang, translated)
        return core.format_chat_message(name, string.format(format_base, source, lang, translated))
    end
end

core.register_chatcommand("babel", {
    description = S("Translate last message sent by a player"),
    params = cmd_param,
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("You must be online to run this command.")
        end

        local target_lang = babelfish.get_player_preferred_language(name)
        if not target_lang then
            return false, S("Error while obtaining default language.")
        end

        local args = string.split(param, " ")
        if not args[1] then
            return false
        end

        local target_player, channel = args[1], args[2] or get_channel(name)
        if not channel then
            return false, S("Failed to get channel.")
        end

        if not is_player_subscribed_to_channel(name, channel) then
            return false, S("You are not allowed to read messages from channel #@1!", channel)
        end

        if not (chat_history[channel] and chat_history[channel][target_player]) then
            return false, S("@1 haven't sent anything on @2.",
                target_player, channel == main_channel and S("the main channel") or ("#" .. channel))
        end

        local message = chat_history[channel][target_player]
        local source_lang = "auto"
        message = " " .. message .. " "
        local _, _, language_string = string.find(message, "%s%%([a-zA-Z-_:,]+)%s")
        if language_string then
            message = message:gsub("%%" .. string.gsub(language_string, '%W', '%%%1'), '', 1)
            local status, source = babelfish.parse_language_string(language_string)
            if status then
                source_lang = source
            end
        end
        message = string.trim(message)

        babelfish.translate(source_lang, target_lang, message, function(succeeded, translated, detected)
            if not core.get_player_by_name(name) then return end

            if not succeeded then
                return core.chat_send_player(name, S("Failed to get translation: @1", translated))
            end

            return core.chat_send_player(name,
                format_message(target_player, detected or source_lang, target_lang, translated, channel))
        end)
        return true
    end,
})

if core.global_exists("random_messages_api") then
    random_messages_api.register_message(
        S("Use /babel <player name> to translate a player's last message into your preferred language."))
end
