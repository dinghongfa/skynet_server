
---! 依赖
local skynet = require "skynet"

---! 常量
local timeout = 60 -- 60 seconds
local nodeInfo

---! 心跳, 汇报在线人数
local function report_info ()
    if not nodeInfo then
        nodeInfo = skynet.queryservice("NodeInfo")
    end

    while true do
        skynet.sleep(timeout * 100)

        local stat = skynet.call(skynet.self(), "lua", "getStat")
        skynet.call(nodeInfo, "lua", "updateConfig", stat.sum, "nodeInfo", "numPlayers")
        local ret, nodeLink = pcall(skynet.call, nodeInfo, "lua", "getServiceAddr", "NodeLink")
        if ret and nodeLink ~= "" then
            pcall(skynet.send, nodeLink, "lua", "heartBeat", stat.sum)
        end

        local appName = skynet.call(nodeInfo, "lua", "getConfig", "nodeInfo", "appName")
        local arr = {appName}
        table.insert(arr, string.format("Web: %d", stat.web))
        table.insert(arr, string.format("总人数: %d", stat.sum))
        print(table.concat(arr, "\t"))
    end
end

skynet.fork(report_info)
