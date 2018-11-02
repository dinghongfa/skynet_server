-------------------------------------------------------------
---! @file
---! @brief F_COMN_SAVE
-------------------------------------------------------------

---! 模块
local M = {}

---! 加载
function M:load ()
    return DATABASE_D:load(self)
end

---! 保存
function M:save ()
    return DATABASE_D:save(self)
end

function M:get_save_path ()
    error("Method get_save_path must be override.")
end

function M:set_selector (selector)
    self:set_temp("data_selector", selector)
end

function M:get_selector ()
    return self:query_temp("data_selector") or {}
end

---! 导出
ttd.exports.F_COMN_SAVE = M
