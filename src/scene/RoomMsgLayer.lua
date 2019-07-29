local RoomMsgLayer = class("RoomMsgLayer", function()
    return cc.Layer:create()
end)

function RoomMsgLayer.create(is_nxmj, callback)
    local layer    = RoomMsgLayer.new()
    layer.callback = callback
    layer:createLayerMenu(is_nxmj)
    return layer
end

function RoomMsgLayer:sendBiaoqing(bq_id)
    print('sendBiaoqing', bq_id)
    local input_msg = {
        cmd      = NetCmd.C2S_ROOM_CHAT,
        msg_type = 2,
        msg      = bq_id,
    }
    ymkj.SendData:send(json.encode(input_msg))
    if type(self.callback) == "function" then
        self.callback()
    end
end

function RoomMsgLayer:sendMsg(input)
    local input_msg = {
        cmd      = NetCmd.C2S_ROOM_CHAT,
        msg_type = 1,
        msg      = ymkj.base64Encode(input),
    }
    ymkj.SendData:send(json.encode(input_msg))
    if type(self.callback) == "function" then
        self.callback()
    end
end

function RoomMsgLayer:sendinputMsg(input)
    local input_msg = {
        cmd      = NetCmd.C2S_ROOM_CHAT,
        msg_type = 4,
        msg      = ymkj.base64Encode(input),
    }
    ymkj.SendData:send(json.encode(input_msg))
    if type(self.callback) == "function" then
        self.callback()
    end
end

