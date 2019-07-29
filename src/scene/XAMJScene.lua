local MJBaseScene = require('scene.MJBaseScene')

local XAMJScene = class("XAMJScene",MJBaseScene)

function XAMJScene.create(param_list)

    MJBaseScene.removeUnusedRes()

    local mj = XAMJScene.new(param_list)
    local scene = cc.Scene:create()
    scene:addChild(mj)
    return scene
end

function XAMJScene:setMjSpecialData()
    self.haoZi = 'ui/qj_mj/dt_play_laizi_img.png'
    self.haoZiDi = 'ui/qj_mj/dt_play_laizi.png'
    self.curLuaFile = 'scene.XAMJScene'

    self.mjTypeWanFa = 'xamj'

    self.RecordGameType = RecordGameType.XA
    self.mjGameName = '西安麻将'
end

function XAMJScene:loadMjLogic()
    self.MJLogic = require('logic.mjxian_logic')
end

function XAMJScene:PassTing(value)
    return false
end

function XAMJScene:PassGang(value)
    return false
end

function XAMJScene:onRcvMjGameStartOwnerData()
    for i =1 ,4 do
        self:removeTingTag(i)
        local userData = PlayerData.getPlayerDataByClientID(i)
        self.player_ui[i]:getChildByName("paozifen"):getChildByName("num"):setString(userData and userData.paozi or 0)
    end

    self.wanfa:setVisible(true)
    self.btnjiesan:setVisible(false)
    self.dengdai:setVisible(false)
    self.jiesanroom:setVisible(false)
end

function XAMJScene:treatPlayback(rtn_msg)
    self.direct_img_cur = nil
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i+1] = v
    end

    local function setWangCard()
        local haoziSprite = cc.Sprite:create(self.haoZiDi)
        haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-150))
        self.node:addChild(haoziSprite)

        self.wang_cards = {rtn_msg.wang, rtn_msg.wang1, rtn_msg.wang2}
        self.wang_card_list = {}
        for i, v in ipairs(self.wang_cards) do
            local pai = self:getOpenCardById(1, v, true)
            pai.card_id = v
            pai:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
            self.node:addChild(pai)

            haoziSprite:setPosition(cc.p(g_visible_size.width-80, g_visible_size.height-165))
            pai:runAction(cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(g_visible_size.width-80, g_visible_size.height-150))))
            self.wang_card_list[i] = pai
        end
        if 0 == #self.wang_card_list then
            haoziSprite:setVisible(false)
        end
    end

    setWangCard()

    for __, player in ipairs(playerinfo_list) do
        commonlib.echo(player)
        local direct = self:indexTrans(player.index)
        table.sort(player.cards)
        for ii, cid in ipairs(player.cards) do
            local pai = nil
            if direct == 1 then
                pai = self:getCardById(direct, cid)
                pai.sort = 0
                pai.card_id = cid
            else
                pai = self:getBackCard(direct)
                pai.card_id = 1000+cid
                pai.sort = 0
                pai.ssort = ii
            end
            self.node:addChild(pai)
            self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
        end
        self:sortHandCardEx(direct)
        self:placeHandCard(direct)
        self.player_ui[direct]:getChildByName("paozifen"):getChildByName("num"):setString(player.paozi)
    end
    self.left_card_num = rtn_msg.left_card_num
    self.left_lbl:setString(self.left_card_num)
    self.left_lbl:setVisible(true)
end

function XAMJScene:treatResume(rtn_msg)
    self:resetOperBtnTag()
    -- 断线重连
    if self.is_playback then
        self:addPlist()
        self:treatPlayback(rtn_msg)
        return
    end
    if rtn_msg.result_packet then
        self:treatResumeSaveRecord(rtn_msg.result_packet)
    end
    self.quan_lbl:setVisible(true)
    self.direct_img_cur = nil
    self.is_treatResume = true
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))
    local is_start = rtn_msg.cur_id and #rtn_msg.player_info.hand_card > 0
    if is_start then
        self:addPlist()
    end
    if is_start and rtn_msg.cur_id > 0 and rtn_msg.cur_id <= 4 then
        local play_index = self:indexTrans(rtn_msg.cur_id)
        self:showWatcher(play_index, rtn_msg.time or 15)
    end

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i+1] = v
    end
    self:treatResumeLastOutCard(rtn_msg,playerinfo_list)

    if is_start then
        for i,v in ipairs(playerinfo_list) do
            if v.paozi ~= 0 then
                self.player_ui[self:indexTrans(i)]:getChildByName("paozifen"):getChildByName("num"):setString(playerinfo_list[i].paozi)
            end
        end
    else
        if playerinfo_list[1].ready then
            self.dengdai:setVisible(true)
            self:showWatcher(self.banker, rtn_msg.time or 15)
            commonlib.showShareBtn(self.share_list)
            commonlib.showbtn(self.jiesanroom)
        end
    end

    self:setLaZi(rtn_msg)

    if rtn_msg.result_packet then
        if g_channel_id == 800002 then
            AudioManager:stopPubBgMusic()
        end
        self:initResultUI(rtn_msg.result_packet)
        return
    end

    self.ting_status = rtn_msg.player_info.is_ting
    if self.ting_status then
        self.ting_list = {}
    end

    local is_kg_resume = nil
    local kg_actions = nil

    local windowSize = cc.Director:getInstance():getWinSize()

    for __, player in ipairs(playerinfo_list) do
        local direct = self:indexTrans(player.index)

        -- 下坎的牌
        self:treatResumeGroupCard(direct,player.group_card)

        -- log('断线重连 direct ' .. tostring(direct) .. ' 听牌 ' .. tostring(player.is_ting))
        if direct == 1 then
            local len = 14 - (#player.group_card*3)
            -- 设置手牌
            for ci, cid in ipairs(player.hand_card) do
                if ci <= len then
                    local pai = self:getCardById(direct, cid)
                    pai.card_id = cid
                    pai.sort = 0
                    self.node:addChild(pai, 10)
                    self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                end
            end

            -- 设置
            if player.kg_actions then
                self.oper_panel.no_reply = true
                if player.kg_actions[1] and player.kg_actions[2] then
                    kg_actions  = player.kg_actions
                end
                is_kg_resume = true
            -- elseif player.haidi_ting ~= 0 then
            --     self:resetOperPanel({100},  player.haidi_ting==2)
            --     self.oper_panel.time_out_flag = true
            elseif player.actions and #player.actions > 0 then
                self:resetOperPanel(player.actions, nil, player.oper_card, player.msgid, player.kg_cards)
            end
        elseif is_start then
            local len = 13 - (#player.group_card*3)
            if rtn_msg.cur_id ~= rtn_msg.last_id and rtn_msg.cur_id == player.index then
                len = len+1
            end
            for ii=1, len  do
                local pai = self:getBackCard(direct)
                pai.card_id = 1000
                pai.sort = 0
                pai.ssort = ii
                if direct == 4 then
                    self.node:addChild(pai, 14-ii)
                else
                    self.node:addChild(pai, 10)
                end
                self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
            end
        end

        self:sortHandCard(direct, true)

        local b14Card = self:treatResume14thCard(direct,player)

        self:placeHandCard(direct,nil, not b14Card)

        if player.is_ting and direct == 1 then
            self:addCardShadow()
        end

        if player.is_ting then
            self:addTingTag(direct)
        end

        -- player.out_card = {1,2,3,4,0,0,0,4,1,2,3,1,1,1,1,1,1,2,1,2,1,2}
        self:treatResumeOutCard(direct,player.out_card)
    end

    if rtn_msg.left_card_num and self.is_game_start then
        self.left_card_num = rtn_msg.left_card_num
        self.left_lbl:setString(self.left_card_num)
        self.left_lbl:setVisible(true)
    end

    if rtn_msg.last_id then
        self.pre_out_direct = self:indexTrans(rtn_msg.last_id)
        self:showCursor()
    end

    if is_kg_resume then
        if self.pre_out_direct then
            local out_card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
            if out_card then
                out_card.kg = true
            end
        end
    end
end

function XAMJScene:sendOperate(value, opt, target_value)

    if opt == 3 then
        opt = 4
    end
    if self.oper_pai_bg then
        self.oper_pai_bg:removeFromParent(true)
        self.oper_pai_bg = nil
    end
    if opt == 2 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_PENG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 3 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_KAIGANG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 4 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_GANG},
            {index=self.my_index},
        }
        if target_value then
            input_msg[3] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 1 then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_CHI_CARD},
            {cards=value},
            {index=self.my_index},
        }
        if target_value then
            input_msg[4] = {card=target_value}
        end
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    elseif opt == 5 then
        if self.hu_type == 101 then
            local input_msg = {
                cmd =NetCmd.C2S_MJ_BBHU,
                typ =self.bbh_data[1].typ,
                index=self.my_index,
            }
            ymkj.SendData:send(json.encode(input_msg))
        elseif self.hu_type == 7 then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_BBHU},
                {index=self.my_index},
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        elseif self.hu_type == 5 then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_CHI_HU},
                {index=self.my_index},
            }
            if target_value then
                input_msg[3] = {card=target_value}
            end
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        else
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_HU},
                {index=self.my_index},
            }
            if target_value then
                input_msg[3] = {card=target_value}
            end
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        end
    elseif opt == 6 then
        local input_msg = {
            cmd =NetCmd.C2S_MJ_HAIDI,
            need =1,
            index=self.my_index,
        }
        ymkj.SendData:send(json.encode(input_msg))
    elseif opt == 0 then
        if not self.oper_panel.time_out_flag then
            local input_msg = {
                {cmd =NetCmd.C2S_PASS},
                {index=self.my_index},
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))
        else
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_HAIDI},
                {need =0},
                {index=self.my_index},
            }
            ymkj.SendData:send(json.encode2(input_msg))
        end
    elseif opt == self.TING_OPERATOR then
        self.ting_list = {}
        self:removeTingArrow()

        local input_msg = {
            {cmd =NetCmd.C2S_MJ_TINGPAI},
            {index=self.my_index},
            {card = target_value},
        }
        ymkj.SendData:send(json.encode2(input_msg))
    end

    self.oper_panel.msgid = nil
end






