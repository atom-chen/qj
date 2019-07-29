
local domain_release    = {
    "yl04.nnzzh.com",
    "yl-qj.oss-cn-zhangjiakou.aliyuncs.com",
    "39.100.85.155",
}
local domain_test       = {
    "47.96.62.50/pre_release",
    "47.96.62.50/pre_release",
    "47.96.62.50/pre_release",
}

local cfg = {
    verkey1             = "res.ylqp.com",
    verdft1             = "1.0.0",
    assetsMgr1          = nil,
    pathToSave1         = nil,
    verkey2             = "pack.ylqp.com",
    verdft2             = "1.0.0",
    assetsMgr2          = nil,
    pathToSave2         = nil,
    log_url             = "http://118.89.182.159:8081",
    taobao_url          = "http://ip.taobao.com/service/getIpInfo.php?ip=myip",
    daili_url           = "http://pv.sohu.com/cityjson?ie=utf-8",
    -- upd_domain_list     = {
    --     "yl04.nnzzh.com",
    --     "yl-qj.oss-cn-zhangjiakou.aliyuncs.com",
    --     "39.100.85.155",
    -- },
}

local file_cfg          = "game_conf.lua"

--  cfgdemo = {
--      "assetsMgr"     = userdata: 0x2824714c8
--      "game_conf_url" = "http://yl04.nnzzh.com/dbw/game_conf.lua"
--      "pathToSave"    = "/var/mobile/Containers/Data/Application/FCD63CAD-9684-479E-8CBD-AC0499D02424/Documents/updateDir"
--      "verPath"       = "http://yl04.nnzzh.com/ylqj/qjupd.txt"
--      "verdft"        = "1.0.0"
--      "verkey"        = "update_code_ver"
--      "zipPath"       = "http://yl04.nnzzh.com/ylqj/qjupd"
-- }

function cfg:setAssetsMgr(ver,obj)
    cfg['assetsMgr' .. ver] = obj
end

function cfg:setPathToSave(ver,path)
    cfg['pathToSave' .. ver] = path
end

function cfg:getDomainList()
    local ret = {}
    local cf_list = self:getConf("upd_domain_list")
    if type(cf_list) == "table" then
        for i,v in ipairs(cf_list) do
            ret[#ret+1] = v
        end
    end
    local list = domain_release
    if test_package then
        list = domain_test
    end
    for i,v in ipairs(list) do
        ret[#ret+1] = v
    end
    -- dump(ret,"getDomainList")
    return ret
end

function cfg:getDomainGameConf()
    local list = self:getDomainList()
    local temp = {}
    for i,v in ipairs(list) do
        local tab = string.split(v,".")
        if tab[1] and tonumber(tab[1]) == nil then
            temp[#temp+1] = v
        end
    end
    if #temp == 0 then
        temp = list
    end
    local idx = math.random(1,#temp)
    local domain = temp[idx]
    -- print("cfg:getGameConfUrl",domain)
    return domain
end

function cfg:getDomain(count)
    local list = self:getDomainList()
    local idx = count%(#list)+1
    local domain = list[idx]
    return domain
end

function cfg:getUpdateConf(ver,count)
    local ret = {
        verkey          = cfg['verkey' .. ver],
        verdft          = "1.0.0",
        assetsMgr       = cfg['assetsMgr' .. ver],
        pathToSave      = cfg['pathToSave' .. ver],
    }
    local domain_cf = self:getDomainGameConf()
    if g_is_new_update then
        local domain            = self:getDomain(count)
        local path              = "ylqj"
        local zipres_prefix     = "resupd"
        local zip_prefix        = "qjupd"
        local version_res       = "version_resupd.txt"
        local version           = "qjupd.txt"
        if test_package == 1 then
            path = "ylqjtyb"
        end
        if ver == 1 then
            ret.zipPath         = string.format("http://%s/%s/%s",domain,path,zipres_prefix)
            ret.verPath         = string.format("http://%s/%s/%s",domain,path,version_res)
        else
            ret.zipPath         = string.format("http://%s/%s/%s",domain,path,zip_prefix)
            ret.verPath         = string.format("http://%s/%s/%s",domain,path,version)
        end
        ret.game_conf_url   = string.format("http://%s/%s/%s",domain_cf,path,file_cfg)
    else
        local domain            = self:getDomain(count)
        local path              = "ylqj"
        local zipres_prefix     = "resui"
        local zip_prefix        = "qjui"
        local version_res       = "version_resui.txt"
        local version           = "qjui.txt"
        if test_package == 1 then
            path    = "ylqjtyb"
        end
        if package_name ~= "qjui" then
            zipres_prefix     = "res"
            zip_prefix        = "ylqj"
            version_res       = "version_res.txt"
            version           = "ylqj.txt"
        end
        if ver == 1 then
            ret.zipPath         = string.format("http://%s/%s/%s",domain,path,zipres_prefix)
            ret.verPath         = string.format("http://%s/%s/%s",domain,path,version_res)
        else
            ret.zipPath         = string.format("http://%s/%s/%s",domain,path,zip_prefix)
            ret.verPath         = string.format("http://%s/%s/%s",domain,path,version)
        end
        ret.game_conf_url   = string.format("http://%s/%s/%s",domain_cf,path,file_cfg)
    end
    -- dump(ret,"cfg:getUpdateConf" .. tostring(ver) .. tostring(count))
    return ret
end

function cfg:getConf(key)
    local ret = cfg[key]
    if gt.local_game_conf and gt.local_game_conf[key] ~= nil then
        if key == "abilitys" then
            ret = ret .. gt.local_game_conf[key]
        else
            ret = gt.local_game_conf[key]
        end
    end
    if gt.game_conf and gt.game_conf[key] ~= nil then
        if key == "abilitys" then
            ret = ret .. gt.game_conf[key]
        else
            ret = gt.game_conf[key]
        end
    end
    return ret
end

function cfg:initLocalGameConf()
    local _confStr = cc.UserDefault:getInstance():getStringForKey("local_game_conf","")
    if type(_confStr) ~= "string" or #_confStr == 0 then
        return
    end
    local func = loadstring("return ".._confStr)
    local ret, local_game_conf = pcall(func)
    if ret and local_game_conf then
        gt.local_game_conf = local_game_conf
    end
    -- dump(gt.local_game_conf,"util:initLocalGameConf")
end

function cfg:saveLocalGameConf(_confStr)
    if type(_confStr) == "string" then
        cc.UserDefault:getInstance():setStringForKey("local_game_conf", _confStr)
        cc.UserDefault:getInstance():flush()
    end
end

return cfg