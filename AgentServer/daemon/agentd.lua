
---! 依赖
local skynet = require "skynet"
local crypt  = require "skynet.crypt"

local clsHelper = require "ClusterHelper"

---! 常量
local API_LEVEL_NONE = 0    -- 尚未验证
local API_LEVEL_AUTH = 1    -- 已经验证
local API_LEVEL_HALL = 2    -- 进入大厅
local API_LEVEL_GAME = 3    -- 进入游戏

---! 模块
ttd.exports.AGENT_D = {}

function AGENT_D:auth_gate (agent, data)
    if not agent:query_temp("apiLevel") then
        agent:set_temp("apiLevel", API_LEVEL_NONE)
    end

    ---! 尚未验证
    if agent:query_temp("apiLevel") == API_LEVEL_NONE then
        local uid   = tostring(data.uid)
        local ts    = tonumber(data.ts)
        local token = tostring(data.token)

        local diff = os.time() - ts
        if diff < 0 or diff > 7 * 86400 then
            ---! token失效
            agent:send_packet("user.AuthGateRep", { result = 10, })
            agent:disconnect()
            return
        end

        ---! 生成验证结果
        local result = AUTH_RESULT_PASS
        local chksum = crypt.hexencode(crypt.hmac_sha1("LbbKey123", string.format("%d:%d", uid, ts)))
        if token == chksum then
            result = AUTH_RESULT_PASS
        end

        if result ~= AUTH_RESULT_PASS then
            ---! 验证失败
            agent:send_packet("user.AuthGateRep", { result = 11, })
            agent:disconnect()
            return
        end

        ---!
        agent:set_temp("uid", uid)
        agent:set_temp("token", token)
        agent:set_temp("apiLevel", API_LEVEL_AUTH)
    end

    ---! 验证通过
    if agent:query_temp("apiLevel") == API_LEVEL_AUTH then
        ---! 获取授权信息
        local authInfo = skynet.call("ClientAuth", "lua", "load_user", agent:query_temp("uid"))
        printf("用户: %s，持有token信息 : %s，获取授权信息 : %s", agent:query_temp("uid"), agent:query_temp("token"), lume.serialize(authInfo))

        if not authInfo or authInfo.token ~= agent:query_temp("token") or not authInfo.eosname then
            ---! 验证失败
            agent:send_packet("user.AuthGateRep", { result = 12, })
            agent:disconnect()
            return
        end

        ---!
        agent:set_temp("authInfo", authInfo)
        agent:set_temp("apiLevel", API_LEVEL_HALL)
    end

    ---! 登录大厅
    if agent:query_temp("apiLevel") == API_LEVEL_HALL then
        ---! 获取 NodeInfo 服务
        local nodeInfo = skynet.queryservice("NodeInfo")
        local appName = skynet.call(nodeInfo, "lua", "getConfig", clsHelper.kLobbyServer, 1)
        if not appName then
            ---! 验证失败
            agent:send_packet("user.AuthGateRep", { result = 13, })
            agent:disconnect()
            return
        end

        ---! 请求授权登录
        local fd = agent:get_client_fd()
        local uid = agent:query_temp("uid")
        local authInfo = agent:query_temp("authInfo")

        local ok, ret = clsHelper.cluster_proxy_pcall(appName, clsHelper.kHallCenter, "login", fd, uid, authInfo)
        if not ok then
            ---! 验证失败
            agent:send_packet("user.AuthGateRep", { result = 14, })
            agent:disconnect()
            return
        end

        if not ret then
            ---! 登录失败
            agent:send_packet("user.AuthGateRep", { result = 15, })
            agent:disconnect()
            return
        end

        ---!
        agent:set_temp("appName", appName)
        agent:set_temp("apiLevel", API_LEVEL_GAME)
    end

    ---! 登录成功
    if agent:query_temp("apiLevel") == API_LEVEL_GAME then
        agent:send_packet("user.AuthGateRep", { result = 0, server_time = os.time(), })
    end
end

function AGENT_D:keep_alive (agent)
    ---! 验证尚未完成
    if agent:query_temp("apiLevel") ~= API_LEVEL_GAME then
        return
    end

    ---! 服务器地址丢失
    local appName = agent:query_temp("appName")
    local proxy = clsHelper.cluster_proxy(appName, clsHelper.kHallCenter)
    if not proxy then
        return
    end

    ---! 转发指令
    skynet.send(proxy, "lua", "heartbeat", agent:get_client_fd())
end

function AGENT_D:forward (agent, name, data)
    ---! 验证尚未完成
    if agent:query_temp("apiLevel") ~= API_LEVEL_GAME then
        agent:send_packet("user.LogoutRep", { type = 2, })
        agent:disconnect()
        return
    end

    ---! 服务器地址丢失
    local appName = agent:query_temp("appName")
    local proxy = clsHelper.cluster_proxy(appName, clsHelper.kHallCenter)
    if not proxy then
        agent:send_packet("user.LogoutRep", { type = 2, })
        agent:disconnect()
        return
    end

    ---! 转发指令
    skynet.send(proxy, "lua", "forward", agent:get_client_fd(), name, data)
end

function AGENT_D:disconnect (agent)
    local fd = agent:get_client_fd()
    if not fd then
        return
    end

    ---!
    WEBSOCKET_D:close_agent(fd)

    ---! 验证尚未完成
    if agent:query_temp("apiLevel") ~= API_LEVEL_GAME then
        return
    end

    ---! 服务器地址丢失
    local appName = agent:query_temp("appName")
    local proxy = clsHelper.cluster_proxy(appName, clsHelper.kHallCenter)
    if not proxy then
        return
    end

    ---! 转发指令
    skynet.send(proxy, "lua", "disconnect", fd)
end
