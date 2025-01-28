read_globals = {
    "DIR_DELIM",
    "INIT",

    "core",
    "dump",
    "dump2",

    "Raycast",
    "Settings",
    "PseudoRandom",
    "PerlinNoise",
    "VoxelManip",
    "SecureRandom",
    "VoxelArea",
    "PerlinNoiseMap",
    "PcgRandom",
    "ItemStack",
    "AreaStore",

    "vector",

    table = {
        fields = {
            "copy",
            "indexof",
            "insert_all",
            "key_value_swap",
            "shuffle",
        }
    },

    string = {
        fields = {
            "split",
            "trim",
        }
    },

    math = {
        fields = {
            "hypot",
            "sign",
            "factorial"
        }
    },
}

files["babelfish_core"] = {
    globals = {
        "babelfish",
    }
}

files["babelfish_engine_lingva"] = {
    read_globals = {
        "babelfish",
    }
}

files["babelfish_chat"] = {
    read_globals = {
        "babelfish",
        "beerchat",
        "random_messages_api",
    }
}

files["babelfish_chat_history"] = {
    read_globals = {
        "babelfish",
        "beerchat",
        "random_messages_api",
    }
}

files["babelfish_preferred_langauge"] = {
    globals = {
        "babelfish",
    },
    read_globals = {
        "random_messages_api",
    }
}

files["babelfish_private_chat"] = {
    read_globals = {
        "babelfish",
        "random_messages_api",
    }
}
