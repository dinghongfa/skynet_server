local skynet = require "skynet"
local core   = require "skynet.core"
local snax   = require "skynet.snax"
local socket = require "skynet.socket"
local memory = require "skynet.memory"
local codecache = require "skynet.codecache"

local COMMAND = {}
local COMMANDX = {}

local function format_table(t)
    local index = {}
    for k in pairs(t) do
        table.insert(index, k)
    end
    table.sort(index, function(a, b) return tostring(a) < tostring(b) end)
    local result = {}
    for _,v in ipairs(index) do
        table.insert(result, string.format("%s:%s",v,tostring(t[v])))
    end
    return table.concat(result,"\t")
end

local function dump_line(print, key, value)
    if type(value) == "table" then
        print(key, format_table(value))
    else
        print(key, tostring(value))
    end
end

local function dump_list(print, list)
    local index = {}
    for k in pairs(list) do
        table.insert(index, k)
    end
    table.sort(index, function(a, b) return tostring(a) < tostring(b) end)
    for _,v in ipairs(index) do
        dump_line(print, v, list[v])
    end
end

local function split_cmdline(cmdline)
    local split = {}
    for i in string.gmatch(cmdline, "%S+") do
        table.insert(split,i)
    end
    return split
end

local function docmd(cmdline, fd)
    local split = split_cmdline(cmdline)
    local command = split[1]
    local cmd = COMMAND[command]
    local ok, list
    if cmd then
        printf("<CMD %s>", cmdline)
        ok, list = pcall(cmd, table.unpack(split,2))
    else
        cmd = COMMANDX[command]
        if cmd then
            printf("<CMDX %s>", cmdline)
            split.fd = fd
            split[1] = cmdline
            ok, list = pcall(cmd, split)
        else
            print("Invalid command, type help for command list")
            return
        end
    end

    if ok then
        if list then
            if type(list) == "table" then
                dump_list(print, list)
            else
                print(list)
            end
        end
        print("<CMD OK>")
    else
        print(list)
        print("<CMD Error>")
    end
end

local function console_main_loop()
    local stdin = socket.stdin()
    while true do repeat
        local cmdline = socket.readline(stdin, "\n")
        if not cmdline then
            break
        end

        if cmdline ~= "" then
            docmd(cmdline, stdin)
        end
    until true end
end

skynet.start(function()
    skynet.fork(console_main_loop)
end)

local function adjust_address(address)
    local prefix = address:sub(1,1)
    if prefix == '.' then
        return assert(skynet.localname(address), "Not a valid name")
    elseif prefix ~= ':' then
        address = assert(tonumber("0x" .. address), "Need an address") | (skynet.harbor(skynet.self()) << 24)
    end
    return address
end

local function toboolean(x)
    return x and (x == "true" or x == "on")
end

local function bytes(size)
    if size == nil or size == 0 then
        return
    end
    if size < 1024 then
        return size
    end
    if size < 1024 * 1024 then
        return tostring(size/1024) .. "K"
    end
    return tostring(size/(1024*1024)) .. "M"
end

local function convert_stat(info)
    local now = skynet.now()
    local function time(t)
        if t == nil then
            return
        end
        t = now - t
        if t < 6000 then
            return tostring(t/100) .. "s"
        end
        local hour = t // (100*60*60)
        t = t - hour * 100 * 60 * 60
        local min = t // (100*60)
        t = t - min * 100 * 60
        local sec = t / 100
        return string.format("%s%d:%.2gs",hour == 0 and "" or (hour .. ":"),min,sec)
    end

    info.address = skynet.address(info.address)
    info.read = bytes(info.read)
    info.write = bytes(info.write)
    info.wbuffer = bytes(info.wbuffer)
    info.rtime = time(info.rtime)
    info.wtime = time(info.wtime)
end

function COMMAND.help()
    local instructions = {
        help = "This help message",
        list = "List all the service",
        stat = "Dump all stats",
        info = "info address : get service infomation",
        exit = "exit address : kill a lua service",
        kill = "kill address : kill service",
        mem = "mem : show memory status",
        gc = "gc : force every lua service do garbage collect",
        start = "lanuch a new lua service",
        snax = "lanuch a new snax service",
        clearcache = "clear lua code cache",
        service = "List unique service",
        task = "task address : show service task detail",
        inject = "inject address luascript.lua",
        logon = "logon address",
        logoff = "logoff address",
        log = "launch a new lua service with log",
        signal = "signal address sig",
        cmem = "Show C memory info",
        shrtbl = "Show shared short string table info",
        ping = "ping address",
        call = "call address ...",
        trace = "trace address [proto] [on|off]",
        netstat = "netstat : show netstat",
        eval = "eval address lua code",
    }

    for key, value in pairs(instructions) do
        printf("%-10s - %s", key, value)
    end
