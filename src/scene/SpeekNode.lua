local NativeUtil = require("common.NativeUtil")
require("scene.PlayerData")

local SpeekNode = class("SpeekNode", function()
    return cc.Node:create()
end)

function SpeekNode:ctor(_scene)
    self._scene     = _scene
    self._play_list = {}
    self:enableNodeEvents()
end

function SpeekNode:onEnter()
    self:registerEvent()
    SpeekMgr:addDelegate()
end

function SpeekNode:onExit()
    SpeekMgr:removeDelegate()
    self:unregisterEvent()
    self:disableNodeEvents()
end

function SpeekNode:registerEvent()
    local events = {
        {
            eType = EventEnum.onRecordStart,
            func  = handler(self, self.onRecordStart),
        },
        {
            eType = EventEnum.onRecordStop,
            func  = handler(self, self.onRecordStop),
        },
        {
            eType = EventEnum.onRecordTimeOut,
            func  = handler(self, self.onRecordTimeOut),
        },
        {
            eType = EventEnum.onRecordFaild,
            func  = handler(self, self.onRecordFaild),
        },
        {
            eType = EventEnum.onWillPlay,
            func  = handler(self, self.onWillPlay),
        },
        {
            eType = EventEnum.onPlayStop,
            func  = handler(self, self.onPlayStop),
        },
        {
            eType = EventEnum.onRcvSpeek,
            func  = handler(self, self.onRcvSpeek),
        },
        {
            eType = EventEnum.onMjSound,
            func  = handler(self, self.onMjSound),
        },
        {
            eType = EventEnum.onPokerSound,
            func  = handler(self, self.onPokerSound),
        },
        {
            eType = EventEnum.playOneLast,
            func  = handler(self, self.playOneLast),
        },
    }
    for i, v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function SpeekNode:unregisterEvent()
    for i, v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function SpeekNode:touchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        print('began')
        if NativeUtil:getAbility("speex") then
            AudioManager:pauseMusic()
            SpeekMgr:startRecord()
        end
    elseif eventType == ccui.TouchEventType.ended then
        print('ended')
        if NativeUtil:getAbility("speex") then
            SpeekMgr:stopRecord()
        else
            commonlib.showLocalTip("因您的游戏版本过低,无法录制,请重新下载游戏!")
        end
    elseif eventType == ccui.TouchEventType.canceled then
        print('canceled')
        if NativeUtil:getAbility("speex") then
            SpeekMgr:cancelRecord()
        end
    end
end

function SpeekNode:isSpeexMsg(msg)
    if string.find(msg, ".amr") then
        return false
    end
    return true
end

function SpeekNode:playOneLast(msgTab)
    local index = self._scene:indexTrans(msgTab.index)
    if self._play_list[index] then
        SpeekMgr:addPlay(self._play_list[index])
    else
        commonlib.showLocalTip("此玩家还未说话哦")
    end
end

function SpeekNode:onRcvSpeek(rtn_msg)
    local index = self._scene:indexTrans(rtn_msg.index)
    local name  = "其它玩家"
    if index and self._scene.player_ui[index] and self._scene.player_ui[index].user and self._scene.player_ui[index].user.nickname then
        name = self._scene.player_ui[index].user.nickname
    end
    if self:isSpeexMsg(rtn_msg.msg) then
        if NativeUtil:getAbility("speex") then
            if index ~= 1 then
                SpeekMgr:addPlay(rtn_msg.msg)
                self._play_list[index] = rtn_msg.msg
            end
        else
            local str = string.format("因您的游戏版本过低,无法播放%s的语音消息,请重新下载游戏!", name)
            commonlib.showLocalTip(str)
        end
    end
end

function SpeekNode:onRecordStart(data)
    print("onRecordStart")
    self:addRecordAni()
    AudioManager:pauseMusic()
end

