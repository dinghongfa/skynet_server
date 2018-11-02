local protoIDs = {}

-- 基本消息 AgentServer
protoIDs[4001] = "user.AuthGateReq"
protoIDs[4002] = "user.AuthGateRep"
protoIDs[4003] = "user.HeartbeatReq"
protoIDs[4004] = "user.HeartbeatRep"
protoIDs[4006] = "user.LogoutRep"

-- 用户相关 HallServer
protoIDs[4011] = "user.UserInfoReq"
protoIDs[4012] = "user.UserInfoRep"
protoIDs[4013] = "user.UserInfoUpdate"
protoIDs[4014] = "user.NotifyMessage"
protoIDs[4015] = "user.CurrencyTransferReq"
protoIDs[4016] = "user.CurrencyTransferRep"

-- 下注游戏 HallServer
protoIDs[4301] = "roll.EnterRoomReq"
protoIDs[4302] = "roll.EnterRoomRep"
protoIDs[4304] = "roll.ErrorCodeRep"
protoIDs[4305] = "roll.RollingNormalReq"
protoIDs[4306] = "roll.RollingNormalRep"
protoIDs[4307] = "roll.RollingPaymentReq"
protoIDs[4309] = "roll.NormalRecordsReq"
protoIDs[4310] = "roll.NormalRecordsRep"
protoIDs[4312] = "roll.NormalRecordsMsg"
protoIDs[4313] = "roll.PersonRecordsReq"
protoIDs[4314] = "roll.PersonRecordsRep"
protoIDs[4316] = "roll.PersonRecordsMsg"
protoIDs[4317] = "roll.RollingDebugReq"
protoIDs[4320] = "roll.ErrorCodeRep"

local ret = {}
for k, v in pairs(protoIDs) do
    ret[k] = v
    ret[v] = k
end

return ret
