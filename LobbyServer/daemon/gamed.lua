-------------------------------------------------------------
---! @file
---! @brief 游戏管理
-------------------------------------------------------------

---! 依赖
local uuid = require "uuid"

---! 模块
ttd.exports.GAME_D = {}

---! 发送房间信息
function ROLL_D:send_room_info (me)
    me:send("roll.EnterRoomRep")
end
