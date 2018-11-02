-------------------------------------------------------------
---! @file
---! @brief  F_CHAR_COMM
-------------------------------------------------------------

---! 依赖
local json = require "cjson"

---! 模块
local M = {}

---! 发包
function M:send (packetName, packetData)
    COMMAND_D:send_messasge(self, packetName, packetData)
end

---! 广播
function M:broadcast (packetName, packetData)
    COMMAND_D:broadcast_message(self, packetName, packetData)
end

---! 更新自己数据
function M:send_update (userData)
    self:send_update_user(self:get_user_id(), userData)
end

---! 更新玩家数据
function M:send_update_user (userId, userData)
    self:send("user.UserInfoUpdate", { uid = userId, doc = json.encode(userData), })
end

---! 发送提示信息
function M:send_notice (channel, message, parameters)
    self:send("user.NotifyMessage", { channel = channel, message = message, parameter = parameters or {} })
end

---! 发送弹出提示
function M:send_dialog_ok (message)
    self:send_notice(ttd.CHANNEL_DIALOG, message)
end

ttd.exports.F_CHAR_COMM = M
