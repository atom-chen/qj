commonlib = commonlib or {}

gt = gt or {}

local function isCocos2dx317()
    if cocos2dVersionCode and cocos2dVersionCode() >= 0x00031701 then
        return true
    else
        return false
    end
end
gt.isCocos2dx317 = isCocos2dx317

local function getPackageName()
    local pkgName = "com.sy18.qjqp"
    if g_os == "ios" then
        pkgName = "com.xzkj.qwer.qjqp"
    end
    local app_info = nil
    if ymkj and ymkj.getAppInfo then
        app_info = ymkj.getAppInfo()
    end
    if app_info and app_info ~= "" then
        local tab = string.split(app_info, "|")
        if tab[2] then
            pkgName = tab[2]
        end
    end
    return pkgName
end
gt.getPackageName = getPackageName

local NativeUtil = require("common.NativeUtil")
NativeUtil:init()

-- 99yixin for commit
local local_conf = {
    wxFkFk             = "QJKFU006",
    wxFkYx             = "QJKFU003",
    download_url       = "https://xz.oozzh.com/?qj=",
    iosdownload_url    = "https://xz.oozzh.com/?qj=",
    game_conf_url      = "http://yl04.nnzzh.com/ylqj/game_conf.lua",
    game_conf_tyb_url  = "http://yl04.nnzzh.com/ylqjtyb/game_conf.lua",
    game_conf_test_url = "http://47.96.62.50/pre_release/ylqj/game_conf.lua",
    gongzhonghao       = "yl-huyu01",
    version_url        = "http://yl04.nnzzh.com/ylqj/ylqj.txt",
    version_url_tyb    = "http://yl04.nnzzh.com/ylqjtyb/ylqj.txt",
    version_url_test   = "http://47.96.62.50/pre_release/ylqj/ylqj.txt",
    zj_link_url        = "http://charge.qj.skjhwui.com/shareGameRecord/",
    zj_link_url_tyb    = "http://charge.qj.99yixin.cn/shareGameRecord_tyb/",
    qyqshare_url       = "http://charge.qj.99yixin.cn/qj_club/?c=",
    qyqshare_url_tyb   = "http://charge.qj.99yixin.cn/qj_club_tyb/?c=",
    wx_charge_url      = "http://charge.qj.99yixin.cn/wechat_h5/club_h5.php",
    -- 语音服务器地址
    voice_url             = "http://speakmj.99thj.com/up_voice.php",
    log_url               = "http://118.89.182.159:8081",
    redbag_url            = "http://charge.qj.99yixin.cn/qjhb/api.php",
    redbag_server         = "47.105.171.81:8003", -- "139.129.107.113:8003", --@120.27.83.88:8003
    redbag_appid          = 6,
    redbag_lq_url         = "http://charge.qj.99yixin.cn/tjhb/hb/second.php",
    redbag_writings_rul   = "http://charge.qj.99yixin.cn/tjhb/hb/get_unionid.php",
    send_club_uid_url     = "http://charge.qj.99yixin.cn/qjim/join_team.php",
    share_image_url       = "http://yl04.nnzzh.com/ylqj/share_icon.png",
    xianliao_download_url = "https://a.app.qq.com/o/simple.jsp?pkgname=org.xianliao",
    qinliao_download_url  = "http://xz.csxzhy.cn/?qinliao",
    qinliao_push_url      = "http://other.qj.oozzh.com/bind_qinliao_group/",
    abilitys              = "openApp,",
    is_use_tjd            = 1,
    server_ip             = {{{ip = "wstfcccthjgm46", port = 8361, fail = false}}},
    -- 分享聊天室地址
    share_chat_url = "http://charge.qj.99xzkj.cn/qjim/",
    -- 提醒更新的基础版本
    notice_update_version = 7,
}

local function getConf(key)
    local ret = local_conf[key]
    if gt.local_game_conf and gt.local_game_conf[key] then
        if key == "abilitys" then
            ret = ret .. gt.local_game_conf[key]
        else
            ret = gt.local_game_conf[key]
        end
    end
    if gt.game_conf and gt.game_conf[key] then
        if key == "abilitys" then
            ret = ret .. gt.game_conf[key]
        else
            ret = gt.game_conf[key]
        end
    end
    if gt.db_conf and gt.db_conf[key] then
        if key == "abilitys" then
            ret = ret .. gt.db_conf[key]
        else
            ret = gt.db_conf[key]
        end
    end
    return ret
end
gt.getConf = getConf

local function saveLocalGameConf(_confStr)
    if type(_confStr) == "string" then
        cc.UserDefault:getInstance():setStringForKey("local_game_conf", _confStr)
        cc.UserDefault:getInstance():flush()
    end
end
gt.saveLocalGameConf = saveLocalGameConf

local function saveLocalIp(_ip)
    if g_os == 'win' then
        return
    end
    if type(_ip) == 'string' then
        cc.UserDefault:getInstance():setStringForKey("local_ip", _ip)
        cc.UserDefault:getInstance():flush()
    end
end
gt.saveLocalIp = saveLocalIp

local function initLocalIp()
    if g_os == 'win' then
        return
    end
    if g_ip_list then return end
    g_ip_list = gt.getConf("server_ip")
    local _ip = cc.UserDefault:getInstance():getStringForKey("local_ip", '')
    if type(_ip) ~= 'string' or #_ip == 0 then
        return
    end
    local func = function()
        return json.decode(_ip)
    end
    local ret, local_ip = pcall(func)
    if ret and local_ip then
        g_ip_list = local_ip
    end
end
gt.initLocalIp = initLocalIp
gt.initLocalIp()

local function initLocalGameConf()
    local _confStr = cc.UserDefault:getInstance():getStringForKey("local_game_conf", "")
    if type(_confStr) ~= "string" or #_confStr == 0 then
        return
    end
    local func = loadstring("return ".._confStr)
    local ret, local_game_conf = pcall(func)
    if ret and local_game_conf then
        gt.local_game_conf = local_game_conf
        dump(local_game_conf, "local_game_conf")
    end
