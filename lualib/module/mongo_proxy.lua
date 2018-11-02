
---! 依赖库
local skynet    = require "skynet"
local mongo     = require "skynet.db.mongo"

---! 常量
local conf
local mongo_conn
local wait_list = {}

---! 模块
local mongo_proxy = {}

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
local function do_make_mongo_conn ()
    local first = {
        host = conf.host,
        port = conf.port or 27017,
        username = conf.user,
        password = conf.password,
        authdb = conf.database,
    }

    local db = mongo.client(first)
    if db then
        if mongo_conn then
            mongo_conn:disconnect()
        end
        mongo_conn = db[first.authdb]
        resume()
        skynet.error("success connect to mongo ", conf.host, conf.port)
        return true
    else
        skynet.error("can't connect to mongo ", conf.host, conf.port)
    end
end

---! 连接到数据库
local function make_mongo_conn ()
    if mongo_conn then
        return
    end

    local ret
    repeat
        ret = pcall(do_make_mongo_conn)
        if ret then
            break
        end
        skynet.sleep(100)
    until ret
end

---! mongo数据库连接不正常，暂停
local function connect ()
    skynet.fork(make_mongo_conn)
    local co = coroutine.running()
    table.insert(wait_list, co)
    skynet.wait(co)
end

---! checked call sql cmd
function mongo_proxy.checked_call (cmd, ...)
    while true do
        if not mongo_conn then
            connect()
        end
        local ret, val = pcall(mongo_conn[cmd], mongo_conn, ...)
        if ret then
            return val
        end
        mongo_conn:disconnect()
        mongo_conn = nil
    end
end

---! alias
mongo_proxy.call = mongo_proxy.checked_call

---!
function mongo_proxy.genId ()
    return mongo_proxy.call("genId")
end

---!
function mongo_proxy.find_one (collection, query, selector)
    local col = mongo_proxy.call("getCollection", collection)
    local ret = col:findOne(query, selector)
    return ret
end

---!
function mongo_proxy.find_all (collection, query, selector)
    local col = mongo_proxy.call("getCollection", collection)
    return col:find(query, selector)
end

---!
function mongo_proxy.insert (collection, doc)
    local col = mongo_proxy.call("getCollection", collection)
    local ok, err, ret = col:safe_insert(doc)
    assert(ok and ret and ret.n == 1, err)
    return ok, err, ret
end

---!
function mongo_proxy.batch_insert (collection, docs)
    local col = mongo_proxy.call("getCollection", collection)
    col:batch_insert(docs)
end

---!
function mongo_proxy.update (collection, selector, update, upsert, multi)
    local col = mongo_proxy.call("getCollection", collection)
    local ok, err, ret = col:safe_update(selector, update, upsert, multi)
    return ok, err, ret
end

---!
function mongo_proxy.delete (collection, selector, single)
    local col = mongo_proxy.call("getCollection", collection)
    local ok, err, ret = col:safe_delete(selector, single)
    return ok, err, ret
end

---! open
function mongo_proxy.open (_conf)
    conf = _conf
    connect()
end

---! close
function mongo_proxy.close ()
    if mongo_conn then
        mongo_conn:disconnect()
        mongo_conn = nil
    end
end

---! 导出模块
return mongo_proxy
