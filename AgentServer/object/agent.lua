
---! 依赖
local skynet = require "skynet"
local dbase  = require "feature.dbase"

---! 常量
local heartbeat = 10    -- 10 seconds to send heart beat
local timeout   = 180   -- 180 seconds, 3 minutes

---! 模块
ttd.exports.AGENT_OB = class("AGENT_OB", dbase)

function AGENT_OB:start (fd, addr, header)
    local srv = skynet.newservice("WebAgent")
    local ret = skynet.call(srv, "lua", "start", fd, addr, header)
    if not ret then
        return false
    end

    ---!
    self:set("client_fd", fd)
    self:set("address", addr)
    self:set("service", srv)

    ---!
    self:set_temp("login_time", skynet.time())
    self:set_temp("last_update", skynet.time())

    ---!
    skynet.fork(self.keep_alive, self)
    return true
end

function AGENT_OB:connected ()
    self:set_temp("last_update", skynet.time())
end

function AGENT_OB:destory ()
    ---/// todo:
end

function AGENT_OB:disconnect (timeout)
    timeout = checknumber(timeout)

    if self:query_temp("terminated") then
        return
    end

    self:set_temp("terminated", true)

    skynet.timeout(timeout * 100, function()
        local client_srv = self:query("service")
        if client_srv then
            ---!
            self:delete("service")

            ---! 断开连接
            pcall(skynet.send, client_srv, "lua", "disconnect")
        end

        local client_fd = self:query("client_fd")
        if client_fd then
            ---!
            AGENT_D:disconnect(self)

            ---!
            self:delete("client_fd")
        end
    end)
end

function AGENT_OB:send_packet (name, packet)
    local client_srv = self:query("service")
    if not client_srv then
        return
    end

    local ok, message = PROTO_D:encode_packet(name, packet)
    if not ok then
        return
    end

    pcall(skynet.send, client_srv, "lua", "send_packet", message)
end

function AGENT_OB:recv_message (message)
    local ok, name, packet = PROTO_D:decode_packet(message)
    if not ok then
        self:send_packet("user.LogoutRep", { type = 2, })
        self:disconnect()
        return
    end

    ---! 更新时间
    self:set_temp("last_update", skynet.time())

    ---! 心跳处理
    if name == "user.HeartbeatReq" then
        return
    end

    ---! 授权处理
    if name == "user.AuthGateReq" then
        AGENT_D:auth_gate(self, packet)
        return
    end

    AGENT_D:forward(self, name, packet)
end

function AGENT_OB:get_client_fd ()
    return self:query("client_fd")
end

function AGENT_OB:keep_alive ()
    while true do
        local client_fd = self:query("client_fd")
        if not client_fd then
            break
        end

        local last_update = self:query_temp("last_update")
        if skynet.time() - checknumber(last_update) >= timeout then
            self:disconnect()
            break
        end

        ---! 触发心跳
        AGENT_D:keep_alive(self)

        ---! 休息一下
        skynet.sleep(heartbeat * 100)
    end
end
