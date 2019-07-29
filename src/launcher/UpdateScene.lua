require "cocos.extension.ExtensionConstants"
local device = require("cocos.framework.device")
gt = gt or {}

function COPY_MSG(str, portrait, parent)
end

local cfg = require("launcher.cfg")
local util = require("launcher.util")

local UpdateScene = class("UpdateScene",function()
    return cc.Scene:create()
end)

function UpdateScene:ctor()
    self.retryCount = 0
    self.retryRound = 0
    self:enableNodeEvents()
end

function UpdateScene:performWithDelay(func,delay)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(delay), cc.CallFunc:create(function()
        func()
    end)))
end

function UpdateScene:startGame()
    self:unregisterEventListener()
    --Launcher为游戏入口,只能在进入游戏时require,保证Launcher使用热更后的代码
    require("launcher.Launcher"):startGame()
end

function UpdateScene:delUpdatedVersion(ver)
    local assetsMgr = self:getAssetsManager(ver)
    assetsMgr:deleteVersion()
    -- 去掉删除文件夹步骤，更新失败也是用上次更新成功的资源(这样会引入回档的bug，更新后的文件还保留再代码里了,还是要删)
    cc.FileUtils:getInstance():removeDirectory(cfg["pathToSave" .. ver].."/")
    if ver == 1 then
        cfg["pathToSave" .. ver] = createResDownloadDir()
    elseif ver == 2 then
        cfg["pathToSave" .. ver] = createDownloadDir()
    end
end

function UpdateScene:cleanForCover()
    local pkgName = cc.UserDefault:getInstance():getStringForKey("package_name","")
    if pkgName == "" then
        pkgName = nil
    end
    if pkgName ~= package_name then
        for ver=1,2 do
            self:delUpdatedVersion(ver)
            cc.FileUtils:getInstance():removeDirectory(cfg["pathToSave" .. ver].."/")
        end
        local pathToSave1 = createResDownloadDir()
        cfg:setPathToSave(1,pathToSave1)
        local pathToSave2 = createDownloadDir()
        cfg:setPathToSave(2,pathToSave2)
        cc.UserDefault:getInstance():setStringForKey("package_name",package_name or "")
        cc.UserDefault:getInstance():flush()
    end
end

function UpdateScene:showTipFail(ver)
    local tipStr = "连接超时\n立即重连，点击“确定”\n检查网络重新打开再连，点击“取消”"
    util:showTip(tipStr,function(isOk)
        if isOk then
            self:startUpdate(ver)
            util:uploadErr("UpdateScene:showTipFail" .. ver)
        else
            cc.Director:getInstance():endToLua()
        end
    end)
end

function UpdateScene:getUpdateConf(ver)
    local updCfg = cfg:getUpdateConf(ver,self.retryCount)
    return updCfg
end

