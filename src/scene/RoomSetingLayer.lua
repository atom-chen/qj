local RoomSetingLayer = class("RoomSetingLayer", function()
    return cc.Layer:create()
end)

function RoomSetingLayer.create(is_game_start, is_fangzhu, is_playback, callback)
    local layer = RoomSetingLayer.new()
    layer:createLayerMenu(is_game_start, is_fangzhu, is_playback, callback)
    return layer
end

function RoomSetingLayer:createLayerMenu(is_game_start, is_fangzhu, is_playback, callback)
    require 'scene.DTUI'
    local csb  = DTUI:getInstance().csb_RoomSettingLayer
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                self:removeFromParent(true)

            end
        end
    )
    local speedPanel = tolua.cast(ccui.Helper:seekWidgetByName(node, "speed"), "ccui.ImageView")
    self.btnQuick    = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnQuick"), "ccui.Button")
    self.btnSlow     = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnSlow"), "ccui.Button")
    self.imgQuick    = tolua.cast(ccui.Helper:seekWidgetByName(node, "imgQuick"), "ccui.ImageView")
    self.imgSlow     = tolua.cast(ccui.Helper:seekWidgetByName(node, "imgSlow"), "ccui.ImageView")
    local btjiesan   = tolua.cast(ccui.Helper:seekWidgetByName(node, "btJiesan"), "ccui.Button")

    if is_playback then
        btjiesan:setVisible(false)
        speedPanel:setVisible(false)
    end
    local speed = cc.UserDefault:getInstance():getStringForKey("TingAutoOutCard", '0.55')
    self:initBtnSpeed(tonumber(speed))
    if not callback then
        speedPanel:setVisible(false)
    else
        callback(tonumber(speed))
    end

    self.btnQuick:addClickEventListener(function()
        AudioManager:playPressSound()
        self:initBtnSpeed(0.3)
        callback(0.3)
    end)

    self.btnSlow:addClickEventListener(function()
        AudioManager:playPressSound()
        self:initBtnSpeed(0.55)
        callback(0.55)
    end)

    btjiesan:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                self:removeFromParent(true)
                cc.UserDefault:getInstance():setStringForKey("is_back_fromroom", "false")
                cc.UserDefault:getInstance():flush()
                if not is_game_start then
                    if is_room_owner then
                        local input_msg = {
                            cmd = NetCmd.C2S_JIESAN,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    else
                        local input_msg = {
                            cmd = NetCmd.C2S_LEAVE_ROOM,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end
                else
                    local input_msg = {
                        cmd = NetCmd.C2S_APPLY_JIESAN,
                    }
                    ymkj.SendData:send(json.encode(input_msg))
                end

            end
        end
    )
    local soundSlider = ccui.Helper:seekWidgetByName(node, "Slider_Sound")
    local musicSlider = ccui.Helper:seekWidgetByName(node, "Slider_Music")

    soundSlider:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                AudioManager:setSoundVolume(soundSlider:getPercent() / 100)
                if soundSlider:getPercent() == 0 then
                    AudioManager:setSoundable(false)
                else
                    AudioManager:setSoundable(true)
                end

            end
        end
    )

    if AudioManager:getSoundable() then
        soundSlider:setPercent(AudioManager:getSoundVolume() * 100)
        if AudioManager:getSoundVolume() == 0 then
            soundSlider:setPercent(50)
        end
    else
        soundSlider:setPercent(0)
    end

    musicSlider:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                AudioManager:setMusicVolume(musicSlider:getPercent() / 100)
                if musicSlider:getPercent() == 0 then
                    AudioManager:setMusicable(false)
                else
                    AudioManager:setMusicable(true)
                end
            end
        end
    )

    if AudioManager:getMusicable() then
        musicSlider:setPercent(AudioManager:getMusicVolume() * 100)
        if AudioManager:getMusicVolume() == 0 then
            musicSlider:setPercent(50)
        end
    else
        musicSlider:setPercent(0)
    end

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))

    return layer
end

function RoomSetingLayer:initBtnSpeed(speed)
    if speed == 0.3 then
        self.btnQuick:loadTextureNormal("ui/qj_setting/speedSel1.png")
        self.btnQuick:loadTexturePressed("ui/qj_setting/speedSel0.png")
        self.btnSlow:loadTextureNormal("ui/qj_setting/speedSel0.png")
        self.btnSlow:loadTexturePressed("ui/qj_setting/speedSel1.png")
        self.imgQuick:loadTexture("ui/qj_setting/quick1.png")
        self.imgSlow:loadTexture("ui/qj_setting/slow0.png")
        cc.UserDefault:getInstance():setStringForKey("TingAutoOutCard", '0.3')
        cc.UserDefault:getInstance():flush()
    else
        self.btnQuick:loadTextureNormal("ui/qj_setting/speedSel0.png")
        self.btnQuick:loadTexturePressed("ui/qj_setting/speedSel1.png")
        self.btnSlow:loadTextureNormal("ui/qj_setting/speedSel1.png")
        self.btnSlow:loadTexturePressed("ui/qj_setting/speedSel0.png")
        self.imgQuick:loadTexture("ui/qj_setting/quick0.png")
        self.imgSlow:loadTexture("ui/qj_setting/slow1.png")
        cc.UserDefault:getInstance():setStringForKey("TingAutoOutCard", '0.55')
        cc.UserDefault:getInstance():flush()
    end
end

return RoomSetingLayer