end
gt.initLocalGameConf = initLocalGameConf

gt.initLocalGameConf()

local function isPkgHasAbility(_name)
    local abilitys = gt.getConf("abilitys")
    if abilitys then
        return string.find(abilitys, _name)
    end
end
gt.isPkgHasAbility = isPkgHasAbility

local function openApp(_name)
    local tip = "微信"
    if NativeUtil:getAbility("openApp") then
        NativeUtil:openApp(_name)
    else
        if gt.isPkgHasAbility("openApp") then
            commonlib.showExitTip(string.format("打开%s请更新到最新版本", tip), function(ok)
                if ok then
                    ymkj.ymIM(100, "", "")
                end
            end)
        else
            commonlib.showLocalTip("敬请期待")
        end
    end
end
gt.openApp = openApp

local oldTime     = 0
local newTime     = 0
local oldFuncName = "start"
local newFuncName = "start"
local function printTime(_name)
    if g_is_debug then
        oldTime     = newTime
        oldFuncName = newFuncName
        local info  = debug.getinfo(2, "n")
        newTime     = os.clock()
        if oldTime == 0 then
            oldTime = newTime
        end
        newFuncName = _name or info.name
        print(string.format("%s>>>>>>>>>>>%s %.2f", oldFuncName, newFuncName, newTime - oldTime))
    end
end
gt.printTime = printTime

local function performWithDelay(target, callback, delay)
    if tolua.isnull(target) then
        gt.uploadErr("error use invalid target")
        return
    end
    local seq = cc.Sequence:create(cc.DelayTime:create(delay), cc.CallFunc:create(function()
        if not tolua.isnull(target) then
            callback()
        end
    end))
    target:runAction(seq)
end
gt.performWithDelay = performWithDelay

local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end
gt.urlEncode = urlEncode

local function urlDecode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end
gt.urlDecode = urlDecode

local function openUrl(_url)
    if #_url > 0 and string.find(_url, "http") then
        print("openUrl", _url)
        local temp  = g_share_url
        g_share_url = _url
        ymkj.ymIM(100, "", "")
        g_share_url = temp
    end
end
gt.openUrl = openUrl

local function getData(_name)
    local profile = ProfileManager.GetProfile()
    if not profile then return nil end
    return profile[_name]
end
gt.getData = getData

local curWeChatAppId = nil
if ymkj and ymkj.registerApp then
    local tempFunc = ymkj.registerApp
    ymkj.registerApp = function(appid)
        curWeChatAppId = appid
        tempFunc(appid)
    end
end

local function getCurWeChatAppId()
    return curWeChatAppId
end
gt.getCurWeChatAppId = getCurWeChatAppId

local currentAppId = nil
local tempAppId    = nil
local function wechatShareChatStart()
    currentAppId = gt.getCurWeChatAppId()
    tempAppId    = NativeUtil:getRandAppId()
    if currentAppId and tempAppId then
        ymkj.registerApp(tempAppId)
    end
end
gt.wechatShareChatStart = wechatShareChatStart

local function wechatShareChatEnd()
    if currentAppId and tempAppId then
        ymkj.registerApp(currentAppId)
    end
end
gt.wechatShareChatEnd = wechatShareChatEnd

function commonlib.showShareBtn(btn_list, content, ori_title, roomid, copy, getChaPeople)
    for i, v in ipairs(btn_list or {}) do
        if ios_checking and (i == 1 or i == 2) then
            v:setVisible(false)
        end
        if not content or not ori_title then
            v:setVisible(false)
            v:setTouchEnabled(false)
        else
            v:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local title  = ori_title
                    local people = nil
                    if getChaPeople then
                        title  = title..getChaPeople()
                        people = getChaPeople()
                    else
                        people = ""
                    end
                    local share_url = g_share_url
                    if roomid then
                        share_url = share_url.."&room_id="..roomid
                    end
                    if i == 2 or (g_copy_share and i == 1) then
                        ymkj.copyClipboard("房间号:"..roomid.."\n"..content..
                        "\n速度加入【"..string.sub(g_game_name, 4, -4) .. "】("..people..")\n游戏下载地址:"..share_url)
                        print("房间号:"..roomid.."\n"..content..
                        "\n速度加入【"..string.sub(g_game_name, 4, -4) .. "】("..people..")\n游戏下载地址:"..share_url)

                        require('scene.DTUI')
                        local csb  = DTUI.getInstance().csb_copyroomtip
                        local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
                        cc.Director:getInstance():getRunningScene():addChild(node, 999)
                        node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                        ccui.Helper:doLayout(node)

                        ccui.Helper:seekWidgetByName(node, "texit"):addTouchEventListener(
                            function(sender, eventType)
                                if eventType == ccui.TouchEventType.ended then
                                    AudioManager:playPressSound()
                                    node:removeFromParent(true)
                                end
                            end
                        )
                        ccui.Helper:seekWidgetByName(node, "openwx"):addTouchEventListener(
                            function(sender, eventType)
                                if eventType == ccui.TouchEventType.ended then
                                    AudioManager:playPressSound()
                                    NativeUtil:openApp("weixin")
                                end
                            end
                        )
                    elseif i == 1 then
                        local data = {
                            ["title"]       = title,
                            ["copy"]        = copy,
                            ["share_url"]   = share_url,
                            ["content"]     = content,
                            ["roomid"]      = roomid,
                            ["people"]      = people,
                            ["isRoomShare"] = true,
                        }
                        local ShareWindow = require("scene.ShareWindow")
                        cc.Director:getInstance():getRunningScene():addChild(ShareWindow:create(data), 100)
                    elseif i == 3 then
                        -- local time = os.date("%m%d%H",os.time())
                        -- if tonumber(time) <= 501010 then
                        --     commonlib.showLocalTip("钉钉分享明日10时开放")
                        -- else
                        if g_can_ddshare then
                            ymkj.wxReq(2, content, title, share_url, 10)
                            print(title.."\n"..content.."\n"..share_url.."\n打开钉钉分享")
                        else
                            commonlib.showTipDlg("钉钉分享请更新到最新版本\n(需卸载当前版本再安装)", function()
                                ymkj.ymIM(100, "", "")
                            end)
                        end
                        -- end
                    elseif i == 4 then
                        -- local time = os.date("%m%d%H",os.time())
                        -- if tonumber(time) <= 501010 then
                        --     commonlib.showLocalTip("易信分享明日8时开放")
                        -- else
                        -- 钉钉分享的包和易信的包同时上传的
                        if g_can_ddshare then
                            ymkj.wxReq(2, content, title, share_url, 20)
                            print(title.."\n"..content.."\n"..share_url.."\n打开易信分享")
                        else
                            commonlib.showTipDlg("易信分享请更新到最新版本\n(需卸载当前版本再安装)", function()
                                ymkj.ymIM(100, "", "")
                            end)
                        end
                        -- end
                    end
                end
            end)
        end
    end
