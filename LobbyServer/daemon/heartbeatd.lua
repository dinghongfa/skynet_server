-------------------------------------------------------------
---! @file
---! @brief 心跳管理
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 常量
local timeout = 30 -- 30 second

---! 模块
ttd.exports.HEART_BEAT_D = {}

---! 触发心跳
function HEART_BEAT_D:active(clientAddr, clientFd)
    local userOb = LOGIN_D:find_user(clientAddr, clientFd)
    if not userOb then
        return
    end
    if userOb:is_robot() then
        return
    end

    ---! 获取上次更新时间
    local lastUpdateTime = userOb:query_temp("last_update_time")

    ---! 获取当前时间
    local nowTime = os.time()

    ---! 设置当前更新时间
    userOb:set_temp("last_update_time", nowTime)

    ---!
    ----////todo:做一些每日更新数据等操作
end

---! 守护线程
function HEART_BEAT_D:daemon()
    while true do
        if self ~= HEART_BEAT_D then
            break
        end

        ---! 获取当前时间
        local nowTime = os.time()

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

        ---! 遍历所有在线玩家
        lume.each(USER_D:get_all_users(), function (userOb)
            if userOb:is_robot() then
                ---! 机器人不处理
                return
            end

            ---! 获取上次更新时间
            local lastUpdateTime = userOb:query_temp("last_update_time")
            if not lastUpdateTime then
                ---! 刚刚上线被加载
                userOb:set_temp("last_update_time", nowTime)
                return
            end

            if nowTime - lastUpdateTime > timeout then
                ---! 当前玩家已超时
                userOb:save()

                ---! 执行下线处理
                userOb:logout()
            end
        end)

        ---! 30 second 后再检查一次
        skynet.sleep(timeout * 100)
    end
end

---! 启动协程
skynet.timeout(timeout * 100, HEART_BEAT_D.daemon, HEART_BEAT_D)
