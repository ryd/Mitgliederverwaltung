local table      = require("table")
local couchdb    = require("couchdb")
local string     = require("string")
local base = _G
module("utils")

config = config or {}
config.host = "localhost"
config.port = 5984
config.debug = false
config.schema = 'example'
config.id_field = 'mitgliedernummer'


function get_config()
    couchdb.config = config
    return config.schema
end

function init_db()
    couchdb.create_database(get_config())
    couchdb.create_document(get_config(), get_id_field(), { value=0 })
end

function get_id_field()
    return config.id_field
end

function urldecode(s)
    if s == nil then return nil end
    for word in string.gmatch("asdf%20asdf", "(%%%x%x)") do
        s = string.gsub(s, "%" .. word,
            string.char(base.tonumber(string.sub(word, 2), 16)))
    end
    return s
end

function urldecode_table(t)
    for k, v in base.pairs(t) do
        t[k] = urldecode(v)
    end
end
