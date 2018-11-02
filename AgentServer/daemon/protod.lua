
---! 依赖
local proto_proxy = require "module.proto_proxy"

---! 加载协议
proto_proxy:init()

---! 导出模块
ttd.exports.PROTO_D = proto_proxy
