local http   = require("socket.http")
local json   = require("json")
local table  = require("table")
local ltn12  = require("ltn12")
local string = require("string")
local base   = _G
module("couchdb")

config = config or {}
config.host = "localhost"
config.port = 5984
config.debug = false

local couchdb_request
local to_json
local get_documents_by_filter
local make_condition

function couchdb_request(request)
    -- ensure methode
    if request.methode == nil then
        request.methode = 'GET'
    end

    local t = {}
    -- request parameter
    local param = {
        url     = string.format("http://%s:%d/%s", config.host, config.port, request.path),
        method  = request.methode,
        sink    = ltn12.sink.table(t),
        headers = { 
            ["Connection"]          = 'close',
            ["X-Couch-Full-Commit"] = 'true'
        }
    }

    -- POST body
    if request.body ~= nil then
        local data = to_json(request.body)
        param.source = ltn12.source.string(data)
        param.headers["Content-Length"] = string.len(data)
        param.headers["Content-Type"]   = "application/json"
    end

    -- send request
    local response, code = http.request(param)

    -- debug
    if config.debug then
        base.print('#### ' .. request.methode .. ' ' .. request.path .. ' ####')
        if request.body ~= nil then base.print("body = " .. to_json(request.body) .. "\n") end
        base.print('code = ' .. code)
        base.print(table.concat(t))
    end

    -- ensure right reponse
    if request.code ~= nil then
        base.assert(code == request.code, 'unexpected return code - ' .. code)
    end

    return json.decode(table.concat(t))
end

function get_all_databases()
    return couchdb_request({ path = '_all_dbs', code = 200 })
end

function get_stats()
    return couchdb_request({ path = '_stats', code = 200 })
end

function create_database(name)
    return couchdb_request({ path = name, methode = 'PUT', code = 201 })
end

function delete_database(name)
    return couchdb_request({ path = name, methode = 'DELETE', code = 200 })
end

function get_database_info(name)
    return couchdb_request({ path = name, code = 200 })
end

function create_document(db, name, data)
    local query
    local methode
    if name == nil then
        query = db .. '/'
        methode = 'POST'
    else
        query = db .. '/' .. name
        methode = 'PUT'
    end

    return couchdb_request( { path = query, methode = methode, body = data, code = 201 })
end

function change_document(db, name, data)
    base.assert(name, 'param name is missing')

    local rev = couchdb_request({ path = db .. '/' .. name, code = 200 })
    data["_rev"] = rev["_rev"]
    return couchdb_request({ path = db .. '/' .. name, methode = 'PUT', body = data, code = 201 })
end

function delete_document(db, name)
    base.assert(db and name, 'parameter is missing')

    local rev = couchdb_request({ path = db .. '/' .. name, code = 200 })
    return couchdb_request({ path = db .. '/' .. name .. '?rev=' .. rev["_rev"] , methode = 'DELETE', code = 200 })
end

function get_document(db, name)
    base.assert(db and name, 'parameter is missing')

    return couchdb_request({ path = db .. '/' .. name, code = 200 })
end

function get_document_revs(db, name)
    base.assert(db and name, 'parameter is missing')

    return get_document(db, name .. '?revs=true')
end

function get_documents_by_attribute(db, attribute, value)
    base.assert(db and attribute and value, 'parameter is missing')

    return get_documents_by_condition(db, "doc." .. attribute .. "=='" .. value ..  "'")
end

function get_documents_by_filter_or(db, attributes)
    return get_documents_by_filter(db, attributes, ' || ')
end

function get_documents_by_filter_and(db, attributes)
    return get_documents_by_filter(db, attributes, ' && ')
end

-- private functions ------------------------------------------------------------------------------

-- convert object to JSON
function to_json(text)
    -- fix quote escaping problem
    return string.gsub(json.encode(text), "\\'", "'")
end

-- get documents by attributes and connect them by condition
function get_documents_by_filter(db, attributes, condition)
    base.assert(db and condition and base.type(attributes) == "table", 'parameter is wrong or missing')

    local query = nil
    for k, v in base.pairs(attributes) do
        if query then
            -- ectend
            query = query .. condition .. make_condition(k, v)
        else
            -- first time
            query = make_condition(k, v)
        end
    end

    return get_documents_by_condition(db, query)
end

-- create javascript compare
function make_condition(key, value)
    return 'doc.' .. key .. "=='" .. value .. "'"
end

-- return documents by given condition
function get_documents_by_condition(db, condition, sort)
    -- check
    base.assert(db and condition, 'parameter is wrong or missing')

    -- sorting - null == without sorting
    if sort == nil then
        sort = 'null'
    end

    -- create request and response
    local response =  couchdb_request({
        path = db .. '/_temp_view',
        methode = 'POST',
        body = { map = "function(doc) { if (" .. condition ..  ") { emit(" .. sort .. ", doc); }}" }
    })

    -- map documents
    local docs = {}
    for k, v in base.ipairs(response.rows) do
        table.insert(docs, v.value)
    end

    -- and return
    return docs
end