end

function commonlib.shareResult(node, str, title, roomid, copy, params)
    local share_url = g_share_url
    if roomid then
        share_url = share_url.."&room_id="..roomid
    end

    local wxfx = ccui.Helper:seekWidgetByName(node, "btn-fxzj") or ccui.Helper:seekWidgetByName(node, "btn-fenxiang")
    if wxfx then
        wxfx:setVisible(not ios_checking)
        wxfx:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local ShareWindow = require("scene.ShareWindow")
                local data = {
                    ["str"]    = str,
                    ["title"]  = title,
                    ["copy"]   = copy,
                    ["params"] = params,
                }
                node:addChild(ShareWindow:create(data), 100)
            end
        end)
        -- if ios_checking or g_author_game then wxfx:setVisible(false) end
    end

    local fzzj = ccui.Helper:seekWidgetByName(node, "btn-fzzj")
    if fzzj then
        fzzj:setVisible(not ios_checking)
        fzzj:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if ymkj.copyClipboard then
                    ymkj.copyClipboard(title.."\n"..str)
                else
                    commonlib.showTipDlg("您的版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
                        ymkj.ymIM(100, "", "")
                    end)
                end
                print(title.."\n"..str)
                commonlib.showLocalTip("复制成功，可切换微信分享")
            end
        end)
        if ios_checking or g_author_game then fzzj:setVisible(false) end
    end

    local zjlink = ccui.Helper:seekWidgetByName(node, "btn-zjlink")
    if zjlink then
        zjlink:setVisible(not ios_checking)
        if not params.log_ju_id then
            zjlink:setVisible(false)
        end
        zjlink:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local title   = string.format("战绩分享-房间号:%s", tostring(roomid))
                local content = ""
                for i, v in ipairs(params.players or {}) do
                    content = content .. string.format("【%s】", v.nickname)
                end
                local bas   = ymkj.base64Encode(tostring(params.log_ju_id))
                local zjUrl = string.format("%s?s=%s", gt.getConf("zj_link_url"), bas)
                if test_package == 1 then
                    zjUrl = string.format("%s?s=%s", gt.getConf("zj_link_url_tyb"), bas)
                end
                gt.wechatShareChatStart()
                ymkj.wxReq(2, content, title, zjUrl)
                gt.wechatShareChatEnd()
                print(title.."\n"..content.."\n"..zjUrl.."\n打开微信分享")
            end
        end)
        if ios_checking then zjlink:setVisible(false) end
    end
    local btCopy = ccui.Helper:seekWidgetByName(node, "btn-copy")
    if btCopy then
        btCopy:setVisible(not ios_checking)
        btCopy:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local bas   = ymkj.base64Encode(tostring(params.log_ju_id))
                local zjUrl = string.format("%s?s=%s", gt.getConf("zj_link_url"), bas)
                if test_package == 1 then
                    zjUrl = string.format("%s?s=%s", gt.getConf("zj_link_url_tyb"), bas)
                end
                log(title.."\n"..str.."点击查看:"..zjUrl)
                if ymkj.copyClipboard then
                    ymkj.copyClipboard(title.."\n"..str.."点击查看:"..zjUrl)
                else
                    commonlib.showTipDlg("您的版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
                        ymkj.ymIM(100, "", "")
                    end)
                end

                require('scene.DTUI')
                local csb  = DTUI.getInstance().csb_copyroomtip
                local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
                cc.Director:getInstance():getRunningScene():addChild(node, 999)
                node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(node)
                local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text")
                content:setString("战绩信息复制成功，请打开微信，选择粘\n贴，发送复制的内容")
                ccui.Helper:seekWidgetByName(node, "texit"):addTouchEventListener(
                    function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            node:removeFromParent(true)
                        end
                    end
                )
                ccui.Helper:seekWidgetByName(node, "openwx"):addTouchEventListener(
                    function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            print("打开微信")
                            NativeUtil:openApp("weixin")
                        end
                    end
                )
            end
        end)
    end
end

package.loaded["common.IpMgr"] = nil
gt.IpMgr                       = require("common.IpMgr").new()

local mydump = dump
dump = function(...)
    if g_os == "win" or g_is_debug then
        mydump(...)
    end
end

if commonlib and commonlib.echo then
    local echo = commonlib.echo
    commonlib.echo = function(...)
        if g_os == "win" or g_is_debug then
            echo(...)
        end
    end
end

print = function(...)
    if g_os == "win" or g_is_debug then
        release_print(...)
    end
end

