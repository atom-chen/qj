-- total error 19 lines ylqj/1.0.21012

local MJBaseScene = require('scene.MJBaseScene')

local MJScene = class("MJScene",MJBaseScene)

function MJScene.create(param_list)
    gt.printTime("MJScene.create")
    log('推倒胡')
    MJBaseScene.removeUnusedRes()

    local mj = MJScene.new(param_list)
    local scene = cc.Scene:create()
    scene:addChild(mj)
    gt.printTime("cc.Scene:create end")
    return scene
end

function MJScene:setMjSpecialData()
    self.haoZi = 'ui/qj_mj/dt_play_haozi_img.png'
    self.haoZiDi = 'ui/qj_mj/haozi.png'
    self.curLuaFile = 'scene.TDHMJScene'

    self.mjTypeWanFa = 'tdhmj'

    self.RecordGameType = RecordGameType.TDH

    self.mjGameName = '推倒胡'
end

function MJScene:loadMjLogic()
    self.MJLogic = require('logic.mjtdh_logic')
end

function MJScene:PassGang(value)
    return false
end

function MJScene:createLayerMenu(room_info)
    gt.printTime("MJScene:createLayerMenu")
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

    node:setContentSize(g_visible_size)

    ccui.Helper:doLayout(node)

    self.node = node

    ccui.Helper:seekWidgetByName(node,"koupai"):setVisible(false)
    local img_bg = ccui.Helper:seekWidgetByName(node, "Panel_1"):getChildByName("Image_2")
    local img_bg_title = tolua.cast(img_bg:getChildByName("img_title"), "ccui.ImageView")
    img_bg_title:setVisible(not ios_checking)
    if self.is_3dmj then
        img_bg_title:loadTexture("ui/qj_bg/3d/3d_tdh.png")
        img_bg:loadTexture(self.img_3d[self.zhuobu])
    else
        img_bg_title:loadTexture("ui/qj_bg/2d/2d_tdh.png")
        img_bg:loadTexture(self.img_2d[self.zhuobu])
    end
    self.img_bg = img_bg
    local endtime = os.clock()
    print(string.format("加载Roommp cost time  : %.4f", endtime - starttime))

    self.res3DPath = 'ui/qj_mj/3d'

    local starttime = os.clock()

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
                    if not self.can_opt then
                        self:setImgGuoHuIndexVisible(1, true)
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

    -- self.MJClickAction.closeClickSchedule()

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
                    if self.hasHu or self.hasTing then
                        return true
                    end
                end
                has_move = self.MJClickAction.End(self,xx,yy,preX,preY,sel_init_posx,has_move,callFunc)
            end
        end
    end)


    -- 剩于牌张数
    self.left_lbl = tolua.cast(ccui.Helper:seekWidgetByName(node, "zhangshu"), "ccui.Text")
    self.left_lbl:setString("-")

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

    self:setLastJu(self.total_ju, room_info.cur_ju)
    self.is_game_start = (room_info.status~=0)
    self.is_fangzhu = (room_info.qunzhu ~= 1 and self.my_index == 1)
    self.people_num = room_info.people_num or 4
    self.isGSHZ = room_info.isGSHZ or false
    self.rTGT   = room_info.rTGT or 0

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

    local piaofen = 0
    self.pnPiaoFen = tolua.cast(ccui.Helper:seekWidgetByName(node, "pnPiaoFen"), "ccui.Widget")
    self.pnPiaoFen:setVisible(false)
    self.btnPiaoFen = tolua.cast(ccui.Helper:seekWidgetByName(self.pnPiaoFen,"btnPiaoFen"),"ccui.Button")
    self.btnPiaoFen:addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self:sendReady(piaofen)
            self.pnPiaoFen:setVisible(false)
        end
    end)

    local piaofenBtnList = {
        tolua.cast(ccui.Helper:seekWidgetByName(self.pnPiaoFen,"0fen"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.pnPiaoFen,"fen1"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.pnPiaoFen,"fen2"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(self.pnPiaoFen,"fen3"),"ccui.Button"),
    }

    local function initPiaoFenShowOpt()
        local piaoFenList = {1,2,3}
        if room_info.isPiaoFen == 101 then
            piaoFenList = {1,2,3}
        elseif room_info.isPiaoFen == 102 then
            piaoFenList = {2,3,5}
        elseif room_info.isPiaoFen == 103 then
            piaoFenList = {2,5,8}
        end
        piaofenBtnList[2]:setTitleText(piaoFenList[1]..'分')
        piaofenBtnList[3]:setTitleText(piaoFenList[2]..'分')
        piaofenBtnList[4]:setTitleText(piaoFenList[3]..'分')
        self:setOpt(piaofenBtnList[1], false, piaofen == 0)
        self:setOpt(piaofenBtnList[2], false, piaofen == piaoFenList[1])
        self:setOpt(piaofenBtnList[3], false, piaofen == piaoFenList[2])
        self:setOpt(piaofenBtnList[4], false, piaofen == piaoFenList[3])
    end

    for i, v in ipairs(piaofenBtnList) do
        v:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i == 1 then
                    piaofen = 0
                elseif i == 2 then
                    if room_info.isPiaoFen == 101 then
                        piaofen = 1
                    elseif room_info.isPiaoFen == 102 then
                        piaofen = 2
                    elseif room_info.isPiaoFen == 103 then
                        piaofen = 2
                    end
                elseif i == 3 then
                    if room_info.isPiaoFen == 101 then
                        piaofen = 2
                    elseif room_info.isPiaoFen == 102 then
                        piaofen = 3
                    elseif room_info.isPiaoFen == 103 then
                        piaofen = 5
                    end
                elseif i == 4 then
                    if room_info.isPiaoFen == 101 then
                        piaofen = 3
                    elseif room_info.isPiaoFen == 102 then
                        piaofen = 5
                    elseif room_info.isPiaoFen == 103 then
                        piaofen = 8
                    end
                end
                initPiaoFenShowOpt()
            end
        end)
    end
    initPiaoFenShowOpt()

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

    self:setShuoMing(self.wanfa_str)

    -- 推倒胡
    ccui.Helper:seekWidgetByName(node, "Image_40"):setVisible(false)

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
    if room_info.isPiaoFen and room_info.isPiaoFen ~= 0 then
        self:setPiaoFenNum(room_info)
    end

    -- 准备相关
    if room_info.player_info and (room_info.player_info.hand_card or room_info.player_info.cards) then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:removeAllHandCard()
            self:treatResume(room_info)
        end
    end

    --游戏开始开心跳
    if self.is_game_start then
        if not self.is_playback then
            ymkj.setHeartInter(0)
        end
    else
        self:showTuoGuanTip()
    end

    self:setBtnsVisible()
    self:setEnterRoomIsStartStartHeadPos()

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

    local endtime = os.clock()
    gt.printTime("MJScene:createLayerMenu end")
