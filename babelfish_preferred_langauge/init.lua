-- babelfish_redo/babelfish_preferred_language/init.lua
-- Set and get player preferred languages
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: AGPL-3.0-or-later

local S = core.get_translator("babelfish_preferred_language")

local language_map
local fallback_lang
babelfish.register_on_engine_ready(function()
    language_map = babelfish.get_mt_language_map()

    local settings_fallback_lang = core.settings:get("babelfish_preferred_language.fallback_lang")
    fallback_lang = babelfish.validate_language(settings_fallback_lang)
    if not fallback_lang or fallback_lang == "auto" then
        core.log("error", "Invalid fallback language, using en")
        fallback_lang = "en" -- out last hope
    end
end)

---Guess the player's preferred language from player information
---@param name string
---@return string
function babelfish.guess_player_preferred_language(name)
    local player_info = core.get_player_information(name)
    if not player_info then return fallback_lang end

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
---@return string
function babelfish.get_player_preferred_language(name)
    local player = core.get_player_by_name(name)
    if not player then return end

    local meta = player:get_meta()
    local preferred_language = meta:get_string("babelfish:preferred_language")
    preferred_language = babelfish.validate_language(preferred_language)

    if not preferred_language or preferred_language == "auto" then
        preferred_language = babelfish.guess_player_preferred_language(name)
        if not preferred_language then return end
        meta:set_string("babelfish:preferred_language", preferred_language)
    end

    return preferred_language
end

---Set a player's preferred language
---@param name string
---@param lang string
function babelfish.set_player_preferred_languag(name, lang)
    local player = core.get_player_by_name(name)
    if not player then return end

    local meta = player:get_meta()
    return meta:set_string("babelfish:preferred_language", lang)
end

core.register_on_joinplayer(function(player)
    -- Beautiful hack to update or generate preferred language
    return babelfish.get_player_preferred_language(player:get_player_name())
end)

core.register_chatcommand("bblang", {
    descriptio = S("Get or set preferred language"),
    params = S("[<language code>]"),
    func = function(name, param)
        if param == "" then
            local lang = babelfish.get_player_preferred_language(name)
            return true, S("Preferred language: @1", lang and babelfish.get_language_name(lang) or S("Unknown"))
        end

        local lang = babelfish.validate_language(param)
        if not lang or lang == "auto" then
            return false, S("Invalid language code: @1", param)
        end

        local player = core.get_player_by_name(name)
        if not player then
            return false, S("You must be online to run this command.")
        end

        babelfish.set_player_preferred_languag(name, lang)
        return true, S("Preferred language set to @1.", babelfish.get_language_name(lang))
    end,
})