-- 播放响应的骨骼动画
local function playInteractiveSpine(_prt, _name)
    local spineFile        = nil
    local is_back_fromroom = nil
    local num              = 1
    if cc.UserDefault:getInstance():getStringForKey("is_back_fromroom") ~= "" then
        is_back_fromroom = cc.UserDefault:getInstance():getStringForKey("is_back_fromroom")
    end
    local hall_style = gt.getLocalString("hall_style")
    -- 经典风格
    if _name == "shaoxiang" then
        spineFile = "ui/qj_play/interactiveSpine/neimenggu_baishen"
    elseif _name == "xishou" then
        spineFile = "ui/qj_play/interactiveSpine/neimenggu_choushouDH"
    elseif _name == "juese" then
        spineFile = "ui/qj_main/zhujiemian/jueseqietu"
    elseif _name == "chuangjianfangjian" then
        spineFile = "ui/qj_main/zhujiemian/zhujiemiananniu_spine"
    elseif _name == "jiarufangjian" then
        spineFile = "ui/qj_main/zhujiemian/zhujiemiananniu_spine"
    elseif _name == "qinyouquan" then
        spineFile = "ui/qj_main/zhujiemian/zhujiemiananniu_spine"
    elseif _name == "kaiju" then
        spineFile = 'ui/qj_mj/huSpine/kaiju'
    end

    -- 怀旧风格
    if hall_style == "huaijiu" then
        -- 人物动画
        if _name == "juese" then
            spineFile = "ui/qj_main_before/SX_home_spine/SXrenwuDH1_5"
        -- 创建房间动画
        elseif _name == "chuangjianfangjian" then
            spineFile = "ui/qj_main_before/SX_home_spine/denglong"
        -- 加入房间动画
        elseif _name == "jiarufangjian" then
            spineFile = "ui/qj_main_before/SX_home_spine/denglong"
        -- 亲友圈动画
        elseif _name == "qinyouquan" then
            spineFile = "ui/qj_main_before/SX_home_spine/denglong"
        end
    end
    if not spineFile then return end
    skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
    if _name == "juese" then
        if ios_checking then
            local sp         = cc.Sprite:create("ui/qj_main/js.png")
            local windowSize = cc.Director:getInstance():getWinSize()
            sp:setPosition(cc.p(windowSize.width / 1.3 - 150, windowSize.height / 2))
            _prt:addChild(sp)
        else
            local windowSize = cc.Director:getInstance():getWinSize()
            if hall_style == "huaijiu" then
                skeletonNode:setAnimation(0, "animation", true)
                skeletonNode:setScale(0.98)
                skeletonNode:setPosition(cc.p(windowSize.width / 2 - 290, windowSize.height / 2 - 390))
            else
                skeletonNode:setAnimation(0, "idle", true)
                skeletonNode:setScale(1.0)
                skeletonNode:setPosition(cc.p(windowSize.width / 1.3 + 15, windowSize.height / 2 - 210))
            end
            _prt:addChild(skeletonNode)
        end
    elseif _name == "chuangjianfangjian" then
        if ios_checking then
            local windowSize = cc.Director:getInstance():getWinSize()
            local pst        = cc.p(windowSize.width / 2 - 5, windowSize.height / 2 + 130)
            if ios_checking then
                pst = cc.p(windowSize.width / 2 - 250, windowSize.height / 2 + 130)
            end
            local sp = cc.Sprite:create("ui/qj_main/cjgj.png")
            sp:setPosition(pst)
            _prt:addChild(sp)
        else
            local windowSize = cc.Director:getInstance():getWinSize()
            if hall_style == "huaijiu" then
                skeletonNode:setAnimation(0, "jianfangjian", true)
                skeletonNode:setScale(1)
                local pst        = cc.p(windowSize.width / 2 + 150, windowSize.height / 2 + 130)
                if ios_checking then
                    pst = cc.p(windowSize.width / 2 - 250, windowSize.height / 2 + 130)
                end
                skeletonNode:setPosition(pst)
            else
                skeletonNode:setAnimation(0, "chuangjianfangjian", true)
                skeletonNode:setScale(1.0)
                local pst        = cc.p(windowSize.width / 2 - 5, windowSize.height / 2 + 130)
                if ios_checking then
                    pst = cc.p(windowSize.width / 2 - 250, windowSize.height / 2 + 130)
                end
                skeletonNode:setPosition(pst)
            end
            _prt:addChild(skeletonNode)
        end
    elseif _name == "jiarufangjian" then
        if ios_checking then
            local windowSize = cc.Director:getInstance():getWinSize()
            local pst        = cc.p(windowSize.width / 2 - 5, windowSize.height / 2 - 100)
            if ios_checking then
                pst = cc.p(windowSize.width / 2 - 250, windowSize.height / 2 - 100)
            end
            local sp = cc.Sprite:create("ui/qj_main/jrfj.png")
            sp:setPosition(pst)
            _prt:addChild(sp)
        else
            if is_back_fromroom == "true" then
                if hall_style == "huaijiu" then
                    skeletonNode:setAnimation(0, "jinyouxi1", false)
                else
                    skeletonNode:setAnimation(0, "fanhuifangjian1", false)
                    for i = 1, 100 do
                        num = math.random(1, 2)
                        skeletonNode:addAnimation(0, "fanhuifangjian"..num, false)
                        skeletonNode:setMix("fanhuifangjian1", "fanhuifangjian2", 0.2)
                        if i == 100 then
                            skeletonNode:addAnimation(0, "fanhuifangjian1", true)
                        end
                    end
                end
            else
                if hall_style == "huaijiu" then
                    skeletonNode:setAnimation(0, "jinyouxi", false)
                else
                    skeletonNode:setAnimation(0, "jiarufangjian1", false)
                    for i = 1, 100 do
                        num = math.random(1, 2)
                        skeletonNode:addAnimation(0, "jiarufangjian"..num, false)
                        skeletonNode:setMix("jiarufangjian1", "jiarufangjian2", 0.2)
                        if i == 100 then
                            skeletonNode:addAnimation(0, "jiarufangjian1", true)
                        end
                    end
                end
            end
            local windowSize = cc.Director:getInstance():getWinSize()
            if hall_style == "huaijiu" then
                skeletonNode:setScale(1.0)
                local pst        = cc.p(windowSize.width - 150, windowSize.height / 2 + 270)
                if ios_checking then
                    pst = cc.p(windowSize.width / 2 - 160, windowSize.height / 2 - 100)
                end
                skeletonNode:setPosition(pst)
            else
                -- skeletonNode:setName('Spine_jiaru')
                skeletonNode:setScale(1.0)
                local pst        = cc.p(windowSize.width / 2 - 5, windowSize.height / 2 - 100)
                if ios_checking then
                    pst = cc.p(windowSize.width / 2 - 160, windowSize.height / 2 - 100)
                end
                skeletonNode:setPosition(pst)
            end
            _prt:addChild(skeletonNode)
        end
    elseif _name == "qinyouquan" then
        local windowSize = cc.Director:getInstance():getWinSize()
        if hall_style == "huaijiu" then
            skeletonNode:setAnimation(0, "julebu", true)
            skeletonNode:setScale(1.0)
            skeletonNode:setPosition(cc.p(windowSize.width / 2 + 320, windowSize.height / 2 + 230))
        else
            skeletonNode:setAnimation(0, "qinyouquan", true)
            skeletonNode:setScale(1.0)
            skeletonNode:setPosition(cc.p(windowSize.width / 4 - 25, windowSize.height / 2 + 15))
        end
        _prt:addChild(skeletonNode)
    else
        skeletonNode:setAnimation(0, "animation", false)
        skeletonNode:setScale(1.0)
        local windowSize = cc.Director:getInstance():getWinSize()
        skeletonNode:setPosition(cc.p(windowSize.width / 2, windowSize.height / 2))
        _prt:addChild(skeletonNode, 100)
    end
    skeletonNode:setName(_name)
