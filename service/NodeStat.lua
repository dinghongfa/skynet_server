-------------------------------------------------------------
---! @file  NodeStat.lua
---! @brief 调试当前节点，获取运行信息
--------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

local clsHelper = require "ClusterHelper"
local admin_kind = clsHelper.kAdminServer
local agent_kind = clsHelper.kAgentServer
local lobby_kind = clsHelper.kLobbyServer
local admin_name = clsHelper.kMainInfo
local agent_name = clsHelper.kWatchDog
local lobby_name = clsHelper.kHallCenter

---! AdminServer信息
local function admin_info(nodeInfo)
    local srv  = skynet.queryservice(admin_name)
    local stat = skynet.call(srv, "lua", "getStat")
    return stat
end

---! AgentServer信息
local function agent_info(nodeInfo)
    local srv  = skynet.queryservice(agent_name)
    local stat = skynet.call(srv, "lua", "getStat")
    local arr  = {nodeInfo.appName}
    table.insert(arr, string.format("Web: %d", stat.web))
    table.insert(arr, string.format("总人数: %d", stat.sum))
    return arr
end

---! LobbyServer
local function lobby_info(nodeInfo)
    local arr = {nodeInfo.appName}
    table.insert(arr, string.format("num: %d", nodeInfo.numPlayers))
    return arr
end

---! 显示节点信息
local function dump_info()
    local srv = skynet.queryservice("NodeInfo")
    local nodeInfo = skynet.call(srv, "lua", "getConfig", "nodeInfo")

    if nodeInfo.serverKind == admin_kind then
        return admin_info(nodeInfo)
    end

    if nodeInfo.serverKind == agent_kind then
        return agent_info(nodeInfo)
    end

    if nodeInfo.serverKind == lobby_kind then
        return lobby_info(nodeInfo)
    end

    return "nothing output."
end

skynet.start(function()
    skynet.info_func(dump_info)
end)
