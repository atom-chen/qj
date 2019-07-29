require('scene.DTUI')

local ShareDialog = class("ShareDialog", function()
    return gt.createMaskLayer()
end)

function ShareDialog:ctor()
    local csb = DTUI.getInstance().csb_main_share_dialog
    self:addCSNode(csb)

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)

    self:addBtListener("btnWx", function()
        AudioManager:playPressSound()
        local profile = ProfileManager.GetProfile()
        local uid     = profile.uid
        gt.wechatShareChatStart()
        ymkj.wxReq(2, "拥有多款陕西，山西，河北当地经典火爆玩法，麻将，扑克样样齐全",
        "玩法多多，惊喜多多，快来玩吧！", g_share_url.."&uid="..uid)
        gt.wechatShareChatEnd()
        print("open WXshare")
    end)

    self:addBtListener("btnPyq", function()
        AudioManager:playPressSound()
        local profile     = ProfileManager.GetProfile()
        local invite_code = profile.invite_code
        local uid         = profile.uid
        ymkj.wxReq(2, "", "拥有多款陕西，山西，河北当地经典火爆玩法，麻将，扑克样样齐全",
        g_share_url.."&uid="..uid, 2)
        print("open Pyqshare")
    end)
end

return ShareDialog