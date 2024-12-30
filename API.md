# BabelFish Redo API

## Ensure engine init

You can assume the existance of a BabelFish translation engine only:

* In functions wrapped in `babelfish.register_on_engine_ready`; or
* In server step (i.e. not starting up).

For example, to get a copy of the language map, you should do:

```lua
local language_map
babelfish.register_on_engine_ready(function()
    language_map = babelfish.get_mt_language_map()
end)
```

Though you can safely do this, as the function would only be called in server step:

```lua
core.register_on_joinplayer(function(player)
    babelfish.get_player_preferred_language(player:get_player_name())
end)
```

## Engine Registeration

Use `babelfish.register_engine` to register a translation engine.

```lua
babelfish.register_engine({
    -- Function to translate a given text.
    -- If source == "auto", detect the source language automatically.
    -- callback: fun(succeeded, translated or error, detected language?)
    translate = function(source, target, query, callback) end,

    -- Table of language codes to human-readable names.
    language_codes = {
        -- Example data, error if not given
        en = "English",
        zh = "Chinese",
    },

    -- Table of alternative language codes to the code used by translate()
    language_alias = {
        -- Example data, default: {}
        ["zh-hans"] = "zh",
    },

    -- Table of gettext language codes to the code used by translate()
    -- Used to guess new player's preferred language
    -- If a gettext language is not found, the engine searches whether there is a
    -- supported language with the same code.
    mt_language_map = {
        -- Example data, default: {}
        ["zh-CN"] = "zh",
    },

    -- String showed to describe this translation engine when player joins
    -- Default to localized "Translations are powered by {engine_label}"
    compliance = S("Translations are powered by Lingva"),

    -- Label added to every translated message
    -- Default to mod name
    engine_label = "Lingva Translate",
})
```

## `babelfish_core` references

* `babelfish.translate(source, target, query, callback)`: Translate a given text
    * `source`: `string`, if `"auto"`, detect the source language automatically
    * `target`: `string`, any valid languages except `"auto"`.
    * `query`: `string`, the string to be translated.
    * `callback`: `function`, check [Engine Registeration](#engine-registeration) for more details
* `babelfish.validate_language(language)`: Validate a language code, and resolve any alias
    * `language`: `string?`, if `nil`, returns `"auto"`
    * If the given language code is invalid, return `nil`.
* `babelfish.get_language_name(language)`: Get name of a language code
* `babelfish.get_language_codes()`: Get a copy of the list of language codes
* `babelfish.get_mt_language_map()`: Get a copy of the list of gettext language mappings
* `babelfish.get_compliance()`: Get compliance string
* `babelfish.get_engine_label()`: Get engine label

## `babelfish_preferred_language` references

* `babelfish.guess_player_preferred_language(name)`: Guess the player's preferred language from player information
* `babelfish.get_player_preferred_language(name)`: Get a player's preferred language
    * If one is not set or is invalid, a new one will be guessed. If the guess failed, return `nil`.
* `babelfish.set_player_preferred_language(name, lang)`: Set a player's preferred language
    * No validation happens inside this function, so you should run `babelfish.validate_language` beforehand.
