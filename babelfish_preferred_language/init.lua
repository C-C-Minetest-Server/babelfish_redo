-- babelfish_redo/babelfish_preferred_language/init.lua
-- Set and get player preferred languages
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_preferred_language")
local storage = core.get_mod_storage()

local language_map
local fallback_lang
babelfish.register_on_engine_ready(function()
    language_map = babelfish.get_mt_language_map()

    local settings_fallback_lang = core.settings:get("babelfish_preferred_language.fallback_lang")
    if settings_fallback_lang == nil then
        settings_fallback_lang = "en"
    end
    fallback_lang = babelfish.validate_language(settings_fallback_lang)
    if not fallback_lang or fallback_lang == "auto" then
        fallback_lang = "en" -- out last hope
        return core.log("warning", "Invalid fallback language, using en")
    end
end)

---Guess the player's preferred language from player information
---@param name string
---@return string?
function babelfish.guess_player_preferred_language(name)
    local player_info = core.get_player_information(name)
    if not player_info then return end -- Don't make a guess

    local lang_code = player_info.lang_code
    lang_code = language_map[lang_code] or lang_code
    lang_code = babelfish.validate_language(lang_code)

    if not lang_code or lang_code == "auto" then
        return fallback_lang
    end
    return lang_code
end

---Get a player's preferred lanaguage
---@param name string
---@return string?
function babelfish.get_player_preferred_language(name)
    local preferred_language = storage:get_string("preferred_language:" .. name)
    preferred_language = babelfish.validate_language(preferred_language)

    if not preferred_language or preferred_language == "auto" then
        preferred_language = babelfish.guess_player_preferred_language(name)
        if not preferred_language then return end
        core.log("action", "[babelfish_preferred_language] Guessed preferred language of " .. name
            .. ": " .. preferred_language)
        storage:set_string("preferred_language:" .. name, preferred_language)
    end

    return preferred_language
end

---Set a player's preferred language
---@param name string
---@param lang string
function babelfish.set_player_preferred_language(name, lang)
    return storage:set_string("preferred_language:" .. name, lang)
end

core.register_on_joinplayer(function(player)
    babelfish.get_player_preferred_language(player:get_player_name())
end)

core.register_chatcommand("bblang", {
    description = S("Get or set your preferred language"),
    params = S("[<language code>]"),
    func = function(name, param)
        if param == "" then
            local lang = babelfish.get_player_preferred_language(name)
            return true, S("Preferred language: @1",
                lang and (babelfish.get_language_name(lang) .. " (" .. lang .. ")") or S("Unknown"))
        end

        local lang = babelfish.validate_language(param)
        if not lang or lang == "auto" then
            return false, S("Invalid language code: @1", param)
        end

        babelfish.set_player_preferred_language(name, lang)
        return true, S("Preferred language set to @1.",
            babelfish.get_language_name(lang) .. " (" .. lang .. ")")
    end,
})

core.register_chatcommand("bbget", {
    description = S("Get a player's preferred language"),
    params = S("[<player name>]"),
    func = function(name, param)
        if param == "" then
            param = name
        end

        local lang = babelfish.get_player_preferred_language(param)
        return true, S("Preferred language of @1: @2",
            param, lang and (babelfish.get_language_name(lang) .. " (" .. lang .. ")") or S("Unknown"))
    end
})

core.register_chatcommand("bbset", {
    description = S("Set a player's preferred language"),
    params = S("<player name> <language code>"),
    privs = { ban = true },
    func = function(_, param)
        local args = string.split(param, " ")
        if not args[1] then return false end

        local target, lang = args[1], args[2]

        if not lang then
            return false
        end

        lang = babelfish.validate_language(lang)
        if not lang or lang == "auto" then
            return false, S("Invalid language code: @1", args[2])
        end

        babelfish.set_player_preferred_language(target, lang)
        return true, S("Preferred language of @1 set to @2.",
            target, babelfish.get_language_name(lang) .. " (" .. lang .. ")")
    end,
})

core.register_chatcommand("bbmigrate", {
    description = S("Import preferred language data from old BabelFish"),
    params = "[override]",
    privs = { server = true },
    func = function(_, param)
        local file, err = io.open(core.get_worldpath() .. "/babel_langprefs", "r")
        if not file then
            return false, S("Error while opening old savefile: @1", err)
        end

        local player_pref_language = core.deserialize(file:read("*a")) or {}
        file:close()

        for name, lang in pairs(player_pref_language) do
            if param == "override" or storage:get_string("preferred_language:" .. name) == "" then
                lang = babelfish.validate_language(lang)
                if lang then
                    babelfish.set_player_preferred_language(name, lang)
                end
            end
        end

        return true, S("Successfully imported old savefile.")
    end,
})

if core.global_exists("random_messages_api") then
    random_messages_api.register_message(
        S("Use /bblang <language code> to set your preferred language."))
end
