------------------------------------------------------
---! @file
---! @brief AdminService
------------------------------------------------------

---! 依赖
local skynet    = require "skynet"
local cluster   = require "skynet.cluster"

---! 工具
local clsHelper = require "ClusterHelper"

---! 全局常量
local nodeInfo = nil
local appName = nil

local servers = {}
local admin = {}

---! detect master AdminServer
local function do_detectMaster (app, addr)
    if app < appName then
        if admin[app] then
            return
        end
        admin[app] = addr
        skynet.error("hold the admin server", app)
        pcall(cluster.call, app, addr, "LINK", true)
        skynet.error("disconnect the admin server", app)
        admin[app] = nil
    else
        addr = clsHelper.cluster_addr(app, clsHelper.kMainInfo)
        if addr then
            pcall(cluster.call, app, addr, "holdAdmin", appName)
        end
    end
end

---! loop in the back to detect master
local function detectMaster ()
    local list = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kAdminServer)
    table.sort(list, function (a, b)
        return a < b
    end)

    for _, app in ipairs(list) do
        if app ~= appName then
            local addr = clsHelper.cluster_addr(app, clsHelper.kNodeLink)
            if addr then
                skynet.fork(function ()
                    do_detectMaster(app, addr)
                end)
            end
        end
    end
end

---! other node comes to register, check if any master
local function checkBreak ()
    for app, _ in pairs(admin) do
        if app < appName then
            skynet.error(appName, "find better to break", app)
            skynet.call(nodeInfo, "lua", "nodeOff")
            skynet.sleep(3 * 100)
            skynet.newservice("NodeLink")
            break
        end
    end
end

---! 对方节点断线
local function disconnect_kind_server (kind, name)
    local list = servers[kind] or {}
    local one = list[name]

    --! remove from server kind reference
    list[name] = nil

    --! remove from game id reference
    if one.gameId then
        list = servers[one.gameId] or {}
        list[name] = nil
    end
end

---! 维持与别的节点的联系
local function hold_kind_server (kind, name)
    local addr = clsHelper.cluster_addr(name, clsHelper.kNodeLink)
    if not addr then
        disconnect_kind_server(kind, name)
        return
    end

    skynet.error("hold kind server", kind, name)
    pcall(cluster.call, name, addr, "LINK", true)
    skynet.error("disconnect kind server", kind, name)

    disconnect_kind_server(kind, name)
end

---! skynet service handlings
local CMD = {}

---! hold other master
function CMD.holdAdmin (otherName)
    if otherName >= appName or admin[otherName] then
        return 0
    end

    local addr = clsHelper.cluster_addr(otherName, clsHelper.kNodeLink)
    if not addr then
        return 0
    end

    admin[otherName] = addr

    skynet.fork(function ()
        skynet.error("hold the admin server", otherName)
        pcall(cluster.call, otherName, addr, "LINK", true)
        skynet.error("disconnect the admin server", otherName)
        admin[otherName] = nil
    end)

    skynet.fork(checkBreak)
    return 0
end

---! get noticed of my node off
function CMD.nodeOff ()
    servers = {}
end

---! ask all possible nodes to register them
function CMD.askAll ()
    servers = {}

    local all = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kAgentServer)
    local list = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kLobbyServer)
    for _, v in ipairs(list) do
        table.insert(all, v)
    end

    for _, app in ipairs(all) do
        local addr = clsHelper.cluster_addr(app, clsHelper.kNodeLink)
        if addr then
            pcall(cluster.call, app, addr, "askReg")
        end
    end
end

function CMD.getAgentList ()
    local ret = {}
    ret.agents = {}
    local list = servers[clsHelper.kAgentServer] or {}
    for k, v in pairs(list) do
        local one = {}
        one.name = v.clusterName
        one.addr = v.address
        one.port = v.port
        one.numPlayers = v.numPlayers
        table.insert(ret.agents, one)
    end

    return ret
end

