------------------------------------------------------
---! @file
---! @brief luafilesystem
------------------------------------------------------

---!
local sep = string.match (package.config, "[^\n]+")
local upper = ".."

---!
local lfs = require "lfs"

---! 获取文件名
function getfilename(filename)
    return string.match(filename, ".+/([^/]*%.%w+)$")
end

---! 获取路径
function getpath(filename)
    return string.match(filename, "(.+)/[^/]*%.%w+$")
end

---! 获取扩展名
function getextension(filename)
    return string.match(filename, ".+%.(%w+)$")
end

function attrdir (path)
    local ret = {}
    for file in lfs.dir(path) do
        -- if file ~= "." and file ~= ".." then
        if string.sub(file, 1, 1) ~= "." then
            local f = path..sep..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                table.insertto(ret, attrdir (f))
            else
                table.insert(ret, f)
            end
        end
    end
    return ret
end

function load_all (path)
    local skynet = require "skynet"

    local root = skynet.getenv("app_root")
    for _, filepath in ipairs(attrdir(root .. path)) do
        local loadfile
        local ext = getextension(filepath)
        if ext then
            loadfile = string.sub(filepath, 1, #filepath - #ext - 1)
        else
            loadfile = filepath
        end

        printf("Load file : %s ...", filepath)
        local tick = skynet.time()
        require(string.sub(loadfile, #root + 1))
        local cost = skynet.time() - tick
        printf("Load file : %s OK. cost tick = %s", filepath, cost)
    end
end

function load_all_services (path)
    local skynet = require "skynet"

    local root = skynet.getenv("app_root")
    for _, filepath in ipairs(attrdir(root .. path)) do
        local newservice
        local extension = getextension(filepath)
        local filename  = getfilename(filepath)
        if extension then
            newservice = string.sub(filename, 1, #filename - #extension - 1)
        else
            newservice = filename
        end

        printf("New service : %s ...", filepath)
        local tick = skynet.time()
        skynet.newservice(newservice)
        local cost = skynet.time() - tick
        printf("New service : %s OK. cost tick = %s", filepath, cost)
    end
end

function load_unique_services (path)
    local skynet = require "skynet"

    local root = skynet.getenv("app_root")
    for _, filepath in ipairs(attrdir(root .. path)) do
        local newservice
        local extension = getextension(filepath)
        local filename  = getfilename(filepath)
        if extension then
            newservice = string.sub(filename, 1, #filename - #extension - 1)
        else
            newservice = filename
        end

        printf("New uniqueservice : %s ...", filepath)
        local tick = skynet.time()
        skynet.uniqueservice(newservice)
        local cost = skynet.time() - tick
        printf("New uniqueservice : %s OK. cost tick = %s", filepath, cost)
    end
end