function SpeekNode:onRecordStop(info)
    -- dump(info,"onRecordStop")
    self:removeRecordAni()
    if info.Param.BCancel == tostring(0) then
        -- cc.vv.log("录音成功")
        if info.Param.Url then
            local input_msg = {
                cmd      = NetCmd.C2S_ROOM_CHAT,
                msg_type = 3,
                msg      = info.Param.Url,
                len      = info.Param.SoundLen,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    elseif info.Param.BCancel == tostring(1) then
        -- cc.vv.log("录音取消")
        AudioManager:resumeMusic()
        if tonumber(info.Param.SoundLen) == 0 then
            commonlib.showLocalTip("录音时间太短")
        elseif tonumber(info.Param.SoundLen) <= 0.55 then
            commonlib.showLocalTip("录音时间太短")
        else
            -- commonlib.showLocalTip("录音取消")
            self:cancelRecordAni()
        end
    end
end

function SpeekNode:onRecordTimeOut()
    print("onRecordTimeOut")
    self:removeRecordAni()
    AudioManager:resumeMusic()
    commonlib.showLocalTip("录音超时")
end

function SpeekNode:onRecordFaild()
    print("onRecordFaild")
    self:removeRecordAni()
    AudioManager:resumeMusic()
    self:failRecordAni()
    -- commonlib.showLocalTip("录音失败")
end

function SpeekNode:onWillPlay(info)
    -- dump(info,"onWillPlay")
    self:removeRecordAni()
    AudioManager:pauseMusic()
    local idx = nil
    for i, v in ipairs(self._scene.player_ui or {}) do
        if v.user and v.user.user_id == tonumber(info.Param.userid) then
            idx = i
        else
            -- mj
            local userData = PlayerData.getPlayerDataByClientID(i)
            if userData and userData.uid == tonumber(info.Param.userid) then
                idx = i
            end
        end
    end
    if idx then
        self:playSpeekAni(idx, tonumber(info.Param.record_len) or 15, "speex")
    end
end

function SpeekNode:onPlayStop(data)
    print("onPlayStop")
    AudioManager:resumeMusic()
    self:removeSpeekAni(data)
end

function SpeekNode:playSpeekAni(index, len, speekType)
    self:removeSpeekAni({})
    local shuohua      = tolua.cast(cc.CSLoader:createNode("ui/shuohua.csb"), "ccui.Widget")
    local shuohuakuang = ccui.Helper:seekWidgetByName(shuohua, "Panel_1")
    local pos          = commonlib.worldPos(self._scene.player_ui[index])
    if index == 2 then
        shuohua:setPosition(cc.p(pos.x - 50, pos.y + 25))
        shuohuakuang:setScaleX(-1)
        local x1, y1 = shuohuakuang:getPosition()
        ccui.Helper:seekWidgetByName(shuohua, "Panel_2"):setPosition(cc.p(x1 - 300, y1))
    else
        shuohua:setPosition(cc.p(pos.x + 50, pos.y + 25))
    end
    self:addChild(shuohua, 999)
    local active = cc.CSLoader:createTimeline("ui/shuohua.csb")
    shuohua:runAction(active)
    shuohua:runAction(cc.Sequence:create(cc.DelayTime:create(len or 15), cc.CallFunc:create(function()
        EventBus:dispatchEvent(EventEnum.onPlayStop, {mType = speekType, index = index})
    end)))
    active:gotoFrameAndPlay(0, true)
    self.shuohuaList        = self.shuohuaList or {}
    self.shuohuaList[index] = shuohua
end

function SpeekNode:removeSpeekAni(data)
    if not self.shuohuaList then return end
    if data and data.index then
        if self.shuohuaList[data.index] then
            self.shuohuaList[data.index]:removeFromParent(true)
            self.shuohuaList[data.index] = nil
        end
    else
        for k, shuohua in pairs(self.shuohuaList) do
            shuohua:removeFromParent(true)
            self.shuohuaList[k] = nil
        end
    end
end

function SpeekNode:addRecordAni()
    if self.huatong then
        self.huatong:stopAllActions()
        self.huatong:removeFromParent(true)
        self.huatong = nil
    end
    self.huatong  = tolua.cast(cc.CSLoader:createNode("ui/shuohuatong.csb"), "ccui.Widget")
    local Image_1 = ccui.Helper:seekWidgetByName(self.huatong, "Image_1")
    self.huatong:setPosition(g_visible_size.width / 2 - Image_1:getContentSize().width / 2, g_visible_size.height / 2 - Image_1:getContentSize().height / 2)
    self:addChild(self.huatong, 99999)

    local active = cc.CSLoader:createTimeline("ui/shuohuatong.csb")
    self.huatong:runAction(active)
    active:gotoFrameAndPlay(0, true)
end

function SpeekNode:removeRecordAni()
    if self.huatong then
        self.huatong:stopAllActions()
        self.huatong:removeFromParent(true)
        self.huatong = nil
    end
end

function SpeekNode:failRecordAni()
    local shuohua = tolua.cast(cc.CSLoader:createNode("ui/shuohuatongfaild.csb"), "ccui.Widget")
    self:addChild(shuohua, 99999)
    local Image_1 = ccui.Helper:seekWidgetByName(shuohua, "Image_1")
    shuohua:setPosition(g_visible_size.width / 2 - Image_1:getContentSize().width / 2, g_visible_size.height / 2 - Image_1:getContentSize().height / 2)

    local ImgCancel = ccui.Helper:seekWidgetByName(shuohua, "ImgCancel")
    ImgCancel:setVisible(false)

    local tCancel = ccui.Helper:seekWidgetByName(shuohua, "tCancel")
    tCancel:setVisible(false)

    shuohua:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        shuohua:removeFromParent(true)
    end)))
