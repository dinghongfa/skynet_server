-------------------------------------------------------------
---! @file
---! @brief USER_OB
-------------------------------------------------------------

---! 模块
local USER_OB = class("USER_OB", BASE_OB)
table.merge(USER_OB, F_COMN_DBASE)
table.merge(USER_OB, F_COMN_SAVE)
table.merge(USER_OB, F_CHAR_COMM)
table.merge(USER_OB, F_CHAR_WALLET)

function USER_OB:set_user_id (userId)
    return self:set("userId", userId)
end

function USER_OB:get_user_id ()
    return self:query("userId")
end

function USER_OB:get_user_name ()
    if not user_name then
        user_name = self:get_user_id()
    end
    return user_name
end

function USER_OB:get_user_portrait ()
    local portrait = self:query("portrait")
    if not portrait then
        portrait = tostring(math.random(10))
        self:set("portrait", portrait)
    end
    return portrait
end

function USER_OB:repair_entire_dbase ()
    local flag = false

    ---! 创建时间
    if not self:query("create_time") then
        flag = true
        self:set("create_time", os.time())
    end

    ---! 保存数据
    if flag then
        self:save()
    end
end

function USER_OB:get_save_path ()
    return "lbb_user_data"
end

function USER_OB:set_client_id (clientId)
    self:set_temp("clientId", clientId)
end

function USER_OB:get_client_id ()
    return self:query_temp("clientId")
end

function USER_OB:set_login_info (loginInfo)
    self:set_temp("loginInfo", loginInfo)
end

---! 断开连接
function USER_OB:disconnect ()
    USER_D:disconnect(self)
end

---! 登出游戏
function USER_OB:logout ()
    LOGIN_D:logout(self)
end

---! 销毁对象
function USER_OB:destroy ()
    USER_D:destroy_user(self)
    OBJECT_D:destroy_object(self)
end

---! 是否已销毁
function USER_OB:is_destroy ()
    if self:query_temp("destroy") then
        return true
    end
    return false
end

---! 是否是机器人
function USER_OB:is_robot ()
    if not self:query("robot") then
        return false
    end
    return true
end

---! 导出模块
ttd.exports.USER_OB = USER_OB
