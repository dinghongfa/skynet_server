
---!
local skynet      = require "skynet"
require "skynet.manager"	-- import skynet.launch, ...
local mysql_proxy = require "module.mysql_proxy"

---! static mysql format
local sql_format = "SELECT * FROM `lbb_user` WHERE uid = '%s' LIMIT 1;"

---! skynet service handlings
local CMD = {}

---! load all from table
function CMD.load_user (uid)
    local sql_cmd = string.format(sql_format, uid)
    printf("exec sql cmd : %s", sql_cmd)

    local ret = mysql_proxy.call(sql_cmd)
    if type(ret) ~= "table" then
        return
    end

    if lume.count(ret) <= 0 then
        return
    end

    local row = ret[1]
    if type(row) ~= "table" then
        return
    end

    return row
end

---! 服务的启动函数
skynet.start(function()
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            skynet.error("unknown command ", cmd)
        end
    end)

    ---! 加载配置
    local clsHelper = require "ClusterHelper"
    local config = clsHelper.load_config("./config/config.mysql")
    conf = config.DB_Conf
    conf.on_connect = function (db)
        db:query("set charset utf8");
    end

    ---! 主动触发链接
    mysql_proxy.open(conf)

    ---! 启动成功
    skynet.register(SERVICE_NAME)
end)
