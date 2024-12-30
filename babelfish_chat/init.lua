-- babelfish_redo/babelfish_chat/init.lua
-- Translate by writing %<code>
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_chat")

local function check_message(message)
    local _, _, targetlangstr = message:find("%%([a-zA-Z-_:]+)")
    if targetlangstr then
        local targetphrase = message:gsub("%%" .. string.gsub(targetlangstr, '%W', '%%%1'), '', 1)
        local splited = string.split(targetlangstr, ":")

        local new_targetlang = babelfish.validate_language(splited[1])
        local new_sourcelang = splited[2] and babelfish.validate_language(splited[2]) or "auto"

        if not (new_targetlang and new_sourcelang) then
            return false, not new_targetlang and splited[1] or nil, not new_sourcelang and splited[2] or nil
        end
        return targetphrase, new_targetlang, new_sourcelang
    end
    return false
end

local dosend
local function process(name, message, arg1)
    local targetphrase, targetlang, sourcelang = check_message(message)
    if not targetphrase then
        if targetlang then
            core.chat_send_player(name, S("@1 is not a valid language.", targetlang))
        end
        if sourcelang then
            core.chat_send_player(name, S("@1 is not a valid language.", sourcelang))
        end
        return
    end
    return babelfish.translate(sourcelang, targetlang, targetphrase, function(succeed, translated, detected_sourcelang)
        if not succeed then
            if core.get_player_by_name(name) then
                return core.chat_send_player(name, S("Could not translate message: @1", translated))
            end
            return
        end

        return dosend(name, translated, detected_sourcelang or sourcelang, targetlang, arg1)
    end)
end

local format_base
babelfish.register_on_engine_ready(function()
    format_base = "[" .. babelfish.get_engine_label() .. " %s -> %s]: %s"
end)

local function do_bb(name, param, sendfunc)
    local args = string.split(param, " ", false, 1)
    if not args[2] then
        return false
    end
    local langs, message = string.split(args[1], ":"), args[2]
    local sourcelang = langs[2] and babelfish.validate_language(langs[2]) or "auto"
    local targetlang = babelfish.validate_language(langs[1])
    if not targetlang or targetlang == "auto" then
        return false, S("@1 is not a valid language.", langs[1])
    elseif not sourcelang then
        return false, S("@1 is not a valid language.", langs[2])
    end
    babelfish.translate(sourcelang, targetlang, message,
        function(succeed, translated, detected_sourcelang)
            if not succeed then
                if core.get_player_by_name(name) then
                    return core.chat_send_player(name, S("Could not translate message: @1", translated))
                end
                return
            end

            return sendfunc(name, translated, detected_sourcelang or sourcelang, targetlang)
        end)
    return true
end

if core.global_exists("beerchat") then
    dosend = function(name, translated, sourcelang, targetlang, channel)
        return beerchat.send_on_channel({
            name = name,
            channel = channel,
            message = string.format(format_base, sourcelang, targetlang, translated),
            _supress_babelfish_redo = true,
        })
    end
    beerchat.register_callback("before_send_on_channel", function(name, msg)
        if msg._supress_babelfish_redo then return end
        local message = msg.message

        return process(name, message, msg.channel)
    end)

    core.register_chatcommand("bb", {
        description = S("Translate a sentence and transmit it to everybody, or to the given channel"),
        params = S("[#<channel>] <language code>[:<source language>] <sentence>"),
        privs = { shout = true },
        func = function(name, param)
            local args = string.split(param, " " , false, 1)
            if not args[2] then return false end
            local channel
            if string.sub(args[1], 1, 1) == "#" then
                param = args[2]
                channel = string.sub(args[1], 2)
                if not beerchat.is_player_subscribed_to_channel(name, channel) then
                    return false, S("You cannot send to channel #@1!", channel)
                end
            else
                channel = beerchat.get_player_channel(name)
                if not channel then
                    beerchat.fix_player_channel(name, true)
                    return false
                end
            end
            return do_bb(name, param, function(_, translated, sourcelang, targetlang)
                return dosend(name, translated, sourcelang, targetlang, channel)
            end)
        end,
    })
else
    dosend = function(name, translated, sourcelang, targetlang)
        return core.chat_send_all(core.format_chat_message(name,
            string.format(format_base, sourcelang, targetlang, translated)))
    end
    core.register_on_chat_message(process)

    core.register_chatcommand("bb", {
        description = S("Translate a sentence and transmit it to everybody"),
        params = S("<language code>[:<source language>] <sentence>"),
        privs = { shout = true },
        func = function(name, param)
            return do_bb(name, param, dosend)
        end,
    })
end

if core.global_exists("random_messages_api") then
    random_messages_api.register_message(
        S("Add %<language code> in your chat message to translate it into another language."))
end
