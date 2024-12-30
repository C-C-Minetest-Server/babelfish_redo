-- babelfish_redo/babelfish_chat_history/init.lua
-- Translate messages in chat history
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: AGPL-3.0-or-later

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

local get_channel
local cmd_param
local is_player_subscribed_to_channel

if core.global_exists("beerchat") then
    main_channel = beerchat.main_channel_name
    beerchat.register_callback("on_send_on_channel", function(name, msg)
        record_message(name, msg.channel, msg.message)
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
else
    core.register_on_chat_message(function(name, message)
        record_message(name, main_channel, message)
    end)
    cmd_param = S("<player name>")
    get_channel = function() return main_channel end
    is_player_subscribed_to_channel = function() return true end
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

        local target_player, channel = args[2], args[3] or get_channel(name)
        if not channel then
            return false, S("Failed to get channel.")
        end

        if not is_player_subscribed_to_channel(name, channel) then
            return false, S("You are not allowed to read messages from channel #@1!", channel)
        end

        if not (chat_history[channel] and chat_history[channel][target_player]) then
            return false, S("@1 haven't sent anythign on @2.",
                target_player, channel == main_channel and S("the main channel") or ("#" .. channel))
        end

        babelfish.translate("auto", target_lang, chat_history[channel][target_player], function(succeeded, translated)
            if not core.get_player_by_name(name) then return end

            if not succeeded then
                return core.chat_send_player(name, S("Failed to get translation: @1", translated))
            end

            return core.chat_send_player(name,
                "[" .. babelfish.get_engine_label() .. " #" .. channel .. " " .. target_player .. "]: " .. translated)
        end)
        return true
    end,
})

if core.global_exists("random_messages_api") then
    random_messages_api.register_message(
        S("Use /babel <player name> to translate a player's last message into your preferred language."))
end
