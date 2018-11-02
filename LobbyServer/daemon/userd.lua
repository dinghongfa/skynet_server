-------------------------------------------------------------
---! @file
---! @brief 用户管理
-------------------------------------------------------------

local skynet = require "skynet"

---! 映射表
local load_map = {}     ---! 正在加载的玩家对象
local user_map = {}     ---! 已经加载的玩家对象
local temp_map = {}     ---! 临时缓存的玩家对象

---! 等待列表
local wait_list = {}

---! 模块
ttd.exports.USER_D = {}

---! 查找对象
function USER_D:find_user (userId)
    local userOb = user_map[userId]
    if userOb then
        return userOb
    end
end

---! 查找临时对象
function USER_D:find_temp_user (userId)
    local userOb = temp_map[userId]
    if userOb then
        return userOb
    end
end

---! 查找或临时加载对象
function USER_D:find_load_user (userId)
    local userOb
    local co = coroutine.running()
    USER_D:call_user(userId, function (loadOb)
        userOb = loadOb
        skynet.wakeup(co)
    end)
    skynet.wait(co)
    return userOb
end

---! 判断对象是否存在
function USER_D:is_exits_user (userId)
    local userOb = USER_D:find_load_user(userId)
    if not userOb then
        return false
    end
    return true
end

---! 对指定对象执行方法
function USER_D:call_user (userId, fn)
    if not userId then
        return
    end

    if type(userId) ~= "string" then
        return
    end

    if #userId <= 0 then
        return
    end

    skynet.fork(function ()
        if USER_D:is_loading(userId) then
            ---! 目标玩家正在加载数据
            local co = coroutine.running()
            wait_user_list = wait_list[userId] or {}
            table.insert(wait_user_list, co)
            wait_list[userId] = wait_user_list
            skynet.wait(co)
        end

        local userOb = USER_D:find_user(userId)
        if userOb then
            pcall(fn, userOb)
            return
        end

        local userOb = USER_D:load_user(userId)
        if userOb then
            pcall(fn, userOb)
            return
        end
    end)
end

---! 判断是否正在加载
function USER_D:is_loading (userId)
    if load_map[userId] then
        return true
    end
    return false
end

local function _load_user (userId)
    ---! 临时对象
    local userOb = temp_map[userId]
    if userOb then
        return userOb
    end

    ---! 创建对象
    local userOb = USER_OB:create()

    ---! 设置查询
    userOb:set_selector({ userId = userId, })

    ---! 加载数据
    local ok = userOb:load()
    if not ok then
        return
    end

    ---! 记录对象
    temp_map[userId] = userOb

    ---! 返回对象
    return userOb
end

---! 加载对象
function USER_D:load_user (userId)
    if  BOOT_D:is_shut_down() then
        return
    end

    ---! 获取当前时间
    local now = os.time()

    ---! 设置加载状态
    load_map[userId] = now

    ---! 开始加载对象
    printf("user [%s] start load ...", userId)
    local userOb = _load_user(userId)
    printf("user [%s] load cost time = %s", userId, os.time() - now)

    ---! 解除加载状态
    load_map[userId] = nil

    ---! 释放所有回调
    if wait_list[userId] then
        local wait_user_list = wait_list[userId]
        wait_list[userId] = nil

        lume.each(wait_user_list, function (co)
            skynet.wakeup(co)
        end)
    end

    ---! 返回对象
    return userOb
end

---! 销毁对象
function USER_D:destroy_user (userOb)
    local userId = userOb:get_user_id()
    user_map[userId] = nil
    temp_map[userId] = nil
    userOb:set_temp("destroy", os.time())
end

---! 进入游戏
function USER_D:enter_world (userOb)
    local userId = userOb:get_user_id()

    user_map[userId] = userOb
    temp_map[userId] = nil

    ---/// todo: login_log
    if userOb:is_robot() then
        printf(">>>> robot %s enter world succ.", userId)
    else
        printf(">>>> user %s enter world succ.", userId)
    end
end

---! 离开游戏
function USER_D:leave_world (userOb)
    local userId = userOb:get_user_id()
    user_map[userId] = nil
    temp_map[userId] = userOb

    ---/// todo: login_log
    if userOb:is_robot() then
        printf(">>>> robot %s leave world succ.", userId)
    else
        printf(">>>> user %s leave world succ.", userId)
    end
end

---! 重连游戏
function USER_D:reconnect (userOb)
    local userId = userOb:get_user_id()

    ---/// todo: login_log
    printf(">>>> user %s reconnect world succ.", userId)
end

---! 断开游戏
function USER_D:disconnect (userOb)
    local userId = userOb:get_user_id()

    ---! 顶号退出
    userOb:send("user.LogoutRep", { type = 1, })

    ---/// todo: login_log
    printf(">>>> user %s disconnect world succ.", userId)
end

---! 获取所有在线玩家
function USER_D:get_all_users ()
    return user_map
end

---! 获取所有临时玩家
function USER_D:get_all_temp_users ()
    return temp_map
end

---! 获取所有加载玩家
function USER_D:get_all_load_users ()
    return load_map
end

---! 发送玩家信息
function USER_D:send_user_info (me, userId)
    local userOb = USER_D:find_user(userId)
    if not userOb then
        return
    end

    local userInfo = {}
    userInfo.uid      = userOb:get_user_id()
    userInfo.nickname = userOb:get_user_name()
    userInfo.portrait = userOb:get_user_portrait()
    userInfo.wallet   = userOb:get_wallet_info()
    userOb:send("user.UserInfoRep", userInfo)
end

---! 发送系统广播
function USER_D:broascat_system_notice (message, parameters)
    lume.each(user_map, function (userOb)
        userOb:send_notice(ttd.CHANNEL_SYSTEM, message, parameters)
    end)
end