function RoomMsgLayer:createLayerMenu(is_nxmj)
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_liaotian.csb"), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)

    self.node = node

    self:loadEmotion()

    -- local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node,"btn-exit"), "ccui.Widget")
    local backBtn = ccui.Helper:seekWidgetByName(node, "Panel_5")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                -- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("HideKeyboard")
                commonlib.fadeOut(ccui.Helper:seekWidgetByName(node, "Panel_1"))
                commonlib.scaleOut(ccui.Helper:seekWidgetByName(node, "Img-dikuang"), function()
                    self:removeFromParent(true)
                end)
            end
        end
    )

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Img-dikuang"))

    local topPanel = tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_msg"), "ccui.Widget")
    local zjPanel  = tolua.cast(ccui.Helper:seekWidgetByName(node, "Panel_bq"), "ccui.Widget")
    zjPanel:setEnabled(false)
    zjPanel:setVisible(false)

    ---------------------------------------------------------------------
    local text_field = tolua.cast(ccui.Helper:seekWidgetByName(node, "TextField_3"), "ccui.TextField")

    local function sendRoomMsg()
        local input_msg = text_field:getString()
        if not input_msg or input_msg == "" then
            if not portrait then
                commonlib.showLocalTip("输入不能为空")
            else
                commonlib.showLocalTip("输入不能为空", nil, -90)
            end
        else
            self:sendinputMsg(input_msg)

            cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("HideKeyboard")

            self:removeFromParent(true)
        end
    end

    ccui.Helper:seekWidgetByName(node, "btn_fasong"):addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
            sendRoomMsg()
        end
    end)

    --------------------------------------------------------------------
    for i = 1, 28 do
        local btn_bq = ccui.Helper:seekWidgetByName(node, "BQ"..i)
        btn_bq:setTouchEnabled(true)
        btn_bq:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then

                AudioManager:playPressSound()

                self:sendBiaoqing(i)

                -- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("HideKeyboard")

                self:removeFromParent(true)

            end
        end)
    end

    local nxTextConfig = is_nxmj and {
        "大家好！祝大家都有好手气。",
        "出牌啊,这牌你都看出花了。",
        "都别走啊,一会再打两圈。",
        "哎呦,好运来了挡都挡不住。",
        "稍等一下,我接个电话。",
        "刚才在接电话,久等了各位",
        "就是不上牌,没辙！",
        "又断线了,今天这网怎么了？",
        "你是哪的人啊,咱们加个好友吧。",
        } or nil

    for i = 1, 9 do
        local ii      = i
        local btn_msg = ccui.Helper:seekWidgetByName(node, "MSG"..ii)
        -- local title = ccui.Helper:seekWidgetByName(btn_msg, "Text_38")
        if nxTextConfig then

            btn_msg:setString(nxTextConfig[i])
        end

        btn_msg:setTouchEnabled(true)
        btn_msg:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then

                AudioManager:playPressSound()

                self:sendMsg(nxTextConfig and nxTextConfig[i] or specTextConfig[i])

                -- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("HideKeyboard")

                self:removeFromParent(true)

            end
        end)
    end

    local bindTab = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-bangding"), "ccui.Button")
    -- bindTab:setVisible(true)
    local toolTab = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-cyy"), "ccui.Button")
    -- toolTab:setVisible(true)
    local chat = ccui.Helper:seekWidgetByName(node, "Panel_2")
    local function bindTabTouch(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if sender then
                AudioManager:playPressSound()
            end
            topPanel:setEnabled(false)
            topPanel:setVisible(false)
            zjPanel:setEnabled(true)
            zjPanel:setVisible(true)

            bindTab:setTouchEnabled(false)
            bindTab:setBright(false)
            toolTab:setTouchEnabled(true)
            toolTab:setBright(true)

            chat:setVisible(false)
        end
    end

    local function toolTabTouch(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if sender then
                AudioManager:playPressSound()
            end
            topPanel:setEnabled(true)
            topPanel:setVisible(true)
            zjPanel:setEnabled(false)
            zjPanel:setVisible(false)

            bindTab:setTouchEnabled(true)
            bindTab:setBright(true)
            toolTab:setTouchEnabled(false)
            toolTab:setBright(false)

            chat:setVisible(true)
        end
    end

    bindTab:addTouchEventListener(bindTabTouch)
    toolTab:addTouchEventListener(toolTabTouch)

    toolTabTouch(nil, ccui.TouchEventType.ended)

end

function RoomMsgLayer:loadEmotion()
    local Emotion = {
        'png/expression1102.png', -- 666
        'png/expression181.png', -- 吐
        'png/expression101.png', -- 晕星星
        'png/expression91.png', -- 怒火

        'png/expression83.png', -- 哈欠
        'png/expression201.png', -- 加油
        'png/expression35.png', -- 呵呵
        'png/expression251.png', -- 哭

        'png/expression123.png', -- 白旗
        'png/expression41.png', -- 汗
        'png/expression211.png', -- 我伙呆
        'png/expression1403.png', -- 含情

        'png/expression246.png', -- 得意
        'png/expression191.png', -- 可怜
        'png/expression134.png', -- 色
        'png/expression151.png', -- 烧香
    }

    cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/chat/biaoqingALL0/biaoqingALL00.plist')
    cc.SpriteFrameCache:getInstance():addSpriteFrames('ui/chat/biaoqingALL0/biaoqingALL01.plist')

    for i = 1, #Emotion do
        local btn_bq = ccui.Helper:seekWidgetByName(self.node, "BQ"..i)
        local size   = btn_bq:getContentSize()

        print('--------------------')
        print(size.width, size.height)
        print('--------------------')

        btn_bq:loadTexture('ui/qj_commom/anniu1.png')
        local sprite = cc.Sprite:createWithSpriteFrameName(Emotion[i])
        sprite:setAnchorPoint(0.5, 1)
        sprite:setPosition(btn_bq:getContentSize().width / 2, btn_bq:getContentSize().height)
        btn_bq:addChild(sprite)

        local scaleX = size.width / sprite:getContentSize().width
        local scaleY = size.height / sprite:getContentSize().height

        if scaleX < scaleY then
            sprite:setScale(scaleX)
        else
            sprite:setScale(scaleY)
        end
    end
end

return RoomMsgLayer