function XAMJScene:chiOptTreat(open_value, target_value)
    print("chi")
    local target_list = {{open_value-2,open_value-1},{open_value-1,open_value+1},{open_value+1,open_value+2}}
    local valid_index_list = {}
    for __, v in ipairs(target_list) do
        if v[1] ~= self.wang_cards[2] and v[1] ~= self.wang_cards[3] and v[2] ~= self.wang_cards[2] and v[2] ~= self.wang_cards[3] then
            local index1 = -1
            local index2 = -1
            for ii, vv in ipairs(self.hand_card_list[1] or {}) do
                if vv.sort == 0 then
                    if vv.card_id== v[1] then
                        index1 = ii
                    end
                    if vv.card_id== v[2] then
                        index2 = ii
                    end
                end
            end
            if index1~=-1 and index2~=-1 then
                valid_index_list[#valid_index_list+1] = {index1, index2}
            end
        end
    end
    if #valid_index_list == 1 then
        local index1 = valid_index_list[1][1]
        local index2 = valid_index_list[1][2]
        if index1~=-1 and index2 ~= -1 then
            local last_index = 0
            for t=1, #self.hand_card_list[1] do
                if t~= index1 and t~= index2 then
                    last_index = t
                end
            end
            local last_value = 0
            if last_index ~= 0 then
                last_value = self.hand_card_list[1][last_index].card_id
            end
            local base_i = self:handCardBaseIndex(1)
            self:sendOperate({self.hand_card_list[1][index1].card_id, self.hand_card_list[1][index2].card_id}, 1, target_value)
        end
        self.oper_panel:setVisible(false)
    elseif #valid_index_list > 1 then
        self.oper_panel:setVisible(false)
        self.chi_panel:setVisible(true)
        ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(#valid_index_list/3)
        for i=1, 3 do
            local btn = self.chi_panel:getChildByName("com"..i)
            local vv = valid_index_list[i]
            if vv then
                btn:setTouchEnabled(true)
                btn:setVisible(true)
                local card_id_list = {self.hand_card_list[1][vv[1]].card_id, self.hand_card_list[1][vv[2]].card_id, open_value}
                table.sort( card_id_list, function(a, b) return a < b end )
                for cii, cid in ipairs(card_id_list) do
                    local color = math.floor(cid/16)
                    if color == 0 then
                        color = ""
                    end
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_"..cii), "ccui.ImageView"):loadTexture("card/img_cardvalue"..color..(cid%16)..".png")
                end
                btn:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        local index1 = vv[1]
                        local index2 = vv[2]
                        local last_index = 0
                        for t=1, #self.hand_card_list[1] do
                            if t~= index1 and t~= index2 then
                                last_index = t
                            end
                        end
                        local last_value = 0
                        if last_index ~= 0 then
                            last_value = self.hand_card_list[1][last_index].card_id
                        end
                        local base_i = self:handCardBaseIndex(1)
                        self:sendOperate({self.hand_card_list[1][index1].card_id, self.hand_card_list[1][index2].card_id}, 1, target_value)
                        self.chi_panel:setVisible(false)
                    end
                end)
            else
                btn:setTouchEnabled(false)
                btn:setVisible(false)
            end
        end
        local cancel_btn = ccui.Helper:seekWidgetByName(self.chi_panel, "cancel")
        cancel_btn:setVisible(true)
        cancel_btn:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self.chi_panel:setVisible(false)
                self.oper_panel:setVisible(true)
            end
        end)
    end
end