end
----------------------- 麻将spine玩家交互
function commonlib.runInteractiveEffect(panContainer, fromNode, toNode, emotionId, fromNodeindex, toNodeindex, is_zgz)
    -- if g_os == "win" then return end
    if not emotionId or emotionId < 101 or emotionId > 106 then return end
    local spineFile  = nil
    local sprEmotion = nil
    local sPos       = commonlib.worldPos(fromNode)
    local ePos       = commonlib.worldPos(toNode)

    if emotionId == 101 then
        spineFile  = "ui/chat/SX_chat_spine/SX_biaoqingqinwen"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/SX_biaoqingqinwen.png")
        AudioManager:playDWCSound("sound/chatFace_0.mp3")
    elseif emotionId == 102 then
        spineFile  = "ui/chat/SX_chat_spine/SX_biaoqingmeigui1"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/SX_biaoqingmeigui1.png")
        AudioManager:playDWCSound("sound/chatFace_1.mp3")
    elseif emotionId == 103 then
        spineFile  = "ui/chat/SX_chat_spine/xihongshi"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/xihongshi.png")
        AudioManager:playDWCSound("sound/chatFace_4.mp3")
    elseif emotionId == 104 then
        spineFile  = "ui/chat/SX_chat_spine/qiang"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/qiang.png")
        AudioManager:playDWCSound("sound/chatFace_5.mp3")
    elseif emotionId == 105 then
        spineFile  = "ui/chat/SX_chat_spine/chaju"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/chaju.png")
        AudioManager:playDWCSound("sound/chatFace_2.mp3")
    elseif emotionId == 106 then
        spineFile  = "ui/chat/SX_chat_spine/bangbangtang"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/bangbangtang.png")
        AudioManager:playDWCSound("sound/chatFace_3.mp3")
    end
    if not spineFile then return end
    panContainer:addChild(sprEmotion, 300)
    sprEmotion:setPosition(sPos)

    local speed        = 2000
    local dis          = cc.pGetDistance(sPos, ePos)
    local t            = dis / speed
    local moveTo1      = cc.MoveTo:create(t, ePos)
    local fadeOut1     = cc.FadeOut:create(0.1)
    local orbitcamere1 = cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0)
    local callfunc = cc.CallFunc:create(function()
        sprEmotion:removeFromParent(true)
        skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
        skeletonNode:setAnimation(0, "animation", false)
        skeletonNode:setPosition(ePos)
        panContainer:addChild(skeletonNode, 300)
        skeletonNode:setScale(1)
        if emotionId == 104 then
            if is_zgz then
                if toNodeindex == 1 or toNodeindex == 5 or toNodeindex == 6 then
                    skeletonNode:runAction(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0))
                end
            else
                if toNodeindex == 1 or toNodeindex == 4 or toNodeindex == 5 then
                    skeletonNode:runAction(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0))
                elseif toNodeindex == 3 and fromNodeindex == 2 then
                    skeletonNode:runAction(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0))
                end
            end
        end
        skeletonNode:runAction(cc.FadeOut:create(2))
    end)
    if emotionId == 104 then
        if is_zgz then
            if toNodeindex == 1 or toNodeindex == 5 or toNodeindex == 6 then
                local seq = cc.Sequence:create(orbitcamere1, moveTo1, fadeOut1, callfunc)
                sprEmotion:runAction(seq)
            else
                local seq = cc.Sequence:create(moveTo1, fadeOut1, callfunc)
                sprEmotion:runAction(seq)
            end
        else
            if toNodeindex == 1 or toNodeindex == 4 then
                local seq = cc.Sequence:create(orbitcamere1, moveTo1, fadeOut1, callfunc)
                sprEmotion:runAction(seq)
            elseif toNodeindex == 3 and fromNodeindex == 2 then
                local seq = cc.Sequence:create(orbitcamere1, moveTo1, fadeOut1, callfunc)
                sprEmotion:runAction(seq)
            else
                local seq = cc.Sequence:create(moveTo1, fadeOut1, callfunc)
                sprEmotion:runAction(seq)
            end
        end
    else
        local seq = cc.Sequence:create(moveTo1, fadeOut1, callfunc)
        sprEmotion:runAction(seq)
    end
end

