
require "cocos.extension.ExtensionConstants"

local UpdateRes = class("UpdateRes",function()
    return cc.Layer:create()
end)


function UpdateRes.create()
    local layer = UpdateRes.new()
    return layer
end


function UpdateRes:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.pathToSave = createResDownloadDir()  -- 保存路径
    self.assetsManager = nil -- 资源管理器对象
end


function UpdateRes:getAssetsManager()

    if nil == self.assetsManager then

        -- 测试true 体验1
        if test_package then
            if package_name == "qjui" then
                if test_package == 1 then
                    self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqjtyb/resui",
                        "http://yl04.nnzzh.com/ylqjtyb/version_resui.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                else
                    self.assetsManager = cc.AssetsManager:new("http://47.96.62.50/pre_release/ylqj/resui",
                        "http://47.96.62.50/pre_release/ylqj/version_resui.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                end
            else
                if test_package == 1 then
                    self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqjtyb/res",
                        "http://yl04.nnzzh.com/ylqjtyb/version_res.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                else
                    self.assetsManager = cc.AssetsManager:new("http://47.96.62.50/pre_release/ylqj/res",
                        "http://47.96.62.50/pre_release/ylqj/version_res.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                end
            end
        else
            -- 正式服
            if package_name == "qjui" then
                self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqj/resui",
                    "http://yl04.nnzzh.com/ylqj/version_resui.txt?v="..os.date("%m%d%H%M", os.time()),
                    self.pathToSave)
            else
                self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqj/res",
                    "http://yl04.nnzzh.com/ylqj/version_res.txt?v="..os.date("%m%d%H%M", os.time()),
                    self.pathToSave)
            end
        end

        if self.assetsManager and self.assetsManager.setVersionKey then
            self.assetsManager:setVersionKey(g_version_key_1)
        end

        if self.assetsManager and self.assetsManager.setDefaultVersion then
            self.assetsManager:setDefaultVersion(g_res_ver_1)
        end
        self:addChild(self.assetsManager)

        self.assetsManager:setConnectionTimeout(15)
    end

    return self.assetsManager
end

function UpdateRes:delSecondRes()
    self.assetsManager:setVersionKey(g_version_key_2)
    self:getAssetsManager():deleteVersion()
    self.assetsManager:setVersionKey(g_version_key_1)
    local pathToSave = createDownloadDir()
    cc.FileUtils:getInstance():removeDirectory(pathToSave.."/")
end

function UpdateRes:checkUpdate(call_func)

    self:createLayerMenu(true)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()

    local function onError(errorCode)
        if errorCode ~= cc.ASSETSMANAGER_NO_NEW_VERSION then
            commonlib.showTipDlg("网络超时\n立即重试，点击“确定”\n检查网络重新打开再试，点击“取消”", function(is_ok)
                if is_ok then
                    local parent = self:getParent()
                    if parent then
                        parent:unregisterEventListener()
                    end
                    local scene = require("scene.LoginScene")
                    local gameScene = scene.create_from_update()
                    local loginScene = cc.Director:getInstance():getRunningScene()
                    if loginScene then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                else
                    cc.Director:getInstance():endToLua()
                end
            end)
        end
    end


    local function onSuccess()
        self:runAction(cc.CallFunc:create(function()
            local function clearLoadedFiles()
                for k, v in pairs(package.loaded) do
                    if string.sub(k, 1, 6) == "common" then
                        package.loaded[k] = nil
                    end
                    if string.sub(k, 1, 5) == "scene" then
                        package.loaded[k] = nil
                    end
                end
                cc.SpriteFrameCache:getInstance():removeSpriteFrames()
                cc.Director:getInstance():getTextureCache():removeAllTextures()
            end
            clearLoadedFiles()
            if self.assetsManager and self.assetsManager.getVersion then
                local version = self.assetsManager:getVersion() or "1.0.0"
                cc.UserDefault:getInstance():setStringForKey("UpdateResVersion",version)
                cc.UserDefault:getInstance():flush()
            end
            if ios_checking then
                ymkj.setIpv4Net(1)
            end
            local scene = require("scene.LoginScene")
            local gameScene = scene.create_from_update()
            local loginScene = cc.Director:getInstance():getRunningScene()
            if loginScene then
                cc.Director:getInstance():replaceScene(gameScene)
            else
                cc.Director:getInstance():runWithScene(gameScene)
            end
        end)
        )
    end

    self:getAssetsManager():setDelegate(onSuccess, cc.ASSETSMANAGER_PROTOCOL_SUCCESS)
    self:getAssetsManager():setDelegate(onError, cc.ASSETSMANAGER_PROTOCOL_ERROR)

    local codeVersion = cc.UserDefault:getInstance():getStringForKey("update_version1","3.0")
    if "3.0" > codeVersion then
        self:getAssetsManager():deleteVersion()
        cc.FileUtils:getInstance():removeDirectory(self.pathToSave.."/")
        self.pathToSave = createResDownloadDir()
        cc.UserDefault:getInstance():setStringForKey("update_version1", "3.0")
        cc.UserDefault:getInstance():flush()
    end

    if g_os == "win" then
        if call_func then
           call_func(false)
        end
        return
    end


    local rtn = self:getAssetsManager():checkUpdate()
    if rtn == 3 then
        --有更新
        self:delSecondRes()
        cc.FileUtils:getInstance():removeDirectory(self.pathToSave.."/")
        self.pathToSave = createResDownloadDir()
        self:createLayerMenu()
        if call_func then
           call_func(true)
        end
    elseif rtn == 1 then
        --异常
        if call_func then
           call_func(true)
        end
    else
        --没有更新
        if call_func then
           call_func(false)
        end
    end

    end)))
end

function UpdateRes:createLayerMenu(is_init)

    if is_init then

        local title = cc.LabelTTF:create("检查资源中...", "STHeitiSC-Medium", 30)
        if ios_checking then
            title:setString("")
        end
        title:setHorizontalAlignment(1)
        title:setColor(cc.c3b(255,255,255))
        title:setPosition(cc.p(g_visible_size.width/2, 110))
        self:addChild(title)

        self.title = title

        return
    end


    local version = self:getAssetsManager():getDownloadVersion()
    self.title:setString(string.format("初始化资源%s(%0.1f%%)",version, 0))
    local function onProgress(percent)
        self.title:setString(string.format("初始化资源%s(%0.1f%%)",version, percent))
    end


    self:getAssetsManager():setDelegate(onProgress, cc.ASSETSMANAGER_PROTOCOL_PROGRESS)

    self:getAssetsManager():update()
end


return UpdateRes