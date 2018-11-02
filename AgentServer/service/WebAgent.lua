-------------------------------------------------------------
---! @file
---! @brief web socket的客户连接
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"
local socket = require "skynet.socket"
local queue  = require "skynet.queue"
local websocket = require "utils.websocket"

---! 变量
local client_fd
local client_addr
local client_srv
local client_sock
local critical = queue()

---! 接口
local handler = {}

function handler.on_open (ws)
    if not client_fd or not client_srv then
        return
    end

    pcall(skynet.send, client_srv, "lua", "openAgent", client_fd)
end

function handler.on_message (ws, msg)
    if not client_fd or not client_srv then
        return
    end

    xpcall( function()
        critical(function ()
            pcall(skynet.send, client_srv, "lua", "recvFromAgent", client_fd, msg)
        end)
    end,
    function(err)
        skynet.error(err)
        skynet.error(debug.traceback())
    end)
end

function handler.on_error (ws, err)
    printf("on_error : %s from %s", err, client_addr)

    if not client_fd or not client_srv then
        return
    end

    pcall(skynet.send, client_srv, "lua", "closeAgent", client_fd)
end

function handler.on_close (ws, code, reason)
    if not client_fd or not client_srv then
        return
    end

    pcall(skynet.send, client_srv, "lua", "closeAgent", client_fd)
end

---! 消息
local CMD = {}

function CMD.start (srv, fd, addr, header)
    if client_sock then
        return false
    end

    socket.start(fd)
    pcall(function ()
        client_sock = websocket.new(fd, header, handler)
    end)
    if not client_sock then
        return false
    end
    skynet.fork(client_sock.start, client_sock)

    client_fd   = fd
    client_addr = addr
    client_srv  = srv
    return true
end

function CMD.send_packet (srv, packet)
    if not client_sock then
        return
    end

    client_sock:send_binary(packet)
end

function CMD.disconnect (srv)
    if client_sock then
        client_sock:close()
        client_sock = nil
    end

    skynet.exit()
end

---! 启动函数
skynet.start(function()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_, srv, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(srv, ...))
        else
            skynet.error(string.format("Invalid command %s from %s", cmd, skynet.address(srv)))
        end
    end)
end)
