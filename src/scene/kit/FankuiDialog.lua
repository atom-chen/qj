require('scene.DTUI')

local FankuiDialog = class("FankuiDialog", function()
    return gt.createMaskLayer()
end)

function FankuiDialog:ctor()
    local csb = DTUI.getInstance().csb_main_fankui_dialog
    self:addCSNode(csb)

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)

    local wxNum1 = self:seekNode("wxNum1")
    local wxNum2 = self:seekNode("wxNum2")

    wxNum1:setString(gt.getConf("wxFkYx") or '敬请期待')
    wxNum2:setString(gt.getConf("wxFkFk") or '敬请期待')

    self:addBtListener("Copy_1", function()
        AudioManager:playPressSound()
        if ymkj.copyClipboard then
            ymkj.copyClipboard(wxNum1:getString())
        end
        commonlib.showTipDlg("复制成功")
    end)

    self:addBtListener("Copy_2", function()
        AudioManager:playPressSound()
        if ymkj.copyClipboard then
            ymkj.copyClipboard(wxNum2:getString())
        end
        commonlib.showTipDlg("复制成功")
    end)

    self:addBtListener("btn_upload", function()
        AudioManager:playPressSound()
        gt.openUrl("http://qj.iizzh.com/index/agent/suggest")
    end)
end

return FankuiDialog