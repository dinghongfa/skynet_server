-------------------------------------------------------------
---! @file
---! @brief 对象管理
-------------------------------------------------------------

---! 自增Id
local _object_id = 1000

---! 映射表
local _object_map = {}
local _object_iid = {}

---! 模块
ttd.exports.OBJECT_D = {}

---! 获取Id
function OBJECT_D:get_id ()
    _object_id = _object_id + 1
    return _object_id
end

---! 注册对象
function OBJECT_D:register_object (obj)
    assert(iskindof(obj, "BASE_OB"))

    _object_id = _object_id + 1
    _object_map[_object_id] = obj

    if type(obj.set_id) == "function" then
        obj:set_id(_object_id)
    end

    if type(obj.get_iid) == "function" then
        local iid = obj:get_iid()
        _object_iid[iid] = obj
    end
end

---! 销毁对象
function OBJECT_D:destroy_object (obj)
    assert(iskindof(obj, "BASE_OB"))

    if type(obj.get_id) == "function" then
        local id = obj:get_id()
        _object_map[id] = nil
    end

    if type(obj.get_iid) == "function" then
        local iid = obj:get_iid()
        _object_iid[iid] = nil
    end
end

---! 通过 id 获取对象
function OBJECT_D:get_object_by_id (id)
    local obj = _object_map[id]
    return obj
end

---! 通过 iid 获取对象
function OBJECT_D:get_object_by_iid (iid)
    local obj = _object_iid[iid]
    return obj
end

---! 调试接口1
function OBJECT_D:query_object_map ()
    return _object_map
end

---! 调试接口2
function OBJECT_D:query_object_iid ()
    return _object_iid
end
