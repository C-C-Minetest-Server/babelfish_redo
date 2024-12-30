# BabelFish Redo: Lingva Translate

[Google Translate](https://translate.google.com) via the [Lingva](https://github.com/TheDavidDelta/lingva-translate) frontend.

## Configuration

You need a Lingva instance. You may choose [any of the officially recognized instances](https://github.com/TheDavidDelta/lingva-translate#instances), or [host one yourself](https://github.com/TheDavidDelta/lingva-translate#deployment).

Write the URL of the instance's GraphQL API into `babelfish_engine_lingva.serviceurl` of `minetest.conf`, e.g.:

```conf
# This is the official instance. You may choose another one, or host one yourself.
babelfish_engine_lingva.serviceurl = https://lingva.ml/api/graphql
```

## Supported Languages

The list of supported languages is not a constant and therefore, is fetched on every server restart.
