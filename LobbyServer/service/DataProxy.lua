-------------------------------------------------------------
---! @file  HallCenter
---! @brief 数据管理服务
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"
require "skynet.manager"	-- import skynet.launch, ...
local mongo_proxy = require "module.mongo_proxy"

---! 消息
local CMD = {}

---! 启动函数
skynet.start(function(...)
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("unknown command ", cmd)
        end
    end)

    ---! 加载配置
    local clsHelper = require "ClusterHelper"
    local config = clsHelper.load_config("./config/config.mongo")
    conf = config.DB_Conf

    ---! 主动触发链接
    mongo_proxy.open(conf)

    ---! 启动成功
    skynet.register(SERVICE_NAME)
end)

CMD.genId = function ()
    return mongo_proxy.genId()
end

CMD.find_one = function (collection, query, selector)
    return mongo_proxy.find_one(collection, query, selector)
end

CMD.find_all = function (collection, query, selector, sort_selector, limit_selector)
    local docs = mongo_proxy.find_all(collection, query, selector)

    if sort_selector then
        sort_selector = table.unpack(sort_selector)
        docs = docs:sort(sort_selector)
    end

    if limit_selector then
        docs = docs:limit(limit_selector)
    end

    local data = {}
    while docs:hasNext() do
        table.insert(data, docs:next())
    end
    return data
end

CMD.insert = function (collection, doc)
    return mongo_proxy.insert(collection, doc)
end

CMD.batch_insert = function (collection, docs)
    return mongo_proxy.batch_insert(collection, docs)
end

CMD.update = function (collection, selector, update, upsert, multi)
    mongo_proxy.update(collection, selector, update, upsert, multi)
end

CMD.delete = function (collection, selector, single)
    return mongo_proxy.delete(collection, selector, single)
end
