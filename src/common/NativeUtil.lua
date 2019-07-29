local NativeUtil = {
    abilitys = {},
    validWeChatAppIds = {
        ["wx023871851a2b168c"] = "com.xzkj.qwer.qjqp",

        ["wxe9da9f9a6908ccd8"] = "com.xzkj.qwer.qjqp",
        ["wx74afa9034b34a179"] = "com.xzkj.qwer.qjqp",
        ["wxe9646026bc20e39e"] = "com.xzkj.qwer.qjqp",
        ["wxbd296a8739530eaa"] = "com.xzkj.qwer.qjqp",
        ["wx37ad2219b9362837"] = "com.xzkj.qwer.qjqp",
        ["wx40ed5a7d32708005"] = "com.xzkj.qwer.qjqp",
        ["wx4a365f14e55edf51"] = "com.xzkj.qwer.qjqp",
        ["wxfa7a54ff6d143a26"] = "com.xzkj.qwer.qjqp",
        ["wxb13240da79af7579"] = "com.xzkj.qwer.qjqp",
        ["wxb673b5c16398f0a7"] = "com.xzkj.qwer.qjqp",

        ["wxd3ec995faeb43edd"] = "com.xzkj.qwer.qjqp",
        ["wx68d6bda9242b3498"] = "com.xzkj.qwer.qjqp",
        ["wx7d1c3009e80c2d9f"] = "com.xzkj.qwer.qjqp",
        ["wx5e5a0b399782ea56"] = "com.xzkj.qwer.qjqp",
        ["wx68c6cf71e4b28a33"] = "com.xzkj.qwer.qjqp",
        ["wx60044923e77a13a8"] = "com.xzkj.qwer.qjqp",
        ["wxf3565f327a4617c4"] = "com.xzkj.qwer.qjqp",
        ["wx875c6bbc4a4d8092"] = "com.xzkj.qwer.qjqp",
        ["wx0b962d8274adfce8"] = "com.xzkj.qwer.qjqp",
        ["wxd295e3fe1196468e"] = "com.hnthj.nxqp",

        ["wx3d589cc63b48afdd"] = "com.hnthj.nxqp",
        ["wx890dfc24df3856df"] = "com.hnthj.nxqp",
        ["wxd8bc3904a25be263"] = "com.hnthj.nxqp",
        ["wxa21bacf8c1ad0fdf"] = "com.hnthj.nxqp",
        ["wx37c1c849b84a7da1"] = "com.hnthj.nxqp",
        ["wx55d1096d226f4067"] = "com.hnthj.nxqp",
        ["wxf16e0e1dda5b3ade"] = "com.hnthj.nxqp",
        ["wxa60d23a1918c148d"] = "com.hnthj.nxqp",
        ["wx02c9fa5f75584406"] = "com.hnthj.nxqp",
        ["wxe9ba7534214c62ed"] = "com.hnthj.nxqp",
        ["wxb3956a25ea1ddd24"] = "com.hnthj.nxqp",
        ["wx9bf276ecc6c34f3a"] = "com.hnthj.nxqp",
    },
    wechatAppIds = {},
}

function NativeUtil:init()
    local retStr = ""
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "getAbilitys"
        local className = "XZUtil"
        local args      = {}
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    elseif g_os == "android" then
        local funcName  = "getAbilitys"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "()Ljava/lang/String;"
        local className = "com/sy18/luaj/XZUtil"
        local ok, ret = luaj.callStaticMethod(className, funcName, {}, sigs)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    end
    local tab = string.split(retStr, ",")
    for i, key in ipairs(tab) do
        self.abilitys[key] = true
    end
    self:initWechatAppIds()
end

function NativeUtil:getAbility(name)
    return self.abilitys[name]
end

function NativeUtil:getAbilityCount()
    local ret = 0
    for k, v in pairs(self.abilitys) do
        if k ~= "" then
            ret = ret + 1
        end
    end
    return ret
end

