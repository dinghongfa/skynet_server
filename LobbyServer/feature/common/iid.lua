-------------------------------------------------------------
---! @file
---! @brief F_COMN_IID
-------------------------------------------------------------

---! 依赖
local uuid = require "uuid"

---! 模块
local M = {}

---! 获取
function M:get_iid ()
    if self._iid then
        return self._iid
    end

    self._iid = uuid.gen()
    return self._iid
end

---! 设置
function M:set_iid (iid)
    self._iid = iid
end

---! 导出模块
ttd.exports.F_COMN_IID = M
