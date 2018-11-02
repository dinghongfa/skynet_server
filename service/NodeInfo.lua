-------------------------------------------------------------
---! @file  NodeInfo.lua
---! @brief 保存当前节点信息，供其它服务使用
--------------------------------------------------------------

---! 依赖
local skynet    = require "skynet"
local cluster   = require "skynet.cluster"

---! 工具
local clsHelper = require "ClusterHelper"

---! 信息
local info = {}

---! 通讯
local CMD = {}

function CMD.initNode ()
    clsHelper.parseConfig(info)
    return info
end

function CMD.getServiceAddr (key)
    local ret = info[key] or ""
    return ret
end

function CMD.getConfig (...)
    local args = table.pack(...)
    local ret = info
    for _, key in ipairs(args) do
        if ret[key] then
            ret = ret[key]
        else
            return ""
        end
    end

    return ret or ""
end

function CMD.updateConfig (value, ...)
    local args = table.pack(...)
    local last = table.remove(args)
    local ret = info
    for _, key in ipairs(args) do
        local one = ret[key]
        if not one then
            one = {}
            ret[key] = one
        elseif type(one) ~= "table" then
            return ""
        end
        ret = one
    end

    ret[last] = value
    return ""
end

---! 获得本节点的注册信息
function CMD.getRegisterInfo ()
    local nodeInfo = info.nodeInfo
    local ret = {}
    ret.kind = nodeInfo.serverKind
    ret.name = nodeInfo.appName
    ret.addr = nodeInfo.privAddr
    ret.port = nodeInfo.debugPort
    ret.numPlayers = nodeInfo.numPlayers

    ret.conf = info[clsHelper.kHallConfig]

    return ret
end

---! 收到通知，NodeLink已经上线
function CMD.nodeOn (nodeLink)
    CMD.nodeOff()

    info["NodeLink"] = nodeLink
    skynet.fork(function()
        ---! 实时监控NodeLink
        pcall(skynet.call, nodeLink, "debug", "LINK")
        skynet.error("my nodelink is offline", nodeLink)
        if info["NodeLink"] == nodeLink then
            info["NodeLink"] = nil
        end
    end)
end

---! 收到通知，NodeLink已经下线
function CMD.nodeOff ()
    local old = info["NodeLink"]
    if old then
        skynet.send(old, "lua", "exit")
        info["NodeLink"] = nil
    end

    old = info[clsHelper.kMainInfo]
    if old then
        skynet.send(old, "lua", "nodeOff")
    end
end

---! 启动函数
skynet.start(function()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("unknown command ", cmd)
        end
    end)

    ---! 注册自己的地址
    cluster.register("NodeInfo", skynet.self())
end)
