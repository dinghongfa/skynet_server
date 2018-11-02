-------------------------------------------------------------
---! @file  HallCenter
---! @brief 游戏大厅核心服务
-------------------------------------------------------------

---! 依赖
local skynet  = require "skynet"
require "skynet.manager"	-- import skynet.launch, ...

---! 消息
local CMD = {}

---! 启动函数
skynet.start(function()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(address, ...))
        else
            skynet.error("unknown command ", cmd)
        end
    end)

    ---! 获得 NodeInfo 服务 注册自己
    local nodeInfo = skynet.queryservice("NodeInfo")
    skynet.call(nodeInfo, "lua", "updateConfig", skynet.self(), SERVICE_NAME)

    require "utils.constant"

    ---! 加载模块
    load_all("feature")
    load_all("inherit")
    load_all("object")
    load_all("daemon")

    skynet.register(SERVICE_NAME)
end)

---! 登录
CMD.login = function (address, fd, userId, loginInfo)
    local ret = LOGIN_D:login(address, fd, userId, loginInfo)
    if not ret then
        return false
    end

    return true
end

---! 断线
CMD.disconnect = function (address, fd)
    LOGIN_D:disconnect(address, fd)
    return true
end

---! 心跳
CMD.heartbeat = function (address, fd)
    HEART_BEAT_D:active(address, fd)
    return true
end

---! 转发
CMD.forward = function (address, fd, packetName, packetData)
    COMMAND_D:process_command(address, fd, packetName, packetData)
    return true
end
