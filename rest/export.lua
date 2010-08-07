require "string"
local table   = require("table")
local json    = require("json")
local couchdb = require("couchdb")
local utils   = require("utils")
local base    = _G

local fields  = { 'id', 'firstname', 'lastname', 'street', 'plz', 'email', 'phone', 'entry_date',
        'separation_date', 'member_fee', 'member_fee_frequenze', 'paid_till' }

function handle(r)
    r.content_type = "text/plain" -- default choose text

    local params   = {}

    if r.method == 'GET' then
        for k, v in pairs( r:parseargs() ) do
            params[k] = utils.urldecode(v)
        end

        dispatch_post(r, params)
    else
        r:puts("unknown HTTP method " .. r.method)
    end 
end

function dispatch_post(r, args)
    if args.format and args.format == 'tsv' then
        export_tsv(r)
    else 
        r.content_type = 'text/txt'
        r:puts("unkown format")
    end
end

function export_tsv(r)
    r.content_type = 'text/tsv'
    result = couchdb.get_documents_by_condition(utils.get_config(), 
            'doc.' .. utils.config.id_field, 'doc.' .. utils.config.id_field)
    r:puts(table.concat(fields, "\t") .. "\n")
    for i, v in base.ipairs(result) do
        row = {}
        for j, f in base.ipairs(fields) do
            table.insert(row, v[f] or '-')
        end
        r:puts(table.concat(row, "\t") .. "\n")
    end
end


