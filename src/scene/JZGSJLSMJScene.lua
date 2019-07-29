local MJBaseScene = require('scene.MJBaseScene')

local MJScene = class("MJScene",MJBaseScene)

local LIPAI_DEF = 1
local HOUPAI_DEF = 0
function MJScene.create(param_list)
    log('晋中拐三角立四')
    MJBaseScene.removeUnusedRes()

    local mj = MJScene.new(param_list)

    local scene = cc.Scene:create()
    scene:addChild(mj)
    return scene
end

function MJScene:setMjSpecialData()
    self.haoZi = 'ui/qj_mj/dt_play_haozi_img.png'
    self.haoZiDi = 'ui/qj_mj/haozi.png'
    self.curLuaFile = 'scene.JZGSJLSMJScene'

    self.mjTypeWanFa = 'jzgsj'

    self.RecordGameType = RecordGameType.JZGSJ

    self.mjGameName = '晋中拐三角立四'
end

function MJScene:loadMjLogic()
    self.MJLogic = require('logic.mjjzgsj_lisi_logic')
end

function MJScene:PassTing(value)
    return false
end

function MJScene:PassHu(value)
    if self.hasHu and not self.bMustHu then
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_DO_PASS_HU},
            {index=self.my_index},
        }
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))

        commonlib.showTipDlg("您确定过胡吗？", function(ok)
            if ok then
                self.my_sel_index = nil
                self:sendOperate(nil, 0)

                self.IngoreOpr = true

                self.hasHu = false
                self:sendOutCards(value)
                if not self.can_opt then
                    if self.hasZiMo then
                        self.hasZiMo = false
                    else
                        self:setImgGuoHuIndexVisible(1, true)
                    end
                end
            else
                self.my_sel_index = nil
                if self.show_pai then
                    self.show_pai:removeFromParent(true)
                    self.show_pai = nil
                end
                self:resetCard()
            end
        end)
        self:placeHandCard(1)
        return true
    end
    return false
end

function MJScene:draw_card()
    AudioManager:playDWCSound("sound/mj/card_click_effect.mp3")

    if not self.draw_card_msg and not self.is_playback then
        self:send_join_room_again()
        return
    end

    self.left_card_num = self.draw_card_msg.left_card_num
    self.left_lbl:setString(self.left_card_num)

    local index = self:indexTrans(self.draw_card_msg.index)
    if self.left_card_num > 0 or true then
        local pai = nil
        if index == 1 then
            pai = self:getCardById(index, self.draw_card_msg.card)
            pai.card_id = self.draw_card_msg.card
            pai.type = "huopai"
            pai.sort = 0
        elseif self.is_playback then
            pai = self:getCardById(index, self.draw_card_msg.card, "_stand")
            pai.card_id = self.draw_card_msg.card
            pai.sort = -1
        else
            pai = self:getBackCard(index)
            pai.card_id = 1000
            pai.sort = 0
        end

        local i = (#self.hand_card_list[index])+1
        local pos  = cc.p(self.hand_card_list[index][i-1]:getPosition())
        if self.is_playback then
            if i <= 14 then
                pos.x = pos.x + self.hand_card_pos_list[index].space.x*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.x*self.z_p_s[index]
                pos.y = pos.y + self.hand_card_pos_list[index].space.y*self.scard_space_scale[index] + self.hand_card_pos_list[index].space.y*self.z_p_s[index]
                if index == 1 then
                    pos.x = pos.x + self.hand_card_pos_list[index].space.x*self.z_p_s[index]
                    pos.y = pos.y + self.hand_card_pos_list[index].space.y*self.z_p_s[index]
                end
            else
                i = i-1
                self.hand_card_list[index][i]:removeFromParent(true)
            end
            pai:setPosition(cc.p(pos.x, pos.y+80))
            pai:runAction(cc.MoveTo:create(0.07, pos))

            self.node:addChild(pai)
            local v = pai
            local direct = index
            self:sortHandCardExByIndex(direct,v,i)
        else
            if i <= 14 then
                if index%2 ~= 0 then
                    pos.x = pos.x+self.hand_card_pos_list[index].space.x+self.hand_card_pos_list[index].space.x*self.z_p_s[index]
                    pos.y = pos.y+self.hand_card_pos_list[index].space.y+self.hand_card_pos_list[index].space.y*self.z_p_s[index]
                else
                    pos.x = pos.x+self.hand_card_pos_list[index].space.x+self.hand_card_pos_list[index].space.x*self.z_p_s[index]*0.5
                    pos.y = pos.y+self.hand_card_pos_list[index].space.y+self.hand_card_pos_list[index].space.y*self.z_p_s[index]*0.5
                end
            else
                i = i-1
                self.hand_card_list[index][i]:removeFromParent(true)
            end
            pai:setPosition(cc.p(pos.x, pos.y+80))
            pai:runAction(cc.MoveTo:create(self.drawCardActionTime, pos))

            self.node:addChild(pai)
            local v = pai
            local direct = index
            self:sortHandCardExByIndex(direct,v,i)
        end
        self.hand_card_list[index][i] = pai

        self.draw_card_msg = nil
        self:showAction()
    else
        local cpai = self:getCardById(1, self.draw_card_msg.card)
        cpai:setPosition(cc.p(g_visible_size.width/2, g_visible_size.height/2))
        self.node:addChild(cpai, 10000)
        cpai:setScale(1.25)
        cpai.card_id = self.draw_card_msg.card

        cpai:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.Spawn:create(cc.ScaleTo:create(0.15,1), cc.MoveTo:create(0.15, self.open_card_pos_list[index])),cc.CallFunc:create(function()

        local pai = self:getOpenCardById(index, cpai.card_id)
        pai.card_id = cpai.card_id
        local nRow = math.floor((#self.out_card_list[direct]) / (self.out_row_nums))
        local nCow = (#self.out_card_list[direct]) % (self.out_row_nums)

        pai:setPosition(self:getOutCardPosition(direct,nRow,nCow))
        self.node:addChild(pai)
        pai:setLocalZOrder(self:getOutCardZOrder(direct,nRow,nCow))
        self.out_card_list[index][#self.out_card_list[index]+1] = pai

        cpai:removeFromParent(true)

        self.pre_out_direct = index
        self:showCursor()

        self:showAction()

        end)))

        self.draw_card_msg = nil
    end
end

function MJScene:onRcvMjOutCard(rtn_msg)
    local open_card_index = self:indexTrans(rtn_msg.index)
    local isTingOut = false
    if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD and rtn_msg.cards and rtn_msg.cards[1] > 0x80 then
        isTingOut = true
    end
    local bForceRunServer = false
    if open_card_index == 1 and 14 == #self.hand_card_list[open_card_index] then
        bForceRunServer = true
    end

    if not bForceRunServer then
        if rtn_msg.cmd == NetCmd.S2C_MJ_OUT_CARD and open_card_index == 1 and not self.out_from_client and not self.is_playback and not isTingOut then
            if rtn_msg.errno and rtn_msg.errno ~= 0 then
                self:clientOutCardRollBack(rtn_msg)
            end
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
                    elseif rtn_msg.errno == 1 then
                        commonlib.showLocalTip('不能出牌，必须胡牌')
                    end
                end
            else
                if self.oper_pai_bg then
                    self.oper_pai_bg:removeFromParent(true)
                    self.oper_pai_bg = nil
                end
                if self.oper_pai_id then
                    self.oper_pai_id = 0
                end
                log('S2C_MJ_OUT_CARD')
                if self.is_playback and self.soundTing then
                    self:playTingAct(self,open_card_index)
                end
                self.pre_out_direct = open_card_index
                self:openCard(open_card_index, rtn_msg.cards, 0)
                self:playCardSound(rtn_msg.cards[1], open_card_index)
                if self.ting_status then
                    self:addCardShadow()
                end
            end
            self:placeHandCard(1)
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
            if self.ting_status then
                self:addCardShadow()
            end
        end
    end
end

function MJScene:backOpenCard()
    if not self.is_back_open_card then
        for direct, player in ipairs(self.hand_card_list or {}) do
            if direct ~= 1 then
                for ii, cid in ipairs(player) do
                    local pai = self:getCardById(direct, cid.card_id-1000, "_stand")
                    pai.card_id = cid.card_id-1000
                    pai.sort = -1
                    pai.type = "huopai"
                    if ii <= 4 then
                        pai.sort = 1
                        pai.type = "lipai"
                    end
                    if direct == 4 then
                        self.node:addChild(pai, 14-ii)
                    else
                        self.node:addChild(pai, 1)
                    end
                    cid:removeFromParent(true)
                    self.hand_card_list[direct][ii] = pai
                end
                self:placeHandCard(direct)
                self:sortHandCardEx(direct)
            end
        end
        self.is_back_open_card = true
    end
end

function MJScene:treatPlayback(rtn_msg)
    self.direct_img_cur = nil
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))

    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i+1] = v
    end

    for __, player in ipairs(playerinfo_list) do
        commonlib.echo(player)
        local direct = self:indexTrans(player.index)
        table.sort(player.cards)
        for ii, cid in ipairs(player.lipai) do
            local pai = nil
            if direct == 1 then
                pai = self:getCardById(direct, cid)
                pai.sort = LIPAI_DEF
                pai.type = "lipai"
                pai.card_id = cid
            else
                pai = self:getBackCard(direct)
                pai.card_id = 1000+cid
                pai.sort = LIPAI_DEF
                pai.type = "lipai"
                pai.ssort = ii
            end
            self.node:addChild(pai)
            self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
        end

        for ii, cid in ipairs(player.huopai) do
            local pai = nil
            if direct == 1 then
                pai = self:getCardById(direct, cid)
                pai.sort = HOUPAI_DEF
                pai.type = "huopai"
                pai.card_id = cid
            else
                pai = self:getBackCard(direct)
                pai.card_id = 1000+cid
                pai.sort = HOUPAI_DEF
                pai.type = "huopai"
                pai.ssort = ii
            end
            self.node:addChild(pai)
            self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
        end
        self:sortHandCardEx(direct)
        self:placeHandCard(direct)
    end
    self.left_card_num = rtn_msg.left_card_num
    self.left_lbl:setString(self.left_card_num)
    self.left_lbl:setVisible(true)
