require "string"
local table   = require("table")
local json    = require("json")
local couchdb = require("couchdb")
local utils   = require("utils")
local base    = _G


function handle(r)
    r.content_type = "text/plain" -- default choose text

    local params   = {}

    if r.method == 'POST' then
        for k, v in pairs( r:parseargs() ) do
            params[k] = v
        end

        local body = {}
        for k, v in pairs( r:parsebody() ) do
            body[k] = v
        end
        dispatch_post(r, params, body)
    else
        r:puts("unknown HTTP method " .. r)
    end 
end

function dispatch_post(r, args, body)
    r.content_type = 'application/json'
    if body.id == 'new' then
        body.id = get_next_id()
    end
    r:puts( json.encode( couchdb.create_document( utils.get_config(), body.id, body ) ) )
end

function get_next_id()
    local number =  couchdb.get_document( utils.get_config(), utils.get_id_field() ).value + 1
    couchdb.change_document( utils.get_config(), utils.get_id_field(), { value = number } )
    return number
end

