local ShareWindow = class("ShareWindow", cc.Layer)

function ShareWindow:ctor(Data)
    self.Data = Data
    self:initLayer()
end

function ShareWindow:initLayer()
    local node = tolua.cast(cc.CSLoader:createNode("ui/ShareWindow.csb"), "ccui.Widget")
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)
    self:addChild(node)

    local btn = {
        {"Panel_Shadow", click = "onBgClickHandler"},
        {"btn_xianl", click = "onXianlClickHandler"},
        {"btn_wx", click = "onWxClickHandler"},
        {"btn_weil", click = "onWlClickHandler"},
    }

    local function addBtnEvent(btnName, callback)
        local btn = tolua.cast(ccui.Helper:seekWidgetByName(node, btnName), "ccui.Button")
        btn:addTouchEventListener(function (sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                callback()
            end
        end)
    end

    for _, v in ipairs(btn) do
        if v then
            addBtnEvent(v[1], handler(self, self[v.click]))
        end
    end
end

-- 背景控制退出
function ShareWindow:onBgClickHandler()
    self:removeFromParent()
end

-- 闲聊
function ShareWindow:onXianlClickHandler()
    AudioManager:playPressSound()
    local NativeUtil = require("common.NativeUtil")
    if self.Data.isRoomShare then
        local clubId = ""
        NativeUtil:shareGame({
            typ       = "xianliao",
            title     = self.Data.title,
            text      = self.Data.content,
            roomToken = clubId,
            roomId    = tostring(self.Data.roomid),
            url       = self.Data.share_url,
            imageUrl  = gt.getConf("share_image_url"),
            -- androidDownloadUrl = "https://fir.im/nt2p",
            -- iOSDownloadUrl = "https://fir.im/13yp",
            classId = function(ret)
                if ret and ret.code == -1 then
                    NativeUtil:dowloadOtherTip("xianliao")
                end
            end
        })
    else
        gt.performWithDelay(display.getRunningScene(), function()
            NativeUtil:shareDataImage({
                typ = "xianliao",
                classId = function(ret)
                    if ret and ret.code == -1 then
                        NativeUtil:dowloadOtherTip("xianliao")
                    end
                end
            })
        end, 0.1)
    end
    self:removeFromParent(true)
end

-- 微信
function ShareWindow:onWxClickHandler()
    AudioManager:playPressSound()
    if self.Data.isRoomShare then
        if self.Data.copy then
            ymkj.copyClipboard("房间号:"..self.Data.roomid.."\n"..self.Data.content..
                "\n速度加入【"..string.sub(g_game_name, 4, -4) .. "】("..self.Data.people..")\n游戏下载地址:"..self.Data.share_url)
            print("房间号:"..self.Data.roomid.."\n"..self.Data.content..
                "\n速度加入【"..string.sub(g_game_name, 4, -4) .. "】("..self.Data.people..")\n游戏下载地址:"..self.Data.share_url)
            commonlib.showLocalTip("复制分享房间，已自动为您复制成功，可切换微信分享")
        else
            gt.wechatShareChatStart()
            ymkj.wxReq(2, self.Data.content, "包厢号:"..self.Data.title, self.Data.share_url)
            gt.wechatShareChatEnd()
            print(self.Data.title.."\n"..self.Data.content.."\n"..self.Data.share_url.."\n打开微信分享")
        end
    else
        if g_copy_share then
            if ymkj.copyClipboard then
                ymkj.copyClipboard(self.Data.title.."\n"..self.Data.str)
            else
                commonlib.showTipDlg("您的版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
                    ymkj.ymIM(100, "", "")
                end)
            end
            print(self.Data.title.."\n"..self.Data.str)
            commonlib.showLocalTip("复制成功，可切换微信分享")
        else
            if self.Data.copy then
                if ymkj.copyClipboard then
                    ymkj.copyClipboard(self.Data.title.."\n"..self.Data.str)
                else
                    commonlib.showTipDlg("您的版本过低\n点击确定前往安装最新版本\n(需卸载当前版本再安装)", function()
                        ymkj.ymIM(100, "", "")
                    end)
                end
                print(self.Data.title.."\n"..self.Data.str)
                commonlib.showLocalTip("复制分享房间，已自动为您复制成功，可切换微信分享")
            else
                gt.performWithDelay(display.getRunningScene(), function()
                    if g_os ~= "win" then
                        gt.wechatShareChatStart()
                        ymkj.wxReq(3, "")
                        gt.wechatShareChatEnd()
                    end
                end, 0.1)
                print("打开微信分享")
            end
        end
    end
    self:removeFromParent(true)
end

function ShareWindow:onWlClickHandler()
    AudioManager:playPressSound()
    local NativeUtil = require("common.NativeUtil")
    if self.Data.isRoomShare then
        local clubId = ""
        NativeUtil:shareLink({
            typ       = "qinliao",
            title     = self.Data.title,
            text      = self.Data.content,
            roomToken = clubId,
            roomId    = tostring(self.Data.roomid),
            url       = self.Data.share_url,
            imageUrl  = gt.getConf("share_image_url"),
            -- androidDownloadUrl = "https://fir.im/nt2p",
            -- iOSDownloadUrl = "https://fir.im/13yp",
            classId = function(ret)
                if ret and ret.code == -1 then
                    NativeUtil:dowloadOtherTip("qinliao")
                end
            end
        })
    else
        gt.performWithDelay(display.getRunningScene(), function()
            NativeUtil:shareDataImage({
                typ = "qinliao",
                classId = function(ret)
                    if ret and ret.code == -1 then
                        NativeUtil:dowloadOtherTip("qinliao")
                    end
                end
            })
        end, 0.1)
    end
    self:removeFromParent(true)
end

return ShareWindow