end

function MJScene:checkIpWarn(is_click_see)
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
                local people_num = RoomInfo.getTotalPeopleNum()
                if count < people_num then
                    if is_click_see then
                        commonlib.showLocalTip("房间满人可查看")
                    end
                    return
                end

                log('people_num ' .. tostring(people_num) .. ' is_click_see ' .. tostring(is_click_see) .. ' self.piaoniao_mode ' .. tostring(self.piaoniao_mode))

                 if (people_num == 2 or people_num == 3 or people_num == 4) and not is_click_see then
                    if self.piaoFen and self.piaoFen > 100 then
                        if not self.hasPiaoFen then
                            self.pnPiaoFen:setVisible(true)
                            self.pnPiaoFen:setEnabled(true)
                        end
                        commonlib.showbtn(self.jiesanroom)
                        commonlib.showShareBtn(self.share_list)
                        self.btnQuick:setVisible(false)
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

function MJScene:setBtnsAfterLeave()
    for i, v in ipairs(self.share_list) do
        v:setVisible(true)
        v:setTouchEnabled(true)
    end
    if self.pnPiaoFen:isVisible() then
        self.pnPiaoFen:setVisible(false)
        self.pnPiaoFen:setEnabled(false)
    end
    self.jiesanroom:setVisible(true)
    self.jiesanroom:setTouchEnabled(true)
    self:setBtnQuickStart()
    for i, play in ipairs(self.player_ui) do
        play:getChildByName("zhunbei"):setVisible(false)
    end
end

function MJScene:onRcvReady(rtn_msg)
    if rtn_msg.isPiaoFen and rtn_msg.isPiaoFen ~= 0 then
        self:setPiaoFen()
        self.is_game_start = true
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
    userData.piao_fen = rtn_msg.piao_fen
    if self.player_ui[index] then

        self.player_ui[index]:getChildByName("zhunbei"):setVisible(true)
        -- 设置分数
        print('准备后设置分数')
        print(userData.score)
        print(userData.piao_fen)
        tolua.cast(ccui.Helper:seekWidgetByName(self.player_ui[index],"lab-jinbishu"), "ccui.Text"):setString(commonlib.goldStr(rtn_msg.score+1000))
        AudioManager:playDWCSound("sound/ready.mp3")
    end
end