end

function MJScene:treatResume(rtn_msg)
    -- print('```````````````````````')
    -- dump(rtn_msg)
    -- print('```````````````````````')
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
    -- self.last_out_card = rtn_msg.player_info.out_card[#rtn_msg.player_info.out_card]
    -- for i,v in ipairs(rtn_msg.other) do
    --     if #v.out_card > #rtn_msg.player_info.out_card then
    --         self.last_out_card = v.out_card[#v.out_card]
    --     end
    -- end
    self.direct_img_cur = nil
    self.is_treatResume = true
    self.watcher_lab:stopAllActions()
    self.watcher_lab:setString(string.format("%02d", 0))
    local is_start = rtn_msg.cur_id and #rtn_msg.player_info.hand_card > 0
    if is_start then
        self:addPlist()
    end

    if rtn_msg.player_info.ready == false and not rtn_msg.result_packet then
        self:sendReady()
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

    for __, player in ipairs(playerinfo_list) do
        local direct = self:indexTrans(player.index)
        -- 下坎的牌
        self:treatResumeGroupCard(direct,player.group_card,nil,1)

        -- log('断线重连 direct ' .. tostring(direct) .. ' 听牌 ' .. tostring(player.is_ting))
        if direct == 1 then
            local len = 14 - (#player.group_card*3)
            -- 设置手牌
            if player.lipai and #player.lipai > 0 then
                for ci, cid in ipairs(player.lipai) do
                    if ci <= len then
                        local pai = self:getCardById(direct, cid)
                        pai.card_id = cid
                        pai.sort = LIPAI_DEF
                        pai.type = "lipai"
                        self.node:addChild(pai)
                        self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                    end
                end
                self.lipai = player.lipai
            end
            if player.huopai and #player.huopai > 0 then
                for ci, cid in ipairs(player.huopai) do
                    if ci <= len then
                        local pai = self:getCardById(direct, cid)
                        pai.card_id = cid
                        pai.sort = HOUPAI_DEF
                        pai.type = "huopai"
                        self.node:addChild(pai)
                        self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
                    end
                end
            end
            self:addLipaiCardShadow()

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
                self.actions = player.actions
                self:resetOperPanel(player.actions, nil, player.oper_card, player.msgid, player.kg_cards, player.isMustHu)
            end
            self:setImgGuoHuIndexVisible(1,player.is_louhu)
            self:setImgGuoLongIndexVisible(1,player.is_pass_long)
            self:setImgGuoPengIndexVisible(1,player.is_pass_peng)
        elseif is_start then
            local len = 13 - (#player.group_card*3)
            if rtn_msg.cur_id ~= rtn_msg.last_id and rtn_msg.cur_id == player.index then
                len = len+1
            end
            for ii=1, len  do
                local pai = self:getBackCard(direct)
                pai.card_id = 1000
                pai.sort = HOUPAI_DEF
                pai.ssort = ii
                if direct == 4 then
                    self.node:addChild(pai, 14-ii)
                else
                    self.node:addChild(pai, 10)
                end
                self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
            end
        end

        --排序手牌
        self:sortHandCard(direct, true)

        local b14Card = self:treatResume14thCard(direct,player)

        self:placeHandCard(direct,nil, not b14Card)

        -- 加阴影
        if player.is_ting and direct == 1 then
            self:addCardShadow()
        end

        -- 听牌
        if player.is_ting then
            self:addTingTag(direct)
        end

        -- 设置已出的牌
        -- player.out_card = {0,0,0,0,0,0,1,1,1,1,}

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
function MJScene:checkNoWangCard()
    local count = 0
    for __, v in ipairs(self.hand_card_list[1]) do
        if (v.sort == 0 or v.sort == 1) and v.card_id ~= self.wang_cards[2] and v.card_id ~= self.wang_cards[3] then
            count = count + 1
        end
    end
    return count
end

function MJScene:checkTingTip(card_id)
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
                if v.sort ~= 0 and v.card_id and v.card_id == card_id and v.sort ~= 1 then
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
        -- 听字
        self:setTingTitleVisible(self.tdh_need_bTing)

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

function MJScene:createLayerMenu(room_info)
    local starttime = os.clock()
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end

    self:setOwnerName(room_info)

    local ui_prefix = ""
    ui_prefix = 'pm'
    local endtime = os.clock()
    print(string.format("··· cost time  : %.4f", endtime - starttime))

    local starttime = os.clock()
    local node = nil
    if self.is_3dmj then
        node = tolua.cast(cc.CSLoader:createNode("ui/Roompm3d.csb"), "ccui.Widget")
    else
        node = tolua.cast(cc.CSLoader:createNode("ui/Roompm.csb"), "ccui.Widget")
    end
    self:addChild(node)

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node

    local endtime = os.clock()
    print(string.format("加载 Roommp.csb cost time  : %.4f", endtime - starttime))

    local starttime = os.clock()

    ccui.Helper:seekWidgetByName(node,"koupai"):setVisible(false)
    ccui.Helper:seekWidgetByName(node, "pnPiaoFen"):setVisible(false)
    local img_bg = ccui.Helper:seekWidgetByName(node, "Panel_1"):getChildByName("Image_2")
    local img_bg_title = tolua.cast(img_bg:getChildByName("img_title"), "ccui.ImageView")
    img_bg_title:setVisible(not ios_checking)
    if self.is_3dmj then
        img_bg_title:loadTexture("ui/qj_bg/3d/3d_jzgsj.png")
        img_bg:loadTexture(self.img_3d[self.zhuobu])
    else
        img_bg_title:loadTexture("ui/qj_bg/2d/2d_jzgsj.png")
        img_bg:loadTexture(self.img_2d[self.zhuobu])
    end
    self.img_bg = img_bg
    self.res3DPath = 'ui/qj_mj/3d'

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

    local endtime = os.clock()
    print(string.format("设置Roompm.csb cost time  : %.4f", endtime - starttime))

    local starttime = os.clock()
    -- 吃碰杠胡操作面板
    local oper_ui = tolua.cast(cc.CSLoader:createNode("ui/Oper"..ui_prefix..".csb"), "ccui.Widget")
    self:addChild(oper_ui, 10000)

    oper_ui:setContentSize(g_visible_size)

    ccui.Helper:doLayout(oper_ui)

    local endtime = os.clock()
    print(string.format("加载Oper.csb cost time  : %.4f", endtime - starttime))

    local starttime = os.clock()

    self.oper_panel = oper_ui:getChildByName("Panel_caozuo")
    self.oper_panel:setVisible(false)

    self.chi_panel = oper_ui:getChildByName("Panel_chi")
    self.chi_panel:setVisible(false)

    -- 碰回调
    local function pengOptTreat()
        print("peng")
        local open_value = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]].card_id
        local index_list = {}
        local lipai_cards = {}
        local is_peng_lipai = 0
        for i=#self.hand_card_list[1], 1, -1 do
            local v = self.hand_card_list[1][i]
            if (v.sort == 0 or v.sort == 1) and v.card_id== open_value then
                index_list[#index_list+1] = i
                if v.type == "lipai" then
                    is_peng_lipai = is_peng_lipai + 1
                end
            end
        end
        for i=1,#index_list do
            if self.hand_card_list[1][index_list[i]].type == "lipai" then
                lipai_cards[#lipai_cards+1] = self.hand_card_list[1][index_list[i]].card_id
                self.hand_card_list[1][index_list[i]].sort = 0
                local card_shadow = self.hand_card_list[1][index_list[i]]:getChildByName('card_shadow')
                if card_shadow then
                    card_shadow:removeFromParent(true)
                end
            end
        end
        local handLipai = self:getHandCardLipaisId()
        if handLipai and #handLipai == 2 and is_peng_lipai == 2 then
            table.remove(lipai_cards,#lipai_cards)
            self.hand_card_list[1][index_list[1]].sort = 1
            self.hand_card_list[1][index_list[1]].type = "lipai"
            self:sendOperate({self.hand_card_list[1][index_list[2]].card_id, self.hand_card_list[1][index_list[3]].card_id}, 2, nil, lipai_cards)
            self.pengOpt = 2
            return
        end
        if is_peng_lipai == 1 and handLipai and #handLipai == 1 then
            table.remove(lipai_cards,#lipai_cards)
            self.hand_card_list[1][index_list[1]].sort = 1
            self.hand_card_list[1][index_list[1]].type = "lipai"
            self:sendOperate({self.hand_card_list[1][index_list[2]].card_id, self.hand_card_list[1][index_list[3]].card_id}, 2, nil, lipai_cards)
            self.pengOpt = 2
            return
        end
        if is_peng_lipai > 0 and is_peng_lipai < 3 and #index_list > 2 then
            self:addLipaiCardShadow()
            self.chi_panel:setVisible(true)
            ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(0.68)
            self.chi_panel:getChildByName("com1"):setVisible(false)
            self.chi_panel:getChildByName("com2"):setVisible(false)
            self.chi_panel:getChildByName("com3"):setVisible(false)
            self.chi_panel:setPositionX(840)
            for i=1,2 do
                local btn = self.chi_panel:getChildByName("com"..i)
                btn:setBackGroundImageOpacity(0)
                local vv = self.hand_card_list[1][index_list[i]].card_id
                if vv then
                    btn:setTouchEnabled(true)
                    btn:setVisible(true)

                    local color = math.floor(vv/16)
                    if color == 0 then
                        color = ""
                    end
                    if self.is_3dmj then
                        local bei1 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView")
                        local bei2 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView")
                        local bei3 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView")
                        bei1:loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv%16)..".png")
                        bei2:loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv%16)..".png")
                        bei3:loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv%16)..".png")
                        if is_peng_lipai == 1 then
                            if i == 1 then
                                bei1:addChild(self:createCardShadow(bei1, false))
                            end
                        else
                            bei1:addChild(self:createCardShadow(bei1, false))
                            bei2:addChild(self:createCardShadow(bei2, false))
                            if i == 2 then
                                bei2:getChildByName("card_shadow"):removeFromParent(true)
                            end
                        end
                    else
                        local bei1 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei1"), "ccui.ImageView")
                        local bei2 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei2"), "ccui.ImageView")
                        local bei3 = tolua.cast(ccui.Helper:seekWidgetByName(btn, "bei3"), "ccui.ImageView")
                        bei1:loadTexture(self:getCardTexture(vv),1)
                        bei2:loadTexture(self:getCardTexture(vv),1)
                        bei3:loadTexture(self:getCardTexture(vv),1)
                        bei2:setPositionX(87)
                        bei3:setPositionX(175)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):setVisible(false)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):setVisible(false)
                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):setVisible(false)
                        if is_peng_lipai == 1 then
                            if i == 1 then
                                bei1:addChild(self:createCardShadow(bei1, true))
                            end
                        else
                            bei1:addChild(self:createCardShadow(bei1, true))
                            bei2:addChild(self:createCardShadow(bei2, true))
                            if i == 2 then
                                bei2:getChildByName("card_shadow"):removeFromParent(true)
                            end
                        end
                    end
                    btn:addTouchEventListener(function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            if i == 1 then
                                self:sendOperate({self.hand_card_list[1][index_list[1]].card_id, self.hand_card_list[1][index_list[2]].card_id}, 2, nil, lipai_cards)
                            else
                                table.remove(lipai_cards,#lipai_cards)
                                self.hand_card_list[1][index_list[1]].sort = 1
                                self.hand_card_list[1][index_list[1]].type = "lipai"
                                self:sendOperate({self.hand_card_list[1][index_list[2]].card_id, self.hand_card_list[1][index_list[3]].card_id}, 2, nil, lipai_cards)
                                self.pengOpt = 2
                            end
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
        else
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
            if is_peng_lipai == 3 then
                table.remove(lipai_cards,#lipai_cards)
            end
            local base_i = self:handCardBaseIndex(1)
            self:sendOperate({self.hand_card_list[1][index_list[1]].card_id, self.hand_card_list[1][index_list[2]].card_id}, 2, nil, lipai_cards)
        end
        self.oper_panel:setVisible(false)
    end

    -- 杠回调
     local function gangOptTreat(open_value_list)
        print("gang")
        local lipai_cards = {}
        local handLipai = self:getHandCardLipaisId()
        if not open_value_list or #open_value_list == 0 then
            for __,v in ipairs(handLipai or {}) do
                if self.last_out_card == v then
                    lipai_cards[#lipai_cards+1] = self.last_out_card
                end
            end
            self:sendOperate(nil, 3, nil, lipai_cards)
        elseif #open_value_list == 1 then
            for __,v in ipairs(handLipai or {}) do
                if open_value_list[1] == v then
                    lipai_cards[#lipai_cards+1] = open_value_list[1]
                end
            end
            self:sendOperate(open_value_list[1], 3, open_value_list[1], lipai_cards)
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
                            for __,v in ipairs(handLipai or {}) do
                                if vv == v then
                                    lipai_cards[#lipai_cards+1] = vv
                                end
                            end
                            self:sendOperate(vv, 3, vv, lipai_cards)
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

    self.tdh_need_bTing = false

    -- 可碰杠胡时的回调
    local function operCallback(opt_type)
        log(' !!!!!!!!!!!!!!! ' .. tostring(opt_type))

        self:removeCardShadow()

        -- 听
        self.tdh_need_bTing = false
        if self.oper_pai_id then
            self.oper_pai_id = 0
        end
        if self.ting_tip_layer then
            self.ting_tip_layer:setVisible(false)
        end
        if self.oper_pai_bg and opt_type ~= "guo" and opt_type ~= "guo_hu" and type(opt_type) ~= "table" then
            self.oper_pai_bg:removeFromParent(true)
            self.oper_pai_bg = nil
        end
        self:removeShowPai()

        local hasPeng = self.hasPeng

        self.hasPeng = false
        self.hasTing = false
        self.hasGang = false
        self.hasHu = false

        local treat = nil
        if type(opt_type) == "table" then
            log(' table ')
            gangOptTreat(opt_type)
            treat = true
        elseif opt_type == "guo" then
            if hasPeng then
                self:setImgGuoPengIndexVisible(1, true)
            end
            self:resetCardSort()
            self:removeTingArrow()
            self:addLipaiCardShadow()
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
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))

            commonlib.showTipDlg("当前可胡牌，您确定不胡吗？", function(ok)
                if ok then
                    operCallback("guo")
                    -- 过胡一直存在
                    if not self.can_opt then
                        if self.is_pass_long then
                            self:setImgGuoLongIndexVisible(1, true)
                        else
                            self:setImgGuoHuIndexVisible(1, true)
                        end
                        if hasPeng then
                            self:setImgGuoPengIndexVisible(1, true)
                        end
                    end
                end
            end)

            treat = true
        elseif opt_type == "peng" then
            pengOptTreat()
            treat = true
        elseif opt_type == "bu" then
            treat = true
        elseif opt_type == "chi" then
            self:chiOptTreat(self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]].card_id)
            treat = true
        elseif opt_type == "hu" then
            self:sendOperate(nil, 5)
            self.hasZiMo = false
        elseif opt_type == "yao" then
            self:sendOperate(nil, 6)
        elseif opt_type == 'ting' then
            if self.btnTing then
                self.btnTing:setVisible(false)
            end
            if self.btnGang then
                self.btnGang:setVisible(false)
            end
            -- 获取听牌列表
            self.tdh_need_bTing = true
            for i , card in pairs(self.hand_card_list[1]) do
                local card_shadow = card:getChildByName('card_shadow')
                if not card_shadow and card.sort == 0 and card.type == "huopai" then
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
                if card.ting_ar and card.type == "lipai" then
                    card.sort = 0
                    if card_shadow then
                        card_shadow:removeFromParent(true)
                    end
                end
                if card.type == "huopai" then
                    card.sort = 1
                end
            end
            ------------------------------------------------
            treat = true
        end

        self:setTingTitleVisible(self.tdh_need_bTing)

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
    local function loggg(...)
        -- log(...)
    end
    -- 点击按钮
    self:registerScriptTouchHandler(function(touch_type, xx, yy)
        loggg('点击',touch_type,self.can_opt)
        if self.can_opt then
            if touch_type == "began" then
                local vaild = false
                vaild,sel_init_posx,preX,preY,has_move = self.MJClickAction.Began(self,xx,yy,preX,preY,sel_init_posx,has_move)
                return vaild
            elseif touch_type == "moved" then
                sel_init_posx,preX,preY,has_move = self.MJClickAction.Move(self,xx,yy,preX,preY,sel_init_posx,has_move)
            else
                local function outCardAppedMsgFun(card)
                    if card.type == "lipai" then
                        self.out_card_islipai = true
                    end
                end
                local function callFunc()
                    if self.hasHu or self.hasGang then
                        return true
                    end
                end
                has_move = self.MJClickAction.End(self,xx,yy,preX,preY,sel_init_posx,has_move,callFunc,outCardAppedMsgFun)
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

    -- 庄家
    self.banker = self:indexTrans(room_info.host_id)
    -- 根据庄家初始化 东南西北位置
    self:initSouthPan()

    if self.is_pmmj then
        self.southPan:setVisible(self.is_game_start)
    elseif self.is_3dmj then
        self.southPan3d:setVisible(self.is_game_start)
    end

    self.watcher_lab:setVisible(self.is_game_start)
    --
    self.wanfa_str = self:getWanFaStr()
    -- 房间信息，局数，扎鸟等
    self:setShuoMing(self.wanfa_str)

    self.isZiMoIfPass = room_info.isZiMoIfPass

	ccui.Helper:seekWidgetByName(node, "Image_40"):setVisible(false)

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

    self:initImgGuoHuIndex()

    self:initImgGuoPengIndex()
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

    if room_info.status == 0 then
        if not room_info.player_info or not room_info.player_info.ready then
            -- self:sendReady()
        end
    end

    -- 显示庄家
    if self.banker > 0 and self.banker <= 4 then
        self.player_ui[self.banker]:getChildByName("Zhang"):setVisible(true)
    end

    self:setBtnDeskShare()

    self.qunzhu = room_info.qunzhu
    self:setClubInvite()
    --gt.listenBatterySignal(self)

    local endtime = os.clock()
    print(string.format("游戏准备开始 cost time  : %.4f", endtime - starttime))
end

function MJScene:playKaiWang(rtn_msg)
    -- print('晋中拐三角立四S')
    -- dump(rtn_msg)
    -- print('晋中拐三角立四E')
    local function initCard()
        -- log('XXXXXXXXXX')
        -- 加入手牌
        for __, v in ipairs(rtn_msg.lipai) do
            local pai = self:getCardById(1, v)
            pai.card_id = v
            pai.sort = LIPAI_DEF
            pai.type = "lipai"
            self.hand_card_list[1][#self.hand_card_list[1]+1] = pai
        end
        self.lipai = rtn_msg.lipai
        for __, v in ipairs(rtn_msg.huopai) do
            local pai = self:getCardById(1, v)
            pai.card_id = v
            pai.sort = HOUPAI_DEF
            pai.type = "huopai"
            self.hand_card_list[1][#self.hand_card_list[1]+1] = pai
        end
        self:addLipaiCardShadow()
        -- 排序手牌
        self:sortHandCard(1)
        self:placeHandCard(1)
        -- 加入到桌面
        for i, v in ipairs(self.hand_card_list[1]) do
            self.node:addChild(v)
        end

        local direct_list = {2,3,4}
        if self.people_num == 3 then
            direct_list = {2, 4}
        elseif self.people_num == 2 then
            direct_list = {3}
        end

        -- 设置其它玩家的手牌背面
        for __, direct in ipairs(direct_list) do
            local count = 13
            local k = 4
            if direct == self.banker then
                count = 14
                k = 5
            end
            for i=1, count do
                local pai = self:getBackCard(direct)
                pai.sort = HOUPAI_DEF
                if i <=4 then
                    pai.sort = LIPAI_DEF
                end
                pai.card_id = 1000
                pai.ssort = i

                self.node:addChild(pai)
                self.hand_card_list[direct][#self.hand_card_list[direct]+1] = pai
            end
            self:sortHandCard(direct)

            self:placeHandCard(direct)
        end

        -- 剩于牌张数
        self.left_card_num = rtn_msg.left_card_num
        self.left_lbl:setVisible(true)
        self.left_lbl:setString(self.left_card_num)

        self:showAction()
    end
    initCard()
end

function MJScene:liSiSpecialCardType(pai)
    pai.type = "huopai"
end

function MJScene:liSiSpecialCardTypeSort(vv)
    if self.is_playback then
        vv.type = nil
        return
    end
    if vv.type == "lipai" and vv.sort == 0 then
        vv.sort = 1
    end
end

function MJScene:sortHandCard(direct, no_comp_id)

    local wang_cards = {}
    if self.wang_cards and #self.wang_cards > 0 then
        if #self.wang_cards == 3 then
            wang_cards = {self.wang_cards[2], self.wang_cards[3]}
        else
            wang_cards = self.wang_cards
        end
    end
    for i, v in ipairs(self.hand_card_list[direct]) do
        local j = i
        for ii, vv in ipairs(self.hand_card_list[direct]) do
            if ii > i then
                if vv.sort == self.hand_card_list[direct][j].sort then
                    if vv.ssort and self.hand_card_list[direct][j].ssort and vv.ssort < self.hand_card_list[direct][j].ssort then
                        j = ii
                    elseif vv.card_id ~= self.hand_card_list[direct][j].card_id then
                        if vv.sort == 0 or vv.sort == -1 or vv.sort == 1 then
                            if #wang_cards > 0 then
                                local j_w = 0
                                local v_w = 0
                                for w_i, w_c in ipairs(wang_cards) do
                                    if w_c == vv.card_id then
                                        v_w = w_i
                                    end
                                    if w_c == self.hand_card_list[direct][j].card_id then
                                        j_w = w_i
                                    end
                                end
                                if j_w == 0 then
                                    if v_w ~= 0 then
                                        j = ii
                                    else
                                        if vv.card_id < self.hand_card_list[direct][j].card_id then
                                            j = ii
                                        end
                                    end
                                elseif j_w ~= 1 then
                                    if v_w == 1 then
                                        j = ii
                                    elseif v_w ~= 0 then
                                        if vv.card_id < self.hand_card_list[direct][j].card_id then
                                            j = ii
                                        end
                                    end
                                end

                            elseif not no_comp_id and vv.card_id < self.hand_card_list[direct][j].card_id then
                                j = ii
                            end
                        end
                    end
                elseif vv.sort > self.hand_card_list[direct][j].sort then
                    j = ii
                end
            end
        end
        if j ~= i then
            local temp = self.hand_card_list[direct][i]
            self.hand_card_list[direct][i] = self.hand_card_list[direct][j]
            self.hand_card_list[direct][j] = temp
        end
    end

    self:sortHandCardEx(direct)
end

function MJScene:placeHandCard(direct, first_pos)
    local com_space = first_pos or cc.p(self.hand_card_pos_list[direct].init_pos.x, self.hand_card_pos_list[direct].init_pos.y)
    local first_hand = nil

    local bHasLiPai = false

    for ii, vv in ipairs(self.hand_card_list[direct]) do
        -- 设置手牌
        vv:stopAllActions()
        if vv.sort == -1 then
            -- 回放时走这里
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space_replay.x
            com_space.y = com_space.y + self.hand_card_pos_list[direct].space_replay.y

            vv:setPosition(cc.p(com_space.x, com_space.y))
        elseif vv.sort == LIPAI_DEF then
            self:placeHandCardWithCanOut(direct,com_space,vv,ii)

            bHasLiPai = true

            local next_card = self.hand_card_list[direct][ii+1]
            if next_card and next_card.sort and next_card.sort ~= vv.sort then
                com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]/5
                com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]/5
            end
        elseif vv.sort == HOUPAI_DEF then
            self:placeHandCardWithCanOut(direct,com_space,vv,ii)
        else
            -- 设置下坎后的牌
            com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.scard_space_scale[direct]
            com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y*self.scard_space_scale[direct]

            vv:setPosition(cc.p(com_space.x, com_space.y))

            if first_pos then
                local pai = self.hand_card_list[direct][13]
                if pai and pai.sort == 0 then
                    if direct == 2 then
                        local pos = com_space.x
                        local starPosX = pos + pai:getContentSize().width/2
                        vv:setPositionX(starPosX - vv:getContentSize().width/2)
                    elseif direct == 4 then
                        local pos = com_space.x
                        local starPosX = pos - pai:getContentSize().width/2
                        vv:setPositionX(starPosX + vv:getContentSize().width/2)
                    elseif direct == 3 then
                        local pos = com_space.y
                        local starPosY = pos - pai:getContentSize().height/2
                        vv:setPositionY(starPosY + vv:getContentSize().height/2)
                    elseif direct == 1 then
                        local pos = com_space.y
                        local starPosY = pos - pai:getContentSize().height/2 + 0.1 * pai:getContentSize().height/2
                        vv:setPositionY(starPosY + vv:getContentSize().height/2)
                    end
                end
            end

            local next_card = self.hand_card_list[direct][ii+1]
            if next_card and (not next_card.cardType or next_card.cardType and next_card.cardType ~= vv.cardType) then
                com_space.x = com_space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
                com_space.y = com_space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
            end
        end
    end
    if not self.tdh_need_bTing then
        self:addLipaiCardShadow()
    end
    if first_pos then
        self:set14thCardPosition(direct)
        return
    end
    if not self.hand_card_list[direct] or not self.hand_card_list[direct][1] or not self.hand_card_list[direct][13] then
        return
    end
    local first_pos_x,first_pos_y = self.hand_card_list[direct][1]:getPosition()
    local end_pos_x,end_pos_y = self.hand_card_list[direct][13]:getPosition()

    if direct == 1 then
        first_pos_y = self.hand_card_pos_list[direct].init_pos.y
        end_pos_y = self.hand_card_pos_list[direct].init_pos.y
    end

    if self.hand_card_list[direct][13].sort == -1 then
        end_pos_x = end_pos_x + self.hand_card_pos_list[direct].space_replay.x + self.hand_card_pos_list[direct].space_replay.x*self.z_p_s[direct]
        end_pos_y = end_pos_y + self.hand_card_pos_list[direct].space_replay.y + self.hand_card_pos_list[direct].space_replay.y*self.z_p_s[direct]
    else
        end_pos_x = end_pos_x + self.hand_card_pos_list[direct].space.x + self.hand_card_pos_list[direct].space.x*self.z_p_s[direct]
        end_pos_y = end_pos_y + self.hand_card_pos_list[direct].space.y + self.hand_card_pos_list[direct].space.y*self.z_p_s[direct]
    end
    if direct == 1 or direct == 3 then
        first_pos_x = (g_visible_size.width - (end_pos_x - first_pos_x))/2
    elseif direct == 2 or direct == 4 then
        first_pos_y = (g_visible_size.height - (end_pos_y - first_pos_y))/2
    end

    if direct == 1 then
        first_pos_x = self:adjustFirstCardPos(first_pos_x,self.hand_card_list[direct][1])
    end

    if self.hand_card_list[direct][13].sort == -1 then
        first_pos_x = first_pos_x - self.hand_card_pos_list[direct].space_replay.x
        first_pos_y = first_pos_y - self.hand_card_pos_list[direct].space_replay.y
    else
        first_pos_x = first_pos_x - self.hand_card_pos_list[direct].space.x
        first_pos_y = first_pos_y - self.hand_card_pos_list[direct].space.y
    end

    self:placeHandCard(direct,cc.p(first_pos_x,first_pos_y))
end

function MJScene:resetCardSort()
    for i,v in ipairs(self.hand_card_list[1]) do
        if v.type == "lipai" then
            v.sort = 1
        elseif v.type == "huopai" then
            v.sort = 0
        end
    end
end

function MJScene:addCardShadow(bIngore14)
    for i , card in pairs(self.hand_card_list[1]) do
        local card_shadow = card:getChildByName('card_shadow')
        if not card_shadow and (card.sort == 0 or card.sort == 1) and (i ~= 14 or bIngore14) then
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

function MJScene:addLipaiCardShadow()
    for i, card in ipairs(self.hand_card_list[1]) do
        local card_shadow = card:getChildByName('card_shadow')
        if not card_shadow and card.type == "lipai" then
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

function MJScene:sendOperate(value, opt, target_value, lipai_cards)

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
        if lipai_cards and #lipai_cards > 0 then
            input_msg[#input_msg+1]={cardsInLiPai=lipai_cards}
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
        if lipai_cards and #lipai_cards > 0 then
            input_msg[#input_msg+1]={cardsInLiPai=lipai_cards}
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
        -- if not self.oper_panel.time_out_flag then
        local input_msg = {
            {cmd =NetCmd.C2S_PASS},
            {index=self.my_index},
        }
        if self.oper_panel.msgid then
            input_msg[#input_msg+1] = {msgid=self.oper_panel.msgid}
        end
        ymkj.SendData:send(json.encode2(input_msg))
        -- else
        --     local input_msg = {
        --         {cmd =NetCmd.C2S_MJ_HAIDI},
        --         {need =0},
        --         {index=self.my_index},
        --     }
        --     ymkj.SendData:send(json.encode2(input_msg))
        -- end
    elseif opt == self.TING_OPERATOR then
        self.ting_list = {}
        self:removeTingArrow()
        self.soundTing = true
        local input_msg = {
            {cmd =NetCmd.C2S_MJ_TINGPAI},
            {index=self.my_index},
            {card = target_value},
        }
        if self.out_card_islipai then
            input_msg[#input_msg+1] = {isLiPai = self.out_card_islipai}
        end
        ymkj.SendData:send(json.encode2(input_msg))
    end

    self.oper_panel.msgid = nil
end

function MJScene:openCard(direct, card_ids, opt_type, check_ac, lnLastUser)
    logUp('MJScene:openCard')

    log('direct ' .. tostring(direct))
    local str = ''
    for i = 1,#card_ids do
        str = str .. tonumber(card_ids[i]) .. '-'
    end
    log('card_ids ' .. str)
    log('opt_type ' .. tostring(opt_type))
    log('check_ac ' .. tostring(check_ac))
    log(self.out_card_islipai)
    self:removeShowPai()
    if not card_ids then
    elseif #card_ids == 1 and opt_type < 10 then
        local card_value = card_ids[1]
        if card_value > 0x80 then
            card_ids[1] = card_ids[1] - 0x80
            card_value = 0
        end
        local card = nil
        if direct == 1 then
            if self.out_card_islipai then
               for i,v in ipairs(self.hand_card_list[direct]) do
                    local v = self.hand_card_list[direct][i]
                    if v.sort == 0 and v.card_id == card_ids[1] then
                            card = v
                        break
                    end
                end
            else
                for i=#self.hand_card_list[direct], 1, -1 do
                    local v = self.hand_card_list[direct][i]
                    if v.sort == 0 and v.card_id == card_ids[1] then
                            card = v
                        break
                    end
                end
            end
        elseif self.is_playback then
            if self.out_card_islipai then
                for i,v in ipairs(self.hand_card_list[direct]) do
                    local v = self.hand_card_list[direct][i]
                    if v.sort == 0 and v.card_id == card_ids[1] then
                            card = v
                        break
                    end
                end
            else
                for i=#self.hand_card_list[direct], 1, -1 do
                    local v = self.hand_card_list[direct][i]
                    if v.sort == -1 and v.card_id == card_ids[1] then
                            card = v
                        break
                    end
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

                    if card.getPosition then
                        startPosX, startPosY = card:getPosition()
                    end

                    card:removeFromParent(true)
                    card = nil
                    break
                end
            end
            for i,v in ipairs(self.hand_card_list[direct]) do
                if v.type == "lipai" then
                    v.sort = 1
                end
                self.out_card_islipai = nil
            end
            if direct == 1 or self.is_playback then
                self:sortHandCard(direct)
                self:placeHandCard(direct)
            end

            local show_pai = self.show_pai
            local bigger_scale = 1
            if direct ~= 3 or direct ~= 1 then
                bigger_scale = 1.25
            end
            local show_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_chupai_img.png")
            if not show_pai then
                show_pai = self:getCardById(1, card_value, "_stand", true)
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
            local is_tingpai_inrecord = nil
            if self.soundTing and self.is_playback and card_value == 0 then
                card_value = card_ids[1]
                is_tingpai_inrecord = true
            end
            local pai = self:getOpenCardById(direct, card_value, true)
            pai.card_id = card_value
            if is_tingpai_inrecord then
                pai:setColor(cc.c3b(96,96,96))
                is_tingpai_inrecord = nil
            end

            local nRow = math.floor((#self.out_card_list[direct]) / (self.out_row_nums))
            local nCow = (#self.out_card_list[direct]) % (self.out_row_nums)

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

            self.node:addChild(pai)
            pai:setLocalZOrder(self:getOutCardZOrder(direct,nRow,nCow))

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

function MJScene:resetOperPanel(oper, haidi_ting, last_card_id, msgid, kg_cards, bMustHu)
    -- logUp('MJScene:resetOperPanel')
    -- logUp('resetOperPanel ')
    -- print('@@@@@@@@@@@@@')
    -- print('oper')
    -- dump(oper)
    -- print('haidi_ting')
    -- dump(haidi_ting)
    -- print('last_card_id')
    -- dump(last_card_id)
    -- print('msgid')
    -- dump(msgid)
    -- print('kg_cards')
    -- dump(kg_cards)
    -- print('bMustHu')
    -- dump(bMustHu)

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
    local OPER_BI_HU     = 13 -- 必胡

    self.oper_panel:setVisible(true)
    self.oper_panel.no_reply = true
    self.only_bu = true
    local oper_list = {chi=0,peng=0,gang=0,bu=0,hu=0,hd=0,guo=1}
    if bMustHu then
        has_oper = true
        oper_list.hu = 1
        oper_list.guo = 0
        self.bMustHu = true
    end
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
            -- oper_list.guo = 0
            self.hasHu = true
            if v == 6 then
                self.hasZiMo = true
            end
        elseif v == 101 then
            oper_list.hu = 1
            self.hu_type = 101
            oper_list.guo = 0
            has_oper = true
        elseif v == OPER_PENG then
            oper_list.peng = 1
            has_oper = true
            self.hasPeng = true
        elseif v == OPER_CHI_CARD then
            oper_list.chi = 1
            has_oper = true
        elseif v == OPER_GANG then
            oper_list.gang = 1
            has_oper = true
            self.hasGang = true
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
            self.hasTing = true
            oper_list.guo = 0
            for __,v in ipairs(self.hand_card_list[1]) do
                if v.type == "huopai" and v.sort == 0 then
                    oper_list.guo = 1
                end
            end
        elseif v == OPER_BI_HU then
            has_oper = true
            oper_list.hu = 1
            oper_list.guo = 0
            self.bMustHu = true
            log('OPER_BI_HU OPER_BI_HU OPER_BI_HU')
        end

        if v ~= 1 or v ~= 3 then
            self.only_bu = nil
        end
    end

    if self.bMustHu then
        self:addCardShadow(true)
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

    if (self.action_msg or self.is_treatResume) and max_oper > 1 then
        if #self.hand_card_list[1] == 14 then
            self.oper_pai_id = self.hand_card_list[1][14].card_id
        else
            if last_card_id then
                self.oper_pai_id = last_card_id
            else
                self.oper_pai_id = self.last_out_card or 1
            end
        end
        oper_pai = self:getCardById(1,self.oper_pai_id, "_stand")
        oper_pai:setPosition(cc.p(oper_pai:getPositionX()+90, oper_pai:getPositionY()+30))
        self.is_treatResume = false
    end
    print('显示操作哪张牌', self.oper_pai_id)

    if oper_list.guo==1 and has_oper then
        if oper_list.hu == 1 then
            log('要过胡')
            oper_btn_list[1].opt_type = "guo_hu"
        else
            oper_btn_list[1].opt_type = "guo"
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
    end

    if oper_list.chi==1 then
        oper_btn_list[1].opt_type = "chi"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_chi_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
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
            local lipais_id = self:getHandCardLipaisId()
            if lipais_id and #lipais_id == 1 then
                if kg_cards and #kg_cards > 0 then
                    for i,v in ipairs(kg_cards) do
                        if v == lipais_id[1] then
                            table.remove(kg_cards,i)
                        end
                    end
                end
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
        self.btnGang = oper_btn_list[1]
        table.remove(oper_btn_list, 1)
    end
    if oper_list.hu==1 then
        oper_btn_list[1].opt_type = "hu"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_hu_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if #oper_btn_list >= 6 then
            oper_btn_list[1]:setScale(1.3)
        end
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
        --听牌后出牌
        if self.can_opt and self.ting_status then
            self.can_opt = nil

            self:runAction(cc.Sequence:create(cc.DelayTime:create(self.TingAutoOutCard), cc.CallFunc:create(function()
                if last_card_id then
                    self:sendOutCards(last_card_id)

                    -- self:setImgGuoHuIndexVisible(1, false)
                    self:setImgGuoPengIndexVisible(1, false)
                else
                    local card = self.hand_card_list[1][#self.hand_card_list[1]]
                    if card then
                        self:sendOutCards(card.card_id)

                        -- self:setImgGuoHuIndexVisible(1, false)
                        self:setImgGuoPengIndexVisible(1, false)
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
    if self.can_opt and
        self.ting_tip_layer and
        not self.ting_status
        then
        -- 没有报听
        if oper_list.ting ~= 1 then
            return
        end

        local hand_list = {}
        local group_list = {}
        local j = 1
        while j <= #self.hand_card_list[1] do
            local v = self.hand_card_list[1][j]
            if v then
                if v.sort == 0 or v.sort == 1 then
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
        local left_cards = self.MJLogic.copyArray(MJScene.CardNum)
        for i,v in ipairs(out_list) do
            left_cards[v] = left_cards[v] or 4
            left_cards[v] = left_cards[v]  - 1
        end

        log('晋中拐三角听牌')
        self.ting_list = {}


        for i, v in ipairs(hand_list) do
            if not self.ting_list[v] then
                local hands = clone(hand_list)
                table.remove(hands, i)

                local hu_list = {}
                local ting_list = self.MJLogic.CetTingCards(hands, group_list, self.wang_cards[1])
                if ting_list and #ting_list > 0 then
                    for i ,v in pairs(ting_list) do
                        -- if left_cards[v] > 0 then
                            hu_list[#hu_list+1] = {v,left_cards[v]}
                        -- end
                    end
                end
                if hu_list and #hu_list > 0 then
                    self.ting_list[v] = hu_list
                end
            end
        end

        self:removeTingArrow()
        if not self.hand_card_list[1] or not self.hand_card_list[1][14] then
            return
        end
        local card_size = self.hand_card_list[1][14]:getContentSize()
        for k, __ in pairs(self.ting_list) do
            for __, v in ipairs(self.hand_card_list[1]) do
                if v.sort == 1 and v.card_id == k and not v.ting_ar then
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

function MJScene:initResultUI(rtn_msg)
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

    local hu_type_name ={
        [ self.MJLogic.HU_NORMAL       ] = '堆胡',
        [ self.MJLogic.HU_QIXIAODUI    ] = '七小对',
        [ self.MJLogic.HU_YITIAOLONG   ] = '一条龙',
        [ self.MJLogic.HU_QINGYISE     ] = '清一色',
        [ self.MJLogic.HU_HAOQIXIAODUI ] = '豪华七小对',
        [ self.MJLogic.HU_SHISANYAO    ] = '十三幺',

        [ self.MJLogic.HU_MENQING      ] = '门清',
        [ self.MJLogic.HU_KANZHANG     ] = '坎张',
        [ self.MJLogic.HU_BIANZHANG    ] = '边张',
        [ self.MJLogic.HU_DIAOZHANG    ] = '吊张',
        [ self.MJLogic.HU_DUANYAO      ] = '断幺',
        [ self.MJLogic.HU_COUYISE      ] = '凑一色',
        [ self.MJLogic.HU_FENGYISE     ] = '风一色',
        [ self.MJLogic.HU_PENGPENGHU   ] = '碰碰胡',
        [ self.MJLogic.HU_HOST         ] = '庄家',
    }
    -- print('------------------------')
    -- dump(rtn_msg)
    --lianHost
    -- print('------------------------')

    self:setRoomNumber(tolua.cast(ccui.Helper:seekWidgetByName(node, "fanghao"), "ccui.Text"))

    local index_list = {1,2,3,4}
    -- local diangangNum = {0,0,0,0}
    -- for i,v in ipairs(rtn_msg.players) do
    --     for ii=1,#v.groups do
    --         local count = 0
    --         for __,group in pairs(v.groups[ii]) do
    --             count = count + 1
    --             if count >= 5 then
    --                 if v.groups[ii]["5"] == 1 then
    --                     if v.groups[ii].last_user ~= v.index then
    --                         diangangNum[v.groups[ii].last_user] = diangangNum[v.groups[ii].last_user] + 1
    --                     end
    --                 end
    --                 break
    --             end
    --         end
    --     end
    -- end
    table.sort( rtn_msg.players, function(x,y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg.players) do
        local play_index = self:indexTrans(v.index)
        local sortIndex = self:setResultIndex(play_index)
        index_list[sortIndex] = nil
        local play = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")

        self:initResultUIPlayer(v,node,index_list,rtn_msg)

        local str = nil
        local dh_lbl = tolua.cast(ccui.Helper:seekWidgetByName(play, "dianpao"), "ccui.Text")

        -- if diangangNum[i] > 0 then
        --     str = diangangNum[i].."点杠"
        -- end
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
        -- 明杠 暗杠 胡的牌型 胡的方式
        local gangStr = ''
        if mingNum ~= 0 then
            gangStr = gangStr or ""
            gangStr = gangStr.."  "..mingNum.."明杠"
        end
        if anNum ~= 0 then
            gangStr = gangStr or ""
            gangStr = gangStr.."  "..anNum.."暗杠"
        end

        local huTypeStr = ''
        if v.hu_types and #v.hu_types > 0 then
            huTypeStr = huTypeStr or ""
            for __, ht in ipairs(v.hu_types) do
                if not hu_type_name[ht] then
                    print('此处应有值,胡牌类型', tostring(ht))
                end
                if ht > 4 and ht < 18 then
                    huTypeStr = huTypeStr.."  "..hu_type_name[ht]
                end
            end
        end

        if v.hu_types and #v.hu_types > 0 then
            huTypeStr = huTypeStr or ""
            for __, ht in ipairs(v.hu_types) do
                if not hu_type_name[ht] then
                    print('此处应有值,胡牌类型', tostring(ht))
                end
                if ht <= 4 or ht >= 18 then
                    huTypeStr = huTypeStr.."  "..hu_type_name[ht]
                end
            end
        end

        if string.len(huTypeStr) == 0 then
            huTypeStr = '烂胡'
        end

        local bHu = false
        if v.is_zimo == 1 then
            str = str or ""
            str = str.."  自摸"
            bHu = true
        elseif v.is_dianpao == 1 then
            str = str or ""
            str = str.."  点炮"
        elseif v.is_jiepao == 1 then
            str = str or ""
            str = str.."  吃胡"
            bHu = true
        end
        if v.is_qianggang == 1 then
            str = str or ""
            str = str.."  抢杠"
            bHu = true
        end

        if bHu then
            str = str or ''
            str = gangStr .. ' ' .. huTypeStr .. str
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
        pos.x = pos.x + 170
        pos.y = pos.y - 20
        self:resultCard(v,node,pos)
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node,"play"..v):setVisible(false)
        end
    end

    self:setShareBtn(rtn_msg,node)
end

function MJScene:GetGangPai()
    local hand_list = {}
    local group_list = {}
    local j = 1
    while j <= #self.hand_card_list[1] do
        local v = self.hand_card_list[1][j]
        if v then
            log(v.sort)
            log(v.type)
            if v.sort == 0 or v.sort == 1 then
                hand_list[#hand_list+1] = v.card_id
                j = j+1
            else
                local list = {}
                local k =0
                while k < 3 do
                    log((k+j))
                    list[#list+1] = self.hand_card_list[1][k+j].card_id
                    k = k+1
                end
                j = j+k
                table.sort(list)
                group_list[#group_list+1] = list
            end
        end
    end


    local tGroupGang = self.MJLogic.GetGroupGangpai(hand_list, group_list)

    local tGang =  self.MJLogic.GetGangPai(hand_list)

    for i , v in pairs(tGroupGang) do
        table.insert(tGang,v)
    end

    return tGang
end

function MJScene:setLastJu(lnTotal, lnCur)
    -- log(lnTotal ..' @@@@@@@@@@@@@@@ ' .. lnCur)
    if self.is_playback then
        self.quan_lbl:setVisible(true)
        self.quan_lbl:setString("第"..lnCur.."局")
    else
        if lnTotal >= 100 then
            self.quan_lbl:setString('剩余 ' .. tostring(lnTotal - lnCur - 100) .. '圈')
            --剩   圈
            -- tolua.cast(ccui.Helper:seekWidgetByName(self.quan_lbl, "Text_1"), "ccui.Text"):setString('剩   圈')
        else
            self.quan_lbl:setString('剩余 ' .. tostring(lnTotal - lnCur) .. '局')
            --剩   局
            -- tolua.cast(ccui.Helper:seekWidgetByName(self.quan_lbl, "Text_1"), "ccui.Text"):setString('剩   局')
        end
    end
end

function MJScene:getHuImg()
    local hu_img={}
    hu_img[self.MJLogic.HU_NORMAL] = 5       --平胡
    hu_img[self.MJLogic.HU_QIXIAODUI] = 6    --七小对
    hu_img[self.MJLogic.HU_YITIAOLONG] = 23  --一条龙''
    hu_img[self.MJLogic.HU_QINGYISE] = 7     --清一色
    hu_img[self.MJLogic.HU_HAOQIXIAODUI] = 11--豪七对
    hu_img[self.MJLogic.HU_SHISANYAO] = 22   --十三妖''

    hu_img[self.MJLogic.HU_HOST       ]= 100  -- 庄家
    hu_img[self.MJLogic.HU_KANZHANG   ]= 104  -- 坎张(夹中)
    hu_img[self.MJLogic.HU_BIANZHANG  ]= 105  -- 边张(边夹)
    hu_img[self.MJLogic.HU_DIAOZHANG  ]= 106  -- 吊张(单吊)
    hu_img[self.MJLogic.HU_MENQING    ]= 109  -- 门清
    hu_img[self.MJLogic.HU_DUANYAO    ]= 110  -- 断幺(胡牌无幺九)
    hu_img[self.MJLogic.HU_FENGYISE   ]= 111  -- 风一色(全风牌)
    hu_img[self.MJLogic.HU_COUYISE    ]= 112  -- 凑一色(风牌+一色)
    hu_img[self.MJLogic.HU_PENGPENGHU ]= 113  -- 碰碰胡(须对倒胡)
    hu_img[30] = 30                     --自摸
    return hu_img
end

function MJScene:setHuData(hu_types)
    for i , v in pairs(hu_types) do
        if v == self.MJLogic.HU_KANHU then
            hu_types[i] = self.MJLogic.HU_NORMAL
        end
    end

    return hu_types
end

-- 得到胡牌分最高的两种类型
-- 自己自摸 显示自摸 别人显示自摸
-- 自己接炮 抢杠胡 没有番只显示胡，别人只显示胡，有番，所以人显示番型图片，
-- 如果多个番同时存在，只显示最大的两个番
-- by 严茂
function MJScene:getHuTye(hu_types)
    local hu = {}
    for i , v in ipairs(hu_types) do
        local huCell = {}
        huCell.type = hu_types[i]
        print('胡牌类型',huCell.type)
        huCell.score = self.MJLogic.HUSCORES[hu_types[i]]
        print('胡牌分数',huCell.score)
        hu[#hu+1] = huCell
    end
    local function huTypeSort(a,b)
        if a.score > b.score then
            return true
        end
        return false
    end
    table.sort(hu,huTypeSort)

    local huType = {}
    for i, v in ipairs(hu) do
        huType[#huType+1] = hu[i].type
    end
    return huType
end

function MJScene:playHuAni(rtn_msg)
    -- print('MJScene:playHuAni')
    -- dump(rtn_msg)
    -- print('MJScene:playHuAni END')
    local old_ui = self:getChildByTag(1369)
    if old_ui then
        old_ui:removeFromParent(true)
    end

    -- local play_sound = true
    -- local hu_Ani = {}
    for __, player in ipairs(rtn_msg.players) do
        local hu_type = nil

        local hu_Ani = {}
        if player.hu_types and #player.hu_types >0 then
            player.hu_types = self:setHuData(player.hu_types)
            local hu_types = self:getHuTye(player.hu_types)
            -- dump(hu_types)
            hu_type = hu_types[1]
            hu_Ani[1] = hu_types[1]
            hu_Ani[2] = hu_types[2]
            -- print(tostring('第一个胡牌类型'),hu_Ani[1])
            -- print(tostring('第二个胡牌类型'),hu_Ani[2])
        else
            hu_type = self.MJLogic.HU_NORMAL
        end

        -- print('胡牌 ')
        -- dump(player.hu_types)
        -- print('单胡')
        -- dump(hu_type)
        -- print('胡牌 END')

        if player.is_zimo == 1 then
            hu_type = 30
        end

        local hu_img = self:getHuImg()

        if hu_type then
            hu_type = hu_img[hu_type]
        end
        if hu_Ani[1] then
            hu_Ani[1] = hu_img[hu_Ani[1]]
        end
        if hu_Ani[2] then
            hu_Ani[2] = hu_img[hu_Ani[2]]
        end
        -- hu_type = 999
        -- hu_Ani[1] = hu_img[hu_Ani[1]]
        -- hu_Ani[2] = hu_img[hu_Ani[2]]
        -- print('第一张要显示的图',hu_Ani[1])
        -- print('第二张要显示的图',hu_Ani[2])


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

        print('``````````````````` ' .. tostring(player.hu_cards[1]))
        if hu_type == 30 and index == 1 and player.hu_cards[1] then
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
            -- 点炮
            self:playdianpao(pos)
            self.wait_over = 2
        end

        if hu_type and player.hu_cards and #player.hu_cards > 0 then
            local index = self:indexTrans(player.index)
            local old_card_list = {}
            local is_zimo = nil
            local sp = cc.Sprite:create("ui/qj_mj/hn"..hu_type..".png")
            sp = sp or cc.Sprite:create("ui/qj_mj/hn5.png")
            local sp_size = sp:getContentSize()
            local sp_scale = 1
            if index ~= 1 then
                sp_scale = 0.8
                sp_size.width = sp_size.width*sp_scale
                sp_size.height = sp_size.height*sp_scale
            end
            -- log('AAAAAAAAAAAAAAAAAAAAA')
            AudioManager:playDWCSound("sound/mj/mj_op.mp3")
            if hu_Ani and #hu_Ani >= 2 then
                -- log('GGGGGGGGGGGGGGGG')
                local ani1 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[1]..".png")
                local ani2 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[2]..".png")
                if not ani1 then
                    ani1 = ani2
                    ani1 = ani1 or sp

                    ani2 = nil

                    log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
                end

                local sp_size = ani1:getContentSize()
                local sp_scale = 1
                -- log('FFFFFFFFFFFFFFFFFFFFF')
                if index ~= 1 then
                    sp_scale = 0.8
                    sp_size.width = sp_size.width*sp_scale
                    sp_size.height = sp_size.height*sp_scale
                end
                -- log('EEEEEEEEEEEEEEEEEE')
                local hu_pos = cc.p(self.open_card_pos_list[index].x, self.open_card_pos_list[index].y)
                ani1:setPosition(hu_pos)
                ani1:setScale(3.5)
                self:addChild(ani1, 10000)
                -- log('CCCCCCCCCCCCCCCCCCCCCC')
                ani1:runAction(cc.Sequence:create(cc.Spawn:create(cc.FadeTo:create(0.2, 127), cc.ScaleTo:create(0.2, 4.5)),
                    cc.Spawn:create(cc.FadeIn:create(0.05), cc.ScaleTo:create(0.05, sp_scale)), cc.DelayTime:create(0.5),
                    cc.CallFunc:create(function()
                        ani1:removeFromParent(true)
                    end),
                    cc.CallFunc:create(function()
                        if ani2 then
                            local ani2 = cc.Sprite:create("ui/qj_mj/hn"..hu_Ani[2]..".png")
                            ani2:setPosition(hu_pos)
                            ani2:setScale(3.5)
                            self:addChild(ani2,10000)
                            ani2:runAction(
                                cc.Sequence:create(
                                    cc.Spawn:create(
                                        cc.FadeTo:create(0.2, 127),
                                        cc.ScaleTo:create(0.2, 4.5)
                                        ),
                                    cc.Spawn:create(
                                        cc.FadeIn:create(0.05),
                                        cc.ScaleTo:create(0.05, sp_scale)),
                                    cc.DelayTime:create(1),
                                    cc.RemoveSelf:create()
                                ))
                        end
                    end)
                    ))
                -- log('BBBBBBBBBBBBBBBBBBBBBBBBB')
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

function MJScene:dongZhangCleanGuoHu()
    if not self.isZiMoIfPass then
        self:setImgGuoHuIndexVisible(1,false)
        self:setImgGuoLongIndexVisible(1,false)
    end
end

function MJScene:pengGangReplayCard(param)
    local direct = param.direct
    local card_ids = param.card_ids
    local bu_gang = param.bu_gang
    local sort_max = param.sort_max
    local last_i = param.last_i
    local opt_type = param.opt_type
    for i, v_id in ipairs(card_ids) do
        for ii, v in ipairs(self.hand_card_list[direct]) do
            if v.card_id == v_id and (v.sort == 0 or v.sort == 1 or v.sort == -1 or (bu_gang and v.sort ~= sort_max)) then
                v.card_id = v_id
                v.sort = sort_max
                last_i = ii
                if #card_ids >= 3 and opt_type ~= 14 then
                    if i == #card_ids then
                        table.remove(self.hand_card_list[direct], ii)
                        v:removeFromParent(true)
                    end
                end
                break
            end
        end
    end
    return last_i
end

function MJScene:penGangCard(param)
    local direct = param.direct
    local card_ids = param.card_ids
    local bu_gang = param.bu_gang
    local sort_max = param.sort_max
    local last_i = param.last_i
    local opt_type = param.opt_type
    if self.is_playback then
        return self:pengGangReplayCard(param)
    end
    for i, v_id in ipairs(card_ids) do
        for ii, v in ipairs(self.hand_card_list[direct]) do
            if v.card_id == v_id and (v.sort == 0 or (bu_gang and v.sort ~= sort_max)) then
                v.card_id = v_id
                v.sort = sort_max
                last_i = ii
                if #card_ids >= 3 and opt_type ~= 14 then
                    if i == #card_ids then
                        table.remove(self.hand_card_list[direct], ii)
                        v:removeFromParent(true)
                    end
                end
                break
            end
        end
    end
    return last_i
end

function MJScene:getHandCardLipaisId()
    local lipais_id = {}
    for i,v in ipairs(self.hand_card_list[1]) do
        if v.type == "lipai" then
            lipais_id[#lipais_id+1] = v.card_id
        end
    end
    return lipais_id
end

function MJScene:getWanFaStr()
    local room_info = RoomInfo.params

    self.game_name = '晋中拐三角\n'

    local str = nil
    str = self.game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju-100).."圈\n"
    else
        str = str..room_info.total_ju.."局\n"
    end

    str = str .. (RoomInfo.people_total_num or 3).."人\n"
    -- 房间信息
    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸\n' or '')
    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙\n' or '')
    str = str .. (room_info.isDaiKanSuanKan and '带砍算砍胡\n' or '')
    str = str .. (room_info.isLiSi and '立四张\n' or '')

    self.isLiSi = room_info.isLiSi

    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    log(str)
    return str
end

return MJScene
