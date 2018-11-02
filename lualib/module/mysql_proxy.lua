
---! 依赖库
local skynet    = require "skynet"
local mysql     = require "skynet.db.mysql"

---! 常量
local conf
local mysql_conn
local wait_list = {}

---! 模块
local mysql_proxy = {}

---! 恢复之前的执行序列
local function resume ()
    while true do
        local co = table.remove(wait_list)
        if not co then
            return
        end
        skynet.wakeup(co)
    end
end

---! do make
local function do_make_mysql_conn ()
    local db = mysql.connect(conf)
    if db then
        if mysql_conn then
            mysql_conn:disconnect()
        end
        mysql_conn = db
        resume()
        skynet.error("success connect to mysql ", conf.host, conf.port)
        return true
    else
        skynet.error("can't connect to mysql ", conf.host, conf.port)
    end
end

---! 连接到数据库
local function make_mysql_conn ()
    if mysql_conn then
        return
    end

    local ret
    repeat
        ret = pcall(do_make_mysql_conn)
        if ret then
            break
        end
        skynet.sleep(100)
    until ret
end

---! mysql数据库连接不正常，暂停
local function connect ()
    skynet.fork(make_mysql_conn)
    local co = coroutine.running()
    table.insert(wait_list, co)
    skynet.wait(co)
end

---! checked call sql cmd
function mysql_proxy.checked_call (cmd)
    while true do
        if not mysql_conn then
            connect()
        end
        local ret, val = pcall(mysql_conn.query, mysql_conn, cmd)
        if not ret then
            mysql_conn:disconnect()
            mysql_conn = nil
            connect()
        else
            return val
        end
    end
end

---! alias
mysql_proxy.call = mysql_proxy.checked_call

---! open
function mysql_proxy.open (_conf)
    conf = _conf
    connect()
end

---! close
function mysql_proxy.close ()
    if mysql_conn then
        mysql_conn:disconnect()
        mysql_conn = nil
    end
end

---! 导出模块
return mysql_proxy
