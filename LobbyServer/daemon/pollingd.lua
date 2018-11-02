-------------------------------------------------------------
---! @file
---! @brief 数据挖掘
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 模块
ttd.exports.POLLING_D = {}

function _save_into_mysql (save_path, save_data)
    local ret = pcall(function ()
        skynet.send("Polling", "lua", "polling", save_path, save_data)
    end)
    return ret
end

function POLLING_D:polling_user_money (data)
    if not data.account then
        data.account = ""
    end

    _save_into_mysql("ltt_user_money", data)
end
