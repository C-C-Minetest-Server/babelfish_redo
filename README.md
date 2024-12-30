# BabelFish... but done in another way

This mod allows Luanti players to communicate across language barriers.

## ... but why not the original BabalFish mod?

[BabelFish](https://github.com/taikedz-mt/babelfish) was (and if you aren't a developer, still is) a great mod for breaking langauge barrier between players speaking different languages. However, it was unmaintained for 7 years, and many code became messy and inefficient. This rewrite is a drop-in replacement for most end users, and provides more method for developers to interact with BabelFish. Notable changes include:

* Guessing preferred language from the player's client language code
* Allow specifying source language in translations
* Handles [Beerchat](https://content.luanti.org/packages/mt-mods/beerchat/) properly
* Shipped with [Lingva Translate](https://github.com/thedaviddelta/lingva-translate) support (Yandex Translate port will be avaliable soon)
* Register new translation engine with new mods instead of adding files into the core mod

## How to use? (as an end-user)

Avaliable in `babelfish_core` mod:

* Use `/bbcodes` to list all avaliable languages and their alias.

Avaliable in `babelfish_chat` mod:

* Write `%<language code>:[<source language>]` in a message to boardcast translation to other players
    * e.g. "Hello %fr" would yield "Bonjour"
    * Specifying source language may be userful in translating shorter phrases, e.g. "Ja %en" would yield "And" (Estonian), but "Ja %en:de" would yield "Yes" (German).
    * Unlike the original BabelFish, you must leave spaces between the tag and other texts.
* Use `/bb <language code>[:<source language>] <sentence>` to send a message in another language.
    * (Beerchat only) Use `/bb #<channel> (other arguments...)` to send to a channel.

Avaliable in `babelfish_preferred_langauge` mod:

* Your preferred language is guessed when you first join the server.
    * Fallbacks to English if your language is not supported.
* Use `/bblang <language code>` to set your preferred language.
* Use `/bbget` to check your preferred language.
* Use `/bbget <player name>` to check other's preferred language
* (Moderators only) Use `/bbset <player name> <language code>` to set other's preferred language

Avaliable in `babelfish_chat_history` mod:

* Use `/babel <username>` to translate the last message sent by a user
* (Beerchat only) Use `/babel <username> <channel>` to translate the last message sent by a user on a channel
    * If channel is unspecified, defaults to the executer's channel.

Avaliable in `babelfish_private_chat`

* User `/bmsg <username> <message>` to send private messages to a player in their preferred language.

## How to set up? (as a server maintainer)

To start, you must enable the following mods:

* `babelfish_core`
* Any BabelFish Redo translation engines (e.g. `babelfish_engine_lingva`)
    * Check their `README.md` for installation instructions. Most backends requires adding them to `secure.http_mods`.

To enable all features the original BabelFish have, enable the following mods:

* `babelfish_chat`: Translate using `%<code>` shortcuts
* `babelfish_preferred_langauge`: Detect and set preferred languages
* `babelfish_chat_history`: Use `/babel` to translate chat history
* `babelfish_private_chat`: Use `/bmsg` to send private messages in the receiver's preferred language

You may want to run `/bbmigrate` to import old preferred languages. Use `/bbmigrate override` to override data collected under this new mod.

## How to develop my mods? (as a developer)

Check out API.md for how to use BabelFish Redo in your mod.
