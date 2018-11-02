
---! 依赖
local skynet = require "skynet"
local crypt  = require "skynet.crypt"

---! 协议
local protobuf = require "protobuf"
local protocol = require "msgprotocol"

---! 模块
local proto_proxy = {}

---! 初始
function proto_proxy:init (path)
    local path = path or "./proto"
    for _, file in ipairs(attrdir(path)) do repeat
        local ext = getextension(file)
        if ext ~= "pb" then
            break
        end

        protobuf.register_file(file)
        printf("Register pb file : %s OK.", file)
    until true end
end

---! 封包
local function _encode_packet (name, msg)
    local id = protocol[name]
    local buf = protobuf.encode(name, msg)
    local data = string.pack(">Hc" .. #buf, id, buf)
    return data
end

function proto_proxy:encode_packet (name, msg)
    local ok, data = pcall(_encode_packet, name, msg)
    if not ok then
        printf("encode_packet: parse command error, name = %s msg = %s", name, lume.serialize(msg))
        return ok, data
    end
    --[[
    if name ~= "user.HeartbeatReq" then
        printf("encode packet : %s, buf = %s, text = %s", name, crypt.hexencode(data), lume.serialize(msg))
    end
    --]]
    return ok, data
end

---! 解包
local function _decode_packet (data)
    local size = #data - 2
    local id, buf = string.unpack(">Hc" .. tostring(size), data)
    local name = protocol[id]
    local msg = protobuf.decode(name, buf)
    return name, msg
end

function proto_proxy:decode_packet (data)
    local ok, name, msg = pcall(_decode_packet, data)
    if not ok then
        printf("decode_packet: parse command error, buf = %s", crypt.hexencode(data))
        return ok, name, msg
    end
    --[[
    if name ~= "user.HeartbeatRep" then
        printf("decode packet : %s, buf = %s, text = %s", name, crypt.hexencode(data), lume.serialize(msg))
    end
    --]]
    return ok, name, msg
end

---! 退出服务
function proto_proxy:exit_service ()
    skynet.exit()
end

---! 启动服务
function proto_proxy:start_service ()
    local CMD = {}
    setmetatable(CMD, {
        __index = function (tab, key)
            if key == "encode_packet" or key == "decode_packet" then
                return proto_proxy[key]
            end
        end
    })

    ---! 启动函数
    skynet.start(function()
        ---! 注册skynet消息服务
        skynet.dispatch("lua", function(_, _, cmd, ...)
            local f = CMD[cmd]
            if f then
                local ret = table.pack(f(proto_proxy, ...))
                skynet.retpack(ret)
            else
                skynet.error("unknown command ", cmd)
            end
        end)

        skynet.register(SERVICE_NAME)
    end)
end

return proto_proxy
