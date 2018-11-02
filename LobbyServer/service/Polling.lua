-------------------------------------------------------------
---! @file
---! @brief 数据挖掘
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"
require "skynet.manager"	-- import skynet.launch, ...
local mysql_proxy = require "module.mysql_proxy"
local uuid = require "uuid"

---! 时区
local now_time = os.time()
local utc8_time = 8 * 3600 + os.time(os.date("!*t", now_time)) - now_time

---! 数据采集
local function polling (save_path, save_data)
    if type(save_data) ~= "table" then
        return
    end

    ---! 获取当前时间
    local ntime = os.time()

    ---! 设置当前服务器时间
    if not save_data.ctime then
        save_data.ctime = os.date("%Y-%m-%d %H:%M:%S", ntime)
    end

    ---! 设置当前东八区时间
    if not save_data.ctime_utc8 then
        save_data.ctime_utc8 = os.date("%Y-%m-%d %H:%M:%S", ntime + utc8_time)
    end

    ---! 设置唯一编码
    if not save_data.id then
        save_data.id = uuid.hex()
    end

    ---! 写入数据库
    local col_names = {}
    local col_values = {}
    for col_name, col_value in pairs (save_data) do
        table.insert(col_names, col_name)
        table.insert(col_values, col_value)
    end
    local keys = table.concat(col_names, "`, `")
    local vals = table.concat(col_values, "', '")
    local cmd  = string.format("REPLACE %s (`%s`) VALUES ('%s');", save_path, keys, vals)
    local ret  = mysql_proxy.call(cmd)
    return ret
end

---! 启动函数
skynet.start(function(...)
    ---! 注册skynet消息服务
    skynet.dispatch("lua", function(_, _, cmd, ...)
        assert(cmd == "polling")
        skynet.retpack(polling(...))
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
