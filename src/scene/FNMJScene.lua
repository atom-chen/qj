-- total error 19 lines ylqj/1.0.21012

local MJBaseScene = require('scene.MJBaseScene')

local MJScene = class("MJScene", MJBaseScene)

function MJScene.create(param_list)
    gt.printTime("MJScene.create")
    log('丰宁')
    MJBaseScene.removeUnusedRes()

    local mj    = MJScene.new(param_list)
    local scene = cc.Scene:create()
    scene:addChild(mj)
    gt.printTime("cc.Scene:create end")
    return scene
end

function MJScene:setMjSpecialData()
    self.haoZi      = 'ui/qj_mj/huier-fs8.png'
    self.haoZiDi    = 'ui/qj_mj/huier2-fs8.png'
    self.curLuaFile = 'scene.FNMJScene'

    self.mjTypeWanFa = 'fnmj'

    self.RecordGameType = RecordGameType.FN

    self.mjGameName = '丰宁'
end

function MJScene:loadMjLogic()
    self.MJLogic = require('logic.mjfn_logic')
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
    ui_prefix       = 'pm'

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

    ccui.Helper:seekWidgetByName(node, "koupai"):setVisible(false)
    local img_bg       = ccui.Helper:seekWidgetByName(node, "Panel_1"):getChildByName("Image_2")
    local img_bg_title = tolua.cast(img_bg:getChildByName("img_title"), "ccui.ImageView")
    img_bg_title:setVisible(not ios_checking)
    if self.is_3dmj then
        img_bg_title:loadTexture("ui/qj_bg/3d/3d_fengnong.png")
        img_bg:loadTexture(self.img_3d[self.zhuobu])
    else
        img_bg_title:loadTexture("ui/qj_bg/2d/2d_fengning.png")
        img_bg:loadTexture(self.img_2d[self.zhuobu])
    end
    self.img_bg   = img_bg
    local endtime = os.clock()
    print(string.format("加载Roommp cost time  : %.4f", endtime - starttime))

    self.res3DPath = 'ui/qj_mj/3d'

    local starttime = os.clock()

    ccui.Helper:seekWidgetByName(node, "pnPiaoFen"):setVisible(false)
    self.batteryProgress = ccui.Helper:seekWidgetByName(node, "battery")
    gt.refreshBattery(self.batteryProgress)
    self.signalImg = ccui.Helper:seekWidgetByName(node, "img_xinhao")

    self:setNonePeopleChair()

    self:setBtns()

    ccui.Helper:seekWidgetByName(node, "Image_tip"):setLocalZOrder(self.ZOrder.BEYOND_CARD_ZOREDER)

    -- 返回大厅
    self:setBtnJieSan()

    self.hand_card_list    = {}
    self.hand_card_list[1] = {}
    self.hand_card_list[2] = {}
    self.hand_card_list[3] = {}
    self.hand_card_list[4] = {}

    self.out_card_list    = {}
    self.out_card_list[1] = {}
    self.out_card_list[2] = {}
    self.out_card_list[3] = {}
    self.out_card_list[4] = {}

    -- 中间倒计时
    ccui.Helper:seekWidgetByName(node, "LeftLbl"):setVisible(false)
    ccui.Helper:seekWidgetByName(node, "LeftLbl_3d"):setVisible(false)
    if self.is_3dmj then
        self.watcher_lab = tolua.cast(ccui.Helper:seekWidgetByName(node, "LeftLbl_3d"), "ccui.Text")
    else
        self.watcher_lab = tolua.cast(ccui.Helper:seekWidgetByName(node, "LeftLbl"), "ccui.Text")
    end
    self.watcher_lab:setVisible(true)
    self.watcher_lab:setString("00")

    self.direct_img_cur = nil

    self:setPlayerHead()

    -- 吃碰杠胡操作面板
    local oper_ui = tolua.cast(cc.CSLoader:createNode("ui/Oper" .. ui_prefix .. ".csb"), "ccui.Widget")
    self:addChild(oper_ui, 10000)

    oper_ui:setContentSize(g_visible_size)

    ccui.Helper:doLayout(oper_ui)

    self.oper_panel = oper_ui:getChildByName("Panel_caozuo")
    self.oper_panel:setVisible(false)

    self.chi_panel = oper_ui:getChildByName("Panel_chi")
    self.chi_panel:setVisible(false)

    self.hua_panel = oper_ui:getChildByName("Panel_hua")
    -- 碰回调
    local function pengOptTreat()
        print("peng")
        local open_value = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]].card_id
        local index_list = {}
        for ii, vv in ipairs(self.hand_card_list[1] or {}) do
            if vv.sort == 0 and vv.card_id == open_value then
                index_list[#index_list + 1] = ii
            end
        end
        if #index_list >= 2 then
            local last_index = 0
            for t = 1, #self.hand_card_list[1] do
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
            ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(#open_value_list / 3)
            for i = 1, 3 do
                local btn = self.chi_panel:getChildByName("com" .. i)
                local vv  = open_value_list[i]
                if vv then
                    btn:setTouchEnabled(true)
                    btn:setVisible(true)

                    local color = math.floor(vv / 16)
                    if color == 0 then
                        color = ""
                    end

                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv % 16) .. ".png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/back1.png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):setScale(0.7)
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv % 16) .. ".png")

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

    local function huaOptTreat(open_value_list)
        -- 补花，只发送补的那张花牌过去
        if #open_value_list[1] == 1 then
            if #open_value_list == 1 then
                self:sendOperate(nil, 21, open_value_list[1])
            else
                self.hua_panel:setVisible(true)
                local img_bg = ccui.Helper:seekWidgetByName(self.hua_panel , "Image_4")
                img_bg:setScaleX(#open_value_list / 4)
                for i = 1, 4 do
                    local btn = self.hua_panel:getChildByName("hua" .. i)
                    btn:setPositionX(img_bg:getContentSize().width * (1 / (#open_value_list + 1) * i))
                    local vv  = open_value_list[i]
                    if vv then
                        btn:setTouchEnabled(true)
                        btn:setVisible(true)
                        local cards = clone(vv)
                        local color = math.floor(vv[1] / 16)

                        tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(cards[1] % 16) .. ".png")

                        btn:addTouchEventListener(function(sender, eventType)
                            if eventType == ccui.TouchEventType.ended then
                                AudioManager:playPressSound()
                                self:sendOperate(nil, 21, vv)
                                self.hua_panel:setVisible(false)
                            end
                        end)
                    else
                        btn:setTouchEnabled(false)
                        btn:setVisible(false)
                    end
                end
                local cancel_btn = ccui.Helper:seekWidgetByName(self.hua_panel, "btncancel")
                cancel_btn:setVisible(true)
                cancel_btn:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        self.hua_panel:setVisible(false)
                        self.oper_panel:setVisible(true)
                    end
                end)
            end
        -- 正常起手花 发送东南西北或中发白过去
        elseif #open_value_list == 1 then
            self:sendOperate(nil, 21, open_value_list[1])
        else
            self.chi_panel:setVisible(true)
            ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(#open_value_list / 3)
            for i = 1, 3 do
                local btn = self.chi_panel:getChildByName("com" .. i)
                local vv  = open_value_list[i]
                if vv then
                    btn:setTouchEnabled(true)
                    btn:setVisible(true)
                    local cards = clone(vv)
                    local color = math.floor(vv[1] / 16)
                    if color == 0 then
                        color = ""
                    elseif color == 4 then
                        color    = 3
                        cards[1] = 37
                        cards[2] = 38
                        cards[3] = 39
                    end

                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(cards[1] % 16) .. ".png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(cards[2] % 16) .. ".png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(cards[3] % 16) .. ".png")

                    btn:addTouchEventListener(function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            self:sendOperate(nil, 21, vv)
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

    local function keOptTreat(open_value_list)
        if #open_value_list == 1 then
            self:sendOperate(nil, 22, open_value_list[1])
        else
            self.chi_panel:setVisible(true)
            ccui.Helper:seekWidgetByName(self.chi_panel, "Image_4"):setScaleX(#open_value_list / 3)
            for i = 1, 3 do
                local btn = self.chi_panel:getChildByName("com" .. i)
                local vv  = open_value_list[i]
                if vv then
                    btn:setTouchEnabled(true)
                    btn:setVisible(true)

                    local color = math.floor(vv / 16)
                    if color == 0 then
                        color = ""
                    end

                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_1"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv % 16) .. ".png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/back1.png")
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_2"), "ccui.ImageView"):setScale(0.7)
                    tolua.cast(ccui.Helper:seekWidgetByName(btn, "Image_3"), "ccui.ImageView"):loadTexture(self.res3DPath .. "/img_cardvalue"..color..(vv % 16) .. ".png")

                    btn:addTouchEventListener(function(sender, eventType)
                        if eventType == ccui.TouchEventType.ended then
                            AudioManager:playPressSound()
                            self:sendOperate(nil, 22, vv)
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
    local function operCallback(opt_type, opt_card)
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
        self.hasHua  = false
        self.hasHu   = false
        self.hasTui  = false
        local treat  = nil
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
                {cmd   = NetCmd.C2S_MJ_DO_PASS_HU},
                {index = self.my_index},
            }
            if self.oper_panel.msgid then
                input_msg[#input_msg + 1] = {msgid = self.oper_panel.msgid}
            end
            ymkj.SendData:send(json.encode2(input_msg))

            commonlib.showTipDlg("当前可胡牌，您确定不胡吗？", function(ok)
                if ok then
                    operCallback("guo")
                    if not self.can_opt then
                        self:setImgGuoHuIndexVisible(1, true)
                    end
                else
                    self.hasHu   = true
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

            for i, card in pairs(self.hand_card_list[1]) do
                if not self.ting_list[card.card_id] or 0 == #self.ting_list[card.card_id] then
                    local card_shadow = card:getChildByName('card_shadow')
                    if not card_shadow and card.sort == 0 then
                        local card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
                        card_shadow:setAnchorPoint(0.05, 0.05)
                        card_shadow:setName('card_shadow')
                        if self.is_pmmj or self.is_pmmjyellow then
                            card_shadow:setAnchorPoint(0, 0)
                            local iCardSize       = card:getContentSize()
                            local iCardShadowSize = card_shadow:getContentSize()
                            card_shadow:setScaleX(iCardSize.width / iCardShadowSize.width)
                            card_shadow:setScaleY(iCardSize.height / iCardShadowSize.height)
                        end
                        self.hand_card_list[1][i]:addChild(card_shadow)
                    end
                end
            end
            ------------------------------------------------
            treat = true
        elseif opt_type == 'hua' then
            huaOptTreat(opt_card)
            treat = true
        elseif opt_type == 'ke' then
            keOptTreat(opt_card)
            -- self:sendOperate(nil, 22, opt_card[1])
            treat = true
        elseif opt_type == 'tui' then
            if self.isMPQT then
                self:sendOperate(nil, 23)
            else
                if self.btnTing then
                    self.btnTing:setVisible(false)
                end
                -- 获取听牌列表
                self.tdh_need_bTing = true

                for i, card in pairs(self.hand_card_list[1]) do
                    if not self.ting_list[card.card_id] or 0 == #self.ting_list[card.card_id] then
                        local card_shadow = card:getChildByName('card_shadow')
                        if not card_shadow and card.sort == 0 then
                            local card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
                            card_shadow:setAnchorPoint(0.05, 0.05)
                            card_shadow:setName('card_shadow')
                            if self.is_pmmj or self.is_pmmjyellow then
                                card_shadow:setAnchorPoint(0, 0)
                                local iCardSize       = card:getContentSize()
                                local iCardShadowSize = card_shadow:getContentSize()
                                card_shadow:setScaleX(iCardSize.width / iCardShadowSize.width)
                                card_shadow:setScaleY(iCardSize.height / iCardShadowSize.height)
                            end
                            self.hand_card_list[1][i]:addChild(card_shadow)
                        end
                    end
                end
            end
            treat = true
        end

        self:setTingTitleVisible(self.tdh_need_bTing)

        if not treat then
            self.oper_panel:setVisible(false)
        end
    end

    self:setOperBtn(operCallback)

    self.ting_list = {}

    self.my_sel_index        = nil
    self.my_sel_index_sceond = nil

    local sel_init_posx = nil
    local has_move      = nil
    self:setTouchEnabled(true)
    local preX = 0
    local preY = 0

    -- self.MJClickAction.closeClickSchedule()

    -- 点击按钮
    self:registerScriptTouchHandler(function(touch_type, xx, yy)
        if self.can_opt then
            if touch_type == "began" then
                local vaild = false
                vaild, sel_init_posx, preX, preY, has_move = self.MJClickAction.Began(self, xx, yy, preX, preY, sel_init_posx, has_move)
                return vaild
            elseif touch_type == "moved" then
                sel_init_posx, preX, preY, has_move = self.MJClickAction.Move(self, xx, yy, preX, preY, sel_init_posx, has_move)
            else
                local function callFunc()
                    if self.hasHu or self.hasTing or self.hasTui or self.hasHua then
                        return true
                    end
                end
                has_move = self.MJClickAction.End(self, xx, yy, preX, preY, sel_init_posx, has_move, callFunc)
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

    self.is_game_start = (room_info.status ~= 0)
    self.is_fangzhu    = (room_info.qunzhu ~= 1 and self.my_index == 1)
    self.people_num    = room_info.people_num or 4
    self.isGSHZ        = room_info.isGSHZ or false

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
    self.southPan = ccui.Helper:seekWidgetByName(node, "Img-zj")
    self.southPan:setVisible(false)

    -- 东南西北3d
    self.southPan3d = ccui.Helper:seekWidgetByName(node, "Img-zj_3d")
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

    -- 丰宁
    ccui.Helper:seekWidgetByName(node, "Image_40"):setVisible(false)

    local tingtip = tolua.cast(cc.CSLoader:createNode("ui/TingTip.csb"), "ccui.Widget")
    self:addChild(tingtip, 10000)
    tingtip:setContentSize(g_visible_size)
    ccui.Helper:doLayout(tingtip)

    self.ting_tip_layer          = tingtip:getChildByName("bg")
    self.ting_tip_layer.pai_list = {}
    for i = 1, 10 do
        local ting_item                 = {}
        local pai                       = tolua.cast(self.ting_tip_layer:getChildByName("pai"..i), "ccui.ImageView")
        ting_item.pos                   = cc.p(pai:getPosition())
        ting_item.num                   = tolua.cast(pai:getChildByName("num"), "ccui.Text")
        ting_item.ori_pai               = pai
        self.ting_tip_layer.pai_list[i] = ting_item
    end
    self.ting_tip_layer:setVisible(false)
    -- end

    self:tingTipOper()

    -- 王牌？  赖子牌?
    self.wang_cards = {room_info.wang, room_info.wang1, room_info.wang2}

    self.copy = (room_info.copy == 1)

    self:initImgGuoHuIndex()

    -- 准备相关
    if room_info.player_info and (room_info.player_info.hand_card or room_info.player_info.cards) then
        if not room_info.player_info.ready or room_info.status ~= 102 then
            self:removeAllHandCard()
            self:treatResume(room_info)
        end
    end

    -- 游戏开始开心跳
    if self.is_game_start then
        if not self.is_playback then
            ymkj.setHeartInter(0)
        end
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

function MJScene:getHuImg()
    local hu_img={}
    hu_img[1] = 5       --平胡
    hu_img[2] = 6    --七小对
    hu_img[3] = 23  --一条龙''
    hu_img[4] = 7     --清一色
    hu_img[5] = 11--豪七对
    hu_img[6] = 22   --十三妖''
    hu_img[30] = 30                     --自摸
    hu_img[109] = 109   --门清''
    hu_img[141] = 141   --干巴''
    hu_img[142] = 142   --大对''
    return hu_img
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

    for index = 2, 4 do
        if self.ting_tip_card[index] then
            self.ting_tip_card[index]:setVisible(false)
        end
    end

    self:continueGame(node, ccui.Helper:seekWidgetByName(node, "btn-jxyx"), rtn_msg)

    self:initResultAnQuanMa(node, rtn_msg)
    self:initResultTime(node, rtn_msg)

    self:initResultRoomID(node, rtn_msg)

    self:initResultWangFa(node)

    local hu_type_name = {[1] = "平胡", [2] = "七小对", [3] = "一条龙", [4] = "清一色",
        [5]   = "豪华七小对", [6] = "十三幺", [109] = "门清", [141] = "干巴",
        [142] = "大对"
    }

    local index_list = {1, 2, 3, 4}

    local diangangNum = {0, 0, 0, 0}
    for i, v in ipairs(rtn_msg.players) do
        local isHU = false
        if v.is_zimo == 1 or v.is_jiepao == 1 or v.is_qianggang == 1 then
            isHU = true
        end
        for ii = 1, #v.groups do
            local count = 0
            for __, group in pairs(v.groups[ii]) do
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
    table.sort(rtn_msg.players, function(x, y)
        return self:indexTrans(x.index) < self:indexTrans(y.index)
    end)
    for i, v in ipairs(rtn_msg.players) do
        local play_index      = self:indexTrans(v.index)
        local sortIndex       = self:setResultIndex(play_index)
        index_list[sortIndex] = nil
        local play            = tolua.cast(ccui.Helper:seekWidgetByName(node, "play" .. sortIndex), "ccui.ImageView")

        self:initResultUIPlayer(v, node, index_list, rtn_msg)

        local str    = nil
        local dh_lbl = tolua.cast(ccui.Helper:seekWidgetByName(play, "dianpao"), "ccui.Text")

        if v.dianpaoshu then
            str = v.dianpaoshu .. "点杠"
        end
        local mingNum = 0
        local anNum   = 0

        for ii = 1, #v.groups do
            local count = 0
            for __, group in pairs(v.groups[ii]) do
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
                    str = str .. "  " .. mingNum.."明杠"
                end
                if anNum ~= 0 then
                    str = str or ""
                    str = str .. "  " .. anNum.."暗杠"
                end
            end
        else
            if mingNum ~= 0 then
                str = str or ""
                str = str .. "  " .. mingNum.."明杠"
            end
            if anNum ~= 0 then
                str = str or ""
                str = str .. "  " .. anNum.."暗杠"
            end
        end

        if v.hu_types and #v.hu_types > 0 then
            str = str or ""
            for __, ht in ipairs(v.hu_types) do
                if ht > 4 and ht < 18 then
                    str = str .. "  " .. hu_type_name[ht]
                end
            end
        end

        if v.hu_types and #v.hu_types > 0 then
            str = str or ""
            for __, ht in ipairs(v.hu_types) do
                if ht <= 4 or ht >= 18 then
                    str = str .. "  " .. hu_type_name[ht]
                end
            end
        end

        if v.is_zimo == 1 then
            str = str or ""
            str = str .. "  自摸"
        elseif v.is_dianpao == 1 then
            str = str or ""
            str = str .. "  点炮"
        elseif v.is_jiepao == 1 then
            str = str or ""
            str = str .. "  接炮"
        end
        if v.buhua_group then
            if #v.buhua_group ~= 0 then
                str = str or ""
                str = str .. "  补花" .. #v.buhua_group .. "次"
            end
        end

        if v.index == rtn_msg.host_id then
            if v.score ~= 0 then
                str = str or ""
                str = str .. "  庄"
            end
        end

        if str then
            dh_lbl:setString(str)
        else
            dh_lbl:setString("")
        end

        if v.fan and v.fan ~= 0 and v.fan ~= 1 then
            tolua.cast(ccui.Helper:seekWidgetByName(play, "fanshu"), "ccui.Text"):setString('X' .. v.fan .. '番')
        else
            ccui.Helper:seekWidgetByName(play, "fanshu"):setVisible(false)
        end

        local pos = commonlib.worldPos(ccui.Helper:seekWidgetByName(play, "shuying"))
        pos.x     = pos.x + 190
        pos.y     = pos.y - 25
        self:resultCard(v, node, pos)
    end

    for __, v in pairs(index_list) do
        if v then
            ccui.Helper:seekWidgetByName(node, "play" .. v):setVisible(false)
        end
    end

    self:setShareBtn(rtn_msg, node)
end

function MJScene:GetGangPai()
    local ltHandCard = {}
    for i, v in pairs(self.hand_card_list[1]) do
        ltHandCard[#ltHandCard + 1] = v.card_id
    end
    return self.MJLogic.GetGangPai(ltHandCard)
end

function MJScene:GetKePai()
    local ltHandCard = {}
    for i, v in pairs(self.hand_card_list[1]) do
        if v.sort == 0 then
            ltHandCard[#ltHandCard + 1] = v.card_id
        end
    end
    return self.MJLogic.CanKe(ltHandCard, nil, self.wang_cards[1])
end

function MJScene:GetHuaPai()
    local ltHandCard = {}
    for i, v in pairs(self.hand_card_list[1]) do
        if v.sort == 0 then
            ltHandCard[#ltHandCard + 1] = v.card_id
        end
    end
    return self.MJLogic.GetHuaList(ltHandCard)
end

function MJScene:getWanFaStr()
    local room_info = RoomInfo.params

    self.game_name = '丰宁\n'

    local str = nil
    str       = self.game_name
    str       = str .. room_info.total_ju .. "局" .. (RoomInfo.people_total_num or 4) .. "人\n"
    -- 报听-- 带风-- 只可自摸-- 改变听口不能杠-- 随机耗子-- 大胡-- 平胡

    str = str .. ('底分:' .. room_info.iDiFeng .. '\n')
    if room_info.iPaoFen == 0 then
        str = str .. ('不跑分\n')
    else
        str = str .. ('跑分:' .. room_info.iPaoFen .. '\n')
    end
    str = str .. (room_info.isDaiZhuangXian and '带庄闲\n' or '')
    str = str .. (room_info.isQiShouHua and '起手花\n' or '')
    str = str .. (room_info.isZhiKeZiMo and '只可自摸\n' or '')
    str = str .. (room_info.isBGYJP and '补杠一家赔\n' or '')
    str = str .. (room_info.isDaiFeng and '带风牌\n' or '')
    str = str .. (room_info.isMPQT and '摸牌前推\n' or '')
    str = str .. (room_info.isCPHT and '出牌后推\n' or '')
    str = str .. (room_info.isGSHZ and '杠随胡走\n' or '')
    str = str .. (room_info.isGHGL and '过胡过轮\n' or '')
    str = str .. (room_info.isZKZM and '只可自摸\n' or '')

    self.isMPQT    = room_info.isMPQT
    self.isCPHT    = room_info.isCPHT
    self.isDaHu    = false
    self.isBaoTing = true

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

function MJScene:resetOperPanel(oper, haidi_ting, last_card_id, msgid, kg_cards, isMustHU, player)
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
    local OPER_HUA       = 21 -- 花
    local OPER_KE        = 22 -- 刻
    local OPER_TUI       = 23 -- 推

    self.oper_panel:setVisible(true)

    self.oper_panel.no_reply = true
    self.only_bu             = true
    local oper_list          = {chi = 0, peng = 0, gang = 0, bu = 0, hu = 0, hd = 0, hua = 0, ke = 0, tui = 0, guo = 1}
    if player.isHuiEr then
        oper_list.guo = 0
    end
    local has_oper  = nil
    local max_oper  = 0
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
            has_oper     = true
            self.hasHu   = true
        elseif v == 101 then
            oper_list.hu  = 1
            self.hu_type  = 101
            oper_list.guo = 0
            has_oper      = true
        elseif v == OPER_PENG then
            oper_list.peng = 1
            has_oper       = true
            self.hasPeng   = true
        elseif v == OPER_CHI_CARD then
            oper_list.chi = 1
            has_oper      = true
        elseif v == OPER_GANG then
            oper_list.gang = 1
            has_oper       = true
            self.hasGang   = true
        elseif v == OPER_OUT_CARD then
            self.can_opt = true
        elseif v == 100 then
            oper_list.hd = 1
            has_oper     = true
        elseif v == 9 then
            oper_list.gang = 1
            has_oper       = true
        elseif v == OPER_TING then
            oper_list.ting = 1
            has_oper       = true
            self.hasTing   = true
        elseif v == OPER_HUA then
            oper_list.hua = 1
            has_oper      = true
            self.hasHua   = true
        elseif v == OPER_KE then
            oper_list.ke = 1
            has_oper     = true
        elseif v == OPER_TUI then
            oper_list.tui = 1
            has_oper      = true
            self.hasTui   = true
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
    -- 上次出牌是不是王
    -- local pre_is_wang = self:isWangCard(self.last_out_card)
    -- if self.pre_out_direct and self.out_card_list[self.pre_out_direct] then
    --     -- 得到最后打出的一次牌
    --     local card = self.out_card_list[self.pre_out_direct][#self.out_card_list[self.pre_out_direct]]
    --     if card then
    --         pre_is_wang = (card.card_id==self.wang_cards[2]) or (card.card_id==self.wang_cards[3])
    --     end
    -- end
    local no_wang_count = self:checkNoWangCard()
    -- print('不是王的张牌')
    -- print(no_wang_count)
    -- print('不是王的张牌')

    -- 如果有消息或者是断线重连 并且最大的操作码大于1（除了出牌还有其它操作）
    if (self.action_msg or self.is_treatResume) and max_oper > OPER_OUT_CARD then
        if #self.hand_card_list[1] == 14 then
            self.oper_pai_id = self.hand_card_list[1][14].card_id
        else
            if last_card_id then
                self.oper_pai_id = last_card_id
            else
                self.oper_pai_id = self.last_out_card or 1
            end
        end
        if type(self.oper_pai_id) == "table" then
            self.oper_pai_id = 1
        end
        oper_pai = self:getCardById(1, self.oper_pai_id, "_stand")
        oper_pai:setPosition(cc.p(oper_pai:getPositionX() + 90, oper_pai:getPositionY() + 30))
        self.is_treatResume = false
    end

    if oper_list.guo == 1 and has_oper then
        if oper_list.hu == 1 then
            oper_btn_list[1].opt_type = "guo_hu"
        else
            oper_btn_list[1].opt_type = "guo"
        end
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_guo_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end

    -- 上张是王 并且不是王的张数大于0 或者  上张不是王 并且不是王的手牌大于2 为了验证手牌数
    -- if oper_list.peng==1 and ((pre_is_wang and no_wang_count > 0) or (not pre_is_wang and no_wang_count > 2)) then
    if oper_list.peng == 1 then
        oper_btn_list[1].opt_type = "peng"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_peng_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == OPER_PENG then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX() - 30, self.oper_pai_bg:getPositionY() + 80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            if self.is_3dmj then
                oper_pai:setScale(0.6)
            end
            oper_pai:setPositionY(40)
            self.oper_pai_bg:addChild(oper_pai, 1)
        end
        table.remove(oper_btn_list, 1)
    end

    if oper_list.chi == 1 then
        oper_btn_list[1].opt_type = "chi"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_chi_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end

    if oper_list.gang == 1 then
        if self.can_opt then
            kg_cards = self:GetGangPai()
        else
            kg_cards = {}
        end
        oper_btn_list[1].opt_type = kg_cards or {}
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_gang_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if max_oper == OPER_GANG then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX() - 30, self.oper_pai_bg:getPositionY() + 80))
            oper_btn_list[1]:addChild(self.oper_pai_bg, -1)
            local gang_pai = {}
            if #kg_cards == 0 then
                kg_cards[1] = self.oper_pai_id
            end
            for i, v in ipairs(kg_cards) do
                gang_pai[i] = self:getCardById(1, kg_cards[i], "_stand")
                gang_pai[i]:setPosition(cc.p(gang_pai[i]:getPositionX() + 150 - (i * 60), gang_pai[i]:getPositionY() + 30))
                if self.is_3dmj then
                    gang_pai[i]:setScale(0.6)
                end
                gang_pai[i]:setPositionY(40)
                self.oper_pai_bg:addChild(gang_pai[i], 1)
            end
        end
        table.remove(oper_btn_list, 1)
    end
    if oper_list.hu == 1 then
        oper_btn_list[1].opt_type = "hu"
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_hu_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        if #oper_btn_list >= 6 then
            oper_btn_list[1]:setScale(1.3)
        end
        if max_oper == OPER_HU or max_oper == OPER_CHI_HU then
            self.oper_pai_bg = cc.Sprite:create("ui/qj_mj/dy_play_eat_bg.png")
            self.oper_pai_bg:setPosition(cc.p(self.oper_pai_bg:getPositionX() - 30, self.oper_pai_bg:getPositionY() + 80))
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
            self.can_opt  = nil
        end
    end

    if oper_list.ting == 1 then
        oper_btn_list[1].opt_type = 'ting'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/dy_play_ting_btn.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        self.btnTing = oper_btn_list[1]
        table.remove(oper_btn_list, 1)
    end
    -- TODO:花，推，刻
    if oper_list.hua == 1 then
        local hua_pai = {}
        if player.hua_list then
            hua_pai = player.hua_list
        elseif self:GetHuaPai() then
            hua_pai = self:GetHuaPai()
        end
        oper_btn_list[1].opt_card = hua_pai
        oper_btn_list[1].opt_type = 'hua'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/hua-fs8.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end
    if oper_list.tui == 1 then
        oper_btn_list[1].opt_type = 'tui'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/tui-fs8.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        self.btnTing = oper_btn_list[1]
        table.remove(oper_btn_list, 1)
    end
    if oper_list.ke == 1 then
        kg_cards                  = self:GetKePai()
        oper_btn_list[1].opt_card = kg_cards or {}
        oper_btn_list[1].opt_type = 'ke'
        oper_btn_list[1]:loadTextureNormal("ui/qj_mj/ke-fs8.png")
        oper_btn_list[1]:setVisible(true)
        oper_btn_list[1]:setTouchEnabled(true)
        table.remove(oper_btn_list, 1)
    end
    -- End
    local total = 0
    if #oper_btn_list >= 6 then
        self.oper_panel:setVisible(false)
        self.oper_panel.no_reply = nil
        self.only_bu             = nil
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
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(self.TingAutoOutCard),
                cc.CallFunc:create(function()
                    if last_card_id then
                        self:sendOutCards(last_card_id)
                        self:setImgGuoHuIndexVisible(1, false)
                    else
                        local card = self.hand_card_list[1][#self.hand_card_list[1]]
                        if card and card.card_id and ((self.for_draw_card == card.card_id) or (not self.for_draw_card)) then
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

    if AUTO_PLAY then
        local oper = false
        if has_oper then
            oper = true
            self:sendOperate(nil, 0)
            oper = false
        end
        if self.can_opt and not oper then
            if 14 > #self.hand_card_list[1] then
                return
            end
            self.card_index = self.card_index or 13
            self:sendOutCards(self.hand_card_list[1][self.card_index].card_id)
            self.card_index = self.card_index - 1
            if self.card_index <= 0 then
                self.card_index = 13
            end
        end
        return
    end
    if total ~= 0 then
        self:send_join_room_again()
    end
    if self.can_opt and self.ting_tip_layer and not self.ting_status then
        if self.isBaoTing and oper_list.tui ~= 1 and self.isMPQT then
            return
        end
        local hand_list  = {}
        local group_list = {}
        local j          = 1
        while j <= #self.hand_card_list[1] do
            local v = self.hand_card_list[1][j]
            if v then
                if v.sort == 0 then
                    hand_list[#hand_list + 1] = v.card_id
                    j                         = j + 1
                else
                    local list = {}
                    local k    = 0
                    while k < 3 do
                        list[#list + 1] = self.hand_card_list[1][k + j].card_id
                        k               = k + 1
                    end
                    j = j + k
                    table.sort(list)
                    group_list[#group_list + 1] = list
                end
            end
        end
        local out_list = {}
        for k = 1, 4 do
            if self.hand_card_list[k] and #self.hand_card_list[k] > 0 then
                for __, v in ipairs(self.hand_card_list[k]) do
                    if v.card_id and v.card_id >= 1 and v.card_id <= 81 then
                        out_list[#out_list + 1] = v.card_id
                        if v.is_gang then
                            out_list[#out_list + 1] = v.card_id
                        end
                    end
                end
            end
            if self.out_card_list[k] and #self.out_card_list[k] > 0 then
                for __, v in ipairs(self.out_card_list[k]) do
                    if v.card_id and v.card_id >= 1 and v.card_id <= 81 then
                        out_list[#out_list + 1] = v.card_id
                    end
                end
            end
        end
        self.ting_list      = {}
        local bCanOutToTing = self.MJLogic.CanOutToTing(hand_list, group_list, self.wang_cards[1])
        if not bCanOutToTing then
            return
        end
        local left_cards = self.MJLogic.copyArray(MJBaseScene.CardNum)
        for i, v in ipairs(out_list) do
            left_cards[v] = left_cards[v] or 4
            left_cards[v] = left_cards[v] - 1
        end
        for i, v in ipairs(hand_list) do
            if not self.ting_list[v] then
                local hands = clone(hand_list)
                table.remove(hands, i)

                local hu_list   = {}
                local ting_list = self.MJLogic.CetTingCards(hands, group_list, self.wang_cards[1])
                if ting_list and #ting_list > 0 then
                    for i, v in pairs(ting_list) do
                        hu_list[#hu_list + 1] = {v, left_cards[v]}
                    end
                end
                if hu_list and #hu_list > 0 then
                    local wang = self.wang_cards[1]
                    if wang then
                        local bHasWang = false
                        for i, v in ipairs(hu_list) do
                            if wang == v[1] then
                                bHasWang = true
                                break
                            end
                        end
                        if not bHasWang then
                            table.insert(hu_list, 1, {wang, left_cards[wang]})
                        end
                    end
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
                if v.sort == 0 and v.card_id == k and not v.ting_ar then
                    local sp = cc.Sprite:create("ui/qj_mj/ting_arrow.png")
                    if self.is_pmmj or self.is_pmmjyellow then
                        sp:setScale(1.1)
                    else
                        sp:setScale(2)
                    end
                    sp:setAnchorPoint(0.5, 0)
                    sp:setPosition(card_size.width / 2, card_size.height)
                    v:addChild(sp)
                    v.ting_ar = sp
                end
            end
        end
    end
end

function MJScene:addCardShadow(bIngore14)
    for i, card in pairs(self.hand_card_list[1]) do
        local card_shadow = card:getChildByName('card_shadow')
        if not card_shadow and card.sort == 0 and (i ~= 14 or bIngore14) then
            card_shadow = cc.Sprite:create(self.res3DPath .. '/Frame_ziji_shoupai-zhezhao.png')
            card_shadow:setAnchorPoint(0.05, 0.05)
            card_shadow:setName('card_shadow')
            --- if self.is_pmmj or self.is_pmmjyellow then
            card_shadow:setAnchorPoint(0, 0)
            local iCardSize       = card:getContentSize()
            local iCardShadowSize = card_shadow:getContentSize()
            card_shadow:setScaleX(iCardSize.width / iCardShadowSize.width)
            card_shadow:setScaleY(iCardSize.height / iCardShadowSize.height)
            -- end
            self.hand_card_list[1][i]:addChild(card_shadow)
        end
    end
end

function MJScene:getTingCards(direct)
    if direct == 1 or self.is_playback then
        return
    end
    if 1 then
        return
    end
    local hand_list  = {}
    local group_list = {}
    local j          = 1
    while j <= 13 do
        local v = self.hand_card_list[direct][j]
        if v then
            if v.sort == -1 then
                hand_list[#hand_list + 1] = v.card_id
                j                         = j + 1
            else
                local list = {}
                local k    = 0
                while k < 3 do
                    list[#list + 1] = self.hand_card_list[direct][k + j].card_id
                    k               = k + 1
                end
                j = j + k
                table.sort(list)
                group_list[#group_list + 1] = list
            end
        end
    end

    self.other_ting_list    = {}
    self.other_ting_list[2] = {}
    self.other_ting_list[3] = {}
    self.other_ting_list[4] = {}

    local hands = clone(hand_list)

    if not self.other_ting_list[direct] or #self.other_ting_list[direct] == 0 then
        local hu_list   = {}
        local ting_list = self.MJLogic.CetTingCards(hands, group_list, self.wang_cards[1])

        if ting_list and #ting_list > 0 then
            for i, v in pairs(ting_list) do
                hu_list[#hu_list + 1] = {v}
            end
        end
        if hu_list and #hu_list > 0 then
            local wang = self.wang_cards[1]
            if wang then
                local bHasWang = false
                for i, v in ipairs(hu_list) do
                    if wang == v[1] then
                        bHasWang = true
                        break
                    end
                end
                if not bHasWang then
                    table.insert(hu_list, 1, {wang})
                end
            end
            self.other_ting_list[direct] = hu_list
        end
    end

    if self:iscanAnyHu(direct) then
        return
    end

    local hu_list = self.other_ting_list[direct]

    if hu_list and #hu_list > 0 then
        self.ting_tip_card[direct]:setVisible(true)
        -- 听字
        self:setTingTitleVisible(self.tdh_need_bTing)

        for i = 1, 10 do
            local ting_item = self.ting_tip_card[direct].pai_list[i]

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
                self.ting_tip_card[direct]:addChild(ting_item.pai, 1)
                ting_item.num:setVisible(false)
            end
        end
    else
        self.ting_tip_card[direct]:setVisible(false)
    end
end

function MJScene:iscanAnyHu(direct)
    local hu_list = self.other_ting_list and self.other_ting_list[direct]
    if hu_list and table.maxn(hu_list) >= 27 then
        self.ting_tip_card[direct]:setVisible(true)
        self.ting_tip_card[direct]:getChildByName('ImgAnyHu'):setVisible(true)

        for i = 1, 10 do
            local ting_item = self.ting_tip_card[direct].pai_list[i]

            if ting_item.pai then
                ting_item.pai:removeFromParent(true)
                ting_item.pai = nil
            end
            ting_item.ori_pai:setVisible(false)
        end
        return true
    end
    self.ting_tip_card[direct]:getChildByName('ImgAnyHu'):setVisible(false)
    return false
end

function MJScene:tingTipOper()
    self.ting_tip_card = {}

    local tingtip = tolua.cast(cc.CSLoader:createNode("ui/fntingtip.csb"), "ccui.Widget")
    self:addChild(tingtip, 10000)
    tingtip:setContentSize(g_visible_size)
    ccui.Helper:doLayout(tingtip)
    for index = 2, 4 do
        self.ting_tip_card[index]          = tingtip:getChildByName("bg" .. index)
        self.ting_tip_card[index].pai_list = {}
        for i = 1, 10 do
            local ting_item                       = {}
            local pai                             = tolua.cast(self.ting_tip_card[index]:getChildByName("pai" .. i), "ccui.ImageView")
            ting_item.pos                         = cc.p(pai:getPosition())
            ting_item.num                         = tolua.cast(pai:getChildByName("num"), "ccui.Text")
            ting_item.ori_pai                     = pai
            self.ting_tip_card[index].pai_list[i] = ting_item
        end
        self.ting_tip_card[index]:setVisible(false)
    end
end

return MJScene