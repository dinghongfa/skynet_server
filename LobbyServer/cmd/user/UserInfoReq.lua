
local function main (me, packet)
    local userId = packet.uid
    USER_D:send_user_info(me, userId)
end

COMMAND_D:register_interface("user.UserInfoReq", main)