function UpdateScene:startUpdate(ver)
    local updCfg = self:getUpdateConf(ver)
    -- dump(updCfg,"updCfg"..ver)
    local dotStr = "."
    for i=1,ver do
        dotStr = dotStr .. "."
    end
    self:setTip("正在检测更新" .. dotStr)
    local assetsMgr = self:getAssetsManager(ver,true)
    local function onError(errorCode)
        if errorCode ~= cc.ASSETSMANAGER_NO_NEW_VERSION then
            self.retryCount = self.retryCount + 1
            if self.retryCount > 20 then
                self.retryCount = 0
                self.retryRound = self.retryRound + 1
                -- if self.retryRound >= 3 then
                --     self:startGame()
                -- else
                    local strVer = tostring(ver)
                    if errorCode == cc.ASSETSMANAGER_CREATE_FILE then
                        self:setTip("创建临时文件失败" .. strVer .. errorCode)
                    elseif errorCode == cc.ASSETSMANAGER_NETWORK then
                        self:setTip("网络超时" .. strVer ..errorCode)
                    elseif errorCode == cc.ASSETSMANAGER_UNCOMPRESS then
                        self:setTip("解压失败" .. strVer .. errorCode)
                    end
                    self:showTipFail(ver)
                    self:reqClientIp()
                -- end
            else
                self:startUpdate(ver)
            end
        end
    end
    local function onSuccess()
        self.retryCount = 0
        self.retryRound = 0
        if ver == 1 then
            self:delUpdatedVersion(2)
            self:startUpdate(2)
        else
            if assetsMgr and assetsMgr.getVersion then
                local version = assetsMgr:getVersion() or "1.0.0"
                cc.UserDefault:getInstance():setStringForKey("UpdateVersion",version)
                cc.UserDefault:getInstance():flush()
            end
            self:startGame()
        end
    end
    assetsMgr:setDelegate(onSuccess, cc.ASSETSMANAGER_PROTOCOL_SUCCESS)
    assetsMgr:setDelegate(onError, cc.ASSETSMANAGER_PROTOCOL_ERROR)
    local rtn = assetsMgr:checkUpdate()
    if rtn == 1 then
        -- onError return cc.ASSETSMANAGER_NETWORK
    elseif rtn == 3 then
        self:delUpdatedVersion(ver)
        local version = assetsMgr:getDownloadVersion()
        self.progressLabel:setString(string.format("正在更新至版本%s(%0.1f%%)",version, 0))
        local function onProgress(percent)
            self.progressLabel:setString(string.format("正在更新至版本%s(%0.1f%%)",version, percent))
            self:setPercentage(percent)
        end
        assetsMgr:setDelegate(onProgress, cc.ASSETSMANAGER_PROTOCOL_PROGRESS)
        assetsMgr:update()
    else --2
        -- onError return cc.ASSETSMANAGER_NO_NEW_VERSION
        if ver == 1 then
            self:startUpdate(2)
        else
            self:startGame()
        end
    end
end

function UpdateScene:getAssetsManager(ver,isStartUpdate)
    local updCfg = self:getUpdateConf(ver)
    if isStartUpdate then
        if updCfg.assetsMgr then
            updCfg.assetsMgr:removeSelf()
            cfg:setAssetsMgr(ver,nil)
            updCfg = self:getUpdateConf(ver)
        end
    end
    if updCfg.assetsMgr == nil then
        local assetsMgr = cc.AssetsManager:new(updCfg.zipPath,updCfg.verPath,updCfg.pathToSave)
        cfg:setAssetsMgr(ver,assetsMgr)
        if assetsMgr and assetsMgr.setVersionKey then
            assetsMgr:setVersionKey(updCfg.verkey)
        end
        if assetsMgr and assetsMgr.setDefaultVersion then
            assetsMgr:setDefaultVersion(updCfg.verdft)
        end
        self:addChild(assetsMgr)
        assetsMgr:setConnectionTimeout(15)
        updCfg = self:getUpdateConf(ver)
    end
    return updCfg.assetsMgr
end

function UpdateScene:setTip(_str)
    self.progressLabel:setString(_str)
    print(_str)
end

function UpdateScene:setPercentage(persent)
    self.proBg:setVisible(true)
    self.progressBar:setVisible(true)
    self.progressBar:setPercentage(persent)
end

function UpdateScene:initView()
    local director = cc.Director:getInstance()
    local visible_size = director:getVisibleSize()
    local bg = display.newSprite("launcher/launcher_bg.jpg")
    self:addChild(bg)
    bg:setPosition(cc.p(display.cx,display.cy))
    bg:setContentSize(cc.size(visible_size.width,visible_size.height))
    ccui.Helper:doLayout(bg)

    local logo = display.newSprite("launcher/launcher_logo.png")
    self:addChild(logo)
    logo:setPosition(cc.p(display.cx,display.height*0.575))

    local proBg = display.newSprite("launcher/launcher_bg_loadbarbg.png")
    self:addChild(proBg)
    proBg:setPosition(cc.p(display.cx, display.height*0.2))
    proBg:setVisible(false)
    self.proBg = proBg

    local progressBar = cc.ProgressTimer:create(cc.Sprite:create("launcher/launcher_bg_loadbar.png"))
    progressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    progressBar:setMidpoint(cc.p(0, 0))
    progressBar:setBarChangeRate(cc.p(1, 0))
    progressBar:setPosition(cc.p(display.cx, display.height*0.2))
    self:addChild(progressBar)
    progressBar:setVisible(false)
    self.progressBar = progressBar

    local versionLabel = cc.LabelTTF:create("",display.DEFAULT_TTF_FONT, 32)
    versionLabel:setPosition(cc.p(10,display.height*0.95))
    versionLabel:setAnchorPoint(cc.p(0,0.5))
    self:addChild(versionLabel)
    local version = cc.UserDefault:getInstance():getStringForKey("UpdateVersion","1.0.0")
    versionLabel:setString(string.format("版本号 res:%s",version))

    local progressLabel = cc.LabelTTF:create("正在检测更新",display.DEFAULT_TTF_FONT, 32)
    progressLabel:setPosition(cc.p(display.cx,100))
    self:addChild(progressLabel)
    self.progressLabel = progressLabel
