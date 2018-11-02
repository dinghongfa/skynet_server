
local function main (me, packet)
    GAME_D:send_room_info(me)
end

COMMAND_D:register_interface("game.EnterRoomReq", main)