function XAMJScene:createLayerMenu(room_info)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end

    self:setOwnerName(room_info)
    local ui_prefix = "pm"

    print("ui/Room"..ui_prefix..".csb")

    local node = nil
    if self.is_3dmj then
        node = tolua.cast(cc.CSLoader:createNode("ui/XAMJRoom3d.csb"), "ccui.Widget")
    else
        node = tolua.cast(cc.CSLoader:createNode("ui/XAMJRoom.csb"), "ccui.Widget")
    end

    self.res3DPath = 'ui/qj_mj/3d'

    self:addChild(node)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node

    local img_bg = ccui.Helper:seekWidgetByName(node, "Panel_1"):getChildByName("Image_2")
    local img_bg_title = tolua.cast(img_bg:getChildByName("img_title"), "ccui.ImageView")
    img_bg_title:setVisible(not ios_checking)
    if self.is_3dmj then
        img_bg_title:loadTexture("ui/qj_bg/3d/3d_xamj.png")
        img_bg:loadTexture(self.img_3d[self.zhuobu])
    else
        img_bg_title:loadTexture("ui/qj_bg/2d/2d_xamj.png")
        img_bg:loadTexture(self.img_2d[self.zhuobu])
    end
    self.img_bg = img_bg
    self.batteryProgress = ccui.Helper:seekWidgetByName(node, "battery")
    gt.refreshBattery(self.batteryProgress)
    self.signalImg = ccui.Helper:seekWidgetByName(node, "img_xinhao")

    self:setNonePeopleChair()

    self:setBtns()

    ccui.Helper:seekWidgetByName(node,"Image_tip"):setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)

    -- 返回大厅
    self:setBtnJieSan()

    self.hand_card_list = {}
    self.hand_card_list[1] = {}
    self.hand_card_list[2] = {}
    self.hand_card_list[3] = {}
    self.hand_card_list[4] = {}

    self.out_card_list = {}
    self.out_card_list[1] = {}
    self.out_card_list[2] = {}
    self.out_card_list[3] = {}
    self.out_card_list[4] = {}


    -- 中间倒计时
    ccui.Helper:seekWidgetByName(node,"LeftLbl"):setVisible(false)
    ccui.Helper:seekWidgetByName(node,"LeftLbl_3d"):setVisible(false)
    if self.is_3dmj then
        self.watcher_lab = tolua.cast(ccui.Helper:seekWidgetByName(node,"LeftLbl_3d"), "ccui.Text")
    else
        self.watcher_lab = tolua.cast(ccui.Helper:seekWidgetByName(node,"LeftLbl"), "ccui.Text")
    end
    self.watcher_lab:setVisible(true)
    self.watcher_lab:setString("00")

    self.direct_img_cur = nil

    self:setPlayerHead()

    -- 吃碰杠胡操作面板
    local oper_ui = tolua.cast(cc.CSLoader:createNode("ui/Oper"..ui_prefix..".csb"), "ccui.Widget")
    self:addChild(oper_ui, 10000)

    oper_ui:setContentSize(g_visible_size)

    ccui.Helper:doLayout(oper_ui)

    self.oper_panel = oper_ui:getChildByName("Panel_caozuo")
    self.oper_panel:setVisible(false)

    self.chi_panel = oper_ui:getChildByName("Panel_chi")
    self.chi_panel:setVisible(false)

    -- 碰回调
    local function pengOptTreat()
        print("peng")
        local open_value = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]].card_id
        local index_list = {}
        for ii, vv in ipairs(self.hand_card_list[1] or {}) do
            if vv.sort == 0 and vv.card_id== open_value then
                index_list[#index_list+1] = ii
            end
        end
        if #index_list >= 2 then
            local last_index = 0
            for t=1, #self.hand_card_list[1] do
                local valid = true
                for __, xx in ipairs(index_list) do
                    if xx == t then
                        valid = false
                        break
                    end
                end
                if valid then
                    last_index = t
                end
            end
            local last_value = 0
            if last_index ~= 0 then
                last_value = self.hand_card_list[1][last_index].card_id
            end
            local base_i = self:handCardBaseIndex(1)
            self:sendOperate({self.hand_card_list[1][index_list[1]].card_id, self.hand_card_list[1][index_list[2]].card_id}, 2)
        end
        self.oper_panel:setVisible(false)
    end

    -- 杠回调
     local function gangOptTreat(open_value_list)
        print("gang")
        if not open_value_list or #open_value_list == 0 then
            self:sendOperate(nil, 3)
        elseif #open_value_list == 1 then
            self:sendOperate(open_value_list[1], 3, open_value_list[1])
        else
            self.chi_panel:setVisible(true)
            ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(#open_value_list/3)
            for i=1, 3 do
                local btn = self.chi_panel:getChildByName("com"..i)
                local vv = open_value_list[i]
                if vv then
                    btn:setTouchEnabled(true)
                    btn:setVisible(true)

                    local color = math.floor(vv/16)
                    if color == 0 then
                        color = ""
                    end
                    if self.is_3dmj then
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv%16)..".png")
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/back1.png")
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):setScale(0.7)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv%16)..".png")
                    else
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei1"), "ccui.ImageView"):loadTexture(self:getCardTexture(vv),1)
                        if self.is_pmmj then
                            tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei2"), "ccui.ImageView"):loadTexture('ee_mj_b_up.png',1)
                        elseif self.is_pmmjyellow then
                            tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei2"), "ccui.ImageView"):loadTexture('e_mj_b_up.png',1)
                        end
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei3"), "ccui.ImageView"):loadTexture(self:getCardTexture(vv),1)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):setVisible(false)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):setVisible(false)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):setVisible(false)
                    end

                    btn:addTouchEventListener(function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            self:sendOperate(vv, 3, vv)
                            self.chi_panel:setVisible(false)
                        end
                    end)
                else
                    btn:setTouchEnabled(false)
                    btn:setVisible(false)
                end
            end
            local cancel_btn = ccui.Helper:seekWidgetByName(self.chi_panel, "cancel")
            cancel_btn:setVisible(true)
            cancel_btn:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    self.chi_panel:setVisible(false)
                    self.oper_panel:setVisible(true)
                end
            end)
        end
        self.oper_panel:setVisible(false)
    end

    -- 可碰杠胡时的回调
    local function operCallback(opt_type)
        log(' !!!!!!!!!!!!!!! ' .. tostring(opt_type))

        self:removeCardShadow()

        -- 听
        self.tdh_need_bTing = false
        self.hasHu = false
        if self.oper_pai_id then
            self.oper_pai_id = 0
        end
        if self.oper_pai_bg and opt_type ~= "guo" and opt_type ~= "guo_hu" and type(opt_type) ~= "table" then
            self.oper_pai_bg:removeFromParent(true)
            self.oper_pai_bg = nil
        end

        self:removeShowPai()

        local treat = nil
        if type(opt_type) == "table" then
            gangOptTreat(opt_type)
            treat = true
        elseif opt_type == "guo" then
            if not self.only_bu then
                self:sendOperate(nil, 0)
            else
                self.only_bu = nil
                if self.oper_pai_bg then
                    self.oper_pai_bg:removeFromParent(true)
                    self.oper_pai_bg = nil
                end
            end
        elseif opt_type == "guo_hu" then
            local input_msg = {
                {cmd =NetCmd.C2S_MJ_DO_PASS_HU},
                {index=self.my_index},
                {card = self.last_out_card},
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))

            commonlib.showTipDlg("您确定过胡吗？", function(ok)
                if ok then
                    operCallback("guo")
                end
            end)

            treat = true
        elseif opt_type == "peng" then
            pengOptTreat()
            treat = true
        elseif opt_type == "gang" then
            gangOptTreat()
            treat = true
        elseif opt_type == "bu" then
            treat = true
        elseif opt_type == "chi" then
            self:chiOptTreat(self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]].card_id)
            treat = true
        elseif opt_type == "hu" then
            self:sendOperate(nil, 5)
        elseif opt_type == "yao" then
            self:sendOperate(nil, 6)
        elseif opt_type == 'ting' then
            if self.btnTing then
                self.btnTing:setVisible(false)
            end
            -- 获取听牌列表
            self.tdh_need_bTing = true

            for i , card in pairs(self.hand_card_list[1]) do
                if not self.ting_list[card.card_id] or 0 == #self.ting_list[card.card_id] then
                    local card_shadow = card:getChildByName('card_shadow')
                    if not card_shadow and card.sort == 0 then
                        local card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
                        card_shadow:setAnchorPoint(0.05, 0.05)
                        card_shadow:setName('card_shadow')
                        if self.is_pmmj or self.is_pmmjyellow then
                            card_shadow:setAnchorPoint(0, 0)
                            local iCardSize = card:getContentSize()
                            local iCardShadowSize = card_shadow:getContentSize()
                            card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width)
                            card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height)
                        end
                        self.hand_card_list[1][i]:addChild(card_shadow)
                    end
                end
            end
            ------------------------------------------------
            treat = true
        end

        if not treat then
            self.oper_panel:setVisible(false)
        end
    end

    self:setOperBtn(operCallback)

    self.ting_list = {}

    self.my_sel_index = nil
    self.my_sel_index_sceond = nil

    local sel_init_posx = nil
    local has_move = nil
    self:setTouchEnabled(true)
    local preX = 0
    local preY = 0
    -- 点击按钮
    self:registerScriptTouchHandler(function(touch_type, xx, yy)
        if self.can_opt then
            if touch_type == "began" then
                local vaild = false
                vaild,sel_init_posx,preX,preY,has_move = self.MJClickAction.Began(self,xx,yy,preX,preY,sel_init_posx,has_move)
                return vaild
            elseif touch_type == "moved" then
                sel_init_posx,preX,preY,has_move = self.MJClickAction.Move(self,xx,yy,preX,preY,sel_init_posx,has_move)
            else
                local function callFunc()
                    if self.hasHu then
                        return true
                    end
                end
                has_move = self.MJClickAction.End(self,xx,yy,preX,preY,sel_init_posx,has_move,callFunc)
            end
        end
    end)

    -- 剩于牌张数
    self.left_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "zhangshu"), "ccui.Text")
    if self.is_pmmj or self.is_pmmjyellow then
        self.left_lbl:setString("-")
    else
        self.left_lbl:setVisible(false)
    end

    self:setSysTime()

    self:setRoomData()

    if room_info.result_packet then
        room_info.cur_ju = room_info.result_packet.cur_ju or room_info.cur_ju or 1
    else
        room_info.cur_ju = room_info.cur_ju or 1
    end

    -- 局数
    self.quan_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "Quan_Text"), "ccui.Text")
    self.total_ju = room_info.total_ju
    self.quan_lbl:setVisible(false)
    if self.is_playback then
        self:setLastJu(self.total_ju, room_info.cur_ju or 0)
    else
        if self.total_ju > 100 then
            self:setLastJu(self.total_ju, room_info.cur_quan or 0)
        else
            self:setLastJu(self.total_ju, room_info.cur_ju or 0)
        end
    end

    self.is_game_start = (room_info.status~=0)
    self.is_fangzhu = (room_info.qunzhu ~= 1 and self.my_index == 1)
    self.people_num = room_info.people_num or 4

    self:initOutCardPos()

    self:initPlayerHead()


    self.xiapaozi_mode = room_info.isXiaPaoZi

    self.niaofen = room_info.niaofen

    -- 指向标 锥子
    self.cursor = cc.Sprite:create('ui/qj_mj/zhuizi.png')
    self.cursor:setScale(0.8)
    if not self.is_pmmj and not self.is_pmmjyellow then
        self.cursor:setAnchorPoint(0.5, -0.3)
    else
        self.cursor:setAnchorPoint(0.5, -0.6)
    end
    self.cursor:setVisible(false)
    self:addChild(self.cursor, 202)

    -- 下炮子
    local xiapaozi = 0
    self.dengdai = ccui.Helper:seekWidgetByName(node, "dengdaiBg")
    self.dengdai:setVisible(false)
    self.xiapaozi_panel = ccui.Helper:seekWidgetByName(node, "xiapaozi")
    self.btn_xiapaozi = tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"btn-xiapaozi"),"ccui.Button")
    self.btn_xiapaozi:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:sendReady(xiapaozi)
                self.xiapaozi_panel:setVisible(false)
                self.xiapaozi_panel:setEnabled(false)
                self.dengdai:setVisible(true)
            end
    end)
    local xamj_xiapaozibtn_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"0fen"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"1fen"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"2fen"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"3fen"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.xiapaozi_panel,"4fen"),"ccui.Button"),
    }

    local function initXPZShowOpt()
        if xiapaozi == 0 then
            self:setOpt(xamj_xiapaozibtn_list[1], false, true)
            self:setOpt(xamj_xiapaozibtn_list[2], false, false)
            self:setOpt(xamj_xiapaozibtn_list[3], false, false)
            self:setOpt(xamj_xiapaozibtn_list[4], false, false)
            self:setOpt(xamj_xiapaozibtn_list[5], false, false)
        end
        if xiapaozi == 1 then
            self:setOpt(xamj_xiapaozibtn_list[1], false, false)
            self:setOpt(xamj_xiapaozibtn_list[2], false, true)
            self:setOpt(xamj_xiapaozibtn_list[3], false, false)
            self:setOpt(xamj_xiapaozibtn_list[4], false, false)
            self:setOpt(xamj_xiapaozibtn_list[5], false, false)
        end
        if xiapaozi == 2 then
            self:setOpt(xamj_xiapaozibtn_list[1], false, false)
            self:setOpt(xamj_xiapaozibtn_list[2], false, false)
            self:setOpt(xamj_xiapaozibtn_list[3], false, true)
            self:setOpt(xamj_xiapaozibtn_list[4], false, false)
            self:setOpt(xamj_xiapaozibtn_list[5], false, false)
        end
        if xiapaozi == 3 then
            self:setOpt(xamj_xiapaozibtn_list[1], false, false)
            self:setOpt(xamj_xiapaozibtn_list[2], false, false)
            self:setOpt(xamj_xiapaozibtn_list[3], false, false)
            self:setOpt(xamj_xiapaozibtn_list[4], false, true)
            self:setOpt(xamj_xiapaozibtn_list[5], false, false)
        end
        if xiapaozi == 4 then
            self:setOpt(xamj_xiapaozibtn_list[1], false, false)
            self:setOpt(xamj_xiapaozibtn_list[2], false, false)
            self:setOpt(xamj_xiapaozibtn_list[3], false, false)
            self:setOpt(xamj_xiapaozibtn_list[4], false, false)
            self:setOpt(xamj_xiapaozibtn_list[5], false, true)
        end
    end
    for i, v in ipairs(xamj_xiapaozibtn_list) do
        v:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i == 1 then
                    xiapaozi = 0
                    initXPZShowOpt()
                elseif i == 2 then
                    xiapaozi = 1
                    initXPZShowOpt()
                elseif i == 3 then
                    xiapaozi = 2
                    initXPZShowOpt()
                elseif i == 4 then
                    xiapaozi = 3
                    initXPZShowOpt()
                elseif i == 5 then
                    xiapaozi = 4
                    initXPZShowOpt()
                end
            end
        end)
    end
    initXPZShowOpt()

    self.xiapaozi_panel:setVisible(false)
    self.xiapaozi_panel:setEnabled(false)

    self.share_list = {
                        -- 微信邀请
                        ccui.Helper:seekWidgetByName(node, "WxShare"),
                        -- 复制房号
                        ccui.Helper:seekWidgetByName(node, "btn-copyroom"),
                        --
                        ccui.Helper:seekWidgetByName(node, "DdShare"),
                        ccui.Helper:seekWidgetByName(node, "YxShare"),
                      }

    ccui.Helper:seekWidgetByName(node, "btn-copyroom"):setPositionY(ccui.Helper:seekWidgetByName(node, "WxShare"):getPositionY())

    self:initTimeArrow()

    -- 东南西北
    self.southPan = ccui.Helper:seekWidgetByName(node,"Img-zj")
    self.southPan:setVisible(false)

    -- 东南西北3d
    self.southPan3d = ccui.Helper:seekWidgetByName(node,"Img-zj_3d")
    self.southPan3d:setVisible(false)
    -- self.southPan3d:setPositionY(g_visible_size.height/2+50)
    -- self.southPan3d:setScale(0.8)

    self.direct_img_list = {}
    -- 庄家
    self.banker = self:indexTrans(room_info.host_id)
    -- 根据庄家初始化 东南西北位置
    self:initSouthPan()

    for __, v in ipairs(self.direct_img_list) do
       -- v.direct:setVisible(false)
        v:setOpacity(0)
    end

    if self.is_pmmj then
        self.southPan:setVisible(self.is_game_start)
    elseif self.is_3dmj then
        self.southPan3d:setVisible(self.is_game_start)
    end

    self.watcher_lab:setVisible(self.is_game_start)

    self.wanfa_str = self:getWanFaStr()
    -- 房间信息，局数，扎鸟等
    self:setShuoMing(self.wanfa_str)

    -- 听牌提示框
    local tingtip = tolua.cast(cc.CSLoader:createNode("ui/TingTip.csb"), "ccui.Widget")
    self:addChild(tingtip, 10000)
    tingtip:setContentSize(g_visible_size)
    ccui.Helper:doLayout(tingtip)

    self.ting_tip_layer = tingtip:getChildByName("bg")
    self.ting_tip_layer.pai_list = {}
    for i=1, 10 do
        local ting_item = {}
        local pai = tolua.cast(self.ting_tip_layer:getChildByName("pai"..i), "ccui.ImageView")
        ting_item.pos = cc.p(pai:getPosition())
        ting_item.num = tolua.cast(pai:getChildByName("num"), "ccui.Text")
        ting_item.ori_pai = pai
        self.ting_tip_layer.pai_list[i] = ting_item
    end
    self.ting_tip_layer:setVisible(false)
    -- end

    -- 王牌？  赖子牌?
    self.wang_cards = {room_info.wang, room_info.wang1, room_info.wang2}

    self.copy = (room_info.copy == 1)

    -- 准备相关
    if room_info.player_info and (room_info.player_info.hand_card or room_info.player_info.cards) then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:removeAllHandCard()
            self:treatResume(room_info)
        end
    end

    --关闭分享按钮 关闭解散按钮 显示玩法按钮
    if self.is_game_start then
        if not self.is_playback then
            ymkj.setHeartInter(0)
        end
    end

    self:setBtnsVisible()
    self:setEnterRoomIsStartStartHeadPos()
    --注册网络消息
    -- self:registerEventListener()

    -- GPS
    if (not room_info.player_info or not room_info.player_info.ready) and (not room_info.result_packet) and (not self.is_playback) then
        self:checkIpWarn()
    end

    -- 显示庄家
    if self.banker > 0 and self.banker <= 4 then
        self.player_ui[self.banker]:getChildByName("Zhang"):setVisible(true)
    end

    for i=1,4 do
        if self.xiapaozi_mode == false then
            self.player_ui[i]:getChildByName("paozifen"):setVisible(false)
        else
            self.player_ui[i]:getChildByName("paozifen"):setVisible(true)
        end
    end

	self:setBtnDeskShare()

    self.qunzhu = room_info.qunzhu
    self:setClubInvite()
end

