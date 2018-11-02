-------------------------------------------------------------
---! @file
---! @brief 数据管理
-------------------------------------------------------------

---! 依赖
local skynet = require "skynet"

---! 模块
ttd.exports.DATABASE_D = {}

---! 数据加载
function DATABASE_D:load (obj)
    assert(iskindof(obj, "BASE_OB"))
    assert(type(obj.get_save_path) == "function")

    local save_path = obj:get_save_path()
    assert(type(save_path) == "string", "type of save_path must be string.")
    assert(#save_path > 0, "save_path can't be empty string.")

    local dbase = skynet.call("DataProxy", "lua", "find_one", save_path, obj:get_selector(), { _id = 0, })

    if dbase then
        obj:set_entire_dbase(dbase)
    end

    if type(obj.repair_entire_dbase) == "function" then
        obj:repair_entire_dbase()
    end

    return true
end

---! 数据保存
function DATABASE_D:save (obj)
    assert(iskindof(obj, "BASE_OB"))
    assert(type(obj.get_save_path) == "function")

    local save_path = obj:get_save_path()
    assert(type(save_path) == "string", "type of save_path must be string.")
    assert(#save_path > 0, "save_path can't be empty string.")

    skynet.call("DataProxy", "lua", "update", save_path, obj:get_selector(), {["$set"] = obj:query_entire_dbase()}, true)
end

---! 读取全局
function DATABASE_D:load_global (path)
    local ret = skynet.call("DataProxy", "lua", "find_one", "lbb_global", {path = path}, {value = 1, _id = 0})
    if type(ret) ~= "table" then
        return
    end
    return ret.value
end

---! 保存全局
function DATABASE_D:save_global (path, value)
    local ok = skynet.call("DataProxy", "lua", "update", "lbb_global", {path = path}, {["$set"] = {value=value}}, true)
    return ok
end