function MJScene:setPiaoFenNum(rtn_msg)
    local playerinfo_list = {rtn_msg.player_info}
    for i, v in ipairs(rtn_msg.other) do
        playerinfo_list[i + 1] = v
    end

    for i, v in ipairs(playerinfo_list) do
        local idx         = self:indexTrans(v.index)
        local userData    = PlayerData.getPlayerDataByServerID(v.index)
        userData.piao_fen = v.piao_fen
        if v.piao_fen and v.piao_fen ~= 0 then
            local piaoFenNum = self.player_ui[self:indexTrans(v.index)]:getChildByName("PJN")
            piaoFenNum:setString("+"..v.piao_fen)
        end
    end
    local is_start = rtn_msg.cur_id and #rtn_msg.player_info.hand_card > 0 and rtn_msg.status ~= 102
    if is_start then
        for i,v in ipairs(playerinfo_list) do
            if v.piao_fen ~= 0 then
                self.player_ui[self:indexTrans(v.index)]:getChildByName("PJN"):setVisible(true)
            end
        end
    else
        if playerinfo_list[1].ready then
            commonlib.showShareBtn(self.share_list)
            commonlib.showbtn(self.jiesanroom)
            self.btnQuick:setVisible(false)
        end
    end
end

function MJScene:onRcvMjGameStartOwnerData()
    for i,v in ipairs(self.player_ui) do
        local userData = PlayerData.getPlayerDataByClientID(i)
        if userData then
            if userData.piao_fen and userData.piao_fen ~= 0 then
                local piaoFenNum = v:getChildByName("PJN")
                piaoFenNum:setVisible(true)
                piaoFenNum:setString("+"..userData.piao_fen)
            end
        end
        if self.piaoFen and self.piaoFen > 0 and self.piaoFen < 10 then
            local piaoFenNum = v:getChildByName("PJN")
            piaoFenNum:setVisible(true)
            piaoFenNum:setString("+"..self.piaoFen)
            if userData then
                userData.piao_fen = self.piaoFen
            end
        end
    end
end

function MJScene:setPiaoFen()
    self:setBtnPiaoFenVisible()

    commonlib.closeQuickStart(self)
    self.pnPiaoFen:setVisible(true)
    self.pnPiaoFen:setEnabled(true)

    self.hasPiaoFen = true
end

