-------------------------------------------------------------
---! @file
---! @brief 引导模块管理
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 时区
local now_time = os.time()
local utc8_time = 8 * 3600 + os.time(os.date("!*t", now_time)) - now_time

---! 记录关服时间
local shut_down_time

---! 模块
ttd.exports.BOOT_D = {}

---! 关闭服务器
function BOOT_D:shut_down ()
    shut_down_time = os.time()

    repeat
        ---! 获取正在加载玩家
        local load_users = USER_D:get_all_load_users()
        local load_count = lume.count(load_users)
        if load_count <= 0 then
            break
        end

        printf("now load_users count = %s, must wait load finish...", load_count)
        skynet.sleep(100)
    until false

    ---! 遍历所有在线玩家
    lume.each(USER_D:get_all_users(), function (userOb)
        if userOb:is_robot() then
            ---! 机器人不处理
            return
        end

        ---! 执行下线处理
        userOb:logout()
    end)

    ---! 遍历所有临时玩家
    lume.each(USER_D:get_all_temp_users(), function (userOb)
        if userOb:is_robot() then
            ---! 机器人不处理
            return
        end

        ---! 保存当前玩家数据
        userOb:save()

        ---! 销毁当前玩家对象
        userOb:destroy()
    end)

    ---! 执行后台指令
    os.execute("sh stop.sh")
end

---! 正在关闭服务器
function BOOT_D:is_shut_down ()
    if shut_down_time then
        return
    end

    shut_down_time = os.time()
end

---! 显示节点信息
local function dump_info ()
    ---! 获取所有在线玩家
    local users =  USER_D:get_all_users()

    ---! 获取所有临时玩家
    local temp_users = USER_D:get_all_temp_users()

    local info = {}
    info.online_user_count = lume.count(users)
    lume.each(users, function (user)
        local update_time = user:query_temp("last_update_time") or os.time()
        local user_id = user:get_user_id()

        info[string.format("online user_id:%s", user_id)] = {
            user_name = user:get_user_name(),
            update_time = os.date("%Y-%m-%d %H:%M:%S", update_time + utc8_time),
        }
    end)

    info.temp_user_count = lume.count(temp_users)
    lume.each(temp_users, function (user)
        local user_id = user:get_user_id()

        info[string.format("temp user_id:%s", user_id)] = {
            user_name = user:get_user_name(),
        }
    end)
    return info
end

skynet.info_func(dump_info)
