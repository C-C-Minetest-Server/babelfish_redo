# BabelFish... but done in another way

This mod allows Luanti players to communicate across language barriers.

## ... but why not the original BabalFish mod?

BabelFish was a great mod for breaking langauge barrier between players speaking different languages. However, it was unmaintained for 7 years, and many code became messy and inefficient. This rewrite is a drop-in replacement for most end users, and provides more method for developers to interact with BabelFish. Notable changes include:

* Guessing preferred language from the player's client language code
* Handles [Beerchat](https://content.luanti.org/packages/mt-mods/beerchat/) properly
* Shipped with [Lingva Translate](https://github.com/thedaviddelta/lingva-translate) support (Yandex Translate port will be avaliable soon)
* Register new translation engine with new mods instead of adding files into the core mod

## How to use?

Avaliable in `babelfish_core` mod:

* Use `/bbcodes` to list all avaliable languages and their alias.

Avaliable in `babelfish_chat` mod:

* Write `%<language code>` in a message to boardcast translation to other players
    * e.g. "Hello %fr" would yield "Bonjour"
    * Unlike the original BabelFish, you must leave spaces between the tag and other texts.

Avaliable in `babelfish_preferred_langauge` mod:

* Your preferred language is guessed when you first join the server.
    * Fallbacks to English if your language is not supported.
* Use `/bblang <language code>` to set your preferred language.
* Use `/bblang` to check your preferred language.

Avaliable in `babelfish_chat_history` mod:

* Use `/babel <username>` to translate the last message sent by a user
* (Beerchat only) Use `/babel <username> <channel>` to translate the last message sent by a user on a channel
    * If channel is unspecified, defaults to the executer's channel.

Avaliable in `babelfish_private_chat`

* User `/bmsg <username> <message>` to send private messages to a player in their preferred language.
