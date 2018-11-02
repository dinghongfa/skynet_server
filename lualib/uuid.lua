local skynet = require "skynet"

---! [[uuid format : (32bits timestamp)(6bits machine)(16bits service)(10bits sequence)]]
local uuid = {}

---! 2018 / 10 / 01
local scale = os.time({ day = 1, month = 10, year = 2018, })

local timestamp
local service
local sequence
function uuid.gen ()
    if not service then
        local self = skynet.self()
        local harbor = skynet.harbor(self)
        service = ((harbor & 0x3f) << 25) | ((self & 0xffff) << 10)
    end

    if not timestamp then
        timestamp = os.time() - scale
        timestamp = (timestamp << 32) | service
        sequence = 0
        skynet.timeout (100, function ()
            timestamp = nil
        end)
    end

    sequence = sequence + 1
    assert (sequence <= 0x3ff)

    return (timestamp | sequence)
end

function uuid.hex (id)
    local id = id or uuid.gen()
    return string.format("%X", id)
end

function uuid.split (id)
    local ts = (id >> 32) + scale
    local harbor   = (id & 0xffffffff) >> 25
    local service  = (id & 0x1ffffff) >> 10
    local sequence = id & 0x3ff
    return ts, harbor, service, sequence
end

return uuid
