-- babelfish_redo/babelfish_chat/init.lua
-- Translate by writing %<code>
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_chat")

local format_base
babelfish.register_on_engine_ready(function()
    format_base = "[" .. babelfish.get_engine_label() .. " %s -> %s]: %s"
end)

local parse_language_string = babelfish.parse_language_string

local dosend
local function process(name, message, channel)
    message = " " .. message .. " "
    local _, _, language_string = string.find(message, "%s%%([a-zA-Z-_:,]+)%s")
    local targetlangs, source = {}, "auto"
    local targetphrase = message
    if language_string then
        targetphrase = message:gsub("%%" .. string.gsub(language_string, '%W', '%%%1'), '', 1):trim()
        targetlangs, source = parse_language_string(language_string)
        if not targetlangs then
            return core.chat_send_player(name, source)
        end

        for _, targetlang in ipairs(targetlangs) do
            babelfish.translate(source, targetlang, targetphrase,
                function(succeed, translated, detected_sourcelang)
                    if not succeed then
                        if core.get_player_by_name(name) then
                            return core.chat_send_player(name, S("Could not translate message: @1", translated))
                        end
                        return
                    end

                    return dosend(name, translated, detected_sourcelang or source, targetlang, channel)
                end)
        end
    end

    if babelfish.get_player_preferred_language then
        local targets = {}

        for _, player in ipairs(core.get_connected_players()) do
            if player:get_player_name() ~= name
                and player:get_meta():get_int("babelfish:disable_active_translation") == 0 then
                local lang = babelfish.get_player_preferred_language(player:get_player_name())
                if lang and table.indexof(targetlangs, lang) == -1 then
                    targets[lang] = targets[lang] or {}
                    table.insert(targets[lang], player:get_player_name())
                end
            end
        end

        for lang, players in pairs(targets) do
            babelfish.translate(source, lang, targetphrase, function(succeed, translated, detected)
                if not succeed or detected == lang or targetphrase == translated then
                    return
                end

                for _, tname in ipairs(players) do
                    if core.get_player_by_name(tname) then
                        local tmessage = string.format(format_base, detected or source, lang, translated)
                        if channel then
                            local data = {
                                channel = channel,
                                name = name,
                                message = tmessage
                            }
                            beerchat.execute_callbacks("before_send", tname, tmessage, data)
                            tmessage = data.message or tmessage
                        else
                            tmessage = core.format_chat_message(name, tmessage)
                        end
                        core.chat_send_player(tname, tmessage)
                    end
                end
            end)
        end
    end
end

local function do_bb(name, param, sendfunc)
    local args = string.split(param, " ", false, 1)
    if not args[2] then
        return false
    end

    local targetlangs, sourcelang = parse_language_string(args[1])
    if not targetlangs then
        return false, sourcelang
    end

    for _, targetlang in ipairs(targetlangs) do
        babelfish.translate(sourcelang, targetlang, args[2],
            function(succeed, translated, detected_sourcelang)
                if not succeed then
                    if core.get_player_by_name(name) then
                        return core.chat_send_player(name, S("Could not translate message from @1 to @2: @3",
                            sourcelang, targetlang, translated))
                    end
                    return
                end

                return sendfunc(name, translated, detected_sourcelang or sourcelang, targetlang)
            end)
    end
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
            local args = string.split(param, " ", false, 1)
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

if babelfish.get_player_preferred_language then
    core.register_chatcommand("bbactive", {
        description = S("Toggle active translation"),
        func = function(name)
            local player = core.get_player_by_name(name)
            if not player then
                return false, S("You must be online to run this command.")
            end

            local meta = player:get_meta()
            local value = meta:get_int("babelfish:disable_active_translation") == 0 and 1 or 0
            meta:set_int("babelfish:disable_active_translation", value)
            return true, value == 1 and S("Active translation disabled.") or S("Active translation enabled.")
        end,
    })
end
