-------------------------------------------------------------
---! @file
---! @brief F_COMN_REGISTER
-------------------------------------------------------------

---! 模块
local M = {}

---! 设置接口
function M:register_interface (name, callback)
    self:set_temp("interface", name, callback)
end

---! 查询接口
function M:query_interface (name)
    return self:query_temp("interface", name)
end

---! 导出模块
ttd.exports.F_COMN_REGISTER = M