function NativeUtil:getRandAppId()
    -- dump(self.wechatAppIds,"self.wechatAppIds")
    local ret = nil
    if #self.wechatAppIds == 0 then
        return ret
    end
    ret = self.wechatAppIds[math.random(1, #self.wechatAppIds)]
    return ret
end

function NativeUtil:initWechatAppIds()
    if not self:getAbility("getWeChatAppIds") then return end
    local retStr = ""
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "getWeChatAppIds"
        local className = "XZUtil"
        local args      = {}
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    elseif g_os == "android" then
        local funcName  = "getWeChatAppIds"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "()Ljava/lang/String;"
        local className = "com/sy18/luaj/XZUtil"
        local ok, ret = luaj.callStaticMethod(className, funcName, {}, sigs)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    end
    -- print("getWeChatAppIds",retStr)
    if retStr and retStr ~= "" and #self.wechatAppIds == 0 then
        local tab = string.split(retStr, ",")
        for i, key in ipairs(tab) do
            if key and #key > 0 and self.validWeChatAppIds[key] then
                if g_os == "ios" then
                    if gt.getPackageName() == self.validWeChatAppIds[key] then
                        self.wechatAppIds[#self.wechatAppIds + 1] = key
                    end
                else
                    self.wechatAppIds[#self.wechatAppIds + 1] = key
                end
            end
        end
    end
end

function NativeUtil:downloadTip(_tipStr, _dldUrl)
    local strContent = _tipStr or "安全防护升级，请下载最新的安装包！"
    local function qureyCallback()
        local url = gt.getConf("download_url")
        url       = _dldUrl or url
        gt.openUrl(url)
        print("openUrl", url)
    end
    local function cancelCallback()

    end
    commonlib.showTipDlg(strContent, function(is_ok)
        if is_ok then
            qureyCallback()
        else
            cancelCallback()
        end
    end)
end

function NativeUtil:dowloadOtherTip(_type)
    if _type == "xianliao" then
        local _tipStr = "您还未下载闲聊\n是否前往下载？"
        local _dldUrl = gt.getConf("xianliao_download_url")
        self:downloadTip(_tipStr, _dldUrl)
    elseif _type == "qinliao" then
        local _tipStr = "您还未下载亲聊\n是否前往下载？"
        local _dldUrl = gt.getConf("qinliao_download_url")
        self:downloadTip(_tipStr, _dldUrl)
    end
end

function NativeUtil:upgradeTip(_name)
    if gt.isPkgHasAbility(_name) then
        local _tipStr = "体验新功能,需要下载最新版本哦!\n是否前往下载？"
        self:downloadTip(_tipStr)
    else
        commonlib.showLocalTip("敬请期待!")
    end
end

-- 例子
-- local ret = NativeUtil:isInstallThird({typ="xianliao"})
function NativeUtil:isInstallThird(args)
    local args     = args or {typ = "xianliao"}
    local abliName = "isInstallXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "isInstallThird"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if ok then
            return ret
        else
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local data = {
            json.encode(args),
        }
        local funcName  = "isInstallThird"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(Ljava/lang/String;)I"
        local className = "com/sy18/luaj/XZUtil"
        local ok, ret = luaj.callStaticMethod(className, funcName, data, sigs)
        if ok then
            return ret
        else
            print("not ok The ret is:", ret)
        end
    end
end

-- 例子
-- NativeUtil:loginThird({
--     typ = "xianliao",
--     state = "" .. os.time(),
--     classId = function(ret)
--         dump(ret,"loginThird")
--     end
-- })
function NativeUtil:loginThird(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        self:loginXianLiao(args)
    elseif args.typ == "qinliao" then
        self:loginQinLiao(args)
    end
end

function NativeUtil:loginThirdCommon(args)
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "loginThird"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
            json.encode(args),
        }
        local funcName  = "loginThird"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(ILjava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

function NativeUtil:loginXianLiao(args)
    local abliName = "loginXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:loginThirdCommon(args)
end

function NativeUtil:loginQinLiao(args)
    local abliName = "loginQinLiao"
    if device.platform == "ios" then
        abliName = "loginQinLiao2"
    end
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:loginThirdCommon(args)
end

-- 例子
-- NativeUtil:shareText({
--     typ = "xianliao",
--     text = content,
--     classId = function(ret)
--         dump(ret,"code")
--     end
-- })
function NativeUtil:shareText(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        self:shareTextXianLiao(args)
    end
end

function NativeUtil:shareTextXianLiao(args)
    local abliName = "shareTextXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "shareText"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
            json.encode(args),
        }
        local funcName  = "shareTextText"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(ILjava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

-- 例子
-- NativeUtil:shareLink({
--     typ = "xianliao",
--     title = title,
--     text = content,
--     url = share_url,
--     imageUrl = gt.getConf("share_image_url"),
--     classId = function(ret)
--         dump(ret,"code")
--     end,
-- })
function NativeUtil:shareLink(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        self:shareLinkXianLiao(args)
    elseif args.typ == "qinliao" then
        self:shareLinkQinLiao(args)
    end
end

function NativeUtil:shareLinkCommon(args)
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "shareLink"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
            json.encode(args),
        }
        local funcName  = "shareLink"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(ILjava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

function NativeUtil:shareLinkXianLiao(args)
    local abliName = "shareLinkXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:shareLinkCommon(args)
end

function NativeUtil:shareLinkQinLiao(args)
    local abliName = "shareLinkQinLiao"
    if device.platform == "ios" then
        abliName = "shareLinkQinLiao2"
    end
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:shareLinkCommon(args)
end

-- 例子
-- local clubData = require("login.clubData")
-- local club_id = clubData.getClubId()
-- local clubId = club_id and tostring(club_id) or ""
-- NativeUtil:shareGame({
--     typ = "xianliao",
--     title = title,
--     text = content,
--     roomToken = clubId,
--     roomId = tostring(roomid),
--     url = share_url,
--     imageUrl = gt.getConf("share_image_url"),
--     -- androidDownloadUrl = "https://fir.im/nt2p",
--     -- iOSDownloadUrl = "https://fir.im/13yp",
--     classId = function(ret)
--         dump(ret,"code")
--     end
-- })
function NativeUtil:shareGame(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        self:shareGameXianLiao(args)
    end
end

function NativeUtil:shareGameXianLiao(args)
    local abliName = "shareGameXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "shareGame"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
            json.encode(args),
        }
        local funcName  = "shareGame"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(ILjava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

-- 例子
-- NativeUtil:shareUrlImageXianLiao({
--     typ = "xianliao",
--     imageUrl = gt.getConf("share_image_url"),
--     classId = function(ret)
--         dump(ret,"code")
--     end
-- })
function NativeUtil:shareUrlImage(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        self:shareUrlImageXianLiao(args)
    end
end

function NativeUtil:shareUrlImageXianLiao(args)
    local abliName = "shareUrlImageXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "shareUrlImage"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        -- SDK 没接口
    end
end

-- 例子
-- NativeUtil:shareDataImage({
--     typ = "xianliao",
--     classId = function(ret)
--         dump(ret,"code")
--     end
-- })
function NativeUtil:shareDataImage(_args)
    local args = _args or {}
    if args.typ == "xianliao" then
        gt.printScreen(function(argsPrint)
            args.imageUrl = argsPrint.fileUrl
            self:shareDataImageXianLiao(args)
        end)
    elseif args.typ == "qinliao" then
        gt.printScreen(function(argsPrint)
            args.imageUrl = argsPrint.fileUrl
            self:shareDataImageQinLiao(args)
        end)
    end
end

function NativeUtil:shareDataImageCommon(args)
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "shareDataImage"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
            json.encode(args),
        }
        local funcName  = "shareImage"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(ILjava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

function NativeUtil:shareDataImageXianLiao(args)
    local abliName = "shareDataImageXianLiao"
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:shareDataImageCommon(args)
end

function NativeUtil:shareDataImageQinLiao(args)
    local abliName = "shareDataImageQinLiao"
    if device.platform == "ios" then
        abliName = "shareDataImageQinLiao2"
    end
    if not self:getAbility(abliName) then
        self:upgradeTip(abliName)
        return
    end
    self:shareDataImageCommon(args)
end

-- 例子
-- NativeUtil:getGameInfo({
--     classId = function(ret)
--         dump(ret,"code")
--     end
-- })

function NativeUtil:getGameInfo(args)
    local abliName = "getGameInfo"
    if not self:getAbility(abliName) then
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "getGameInfo"
        local className = "XZUtil"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local classId = args.classId
        args.classId  = nil
        local data = {
            function(event)
                local tab = json.decode(event)
                if tab and classId then
                    pcall(function(...)
                        classId(tab)
                    end)
                end
            end,
        }
        local funcName  = "getGameInfo"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(I)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, data, sigs)
    end
end

function NativeUtil:Log(...)
    if not self:getAbility("Log") then return end
    if g_os == "android" then
        local msg = ""
        for i, v in ipairs({...}) do
            msg = msg .. v .. "    "
        end
        local funcName  = "Log"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(Ljava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        luaj.callStaticMethod(className, funcName, {msg}, sigs)
    end
end

function NativeUtil:locationSet()
    if not self:getAbility("locationSet") then return end
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local args      = {}
        local className = "XZUtil"
        local funcName  = "locationSet"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("locationSet ok ret", ret)
        end
    elseif g_os == "android" then
        local luaj      = require("cocos.cocos2d.luaj")
        local args      = {}
        local sigs      = "()V"
        local className = "com/sy18/luaj/XZUtil"
        local funcName  = "locationSet"
        local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
        if not ok then
            print("locationSet ok ret", ret)
        end
    end
end

function NativeUtil:currentBatteryPercent()
    if not self:getAbility("currentBatteryPercent") then return end
    if self.isBattery == true then return end
    self.isBattery = true
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local args      = {}
        local className = "XZUtil"
        local funcName  = "currentBatteryPercent"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("currentBatteryPercentnot ok ret", ret)
        end
    elseif g_os == "android" then
        local luaj      = require("cocos.cocos2d.luaj")
        local args      = {}
        local sigs      = "()V"
        local className = "com/sy18/luaj/XZUtil"
        local funcName  = "currentBatteryPercent"
        local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
        if not ok then
            print("currentBatteryPercent ok ret", ret)
        end
    end
end

function NativeUtil:getBattery()
    local rst = 100
    if self:getAbility("getBattery") then
        if g_os == "ios" then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "getBattery"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok then
                rst = ret
            end
        elseif g_os == "android" then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()I"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "getBattery"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok then
                rst = ret
            end
        end
    end
    return rst
end

function NativeUtil:getSignalStrength()
    if not self:getAbility("getSignalStrength") then return end
    if self.isSignal == true then return end
    self.isSignal = true
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local args      = {}
        local className = "XZUtil"
        local funcName  = "getSignalStrength"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("getSignalStrength ok ret", ret)
        end
    elseif g_os == "android" then
        local luaj      = require("cocos.cocos2d.luaj")
        local args      = {}
        local sigs      = "()V"
        local className = "com/sy18/luaj/XZUtil"
        local funcName  = "getSignalStrength"
        local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
        if not ok then
            print("getSignalStrength ok ret", ret)
        end
    end
end

function NativeUtil:getSignal()
    local rst = {
        signal = 3,
        typ    = 1,
    }
    if self:getAbility("getSignal") then
        local retStr = nil
        if g_os == "ios" then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "getSignal"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok and ret and #ret > 0 then
                retStr = ret
            end
        elseif g_os == "android" then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()Ljava/lang/String;"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "getSignal"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok and ret and #ret > 0 then
                retStr = ret
            end
        end
        if retStr then
            local temp = json.decode(retStr)
            if temp and temp.signal and temp.typ then
                rst.signal = temp.signal
                rst.typ    = temp.typ
            end
        end
    end
    return rst
end

function NativeUtil:isDingTalkInstalled()
    -- -1/0/1 异常/未安装/已安装
    local result = -1
    if g_os == "ios" then
        if self:getAbility("isDingTalkInstalled") then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "isDingTalkInstalled"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok then
                result = ret
            else
                print("not ok ret", ret)
            end
        end
    elseif g_os == "android" then
        if self:getAbility("isDDAppInstalled") then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()I"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "isDDAppInstalled"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok then
                result = ret
            else
                print("not ok ret", ret)
            end
        end
    end
    print("NativeUtil:isDingTalkInstalled", result)
    return result
end

function NativeUtil:isDingTalkSupportOpenAPI()
    -- -1/0/1 异常/未安装/已安装
    local result = -1
    if g_os == "ios" then
        if self:getAbility("isDingTalkSupportOpenAPI") then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "isDingTalkSupportOpenAPI"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok then
                result = ret
            end
        end
    elseif g_os == "android" then
        if self:getAbility("isDDSupportAPI") then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()I"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "isDDSupportAPI"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok then
                result = ret
            end
        end
    end
    print("NativeUtil:isDingTalkSupportOpenAPI", result)
    return result
end

function NativeUtil:isYXAppInstalled()
    -- -1/0/1 异常/未安装/已安装
    local result = -1
    if g_os == "ios" then
        if self:getAbility("isYXAppInstalled") then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "isYXAppInstalled"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok then
                result = ret
            end
        end
    elseif g_os == "android" then
        if self:getAbility("isYXAppInstalled") then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()I"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "isYXAppInstalled"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok then
                result = ret
            end
        end
    end
    print("NativeUtil:isYXAppInstalled", result)
    return result
end

function NativeUtil:isYXAppSupportApi()
    -- -1/0/1 异常/未安装/已安装
    local result = -1
    if g_os == "ios" then
        if self:getAbility("isYXAppSupportApi") then
            local luaoc     = require("cocos.cocos2d.luaoc")
            local args      = {}
            local className = "XZUtil"
            local funcName  = "isYXAppSupportApi"
            local ok, ret = luaoc.callStaticMethod(className, funcName, args)
            if ok then
                result = ret
            end
        end
    elseif g_os == "android" then
        if self:getAbility("isYXAppInstalled") then
            local luaj      = require("cocos.cocos2d.luaj")
            local args      = {}
            local sigs      = "()I"
            local className = "com/sy18/luaj/XZUtil"
            local funcName  = "isYXAppInstalled"
            local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
            if ok then
                result = ret
            end
        end
    end
    print("NativeUtil:isYXAppSupportApi", result)
    return result
end

function NativeUtil:openApp(appScheme)
    if not self:getAbility("openApp") then return end
    local args = {appScheme = appScheme}
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local className = "XZUtil"
        local funcName  = "openApp"
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif g_os == "android" then
        local luaj      = require("cocos.cocos2d.luaj")
        local args      = {json.encode(args)}
        local sigs      = "(Ljava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        local funcName  = "openApp"
        local ok, ret = luaj.callStaticMethod(className, funcName, args, sigs)
        if not ok then
            print("not ok The ret is:", ret)
        end
    end
end

function NativeUtil:getPasteboard()
    if not self:getAbility("getPasteboard") then return "" end
    local retStr = ""
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "getPasteboard"
        local className = "XZUtil"
        local args      = {}
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    elseif g_os == "android" then
        local funcName  = "getPasteboard"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "()Ljava/lang/String;"
        local className = "com/sy18/luaj/XZUtil"
        local ok, ret = luaj.callStaticMethod(className, funcName, {}, sigs)
        if not ok then
            print("not ok The ret is:", ret)
        else
            retStr = ret
        end
    end
    return retStr
end

-- 开启检测权限
function NativeUtil:checkNetWorkPermission()
    if not self:getAbility("checkNetWorkPermission") then
        return rst
    end
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "checkNetWorkPermission"
        local className = "XZUtil"
        local args      = {}
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        end
    elseif g_os == "android" then
        -- local funcName = "checkNetWorkPermission"
        -- local luaj = require("cocos.cocos2d.luaj")
        -- local sigs = "()Ljava/lang/String;"
        -- local className = "com/sy18/luaj/XZUtil"
        -- local ok,ret  = luaj.callStaticMethod(className,funcName,{},sigs)
        -- if not ok then
        --     print("not ok The ret is:", ret)
        -- end
    end
end

-- 是否有权限 0 关闭 1 仅wifi 2 流量+wifi
-- ios 0检测不到 所以暂时仅用1和2判断
function NativeUtil:getNetWorkPermission()
    local rst = 2
    if not self:getAbility("getNetWorkPermission") then
        return rst
    end
    if g_os == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "getNetWorkPermission"
        local className = "XZUtil"
        local args      = {}
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("not ok The ret is:", ret)
        else
            print("getNetWorkPermission", ret)
            rst = ret
        end
    elseif g_os == "android" then
        -- local funcName = "getNetWorkPermission"
        -- local luaj = require("cocos.cocos2d.luaj")
        -- local sigs = "()Ljava/lang/String;"
        -- local className = "com/sy18/luaj/XZUtil"
        -- local ok,ret  = luaj.callStaticMethod(className,funcName,{},sigs)
        -- if not ok then
        --     print("not ok The ret is:", ret)
        -- else
        --     rst = ret
        -- end
    end
    return rst
end

-- 例子
function NativeUtil:setBuglyUserId(userId)
    local abliName = "setBuglyUserId"
    if not self:getAbility(abliName) then
        return
    end
    if device.platform == "ios" then
        local luaoc     = require("cocos.cocos2d.luaoc")
        local funcName  = "setBuglyUserId"
        local className = "XZUtil"
        local args = {
            userId = tostring(userId),
        }
        local ok, ret = luaoc.callStaticMethod(className, funcName, args)
        if not ok then
            print("!!!!!!setBuglyUserId not ok The ret is:", ret)
        end
    elseif device.platform == "android" then
        local data = {
            tostring(userId),
        }
        local funcName  = "setBuglyUserId"
        local luaj      = require("cocos.cocos2d.luaj")
        local sigs      = "(Ljava/lang/String;)V"
        local className = "com/sy18/luaj/XZUtil"
        local ok, ret = luaj.callStaticMethod(className, funcName, data, sigs)
        if ok then

        else
            print("not ok The ret is:", ret)
        end
    end
end

return NativeUtil