end

function SpeekNode:cancelRecordAni()
    local shuohua = tolua.cast(cc.CSLoader:createNode("ui/shuohuatongfaild.csb"), "ccui.Widget")
    self:addChild(shuohua, 99999)
    local Image_1 = ccui.Helper:seekWidgetByName(shuohua, "Image_1")
    shuohua:setPosition(g_visible_size.width / 2 - Image_1:getContentSize().width / 2, g_visible_size.height / 2 - Image_1:getContentSize().height / 2)

    local ImgTimeShort = ccui.Helper:seekWidgetByName(shuohua, "ImgTimeShort")
    ImgTimeShort:setVisible(false)

    local tTimeShort = ccui.Helper:seekWidgetByName(shuohua, "tTimeShort")
    tTimeShort:setVisible(false)

    shuohua:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        shuohua:removeFromParent(true)
    end)))
end

function SpeekNode:onMjSound(rtn_msg)
    local node  = self._scene
    local index = node:indexTrans(rtn_msg.index)
    if rtn_msg.msg_type == 1 then
        local tips = nil
        if rtn_msg.is_zgz then
            if index == 2 or index == 3 or index == 4 then
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
                tips:setAnchorPoint(1.0, 0.5)
            else
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
                tips:setAnchorPoint(0.0, 0.5)
            end
        else
            if index == 2 then
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
                tips:setAnchorPoint(1.0, 0.5)
            else
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
                tips:setAnchorPoint(0.0, 0.5)
            end
        end
        tips:setPreferredSize(cc.size(330, 60))
        tips:setCapInsets(cc.rect(15, 15, 12, 25))
        tips:setPosition(commonlib.worldPos(node.player_ui[index]))
        node:addChild(tips, 999)

        local str   = ymkj.base64Decode(rtn_msg.msg)
        local title = cc.LabelTTF:create(str, "STHeitiSC-Medium", 22)
        title:setHorizontalAlignment(1)
        title:setColor(cc.c3b(29, 87, 166))
        title:setPosition(cc.p(165, 30))
        tips:addChild(title)

        title:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1)))

        tips:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1), cc.CallFunc:create(function()
            tips:removeFromParent(true)
        end)))

        for ii, tt in ipairs(specTextConfig) do
            if tt == str then
                local lg = cc.UserDefault:getInstance():getStringForKey("language", "gy")
                AudioManager:playDWCSound("sound/liaotian/"..lg.."/" .. "1_"..ii..".mp3")
                -- AudioManager:playDWCSound("sound/liaotian/"..lg.."/"..math.max(node.player_ui[index].user.sex or 1, 1).."_"..ii..".mp3")
                break
            end
        end
    elseif rtn_msg.msg_type == 2 then
        local sex = 1
        if node.player_ui[index].user then
            sex = node.player_ui[index].user.sex
        else
            -- mj
            local userData = PlayerData.getPlayerDataByClientID(index)
            if userData and userData.sex then
                sex = userData.sex
            end
        end
        local tips = commonlib.playbq(rtn_msg.msg, commonlib.worldPos(node.player_ui[index]), nil, math.max(sex or 1, 1))
        if tips then
            node:addChild(tips, 999)
        end
    elseif rtn_msg.msg_type == 4 then
        local tips = nil
        if rtn_msg.is_zgz then
            if index == 2 or index == 3 or index == 4 then
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
                tips:setAnchorPoint(1.0, 0.5)
            else
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
                tips:setAnchorPoint(0.0, 0.5)
            end
        else
            if index == 2 then
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
                tips:setAnchorPoint(1.0, 0.5)
            else
                tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
                tips:setAnchorPoint(0.0, 0.5)
            end
        end
        tips:setPreferredSize(cc.size(330, 60))
        tips:setCapInsets(cc.rect(15, 15, 12, 25))
        tips:setPosition(commonlib.worldPos(node.player_ui[index]))
        node:addChild(tips, 999)

        local str = ymkj.base64Decode(rtn_msg.msg)
        if pcall(commonlib.GetMaxLenString, str, 22) then
            str = commonlib.GetMaxLenString(str, 22)
        else
            str = str
        end
        local title = cc.LabelTTF:create(str, "STHeitiSC-Medium", 22)
        title:setHorizontalAlignment(1)
        title:setColor(cc.c3b(29, 87, 166))
        title:setPosition(cc.p(165, 30))
        tips:addChild(title)
        title:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1)))

        tips:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1), cc.CallFunc:create(function()
            tips:removeFromParent(true)
        end)))
    end
    ------- 发送快捷语后所有人该按钮禁用3秒钟
    node.btnFaYan:setTouchEnabled(false)
    node.btnFaYan:setBright(false)
    gt.performWithDelay(node.btnFaYan, function()
        node.btnFaYan:setTouchEnabled(true)
        node.btnFaYan:setBright(true)
    end, 3)
