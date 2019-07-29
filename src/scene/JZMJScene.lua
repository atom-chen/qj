local MJBaseScene = require('scene.MJBaseScene')

local MJScene = class("MJScene",MJBaseScene)

function MJScene.create(param_list)
    log('晋中')
    MJBaseScene.removeUnusedRes()

    local mj = MJScene.new(param_list)

    local scene = cc.Scene:create()
    scene:addChild(mj)
    return scene
end

function MJScene:setMjSpecialData()
    self.haoZi = 'ui/qj_mj/dt_play_haozi_img.png'
    self.haoZiDi = 'ui/qj_mj/haozi.png'
    self.curLuaFile = 'scene.JZMJScene'

    self.mjTypeWanFa = 'jz'

    self.RecordGameType = RecordGameType.JZ

    self.mjGameName = '晋中麻将'
end

function MJScene:loadMjLogic()
    self.MJLogic = require('logic.mjjz_logic')
end

function MJScene:PassTing(value)
    return false
end

function MJScene:treatResume(rtn_msg)
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
                    self.node:addChild(pai)
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

function MJScene:createLayerMenu(room_info)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end

    self:setOwnerName(room_info)

    local ui_prefix = ""

    ui_prefix = 'pm'

    local starttime = os.clock()

    local node = nil
    if self.is_3dmj then
        node = tolua.cast(cc.CSLoader:createNode("ui/Roompm3d.csb"), "ccui.Widget")
    else
        node = tolua.cast(cc.CSLoader:createNode("ui/Roompm.csb"), "ccui.Widget")
    end
    self:addChild(node)

    ccui.Helper:seekWidgetByName(node,"koupai"):setVisible(false)
    ccui.Helper:seekWidgetByName(node, "pnPiaoFen"):setVisible(false)
    local img_bg = ccui.Helper:seekWidgetByName(node, "Panel_1"):getChildByName("Image_2")
    local img_bg_title = tolua.cast(img_bg:getChildByName("img_title"), "ccui.ImageView")
    img_bg_title:setVisible(not ios_checking)
    if self.is_3dmj then
        img_bg_title:loadTexture("ui/qj_bg/3d/3d_jz.png")
        img_bg:loadTexture(self.img_3d[self.zhuobu])
    else
        img_bg_title:loadTexture("ui/qj_bg/2d/2d_jz.png")
        img_bg:loadTexture(self.img_2d[self.zhuobu])
    end
    self.img_bg = img_bg
    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node
    local endtime = os.clock()
    print(string.format("加载Roommp cost time  : %.4f", endtime - starttime))

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
        if self.show_pai_out then
            self.show_pai_out:removeFromParent(true)
            self.show_pai_out = nil
        end

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
                local function callFunc()
                    if self.hasHu or self.hasGang then
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

    self.wanfa_str = self:getWanFaStr()
    -- 房间信息，局数，扎鸟等
    self:setShuoMing(self.wanfa_str)

    self.is13Yao = room_info.is13Yao

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
end


function MJScene:resetOperPanel(oper, haidi_ting, last_card_id, msgid, kg_cards, bMustHu)
    -- logUp('MJScene:resetOperPanel')
    -- logUp('操作ID ')
    -- -- logUp(oper)
    -- dump(oper)

    -- logUp('MsgID')
    -- logUp(msgid)
    -- logUp('kg_cards')
    -- logUp(kg_cards)

    -- logUp('bMustHu')
    -- logUp(tostring(bMustHu))
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

    if oper_list.guo==1 and has_oper then
        if oper_list.hu == 1 then
            oper_btn_list[1].opt_type = "guo_hu"

            -- log(' oper_btn_list[1].opt_type = "guo_hu" ')
        else
            oper_btn_list[1].opt_type = "guo"

            -- log(' oper_btn_list[1].opt_type = "guo" ')
        end
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_guo_btn.png")
        --oper_btn_list[1]:loadTextureNormal("ui/Majiang/Room"..ui_prefix.."/majiang/guo.png")
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
        local left_cards = self.MJLogic.copyArray(MJScene.CardNum)
        for i,v in ipairs(out_list) do
            left_cards[v] = left_cards[v] or 4
            left_cards[v] = left_cards[v]  - 1
        end

        log('晋中听牌')
        self.ting_list = {}

        for i, v in ipairs(hand_list) do
            if not self.ting_list[v] then
                local hands = clone(hand_list)
                table.remove(hands, i)

                local hu_list = {}
                local ting_list = self.MJLogic.CetTingCards(hands, group_list, self.wang_cards[1],self.is13Yao)
                -- print('-------------------------')
                -- dump(ting_list)
                -- print('-------------------------')
                --local ting_list = {}
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

function MJScene:getWanFaStr()
    local room_info = RoomInfo.params

    self.game_name = '晋中\n'

    local str = nil
    str = self.game_name
    if room_info.total_ju > 100 then
        str = str..(room_info.total_ju-100).."圈\n"
    else
        str = str..room_info.total_ju.."局\n"
    end

    str = str .. (RoomInfo.people_total_num or 4).."人\n"
    str = str .. (room_info.isGuoLongHuLong and '过龙只能胡龙\n' or '')
    str = str .. (room_info.isLiuJuGenGang and '流局跟杠\n' or '')
    str = str .. (room_info.isZiMoIfPass and '过胡只能自摸\n' or '')
    str = str .. (room_info.is13Yao and '十三幺\n' or '')
    str = str .. (room_info.isCanHuanGang and '可缓杠\n' or '')
    str = str .. (room_info.isPassPeng and '过手碰\n' or '')
    dump(room_info)

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
