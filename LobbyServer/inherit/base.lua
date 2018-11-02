-------------------------------------------------------------
---! @file
---! @brief 基础对象
-------------------------------------------------------------

---! 模块
local BASE_OB = class ("BASE_OB")

function BASE_OB:ctor ()
    OBJECT_D:register_object(self)
end

function BASE_OB:set_id (id)
    assert(type(id) == "number")
    self._id = id
end

function BASE_OB:get_id ()
    return tonumber(self._id)
end

function BASE_OB:destroy ()
    OBJECT_D:destroy_object(self)
end

ttd.exports.BASE_OB = BASE_OB
