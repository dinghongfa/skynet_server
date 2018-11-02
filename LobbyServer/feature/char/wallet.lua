-------------------------------------------------------------
---! @file   wallet.lua
---! @brief  钱包
-------------------------------------------------------------

---! 常量
local cpath = "wallet"

---! 当前支持的货币简要
local cash_type_brief = {
    scoin   =   "银元宝",
    gcoin   =   "金元宝",
}

---! 模块
local M = {}

---! 获取货币金额
function M:get_cash (ctype)
    if not cash_type_brief[ctype] then
        error("variable(ctype) is invalid cash type.")
        return 0
    end

    local cash = self:query(cpath, ctype)
    if type(cash) ~= "number" then
        return 0
    end

    return tonumber(string.format("%.4f", cash))
end

---! 设置货币金额
function M:add_cash (ctype, amount)
    if not cash_type_brief[ctype] then
        error("variable(ctype) is invalid cash type.")
        return false
    end

    if type(amount) ~= "number" then
        error("variable(amount) types must be numbers.")
        return false
    end

    if amount <= 0 then
        error("variable(amount) values must be greater than 0.")
        return false
    end

    self:set(cpath, ctype, tonumber(string.format("%.4f", self:get_cash(ctype) + amount)))
    return true
end

---! 消费货币金额
function M:cost_cash (ctype, amount)
    if not cash_type_brief[ctype] then
        error("variable(ctype) is invalid cash type.")
        return false
    end

    if type(amount) ~= "number" then
        error("variable(amount) types must be numbers.")
        return false
    end

    if amount <= 0 then
        error("variable(amount) values must be greater than 0.")
        return false
    end

    self:set(cpath, ctype, self:get_cash(ctype) - amount)
    return true
end

---! 更新钱包数据
function M:send_update_wallet (ctype)
    if ctype == "eos" and self:get_eos_account() then
        ---! EOS账号不需要更新EOS游戏币
        return
    end

    local wallet = {}
    wallet[ctype] = tostring(self:get_cash(ctype))
    self:send_update({ wallet = wallet, })
end

---! 获取钱包信息
function M:get_wallet_info ()
    local allWalletInfo = {}
    local wallet = self:query("wallet") or {}
    for ctype, cval in pairs (wallet) do
        allWalletInfo[ctype] = tostring(cval)
    end
    return allWalletInfo
end

---!
ttd.exports.F_CHAR_WALLET = M
