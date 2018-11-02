-------------------------------------------------------------
---! @file
---! @brief 登录管理
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 映射表
local clients_map = {}

---! 模块
ttd.exports.LOGIN_D = {}

---! 登录
function LOGIN_D:login (clientAddr, clientFd, userId, loginInfo)
    local clientId = string.format("%s@%s", clientFd, clientAddr)
    printf("client [%s] try do login user [%s].", clientId, userId)

    ---! 查找用户对象
    local userOb = USER_D:find_user(userId)
    if not userOb then
        ---! 对象尚未加载，需要做防重入处理，避免多次加载对象
        if USER_D:is_loading(userId) then
            printf("user [%s] is loading...", userId)
            return
        end

        ---! 开始加载对象
        userOb = USER_D:load_user(userId)
        if not userOb then
            printf("user [%s] load failed.", userId)
            return
        end

        ----/////todo:
        userOb:set_user_id(userId)

        ---! 设置客户端ID
        userOb:set_client_id(clientId)

        ---! 设置登录信息
        userOb:set_login_info(loginInfo)

        ---! 安排进入游戏
        USER_D:enter_world(userOb)
    else
        if userOb:get_client_id() ~= clientId then
            ---! 断开之前连接
            userOb:disconnect()

            ---! 设置客户端ID
            userOb:set_client_id(clientId)

            ---! 设置登录信息
            userOb:set_login_info(loginInfo)

            ---! 重新进入游戏
            USER_D:reconnect(userOb)
        end
    end

    ---! 记录登录成功的玩家对象
    clients_map[clientId] = userOb
    return true
end

---! 登出
function LOGIN_D:logout (userOb)
    local clientId = userOb:get_client_id()
    if clientId then
        ---! 尝试断开连接
        userOb:disconnect()

        ---! 清理映射关系
        clients_map[clientId] = nil
        userOb:delete_temp("clientId")
    end

    ---! 安排离开游戏
    USER_D:leave_world(userOb)
end

---! 查找指定玩家
function LOGIN_D:find_user (clientAddr, clientFd)
    local clientId = string.format("%s@%s", clientFd, clientAddr)
    local userOb = clients_map[clientId]
    if userOb then
        return userOb
    end
end

---! 断开连接
function LOGIN_D:disconnect (clientAddr, clientFd)
    printf("client [%s] to do disconnect", string.format("%s@%s", clientFd, clientAddr))
    local clientId = string.format("%s@%s", clientFd, clientAddr)
    local userOb = clients_map[clientId]
    if userOb then
        userOb:delete_temp("clientId")
    end
    clients_map[clientId] = nil
end

---! 调试接口
function LOGIN_D:query_clients_map ()
    return clients_map
end