---- 扑克spine动画玩家交互
function commonlib.runInteractiveEffecttwo(panContainer, fromNode, toNode, emotionId, toNodeindex)
    -- if g_os == "win" then return end
    if not emotionId or emotionId < 101 or emotionId > 106 then return end
    local spineFile  = nil
    local sprEmotion = nil
    local sPos       = commonlib.worldPos(fromNode)
    local ePos       = commonlib.worldPos(toNode)

    if emotionId == 101 then
        spineFile  = "ui/chat/SX_chat_spine/SX_biaoqingqinwen"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/SX_biaoqingqinwen.png")
        AudioManager:playDWCSound("sound/chatFace_0.mp3")
    elseif emotionId == 102 then
        spineFile  = "ui/chat/SX_chat_spine/SX_biaoqingmeigui1"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/SX_biaoqingmeigui1.png")
        AudioManager:playDWCSound("sound/chatFace_1.mp3")
    elseif emotionId == 103 then
        spineFile  = "ui/chat/SX_chat_spine/xihongshi"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/xihongshi.png")
        AudioManager:playDWCSound("sound/chatFace_4.mp3")
    elseif emotionId == 104 then
        spineFile  = "ui/chat/SX_chat_spine/qiang"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/qiang.png")
        AudioManager:playDWCSound("sound/chatFace_5.mp3")
    elseif emotionId == 105 then
        spineFile  = "ui/chat/SX_chat_spine/chaju"
        sprEmotion = cc.Sprite:create("ui/qj_userInfo/chaju.png")
        AudioManager:playDWCSound("sound/chatFace_2.mp3")
    elseif emotionId == 106 then
        spineFile  = "ui/chat/SX_chat_spine/bangbangtang"
        sprEmotion = cc.Sprite:create("ui/chat/SX_chat_spine/bangbangtang.png")
        AudioManager:playDWCSound("sound/chatFace_3.mp3")
    end
    if not spineFile then return end

    panContainer:addChild(sprEmotion, 300)
    sprEmotion:setPosition(sPos)

    local speed        = 2000
    local dis          = cc.pGetDistance(sPos, ePos)
    local t            = dis / speed
    local moveTo1      = cc.MoveTo:create(t, ePos)
    local fadeOut1     = cc.FadeOut:create(0.1)
    local orbitcamere1 = cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0)

    local callfunc = cc.CallFunc:create(function()
        sprEmotion:removeFromParent(true)
        skeletonNode = sp.SkeletonAnimation:create(spineFile .. ".json", spineFile .. ".atlas", 1)
        skeletonNode:setAnimation(0, "animation", false)
        skeletonNode:setPosition(ePos)
        panContainer:addChild(skeletonNode, 300)
        skeletonNode:setScale(1)
        if emotionId == 104 and toNodeindex ~= 2 then
            skeletonNode:runAction(cc.OrbitCamera:create(0.1, 1, 0, 0, 180, 0, 0))
        end
        skeletonNode:runAction(cc.FadeOut:create(2))
    end)
    if emotionId == 104 and toNodeindex ~= 2 then
        local seq = cc.Sequence:create(orbitcamere1, moveTo1, fadeOut1, callfunc)
        sprEmotion:runAction(seq)
    else
        local seq = cc.Sequence:create(moveTo1, fadeOut1, callfunc)
        sprEmotion:runAction(seq)
    end
end

function commonlib.showReturnTips(str)
    local csb  = DTUI.getInstance().csb_returnroomtips
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    cc.Director:getInstance():getRunningScene():addChild(node, 999999)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit    = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    local content = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text")
    local roomid  = cc.UserDefault:getInstance():getStringForKey("room_id")
    content:setString("你已在房间："..roomid.."中，" .. (str or "") .. "是否需要退出房间?")
    ccui.Helper:seekWidgetByName(node, "btReturn"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
                local input_msg = {
                    cmd     = NetCmd.C2S_JOIN_ROOM_AGAIN,
                    room_id = tonumber(roomid),
                }
                ymkj.SendData:send(json.encode(input_msg))
                cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
                cc.UserDefault:getInstance():flush()

            end
        end
    )
    exit:addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    ccui.Helper:seekWidgetByName(node, "btJiesan"):addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
                local input_msg = {
                    cmd = NetCmd.C2S_JIESAN,
                }
                ymkj.SendData:send(json.encode(input_msg))
                cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
                cc.UserDefault:getInstance():flush()
            end
        end
    )

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_5"), function()
        content:setString("你已在房间："..roomid.."中，" .. (str or "") .. "是否需要退出房间?")
    end)
end

function commonlib.showbtn(_prt, content)
    if not content then
        _prt:setVisible(false)
        _prt:setTouchEnabled(false)
    else
        _prt:setVisible(true)
        _prt:setTouchEnabled(true)
    end

end

gt.playInteractiveSpine = playInteractiveSpine

--------------------------
function StringToTable(s)
    local tb = {}

    --[[
    UTF8的编码规则：
    1. 字符的第一个字节范围： 0x00—0x7F(0-127),或者 0xC2—0xF4(194-244); UTF8 是兼容 ascii 的，所以 0~127 就和 ascii 完全一致
    2. 0xC0, 0xC1,0xF5—0xFF(192, 193 和 245-255)不会出现在UTF8编码中
    3. 0x80—0xBF(128-191)只会出现在第二个及随后的编码中(针对多字节编码，如汉字)
    ]]
    for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(tb, utfChar)
    end

    return tb
end

function GetUTFLen(s)
    local sTable = StringToTable(s)

    local len     = 0
    local charLen = 0

    for i = 1, #sTable do
        local utfCharLen = string.len(sTable[i])
        if utfCharLen > 1 then -- 长度大于1的就认为是中文
            charLen = 2
        else
            charLen = 1
        end

        len = len + charLen
    end

    return len
end

function GetUTFLenWithCount(s, count)
    local sTable = StringToTable(s)

    local len       = 0
    local charLen   = 0
    local isLimited = (count >= 0)

    for i = 1, #sTable do
        local utfCharLen = string.len(sTable[i])
        if utfCharLen > 1 then -- 长度大于1的就认为是中文
            charLen = 2
        else
            charLen = 1
        end

        len = len + utfCharLen

        if isLimited then
            count = count - charLen
            if count <= 0 then
                break
            end
        end
    end

    return len
end

function commonlib.GetMaxLenString(s, maxLen, dian)
    local len = GetUTFLen(s)

    local dstString = s
    -- 超长，裁剪，加...
    if len > maxLen then
        dstString = string.sub(s, 1, GetUTFLenWithCount(s, maxLen))
        if dian then
            dstString = dstString
        else
            dstString = dstString.."..."
        end
    end

    return dstString
