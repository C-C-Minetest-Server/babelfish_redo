-- babelfish_redo/babelfish_chat/init.lua
-- Translate by writing %<code>
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: AGPL-3.0-or-later

local S = core.get_translator("babelfish_chat")

local function check_message(message)
    local _, _, targetlang = message:find("%%([a-zA-Z-_]+)")
    if targetlang then
        local targetphrase = message:gsub("%%" .. targetlang, '', 1)
        local new_targetlang = babelfish.validate_language(targetlang)

        if not new_targetlang then
            return false, targetlang
        end
        return new_targetlang, targetphrase
    end
    return false
end

local dosend
local function process(name, message, arg1)
    local targetlang, targetphrase = check_message(message)
    if not targetlang then
        if targetphrase == 1 then
            return core.chat_send_player(name, S("@1 is not a valid language.", targetphrase))
        end
        return
    end
    babelfish.translate("auto", targetlang, targetphrase, function(succeed, translated)
        if not succeed then
            if core.get_player_by_name(name) then
                return core.chat_send_player(name, S("Could not translate message: @1", translated))
            end
            return
        end

        return dosend(name, translated, arg1)
    end)
end

if core.global_exists("beerchat") then
    dosend = function(name, translated, channel)
        return beerchat.send_on_channel({
            name = name,
            channel = channel,
            message = "[" .. babelfish.get_engine_label() .. "]: " .. translated,
            _supress_babelfish_redo = true,
        })
    end
    beerchat.register_callback("before_send_on_channel", function(name, msg)
        if msg._supress_babelfish_redo then return end
        local message = msg.message

        return process(name, message, msg.channel)
    end)
else
    dosend = function(name, translated)
        return core.chat_send_all(core.format_chat_message(name,
            "[" .. babelfish.get_engine_label() .. "]: " .. translated))
    end
    core.register_on_chat_message(process)
end
