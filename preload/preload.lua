------------------------------------------------------
---! @file
---! @brief 预加载文件
------------------------------------------------------

---!
ttd = ttd or {}

---!
require "functions"

---!
require "lfstool"

---!
lume = require "lume.lume"

---! replace print method
local __print = print
print = function (...)
    local skynet = require "skynet"
    skynet.error(...)
end

local __printf = printf
printf = function (...)
    print(string.format("[%s]", os.date("%Y-%m-%d %H:%M:%S")), string.format(...))
end

---! export global variable
local __g = _G
ttd.exports = {}
setmetatable(ttd.exports, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

--[[
setmetatable(__g, {
    __newindex = function(_, name, value)
        error(string.format("USE \" ttd.exports.%s = value \" INSTEAD OF SET GLOBAL VARIABLE", name), 0)
    end
})
--]]

ttd.class = function (classname, ...)
    local M = class(classname, ...)
    ttd.exports[classname] = M:create()
    return M
end

ttd.express_query = function (db, key, ...)
    if type(db) ~= "table" then
        return nil
    end

    if select("#", ...) == 0 then
        return db[key]
    end

    if db[key] == nil then
        return nil
    end

    return ttd.express_query(db[key], ...)
end

ttd.express_set = function (db, key, value, ...)
    if type(db) ~= "table" then
        db = {}
    end

    if select("#", ...) == 0 then
        local ret = db[key]
        db[key] = value
        return ret, value
    end

    return ttd.express_set(db[key], value, ...)
end

ttd.express_delete = function (db, key, ...)
    if type(db) ~= "table" then
        return
    end

    if select("#", ...) == 0 then
        db[key] = nil
        return
    end

    return ttd.express_set(db[key], ...)
end
