
require "cocos.extension.ExtensionConstants"

local UpdateLayer = class("UpdateLayer",function()
    return cc.Layer:create()
end)

function UpdateLayer.create()
    local layer = UpdateLayer.new()
    return layer
end


function UpdateLayer:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.schedulerID = nil
    self.pathToSave = createDownloadDir()  -- 保存路径
    self.assetsManager = nil -- 资源管理器对象
end

function UpdateLayer:getContentLength()
    local length = self.assetsManager:getContentLength()

    if length >= 1024*1024 then
        length = string.format("%0.1fMB", length/1024/1024)
    elseif length >= 1024 then
        length = string.format("%0.1fKB", length/1024)
    elseif length > 0 then
        length = string.format("%dB", length)
    else
        length = "0B"
    end

    return length
end


function UpdateLayer:getAssetsManager()
    if nil == self.assetsManager then
        if test_package then
            if package_name == "qjui" then
                if test_package == 1 then
                    self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqjtyb/qjui",
                        "http://yl04.nnzzh.com/ylqjtyb/qjui.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                else
                    self.assetsManager = cc.AssetsManager:new("http://47.96.62.50/pre_release/ylqj/qjui",
                        "http://47.96.62.50/pre_release/ylqj/qjui.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                end
            else
                if test_package == 1 then
                    self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqjtyb/ylqj",
                        "http://yl04.nnzzh.com/ylqjtyb/ylqj.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                else
                    self.assetsManager = cc.AssetsManager:new("http://47.96.62.50/pre_release/ylqj/ylqj",
                        "http://47.96.62.50/pre_release/ylqj/ylqj.txt?v="..os.date("%m%d%H%M", os.time()),
                        self.pathToSave)
                end
            end
        else
            if package_name == "qjui" then
                self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqj/qjui",
                    "http://yl04.nnzzh.com/ylqj/qjui.txt?v="..os.date("%m%d%H%M", os.time()),
                    self.pathToSave)
            else
                self.assetsManager = cc.AssetsManager:new("http://yl04.nnzzh.com/ylqj/ylqj",
                    "http://yl04.nnzzh.com/ylqj/ylqj.txt?v="..os.date("%m%d%H%M", os.time()),
                    self.pathToSave)
            end
        end
        if self.assetsManager and self.assetsManager.setVersionKey then
            self.assetsManager:setVersionKey(g_version_key_2)
        end
        if self.assetsManager and self.assetsManager.setDefaultVersion then
            self.assetsManager:setDefaultVersion(g_res_ver)
        end
        self:addChild(self.assetsManager)
        self.assetsManager:setConnectionTimeout(15)
    end

    return self.assetsManager
end



function UpdateLayer:checkUpdate(call_func)

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
                    if string.sub(k, 1, 7) == "modules" then
                        package.loaded[k] = nil
                    end
                end
                cc.SpriteFrameCache:getInstance():removeSpriteFrames()
                cc.Director:getInstance():getTextureCache():removeAllTextures()
            end
            clearLoadedFiles()

            if self.assetsManager and self.assetsManager.getVersion then
                local version = self.assetsManager:getVersion() or "1.0.0"
                cc.UserDefault:getInstance():setStringForKey("UpdateVersion",version)
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

    local default_value = g_is_multi_wechat and "3.0" or "2.0.0"
    local codeVersion = cc.UserDefault:getInstance():getStringForKey("update_version2", default_value)
    if default_value > codeVersion then
        self:getAssetsManager():deleteVersion()
        cc.FileUtils:getInstance():removeDirectory(self.pathToSave.."/")
        self.pathToSave = createDownloadDir()

        cc.UserDefault:getInstance():setStringForKey("update_version2", default_value)
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
        cc.FileUtils:getInstance():removeDirectory(self.pathToSave.."/")
        self.pathToSave = createDownloadDir()
        self:createLayerMenu()
        if call_func then
           call_func(true)
        end
    elseif rtn == 1 then
        if call_func then
           call_func(true)
        end
    else
        if call_func then
           call_func(false)
        end
    end

    end)))
end

function UpdateLayer:createLayerMenu(is_init)

    if is_init then

        local title = cc.LabelTTF:create("检查版本中...", "STHeitiSC-Medium", 30)
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


    -- local downloadTitle = tolua.cast(ccui.Helper:seekWidgetByName(node,"Text_1"), "ccui.Text")
    -- downloadTitle:setString(string.format("正在更新至版本%s",self:getAssetsManager():getDownloadVersion()))--, self:getContentLength()))

    -- local tipLabel = tolua.cast(ccui.Helper:seekWidgetByName(node,"lab-shuoming"), "ccui.Text")
    -- tipLabel:setString(loadTipConfg.hall[math.random(1, #loadTipConfg.hall)])
    -- tipLabel:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
    --     tipLabel:setString(loadTipConfg.hall[math.random(1, #loadTipConfg.hall)])
    -- end))))
    -- local downloadBar = tolua.cast(ccui.Helper:seekWidgetByName(node,"LoadingBar_1"), "ccui.LoadingBar")
    -- local downloadLabel = tolua.cast(ccui.Helper:seekWidgetByName(node,"Download_Label"), "ccui.Text")
    local version = self:getAssetsManager():getDownloadVersion()
    self.title:setString(string.format("正在更新至版本%s(%0.1f%%)",version, 0))
    local function onProgress(percent)
        self.title:setString(string.format("正在更新至版本%s(%0.1f%%)",version, percent))
        -- downloadBar:setPercent(percent)
        -- downloadLabel:setString(string.format("%0.1f%%", percent))
    end


    self:getAssetsManager():setDelegate(onProgress, cc.ASSETSMANAGER_PROTOCOL_PROGRESS)

    self:getAssetsManager():update()
end


return UpdateLayer