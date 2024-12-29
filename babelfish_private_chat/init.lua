-- babelfish_redo/babelfish_private_chat/init.lua
-- Translate private chats
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: AGPL-3.0-or-later

local S = core.get_translator("babelfish_private_chat")

core.register_chatcommand("bbmsg", {
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
        local target_lang = babelfish.get_player_preferred_language(sendto)
        babelfish.translate("auto", target_lang, message, function(succeeded, translated)
            if not succeeded then
                if core.get_player_by_name(name) then
                    return core.chat_send_player(name, S("Failed to get translation."))
                end
                return
            end

            core.log("action", "DM from " .. name .. " to " .. sendto
                .. ": " .. translated)
            core.chat_send_player(sendto, core.translate("__builtin", "DM from @1: @2",
                name, "[" .. babelfish.get_engine_label() .. "]: " .. translated))
        end)

        return true, core.translate("__builtin", "Message sent.")
    end,
})
