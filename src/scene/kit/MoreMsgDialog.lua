local MoreMsgDialog = class("MoreMsgDialog", function()
    return gt.createMaskLayer()
end)

function MoreMsgDialog:ctor(rtn_msg)
    local csb = DTUI.getInstance().csb_main_moremsg_dialog
    self:addCSNode(csb)

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        if RedBagController:HBPlay() then
            local actionLayer = require("modules.view.RedBagActionLayer"):create()
            director:getRunningScene():addChild(actionLayer, 5)
        end
        self:removeFromParent(true)
    end)

    local title      = self:seekNode("tTitle")
    local content    = self:seekNode("tContent")
    local Image      = self:seekNode("Image_1")
    local scrollView = self:seekNode("svMessage")
    local Size       = scrollView:getInnerContainerSize()

    Image:setVisible(false)
    if rtn_msg.type == 1 then
        title:setVisible(true)
        title:setString(rtn_msg.title)
        content:setVisible(true)
        content:setString(rtn_msg.content)
    else
        title:setVisible(false)
        content:setVisible(false)
        if rtn_msg.img then
            Image:downloadImg(rtn_msg.img)
            Image:setVisible(true)
        end
    end
    if Size.height < content:getContentSize().height then
        Size.height = content:getContentSize().height
        scrollView:setInnerContainerSize(Size)
        content:setPositionY(Size.height)
    end
end

return MoreMsgDialog