end

function UpdateScene:registerEventListener()
    local CUSTOM_LISTENERS = {
        ["game_conf"]             = handler(self, self.onGameConf),
        ["taobao_url"]            = handler(self, self.onClientIpGetTaobao),
        ["daili_url"]             = handler(self, self.onClientIpGetDaili),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        util:addCustomEventListener(k, v)
    end
end

function UpdateScene:unregisterEventListener()
    local LISTENER_NAMES = {
        ["game_conf"]            = handler(self, self.onGameConf),
        ["taobao_url"]           = handler(self, self.onClientIpGetTaobao),
        ["daili_url"]            = handler(self, self.onClientIpGetDaili),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function UpdateScene:reqGameConf()
    local updCfg = self:getUpdateConf(1)
    ymkj.UrlPool:instance():reqHttpGet("game_conf",updCfg.game_conf_url)
end

function UpdateScene:onGameConf(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    if string.find(rtn_msg,"html") then
        return
    end
    local func = loadstring("return "..rtn_msg)
    local ret, gameconf = pcall(func)
    if ret and gameconf then
        gt.game_conf = gameconf
        cfg:saveLocalGameConf(rtn_msg)
        -- dump(gt.game_conf,"UpdateScene:onGameConf")
    end
end

function UpdateScene:reqClientIp()
    if g_client_ip then
        return
    end
    local cfgName = "taobao_url"
    if math.random(1,2)%2 == 0 then
        cfgName = "daili_url"
    end
    ip_url = cfg:getConf(cfgName)
    if string.find(ip_url,"http") then
        print(cfgName,ip_url)
        ymkj.UrlPool:instance():reqHttpGet(cfgName,ip_url)
    end
end

function UpdateScene:onClientIpGetDaili(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        util:uploadErr("onClientIpGetDaili1" .. tostring(rtn_msg))
        return
    end
    if string.find(rtn_msg,"html") then
        util:uploadErr("onClientIpGetDaili2" .. tostring(rtn_msg))
        return
    end
    local ok1,p1 = pcall(string.find,rtn_msg,":")
    local ok2,p2 = pcall(string.find,rtn_msg,",")
    if not ok1 or not ok2 then
        util:uploadErr("onClientIpGetDaili3" .. tostring(rtn_msg))
        return
    end
    local str = string.sub(rtn_msg,p1+3,p2-2)
    g_client_ip = str
    print("onClientIpGetDaili",g_client_ip)
end

function UpdateScene:onClientIpGetTaobao(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        util:uploadErr("onClientIpGetTaobao1" .. tostring(rtn_msg))
        return
    end
    if string.find(rtn_msg,"html") then
        util:uploadErr("onClientIpGetTaobao2" .. tostring(rtn_msg))
        return
    end
    local ok,tab = pcall(json.decode,rtn_msg)
    if not ok then
        util:uploadErr("onClientIpGetTaobao3" .. tostring(rtn_msg))
        return
    end
    local str = nil
    if tab and tab.code == 0 then
        str = tab.data.ip
    end
    g_client_ip = str
    print("onClientIpGetTaobao",g_client_ip)
end

function UpdateScene:onEnter()
    cfg:initLocalGameConf()
    self:registerEventListener()
    self:initView()
    if device.platform ~= "android" and device.platform ~= "ios" then
        self:startGame()
    else
        local pathToSave1 = createResDownloadDir()
        cfg:setPathToSave(1,pathToSave1)
        local pathToSave2 = createDownloadDir()
        cfg:setPathToSave(2,pathToSave2)
        self:cleanForCover()
        self:performWithDelay(function()
            self:startUpdate(1)
        end,0.1)
    end
    self:reqGameConf()
end

function UpdateScene:onExit()

end

return UpdateScene