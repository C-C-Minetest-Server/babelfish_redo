-- babelfish_redo/babelfish_core/init.lua
-- High leve API for translating texts using one of the Babelfish enginess
-- Copyright (C) 2016  Tai "DuCake" Kedzierski
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = core.get_translator("babelfish_core")

babelfish = {}

local registered_on_engine_ready = {}

---Run function when the engine is ready, or if it is already ready, run it now.
---@param func fun()
function babelfish.register_on_engine_ready(func)
    registered_on_engine_ready[#registered_on_engine_ready+1] = func
end

---@alias BabelFishCallback fun(succeed: boolean, string_or_err: string, detected_lang: string?)

---@class (exact) BabelFishEngine
---@field translate fun(source: string, target: string, query: string, callback: BabelFishCallback)
---@field language_codes { [string]: string }
---@field language_alias { [string]: string }?
---@field mt_language_map { [string] : string }?
---@field compliance string?
---@field engine_label string?
local babelfish_engine

---Register a translate engine
---@param engine_def BabelFishEngine
function babelfish.register_engine(engine_def)
    local mod_name = core.get_current_modname() or "??"
    assert(type(engine_def) == "table",
        "Invalid `engine_def` type (expected table, got " .. type(engine_def) .. ")")
    assert(type(engine_def.translate) == "function",
        "Invalid `engine_def.translate` type (expected function, got " .. type(engine_def.translate) .. ")")
    assert(type(engine_def.language_codes) == "table",
        "Invalid `engine_def.language_codes` type (expected table, got " .. type(engine_def.language_codes) .. ")")
    if engine_def.language_alias == nil then
        engine_def.language_alias = {}
    else
        assert(type(engine_def.language_alias) == "table",
            "Invalid `engine_def.language_alias` type (expected table or nil, got "
            .. type(engine_def.language_alias) .. ")")
    end
    if engine_def.mt_language_map == nil then
        engine_def.mt_language_map = {}
    else
        assert(type(engine_def.mt_language_map) == "table",
            "Invalid `engine_def.mt_language_map` type (expected table or nil, got "
            .. type(engine_def.mt_language_map) .. ")")
    end
    if engine_def.engine_label == nil then
        engine_def.engine_label = mod_name
    else
        assert(type(engine_def.engine_label) == "string",
            "Invalid `engine_def.engine_label` type (expected string or nil, got "
            .. type(engine_def.engine_label) .. ")")
    end
    if engine_def.compliance == nil then
        engine_def.compliance = S("Translations are powered by @1", engine_def.engine_label)
    else
        assert(type(engine_def.compliance) == "string",
            "Invalid `engine_def.compliance` type (expected string or nil, got "
            .. type(engine_def.compliance) .. ")")
    end

    engine_def.mod_name = mod_name
    babelfish_engine = engine_def
    babelfish.register_engine = function()
        return error("[babelfish_core] Attempt to registered more than one BabelFish engine "
            .. "(already registered by " .. engine_def.mod_name .. ")")
    end

    for _, func in ipairs(registered_on_engine_ready) do
        func()
    end
    babelfish.register_on_engine_ready = function(func) return func() end
    registered_on_engine_ready = nil
end

core.register_on_mods_loaded(function()
    if not babelfish_engine then
        return error("[babelfish_core] Please enable one (and only one) BabelFish engine mod.")
    end
end)

---Translate a given text
---@param source string Source language code. If `"auto"`, detect the language automatically.
---@param target string Target language code.
---@param query string String to translate.
---@param callback BabelFishCallback Callback to run after finishing (or failing) a request
function babelfish.translate(source, target, query, callback)
    assert(type(source) == "string",
        "Invalid `source` type (expected string or nil, got " .. type(source) .. ")")
    assert(type(target) == "string",
        "Invalid `target` type (expected string, got " .. type(target) .. ")")
    assert(type(query) == "string",
        "Invalid `query` type (expected string, got " .. type(query) .. ")")

    assert(source == "auto" or babelfish_engine.language_codes[source],
        "Attempt to translate from unsupported language " .. source)

    assert(babelfish_engine.language_codes[target],
        "Attempt to translate from unsupported language " .. target)

    return babelfish_engine.translate(source, target, query, callback)
end

---Check whether a given language code is valid, and resolve any alias
---@param language string?
---@return string
---@nodiscard
function babelfish.validate_language(language)
    if language == nil then
        return "auto"
    end
    language = babelfish_engine.language_alias[language] or language
    return babelfish_engine.language_codes[language] and language or nil
end

---Get name of a language
---@param language string
---@return string?
function babelfish.get_language_name(language)
    if language == "auto" then
        return S("Detect automatically")
    end
    return babelfish_engine.language_codes[language]
end

---Get language codes
---@return { [string]: string }
function babelfish.get_language_codes()
    return table.copy(babelfish_engine.language_codes)
end


---Get language map: MT language code -> engine lanaguage code
---@return { [string]: string }
function babelfish.get_mt_language_map()
    return table.copy(babelfish_engine.mt_language_map)
end

---Get engine compliance
---@return string
function babelfish.get_compliance()
    return babelfish_engine.compliance
end

---Get engine engine_label
---@return string
function babelfish.get_engine_label()
    return babelfish_engine.engine_label
end

core.register_chatcommand("bbcodes", {
    description = S("List avaliable language codes"),
    func = function ()
        local lines = {}
        for code, name in pairs(babelfish_engine.language_codes) do
            lines[#lines+1] = code .. ": " .. name
            local alias = {}
            for src, dst in pairs(babelfish_engine.language_alias) do
                if dst == code then
                    alias[#alias+1] = src
                end
            end
            if #alias ~= 0 then
                lines[#lines] = lines[#lines] .. " " .. S("(Alias: @1)", table.concat(alias, ", "))
            end
        end
        return true, table.concat(lines, "\n")
    end
})

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()

    core.chat_send_player(name, babelfish_engine.compliance)
end)
