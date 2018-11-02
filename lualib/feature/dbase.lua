-------------------------------------------------------------
---! @file
---! @brief F_COMN_DBASE
--------------------------------------------------------------

---! 模块
local M = {}

function M:query_entire_dbase ()
    self.dbase = self.dbase or {}
    return self.dbase
end

function M:set_entire_dbase (dbase)
    self.dbase = dbase or {}
end

function M:query_entire_temp_dbase ()
    self.temp_dbase = self.temp_dbase or {}
    return self.temp_dbase
end

function M:set_entire_temp_dbase (temp_dbase)
    self.temp_dbase = temp_dbase or {}
end

function M:set (key, value, ...)
    local db = self:query_entire_dbase()
    ttd.express_set(db, key, value, ...)
end

function M:query (key, ...)
    local db = self:query_entire_dbase()
    return ttd.express_query(db, key, ...)
end

function M:delete (key, ...)
    local db = self:query_entire_dbase()
    ttd.express_delete(db, key, ...)
end

function M:set_temp (key, value, ...)
    local db = self:query_entire_temp_dbase()
    ttd.express_set(db, key, value, ...)
end

function M:query_temp (key, ...)
    local db = self:query_entire_temp_dbase()
    return ttd.express_query(db, key, ...)
end

function M:delete_temp (key, ...)
    local db = self:query_entire_temp_dbase()
    ttd.express_delete(db, key, ...)
end

return M