end

function playDdzAudio(audio_type, audio_name)
    if audio_type == 2 then
        AudioManager:playPressSound()
    elseif audio_type == 4 then
        AudioManager:playDWCSound("sound/ddz_music/"..audio_name..".mp3")
    elseif audio_type == 5 then
        AudioManager:playDWCSound("sound/m_sendcard.mp3")
    elseif audio_type == 7 then
        AudioManager:playDWCSound("sound/ddz_music/men/"..audio_name..".mp3")
    elseif audio_type == 8 then
        AudioManager:playDWCSound("sound/ddz_music/women/"..audio_name.."-0.mp3")
    end
end

local function refreshBattery(batteryProgress)
    local bat = math.abs(gt.battery or 100)
    -- print("########bat",bat)
    if batteryProgress then
        batteryProgress:setPercent(bat)
    end
end
gt.refreshBattery = refreshBattery

local function refreshSignal(signalImg)
    if signalImg then
        local signal       = tonumber(gt.signalStrength) or 3
        local networktType = tonumber(gt.networktType) or 1
        local img          = "ui/qj_room/wifi3.png"
        if networktType == -1 then
            img = "ui/qj_room/nosignal.png"
        elseif networktType == 1 then
            if signal >= 0 and signal <= 3 then
                img = string.format("ui/qj_room/wifi%d.png", signal)
            end
        elseif networktType >= 2 and networktType <= 4 then
            img = string.format("ui/qj_room/%dg.png", networktType)
        end
        gt.performWithDelay(signalImg, function()
            signalImg:loadTexture(img)
        end, 0.5)
    end
end
gt.refreshSignal = refreshSignal

local function listenBatterySignal()
    if NativeUtil:getAbility("getBattery") then
        NativeUtil:currentBatteryPercent()
    end
    if NativeUtil:getAbility("getSignal") then
        NativeUtil:getSignalStrength()
    end
end
gt.listenBatterySignal = listenBatterySignal

local function updateBatterySignal(target)
    local signalTime  = 0
    local batteryTime = 0
    target:onUpdate(function(dt)
        signalTime  = signalTime - dt
        batteryTime = batteryTime - dt
        if batteryTime <= 0 then
            batteryTime   = 60
            local battery = NativeUtil:getBattery()
            gt.battery    = battery
            if target.batteryProgress then
                gt.refreshBattery(target.batteryProgress)
            end
            -- print("battery",battery)
        end
        if signalTime <= 0 then
            signalTime        = 10
            local rtn_msg     = NativeUtil:getSignal()
            gt.signalStrength = rtn_msg.signal
            gt.networktType   = rtn_msg.typ
            if target.signalImg then
                gt.refreshSignal(target.signalImg)
            end
        end
    end)
end
gt.updateBatterySignal = updateBatterySignal

function ENTER_ROOM(room_id)
    if room_id and room_id ~= "" and room_id ~= "0" then
        local net_msg = {
            cmd     = NetCmd.C2S_JOIN_ROOM,
            room_id = tonumber(room_id),
        }
        ymkj.SendData:send(json.encode(net_msg))
    end
end

local function getMissJuIds()
    local miss_ju_list = gt.getLocal("string", "miss_ju_list", "")
    if miss_ju_list and #miss_ju_list > 0 then
        miss_ju_list = json.decode(miss_ju_list) or {}
    else
        miss_ju_list = {}
    end
    return miss_ju_list
end
gt.getMissJuIds = getMissJuIds

