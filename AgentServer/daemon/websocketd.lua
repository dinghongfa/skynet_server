
---! 依赖
local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd  = require "http.httpd"
local sockethelper = require "http.sockethelper"

---! all agents
local webAgents = {}

---! 模块
ttd.exports.WEBSOCKET_D = {}

---! 开启 web socket 监听
function WEBSOCKET_D:start_listen (address, port)
    local address = string.format("%s:%d", address, port)
    local fd = assert(socket.listen(address))
    printf("Start Websocket listen at %s", address)
    socket.start(fd , function(fd, addr)
        socket.start(fd)
        xpcall(function ()
            WEBSOCKET_D:handle_web(fd, addr)
        end,
        function (err)
            print("error is ", err)
        end)
    end)
end

---! 处理 web socket 连接
function WEBSOCKET_D:handle_web (fd, addr)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
    if not code then
        return
    end

    local last = webAgents[fd]
    if last then
        WEBSOCKET_D:close_agent(fd)
    end

    local agent = AGENT_OB:create()
    agent:start(fd, addr, header)
    webAgents[fd] = agent
    print("watchdog web agent start", fd, addr)
end

---! @brief close agent on socket fd
function WEBSOCKET_D:close_agent (fd)
    local agent = webAgents[fd]
    if agent then
        webAgents[fd] = nil
        ---! close web socket, kick web agent
        agent:disconnect()
    end
end

function WEBSOCKET_D:kick_agent (fd)
    local agent = webAgents[fd]
    if agent then
        webAgents[fd] = nil

        skynet.timeout(3, function()
            agent:disconnect()
        end)
    end
end

function WEBSOCKET_D:open_agent (fd)
    local agent = webAgents[fd]
    if agent then
        agent:connected()
    end
end

function WEBSOCKET_D:send_agent (fd, name, packet)
    local agent = webAgents[fd]
    if not agent then
        return
    end

    if agent:get_client_fd() ~= fd then
        WEBSOCKET_D:close_agent(fd)
        return
    end

    agent:send_packet(name, packet)
end

function WEBSOCKET_D:recv_agent (fd, message)
    local agent = webAgents[fd]
    if not agent then
        return
    end

    if agent:get_client_fd() ~= fd then
        WEBSOCKET_D:close_agent(fd)
        return
    end

    agent:recv_message(message)
end

function WEBSOCKET_D:broadcast_agents (fds, name, packet)
    if fds == 0 then
        for fd, _ in pairs (webAgents) do
            WEBSOCKET_D:send_agent(fd, name, packet)
        end
    else
        for _, fd in ipairs(fds) do
            WEBSOCKET_D:send_agent(fd, name, packet)
        end
    end
end

function WEBSOCKET_D:get_agent_num ()
    return table.nums(webAgents)
end

function WEBSOCKET_D:get_all_agents ()
    return webAgents
end