function MJScene:setBtnPiaoFenVisible()
    self.btnQuick:setVisible(false)

    commonlib.showShareBtn(self.share_list)
    self.btnjiesan:setVisible(false)
    self.wanfa:setVisible(true)
    commonlib.showbtn(self.jiesanroom)

    self:setWenHaoListVisible()

    self.btnClubInvite:setVisible(false)
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

    local hu_type_name = {"平胡","七小对","一条龙","清一色","豪华七小对","十三幺"}

    local index_list = {1,2,3,4}

    local diangangNum = {0,0,0,0}
    for i,v in ipairs(rtn_msg.players) do
        local isHU = false
        if v.is_zimo == 1 or v.is_jiepao == 1 or v.is_qianggang ==1 then
            isHU = true
        end
        for ii=1,#v.groups do
            local count = 0
            for __,group in pairs(v.groups[ii]) do
                count = count + 1
                if count >= 5 then
                    if self.isGSHZ then
                        if isHU then
                            if v.groups[ii]["5"] == 1 then
                                if v.groups[ii].last_user ~= v.index then
                                    diangangNum[v.groups[ii].last_user] = diangangNum[v.groups[ii].last_user] + 1
                                end
                            end
                        end
                    else
                        if v.groups[ii]["5"] == 1 then
                            if v.groups[ii].last_user ~= v.index then
                                diangangNum[v.groups[ii].last_user] = diangangNum[v.groups[ii].last_user] + 1
                            end
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
        local sortIndex = self:setResultIndex(play_index, #rtn_msg.players)
        index_list[sortIndex] = nil
        local play = tolua.cast(ccui.Helper:seekWidgetByName(node,"play"..sortIndex), "ccui.ImageView")

        self:initResultUIPlayer(v,node,index_list,rtn_msg)

        if v.piao_fen and v.piao_fen ~= 0 then
            local piaofen = ccui.Helper:seekWidgetByName(play, "paozifen")
            piaofen:setVisible(true)
            piaofen:getChildByName("num"):setString(v.piao_fen)
        end

        local str = nil
        local dh_lbl = tolua.cast(ccui.Helper:seekWidgetByName(play, "dianpao"), "ccui.Text")

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

        if self.isGSHZ then
            if v.is_zimo == 1 or v.is_jiepao == 1 or v.is_qianggang == 1 then
                if mingNum ~= 0 then
                    str = str or ""
                    str = str.."  "..mingNum.."明杠"
                end
                if anNum ~= 0 then
                    str = str or ""
                    str = str.."  "..anNum.."暗杠"
                end
            end
        else
            if mingNum ~= 0 then
                str = str or ""
                str = str.."  "..mingNum.."明杠"
            end
            if anNum ~= 0 then
                str = str or ""
                str = str.."  "..anNum.."暗杠"
            end
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
            str = str.."  接炮"
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
    local ltHandCard = {}
    for i, v in pairs(self.hand_card_list[1]) do
        if v.sort == 0 then
            ltHandCard[#ltHandCard+1] = v.card_id
        end
    end
    return self.MJLogic.GetGangPai(ltHandCard)
end

function MJScene:getWanFaStr()
    local room_info = RoomInfo.params

    self.game_name = '推倒胡\n'

    local str = nil
    str = self.game_name
    str = str..room_info.total_ju.."局"..(RoomInfo.people_total_num or 4).."人\n"
    -- 报听-- 带风-- 只可自摸-- 改变听口不能杠-- 随机耗子-- 大胡-- 平胡
    str = str .. (room_info.isBaoTing and '报听\n' or '')
    str = str .. (room_info.isDaiFeng and '带风\n' or '')
    str = str .. (room_info.isZhiKeZiMo and '只可自摸\n' or '')
    str = str .. (room_info.isGBTKBNG and '改变听口不能杠\n' or '')
    str = str .. (room_info.isSJHZ and '随机耗子\n' or '')
    str = str .. (room_info.isDaHu and '大胡\n' or '')
    str = str .. (room_info.isPingHu and '平胡\n' or '')
    str = str .. (room_info.isQueYiMen and '缺一门\n' or '')
    str = str .. (room_info.isHPBXQM and '胡牌必须缺门\n' or '')
    str = str .. (room_info.isYHQ and '硬豪七\n' or '')
    str = str .. (room_info.isGSHZ and '杠随胡走\n' or '')
    if room_info.isPiaoFen then
        if room_info.isPiaoFen > 0 and room_info.isPiaoFen <= 10 then
            str = str .. '定飘' .. room_info.isPiaoFen .. '分\n'
        elseif room_info.isPiaoFen == 101 then
            str = str .. '飘123\n'
        elseif room_info.isPiaoFen == 102 then
            str = str .. '飘235\n'
        elseif room_info.isPiaoFen == 103 then
            str = str .. '飘258\n'
        end
    end

    if room_info.rTGT and room_info.rTGT ~= 0 then
        str = str .. '超时托管' .. room_info.rTGT .. '秒\n'
    end

    self.isDaHu = room_info.isDaHu
    self.isBaoTing = room_info.isBaoTing
    self.isHPBXQM = room_info.isHPBXQM
    self.piaoFen = room_info.isPiaoFen
    local room_type = nil
    if room_info.qunzhu == 0 then
        room_type = "(AA房)"
    elseif room_info.qunzhu == 1 then
        room_type = "(亲友圈房)"
    else
        room_type = "(房主房)"
    end
    str = str..room_type

    return str
end

function MJScene:showTuoGuanTip()
    if not self.rTGT or self.rTGT == 0 or self.is_playback then return end

    local msg = "此房间为托管房，超过" .. self.rTGT .. "秒不操作后将自动进入托管状态\n" ..
        "\n1.托管后，摸什么打什么，不做其他操作(吃、碰、杠等)。\n" ..
       "2.一局结束时若有人处于托管状态，则此房间立即自动解散。\n" ..
       "3.若房间内所有玩家均进入托管状态，则房间立即自动解散。"
    require('scene.DTUI')
    local csb  = DTUI.getInstance().csb_Tips
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")
    self:addChild(node, 9999, 10099)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)
    local exit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btnexit"), "ccui.Button")
    exit:setVisible(false)
    local tcontent = tolua.cast(ccui.Helper:seekWidgetByName(node, "tContent"), "ccui.Text") -- :setString(msg)
    tcontent:setVisible(false)

    local content = ccui.Text:create()
    content:setFontName("ui/zhunyuan.ttf")
    content:setFontSize(28)
    content:setColor(cc.c3b(165, 42, 42))
    content:setPosition(cc.p(g_visible_size.width * 0.5, g_visible_size.height * 0.5))
    node:addChild(content)
    content:setString(msg)

    local btnEnter = ccui.Helper:seekWidgetByName(node, "btEnter")
    local btCancel = ccui.Helper:seekWidgetByName(node, "btCancel")
    btCancel:setVisible(false)
    btnEnter:addTouchEventListener(
        function(__, eventType)
            if eventType == ccui.TouchEventType.ended then AudioManager:playPressSound()
                node:removeFromParent(true)
            end
        end
    )

    btnEnter:setPositionX(btnEnter:getParent():getContentSize().width / 2)
end

return MJScene
