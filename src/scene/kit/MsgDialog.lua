require('scene.DTUI')

local MsgDialog = class("MsgDialog", function()
    return gt.createMaskLayer()
end)

function MsgDialog:ctor(rtn_msg)
    local csb = DTUI.getInstance().csb_main_message_dialog
    self:addCSNode(csb)

    self.msg_data = rtn_msg

    self.taskItem = self:seekNode("MsgBg")
    self.listView = self:seekNode("lvMsg")

    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(self.listView)
    self.listView:addScrollViewEventListener(scorllCallBack)
    self.listView:addTouchEventListener(touchCallBack)

    local wu_tip = self:seekNode("tNoMsg")
    wu_tip:setVisible(false)

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)

    if not self.msg_data or #self.msg_data < 1 then
        wu_tip:setVisible(true)
    else
        self:isDelQunzhuMsg()
        self:initList()
    end
end

function MsgDialog:initList()
    self.listView:removeAllItems()
    local title   = self:seekNode("tTitle")
    local btnMore = self:seekNode("btMore")
    for i = #self.msg_data, 1, -1 do
        local item = self.taskItem:clone()
        item:setVisible(true)
        item:getChildByName("tTitle"):setString(self.msg_data[i].title)
        local newIcon = item:getChildByName("new")
        if self.msg_data[i].is_new == false then
            newIcon:setVisible(false)
        end
        item:getChildByName("btMore"):addTouchEventListener(
            function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    newIcon:setVisible(false)
                    self.msg_data[i].is_new = false
                    local MoreMsgDialog     = require("scene.kit.MoreMsgDialog")
                    local more              = MoreMsgDialog.create(self, self.msg_data[i])
                    more.is_in_main         = true
                    self:addChild(more)
                    gt.setLocal("string", "NOTICE", json.encode(self.msg_data), true)
                end
            end)
        self.listView:pushBackCustomItem(item)
        self.listView:refreshView()
        self.listView:jumpToTop()
    end
end

function MsgDialog:isDelQunzhuMsg()
    local profile  = ProfileManager.GetProfile()
    local isQunzhu = false
    if profile and profile.qunzhu == 1 then
        isQunzhu = true
    end
    local index = 1
    if not isQunzhu then
        while self.msg_data[index] do
            if self.msg_data[index].is_qunzhu == 1 then
                table.remove(self.msg_data, index)
            else
                index = index + 1
            end
        end
    end
end

return MsgDialog