require "string"
local table   = require("table")
local json    = require("json")
local couchdb = require("couchdb")
local utils   = require("utils")
local base    = _G


function handle(r)
    r.content_type = 'application/json'-- json is default

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
    local criteria = {}
    if body.keyword then
        criteria.firstname = body.keyword
        criteria.lastname  = body.keyword
        criteria.email     = body.keyword
        criteria.town      = body.keyword
        criteria.plz       = body.keyword

        rs = couchdb.get_documents_by_filter_or(utils.get_config(), criteria)
    else
        rs = couchdb.get_documents_by_filter_and(utils.get_config(), body)
    end

    r:puts(json.encode( rs ))
end

function not_empty(value)
    return value and value ~= ""
end