end

function SpeekNode:onPokerSound(rtn_msg)
    local node  = self._scene
    local index = node:indexTrans(rtn_msg.index)
    if rtn_msg.msg_type == 1 then
        local tips = nil
        if index == 2 then
            tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
            tips:setAnchorPoint(1.0, 0.5)
        else
            tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
            tips:setAnchorPoint(0.0, 0.5)
        end
        tips:setPreferredSize(cc.size(330, 60))
        tips:setCapInsets(cc.rect(15, 15, 12, 25))
        tips:setPosition(commonlib.worldPos(node.player_ui[index]))
        node:addChild(tips, 999)

        local str   = ymkj.base64Decode(rtn_msg.msg)
        local title = cc.LabelTTF:create(str, "STHeitiSC-Medium", 22)
        title:setHorizontalAlignment(1)
        title:setColor(cc.c3b(128, 0, 128))
        title:setPosition(cc.p(165, 30))
        tips:addChild(title)

        title:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1)))

        tips:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1), cc.CallFunc:create(function()
            tips:removeFromParent(true)
        end)))
        for ii, tt in ipairs(specTextConfig) do
            if tt == str then
                local lg = cc.UserDefault:getInstance():getStringForKey("language", "gy")
                AudioManager:playDWCSound("sound/liaotian/"..lg.."/" .. "1_"..ii..".mp3")
                -- AudioManager:playDWCSound("sound/liaotian/"..lg.."/"..math.max(node.player_ui[index].user.sex or 1, 1).."_"..ii..".mp3")
                break
            end
        end
    elseif rtn_msg.msg_type == 2 then
        local sex = nil
        if node.player_ui[index].user then
            sex = node.player_ui[index].user.sex
        else
            -- mj
            local userData = PlayerData.getPlayerDataByClientID(index)
            if userData and userData.sex then
                sex = userData.sex
            end
        end
        sex        = math.max(sex or 1, 1)
        local tips = commonlib.playbq(rtn_msg.msg, commonlib.worldPos(node.player_ui[index]), nil, sex)
        if tips then
            node:addChild(tips, 999)
        end
    elseif rtn_msg.msg_type == 4 then
        local tips = nil
        if index == 2 then
            tips = ccui.Scale9Sprite:create("ui/qj_play/qipao.png")
            tips:setAnchorPoint(1.0, 0.5)
        else
            tips = ccui.Scale9Sprite:create("ui/qj_play/qipao_fs8.png")
            tips:setAnchorPoint(0.0, 0.5)
        end
        tips:setPreferredSize(cc.size(330, 60))
        tips:setCapInsets(cc.rect(15, 15, 12, 25))
        tips:setPosition(commonlib.worldPos(node.player_ui[index]))
        node:addChild(tips, 999)

        local str = ymkj.base64Decode(rtn_msg.msg)
        if pcall(commonlib.GetMaxLenString, str, 22) then
            str = commonlib.GetMaxLenString(str, 22)
        else
            str = str
        end
        local title = cc.LabelTTF:create(str, "STHeitiSC-Medium", 22)
        title:setHorizontalAlignment(1)
        title:setColor(cc.c3b(128, 0, 128))
        title:setPosition(cc.p(165, 30))
        tips:addChild(title)
        title:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1)))

        tips:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(2), cc.FadeOut:create(1), cc.CallFunc:create(function()
            tips:removeFromParent(true)
        end)))
    end
    ------- 发送快捷语后所有人该按钮禁用3秒钟
    node.btnFaYan:setTouchEnabled(false)
    node.btnFaYan:setBright(false)
    gt.performWithDelay(node.btnFaYan, function()
        node.btnFaYan:setTouchEnabled(true)
        node.btnFaYan:setBright(true)
    end, 3)
end

return SpeekNode