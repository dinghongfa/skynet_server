-------------------------------------------------------------
---! @file  NodeLink.lua
---! @brief 监控当前节点，察觉异常退出
--------------------------------------------------------------

---! 依赖
local skynet    = require "skynet"
local cluster   = require "skynet.cluster"

local clsHelper = require "ClusterHelper"
local admin_kind = clsHelper.kAdminServer

---! 信息
local nodeInfo = nil
local thisInfo
local mainApp

---! 保持远程节点，对方断线时切换
local function holdAdminServer(list)
    if mainApp then
        return
    end

    for _, appName in ipairs(list) do repeat
        local addr = clsHelper.cluster_addr(appName, clsHelper.kMainInfo)
        if not addr then
            break
        end

        local ok = pcall(cluster.call, appName, addr, "regNode", thisInfo)
        if not ok then
            break
        end

        skynet.fork(function()
            skynet.error("hold the main server", appName)
            pcall(cluster.call, appName, addr, "LINK", true)
            skynet.error("disconnect the main server", appName)

            mainApp = nil
            skynet.call(nodeInfo, "lua", "updateConfig", nil, clsHelper.kMainNode)
            holdAdminServer(list)
        end)

        skynet.call(nodeInfo, "lua", "updateConfig", appName, clsHelper.kMainNode)
        mainApp = appName
        return
    until true end
end

---! 向 AdminServer 注册自己
local function registerSelf ()
    if mainApp then
        return
    end

    thisInfo = skynet.call(nodeInfo, "lua", "getRegisterInfo")
    skynet.error("thisInfo.kind = ", thisInfo.kind)
    if thisInfo.kind == admin_kind then
        skynet.error("AdminServer should not register itself", thisInfo.name)
        return
    end

    local list = skynet.call(nodeInfo, "lua", "getConfig", admin_kind)
    holdAdminServer(list)

    while not mainApp do
        skynet.sleep(500)
        holdAdminServer(list)
    end
end

---! 通讯
local CMD = {}

---! 收到通知，需要向cluster里的AdminServer注册自己
function CMD.askReg ()
    registerSelf()
end

---! 通知在线人数更新
function CMD.heartBeat (num)
    if not mainApp then
        return
    end
    local mainAddr = clsHelper.cluster_addr(mainApp, clsHelper.kMainInfo)
    if not mainInfoAddr then
        return
    end
    return pcall(cluster.send, mainApp, mainAddr, "heartBeat", thisInfo.kind, thisInfo.name, num)
end

---! 收到通知，结束本服务
function CMD.exit ()
    skynet.exit()
end

function CMD.LINK (hold)
    if hold then
        skynet.wait()
    end
    skynet.error("return from LINK")
    return 0
end

---! 启动服务
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

    ---! 向 NodeInfo 注册自己
    nodeInfo = skynet.queryservice("NodeInfo")
    skynet.call(nodeInfo, "lua", "nodeOn", skynet.self())

    ---! 向 MainNode 注册自己
    registerSelf()
end)