---! node info to register
function CMD.regNode (node)
    local kind = node.kind
    assert(table.indexof({clsHelper.kAgentServer, clsHelper.kLobbyServer}, kind) > 0)

    local list = servers[kind] or {}
    servers[kind] = list

    local one = {}
    one.clusterName   = node.name
    one.address       = node.addr
    one.port          = node.port
    one.numPlayers    = node.numPlayers
    one.lastUpdate    = os.time()

    local config = node.conf
    if config then
        one.gameId         = tonumber(config.GameId) or 0
        one.gameMode       = tonumber(config.GameMode) or 0
        one.gameVersion    = tonumber(config.Version) or 0
        one.lowVersion     = tonumber(config.LowestVersion) or 0
        one.hallName       = config.HallName
        one.lowPlayers     = config.Low
        one.highPlayers    = config.High
    end

    -- add into server kind list
    list[node.name] = one

    if one.gameId then
        -- add into game id list
        list = servers[one.gameId] or {}
        list[node.name] = one
        servers[one.gameId] = list
    end

    skynet.fork(function()
        hold_kind_server(kind, node.name)
    end)
    skynet.fork(checkBreak)

    return 0
end

---! 心跳，更新人数
function CMD.heartBeat (kind, name, num)
    local list = servers[kind] or {}
    local one = list[name]
    if not one then
        return 0
    end
    one.numPlayers = num
end

---! 记录游戏玩家
function CMD.keepAppGameUser (uid, gameId, appName)
end

---! 清除游戏玩家
function CMD.freeAppGameUser (uid, gameId)
end

---! 获得游戏玩家所在的节点
function CMD.getAppGameUser (uid, gameId)
end

---! get the server stat
function CMD.getStat ()
    local agentNum, hallNum = 0,0

    local str = nil
    local arr = {}
    table.insert(arr, os.date() .. "\n")
    table.insert(arr, "[Agent List]\n")

    local agentCount = 0
    local list = servers[clsHelper.kAgentServer] or {}
    for _, one in pairs(list) do
        agentCount = agentCount + one.numPlayers
        agentNum = agentNum + 1
        str = string.format("%s\t%s:%d num:%d\n", one.clusterName, one.address, one.port, one.numPlayers)
        table.insert(arr, str)
    end

    local hallCount = 0
    table.insert(arr, "\n[Lobby List]\n")
    list = servers[clsHelper.kLobbyServer] or {}
    table.sort(list, function(a, b)
        return a.clusterName < b.clusterName
    end)
    for _, one in pairs(list) do
        hallCount = hallCount + one.numPlayers
        hallNum = hallNum + 1
        str = string.format("%s\t%s:%d num:%d \t=> [%d, %d]", one.clusterName, one.address, one.port, one.numPlayers, one.lowPlayers, one.highPlayers)
        table.insert(arr, str)
        str = string.format("\t%s id:%s mode:%s version:%s low:%s\n", one.hallName, one.gameId, one.gameMode, one.gameVersion, one.lowVersion or "0")
        table.insert(arr, str)
    end

    str = string.format("\n大厅服务器数目:%d \t网关服务器数目:%d \t登陆人数:%d \t游戏人数:%d\n", hallNum, agentNum, hallCount, agentCount)
    table.insert(arr, str)

    return table.concat(arr)
end

function CMD.LINK (hold)
    if hold then
        skynet.wait()
    end
    skynet.error("return from LINK")
    return 0
end

---! 服务的启动函数
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

    ---! 获得NodeInfo 服务
    nodeInfo = skynet.queryservice("NodeInfo")

    ---! 注册自己的地址
    skynet.call(nodeInfo, "lua", "updateConfig", skynet.self(), clsHelper.kMainInfo)

    ---! 获得appName
    appName = skynet.call(nodeInfo, "lua", "getConfig", "nodeInfo", "appName")

    ---! ask all nodes to register
    skynet.fork(CMD.askAll)

    ---! run in the back, detect master
    skynet.fork(detectMaster)
end)
