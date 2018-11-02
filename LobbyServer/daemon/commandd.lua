-------------------------------------------------------------
---! @file
---! @brief 指令管理
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 工具
local clsHelper  = require "ClusterHelper"

---!
local nodeInfo

---! 模块
ttd.exports.COMMAND_D = {}
table.merge(COMMAND_D, F_COMN_DBASE)
table.merge(COMMAND_D, F_COMN_REGISTER)

---! 加载指令
load_all("cmd")

---! 派发指令
function COMMAND_D:process_command (clientAddr, clientFd, packetName, packetData)
    local userOb = LOGIN_D:find_user(clientAddr, clientFd)
    if not userOb then
        return
    end

    local process_func = self:query_interface(packetName)
    if type(process_func) ~= "function" then
        return
    end

    skynet.fork(function ()
        if userOb:is_destroy() then
            return
        end

        xpcall(function ()
            process_func(userOb, packetData)
        end,
        function (err)
            skynet.error(err)
            skynet.error(debug.traceback())
        end)
    end)
end

---! 发送消息
function COMMAND_D:send_messasge (userOb, packetName, packetData)
    if userOb:is_destroy() then
        return
    end

    if userOb:is_robot() then
        return
    end

    local clientId = userOb:get_client_id()
    if not clientId then
        return
    end

    local clientFd, clientAddr = clientId:match("([^@]+)@([^@]+)")
    if not clientAddr or not clientFd then
        return
    end

    if not nodeInfo then
        nodeInfo = skynet.queryservice("NodeInfo")
    end

    local appName = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kAgentServer, 1)
    if not appName then
        return
    end

    clsHelper.cluster_proxy_psend(appName, clsHelper.kWatchDog, "sendToAgent", tonumber(clientFd), packetName, packetData or {})
end

---! 广播消息
function COMMAND_D:broadcast_message (userOb, packetName, packetData)
    if userOb:is_destroy() then
        return
    end

    if not nodeInfo then
        nodeInfo = skynet.queryservice("NodeInfo")
    end

    local appNames = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kAgentServer)
    if not appNames then
        return
    end

    lume.each(appNames, function (appName)
        clsHelper.cluster_proxy_psend(appName, clsHelper.kWatchDog, "broadcast", 0, packetName, packetData or {})
    end)
end