end

function COMMAND.list()
    return skynet.call(".launcher", "lua", "LIST")
end

function COMMAND.stat()
    return skynet.call(".launcher", "lua", "STAT")
end

function COMMAND.info(address, ...)
    if not address then
        address = skynet.queryservice("NodeStat")
        return skynet.call(address, "debug", "INFO", ...)
    end

    address = adjust_address(address)
    return skynet.call(address, "debug", "INFO", ...)
end

function COMMAND.exit(address, ...)
    skynet.send(adjust_address(address), "debug", "EXIT")
end

function COMMAND.kill(address)
    return skynet.call(".launcher", "lua", "KILL", address)
end

function COMMAND.mem()
    return skynet.call(".launcher", "lua", "MEM")
end

function COMMAND.gc()
    return skynet.call(".launcher", "lua", "GC")
end

function COMMAND.start(...)
    local ok, addr = pcall(skynet.newservice, ...)
    if ok then
        if addr then
            return { [skynet.address(addr)] = ... }
        else
            return "Exit"
        end
    else
        return "Failed"
    end
end

function COMMAND.snax(...)
    local ok, s = pcall(snax.newservice, ...)
    if ok then
        local addr = s.handle
        return { [skynet.address(addr)] = ... }
    else
        return "Failed"
    end
end

function COMMAND.clearcache()
    codecache.clear()
end

function COMMAND.service()
    return skynet.call("SERVICE", "lua", "LIST")
end

function COMMAND.task(address)
    address = adjust_address(address)
    return skynet.call(address,"debug","TASK")
end

function COMMAND.inject(address, filename, ...)
    address = adjust_address(address)
    local f = io.open(filename, "rb")
    if not f then
        return "Can't open " .. filename
    end
    local source = f:read "*a"
    f:close()
    local ok, output = skynet.call(address, "debug", "RUN", source, filename, ...)
    if ok == false then
        error(output)
    end
    return output
end

function COMMAND.logon(address)
    address = adjust_address(address)
    core.command("LOGON", skynet.address(address))
end

function COMMAND.logoff(address)
    address = adjust_address(address)
    core.command("LOGOFF", skynet.address(address))
end

function COMMAND.log(...)
    local ok, addr = pcall(skynet.call, ".launcher", "lua", "LOGLAUNCH", "snlua", ...)
    if ok then
        if addr then
            return { [skynet.address(addr)] = ... }
        else
            return "Failed"
        end
    else
        return "Failed"
    end
end

function COMMAND.signal(address, sig)
    address = skynet.address(adjust_address(address))
    if sig then
        core.command("SIGNAL", string.format("%s %d",address,sig))
    else
        core.command("SIGNAL", address)
    end
end

function COMMAND.cmem()
    local info = memory.info()
    local tmp = {}
    for k,v in pairs(info) do
        tmp[skynet.address(k)] = v
    end
    tmp.total = memory.total()
    tmp.block = memory.block()

    return tmp
end

function COMMAND.shrtbl()
    local n, total, longest, space = memory.ssinfo()
    return { n = n, total = total, longest = longest, space = space }
end

function COMMAND.ping(address)
    address = adjust_address(address)
    local ti = skynet.now()
    skynet.call(address, "debug", "PING")
    ti = skynet.now() - ti
    return tostring(ti)
end

function COMMANDX.call(cmd)
    local address = adjust_address(cmd[2])
    local cmdline = assert(cmd[1]:match("%S+%s+%S+%s(.+)") , "need arguments")
    local args_func = assert(load("return " .. cmdline, "debug console", "t", {}), "Invalid arguments")
    local args = table.pack(pcall(args_func))
    if not args[1] then
        error(args[2])
    end
    local rets = table.pack(skynet.call(address, "lua", table.unpack(args, 2, args.n)))
    return rets
end

function COMMAND.trace(address, proto, flag)
    address = adjust_address(address)
    if flag == nil then
        if proto == "on" or proto == "off" then
            proto = toboolean(proto)
        end
    else
        flag = toboolean(flag)
    end
    skynet.call(address, "debug", "TRACELOG", proto, flag)
end

function COMMAND.netstat()
    local stat = socket.netstat()
    for _, info in ipairs(stat) do
        convert_stat(info)
    end
    return stat
end

function COMMAND.eval(address, source)
    address = adjust_address(address)
    if not source then
        return "Cant't exec " .. source
    end
    local ok, output = skynet.call(address, "debug", "RUN", source)
    if ok == false then
        error(output)
    end
    return output
end
