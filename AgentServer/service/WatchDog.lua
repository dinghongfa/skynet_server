-------------------------------------------------------------
---! @file
---! @brief 监控游戏连接
--------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! skynet service handlings
local CMD = {}

---! @brief this function may not be called after we transfer fd to agent
function CMD.closeAgent (fd)
    WEBSOCKET_D:kick_agent(fd)
end

function CMD.openAgent(fd)
    WEBSOCKET_D:open_agent(fd)
end

---! 向前端发送消息
function CMD.sendToAgent (fd, name, packet)
    WEBSOCKET_D:send_agent(fd, name, packet)
end

---! 从前端接收消息
function CMD.recvFromAgent (fd, message)
    WEBSOCKET_D:recv_agent(fd, message)
end

---! 向前端广播消息
function CMD.broadcast (fds, name, packet)
    WEBSOCKET_D:broadcast_agents(fds, name, packet)
end

function CMD.getStat ()
    local stat = {}
    stat.web = WEBSOCKET_D:get_agent_num()
    stat.sum = stat.web
    return stat
end

---! 启动函数
skynet.start(function()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("unknown command ", cmd)
        end
    end)

    ---! 获得 NodeInfo 服务 注册自己
    local nodeInfo = skynet.queryservice("NodeInfo")
    skynet.call(nodeInfo, "lua", "updateConfig", skynet.self(), SERVICE_NAME)

    ---! 加载模块
    load_all("object")
    load_all("daemon")

    ---! 启动 web gate
    local myInfo = skynet.call(nodeInfo, "lua", "getConfig", "nodeInfo")
    WEBSOCKET_D:start_listen(myInfo.publAddr, myInfo.webPort)
end)