local function addMissJuId(_id)
    if not _id then return end
    local miss_ju_list              = gt.getMissJuIds()
    miss_ju_list[#miss_ju_list + 1] = _id
    gt.setLocal("string", "miss_ju_list", json.encode(miss_ju_list) or {})
end
gt.addMissJuId = addMissJuId

local function rmMissJuId(_id)
    if not _id then return end
    local miss_ju_list = gt.getMissJuIds()
    for i = #miss_ju_list, 1, -1 do
        if miss_ju_list[i] == _id then
            table.remove(miss_ju_list, i)
        end
    end
    gt.setLocal("string", "miss_ju_list", json.encode(miss_ju_list) or {})
end
gt.rmMissJuId = rmMissJuId

local function removeUnusedRes()
    -- cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    -- cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end
gt.removeUnusedRes = removeUnusedRes

function display.newTTFLabel(params)
    assert(type(params) == "table",
        "[framework.display] newTTFLabel() invalid params")

    local text       = tostring(params.text)
    local font       = params.font or display.DEFAULT_TTF_FONT
    local size       = params.size or display.DEFAULT_TTF_FONT_SIZE
    local color      = params.color or display.COLOR_WHITE
    local textAlign  = params.align or cc.TEXT_ALIGNMENT_LEFT
    local textValign = params.valign or cc.VERTICAL_TEXT_ALIGNMENT_TOP
    local x, y = params.x, params.y
    local dimensions = params.dimensions or cc.size(0, 0)

    assert(type(size) == "number",
        "[framework.display] newTTFLabel() invalid params.size")

    local label
    if cc.FileUtils:getInstance():isFileExist(font) then
        label = cc.Label:createWithTTF(text, font, size, dimensions, textAlign, textValign)
    else
        label = cc.Label:createWithSystemFont(text, font, size, dimensions, textAlign, textValign)
    end

    if label then
        label:setColor(color)
        if x and y then label:setPosition(x, y) end
    end

    return label
end

function display.newBMFontLabel(params)
    assert(type(params) == "table",
        "[framework.display] newBMFontLabel() invalid params")

    local text      = tostring(params.text)
    local font      = params.font
    local textAlign = params.align or cc.TEXT_ALIGNMENT_LEFT
    local maxLineW  = params.maxLineWidth or 0
    local offsetX   = params.offsetX or 0
    local offsetY   = params.offsetY or 0
    local x, y = params.x, params.y
    assert(font ~= nil, "framework.display.newBMFontLabel() - not set font")

    local label = cc.Label:createWithBMFont(font, text, textAlign, maxLineW, cc.p(offsetX, offsetY));
    if not label then return end

    if type(x) == "number" and type(y) == "number" then
        label:setPosition(x, y)
    end

    return label
end

-- start --
--------------------------------
-- @class function
-- @description 获取节点的世界坐标
-- @param node 节点
-- @return 世界坐标
-- end --
local function getWorldPos(node)
    if not node:getParent() then
        return cc.p(node:getPosition())
    end

    local nodeList = {}
    while node do
        -- 遍历节点,存储所有父节点
        table.insert(nodeList, node)
        node = node:getParent()
    end
    -- 移除Scene节点/世界坐标是基于Scene节点
    table.remove(nodeList, #nodeList)

    local worldPosition = cc.p(0, 0)
    for i, node in ipairs(nodeList) do
        local nodePosition = cc.p(node:getPosition())
        local idx          = i + 1
        if idx <= #nodeList then
            -- 累加父节点锚点相对位置
            local parentNode     = nodeList[idx]
            local parentSize     = parentNode:getContentSize()
            local parentAnchor   = parentNode:getAnchorPoint()
            local anchorPosition = cc.p(parentSize.width * parentAnchor.x, parentSize.height * parentAnchor.y)
            local subPosition    = cc.pSub(nodePosition, anchorPosition)
            worldPosition        = cc.pAdd(worldPosition, subPosition)
        else
            -- +最后父节点位置
            worldPosition = cc.pAdd(worldPosition, nodePosition)
        end
    end

    return worldPosition
end
gt.getWorldPos = getWorldPos

local function attachUrlParams(url, args)
    local ret = url
    if type(args) == "table" then
        ret = ret .. "?"
        for k, v in pairs(args) do
            ret = ret .. tostring(k) .. "=" .. tostring(v) .. "&"
        end
        ret = string.sub(ret, 1, -2)
    end
    return ret
end
gt.attachUrlParams = attachUrlParams

local function reqHttpGet(key, url, args)
    local _url = gt.attachUrlParams(url, args)
    ymkj.UrlPool:instance():reqHttpGet(key, _url)
    print("reqHttpGet", key, _url)
end
gt.reqHttpGet = reqHttpGet

local function getClientIp()
    if g_os == 'win' then
        local lon   = math.random(-180, 180)
        local lat   = math.random(-90, 90)
        return {[1] = lat, [2] = lon .. '&'}
    end
    local lon_lat_str = "0;0"
    if not ios_checking then
        lon_lat_str = ymkj.baseInfo(6)
        cc.UserDefault:getInstance():setStringForKey("lonlat", lon_lat_str or "0;0")
    end
    local lon_lat = string.split(lon_lat_str, ";")
    if type(lon_lat) == "table" and lon_lat[1] and lon_lat[2] then
        return lon_lat
    else
        return {[1] = "0", [2] = "0"}
    end
end

gt.getClientIp = getClientIp

local function uploadTextureInfo()
    local TextureInfo = cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
    local strPos      = string.find(TextureInfo, 'dumpDebugInfo')
    if strPos then
        local TextureInfoMem = string.sub(TextureInfo, strPos)
        print(TextureInfoMem)
        gt.uploadErr(TextureInfoMem)
    end
end

local function printScreen(_func)
    local file   = cc.FileUtils:getInstance():getWritablePath() .. "jietu.png"
    local node   = display.getRunningScene()
    local size   = node:getContentSize()
    local canvas = cc.RenderTexture:create(size.width, size.height)
    canvas:begin()
    node:visit()
    canvas:endToLua()
    canvas:saveToFile("jietu.png", 0, false)
    gt.performWithDelay(node, function()
        _func({
            fileUrl = file,
        })
    end, 0.5)
end
gt.printScreen = printScreen

gt.uploadTextureInfo = uploadTextureInfo

local function getVersion()
    local version          = 'can not get versin'
    local UpdateResVersion = cc.UserDefault:getInstance():getStringForKey("UpdateResVersion", version)
    print(UpdateResVersion)
    local UpdateVersion = cc.UserDefault:getInstance():getStringForKey("UpdateVersion", version)
    print(UpdateVersion)
    version = string.format('UpdateResVersion %s UpdateVersion %s', UpdateResVersion, UpdateVersion)

    return version
end

gt.getVersion = getVersion

-- 得到当天某点时间
local function getCurDayHourTime(_future_hour)
    -- 默认参数为当天0点
    local future_hour   = _future_hour or 0
    local cur_timestamp = os.time()
    local temp_date     = os.date("*t", cur_timestamp)

    local resultTime = os.time({year = temp_date.year, month = temp_date.month, day = temp_date.day, hour = future_hour})
    return resultTime
end
gt.getCurDayHourTime = getCurDayHourTime

function filter_spec_chars(s)
    local ss = {}
    local k  = 1
    while true do
        if k > #s then break end
        local c = string.byte(s, k)
        if not c then break end
        if c < 192 then
            if (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) then
                table.insert(ss, string.char(c))
            end
            k = k + 1
        elseif c < 224 then
            k = k + 2
        elseif c < 240 then
            if c >= 228 and c <= 233 then
                local c1 = string.byte(s, k + 1)
                local c2 = string.byte(s, k + 2)
                if c1 and c2 then
                    local a1, a2, a3, a4 = 128, 191, 128, 191
                    if c == 228 then a1 = 184
                    elseif c == 233 then a2, a4 = 190, c1 ~= 190 and 191 or 165
                    end
                    if c1 >= a1 and c1 <= a2 and c2 >= a3 and c2 <= a4 then
                        table.insert(ss, string.char(c, c1, c2))
                    end
                end
            end
            k = k + 3
        elseif c < 248 then
            k = k + 4
        elseif c < 252 then
            k = k + 5
        elseif c < 254 then
            k = k + 6
        end
    end
    return table.concat(ss)
end
gt.filter_spec_chars = filter_spec_chars