function XAMJScene:checkTingTip(card_id)

    for i, v in ipairs(self.light_list or {}) do
        for __, vv in ipairs(v) do
            if i == 1 then
                vv:setColor(cc.c3b(255, 255, 255))
            else
                vv:setColor(cc.c3b(226, 226, 226))
            end
        end
    end
    self.light_list = {{},{}}

    if not card_id then
        if self.ting_tip_layer then
            self.ting_tip_layer:setVisible(false)
        end
        return
    end

    if self:isAnyHu(card_id) then
        return
    end

    for k=1, 4 do
        if self.hand_card_list[k] and #self.hand_card_list[k] > 0 then
            for __, v in ipairs(self.hand_card_list[k]) do
                if v.sort ~= 0 and v.card_id and v.card_id == card_id then
                    self.light_list[1][#self.light_list[1]+1] = v
                    v:setColor(cc.c3b(96, 96, 96))
                end
            end
        end
        if self.out_card_list[k] and #self.out_card_list[k] > 0 then
            for __, v in ipairs(self.out_card_list[k]) do
                if v.card_id and v.card_id == card_id then
                    self.light_list[2][#self.light_list[2]+1] = v
                    v:setColor(cc.c3b(96, 96, 96))
                end
            end
        end
    end

    if not self.ting_tip_layer then
        return
    end

    local hu_list = self.ting_list[card_id]
    if hu_list and #hu_list > 0 then
        self.ting_tip_layer:setVisible(true)
        for i=1, 10  do
            local ting_item = self.ting_tip_layer.pai_list[i]

            if ting_item.pai then
                ting_item.pai:removeFromParent(true)
                ting_item.pai = nil
            end

            if not hu_list[i] then
                ting_item.ori_pai:setVisible(false)
            else
                ting_item.ori_pai:setVisible(true)
                ting_item.pai = self:getCardById(1, hu_list[i][1], "_stand")
                if self.is_pmmj or self.is_pmmjyellow then
                    ting_item.pai:setScale(0.8)
                else
                    ting_item.pai:setScale(0.45)
                end
                ting_item.pai:setPosition(ting_item.pos)
                self.ting_tip_layer:addChild(ting_item.pai, 1)
                ting_item.num:setString(hu_list[i][2].."张")
            end
        end
    else
        self.ting_tip_layer:setVisible(false)
    end
end

function XAMJScene:openCard(direct, card_ids, opt_type, check_ac, lnLastUser)
    logUp('XAMJScene:openCard')

    log('direct ' .. tostring(direct))
    local str = ''
    for i = 1,#card_ids do
        str = str .. card_ids[i] .. '-'
    end
    log('card_ids ' .. str)

    log('opt_type ' .. tostring(opt_type))

    log('check_ac ' .. tostring(check_ac))

    self:removeShowPai()

    if not card_ids then
    elseif #card_ids == 1 and opt_type < 10 then
        local card = nil
        if direct == 1 then
            for i=#self.hand_card_list[direct], 1, -1 do
                local v = self.hand_card_list[direct][i]
                if v.sort == 0 and v.card_id == card_ids[1] then
                    card = v
                    break
                end
            end
        elseif self.is_playback then
            for i=#self.hand_card_list[direct], 1, -1 do
                local v = self.hand_card_list[direct][i]
                if v.sort == -1 and v.card_id == card_ids[1] then
                    card = v
                    break
                end
            end
        else
            card = self.hand_card_list[direct][#self.hand_card_list[direct]]
        end

        if self.show_pai then
            if self.show_pai.card then
                self.show_pai.card:setVisible(true)
                self.show_pai.card = nil
            end
            --if direct ~= 1 then
                self.show_pai:removeFromParent(true)
                self.show_pai = nil
            --end

        end

        if card then
            local startPosX,startPosY = nil
            for ii, cc in ipairs(self.hand_card_list[direct]) do
                if cc == card then
                    table.remove(self.hand_card_list[direct], ii)
                    -- if direct == 1 or not self.is_pmmj then

                    startPosX, startPosY = card:getPosition()

                    card:removeFromParent(true)
                    card = nil
                    -- end
                    break
                end
            end

            if direct == 1 or self.is_playback then
                self:sortHandCard(direct)
                self:placeHandCard(direct)
            end

            --if direct ~= 1 then
                local show_pai = self.show_pai
                local bigger_scale = 1
                if direct ~= 3 or direct ~= 1 then
                    bigger_scale = 1.25
                end
                local show_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_chupai_img.png")
                if not show_pai then
                    show_pai = self:getCardById(1, card_ids[1], "_stand")
                    show_pai:setPosition(self.open_card_pos_list[direct])
                    self.node:addChild(show_pai, 150)
                    show_pai:setName('ShowPai')
                    if self.is_pmmj or self.is_pmmjyellow then
                        show_pai_bg:setScale(0.8)
                        show_pai_bg:setAnchorPoint(0.05, 0.02)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-12,show_pai_bg:getPositionY()-10))
                    else
                        show_pai_bg:setScale(1.3)
                        show_pai_bg:setAnchorPoint(0.02, 0.03)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-17.5,show_pai_bg:getPositionY()-10))
                    end
                else
                    if self.is_pmmj or self.is_pmmjyellow then
                        show_pai_bg:setScale(0.8)
                        show_pai_bg:setAnchorPoint(0.05, 0.02)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-12,show_pai_bg:getPositionY()-10))
                    else
                        show_pai_bg:setScale(1.3)
                        show_pai_bg:setAnchorPoint(0.06, 0.08)
                        show_pai_bg:setPosition(cc.p(show_pai_bg:getPositionX()-17.5,show_pai_bg:getPositionY()-10))
                    end
                end
                if card_value ~= 0 then
                    show_pai:addChild(show_pai_bg,-1)
                end

                local nMaxScale = math.max(show_pai:getScaleX(),show_pai:getScaleY())
                if not card then
                    if 0 ~= card_value then
                        show_pai_bg:setOpacity(0)
                        show_pai_bg:runAction(cc.FadeTo:create(0.2, 255))
                    end

                    show_pai:runAction(cc.Spawn:create(cc.ScaleTo:create(0.07, nMaxScale*bigger_scale), cc.MoveTo:create(0.07, self.open_card_pos_list[direct])))

                else
                    show_pai:setScale(nMaxScale*bigger_scale)
                    show_pai:setVisible(false)
                    card:runAction(cc.Sequence:create(cc.MoveTo:create(0.07,  self.open_card_pos_list[direct]), cc.CallFunc:create(function()
                        show_pai:setVisible(true)
                        card:removeFromParent(true)
                        card = nil
                    end)))
                end

                self.show_pai_out = show_pai
            --[[else
                if self.show_pai then
                    self.show_pai:removeFromParent(true)
                    self.show_pai = nil
                end
                if card then
                    card:removeFromParent(true)
                    card = nil
                end
            end]]

            local pai = self:getOpenCardById(direct, card_ids[1], true)
            pai.card_id = card_ids[1]


            local nRow = math.floor((#self.out_card_list[direct]) / (self.out_row_nums))
            local nCow = (#self.out_card_list[direct]) % (self.out_row_nums)

            self.node:addChild(pai)
            pai:setLocalZOrder(self:getOutCardZOrder(direct,nRow,nCow))

            local pos = self:getOutCardPosition(direct,nRow,nCow)
            self.pos = pos
            local poshand = cc.p(self.hand_card_pos_list[direct].init_pos.x, self.hand_card_pos_list[direct].init_pos.y)
            if startPosX and startPosY then
                poshand = cc.p(startPosX,startPosY)
            end
            if direct == 1 and self.selected_card_posx and self.selected_card_posy then
                pai:setPosition(self.selected_card_posx,self.selected_card_posy)
            else
                pai:setPosition(poshand)
            end
            pai:runAction(cc.MoveTo:create(0.1,self.pos))


            self.out_card_list[direct][#self.out_card_list[direct]+1] = pai

            self:showCursor()

            self:showAction()

            AudioManager:playDWCSound("sound/mj/card_send_effect.mp3")

            print("open  ", pai.card_id)
        end
    else
        if (opt_type >=1 and opt_type < 4) or (opt_type >= 10) then
            self:openMultCard(direct, card_ids, opt_type, lnLastUser)
        end
    end

    self:playOpenCardAnimation(direct,opt_type)

    self:playOpenCardSound(direct,opt_type)
end

function XAMJScene:setImgGuoHuIndexVisible(lnIndex, bVisible)
    local imgGuoHu = self:getChildByName('imgGuoHu')
    if not imgGuoHu then
        --imgGuoHu = cc.Label:createWithTTF("过胡", 'ui/zhunyuan.ttf', 50)
        imgGuoHu = cc.Sprite:create("ui/qj_mj/guohu1-fs8.png")
        imgGuoHu:setName('imgGuoHu')
        imgGuoHu:setPosition(g_visible_size.width/2, 155)
        --imgGuoHu:setColor(cc.c3b(255,255,0))
        self:addChild(imgGuoHu,30)
    end

    imgGuoHu:setVisible(bVisible)
end

function XAMJScene:resetOperPanel(oper, haidi_ting, last_card_id, msgid, kg_cards)
    logUp('XAMJScene:resetOperPanel')
    logUp('操作ID ')
    logUp(oper)

    logUp('MsgID')
    logUp(msgid)
    logUp('kg_cards')
    logUp(kg_cards)
    --kg_cards = {}

    local OPER_EMPTY     = 0  -- 无操作
    local OPER_OUT_CARD  = 1  -- 出牌
    local OPER_PENG      = 2  -- 碰
    local OPER_GANG      = 3  -- 杠
    local OPER_CHI_CARD  = 4  -- 吃牌
    local OPER_CHI_HU    = 5  -- 吃胡
    local OPER_HU        = 6  -- 胡牌
    local OPER_BBHU      = 7  -- 板板胡
    local OPER_HAIDI     = 8  -- 海底
    local OPER_KAIGANG   = 9  -- 开杠
    local OPER_PENG_TING = 10 -- 碰听
    local OPER_CHI_TING  = 11 -- 吃听
    local OPER_TING      = 12 -- 听

    self.oper_panel:setVisible(true)
    self.oper_panel.no_reply = true
    self.only_bu = true
    local oper_list = {chi=0,peng=0,gang=0,bu=0,hu=0,hd=0,guo=1}
    local has_oper = nil
    local max_oper = 0
    local is_chupai = nil
    for __, v in ipairs(oper) do
        if v == 1 then
            is_chupai = true
        end
        if v > max_oper then
            max_oper = v
        end
        if v >= 5 and v <= 7 then
            oper_list.hu = 1
            self.hu_type = v
            has_oper = true
            self.hasHu = true
        elseif v == 101 then
            oper_list.hu = 1
            self.hu_type = 101
            oper_list.guo = 0
            has_oper = true
        elseif v == OPER_PENG then
            oper_list.peng = 1
            has_oper = true
        elseif v == OPER_CHI_CARD then
            oper_list.chi = 1
            has_oper = true
        elseif v == OPER_GANG then
            oper_list.gang = 1
            has_oper = true
        elseif v == OPER_OUT_CARD then
            self.can_opt = true
        elseif v == 100 then
            oper_list.hd = 1
            has_oper = true
        elseif v == 9 then
            oper_list.gang = 1
            has_oper = true
        elseif v == OPER_TING then
            oper_list.ting = 1
            has_oper = true
        end

        if v ~= 1 or v ~= 3 then
            self.only_bu = nil
        end
    end
    local oper_btn_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-guo"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-hu"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-peng"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-chi"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-gang"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.oper_panel, "btn-ting"), "ccui.Button"),
    }

    local oper_pai = nil
    local pre_is_wang = nil
    if self.pre_out_direct and self.out_card_list[self.pre_out_direct] then
        local card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
        if card then
            pre_is_wang = (card.card_id==self.wang_cards[2]) or (card.card_id==self.wang_cards[3])
        end
    end
    local no_wang_count = self:checkNoWangCard()

    local ui_prefix = ""
    if self.is_pmmj then
        ui_prefix = "pm"
    end

   -- if oper_list.hd==1 then
   --     if haidi_ting then
   --         oper_btn_list[1].opt_type = "yao"
   --         oper_btn_list[1]:loadTextureNormal("ui/Majiang/Room"..ui_prefix.."/majiang/yao.png")
   --         oper_btn_list[1]:setVisible(true)
   --         oper_btn_list[1]:setTouchEnabled(true)
   --         table.remove(oper_btn_list, 1)
   --     end
   --     self.oper_panel.no_reply = nil

   --     log(' oper_btn_list[1].opt_type = "yao" ')
   -- end
    if (self.action_msg or self.is_treatResume) and max_oper > 1 then
        if #self.hand_card_list[1] == 14 then
            self.oper_pai_id = self.hand_card_list[1][14].card_id
        else
            if last_card_id then
                self.oper_pai_id = last_card_id
            else
                self.oper_pai_id = self.last_out_card
            end
        end
        oper_pai = self:getCardById(1,self.oper_pai_id, "_stand")
        oper_pai:setPosition(cc.p(oper_pai:getPositionX()+90, oper_pai:getPositionY()+30))
        self.is_treatResume = false
    end

    if oper_list.guo==1 and has_oper then
        if oper_list.hu == 1 then
            oper_btn_list[1].opt_type = "guo_hu"

            log(' oper_btn_list[1].opt_type = "guo_hu" ')
        else
            oper_btn_list[1].opt_type = "guo"

            log(' oper_btn_list[1].opt_type = "guo" ')
        end
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_guo_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)


    end
    if oper_list.peng==1 and ((pre_is_wang and no_wang_count > 0) or (not pre_is_wang and no_wang_count > 2)) then
        oper_btn_list[1].opt_type = "peng"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_peng_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == 2 then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            if self.is_3dmj then
                oper_pai:setScale(0.6)
            end
            oper_pai:setPositionY(40)
            self.oper_pai_bg:addChild(oper_pai, 1)
        end
        table.remove(oper_btn_list, 1)

        log(' oper_btn_list[1].opt_type = "peng" ')
    end

    if oper_list.chi==1 then
        oper_btn_list[1].opt_type = "chi"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_chi_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)

        log(' oper_btn_list[1].opt_type = "chi" ')
    end

    if oper_list.gang==1 then
        if self.can_opt then
            kg_cards = self:GetGangPai()
        else
            kg_cards = {}
        end
        oper_btn_list[1].opt_type = kg_cards or {}
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_gang_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == 3 then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            local gang_pai = {}
            if #kg_cards == 0 then
                kg_cards[1] = self.oper_pai_id
            end
            for i,v in ipairs(kg_cards) do
                gang_pai[i] = self:getCardById(1,kg_cards[i], "_stand")
                gang_pai[i]:setPosition(cc.p(gang_pai[i]:getPositionX()+150-(i*60), gang_pai[i]:getPositionY()+30))
                if self.is_3dmj then
                    gang_pai[i]:setScale(0.6)
                end
                gang_pai[i]:setPositionY(40)
                self.oper_pai_bg:addChild(gang_pai[i], 1)
            end
        end
        table.remove(oper_btn_list, 1)

        log(' oper_list.gang==1 ')
        log(kg_cards)
    end

    if oper_list.hu==1 then
        oper_btn_list[1].opt_type = "hu"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_hu_btn.png")
        if #oper_btn_list >= 6 then
            oper_btn_list[1]:setScale(1.3)
        end
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == 6 or max_oper == 5 then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX()-30,self.oper_pai_bg:getPositionY()+80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            if self.is_3dmj then
                oper_pai:setScale(0.6)
            end
            oper_pai:setPositionY(40)
            self.oper_pai_bg:addChild(oper_pai, 1)
        end
        table.remove(oper_btn_list, 1)

        if self.can_opt and no_wang_count <= 0 then
            oper_list.guo = 0
            self.can_opt = nil
        end
            self:setImgGuoHuIndexVisible(1,false)
        log(' oper_btn_list[1].opt_type = "hu" ')
    end

    if oper_list.ting==1 then
        oper_btn_list[1].opt_type = 'ting'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_ting_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        self.btnTing = oper_btn_list[1]
        table.remove(oper_btn_list, 1)
    end

    local total = 0
    if #oper_btn_list >= 6 then
        self.oper_panel:setVisible(false)

        self.oper_panel.no_reply = nil

        self.only_bu = nil

        if self.can_opt then
            self.oper_panel.msgid = msgid
            if not self.hand_card_list[1] or #self.hand_card_list[1] ~= 14 then
                total = -1
                return
            end
        else
            self.oper_panel.msgid = nil
        end

        if self.can_opt and self.ting_status then
            self.can_opt = nil

            self:runAction(cc.Sequence:create(cc.DelayTime:create(self.TingAutoOutCard), cc.CallFunc:create(function()
                if last_card_id then
                    self:sendOutCards(last_card_id)
                    self:setImgGuoHuIndexVisible(1, false)
                else
                    local card = self.hand_card_list[1][#self.hand_card_list[1]]
                    if card then
                        self:sendOutCards(card.card_id)
                        self:setImgGuoHuIndexVisible(1, false)
                    end
                end
            end)))
        end
    else
        for __, v in ipairs(oper_btn_list) do
            v:setVisible(false)
            v:setTouchEnabled(false)
            v.opt_type = nil
        end
        self.oper_panel.msgid = msgid
    end

    total = self:caculateScore(total)

    if total ~= 0 then
        self:send_join_room_again()
    end
    if self.can_opt and self.ting_tip_layer and oper_list.hu ~= 1 and not self.ting_status then
        local hand_list = {}
        local group_list = {}
        local j = 1
        while j <= #self.hand_card_list[1] do
            local v = self.hand_card_list[1][j]
            if v then
                if v.sort == 0 then
                    hand_list[#hand_list+1] = v.card_id
                    j = j+1
                else
                    local list = {}
                    local k =0
                    while k < 3 do
                        list[#list+1] = self.hand_card_list[1][k+j].card_id
                        k = k+1
                    end
                    j = j+k
                    table.sort(list)
                    group_list[#group_list+1] = list
                end
            end
        end
        local out_list = {}
        for k=1, 4 do
            if self.hand_card_list[k] and #self.hand_card_list[k] > 0 then
                for __, v in ipairs(self.hand_card_list[k]) do
                    if v.card_id and v.card_id >=1 and v.card_id <= 81 then
                        out_list[#out_list+1] = v.card_id
                        if v.is_gang then
                            out_list[#out_list+1] = v.card_id
                        end
                    end
                end
            end
            if self.out_card_list[k] and #self.out_card_list[k] > 0 then
                for __, v in ipairs(self.out_card_list[k]) do
                    if v.card_id and v.card_id >=1 and v.card_id <= 81 then
                        out_list[#out_list+1] = v.card_id
                    end
                end
            end
        end

        --
        local left_cards = self.MJLogic.copyArray(MJBaseScene.CardNum)
        for i,v in ipairs(out_list) do
            left_cards[v] = left_cards[v] or 4
            left_cards[v] = left_cards[v]  - 1
        end

        self.ting_list = {}
        for i, v in ipairs(hand_list) do
            if not self.ting_list[v] then
                local hands = clone(hand_list)
                table.remove(hands, i)

                local hu_list = {}
                local ting_list = {}
                local ting_list = self.MJLogic.GetTingCards(hands, group_list, self.wang_cards[1], self.canHuQiDui, self.is258Jiang)
                if ting_list and #ting_list > 0 then
                    for i ,v in pairs(ting_list) do
                        hu_list[#hu_list+1] = {v,left_cards[v]}
                    end
                end
                if hu_list and #hu_list > 0 then
                    local wang = self.wang_cards[1]
                    if wang then
                        local bHasWang = false
                        for i , v in ipairs(hu_list) do
                            if wang == v[1] then
                                bHasWang = true
                                break
                            end
                        end
                        if not bHasWang then
                            table.insert(hu_list,1,{wang,left_cards[wang]})
                        end
                    end
                    self.ting_list[v] = hu_list
                end
            end
        end

        self:removeTingArrow()
        local card_size = self.hand_card_list[1][14]:getContentSize()
        for k, __ in pairs(self.ting_list) do
            for __, v in ipairs(self.hand_card_list[1]) do
                if  v.sort == 0 and v.card_id == k and not v.ting_ar then
                    local sp = cc.Sprite:create("ui/qj_mj/ting_arrow.png")
                    if self.is_pmmj or self.is_pmmjyellow then
                        sp:setScale(1.1)
                    else
                        sp:setScale(2)
                    end
                    sp:setAnchorPoint(0.5, 0)
                    sp:setPosition(card_size.width/2, card_size.height)
                    v:addChild(sp)
                    v.ting_ar = sp
                end
            end
        end
    end
end

function XAMJScene:initResultUI(rtn_msg)

    local node = tolua.cast(cc.CSLoader:createNode("ui/Jiesuan.csb"), "ccui.Widget")
    self:addChild(node, 100000, 10109)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    for play_index = 1, 4 do
        self.player_ui[play_index]:getChildByName("PJN"):setVisible(false)
        self.player_ui[play_index]:getChildByName("Zhang"):setVisible(false)
    end

    self:continueGame(node,ccui.Helper:seekWidgetByName(node, "btn-jxyx"),rtn_msg)

    self:initResultAnQuanMa(node,rtn_msg)
    self:initResultTime(node,rtn_msg)

    self:initResultRoomID(node,rtn_msg)

    self:initResultWangFa(node)

    local hu_type_name = {
                                [1] = "平胡",[2] = "七小对", [4] = "清一色",
                                [101] = "将258", [102] = "胡258"
                    }

    local index_list = {1,2,3,4}
    local diangangNum = {0,0,0,0}
    for i,v in ipairs(rtn_msg.players) do
        for ii=1,#v.groups do
            local count = 0
            for __,group in pairs(v.groups[ii]) do
                count = count + 1
                if count >= 5 then
                    if v.groups[ii]["5"] == 1 then
                        if v.groups[ii].last_user ~= v.index then
                            diangangNum[v.groups[ii].last_user] = diangangNum[v.groups[ii].last_user] + 1
                        end
                    end
                    break
                end
            end
        end
    end
    for i, v in ipairs(rtn_msg.players) do
        if diangangNum[i] > 0 then
            v.dianpaoshu = diangangNum[i]
        end
    end

    table.sort( rtn_msg.players, function(x,y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        local sortIndex = self:setResultIndex(play_index)
        index_list[sortIndex] = nil
        local play = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")

        local userData = PlayerData.getPlayerDataByClientID(play_index)
        if not userData then
            local errStr = self:mjUploadError('initResultUI',tostring(v.index),tostring(play_index))
            gt.uploadErr(errStr)
            log(errStr)
            local errStr = getPlayerDataDebugStr()
            gt.uploadErr(errStr)
            log(errStr)
        end
        local pTouXiang = tolua.cast(ccui.Helper:seekWidgetByName(play, "touxiang"), "ccui.ImageView")
        local head = userData and userData.head or ''
        pTouXiang:downloadImg(commonlib.wxHead(head), g_wxhead_addr)
        if self.xiapaozi_mode == false then
            ccui.Helper:seekWidgetByName(play, "paozifen"):setVisible(false)
        else
            ccui.Helper:seekWidgetByName(play, "paozifen"):setVisible(true)
            local paozi = userData and userData.paozi or ''
            ccui.Helper:seekWidgetByName(play, "num"):setString(paozi)
        end
        local name = userData and userData.name or ''
        if pcall(commonlib.GetMaxLenString, name, 14) then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setString(commonlib.GetMaxLenString(name, 14))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setString(name)
        end
        if v.index ~= rtn_msg.host_id then
            play:getChildByName("zhuang_icon"):setVisible(false)
        end

        local uid = userData and userData.uid or ''
        tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_3"), "ccui.Text"):setString('ID:'.. uid)

        if v.score > 0 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setString("+"..v.score)
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(0xff, 0xd6, 0x59))
        else
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setString(v.score)
            tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(0x61, 0x42, 0x28))
        end

        if userData and userData.score then
            userData.score = v.total_score or (userData.score+v.score)
        elseif userData then
            userData.score = v.total_score
        end

        local str = nil
        local dh_lbl = tolua.cast(ccui.Helper:seekWidgetByName(play, "dianpao"), "ccui.Text")
        --ccui.Helper:seekWidgetByName(play, "fanshu"):setVisible(false)
        if v.score <= 0 then
            ccui.Helper:seekWidgetByName(play, "shuying"):setVisible(false)
            ccui.Helper:seekWidgetByName(play, "fanshu"):setVisible(false)
        else
            play:loadTexture("ui/qj_end_one/dt_end_one_ying_item_bg.png")
        end

        if v.is_zimo == 1 or v.is_jiepao == 1 then
            dh_lbl:setColor(cc.c3b(238,238,12))
            tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_2"), "ccui.Text"):setColor(cc.c3b(238,238,12))
            tolua.cast(ccui.Helper:seekWidgetByName(play, "Text_3"), "ccui.Text"):setColor(cc.c3b(238,238,12))
            -- tolua.cast(ccui.Helper:seekWidgetByName(play, "lab-shuyingshu"), "ccui.Text"):setColor(cc.c3b(238,238,12))
        end

        if play_index == 1 then
            if v.is_zimo == 1 or v.is_jiepao == 1 then
                AudioManager:playDWCSound("sound/mj/win.mp3")
            else
                AudioManager:playDWCSound("sound/mj/lose.mp3")
            end
        end
        if v.dianpaoshu then
            str = v.dianpaoshu.."点杠"
        end
        local mingNum = 0
        local anNum = 0

        for ii=1,#v.groups do
            local count = 0
            for __,group in pairs(v.groups[ii]) do
                count = count + 1
                if count >= 5 then
                    if v.groups[ii]["5"] == 1 or v.groups[ii]["5"] == 3 then
                        mingNum = mingNum + 1
                    elseif v.groups[ii]["5"] == 2 then
                        anNum = anNum + 1
                    end
                    break
                end
            end
        end

        if mingNum ~= 0 then
            str = str or ""
            str = str.."  "..mingNum.."明杠"
        end
        if anNum ~= 0 then
            str = str or ""
            str = str.."  "..anNum.."暗杠"
        end

        if v.hu_types and #v.hu_types > 0 then
            str = str or ""
            for __, ht in ipairs(v.hu_types) do
                if ht > 4 and ht < 18 then
                    str = str.."  "..hu_type_name[ht]
                end
            end
        end

        if v.hu_types and #v.hu_types > 0 then
            str = str or ""
            for __, ht in ipairs(v.hu_types) do
                if ht <= 4 or ht >= 18 then
                    str = str.."  "..hu_type_name[ht]
                end
            end
        end

        if v.is_zimo == 1 then
            str = str or ""
            str = str.."  自摸"
        elseif v.is_dianpao == 1 then
            str = str or ""
            str = str.."  点炮"
        elseif v.is_jiepao == 1 then
            str = str or ""
            str = str.."  吃胡"
        end
        if v.is_qianggang == 1 then
            str = str or ""
            str = str.."  抢杠"
        end

        if v.index == rtn_msg.host_id then
            if v.score ~= 0 then
                str = str or ""
                str = str.."  庄"
            end
        end

        if str then
            dh_lbl:setString(str)
        else
            dh_lbl:setString("")
        end

        if v.fan and v.fan ~= 0 and v.fan ~= 1 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "fanshu"), "ccui.Text"):setString('X'..v.fan..'番')
        else
            ccui.Helper:seekWidgetByName(play, "fanshu"):setVisible(false)
        end

        local pos = commonlib.worldPos(ccui.Helper:seekWidgetByName(play, "shuying"))
        pos.x = pos.x + 190
        pos.y = pos.y - 25
        local cards = v.groups
        local hand_z = #cards+1
        if #v.hands > 14-(#v.groups*3) then
            v.hands[14-(#v.groups*3)] = v.hands[#v.hands]
            v.hands[15-(#v.groups*3)]= nil
        end
        cards[hand_z] = v.hands
        local pao_z = nil
        if v.hu_cards then
            cards[#cards+1] = v.hu_cards
            pao_z = #cards
        end
        local niao_z = nil
        if v.niao_cards then
            cards[#cards+1] = v.niao_cards
            niao_z = #cards
        end
        local atch_scale = 0.7
        if g_visible_size.width/g_visible_size.height >= 2 then
            atch_scale = 1136/g_visible_size.width
        end
        local scale = 0.55*atch_scale
        if self.is_pmmj or self.is_pmmjyellow then
            scale = 0.83*atch_scale
        end
        for i, v in ipairs(cards or {}) do
            local cards_hash = {}
            for ii ,vv in pairs(v) do
                if ii ~= 'last_user' then
                    cards_hash[tonumber(ii)] = vv
                end
                -- print('1111111111111 ' .. i .. ' ' .. cards_hash[i])
            end
            v = cards_hash
            if v and #v > 0 then
                local bu_gang = nil
                if #v == 5 and i ~= niao_z and i ~= hand_z then
                    bu_gang = v[5]
                    v[5]=nil
                    v[4]=nil
                end
                for ii, vv in ipairs(cards_hash) do
                    if vv ~= 0 then
                        local pai = nil
                        local pscale = nil
                        local add_card = nil
                        pai = self:getCardById(1, vv, "_stand",i< hand_z)
                        pai:setScale(scale*self.scard_size_scale[1]*self.single_scale)
                        if not bu_gang or bu_gang ~= 2 then
                            add_card = self:getCardById(1, vv, "_stand", true)
                            add_card:setScale(1)
                        else
                            if self.is_pmmj then
                                add_card = cc.Sprite:createWithSpriteFrameName('ee_mj_b_up.png')
                            elseif self.is_pmmjyellow then
                                add_card = cc.Sprite:createWithSpriteFrameName('e_mj_b_up.png')
                            else
                                add_card = cc.Sprite:create(self.res3DPath.."/back1.png")
                            end
                        end
                        if bu_gang and ii==2 then
                            add_card:setScaleX(pai:getContentSize().width/add_card:getContentSize().width)
                            add_card:setScaleY(pai:getContentSize().height/add_card:getContentSize().height)
                            if self.is_pmmj or self.is_pmmjyellow then
                                add_card:setAnchorPoint(0, -0.17)
                            else
                                add_card:setAnchorPoint(0, -0.25)
                            end
                            pai.sp_order = 2
                            pai:addChild(add_card)
                        elseif pao_z == i then
                            local wang = cc.Sprite:create("ui/qj_mj/hu.png")
                            if self.is_pmmj or self.is_pmmjyellow then
                                wang:setScale(0.8)
                                wang:setAnchorPoint(-0.2, -1.8)
                            else
                                wang:setScale(1.3)
                                wang:setAnchorPoint(-0.25, -1.8)
                            end
                            pai:addChild(wang)
                        elseif niao_z == i and ii == 1 then
                            local wang = cc.Sprite:create("poker/mj/niao.png")
                            if self.is_pmmj then
                                wang:setScale(0.85)
                                wang:setAnchorPoint(-0.1, -2.1)
                            else
                                wang:setScale(1.25)
                                wang:setAnchorPoint(-0.25, -2.3)
                            end
                            pai:addChild(wang)
                        end
                        pai:setPosition(cc.p(pos.x, pos.y))
                        node:addChild(pai, pai.sp_order or 1)
                        if self.is_3dmj then
                            pos.x = pos.x + self.hand_card_pos_list[1].space_result.x*self.scard_space_scale[1]*0.7*self.single_scale*atch_scale
                        else
                            pos.x = pos.x + self.hand_card_pos_list[1].space_result.x*self.scard_space_scale[1]*0.82*self.single_scale*atch_scale
                        end
                    end
                end
                if self.is_3dmj then
                    pos.x = pos.x+self.hand_card_pos_list[1].space_result.x*self.z_p_s[1]*0.7*self.single_scale*atch_scale
                else
                    pos.x = pos.x+self.hand_card_pos_list[1].space_result.x*self.z_p_s[1]*0.85*self.single_scale*atch_scale
                end
            end
        end
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node,"play"..v):setVisible(false)
        end
    end

    self:setShareBtn(rtn_msg,node)
end


function XAMJScene:playHuAni(rtn_msg)
    -- dump(rtn_msg)
    local old_ui = self:getChildByTag(1369)
    if old_ui then
        old_ui:removeFromParent(true)
    end

    -- local play_sound = true
    local hu_Ani = {}
    for __, player in ipairs(rtn_msg.players) do
        local hu_type = nil

        if player.hu_types and #player.hu_types >0 then
            table.sort(player.hu_types)
            for i , v in pairs(player.hu_types) do
                if not hu_type or v > hu_type then
                    if v == 101 or v == 102 then

                    else
                        hu_type = v
                    end
                end
            end
            for i=#player.hu_types,1,-1 do
                if player.hu_types[i] == 4 then
                    hu_Ani[1] = 7
                    for __,v in pairs(player.hu_types) do
                        if v == 2 or v == 3 or v == 5 then
                            hu_Ani[2] = v
                        end
                    end
                end
            end
        end
        if hu_type == nil then
            hu_type = self.MJLogic.HU_NORMAL
        end
        if player.is_zimo == 1 then
            -- if not hu_type or hu_type == self.MJLogic.HU_NORMAL then
                hu_type = 30
            -- end
        end

        local hu_img={}
        hu_img[self.MJLogic.HU_NORMAL] = 5
        hu_img[self.MJLogic.HU_QIXIAODUI] = 6
        hu_img[self.MJLogic.HU_YITIAOLONG] = 23
        hu_img[self.MJLogic.HU_QINGYISE] = 7
        hu_img[self.MJLogic.HU_HAOQIXIAODUI] = 11
        hu_img[self.MJLogic.HU_SHISANYAO] = 22
        hu_img[30] = 30
        hu_type = hu_img[hu_type]
        hu_Ani[2] = hu_img[hu_Ani[2]]

        local function playsound(index)
            local prefix = self:getSoundPrefix(index)
            if hu_type == 30 then
                AudioManager:playDWCSound("sound/"..prefix.."/zimo.mp3")
            elseif hu_type == 5 then
                AudioManager:playDWCSound("sound/"..prefix.."/hu.mp3")
            else
                AudioManager:playDWCSound("sound/mj/act_hu.mp3")
            end
            play_sound = nil
        end

        local index = self:indexTrans(player.index)
        if hu_type == 30 and index == 1 then
            -- 自摸
            self:playzimo(player.hu_cards[1])
            self.wait_over = 2

            playsound(index)
            break
        elseif hu_type ~= 30 and rtn_msg.last_user then
            print(' 点炮玩家S ' .. rtn_msg.last_user)
            local last_user = self:indexTrans(rtn_msg.last_user)
            print(' 点炮玩家C ' .. last_user)
            local card = self.out_card_list[last_user][#self.out_card_list[last_user]]
            print(' 点炮 ')
            local posX,posY = card:getPosition()
            local pos = cc.p(posX,posY)
            -- pos = cc.p(50,50)
            -- 点炮
            self:playdianpao(pos)
            self.wait_over = 2

            -- playsound(index)
            -- break
        end

        if hu_type and player.hu_cards and #player.hu_cards > 0 then
            -- local index = self:indexTrans(player.index)
            -- local old_card_list = {}
            -- local is_zimo = nil
            -- for ii, card in ipairs(self.hand_card_list[index]) do
            --     if card.sort == 0 or card.sort == -1 then
            --         if not player.hands[#old_card_list+1] then
            --             is_zimo = true
            --             break
            --         end
            --         old_card_list[#old_card_list+1] = card

            --         local pai = self:getCardById(index, player.hands[#old_card_list], "_stand")
            --         pai.sort = -2
            --         pai.card_id = player.hands[#old_card_list]
            --         if index == 4 then
            --             pai.ssort = #old_card_list
            --             self.node:addChild(pai, 15-pai.ssort)
            --         else
            --             pai.ssort = #old_card_list
            --             self.node:addChild(pai, 1)
            --         end
            --         pai:setVisible(false)
            --         self.hand_card_list[index][ii] = pai
            --     end
            -- end
            local sp = cc.Sprite:create("ui/qj_mj/hn"..hu_type..".png")
            sp = sp or cc.Sprite:create("ui/qj_mj/hn5.png")
            local sp_size = sp:getContentSize()
            local sp_scale = 1
            if index ~= 1 then
                sp_scale = 0.8
                sp_size.width = sp_size.width*sp_scale
                sp_size.height = sp_size.height*sp_scale
            end
            -- if player.hu_cards[1] ~= 0 then
            --     local pai = self:getCardById(index, player.hu_cards[1], "_stand")
            --     local scale = pai:getScale()
            --     if index == 1 then
            --         pai:setPosition(cc.p(self.open_card_pos_list[index].x, self.open_card_pos_list[index].y+sp_size.height/4))
            --     elseif index == 2 then
            --         pai:setPosition(cc.p(self.open_card_pos_list[index].x-sp_size.width/4, self.open_card_pos_list[index].y))
            --     elseif index == 3 then
            --         pai:setPosition(cc.p(self.open_card_pos_list[index].x, self.open_card_pos_list[index].y-sp_size.height/4))
            --     else
            --         pai:setPosition(cc.p(self.open_card_pos_list[index].x+sp_size.width/4, self.open_card_pos_list[index].y))
            -- end
            -- self.node:addChild(pai, 10000)
            --     if self.is_pmmj or self.is_pmmjyellow then
            --         if index == 1 then
            --             pai:setScale(1.5)
            --         else
            --             pai:setScale(1.8)
            --         end
            --     else
            --         pai:setScale(1.25)
            --     end
            --     pai:runAction(cc.Sequence:create(cc.FadeIn:create(0.3), cc.DelayTime:create(1.5), cc.CallFunc:create(function()
            --         for __, vv in ipairs(old_card_list) do
            --             if vv then
            --                 vv:removeFromParent(true)
            --             end
            --         end
            --         old_card_list = {}

            --         for ii, card in ipairs(self.hand_card_list[index]) do
            --             if card.sort == -2 then
            --                 card:setVisible(true)
            --             end
            --         end

            --         self:placeHandCard(index)

            --         AudioManager:playDWCSound("sound/mj/act_lipai.mp3")

            --         if not is_zimo then
            --             local pos = cc.p(self.hand_card_list[index][#self.hand_card_list[index]]:getPosition())
            --             pos.x = pos.x + self.hand_card_pos_list[index].space.x*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.x*self.z_p_s[index]
            --             pos.y = pos.y + self.hand_card_pos_list[index].space.y*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.y*self.z_p_s[index]

            --             self.hand_card_list[index][#self.hand_card_list[index]+1] = pai
            --             pai:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.Spawn:create(cc.MoveTo:create(0.2,pos), cc.ScaleTo:create(0.2, scale))))
            --         else
            --             local pos = cc.p(self.hand_card_list[index][#self.hand_card_list[index]-1]:getPosition())
            --             pos.x = pos.x + self.hand_card_pos_list[index].space.x*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.x*self.z_p_s[index]
            --             pos.y = pos.y + self.hand_card_pos_list[index].space.y*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.y*self.z_p_s[index]

            --             self.hand_card_list[index][#self.hand_card_list[index]]:removeFromParent(true)
            --             self.hand_card_list[index][#self.hand_card_list[index]] = pai
            --             pai:setPosition(pos)
            --             pai:setScale(scale)
            --         end
            --     end)))

            -- else

            --     for __, vv in ipairs(old_card_list) do
            --         if vv then
            --             vv:removeFromParent(true)
            --         end
            --     end
            --     old_card_list = {}

            --     for ii, card in ipairs(self.hand_card_list[index]) do
            --         if card.sort == -2 then
            --             card:setVisible(true)
            --         end
            --     end

            --     self:placeHandCard(index)

            --     AudioManager:playDWCSound("sound/mj/act_lipai.mp3")

            -- end

            AudioManager:playDWCSound("sound/mj/mj_op.mp3")
            if hu_Ani and #hu_Ani == 2 then
                local ani1 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[1]..".png")
                local sp_size = ani1:getContentSize()
                local sp_scale = 1
                if index ~= 1 then
                    sp_scale = 0.8
                    sp_size.width = sp_size.width*sp_scale
                    sp_size.height = sp_size.height*sp_scale
                end
                local hu_pos = cc.p(self.open_card_pos_list[index].x, self.open_card_pos_list[index].y)
                ani1:setPosition(hu_pos)
                ani1:setScale(3.5)
                self:addChild(ani1, 10000)
                ani1:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)),
                    cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(0.5),
                    cc.CallFunc:create(function()
                        ani1:removeFromParent(true)
                    end),
                    cc.CallFunc:create(function()
                        local ani2 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[2]..".png")
                        ani2:setPosition(hu_pos)
                        ani2:setScale(3.5)
                        self:addChild(ani2,10000)
                        ani2:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)),
                            cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(1),
                        cc.RemoveSelf:create()))
                    end)
                    ))
            else
                if hu_type then
                    local hu_pos = cc.p(self.open_card_pos_list[index].x, self.open_card_pos_list[index].y)
                    sp:setPosition(hu_pos)
                    sp:setScale(3.5)
                    self:addChild(sp, 10000)
                    sp:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)), cc.CallFunc:create(function()
                        local circle = cc.Sprite:create("ui/qj_mj/room/ani_special_circle.png")
                        circle:setPosition(hu_pos)
                        circle:setAnchorPoint(0.5, 0.55)
                        circle:setScale(0)
                        circle:setOpacity(0)
                        self:addChild(circle, 9999)
                        circle:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeIn:create(0.15), cc.ScaleTo:create(0.15, 1.3)),
                            cc.Spawn:create(cc.FadeTo:create(0.1, 127), cc.ScaleTo:create(0.1, 1.25)), cc.DelayTime:create(0.3), cc.RemoveSelf:create()))
                    end),cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(1.6), cc.CallFunc:create(function()
                        sp:removeFromParent(true)
                    end)))
                end
            end
            playsound(index)
            self.wait_over = 2
            break
        end
    end

end


function XAMJScene:checkIpWarn(is_click_see)
    if self.is_playback then return end

    self:runAction(
        cc.CallFunc:create(
            function()
                -- GPS地址
                local tips = cc.Director:getInstance():getRunningScene():getChildByTag(85001)
                if tips then
                    tips:removeFromParent(true)
                end

                -- 统计人数
                local count = RoomInfo.getCurPeopleNum()

                -- 人数未满
                local people_num = self.people_num or 4
                if count < people_num then
                    if is_click_see then
                        commonlib.showLocalTip("房间满人可查看")
                    end
                    return
                end

                log('people_num ' .. tostring(people_num) .. ' is_click_see ' .. tostring(is_click_see) .. ' self.xiapaozi_mode ' .. tostring(self.xiapaozi_mode))
                if (people_num == 2 or people_num == 3 or people_num == 4)  and not is_click_see then
                    if self.xiapaozi_mode == false then
                        self:sendReady()
                    else
                        self.jiesanroom:setVisible(false)
                        self:disapperClubInvite(true)
                        if not self.hasXiaPaoZi then
                            self.xiapaozi_panel:setVisible(true)
                            self.xiapaozi_panel:setEnabled(true)
                        end
                        commonlib.showShareBtn(self.share_list)
                    end
                    return
                end

                self:disapperClubInvite(true)

                -- GPS
                local GpsMap = require('scene.GpsMap')
                GpsMap.mjShowMap(self,people_num,is_click_see)
            end
        )
    )
end


function XAMJScene:addCardShadow(bIngore14)
	bIngore14 = false
    for i , card in pairs(self.hand_card_list[1]) do
        local card_shadow = card:getChildByName('card_shadow')
        if not card_shadow and card.sort == 0 and (i ~= 14 or bIngore14) then
            card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
            card_shadow:setAnchorPoint(0.05, 0.05)
            card_shadow:setName('card_shadow')
            if self.is_pmmj or self.is_pmmjyellow then
                card_shadow:setAnchorPoint(0, 0)
                local iCardSize = card:getContentSize()
                local iCardShadowSize = card_shadow:getContentSize()
                card_shadow:setScaleX(iCardSize.width/iCardShadowSize.width)
                card_shadow:setScaleY(iCardSize.height/iCardShadowSize.height)
            end
            self.hand_card_list[1][i]:addChild(card_shadow)
        end
    end
end

function XAMJScene:onRcvMjDoPassHu(rtn_msg)
    if rtn_msg.auto == true then
        self:setImgGuoHuIndexVisible(1,true)
        self.before_index = rtn_msg.index
    end
end

function XAMJScene:onRcvReady(rtn_msg)
    if rtn_msg.isXiaPaoZi then
        self:setXiaPaoZi()
        self.is_game_start = true
        return
    end
     -- 游戏准备
    local server_index = rtn_msg.index
    if not server_index then
        return
    end
    local index = PlayerData.getPlayerClientIDByServerID(server_index)
    if not index then
        return
    end
    local userData = PlayerData.getPlayerDataByServerID(server_index)
    if not userData then
        return
    end
    userData.score = rtn_msg.score

    local v = rtn_msg
    if self.player_ui[index] then
        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
        --设置炮子分
        userData.paozi = v.paozi

        -- 设置分数
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index],"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(v.score+1000))
        if not v.piaoniao or v.piaoniao == 0 then
            self.player_ui[index]:getChildByName("PJN"):setVisible(false)
        else
            self.player_ui[index]:getChildByName("PJN"):setVisible(true)
            tolua.cast(self.player_ui[index]:getChildByName("PJN"), "ccui.ImageView"):loadTexture("ui/qj_mj/"..v.piaoniao..".png")
        end
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function XAMJScene:onRcvMjOutCard(rtn_msg)
    local open_card_index = self:indexTrans(rtn_msg.index)
    local bForceRunServer = false
    if open_card_index == 1 and 14 == #self.hand_card_list[open_card_index] then
        bForceRunServer = true
    end
    if not bForceRunServer then
        if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD and open_card_index == 1 and not self.out_from_client and not self.is_playback then
            self:clientOutCardRollBack(rtn_msg)
            return
        end
    end
    self:showWatcher(open_card_index)
    if rtn_msg.index >=1 and rtn_msg.index <= 4 then
        if rtn_msg.cards then
            self.last_out_card = rtn_msg.cards[1]
        end
        local open_card_index = self:indexTrans(rtn_msg.index)
        if not rtn_msg.errno or rtn_msg.errno == 0 then
            self.oper_panel:setVisible(false)
            self.chi_panel:setVisible(false)
            local old_ui = self:getChildByTag(1369)
            if old_ui then
                old_ui:removeFromParent(true)
            end

            self.can_opt = nil
            self.oper_panel.no_reply = nil
        end
        if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD then
            if rtn_msg.errno and rtn_msg.errno ~= 0 then
                if open_card_index == 1 then
                    self.can_opt = true
                     if self.show_pai then
                        if self.show_pai.card then
                            self.show_pai.card:setVisible(true)
                            self.show_pai.card = nil
                        end
                        self.show_pai:removeFromParent(true)
                        self.show_pai = nil
                    end
                    self:placeHandCard(open_card_index)
                    if rtn_msg.errno == 1006 then
                        commonlib.showLocalTip("不能出牌，等待起手胡")
                    elseif rtn_msg.errno == 1007 then
                        commonlib.showLocalTip("王不能打出")
                    elseif rtn_msg.errno == 1012 then
                        commonlib.showLocalTip("不能出牌，等待玩家选择胡牌")
                    end
                end
            else
                if self.oper_pai_bg then
                    self.oper_pai_bg:removeFromParent(true)
                    self.oper_pai_bg = nil
                end
                log('S2C_MJ_OUT_CARD')
                if self.oper_pai_id then
                    self.oper_pai_id = 0
                end
                self.pre_out_direct = open_card_index
                self:openCard(open_card_index, rtn_msg.cards, 0)
                self:playCardSound(rtn_msg.cards[1], open_card_index)
            end
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_CHI_CARD then
            local groups = rtn_msg.group or rtn_msg.cards
            for __, v in ipairs(groups) do
                if v ~= rtn_msg.cards[1] and v ~= rtn_msg.cards[2] then
                    rtn_msg.cards[3]= v
                    break
                end
            end
            log('S2C_MJ_CHI_CARD')
            self:openCard(open_card_index, rtn_msg.cards, 1)
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_PENG then
            self:removeShowPai()
            local last_card_index = rtn_msg.last_user and self:indexTrans(rtn_msg.last_user) or 0
            self:openCard(open_card_index, rtn_msg.cards, 2, nil, last_card_index)
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_GANG then
            log('S2C_MJ_GANG')
            local last_card_index = rtn_msg.last_user and self:indexTrans(rtn_msg.last_user) or 0
            if rtn_msg.typ ~= 1 then
                rtn_msg.cards[4] = rtn_msg.cards[1]
            end
            if rtn_msg.typ == 3 or rtn_msg.typ == 1 then
                self:openCard(open_card_index, rtn_msg.cards, 11, nil, last_card_index)
            else
                self:openCard(open_card_index, rtn_msg.cards, 10, nil, last_card_index)
            end
        elseif rtn_msg.cmd == NetCmd.S2C_MJ_KAIGANG then
            log('S2C_MJ_KAIGANG')

        end
    end
end

function XAMJScene:onRcvLeaveRoom(rtn_msg)
    self:setClubInvite()
    if self.xiapaozi_panel then
        self.xiapaozi_panel:setVisible(false)
    end
    self.dengdai:setVisible(false)
    for __,v in ipairs(self.share_list) do
        v:setVisible(true)
        v:setTouchEnabled(true)
    end
    self.jiesanroom:setVisible(true)
    local index = self:indexTrans(rtn_msg.index)
    if index ~= 1 then
        if self.player_ui[index] then
            commonlib.lixian(self.player_ui[index])
            self.player_ui[index]:setVisible(false)
            -- self.player_ui[index].coin = nil
            -- self.player_ui[index].user = nil
            local ipui = self:getChildByTag(81000+index)
            if ipui then
                ipui:removeFromParent(true)
            end
            self:checkIpWarn()
        end

        commonlib.interQuickStart(self)
    else
        self:unregisterEventListener()
        AudioManager:stopPubBgMusic()
        local scene = require("scene.MainScene")
        local gameScene = scene.create({operType = rtn_msg.operType})
        if cc.Director:getInstance():getRunningScene() then
            cc.Director:getInstance():replaceScene(gameScene)
        else
            cc.Director:getInstance():runWithScene(gameScene)
        end
    end
end

function XAMJScene:GetGangPai()
    local ltHandCard = {}
    for i, v in pairs(self.hand_card_list[1]) do
        ltHandCard[#ltHandCard+1] = v.card_id
    end
    return self.MJLogic.GetGangPai(ltHandCard)
end


function XAMJScene:continueGame(node,jxyx,rtn_msg)
    jxyx:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            print("open continue")
            node:removeFromParent(true)

            if self.niao_node then
                self.niao_node:removeFromParent(true)
                self.niao_node = nil
            end

            for play_index = 1, 4 do
                self.player_ui[play_index]:setPosition(cc.p(self.wenhao_list[play_index]:getPosition()))
            end

            self:stopCountdownWaitOverTime()

            self:stopSouthAction()

            self:removeAllTingTag()

            self.oper_panel:setVisible(false)

            for i, v in ipairs(self.wang_card_list or {}) do
                if v then
                    v:removeFromParent(true)
                end
            end
            self.wang_card_list = {}

            for i, v in ipairs(self.hand_card_list) do
                for __, vv in ipairs(v) do
                    if vv then
                        vv:removeFromParent(true)
                    end
                end
                self.hand_card_list[i] = {}
            end

            for i, v in ipairs(self.out_card_list) do
                for __, vv in ipairs(v) do
                    vv:removeFromParent(true)
                end
                self.out_card_list[i] = {}
            end

            self:removeShowPai()

            if self.is_pmmj or self.is_pmmjyellow then
                self.left_lbl:setString("-")
            else
                self.left_lbl:setVisible(false)
            end

            self.ting_status = nil
            self.oper_panel.time_out_flag = nil
            self.oper_panel.no_reply = nil
            self.can_opt = nil
            self.action_msg = nil
            self.draw_card_msg = nil

            self.pre_out_direct = nil
            self:showCursor()

            for index, v in ipairs(self.player_ui) do
                local userData = PlayerData.getPlayerDataByClientID(index)
                if userData and userData.score then
                    tolua.cast(ccui.Helper:seekWidgetByName(v,"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(userData.score+1000))
                end
                v:getChildByName("paozifen"):getChildByName("num"):setString("0")
                v:getChildByName("Zhang"):setVisible(false)
            end

            if not self.is_playback then
                if not rtn_msg.results then
                    if self.total_ju > 100 then
                        self:setLastJu(self.total_ju, rtn_msg.cur_quan)
                    else
                        self:setLastJu(self.total_ju, rtn_msg.cur_ju)
                    end
                    if self.xiapaozi_mode == false then
                        self:sendReady()
                    else
                         self.jiesanroom:setVisible(false)
                         self.xiapaozi_panel:setVisible(true)
                         self.xiapaozi_panel:setEnabled(true)
                         commonlib.showShareBtn(self.share_list)
                    end
                    if g_channel_id == 800002 then
                        AudioManager:playDWCBgMusic("sound/bgGame.mp3")
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, rtn_msg.log_ju_id, rtn_msg.gmId)
                end
            else
                if not rtn_msg.results then
                    self:unregisterEventListener()
                    AudioManager:stopPubBgMusic()
                    local scene = require("scene.MainScene")
                    local gameScene = scene.create()
                    if cc.Director:getInstance():getRunningScene() then
                        cc.Director:getInstance():replaceScene(gameScene)
                    else
                        cc.Director:getInstance():runWithScene(gameScene)
                    end
                else
                    self:initVIPResultUI(rtn_msg.results, rtn_msg.jiesan_detail, rtn_msg.club_name, gt.playback_log_ju_id, rtn_msg.gmId)
                end
            end
        end
    end)
end

function XAMJScene:getWanFaStr()
    local room_info = RoomInfo.params
    self.game_name = '西安麻将\n'

    local mj_key = "xamj"
    local str = nil
    str = self.game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju-100).."圈"..(RoomInfo.people_total_num or 4).."人\n"
    else
        str = str..room_info.total_ju.."局"..(RoomInfo.people_total_num or 4).."人\n"
    end
    str  = str .. (room_info.isZhiKeZiMo and '只可自摸\n' or '')
    str  = str .. (room_info.isXiaPaoZi and '下炮子\n' or '')
    str  = str .. (room_info.is258Jiang and '258硬将\n' or '')
    str  = str .. (room_info.isHongZhong and '红中癞子\n' or '')
    str  = str .. (room_info.isDaiFeng and '带风\n' or '')
    str  = str .. (room_info.isQingYiSe and '清一色\n' or '')
    str  = str .. (room_info.isHu258Fan and '胡258加番\n' or '')
    str  = str .. (room_info.isJiang258Fan and '将258加番\n' or '')
    str  = str .. (room_info.canHuQiDui == 1 and '可胡七对不加番\n' or '')
    str  = str .. (room_info.canHuQiDui == 2 and '可胡七对加番\n' or '')
    str = str .. (room_info.isQueYiMen and '缺一门\n' or '')

    --self.isDaHu = room_info.isDaHu
    self.is258Jiang = room_info.is258Jiang
    self.canHuQiDui = room_info.canHuQiDui

    log(str)
    return str
end

function XAMJScene:setXiaPaoZi()
    -- 下炮子阶段
    -- 关闭按钮
    self:setBtnXiaPaoZiVisible()

    commonlib.closeQuickStart(self)
    self.xiapaozi_panel:setVisible(true)
    self.xiapaozi_panel:setEnabled(true)

    self.hasXiaPaoZi = true
end

--  下炮子要变更的按钮
function XAMJScene:setBtnXiaPaoZiVisible()
    self.btnQuick:setVisible(false)

    commonlib.showShareBtn(self.share_list)
    self.btnjiesan:setVisible(false)
    self.wanfa:setVisible(true)
    commonlib.showbtn(self.jiesanroom)

    self:setWenHaoListVisible()

    self.btnClubInvite:setVisible(false)
end


return XAMJScene
