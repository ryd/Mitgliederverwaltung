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
    if body.get then
        r:puts(json.encode( couchdb.get_document(utils.get_config(), body.get) ))
    elseif body.save then
        table.save = nil
        r:puts(json.encode( couchdb.change_document(utils.get_config(), body.id, body) ))
    end
end


