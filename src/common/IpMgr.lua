--
-- Author: tanxin
-- Date: 2017-08-25 10:35:44
--
-- local Http = require("common.Http")

local IpMgr = class("IpMgr")

local TAOBAO_URL = "http://ip.taobao.com/service/getIpInfo.php?ip=myip"
local DAILI_RUL  = "http://pv.sohu.com/cityjson?ie=utf-8"

function IpMgr:ctor()
    -- 0 没有获取任何信息 1 从后台获取 2 从网站获取 3从代理获取 4淘宝网站获取
end

function IpMgr:initIp()
    if g_client_ip == nil then
        ymkj.UrlPool:instance():reqHttpGet("client_ip_get_daili", DAILI_RUL)
        ymkj.UrlPool:instance():reqHttpGet("client_ip_get_taobao", TAOBAO_URL)
    end
    if gt.game_conf == nil and (not typ or typ == "conf") then
        local url = gt.getConf("game_conf_url")
        if test_package == 1 then
            url = gt.getConf("game_conf_tyb_url")
        elseif test_package == true then
            url = gt.getConf("game_conf_test_url")
        end
        ymkj.UrlPool:instance():reqHttpGet("game_conf", url)
    end
end

return IpMgr