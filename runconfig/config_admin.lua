----------------------------------
---! @file
---! @brief AdminServer的启动配置文件
----------------------------------

-- 通常指的是 skynet 根目录
local _skynet = "./skynet/"

-- 通常指的是 app 根目录
local  _root = "./"

---! HallServer 用到的参数 从 命令行传的参数
NodeName    =  "$NodeName"
ServerKind  =  "AdminServer"
ServerNo    =  "$ServerNo"

----------------------------------
---!  自定义参数
----------------------------------
app_name = NodeName .. "_" .. ServerKind .. ServerNo
app_root = _root.. ServerKind .."/"

----------------------------------
---!  skynet用到的六个参数
----------------------------------
---!  工作线程数
-- 启动多少个工作线程。通常不要将它配置超过你实际拥有的 CPU 核心数。
thread      = 1

---!  服务模块路径（.so)
-- 用 C 编写的服务模块的位置，通常指 cservice 下那些 .so 文件。
-- 如果你的系统的动态库不是以 .so 为后缀，需要做相应的修改。
-- 这个路径可以配置多项，以 ; 分割。
cpath       = _skynet.."cservice/?.so"

---!  港湾ID，用于分布式系统，0表示没有分布
-- 可以是 1-255 间的任意整数。
-- 一个 skynet 网络最多支持 255 个节点。每个节点有必须有一个唯一的编号。
-- 如果 harbor 为 0 ，skynet 工作在单节点模式下。此时 master 和 address 以及 standalone 都不必设置。
harbor      = 0

---!  后台运行用到的 pid 文件
daemon      = _root .. "/pids/" .. app_name .. ".pid"
-- daemon      = nil

---!  日志文件
-- 它决定了 skynet 内建的 skynet_error 这个 C API 将信息输出到什么文件中。
-- 如果 logger 配置为 nil ，将输出到标准输出。
-- 这里配置一个文件名来将信息记录在指定文件中。
logger      = _root .. "/logs/" .. app_name .. ".log"
-- logger      = nil

---!  初始启动的模块
-- skynet 启动的第一个服务以及其启动参数。
-- 默认配置为 snlua bootstrap ，即启动一个名为 bootstrap 的 lua 服务。
-- 通常指的是 service/bootstrap.lua 这段代码。
bootstrap   = "snlua bootstrap"

----------------------------------
---!   snlua用到的参数
----------------------------------

---！
lua_path    = _skynet .. "lualib/?.lua;" ..
              _skynet .. "lualib/?/init.lua;" ..
              _root .. "lualib/?.lua;" ..
              _root .. "service/?.lua;" ..
              _root .. "preload/?.lua;" ..
              app_root .. "?.lua"

---!
-- 如果你的系统的动态库不是以 .so 为后缀，需要做相应的修改。
lua_cpath   = _skynet .. "luaclib/?.so;" ..
              _root .. "luaclib/?.so"

---!
luaservice  = _skynet .. "service/?.lua;" ..
              _root .. "service/?.lua;" ..
              app_root .. "?.lua;" ..
              app_root .. "service/?.lua;" ..
              app_root .. "http/?.lua;" ..
              app_root .. "test/?.lua"

---!
-- 用哪一段 lua 代码加载 lua 服务。
-- 通常配置为 lualib/loader.lua ，再由这段代码解析服务名称，进一步加载 lua 代码。
-- snlua 会将下面几个配置项取出，放在初始化好的 lua 虚拟机的全局变量中。具体可参考实现。
lualoader   = _skynet .. "lualib/loader.lua"

---!
-- 在设置完 package 中的路径后，加载 lua 服务代码前，loader 会尝试先运行一个 preload 制定的脚本，默认为空。
preload     = _root .. "preload/preload.lua"

---!
-- 这是 bootstrap 最后一个环节将启动的 lua 服务，也就是你定制的 skynet 节点的主程序。
-- 默认为 main ，即启动 main.lua 这个脚本。这个 lua 服务的路径由下面的 luaservice 指定。
start       = "main"

----------------------------------
---!   snax用到的参数
----------------------------------

-- 用 snax 框架编写的服务的查找路径
snax = _skynet .. "service/?.lua;" ..
       _root .. "service/?.lua;" ..
       app_root .. "?.lua"

----------------------------------
---!   cluster用到的参数
----------------------------------

-- cluster 它决定了集群配置文件的路径
cluster = _root .. "config/config.cluster"
