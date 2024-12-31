-- babelfish_redo/babelfish_private_chat/init.lua
-- Translate private chats
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_private_chat")

local format_base
babelfish.register_on_engine_ready(function()
    format_base = "[" .. babelfish.get_engine_label() .. " %s -> %s]: %s"
end)

core.register_chatcommand("bmsg", {
    params = core.translate("__builtin", "<name> <message>"),
    description = S("Send a direct message to a player in their preferred langauge"),
    privs = { shout = true },
    func = function(name, param)
        local sendto, message = param:match("^(%S+)%s(.+)$")
        if not sendto then
            return false
        end
        if not core.get_player_by_name(sendto) then
            return false, core.translate("__builtin", "The player @1 is not online.", sendto)
        end
        local targetlang = babelfish.get_player_preferred_language(sendto)
        if not targetlang then
            return false, S("Failed to get @1's preferred languages.", sendto)
        end

        core.chat_send_player(sendto, core.translate("__builtin", "DM from @1: @2",
            name, message .. " %" .. targetlang))
        core.chat_send_player(name, S("DM to @1: @2",
            sendto, message .. " %" .. targetlang))

        babelfish.translate("auto", targetlang, message, function(succeeded, translated, sourcelang)
            if not succeeded then
                if core.get_player_by_name(name) then
                    return core.chat_send_player(name, S("Failed to get translation."))
                end
                return
            end

            local formatted = string.format(format_base, sourcelang or "?", targetlang, translated)

            core.log("action", "DM from " .. name .. " to " .. sendto
                .. ": " .. translated)
            if core.get_player_by_name(sendto) then
                core.chat_send_player(sendto, core.translate("__builtin", "DM from @1: @2", name, formatted))
                if core.get_player_by_name(name) then
                    core.chat_send_player(name, S("DM to @1: @2", sendto, formatted))
                end
            end
        end)

        return true
    end,
})

if core.global_exists("random_messages_api") then
    random_messages_api.register_message(
        S("Use /bmsg <name> <message> to sent private message to a player in their preferred language."))
end
