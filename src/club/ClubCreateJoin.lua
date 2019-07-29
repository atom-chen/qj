require('club.ClubHallUI')

local ClubCreateJoin = class("ClubCreateJoin", function()
    return cc.Layer:create()
end)

function ClubCreateJoin:create(args)
    local layer = ClubCreateJoin.new()
    layer:setName('ClubCreateJoin')
    layer.isBoss    = args.isBoss
    layer.mainScene = args.mainScene
    layer.clubs     = args.clubs or {}
    layer:createLayerMenu()
    return layer
end

openClubCreateTest = false

function ClubCreateJoin:createLayerMenu()
    require('club.ClubHallUI')
    local csb  = ClubHallUI.getInstance().csb_club_create_join
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local Panel_top = ccui.Helper:seekWidgetByName(node, "Panel_top")

    -- local club_name = ccui.Helper:seekWidgetByName(Panel_top,"club_name")
    -- club_name:setString("亲友圈名称")

    local btCreate     = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btCreate"), "ccui.Button")
    local btCreateShow = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btCreateShow"), "ccui.Button")
    local bHasCreate   = false
    if openClubCreateTest then
        if self.isBoss then
            bHasCreate = true
            -- btCreateShow:setBright(false)
            btCreateShow:loadTextureNormal('ui/qj_club_new_year/a0.png')
        end
    else
        if self.isBoss or not (GameGlobal.qunzhu and GameGlobal.qunzhu == 1) then
            bHasCreate = true
            btCreateShow:loadTextureNormal('ui/qj_club_new_year/a0.png')
            -- btCreateShow:setBright(false)
        end
    end

    btCreate:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if not bHasCreate then
                    GameGlobal.openClubCreate = 1
                    local CreateLayer         = require("scene.CreateLayer")
                    self.mainScene:addChild(CreateLayer:create({
                        clubOpt   = 1,
                        qunzhu    = 1,
                        mainScene = self.mainScene,
                        isGM      = self.isBoss,
                    }))
                    self:removeFromParent(true)
                else
                    local msg = "成为推广员后才能创建亲友圈"
                    if self.isBoss then
                        msg = "最多只能创建1个亲友圈，加入4个亲友圈"
                    else
                        local FankuiDialog = require("scene.kit.FankuiDialog")
                        local fankui       = FankuiDialog.create()
                        fankui.is_in_main  = true
                        self:addChild(fankui, 100)
                    end
                    commonlib.showLocalTip(msg)
                end
            end
        end
    )

    local btJoin     = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btJoin"), "ccui.Button")
    local btJoinShow = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btJoinShow"), "ccui.Button")
    -- btCreate:setBright(false)
    btJoin:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if btJoinShow:isBright() then
                    local ClubJointNumberPanel = require('club.ClubJointNumberPanel')
                    local Layer                = ClubJointNumberPanel:create({clubs = self.clubs})
                    Layer:setName('ClubJointNumberPanel')
                    self:getParent():addChild(Layer)
                    self:removeFromParent(true)
                else
                    -- local ClubTipLayer = require("club.ClubTipLayer")
                    -- local args = {
                    --     msg = "您最多可拥有4个亲友圈",
                    -- }
                    -- self:addChild(ClubTipLayer:create(args),100)
                    local msg = "您最多可拥有4个亲友圈"
                    commonlib.showLocalTip(msg)
                end
            end
        end
    )
    self.btJoinShow = btJoinShow

    local btQues = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "ques"), "ccui.Button")
    btQues:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                print("btQues")
                local ClubNoticeLayer = require('club.ClubNoticeLayer')
                local Layer           = ClubNoticeLayer:create()
                Layer:setName('ClubNoticeLayer')
                self:addChild(Layer)
            end
        end
    )

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(Panel_top, "btExit"), "ccui.Button")
    btExit:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    self:refreshCreateJoinUi()
end

function ClubCreateJoin:refreshCreateJoinUi(clubs)
    self.clubs         = clubs or self.clubs
    local max_join_num = 4
    if self.isBoss and #self.clubs >= max_join_num + 1 or not self.isBoss and #self.clubs >= max_join_num then
        self.btJoinShow:setBright(false)
    end
end

function ClubCreateJoin:onSelEvent(name)
    print("onSelEvent", name)
end

return ClubCreateJoin