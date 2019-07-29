
local buttonClickTime = require('scene.buttonClickTime')

local CreateLayer = class("CreateLayer",function()
    return cc.Layer:create()
end)

--qunzhu
-- * 0 AA房  -- 房主创建房间，每个人扣卡
-- * 2 房主房 -- 房主创建房间，扣房主的卡
-- * 1 亲友圈畅玩房 -- 群主创好房间，只扣群主的卡
-- * 3 亲友圈自由房间  -- 群中的玩家自己可以在亲友圈中开任意类型的房间，方便群中其它玩家加入游戏。只扣群主的卡
-- * 4 亲友圈AA房 -- 群主创好房间，每个人扣卡

--clubOpt
-- * nil 创建普通房间
-- * 1 创建亲友圈
-- * 2 修改亲友圈房间
-- * 3 统一修改默认亲友圈房间

--创房时的默认玩法
-- * self.clubOpt == 2 时读取该桌子的玩法，把其设置为默认玩法
-- * self.clubOpt 存在且 ~= 2 时，存至qyq_opt 中
-- * self.clubOpt 为nil时 存至 _opt中

--
-- * self.clubOpt == nil
-- 创建普通房间 -- 默认的游戏存在   pre_game1，pre_game2，pre_game3中 -- 默认选择的游戏类别存在 pre_game_typ

-- * self.clubOpt == 2
-- 修改亲友圈桌子玩法 -- 默认的游戏存在   qyqpre_game1，qyqpre_game2，qyqpre_game3中  -- 默认选择的游戏类别存在 qyqpre_game_typ

-- * self.clubOpt == 3
-- 同意修改默认亲友圈玩法 -- 默认的游戏存在   waypre_game1，waypre_game2，waypre_game3中  -- 默认选择的游戏类别存在 waypre_game_typ


function CreateLayer:create(args)
    local layer = CreateLayer.new()
    layer:setName("CreateLayer")
    layer.clubOpt = args.clubOpt
    layer.room_id = args.room_id
    layer.club_id = args.club_id
    layer.club_room_info = args.club_room_info
    layer.isGM  = args.isGM
    layer.isFzb = args.isFzb
    self.mainScene = args.mainScene
    layer.qunzhu = args.qunzhu or 2
    if layer.clubOpt and (layer.clubOpt == 1 or layer.clubOpt == 2 or layer.clubOpt == 3) then
        layer.qunzhu = 1
    end
    layer:createLayerMenu(args.typ)
    layer:setLocalZOrder(150)
    return layer
end

function CreateLayer:registerEvent()
    local events = {
        {
            eType = EventEnum.onReconnect,
            func = handler(self,self.onReconnect),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function CreateLayer:onReconnect()
    -- 关闭确认弹窗
    commonlib.closeRoomTipDlg()
end

function CreateLayer:onEnter()
    self:registerEvent()
end

function CreateLayer:unregisterEvent()
    for i,v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

-- 目前没有用到
function CreateLayer:initGameSelect(type)   -- type：类型number   1：山西麻将  2：陕西麻将  3：扑克合集  4：河北麻将
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_CreateroomLayer_GameSelect.csb"),"ccui.Widget")
    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(node)
    self:addChild(node,5)

    -- 看选中的是哪一种游戏模式回调
    local function gameSelectCallBack(typ)  -- typ：类型number   1：山西麻将  2：陕西麻将  3：扑克合集  4：河北麻将
        local t_panel_room = {self.panel_roomMJ,self.panel_roomMJ2,self.panel_roomPK,self.panel_roomMJHeiBei}
        for ii = 1, 4 do
            local btn = ccui.Helper:seekWidgetByName(node, "Tab"..ii)
            -- btn:setTouchEnabled(ii ~= typ)
            btn:setBright(ii ~= typ)

            if t_panel_room[ii] then
                t_panel_room[ii]:setVisible(typ == ii)
            end
        end
    end

    for ii = 1, 4 do
        ccui.Helper:seekWidgetByName(node, "Tab"..ii):addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if self.clubOpt == 2 then
                    cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", tostring(ii))
                elseif self.clubOpt == 3 then
                    cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", tostring(ii))
                else
                    cc.UserDefault:getInstance():setStringForKey("pre_game_typ", tostring(ii))
                end
                cc.UserDefault:getInstance():flush()

                self:refreshUI(ii)

                gameSelectCallBack(ii)
            end
        end)
    end

    gameSelectCallBack(type)
end


function CreateLayer:createLayerMenu(typ)
    self:refreshUI(typ)

    self:enableNodeEvents()
end

function CreateLayer:onExit()
    buttonClickTime.closeButtonClickTimeSchedule(self.mjButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.xaButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.ddzButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.pdkButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.jdpdkButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.zhsButtonClickTime)
    buttonClickTime.closeButtonClickTimeSchedule(self.hbmjButtonClickTime)

    self:unregisterEvent()
end

-- 恢复游戏创房界面
function CreateLayer:refreshUI(typ)
    local type_pre
    if self.clubOpt == 2 then
        type_pre = cc.UserDefault:getInstance():getStringForKey("qyqpre_game_typ",'1')
    elseif self.clubOpt == 3 then
        type_pre = cc.UserDefault:getInstance():getStringForKey("waypre_game_typ",'1')
    else
        type_pre = cc.UserDefault:getInstance():getStringForKey("pre_game_typ",'1')
    end
    typ = tonumber(type_pre)
    -- print('游戏主界面',tostring(type_pre))
    -- typ = 4
    if typ == 1 then
        self:createMJRoomUI()
    elseif typ == 2 then
        self:createMJ2RoomUI()
    elseif typ == 3 then
        self:createPokerRoomUI()
    else
        self:createMJHeBeiRoomUI()
    end

    -- 如果是创建亲友圈
    if self.clubOpt == 1 then
        if GameGlobal.openClubCreate == 1 then
            gt.performWithDelay(self,function()
                commonlib.showLocalTip("您需要设置默认玩法")
            end,0.5)
        end
        GameGlobal.openClubCreate = GameGlobal.openClubCreate + 1
    end
end

-- 恢复游戏大厅界面，若g_author_game为真，则恢复创房界面
function CreateLayer:refreshMainGameUI(panel_room)
    for ii=1, 4 do
        if not g_author_game then
            local Tab = ccui.Helper:seekWidgetByName(panel_room, "Tab"..ii)
            if Tab then
                ccui.Helper:seekWidgetByName(panel_room, "Tab"..ii):addTouchEventListener(function(sender,eventType)
                    if eventType == ccui.TouchEventType.ended then
                        AudioManager:playPressSound()
                        if self.clubOpt == 2 then
                            cc.UserDefault:getInstance():setStringForKey("qyqpre_game_typ", tostring(ii))
                        elseif self.clubOpt == 3 then
                            cc.UserDefault:getInstance():setStringForKey("waypre_game_typ", tostring(ii))
                        else
                            cc.UserDefault:getInstance():setStringForKey("pre_game_typ", tostring(ii))
                        end
                        cc.UserDefault:getInstance():flush()
                        -- 每次点击游戏类别先使整个创房界面隐藏，再利用refreshUI函数恢复所点击的创房界面
                        panel_room:setVisible(false)
                        self:refreshUI(ii)
                    end
                end)
            end
        else
            ccui.Helper:seekWidgetByName(panel_room, "Tab"..ii):setVisible(false)
        end
    end
end

-- 复制
function CreateLayer:tblCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:tblCopy(orig_key)] = self:tblCopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- 改变成选中和未选中时所对应的图片
function CreateLayer:setOpt(opt_btn, is_quan, is_on, font_yanse, name)
    if not is_on then
        tolua.cast(opt_btn:getChildByName("xuan"), "ccui.ImageView"):loadTexture("ui/qj_createroom/cj_0001_quan-fs8.png")
    else
        tolua.cast(opt_btn:getChildByName("xuan"), "ccui.ImageView"):loadTexture("ui/qj_createroom/cj_0000_gou-fs8.png")
    end
    if is_on then
        opt_btn:setTitleColor(cc.c3b(144, 3, 3))
    else
        opt_btn:setTitleColor(cc.c3b(91, 51, 0))
    end
    if opt_btn:getChildByName("fangka") then
        if is_on then
            opt_btn:getChildByName("fangka"):setColor(cc.c3b(144, 3, 3))
        else
            opt_btn:getChildByName("fangka"):setColor(cc.c3b(91, 51, 0))
        end
    end
end

-- 创建山西麻将创房界面
function CreateLayer:createMJRoomUI(has_ani)
    local clientIp = gt.getClientIp()  -- 获取IP
    local panel_room = nil
    if self.panel_roomMJ then
        panel_room = self.panel_roomMJ
        panel_room:setVisible(true)
        self.panel_room = panel_room
        return
    else
        local csb = DTUI.getInstance().csb_DT_CreateroomLayer_sxmj1
        panel_room = tolua.cast(cc.CSLoader:createNode(csb),"ccui.Widget")
        self:addChild(panel_room)
        self.panel_room = panel_room
        self.panel_roomMJ = panel_room
    end

    ccui.Helper:seekWidgetByName(panel_room, "ScrollView_1"):setDirection(0) -- setDirection设置滚动方向，0代表水平和垂直都不滚动
    panel_room:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
    ccui.Helper:doLayout(panel_room)

    if has_ani then
        commonlib.moveTo(ccui.Helper:seekWidgetByName(panel_room, "Panel_Tabbg"), true, function()
        end)
    end

    self:refreshMainGameUI(panel_room)

    -- 抠点
    local panel_kdmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "kdmj"), "ccui.Widget")
    panel_kdmj:setVisible(false)
    panel_kdmj:setEnabled(false)

    -- 立四
    local panel_lsmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "lsmj"), "ccui.Widget")
    panel_lsmj:setVisible(false)
    panel_lsmj:setEnabled(false)

    -- 推倒胡
    local panel_tdh = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "tdh"), "ccui.Widget")
    panel_tdh:setVisible(true)
    panel_tdh:setEnabled(true)

    -- 拐三角
    local panel_gsjmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "gsjmj"), "ccui.Widget")
    panel_gsjmj:setVisible(false)
    panel_gsjmj:setEnabled(false)

    -- 晋中
    local panel_jzmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "jzmj"), "ccui.Widget")
    panel_jzmj:setVisible(false)
    panel_jzmj:setVisible(false)

    -- 晋中拐三角
    local panel_jzgsjmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "jzgsjmj"), "ccui.Widget")
    panel_jzgsjmj:setVisible(false)
    panel_jzgsjmj:setVisible(false)

    -- 返回按钮
    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(panel_room,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    -- 推倒胡
    local btTdh = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btTdh"), "ccui.Button")
    -- 抠点
    local btKd = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btKd"), "ccui.Button")
    -- 立四
    local btLs = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btLs"), "ccui.Button")
    -- 拐三角
    local btGsj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btGsj"), "ccui.Button")
    -- 晋中
    local btJz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btJz"), "ccui.Button")
    -- 晋中拐三角
    local btJzGsj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btJzGsj"), "ccui.Button")

    kefuTextConfig.hd_list = kefuTextConfig.hd_list or {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,}

    self:createJsGsj(panel_jzgsjmj)

    self:createJz(panel_jzmj)

    -- 推倒胡按钮列表  -- 2人 -- 3人 -- 4人 -- 1局   -- 4局   -- 8局，-- 报听-- 带风-- 只可自摸-- 改变听口不能扛-- 随机耗子-- 大胡-- 平胡-- 缺一门-- 胡牌必须缺门-- 硬豪七
    local ltTdhListBtn = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "2ren"), "ccui.Button"), --1
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "3ren"), "ccui.Button"), --2
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "4ren"), "ccui.Button"), --3

        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "1ju"), "ccui.Button"), --4
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "4ju"), "ccui.Button"), --5
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "8ju"), "ccui.Button"), --6

        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "baoting"), "ccui.Button"),          --7
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "daifeng"), "ccui.Button"),          --8
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "zimohu"), "ccui.Button"),           --9
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "bunenggang"), "ccui.Button"),       --10
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "suijihaozi"), "ccui.Button"),       --11
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "dahu"), "ccui.Button"),             --12
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "pinghu"), "ccui.Button"),           --13
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "que1men"), "ccui.Button"),          --14
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "hpbxqm"), "ccui.Button"),           --15
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "yinghaoqi"), "ccui.Button"),        --16
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "gshz"), "ccui.Button"),             --17
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "dingpiao"), "ccui.Button"),         --18
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "ziyoupiao"), "ccui.Button"),        --19
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "30s"), "ccui.Button"),              --20
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "60s"), "ccui.Button"),              --21
        tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "120s"), "ccui.Button"),             --22
    }

    require 'common.global'
    tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "tPiaofen"), "ccui.Button"):setVisible(ENABLE_TDH_PIAOFEN)
    tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "dingpiao"), "ccui.Button"):setVisible(ENABLE_TDH_PIAOFEN)
    tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "ziyoupiao"), "ccui.Button"):setVisible(ENABLE_TDH_PIAOFEN)
    -- tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "piaofen"), "ccui.Button"):setVisible(ENABLE_TDH_PIAOFEN)

    local btn_suijihaozi = tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, "suijihaozi"), "ccui.Button")
    local btn_daifeng = tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh,"daifeng"), "ccui.Button")

    -----------------1280*500分辨率--------------------------
    -- -- 与 扣点中改变某些按钮的位置 道理一样
    -- -- 改变带风的位置
    -- if ltTdhListBtn[10]:getPositionX() + ltTdhListBtn[10]:getContentSize().width < ltTdhListBtn[11]:getPositionX() then
    --     ltTdhListBtn[8]:setPositionX(ltTdhListBtn[11]:getPositionX())
    -- end
    -- -- 改变硬豪七的位置
    -- if ltTdhListBtn[15]:getPositionX() + ltTdhListBtn[15]:getContentSize().width < ltTdhListBtn[11]:getPositionX() then
    --     ltTdhListBtn[16]:setPositionX(ltTdhListBtn[11]:getPositionX())
    -- end
    ----------------------------------------------------------

    local ltTdhHasQuesBtn = {'baoting', 'daifeng', 'zimohu', 'bunenggang', 'suijihaozi', 'que1men', 'hpbxqm', 'yinghaoqi','piaofen', "120s"}

    local ltTdhQuesContent = {
        ['baoting']    = '勾选后，必须报听才能胡牌；不勾选时，\n不需要报听就能胡牌。',
        ['daifeng']    = '勾选时，牌中带有东南西北中发白，共\n136张牌；不勾选时，牌中不带东南西北\n中发白，共108张牌。',
        ['zimohu']     = '勾选时，胡牌只能自摸胡；不勾选时，胡\n牌方式不做限制。',
        ['bunenggang'] = '勾选时，听牌后，少听口或者变听口都不\n可以杠；不勾选时，听牌后，杠后牌型仍\n有听口就可以杠。',
        ['suijihaozi'] = '每局随机一张牌为耗子牌，耗子牌可以顶\n替任何牌，但是不能和其他牌组成组合形\n成听牌或杠牌；耗子牌本身可以碰、杠，\n但是没有额外分数，耗子牌不能点炮用',
        ['que1men']    = '勾选后，所用牌不含条字牌',
        ['hpbxqm']     = '勾选后，必须缺门(万筒条不同时存在，\n' ..
                         '风牌不算入在内)才能胡牌，不勾选，满\n'..
                         '足胡牌牌型，即可胡牌。',
        ['yinghaoqi']  = '勾选后，豪七牌型中的4张一样的牌必须\n'..
                         '无耗子参与才算豪七，否则不算豪七。\n'..
                         '若1133444耗子667799，胡牌，则不算\n'..
                         '豪七，只算七对。若1133444466779耗\n'..
                         '子，胡牌，则算豪七',
        ['120s']       = '牌局开始后,超时未操作，将由系统托管\n'..
                         '自动出牌。一局结束时，若有人处于托管\n'..
                         '状态，则房间立即解散\n',
    }

    -- 问号按钮点击事件回调
    local function tdkQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            -- 某个提示正在显示，当点击其他提示时，原来的提示信息会被移除，显示新点击的提示信息
            if panel_tdh.tipMsgNode and panel_tdh.tipMsgNode.lnSelectName ~= szName then
                panel_tdh.tipMsgNode:removeFromParent(true)
                panel_tdh.tipMsgNode = nil
            end

            if not panel_tdh.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'yinghaoqi' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltTdhQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                if szName == 'yinghaoqi' then
                    pos.x = pos.x -20
                    arrow:setPositionX(arrow:getPositionX()+3)
                else
                    arrow:setPositionX(arrow:getPositionX()-17)
                end
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)
                if szName == "piaofen" then
                    tipMsgNode:getChildByName("panMsg"):setContentSize(cc.size(400, 120))
                end

                panel_tdh.tipMsgNode = tipMsgNode
                panel_tdh.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel_tdh.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel_tdh.tipMsgNode:removeFromParent(true)
                    panel_tdh.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel_tdh.tipMsgNode:runAction(seq)
            end
        end
    end

    -- 给每个问号按钮添加点击事件（去掉ltTdhHasQuesBtn表，利用ltTdhQuesContent表进行遍历）
    for k,v in pairs(ltTdhQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel_tdh, k)
        local btQues = btSelect:getChildByName('ques')
        btQues:addTouchEventListener(tdkQuesBtnCallBack)
    end

    -- 给各个按钮设置一个默认值
    local desk_mode = 3  -- 待需要消耗的房卡数
    local ren_mode = 4
    local player_mode = {}
    player_mode['baoting'] = true
    player_mode['zimohu'] = false
    player_mode['daifeng'] = false
    player_mode['bunenggang'] = false
    player_mode['suijihaozi'] = false
    player_mode['dahu'] = true
    player_mode['pinghu'] = not player_mode['dahu']
    player_mode['que1men'] = false
    player_mode['hpbxqm'] = false
    player_mode['yinghaoqi'] = false
    player_mode['gshz'] = false
    player_mode['piaofen'] = 0
    player_mode['cstg'] = 0

    local tdh_str
    local tdh_jushu = 1
    if self.clubOpt then
        -- 推倒胡修改亲友圈房
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_tdh" then
            player_mode['baoting']      = self.club_room_info.params.isBaoTing
            player_mode['zimohu']       = self.club_room_info.params.isZhiKeZiMo
            player_mode['daifeng']      = self.club_room_info.params.isDaiFeng
            player_mode['bunenggang']   = self.club_room_info.params.isGBTKBNG
            player_mode['suijihaozi']   = self.club_room_info.params.isSJHZ
            player_mode['dahu']         = self.club_room_info.params.isDaHu
            player_mode['pinghu']       = self.club_room_info.params.isPingHu
            player_mode['que1men']      = self.club_room_info.params.isQueYiMen
            player_mode['hpbxqm']       = self.club_room_info.params.isHPBXQM
            player_mode['yinghaoqi']    = self.club_room_info.params.isYHQ
            player_mode['gshz']         = self.club_room_info.params.isGSHZ
            player_mode['piaofen']      = self.club_room_info.params.isPiaoFen or 0
            player_mode['cstg']         = self.club_room_info.params.rTGT or 0
            ren_mode                    = self.club_room_info.params.people_num
            tdh_jushu                   = self.club_room_info.params.total_ju

            if ren_mode == 2 then
                if tdh_jushu == 1 then
                    desk_mode = 1
                elseif tdh_jushu == 8 then
                    desk_mode = 2
                elseif tdh_jushu == 16 then
                    desk_mode = 3
                end
            else
                if tdh_jushu == 1 then
                    desk_mode = 1
                elseif tdh_jushu == 4 then
                    desk_mode = 2
                elseif tdh_jushu == 8 then
                    desk_mode = 3
                end
            end
        else -- 统一修改亲友圈
            tdh_str = cc.UserDefault:getInstance():getStringForKey("qyqtdh_opt", "")
            if tdh_str and tdh_str ~= "" then
                local qyqtdh_opt = json.decode(tdh_str)
                commonlib.echo(qyqtdh_opt)
                for k,v in pairs(qyqtdh_opt) do
                    qyqtdh_opt[k] = v
                end
                player_mode['baoting']    = qyqtdh_opt['baoting'] or false
                player_mode['zimohu']     = qyqtdh_opt['zimohu'] or false
                player_mode['daifeng']    = qyqtdh_opt['daifeng'] or false
                player_mode['bunenggang'] = qyqtdh_opt['bunenggang'] or false
                player_mode['suijihaozi'] = qyqtdh_opt['suijihaozi'] or false
                player_mode['dahu']       = qyqtdh_opt['dahu'] or false
                player_mode['que1men']    = qyqtdh_opt['que1men'] or false
                player_mode['hpbxqm']     = qyqtdh_opt['hpbxqm'] or false
                player_mode['yinghaoqi']  = qyqtdh_opt['yinghaoqi'] or false
                player_mode['pinghu']     = not player_mode['dahu']
                player_mode['gshz']       = qyqtdh_opt['gshz'] or false
                player_mode['piaofen']    = qyqtdh_opt['piaofen'] or 0
                player_mode["cstg"]       = qyqtdh_opt['cstg'] or 0
                -- and后面的内容是为了防止qyqtdh_opt['desk_mode']出错时把它强制变为3，使程序能正常运行
                if qyqtdh_opt['desk_mode'] and (qyqtdh_opt['desk_mode'] == 1 or qyqtdh_opt['desk_mode'] == 2 or qyqtdh_opt['desk_mode'] == 3) then
                    desk_mode = qyqtdh_opt['desk_mode']
                else
                    desk_mode = 3
                end
                ren_mode = qyqtdh_opt['ren_mode'] or 4
            end
        end
    else -- 普通房
        tdh_str = cc.UserDefault:getInstance():getStringForKey("tdh_opt", "")
        if tdh_str and tdh_str ~= "" then
            local tdh_opt = json.decode(tdh_str)
            commonlib.echo(tdh_opt)
            for k,v in pairs(tdh_opt) do
                tdh_opt[k] = v
            end
            player_mode['baoting']    = tdh_opt['baoting'] or false
            player_mode['zimohu']     = tdh_opt['zimohu'] or false
            player_mode['daifeng']    = tdh_opt['daifeng'] or false
            player_mode['bunenggang'] = tdh_opt['bunenggang'] or false
            player_mode['suijihaozi'] = tdh_opt['suijihaozi'] or false
            player_mode['dahu']       = tdh_opt['dahu'] or false
            player_mode['que1men']    = tdh_opt['que1men'] or false
            player_mode['hpbxqm']     = tdh_opt['hpbxqm'] or false
            player_mode['yinghaoqi']  = tdh_opt['yinghaoqi'] or false
            player_mode['pinghu']     = not player_mode['dahu']
            player_mode['gshz']       = tdh_opt['gshz'] or false
            player_mode['piaofen']    = tdh_opt['piaofen'] or 0
            player_mode['cstg']       = tdh_opt['cstg'] or 0
            if tdh_opt['desk_mode'] and (tdh_opt['desk_mode'] == 1 or tdh_opt['desk_mode'] == 2 or tdh_opt['desk_mode'] == 3) then
                desk_mode = tdh_opt['desk_mode']
            else
                desk_mode = 3
            end
            ren_mode = tdh_opt['ren_mode'] or 4
        end
    end

    local sz2RenDaHuTitle = '玩法：胡牌类型有平胡、七小对、豪华七小对、清一色、一条龙、\n'..
                            '\t清一色一条龙、清一色七小对、清一色豪华七小对。'
    local szDaHuTitle = '玩法：胡牌类型有平胡，七小对，豪华七小对，清一色，十三幺，\n一条龙。'
    local szPingHuTitle = '玩法：胡牌类型只有平胡。'

    local tdh_posX = ltTdhListBtn[6]:getChildByName("fangka"):getPositionX()

    local dingDifen  = ccui.Helper:seekWidgetByName(ltTdhListBtn[18], "difen")
    local dingPlus   = ccui.Helper:seekWidgetByName(ltTdhListBtn[18], "plus")
    local dingMinus  = ccui.Helper:seekWidgetByName(ltTdhListBtn[18], "minus")
    local ziyouDifen = ccui.Helper:seekWidgetByName(ltTdhListBtn[19], "difen")
    local ziyouPlus  = ccui.Helper:seekWidgetByName(ltTdhListBtn[19], "plus")
    local ziyouMinus = ccui.Helper:seekWidgetByName(ltTdhListBtn[19], "minus")

    local ziyouDifenList = {"123", "235", "258"}

    dingPlus:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if player_mode['piaofen'] > 0 and player_mode['piaofen'] < 10 then
                player_mode['piaofen'] = player_mode['piaofen'] + 1
                dingDifen:setTitleText(tostring(player_mode['piaofen']))
            end
        end
    end)

    dingMinus:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if player_mode['piaofen'] > 1 and player_mode['piaofen'] <= 10 then
                player_mode['piaofen'] = player_mode['piaofen'] - 1
                dingDifen:setTitleText(tostring(player_mode['piaofen']))
            end
        end
    end)

    ziyouPlus:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if player_mode['piaofen'] > 100 and player_mode['piaofen'] < 103 then
                player_mode['piaofen'] = player_mode['piaofen'] + 1
                ziyouDifen:setTitleText(ziyouDifenList[player_mode['piaofen'] - 100])
            end
        end
    end)

    ziyouMinus:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if player_mode['piaofen'] > 101 and player_mode['piaofen'] <= 103 then
                player_mode['piaofen'] = player_mode['piaofen'] - 1
                ziyouDifen:setTitleText(ziyouDifenList[player_mode['piaofen'] - 100])
            end
        end
    end)

    if player_mode['piaofen'] > 101 and player_mode['piaofen'] <= 103 then
        ziyouDifen:setTitleText(ziyouDifenList[player_mode['piaofen'] - 100])
    elseif player_mode['piaofen'] > 1 and player_mode['piaofen'] <= 10 then
        dingDifen:setTitleText(tostring(player_mode['piaofen']))
    end

    -- 初始化推倒胡创房时的显示界面
    local function initShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if ren_mode == 2 then
            --btn_suijihaozi:setVisible(false)
            --btn_daifeng:setVisible(false)
            --player_mode['suijihaozi'] = false
            --player_mode['daifeng'] = false
            ltTdhListBtn[5]:setTitleText("8局")
            ltTdhListBtn[6]:setTitleText("16局")
            ltTdhListBtn[6]:getChildByName("fangka"):setPositionX(tdh_posX+10)
        else
            --btn_suijihaozi:setVisible(true)
            --btn_daifeng:setVisible(true)
            ltTdhListBtn[5]:setTitleText("4局")
            ltTdhListBtn[6]:setTitleText("8局")
            ltTdhListBtn[6]:getChildByName("fangka"):setPositionX(tdh_posX)
        end

        local num = 4
        for i = 1,3 do
            self:setOpt(ltTdhListBtn[num],nil,desk_mode == i)
            num = num + 1
        end

        for i , v in pairs(player_mode) do
            --log('@!@@@@@@@@@@@@!@!@!@!@! ' .. i)
            if i ~= 'piaofen' and i ~= 'cstg' then
                local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_tdh, i), "ccui.Button")
                self:setOpt(btnSelect,nil,player_mode[i])
            end
        end

        -- 设置显示的玩法介绍（类型为string）
        if player_mode['dahu'] then
            if ren_mode == 2 then
                ccui.Helper:seekWidgetByName(panel_tdh, "wanfa"):setString(sz2RenDaHuTitle)
            else
                ccui.Helper:seekWidgetByName(panel_tdh, "wanfa"):setString(szDaHuTitle)
            end
        else
            ccui.Helper:seekWidgetByName(panel_tdh, "wanfa"):setString(szPingHuTitle)
        end
        local isDingPiao  = player_mode['piaofen'] > 0 and player_mode['piaofen'] <= 10
        local isZiYouPiao = player_mode['piaofen'] > 100

        self:setOpt(ltTdhListBtn[18], nil, isDingPiao)
        self:setOpt(ltTdhListBtn[19], nil, isZiYouPiao)

        self:setOpt(ltTdhListBtn[20], nil, player_mode['cstg'] == 30)
        self:setOpt(ltTdhListBtn[21], nil, player_mode['cstg'] == 60)
        self:setOpt(ltTdhListBtn[22], nil, player_mode['cstg'] == 120)

        dingPlus:setTouchEnabled(isDingPiao)
        dingPlus:setBright(isDingPiao)
        dingMinus:setTouchEnabled(isDingPiao)
        dingMinus:setBright(isDingPiao)
        ziyouPlus:setTouchEnabled(isZiYouPiao)
        ziyouPlus:setBright(isZiYouPiao)
        ziyouMinus:setTouchEnabled(isZiYouPiao)
        ziyouMinus:setBright(isZiYouPiao)

        if isDingPiao then
            dingDifen:setTitleText(tostring(player_mode['piaofen']))
        elseif isZiYouPiao then
            ziyouDifen:setTitleText(ziyouDifenList[player_mode['piaofen'] - 100])
        end
    end

    initShowOpt()

    -- 推倒胡界面某一个按钮的点击回调
    local function btnTdhSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            if szName == '2ren' then
                ren_mode = 2
                --player_mode['suijihaozi'] = false
                --player_mode['daifeng'] = false
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '4ren' then
                ren_mode = 4
            elseif szName == '1ju' then
                desk_mode = 1
            elseif szName == '4ju' then
                desk_mode = 2
            elseif szName == '8ju' then
                desk_mode = 3
            elseif szName == 'baoting' then
                player_mode['baoting'] = not player_mode['baoting']
            elseif szName == 'daifeng' then
                player_mode['daifeng'] = not player_mode['daifeng']
            elseif szName == 'zimohu' then
                player_mode['zimohu'] = not player_mode['zimohu']
            elseif szName == 'bunenggang' then
                player_mode['bunenggang'] = not player_mode['bunenggang']
            elseif szName == 'suijihaozi' then
                player_mode['suijihaozi'] = not player_mode['suijihaozi']
            elseif szName == 'dahu' then
                player_mode['dahu'] = true
                player_mode['pinghu'] = not player_mode['dahu']
            elseif szName == 'pinghu' then
                player_mode['pinghu'] = true
                player_mode['dahu'] = not player_mode['pinghu']
            elseif szName == 'que1men' then
                player_mode['que1men'] = not player_mode['que1men']
            elseif szName == 'hpbxqm' then
                player_mode['hpbxqm'] = not player_mode['hpbxqm']
            elseif szName == 'yinghaoqi' then
                player_mode['yinghaoqi'] = not player_mode['yinghaoqi']
            elseif szName == "gshz" then
                player_mode['gshz'] = not player_mode['gshz']
            elseif szName == 'dingpiao' then
                if player_mode['piaofen'] > 0 and player_mode['piaofen'] <= 10 then
                    player_mode['piaofen'] = 0
                else
                    player_mode['piaofen'] = 1
                end
            elseif szName == 'ziyoupiao' then
                if player_mode['piaofen'] >= 0 and player_mode['piaofen'] <= 10 then
                    player_mode['piaofen'] = 101
                else
                    player_mode['piaofen'] = 0
                end
            elseif szName == '30s' then
                if player_mode['cstg'] == 30 then
                    player_mode['cstg'] = 0
                else
                    player_mode['cstg'] = 30
                end
            elseif szName == '60s' then
                if player_mode['cstg'] == 60 then
                    player_mode['cstg'] = 0
                else
                    player_mode['cstg'] = 60
                end
            elseif szName == '120s' then
                if player_mode['cstg'] == 120 then
                    player_mode['cstg'] = 0
                else
                    player_mode['cstg'] = 120
                end
            end
            initShowOpt()
        end
    end

    -- 给推倒胡界面每一个按钮的添加点击事件
    for i , v in pairs(ltTdhListBtn) do
        local btnTdh = ltTdhListBtn[i]
        btnTdh:addTouchEventListener(btnTdhSelectCallBack)
    end

    ----------------------------------------------------------------------
    -- 拐三角
    local ltGsjListBtn = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "2ren"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "3ren"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "1ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "4ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "8ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "1quan"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "qsd"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "ssy"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "ybz"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "ghznzm"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "dzskh"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "dkskh"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "difen"):getChildByName('minus'), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "difen"):getChildByName('plus'), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, "que1men"), "ccui.Button"),
    }

    local ltGsjQuesContent = {
        ['qsd'] = '勾选此选项，可胡七小对，不勾选此选\n项，不可胡七小对',
        ['ssy'] = '勾选此选项，带风并可胡十三幺，不勾\n选此选项，不带风并不可胡十三幺',
        ['ybz'] = '勾选此选项，胡牌时必须有同花色的牌\n'..
                  '(万，筒，条，风其中一种)张数大于或\n'..
                  '者等于八张，包括点炮、自摸的第14张\n'..
                  '牌，不勾选此选项，胡牌时无此限制',
        ['dzskh'] = '勾选此选项，吊张胡牌时算砍胡，不勾\n选此选项，吊张胡牌不算砍胡',

        ['dkskh'] = '勾选时，只要能凑成砍胡，就算砍胡番型。\n'..
                    '如2234455，可胡3、6，则胡3算砍胡，\n'..
                    '胡6不算。'..
                    '不勾选时，仅听一个才算砍胡，\n'..
                    '如:2234455胡3不算砍胡。1233胡3算砍\n'..
                    '胡。',

        ['que1men'] =   '勾选后，所用牌不含条字牌',
    }

    local function GsjQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel_gsjmj.tipMsgNode and panel_gsjmj.tipMsgNode.lnSelectName ~= szName then
                panel_gsjmj.tipMsgNode:removeFromParent(true)
                panel_gsjmj.tipMsgNode = nil
            end

            if not panel_gsjmj.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'dkskh' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltGsjQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel_gsjmj.tipMsgNode = tipMsgNode
                panel_gsjmj.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel_gsjmj.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel_gsjmj.tipMsgNode:removeFromParent(true)
                    panel_gsjmj.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel_gsjmj.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltGsjQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel_gsjmj, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(GsjQuesBtnCallBack)
    end


    local gsj_desk_mode = 3
    local gsj_ren_mode = 3
    local gsj_player_mode = {}
    gsj_player_mode['qsd'] = false
    gsj_player_mode['ssy'] = false
    gsj_player_mode['ybz'] = false
    gsj_player_mode['ghznzm'] = false
    gsj_player_mode['dzskh'] = false
    gsj_player_mode['difen'] = 1
    gsj_player_mode['dkskh'] = true
    gsj_player_mode['que1men'] = false
    local gsj_str
    local gsj_jushu =1
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_gsj" then
            gsj_player_mode['qsd']      = self.club_room_info.params.isQiXiaoDui
            gsj_player_mode['ssy']      = self.club_room_info.params.is13Yao
            gsj_player_mode['ybz']      = self.club_room_info.params.isYing8Zhang
            gsj_player_mode['ghznzm']   = self.club_room_info.params.isZiMoIfPass
            gsj_player_mode['dzskh']    = self.club_room_info.params.isDanDiaoKan
            gsj_player_mode['difen']    = self.club_room_info.params.diFen
            gsj_player_mode['dkskh']    = self.club_room_info.params.isDaiKanSuanKan
            gsj_player_mode['que1men']  = self.club_room_info.params.isQueYiMen
            gsj_ren_mode                = self.club_room_info.params.people_num
            gsj_jushu                   = self.club_room_info.params.total_ju

            if gsj_ren_mode == 2 then
                if gsj_jushu == 1 then
                    gsj_desk_mode = 1
                elseif gsj_jushu == 8 then
                    gsj_desk_mode = 2
                elseif gsj_jushu == 16 then
                    gsj_desk_mode = 3
                elseif gsj_jushu == 104 then
                    gsj_desk_mode = 4
                end
            else
                if gsj_jushu == 1 then
                    gsj_desk_mode = 1
                elseif gsj_jushu == 4 then
                    gsj_desk_mode = 2
                elseif gsj_jushu == 8 then
                    gsj_desk_mode = 3
                elseif gsj_jushu == 101 then
                    gsj_desk_mode = 4
                end
            end
        else
            gsj_str = cc.UserDefault:getInstance():getStringForKey("qyqgsj_opt", "")
            if gsj_str and gsj_str ~= "" then
                local qyqgsj_opt = json.decode(gsj_str)
                commonlib.echo(qyqgsj_opt)
                for k,v in pairs(qyqgsj_opt) do
                    qyqgsj_opt[k] = v
                end

                gsj_player_mode['qsd'] = qyqgsj_opt['qsd'] or false
                gsj_player_mode['ssy'] = qyqgsj_opt['ssy'] or false
                gsj_player_mode['ybz'] = qyqgsj_opt['ybz'] or false
                gsj_player_mode['ghznzm'] = qyqgsj_opt['ghznzm'] or false
                gsj_player_mode['dzskh'] = qyqgsj_opt['dzskh'] or false
                gsj_player_mode['difen'] = qyqgsj_opt['difen'] or 1
                gsj_player_mode['que1men'] = qyqgsj_opt['que1men'] or false
                if nil ~= qyqgsj_opt['dkskh'] then
                    gsj_player_mode['dkskh'] = qyqgsj_opt['dkskh']
                end

                if qyqgsj_opt['gsj_desk_mode'] and (qyqgsj_opt['gsj_desk_mode'] == 1 or qyqgsj_opt['gsj_desk_mode'] == 2 or qyqgsj_opt['gsj_desk_mode'] == 3 or qyqgsj_opt['gsj_desk_mode'] == 4) then
                    gsj_desk_mode = qyqgsj_opt['gsj_desk_mode']
                else
                    gsj_desk_mode = 3
                end
                gsj_ren_mode = qyqgsj_opt['gsj_ren_mode'] or 3
            end
        end
    else
        gsj_str = cc.UserDefault:getInstance():getStringForKey("gsj_opt", "")
        if gsj_str and gsj_str ~= "" then
            local gsj_opt = json.decode(gsj_str)
            commonlib.echo(gsj_opt)
            for k,v in pairs(gsj_opt) do
                gsj_opt[k] = v
            end

            gsj_player_mode['qsd'] = gsj_opt['qsd'] or false
            gsj_player_mode['ssy'] = gsj_opt['ssy'] or false
            gsj_player_mode['ybz'] = gsj_opt['ybz'] or false
            gsj_player_mode['ghznzm'] = gsj_opt['ghznzm'] or false
            gsj_player_mode['dzskh'] = gsj_opt['dzskh'] or false
            gsj_player_mode['difen'] = gsj_opt['difen'] or 1
            gsj_player_mode['que1men'] = gsj_opt['que1men'] or false
            if nil ~= gsj_opt['dkskh'] then
                gsj_player_mode['dkskh'] = gsj_opt['dkskh']
            end

            if gsj_opt['gsj_desk_mode'] and (gsj_opt['gsj_desk_mode'] == 1 or gsj_opt['gsj_desk_mode'] == 2 or gsj_opt['gsj_desk_mode'] == 3 or gsj_opt['gsj_desk_mode'] == 4) then
                gsj_desk_mode = gsj_opt['gsj_desk_mode']
            else
                gsj_desk_mode = 3
            end
            gsj_ren_mode = gsj_opt['gsj_ren_mode'] or 3
        end
    end
    local ltGsjFen = {1,2,3,5,10,20}

    local ltGsjFenIndex = 1
    for i , v in ipairs(ltGsjFen) do
        if v == gsj_player_mode['difen'] then
            ltGsjFenIndex = i
        end
    end
    local gsj_posX = ltGsjListBtn[5]:getChildByName("fangka"):getPositionX()
    local function initGsjShowOpt()
        local ltRenMode = {2,3}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,gsj_ren_mode == ltRenMode[i])
        end

        if gsj_ren_mode == 2 then
            ltGsjListBtn[4]:setTitleText("8局")
            ltGsjListBtn[5]:setTitleText("16局")
            ltGsjListBtn[5]:getChildByName("fangka"):setPositionX(gsj_posX+10)
            ltGsjListBtn[6]:setTitleText("4圈")
            ltGsjListBtn[15]:setVisible(true)
        else
            ltGsjListBtn[4]:setTitleText("4局")
            ltGsjListBtn[5]:setTitleText("8局")
            ltGsjListBtn[5]:getChildByName("fangka"):setPositionX(gsj_posX)
            ltGsjListBtn[6]:setTitleText("1圈")
            ltGsjListBtn[15]:setVisible(false)
        end

        local num = 3
        for i = 1,4 do
            self:setOpt(ltGsjListBtn[num],nil,gsj_desk_mode == i)
            num = num + 1
        end

        local gsj_player_mode_true_false = {'qsd','ssy','ybz','ghznzm','dzskh','dkskh','que1men'}

        for i , v in pairs(gsj_player_mode_true_false) do
            --log('@!@@@@@@@@@@@@!@!@!@!@! ' .. i)
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, v), "ccui.Button")
            self:setOpt(btnSelect,nil,gsj_player_mode[v])
        end

        local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_gsjmj, 'difen'), "ccui.Button")
        btnSelect:setTitleText(tostring(gsj_player_mode['difen']))
    end

    initGsjShowOpt()

    local function btnGsjSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            if szName == '2ren' then
                gsj_ren_mode = 2
            elseif szName == '3ren' then
                gsj_ren_mode = 3
                gsj_player_mode['que1men'] = false
            elseif szName == '1ju' then
                gsj_desk_mode = 1
            elseif szName == '4ju' then
                gsj_desk_mode = 2
            elseif szName == '8ju' then
                gsj_desk_mode = 3
            elseif szName == '1quan' then
                gsj_desk_mode = 4
            elseif szName == 'ssy' then
                gsj_player_mode['que1men'] = false
                gsj_player_mode['ssy'] = not gsj_player_mode['ssy']
            elseif szName == 'que1men' then
                gsj_player_mode['ssy'] = false
                gsj_player_mode['que1men'] = not gsj_player_mode['que1men']
            elseif szName == 'qsd' or
                szName == 'ybz' or
                szName == 'ghznzm' or
                szName == 'dzskh' or
                szName == 'dkskh'
                then
                gsj_player_mode[szName] = not gsj_player_mode[szName]
            elseif szName == 'minus' then
                if ltGsjFenIndex > 1 then
                    ltGsjFenIndex = ltGsjFenIndex - 1
                end
                gsj_player_mode['difen'] = ltGsjFen[ltGsjFenIndex]
            elseif szName == 'plus' then
                if ltGsjFenIndex < #ltGsjFen then
                    ltGsjFenIndex = ltGsjFenIndex + 1
                end
                gsj_player_mode['difen'] = ltGsjFen[ltGsjFenIndex]
            end
            initGsjShowOpt()
        end
    end

    for i , v in pairs(ltGsjListBtn) do
        local btnGsj = ltGsjListBtn[i]
        btnGsj:addTouchEventListener(btnGsjSelectCallBack)
    end

    ------------------------------------------------------------------------------

    ------------------------------扣点---------------------------------------------
    -- btKd按钮列表  -- 2人 -- 3人 -- 4人 -- 1局   -- 4局   -- 8局，-- 1圈
    local ltKdListBtn = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "2ren"), "ccui.Button"),        --1
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "3ren"), "ccui.Button"),        --2
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "4ren"), "ccui.Button"),        --3

        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "1ju"), "ccui.Button"),         --4
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "4ju"), "ccui.Button"),         --5
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "8ju"), "ccui.Button"),         --6
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "1quan"), "ccui.Button"),       --7

        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "jiafan"), "ccui.Button"),      --8  清一色，一条龙加番
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "zhuohaozi"), "ccui.Button"),   --9  捉耗子
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "fenghaozi"), "ccui.Button"),   --10 风耗子
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "daizhuang"), "ccui.Button"),   --11 带庄
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "zmzffb"), "ccui.Button"),      --12 自摸庄分翻倍
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "gbtkbng"), "ccui.Button"),     --13 改变听口不能杠
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "fengzuizi"), "ccui.Button"),   --14 风嘴子
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "dgbg"), "ccui.Button"),        --15 点杠包杠
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "7duibujiafan"), "ccui.Button"),--16 可胡七对不加番
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "ddhzbzm"), "ccui.Button"),     --17 单吊耗子必自摸
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "dpbg"), "ccui.Button"),        --18 点炮包杠
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "que1men"), "ccui.Button"),     --19 缺一门
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "wuhaozi"), "ccui.Button"),     --20 无耗子
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "fanshangfan"), "ccui.Button"), --21 番上番
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "dahujiadian"), "ccui.Button"), --22 大胡加点
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "3diankting"), "ccui.Button"),  --23 3点可听
        tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "yhbh"), "ccui.Button"),        --24 有胡必胡
    }
    local btn_zmzffb = tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "zmzffb"), "ccui.Button")

    -----------------1280*500分辨率--------------------------
    -- -- 以上面某个准确位置的按钮为对齐标准，例如加番以捉耗子为标准， 大胡加点以风耗子为标准
    -- -- 重新设置位置的情况：前面按钮的位置与其长度之和 小于 将要对其的位置
    -- -- 如果 加番的X坐标加上其长度 小于 捉耗子的X坐标，呢么就重新设置番上番和大胡加点的X坐标,使其垂直对齐
    -- if  ltKdListBtn[8]:getPositionX() + ltKdListBtn[8]:getContentSize().width < ltKdListBtn[9]:getPositionX() then
    --     ltKdListBtn[21]:setPositionX(ltKdListBtn[9]:getPositionX())
    --     ltKdListBtn[22]:setPositionX(ltKdListBtn[10]:getPositionX())
    -- end
    -- -- 改变单吊耗子必自摸的位置 （45.4为 可胡七对不加番空白的多出来的长度）
    -- if ltKdListBtn[16]:getPositionX() + ltKdListBtn[16]:getContentSize().width - 45.4 < ltKdListBtn[9]:getPositionX() then
    --     ltKdListBtn[17]:setPositionX(ltKdListBtn[9]:getPositionX())
    -- end
    -- -- 改变缺一门的位置
    -- if ltKdListBtn[13]:getPositionX() + ltKdListBtn[13]:getContentSize().width < ltKdListBtn[14]:getPositionX() then
    --     ltKdListBtn[19]:setPositionX(ltKdListBtn[14]:getPositionX())
    -- end
    -- -- 改变自摸庄分翻倍的位置
    -- -- 设置自摸庄分翻倍的位置不能超过背景的长度
    -- if ltKdListBtn[14]:getPositionX() + ltKdListBtn[12]:getContentSize().width < panel_kdmj:getContentSize().width then
    --     ltKdListBtn[12]:setPositionX(ltKdListBtn[14]:getPositionX())
    -- end
    -----------------------------------------------------------

    local ltKdHasQuesBtn = {'zhuohaozi', 'fenghaozi', 'daizhuang', 'zmzffb', 'gbtkbng', 'fengzuizi', 'dgbg', 'dpbg',
                            'que1men', 'fanshangfan', 'wuhaozi', 'jiafan','dahujiadian','3diankting', 'yhbh'}

    local ltKdQuesContent = {
        ['zhuohaozi'] = '耗子可以顶替任何搭子（顺子、刻子），\n'..
                        '但是不能顶替杠；四个耗子可以杠；手里\n'..
                        '有2个耗子，别人打一个耗子不可以碰；\n'..
                        '耗子牌不能点炮用。',

        ['fenghaozi'] = '每局从风牌（东西南北中发白）中随机一\n'..
                        '张牌为本局耗子牌。耗子可以替任何顺\n'..
                        '子、刻子，但是不能顶替杠；四个耗子可\n'..
                        '以杠。手里有两个耗子，别人打了一个耗\n'..
                        '子不可以碰；耗子牌不可以点炮用。',

        ['daizhuang'] = '勾选此项，庄家赢牌多得5分，输牌多出5\n'..
                        '分，坐庄规则和圈的坐庄规则相同。',

        ['zmzffb'] =    '勾选此项，庄家自摸胡，多得5*2=10分，\n'..
                        '闲家自摸胡，庄家多出5*2=10分。',

        ['gbtkbng'] =   '勾选此选项，听牌后，少听口或变听口都\n'..
                        '不可以杠。不勾选，听牌后，杠后牌型仍\n'..
                        '能成听，就能杠。',

        ['fengzuizi'] = '东西南北四张牌中任意三张不同的牌可以\n'..
                        '形成顺子，中发白三张牌算一顺子，耗子\n'..
                        '牌可以顶替任何牌，包括中发白成顺中的\n'..
                        '牌或者东西南北任意三张中成顺的牌。',

        ['dgbg'] =      '若勾选，则未报听点杠由点杠者出\n'..
                        '若不勾选，则未报听点杠由三家出\n'..
                        '无论是否勾选，报听后点杠都由三家出。',

        ['dpbg'] =      '勾选此选项，则玩家未报听点炮，\n'..
                        '所有的杠分由点炮玩家赔付。\n'..
                        '若胡牌时，点炮玩家已报听或者为自摸，\n'..
                        '则杠分由点杠包杠选项决定',

        ['que1men'] =   '勾选后，所用牌不含条字牌',

        ['fanshangfan'] =   '若勾选，各大胡之间可互相叠加\n'..
                            '七小对2番，清一色2番，一条龙2番\n'..
                            '十三幺从2番变为4番\n'..
                            '豪华七小对从2番变为4番\n'..
                            '清一色一条龙从2番变为4番\n'..
                            '清一色七小对从2番变为4番\n'..
                            '清一色豪华七小对从2番变为8番',

        ['wuhaozi'] =   '勾选后，即选择的为经典的不带耗子\n'..
                        '的玩法',

        ['jiafan']  =   '勾选后，清一色从原来的1番变为2番\n'..
                        '一条龙从原来的1番变为2番',

        ['dahujiadian']='勾选后，清一色,一条龙,十三幺,七小\n'..
                        '对,豪华七小对胡牌时，额外增加10点\n'..
                        '的胡牌分。各大胡之间可互相叠加，叠\n'..
                        '加方式为相加叠加。',

        ['3diankting'] = '勾选后，听口在3点或者3点以上即可听\n'..
                        '牌，345点只能自摸，6点或者6点以上\n'..
                        '可接炮或自摸。',

        ['yhbh'] =       '勾选后，接炮/自摸/抢杠，不可点过必须\n' ..
                         '胡牌，且为自动胡牌方式。',
    }

    local function kdQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel_kdmj.tipMsgNode and panel_kdmj.tipMsgNode.lnSelectName ~= szName then
                panel_kdmj.tipMsgNode:removeFromParent(true)
                panel_kdmj.tipMsgNode = nil
            end

            if not panel_kdmj.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'fenghaozi' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                if szName == 'fanshangfan' then
                   tipMsgNode:getChildByName("panMsg"):setContentSize(cc.size(380,200))
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltKdQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))
                tipMsgNode:setScaleY(1.5)
                tipMsgNode:setPosition(pos)

                if szName == 'gbtkbng' then
                    pos.x = pos.x - 25
                    tipMsgNode:setPosition(pos)
                end
                panel_kdmj.tipMsgNode = tipMsgNode
                panel_kdmj.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel_kdmj.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel_kdmj.tipMsgNode:removeFromParent(true)
                    panel_kdmj.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel_kdmj.tipMsgNode:runAction(seq)
            end
        end
    end

    for i = 1, #ltKdHasQuesBtn do
        local btSelect = ccui.Helper:seekWidgetByName(panel_kdmj, ltKdHasQuesBtn[i])
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(kdQuesBtnCallBack)
    end

    local kd_desk_mode = 3
    local kd_ren_mode = 4
    local kd_player_mode = {}
    kd_player_mode['jiafan'] = false
    kd_player_mode['zhuohaozi'] = false
    kd_player_mode['fenghaozi'] = false
    kd_player_mode['daizhuang'] = false
    kd_player_mode['zmzffb'] = false
    kd_player_mode['gbtkbng'] = false
    kd_player_mode['fengzuizi'] = false
    kd_player_mode['dgbg'] = true
    kd_player_mode['7duibujiafan'] = false
    kd_player_mode['ddhzbzm'] = false
    kd_player_mode['dpbg'] = false
    kd_player_mode['que1men'] = false
    kd_player_mode['wuhaozi'] = true
    kd_player_mode['fanshangfan'] = false
    kd_player_mode['dahujiadian'] = false
    kd_player_mode['3diankting'] = false
    kd_player_mode['yhbh'] = false
    local kd_str
    local kd_jushu = 1
    if self.clubOpt then
        ----------------群主允许修改玩法，点击桌子的修改玩法
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_kd" then
            kd_player_mode['jiafan']       = self.club_room_info.params.isQYSYTLJF
            kd_player_mode['zhuohaozi']    = self.club_room_info.params.isZhouHaoZi
            kd_player_mode['fenghaozi']    = self.club_room_info.params.isFengHaoZi
            kd_player_mode['daizhuang']    = self.club_room_info.params.isDaiZhuang
            kd_player_mode['zmzffb']       = self.club_room_info.params.isZMZFFB
            kd_player_mode['gbtkbng']      = self.club_room_info.params.isGBTKBNG
            kd_player_mode['fengzuizi']    = self.club_room_info.params.isFengZuiZi
            kd_player_mode['dgbg']         = self.club_room_info.params.isDGBG
            kd_player_mode['7duibujiafan'] = self.club_room_info.params.isKHQDBJF
            kd_player_mode['ddhzbzm']      = self.club_room_info.params.isHZDDBXZM
            kd_player_mode['dpbg']         = self.club_room_info.params.isDPBG
            kd_player_mode['que1men']      = self.club_room_info.params.isQueYiMen
            kd_player_mode['fanshangfan']  = self.club_room_info.params.isFSF

            kd_player_mode['dahujiadian']  = self.club_room_info.params.isDHJD
            kd_player_mode['3diankting']   = self.club_room_info.params.is3DKT
            kd_player_mode['yhbh']         = self.club_room_info.params.isYHBH
            kd_ren_mode                    = self.club_room_info.params.people_num
            kd_jushu                       = self.club_room_info.params.total_ju

            if not self.club_room_info.params.isZhouHaoZi and not self.club_room_info.params.isFengHaoZi then
                kd_player_mode['wuhaozi'] = true
            else
                kd_player_mode['wuhaozi'] = false
            end
            ----------------------------------
            if kd_ren_mode == 2 then
                if kd_jushu == 1 then
                    kd_desk_mode = 1
                elseif kd_jushu == 8 then
                    kd_desk_mode = 2
                elseif kd_jushu == 16 then
                    kd_desk_mode = 3
                elseif kd_jushu == 104 then
                    kd_desk_mode = 4
                end
            else
                if kd_jushu == 1 then
                    kd_desk_mode = 1
                elseif kd_jushu == 4 then
                    kd_desk_mode = 2
                elseif kd_jushu == 8 then
                    kd_desk_mode = 3
                elseif kd_jushu == 101 then
                    kd_desk_mode = 4
                end
            end
        else
            kd_str = cc.UserDefault:getInstance():getStringForKey("qyqkd_opt", "")
            if kd_str and kd_str ~= "" then
                local qyqkd_opt = json.decode(kd_str)
                commonlib.echo(qyqkd_opt)
                for k,v in pairs(qyqkd_opt) do
                    qyqkd_opt[k] = v
                end
                kd_player_mode['jiafan'] = qyqkd_opt['jiafan'] or false
                kd_player_mode['zhuohaozi'] = qyqkd_opt['zhuohaozi'] or false
                kd_player_mode['fenghaozi'] = qyqkd_opt['fenghaozi'] or false
                if kd_player_mode['fenghaozi'] == false and kd_player_mode['zhuohaozi'] == false then
                    kd_player_mode['wuhaozi'] = true
                else
                    kd_player_mode['wuhaozi'] = false
                end
                kd_player_mode['daizhuang'] = qyqkd_opt['daizhuang'] or false
                kd_player_mode['zmzffb'] = qyqkd_opt['zmzffb'] or false
                kd_player_mode['gbtkbng'] = qyqkd_opt['gbtkbng'] or false
                kd_player_mode['fengzuizi'] = qyqkd_opt['fengzuizi'] or false
                if qyqkd_opt['dgbg'] == nil then
                    kd_player_mode['dgbg'] =true
                else
                    kd_player_mode['dgbg'] = qyqkd_opt['dgbg']
                end
                kd_player_mode['dpbg'] = qyqkd_opt['dpbg'] or false
                kd_player_mode['que1men'] = qyqkd_opt['que1men'] or false
                kd_player_mode['7duibujiafan'] = qyqkd_opt['7duibujiafan'] or false
                kd_player_mode['ddhzbzm'] = qyqkd_opt['ddhzbzm'] or false
                if qyqkd_opt['kd_desk_mode'] and (qyqkd_opt['kd_desk_mode'] == 1 or qyqkd_opt['kd_desk_mode'] == 2 or qyqkd_opt['kd_desk_mode'] == 3 or qyqkd_opt['kd_desk_mode'] == 4) then
                    kd_desk_mode = qyqkd_opt['kd_desk_mode']
                else
                    kd_desk_mode = 3
                end
                kd_ren_mode = qyqkd_opt['kd_ren_mode'] or 4
                kd_player_mode['fanshangfan'] = qyqkd_opt['fanshangfan'] or false
                kd_player_mode['dahujiadian'] = qyqkd_opt['dahujiadian'] or false
                kd_player_mode['3diankting']  = qyqkd_opt['3diankting'] or false
                kd_player_mode['yhbh']        = qyqkd_opt['yhbh'] or false
            end
        end
    else
        kd_str = cc.UserDefault:getInstance():getStringForKey("kd_opt", "")
        if kd_str and kd_str ~= "" then
            local kd_opt = json.decode(kd_str)
            commonlib.echo(kd_opt)
            for k,v in pairs(kd_opt) do
                kd_opt[k] = v
            end
            kd_player_mode['jiafan'] = kd_opt['jiafan'] or false
            kd_player_mode['zhuohaozi'] = kd_opt['zhuohaozi'] or false
            kd_player_mode['fenghaozi'] = kd_opt['fenghaozi'] or false
            if kd_player_mode['fenghaozi'] == false and kd_player_mode['zhuohaozi'] == false then
                kd_player_mode['wuhaozi'] = true
            else
                kd_player_mode['wuhaozi'] = false
            end
            kd_player_mode['daizhuang'] = kd_opt['daizhuang'] or false
            kd_player_mode['zmzffb'] = kd_opt['zmzffb'] or false
            kd_player_mode['gbtkbng'] = kd_opt['gbtkbng'] or false
            kd_player_mode['fengzuizi'] = kd_opt['fengzuizi'] or false
            if kd_opt['dgbg'] == nil then
                kd_player_mode['dgbg'] = true
            else
                kd_player_mode['dgbg'] = kd_opt['dgbg']
            end
            kd_player_mode['dpbg'] = kd_opt['dpbg'] or false
            kd_player_mode['que1men'] = kd_opt['que1men'] or false
            kd_player_mode['7duibujiafan'] = kd_opt['7duibujiafan'] or false
            kd_player_mode['ddhzbzm'] = kd_opt['ddhzbzm'] or false
            kd_player_mode['fanshangfan'] = kd_opt['fanshangfan'] or false
            kd_player_mode['dahujiadian'] = kd_opt['dahujiadian'] or false
            kd_player_mode['3diankting']  = kd_opt['3diankting'] or false
            kd_player_mode['yhbh']        = kd_opt['yhbh'] or false
            if kd_opt['kd_desk_mode'] and (kd_opt['kd_desk_mode'] == 1 or kd_opt['kd_desk_mode'] == 2 or kd_opt['kd_desk_mode'] == 3 or kd_opt['kd_desk_mode'] == 4) then
                kd_desk_mode = kd_opt['kd_desk_mode']
            else
                kd_desk_mode = 3
            end
            kd_ren_mode = kd_opt['kd_ren_mode'] or 4
        end
    end
    -- log(kd_desk_mode)
    -- local szDaHuTitle = '玩法：胡牌类型有平胡，七小对，豪华七小对，清一色，十三幺\n，一条龙。'
    -- local szPingHuTitle = '玩法：胡牌类型只有平胡。'
    local kd_posX = ltKdListBtn[6]:getChildByName("fangka"):getPositionX()
    local function initKdShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,kd_ren_mode == ltRenMode[i])
        end

        if kd_ren_mode == 2 then
            ltKdListBtn[5]:setTitleText("8局")
            ltKdListBtn[6]:setTitleText("16局")
            ltKdListBtn[6]:getChildByName("fangka"):setPositionX(kd_posX+10)
            ltKdListBtn[7]:setTitleText("4圈")
            ltKdListBtn[19]:setVisible(true) --缺一门
        else
            ltKdListBtn[5]:setTitleText("4局")
            ltKdListBtn[6]:setTitleText("8局")
            ltKdListBtn[6]:getChildByName("fangka"):setPositionX(kd_posX)
            ltKdListBtn[7]:setTitleText("1圈")
            ltKdListBtn[19]:setVisible(false)
        end
        if kd_player_mode['zhuohaozi'] or kd_player_mode['fenghaozi'] then
            ltKdListBtn[8]:setVisible(false)  -- 清一色
            ltKdListBtn[21]:setVisible(false) -- 番上番
            ltKdListBtn[13]:setVisible(false) -- 改变听口不能杠
            ltKdListBtn[16]:setVisible(true)  -- 可胡七对不加番
            ltKdListBtn[17]:setVisible(true)  -- 单吊耗子必自摸
        else
            ltKdListBtn[8]:setVisible(true)
            ltKdListBtn[21]:setVisible(true)
            ltKdListBtn[13]:setVisible(true)
            ltKdListBtn[16]:setVisible(false)
            ltKdListBtn[17]:setVisible(false)
        end
        if not kd_player_mode['wuhaozi'] then
            kd_player_mode['dahujiadian'] = false
            tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "dahujiadian"), "ccui.Button"):setVisible(false)
        else
            tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, "dahujiadian"), "ccui.Button"):setVisible(true)
        end
        local num = 4
        for i = 1,4 do
            self:setOpt(ltKdListBtn[num],nil,kd_desk_mode == i)
            num = num + 1
        end

        for i , v in pairs(kd_player_mode) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_kdmj, i), "ccui.Button")
            self:setOpt(btnSelect,nil,kd_player_mode[i])
        end

        btn_zmzffb:setVisible(kd_player_mode['daizhuang'])
    end

    initKdShowOpt()

    local function btnKdSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            if szName == '2ren' then
                kd_ren_mode = 2
            elseif szName == '3ren' then
                kd_ren_mode = 3
            elseif szName == '4ren' then
                kd_ren_mode = 4
            elseif szName == '1ju' then
                kd_desk_mode = 1
            elseif szName == '4ju' then
                kd_desk_mode = 2
            elseif szName == '8ju' then
                kd_desk_mode = 3
            elseif szName == '1quan' then
                kd_desk_mode = 4
            elseif szName == 'jiafan' then
                kd_player_mode['jiafan'] = not kd_player_mode['jiafan']
                kd_player_mode['zhuohaozi'] = false
                kd_player_mode['fenghaozi'] = false
                kd_player_mode['dahujiadian'] = false
            elseif szName == 'wuhaozi' then
                kd_player_mode['wuhaozi'] = not kd_player_mode['wuhaozi']
                kd_player_mode['zhuohaozi'] = false
                kd_player_mode['fenghaozi'] = false
            elseif szName == 'zhuohaozi' then
                kd_player_mode['zhuohaozi'] = not kd_player_mode['zhuohaozi']
                kd_player_mode['fenghaozi'] = false
                kd_player_mode['wuhaozi']  = false
            elseif szName == 'fenghaozi' then
                kd_player_mode['fenghaozi'] = not kd_player_mode['fenghaozi']
                kd_player_mode['zhuohaozi'] = false
                kd_player_mode['wuhaozi']  = false
            elseif szName == 'daizhuang' then
                kd_player_mode['daizhuang'] = not kd_player_mode['daizhuang']
                kd_player_mode['zmzffb'] = (not kd_player_mode['daizhuang'] and false)
            elseif szName == 'zmzffb' then
                kd_player_mode['zmzffb'] = not kd_player_mode['zmzffb']
            elseif szName == 'gbtkbng' then
                kd_player_mode['zhuohaozi'] = false
                kd_player_mode['fenghaozi'] = false
                kd_player_mode['gbtkbng'] = not kd_player_mode['gbtkbng']
            elseif szName == 'fengzuizi' then
                kd_player_mode['fengzuizi'] = not kd_player_mode['fengzuizi']
            elseif szName == 'dgbg' then
                kd_player_mode['dgbg'] = not kd_player_mode['dgbg']
            elseif szName == '7duibujiafan' then
                kd_player_mode['7duibujiafan'] = not kd_player_mode['7duibujiafan']
            elseif szName == 'ddhzbzm' then
                kd_player_mode['ddhzbzm'] = not kd_player_mode['ddhzbzm']
            elseif szName == 'dpbg' then
                kd_player_mode['dpbg'] = not kd_player_mode['dpbg']
            elseif szName == 'que1men' then
                kd_player_mode['que1men'] = not kd_player_mode['que1men']
            elseif szName == 'fanshangfan' then
                kd_player_mode['fanshangfan'] = not kd_player_mode['fanshangfan']
                kd_player_mode['dahujiadian'] = false
            elseif szName == 'dahujiadian' then
                kd_player_mode['dahujiadian'] = not kd_player_mode['dahujiadian']
                kd_player_mode['jiafan'] = false
                kd_player_mode['fanshangfan'] = false
            elseif szName == '3diankting' then
                kd_player_mode['3diankting'] = not kd_player_mode['3diankting']
            elseif szName == 'yhbh' then
                kd_player_mode['yhbh'] = not kd_player_mode['yhbh']
            end
            if kd_player_mode['zhuohaozi'] or kd_player_mode['fenghaozi'] then
                kd_player_mode['wuhaozi'] = false
            else
                kd_player_mode['wuhaozi'] = true
            end
            initKdShowOpt()
        end
    end

    for i , v in pairs(ltKdListBtn) do
        local btnKd = ltKdListBtn[i]
        btnKd:addTouchEventListener(btnKdSelectCallBack)
    end
    --]]

    ---------------------------------立四-------------------------------------------
    -- btls按钮列表  -- 2人 -- 3人 -- 4人 -- 1局   -- 4局   -- 8局，-- 1圈
    local ltLsListBtn = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "2ren"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "3ren"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "4ren"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "1ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "4ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "8ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, "1quan"), "ccui.Button"),
    }

    local ls_desk_mode = 3
    local ls_ren_mode = 4
    local ls_str
    local ls_jushu = 1
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_lisi" then
            ls_ren_mode     = self.club_room_info.params.people_num
            ls_jushu        = self.club_room_info.params.total_ju
            ----------------------------------
            if ls_ren_mode == 2 then
                if ls_jushu == 1 then
                    ls_desk_mode = 1
                elseif ls_jushu == 8 then
                    ls_desk_mode = 2
                elseif ls_jushu == 16 then
                    ls_desk_mode = 3
                elseif ls_jushu == 104 then
                    ls_desk_mode = 4
                end
            else
                if ls_jushu == 1 then
                    ls_desk_mode = 1
                elseif ls_jushu == 4 then
                    ls_desk_mode = 2
                elseif ls_jushu == 8 then
                    ls_desk_mode = 3
                elseif ls_jushu == 101 then
                    ls_desk_mode = 4
                end
            end
        else
            ls_str = cc.UserDefault:getInstance():getStringForKey("qyqls_opt", "")
            if ls_str and ls_str ~= "" then
                local qyqls_opt = json.decode(ls_str)
                commonlib.echo(qyqls_opt)
                for k,v in pairs(qyqls_opt) do
                    qyqls_opt[k] = v
                end
                if qyqls_opt['ls_desk_mode'] and (qyqls_opt['ls_desk_mode'] == 1 or qyqls_opt['ls_desk_mode'] == 2 or qyqls_opt['ls_desk_mode'] == 3 or qyqls_opt['ls_desk_mode'] == 4) then
                    ls_desk_mode = qyqls_opt['ls_desk_mode']
                else
                    ls_desk_mode = 3
                end

                ls_ren_mode = qyqls_opt['ls_ren_mode'] or 4
            end
        end
    else
        ls_str = cc.UserDefault:getInstance():getStringForKey("ls_opt", "")
        if ls_str and ls_str ~= "" then
            local ls_opt = json.decode(ls_str)
            commonlib.echo(ls_opt)
            for k,v in pairs(ls_opt) do
                ls_opt[k] = v
            end
            if ls_opt['ls_desk_mode'] and (ls_opt['ls_desk_mode'] == 1 or ls_opt['ls_desk_mode'] == 2 or ls_opt['ls_desk_mode'] == 3 or ls_opt['ls_desk_mode'] == 4) then
                ls_desk_mode = ls_opt['ls_desk_mode']
            else
                ls_desk_mode = 3
            end

            ls_ren_mode = ls_opt['ls_ren_mode'] or 4
        end
    end
    -- local szDaHuTitle = '玩法：胡牌类型有平胡，七小对，豪华七小对，清一色，十三幺\n，一条龙。'
    -- local szPingHuTitle = '玩法：胡牌类型只有平胡。'
    local ls_posX = ltLsListBtn[6]:getChildByName("fangka"):getPositionX()
    local function initLsShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ls_ren_mode == ltRenMode[i])
        end

        local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_lsmj, '1quan'), "ccui.Button")
        if ls_ren_mode == 2 then
            ltLsListBtn[5]:setTitleText("8局")
            ltLsListBtn[6]:setTitleText("16局")
            ltLsListBtn[6]:getChildByName("fangka"):setPositionX(ls_posX+10)
            ltLsListBtn[7]:setTitleText("4圈")
        else
            ltLsListBtn[5]:setTitleText("4局")
            ltLsListBtn[6]:setTitleText("8局")
            ltLsListBtn[6]:getChildByName("fangka"):setPositionX(ls_posX)
            ltLsListBtn[7]:setTitleText("1圈")
        end

        local num = 4
        for i = 1,4 do
            self:setOpt(ltLsListBtn[num],nil,ls_desk_mode == i)
            num = num + 1
        end


        -- if kd_player_mode['dahu'] then
        --     ccui.Helper:seekWidgetByName(panel_lsmj, "wanfa"):setString(szDaHuTitle)
        -- else
        --     ccui.Helper:seekWidgetByName(panel_lsmj, "wanfa"):setString(szPingHuTitle)
        -- end
    end

    initLsShowOpt()

    local function btnLsSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            if szName == '2ren' then
                ls_ren_mode = 2
            elseif szName == '3ren' then
                ls_ren_mode = 3
            elseif szName == '4ren' then
                ls_ren_mode = 4
            elseif szName == '1ju' then
                ls_desk_mode = 1
            elseif szName == '4ju' then
                ls_desk_mode = 2
            elseif szName == '8ju' then
                ls_desk_mode = 3
            elseif szName == '1quan' then
                ls_desk_mode = 4
            end
            initLsShowOpt()
        end
    end

    for i , v in pairs(ltLsListBtn) do
        local btnLs = ltLsListBtn[i]
        btnLs:addTouchEventListener(btnLsSelectCallBack)
    end

    local lnTypeGame = 1

    -- 设置创建房间时整个面板信息
    local function onPayTabCallback(sender)
        -- 设置左边列表中的按钮缩放
        btTdh:setScaleX(btTdh == sender and 1.1 or 1)
        btKd:setScaleX(btKd == sender and 1.1 or 1)
        btLs:setScaleX(btLs == sender and 1.1 or 1)
        btGsj:setScaleX(btGsj == sender and 1.1 or 1)
        btJz:setScaleX(btJz == sender and 1.1 or 1)
        btJzGsj:setScaleX(btJzGsj == sender and 1.1 or 1)

        -- 当前点中的按钮设置不可触摸和禁用状态（按钮按下状态和禁用状态是同一张图片，造成一直选中的错觉），未点中的按钮设置可触摸和正常状态（保证按钮的相互切换）
        btTdh:setTouchEnabled(btTdh ~= sender)
        btTdh:setBright(btTdh ~= sender)
        btKd:setTouchEnabled(btKd ~= sender)
        btKd:setBright(btKd ~= sender)
        btLs:setTouchEnabled(btLs ~= sender)
        btLs:setBright(btLs ~= sender)
        btGsj:setTouchEnabled(btGsj ~= sender)
        btGsj:setBright(btGsj ~= sender)
        btJz:setTouchEnabled(btJz ~= sender)
        btJz:setBright(btJz ~= sender)
        btJzGsj:setTouchEnabled(btJzGsj ~= sender)
        btJzGsj:setBright(btJzGsj ~= sender)

        -- 设置右边点中的面板信息可见，未点中就不可见
        panel_tdh:setVisible(btTdh == sender)
        panel_tdh:setEnabled(btTdh == sender)

        panel_lsmj:setVisible(btLs == sender)
        panel_lsmj:setEnabled(btLs == sender)

        panel_kdmj:setVisible(btKd == sender)
        panel_kdmj:setEnabled(btKd == sender)

        panel_gsjmj:setVisible(btGsj == sender)
        panel_gsjmj:setEnabled(btGsj == sender)

        panel_jzmj:setVisible(btJz == sender)
        panel_jzmj:setEnabled(btJz == sender)

        panel_jzgsjmj:setVisible(btJzGsj == sender)
        panel_jzgsjmj:setEnabled(btJzGsj == sender)

        if btTdh == sender then
            local scrollview_tdh = ccui.Helper:seekWidgetByName(panel_tdh, "scrollview_tdh")
            scrollview_tdh:jumpToTop()
        end
    end

    -- 设置推倒胡模式的点击
    local function onPayTabTdhCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            gt.printTime("onPayTabTdhCallback")
            if sender then
                AudioManager:playPressSound()
            end
            -- log('tdhmj tdhmj tdhmj tdhmj tdhmj tdhmj')
            lnTypeGame = 1 -- 游戏类型
            onPayTabCallback(btTdh)
       end
    end
    -- 给推倒胡模式按钮添加点击事件
    btTdh:addTouchEventListener(onPayTabTdhCallback)

    local function onPayTabKdCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            -- log('kdmj kdmj kdmj kdmj kdmj kdmj')
            lnTypeGame = 2
            onPayTabCallback(btKd)
       end
    end
    btKd:addTouchEventListener(onPayTabKdCallback)

    local function onPayTabLsCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            -- log('lsmj lsmj lsmj lsmj lsmj lsmj')
            lnTypeGame = 3
            onPayTabCallback(btLs)
       end
    end
    btLs:addTouchEventListener(onPayTabLsCallback)

    local function onPayTabGsjCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            -- log('lsmj lsmj lsmj lsmj lsmj lsmj')
            lnTypeGame = 4
            onPayTabCallback(btGsj)
       end
    end
    btGsj:addTouchEventListener(onPayTabGsjCallback)

    local function onPayTabJzCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            -- log('jzmj jzmj jzmj jzmj jzmj jzmj')
            lnTypeGame = 5
            onPayTabCallback(btJz)
       end
    end
    btJz:addTouchEventListener(onPayTabJzCallback)

    local function onPayTabJzGsjCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            -- log('jzgsjmj jzgsjmj jzgsjmj jzgsjmj jzgsjmj jzgsjmj')
            lnTypeGame = 6
            onPayTabCallback(btJzGsj)
       end
    end
    btJzGsj:addTouchEventListener(onPayTabJzGsjCallback)

    -- 左边列表里所有游戏模式按钮和对应回调函数列表
    local pay_call_list = {
        ["mj_tdh"]  = onPayTabTdhCallback,
        ["mj_lisi"] = onPayTabLsCallback,
        ["mj_kd"]   = onPayTabKdCallback,
        ['mj_gsj'] = onPayTabGsjCallback,
        ['mj_jz'] = onPayTabJzCallback,
        ['mj_jzgsj'] = onPayTabJzGsjCallback,
    }
    local pre_key
    if self.clubOpt == 2 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("qyqpre_game1", "mj_tdh")
    elseif self.clubOpt == 3 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("waypre_game1", "mj_tdh")
    else
        pre_key = cc.UserDefault:getInstance():getStringForKey("pre_game1", "mj_tdh")
    end
    if g_author_game then
        pre_key = g_author_game
        tolua.cast(btTdh:getChildByName("zi"), "ccui.ImageView"):loadTexture("ui/qj_createroom/dt_create_room_img_tdh1.png")
    end

    -- 保存上一次创建房间时的界面信息
    local function payCall()
        -- log('@@@@@@@@@@@@@@@@@ ' .. tostring(pre_key))
        if not pay_call_list[pre_key] then
            onPayTabTdhCallback(nil, ccui.TouchEventType.ended)
        else
            pay_call_list[pre_key](nil, ccui.TouchEventType.ended)
        end
    end

    if has_ani then
        ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(false)
        commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "bg"), function()
            ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(true)
            commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):getVirtualRenderer())
            payCall()
        end)
    else
        payCall()
    end

    local ltmake_cards = cc.UserDefault:getInstance():getStringForKey('make_cards', "")
    local ltmake_cards_type = type(ltmake_cards)
    if ltmake_cards_type ~= "table" then
        if ltmake_cards_type == "string" and "" ~= ltmake_cards then
            ltmake_cards = json.decode(ltmake_cards)
        else
            ltmake_cards = yy_make_cards
        end
    end
    local profile = ProfileManager.GetProfile()

    -- 把所修改的数据发送给服务器
    local function mjcj(qz)
        AudioManager:playPressSound()
        local net_msg = nil
        -- 推倒胡
        if lnTypeGame == 1 then
            -- player_mode['suijihaozi'] = true
            local tdh_ju    = 8
            if ren_mode == 2 then
                if desk_mode == 1 then
                    tdh_ju = 1
                elseif desk_mode == 2 then
                    tdh_ju = 8
                elseif desk_mode == 3 then
                    tdh_ju = 16
                end
            else
                if desk_mode == 1 then
                    tdh_ju = 1
                elseif desk_mode == 2 then
                    tdh_ju = 4
                elseif desk_mode == 3 then
                    tdh_ju = 8
                end
            end
            -- log(player_mode['yinghaoqi'])
            -- log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n\n")
            local clientIp = gt.getClientIp()
            net_msg = {
                cmd =NetCmd.C2S_MJ_TDH_CREATE_ROOM,
                total_ju=tdh_ju,
                people_num=ren_mode,
                qunzhu=self.qunzhu,
                copy=0,
                isBaoTing   = player_mode['baoting'],
                isDaiFeng   = player_mode['daifeng'],
                isZhiKeZiMo = player_mode['zimohu'],
                isGBTKBNG   = player_mode['bunenggang'],
                isSJHZ      = player_mode['suijihaozi'],
                isDaHu      = player_mode['dahu'],
                isPingHu    = player_mode['pinghu'],
                isQueYiMen  = player_mode['que1men'],
                isHPBXQM    = player_mode['hpbxqm'],
                isYHQ       = player_mode['yinghaoqi'],
                isGSHZ      = player_mode['gshz'],
                isPiaoFen   = ENABLE_TDH_PIAOFEN and player_mode['piaofen'] or 0,
                rTGT        = player_mode['cstg'],
                make_cards  = ltmake_cards,
                clubOpt = self.clubOpt,
                room_id = self.room_id,
                club_id = self.club_id,
                isGM    = self.isGM,
                lat = clientIp[1],
                lon = clientIp[2],
            }
            local tdh_mode = self:tblCopy(player_mode)
            tdh_mode['desk_mode'] = desk_mode
            tdh_mode['ren_mode'] = ren_mode
            if self.clubOpt then
                if self.clubOpt ~= 2 then
                    cc.UserDefault:getInstance():setStringForKey("qyqtdh_opt", json.encode(tdh_mode))
                end
            else
                cc.UserDefault:getInstance():setStringForKey("tdh_opt", json.encode(tdh_mode))
            end
            cc.UserDefault:getInstance():flush()
            ymkj.SendData:send(json.encode(net_msg))

        elseif lnTypeGame == 2 then
            --  抠点
            if kd_player_mode['wuhaozi'] then
                kd_player_mode['ddhzbzm'] = false
                kd_player_mode['7duibujiafan'] = false
            else
                kd_player_mode['jiafan'] = false
                kd_player_mode['fanshangfan'] = false
                kd_player_mode['gbtkbng'] = false
            end
            local kd_ju = 8
            if kd_ren_mode == 2 then
                if kd_desk_mode == 1 then
                    kd_ju = 1
                elseif kd_desk_mode == 2 then
                    kd_ju = 8
                elseif kd_desk_mode == 3 then
                    kd_ju = 16
                elseif kd_desk_mode == 4 then
                    kd_ju = 104
                end
            else
                kd_player_mode['que1men'] = false
                if kd_desk_mode == 1 then
                    kd_ju = 1
                elseif kd_desk_mode == 2 then
                    kd_ju = 4
                elseif kd_desk_mode == 3 then
                    kd_ju = 8
                elseif kd_desk_mode == 4 then
                    kd_ju = 101
                end
            end
            local clientIp = gt.getClientIp()
            net_msg = {
                cmd =NetCmd.C2S_MJ_KD_CREATE_ROOM,
                total_ju=kd_ju,
                people_num=kd_ren_mode,
                qunzhu=self.qunzhu,
                copy=0,

                isQYSYTLJF   = kd_player_mode['jiafan'],
                isZhouHaoZi  = kd_player_mode['zhuohaozi'],
                isFengHaoZi  = kd_player_mode['fenghaozi'],
                isDaiZhuang  = kd_player_mode['daizhuang'],
                isZMZFFB     = kd_player_mode['zmzffb'],
                isGBTKBNG    = kd_player_mode['gbtkbng'],
                isFengZuiZi  = kd_player_mode['fengzuizi'],
                isDGBG       = kd_player_mode['dgbg'],
                isKHQDBJF    = kd_player_mode['7duibujiafan'],
                isHZDDBXZM   = kd_player_mode['ddhzbzm'],
                isDPBG       = kd_player_mode['dpbg'],
                isQueYiMen   = kd_player_mode['que1men'],
                isFSF        = kd_player_mode['fanshangfan'],
                isDHJD       = kd_player_mode['dahujiadian'],
                is3DKT       = kd_player_mode['3diankting'],
                isYHBH       = kd_player_mode['yhbh'],
                make_cards   = ltmake_cards,
                clubOpt = self.clubOpt,
                room_id = self.room_id,
                club_id = self.club_id,
                isGM    = self.isGM,
                lat = clientIp[1],
                lon = clientIp[2],
              --[[ make_cards = {1,1,2,2,1,2,4,4,4,6,6,6,7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,
                              7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,7,}]]

            }
            ymkj.SendData:send(json.encode(net_msg))

            local kd_mode = self:tblCopy(kd_player_mode)
            kd_mode['kd_desk_mode'] = kd_desk_mode
            kd_mode['kd_ren_mode'] = kd_ren_mode
            if self.clubOpt then
                if self.clubOpt ~= 2 then
                    cc.UserDefault:getInstance():setStringForKey("qyqkd_opt", json.encode(kd_mode))
                end
            else
                cc.UserDefault:getInstance():setStringForKey("kd_opt", json.encode(kd_mode))
            end
            cc.UserDefault:getInstance():flush()
        elseif lnTypeGame == 3 then
            --  立四
            local ls_ju = 8
            if ls_ren_mode == 2 then
                if ls_desk_mode == 1 then
                    ls_ju = 1
                elseif ls_desk_mode == 2 then
                    ls_ju = 8
                elseif ls_desk_mode == 3 then
                    ls_ju = 16
                elseif ls_desk_mode == 4 then
                    ls_ju = 104
                end
            else
                if ls_desk_mode == 1 then
                    ls_ju = 1
                elseif ls_desk_mode == 2 then
                    ls_ju = 4
                elseif ls_desk_mode == 3 then
                    ls_ju = 8
                elseif ls_desk_mode == 4 then
                    ls_ju = 101
                end
            end
            local clientIp = gt.getClientIp()
            net_msg = {
                cmd =NetCmd.C2S_MJ_LISI_CREATE_ROOM,
                total_ju=ls_ju,
                people_num=ls_ren_mode,
                qunzhu=self.qunzhu,
                copy=0,

                make_cards  = ltmake_cards,
                clubOpt = self.clubOpt,
                room_id = self.room_id,
                club_id = self.club_id,
                isGM    = self.isGM,
                lat = clientIp[1],
                lon = clientIp[2],
                --[[make_cards = {7,22,24,5,5,6,6,8,9,17,18,19,23,5,
                            1,1,2,2,3,3,4,4,5,5,6,6,7,
                              7,
                            7,23,24,34,5,6,6,8,9,17,18,19,22,5,
                            1,1,2,2,3,3,4,4,5,5,6,6,7,7,}]]
            }
            ymkj.SendData:send(json.encode(net_msg))
            local ls_mode = {}
            ls_mode['ls_desk_mode'] = ls_desk_mode
            ls_mode['ls_ren_mode'] = ls_ren_mode
            if self.clubOpt then
                if self.clubOpt ~= 2 then
                    cc.UserDefault:getInstance():setStringForKey("qyqls_opt", json.encode(ls_mode))
                end
            else
                cc.UserDefault:getInstance():setStringForKey("ls_opt", json.encode(ls_mode))
            end
            cc.UserDefault:getInstance():flush()
        elseif lnTypeGame == 4 then
            --  拐三角
            local gsj_ju = 8
            if gsj_ren_mode == 2 then
                if gsj_desk_mode == 1 then
                    gsj_ju = 1
                elseif gsj_desk_mode == 2 then
                    gsj_ju = 8
                elseif gsj_desk_mode == 3 then
                    gsj_ju = 16
                elseif gsj_desk_mode == 4 then
                    gsj_ju = 104
                end
            else
                if gsj_desk_mode == 1 then
                    gsj_ju = 1
                elseif gsj_desk_mode == 2 then
                    gsj_ju = 4
                elseif gsj_desk_mode == 3 then
                    gsj_ju = 8
                elseif gsj_desk_mode == 4 then
                    gsj_ju = 101
                end
            end
            local clientIp = gt.getClientIp()
            net_msg = {
                cmd =NetCmd.C2S_MJ_GSJ_CREATE_ROOM,
                total_ju=gsj_ju,
                people_num=gsj_ren_mode,
                qunzhu=self.qunzhu,
                copy=0,

                isQiXiaoDui         = gsj_player_mode['qsd'],
                is13Yao             = gsj_player_mode['ssy'],
                isYing8Zhang        = gsj_player_mode['ybz'],
                isZiMoIfPass        = gsj_player_mode['ghznzm'],
                isDanDiaoKan        = gsj_player_mode['dzskh'],
                diFen               = gsj_player_mode['difen'],
                isDaiKanSuanKan     = gsj_player_mode['dkskh'],
                isQueYiMen          = gsj_player_mode['que1men'],

                make_cards  = ltmake_cards,
                clubOpt = self.clubOpt,
                room_id = self.room_id,
                club_id = self.club_id,
                isGM    = self.isGM,
                lat = clientIp[1],
                lon = clientIp[2],
              --[[ make_cards = {1,1,2,2,1,2,4,4,4,6,6,6,7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,
                              7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,7,
                           1,1,2,2,3,3,4,4,5,5,6,6,7,7,}]]

            }

            ymkj.SendData:send(json.encode(net_msg))
            local gsj_mode = self:tblCopy(gsj_player_mode)
            gsj_mode['gsj_desk_mode'] = gsj_desk_mode
            gsj_mode['gsj_ren_mode'] = gsj_ren_mode
            if self.clubOpt then
                if self.clubOpt ~= 2 then
                    cc.UserDefault:getInstance():setStringForKey("qyqgsj_opt", json.encode(gsj_mode))
                end
            else
                cc.UserDefault:getInstance():setStringForKey("gsj_opt", json.encode(gsj_mode))
            end
            cc.UserDefault:getInstance():flush()
        elseif lnTypeGame == 5 then
            self:sendCreateJz(ltmake_cards)
        elseif lnTypeGame == 6 then
            self:sendCreateJsGsjRoom(ltmake_cards)
        end
    end

    ccui.Helper:seekWidgetByName(panel_room,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])==0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                -- 修改亲友圈单座玩法或整个亲友圈的玩法
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            mjcj(0)
                        end
                    end)
                else --创建普通房间
                    mjcj(0)
                end
            end
            self.mjButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)
end

-- 创建河北麻将创房界面
function CreateLayer:createMJHeBeiRoomUI(has_ani)
    local bddbz_off = false
    local panel_room = nil
    if self.panel_roomMJHeiBei then
        panel_room = self.panel_roomMJHeiBei
        panel_room:setVisible(true)
        self.panel_room = panel_room
        return
    else
        local csb = DTUI.getInstance().csb_DT_CreateroomLayer_hebei
        panel_room = tolua.cast(cc.CSLoader:createNode(csb),"ccui.Widget")
        self:addChild(panel_room)
        self.panel_room = panel_room
        self.panel_roomMJHeiBei = panel_room
    end

    ccui.Helper:seekWidgetByName(panel_room, "ScrollView_1"):setDirection(0)
    panel_room:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(panel_room)

    if has_ani then
        commonlib.moveTo(ccui.Helper:seekWidgetByName(panel_room, "Panel_Tabbg"), true, function()
        end)
    end

    self:refreshMainGameUI(panel_room)

    -- 河北麻将
    local panel_hbmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "hbmj"), "ccui.Widget")
    panel_hbmj:setVisible(false)
    panel_hbmj:setEnabled(false)

    local btHeBeiMJ = ccui.Helper:seekWidgetByName(panel_room, "btHeBeiMJ")

    -- 河北推倒胡麻将
    local panel_hbtdh = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "hbtdh"), "ccui.Widget")
    panel_hbtdh:setVisible(false)
    panel_hbtdh:setEnabled(false)

    local btHeBeiTdh = ccui.Helper:seekWidgetByName(panel_room, "btHeBeiTdh")

    -- 保定打八张
    local panel_bddbz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "bddbz"), "ccui.Widget")
    panel_bddbz:setVisible(false)
    panel_bddbz:setEnabled(false)

    local btBaodingDbz = ccui.Helper:seekWidgetByName(panel_room, "btBaodingDbz")

    -- 丰宁
    local panel_fnmj = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "fnmj"), "ccui.Widget")
    panel_fnmj:setVisible(false)
    panel_fnmj:setEnabled(false)

    local btFengNing = ccui.Helper:seekWidgetByName(panel_room, "btFengNing")

    if bddbz_off then
        btBaodingDbz:setVisible(false)
        btBaodingDbz:setTouchEnabled(false)
    end

    -- 返回按钮
    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(panel_room,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    self:createHeBei(panel_hbmj)    -- 4890行

    self:createHeBeiTdh(panel_hbtdh) -- 5267行

    self:createBaoDingDbz(panel_bddbz) -- 5747行

    self:createFengNing(panel_fnmj)

    local szTypeGame = 'HeBeiMj'
    local gameTable = {
        {
            btn = btHeBeiMJ,
            panel = panel_hbmj,
            type_name = 'HeBeiMj',
        },
        {
            btn = btHeBeiTdh,
            panel = panel_hbtdh,
            type_name = 'HeBeiTdh',
        },
        {
            btn = btFengNing,
            panel = panel_fnmj,
            type_name = 'FengNing',
        },
    }

    if not bddbz_off then
        gameTable[#gameTable+1] = {
            btn = btBaodingDbz,
            panel = panel_bddbz,
            type_name = 'BaoDingDbz',
        }
    end

    -- 显示河北麻将的哪一种形式（河北麻将、河北推倒胡，保定打八张）
    local function onPayTabCallback(sender)
        for i , v in ipairs(gameTable) do
            local btn = v.btn
            local panel = v.panel
            local type_name = v.type_name

            btn:setScaleX(btn == sender and 1.1 or 1)
            btn:setTouchEnabled(btn ~= sender)
            btn:setBright(btn ~= sender)

            panel:setVisible(btn == sender)
            panel:setEnabled(btn == sender)

            szTypeGame = (btn == sender and type_name or szTypeGame)
        end
    end
    local function onPayTabBtnCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then
            if sender then
                AudioManager:playPressSound()
            end
            onPayTabCallback(sender)
       end
    end
    for i , v in ipairs(gameTable) do
        local btn = v.btn
        btn:addTouchEventListener(onPayTabBtnCallback)
    end

    local pay_call_list = {
        ["mj_hebei"]    = btHeBeiMJ,
        ['mj_hbtdh']    = btHeBeiTdh,
        ['mj_dbz']      = btBaodingDbz,
        ['mj_fn']       = btFengNing,
    }
    local pre_key
    if self.clubOpt == 2 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("qyqpre_game_hebei", "mj_hebei")
    elseif self.clubOpt == 3 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("waypre_game_hebei", "mj_hebei")
    else
        pre_key = cc.UserDefault:getInstance():getStringForKey("pre_game_hebei", "mj_hebei")
    end
    if g_author_game then
        pre_key = g_author_game
        tolua.cast(btTdh:getChildByName("zi"), "ccui.ImageView"):loadTexture("ui/qj_createroom/dt_create_room_img_tdh1.png")
    end

    local function payCall()
        if not pay_call_list[pre_key] then
            onPayTabCallback(btHeBeiMJ)
        else
            onPayTabCallback(pay_call_list[pre_key])
        end
    end
    if has_ani then
        ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(false)
        commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "bg"), function()
            ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(true)
            commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):getVirtualRenderer())
            payCall()
        end)
    else
        payCall()
    end

    local ltmake_cards = cc.UserDefault:getInstance():getStringForKey('make_cards', "")
    local ltmake_cards_type = type(ltmake_cards)
    if ltmake_cards_type ~= "table" then
        if ltmake_cards_type == "string" and "" ~= ltmake_cards then
            ltmake_cards = json.decode(ltmake_cards)
        else
            ltmake_cards = yy_make_cards
        end
    end

    local function hbmjcj(qz)
        AudioManager:playPressSound()
        local net_msg = nil
        -- 河北麻将
        if szTypeGame == 'HeBeiMj' then
            self:sendCreateHeBeiRoom(ltmake_cards)
        elseif szTypeGame == 'HeBeiTdh' then
            self:sendCreateHeBeiTdhRoom(ltmake_cards)
        elseif szTypeGame == 'BaoDingDbz' then
            if not bddbz_off then
                self:sendCreateBaoDingDbzRoom(ltmake_cards)
            end
        elseif szTypeGame == 'FengNing' then
            self:sendCreateFengNingRoom(ltmake_cards)
        end
    end

    local profile = ProfileManager.GetProfile()
    local clientIp = gt.getClientIp()
    ccui.Helper:seekWidgetByName(panel_room,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])== 0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            hbmjcj(0)
                        end
                    end)
                else
                    hbmjcj(0)
                end
            end
            self.hbmjButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)
end

-- 创建陕西麻将创房界面
function CreateLayer:createMJ2RoomUI(has_ani)
    local clientIp = gt.getClientIp()
    local panel_room = nil
    if self.panel_roomMJ2 then
        panel_room = self.panel_roomMJ2
        panel_room:setVisible(true)
        self.panel_room = panel_room
        return
    else
        local csb = DTUI.getInstance().csb_DT_CreateroomLayer_sxmj2
        panel_room = tolua.cast(cc.CSLoader:createNode(csb),"ccui.Widget")
        self:addChild(panel_room)
        self.panel_room = panel_room
        self.panel_roomMJ2 = panel_room
    end

    local sc = ccui.Helper:seekWidgetByName(panel_room, "ScrollView_1")

    panel_room:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(panel_room)

    if has_ani then
        commonlib.moveTo(ccui.Helper:seekWidgetByName(panel_room, "Panel_Tabbg"), true, function()
        end)
    else
        sc:setClippingEnabled(true)
    end

    self:refreshMainGameUI(panel_room)

    local panel_list = {
        ccui.Helper:seekWidgetByName(panel_room, "xamj"),
    }

    for __, v in ipairs(panel_list) do
        v:setVisible(false)
        v:setEnabled(false)
    end

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(panel_room,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
                self.panel_room = nil
            end
        end
    )

    local btnXamj = ccui.Helper:seekWidgetByName(panel_room, "btXamj")
    ---------------------xamj-----------------
    local xamj_mode = { 3,--1    局数
                        1,--2    只炸不胡
                        1,--3    下炮子
                        1,--4    红中癞子
                        1,--5    258硬将
                        1,--6    带风
                        1,--7    清一色
                        1,--8    胡258加番
                        1,--9    将258加番
                        0,--10   可胡七对(加番)
                        4,--11   人数
                        0,--12   缺一门
                        }
    local xamj_str
    local xamj_jushu = 1
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_xian" then
            xamj_mode[2]    = self.club_room_info.params.isZhiKeZiMo
            xamj_mode[3]    = self.club_room_info.params.isXiaPaoZi
            xamj_mode[4]    = self.club_room_info.params.isHongZhong
            xamj_mode[5]    = self.club_room_info.params.is258Jiang
            xamj_mode[6]    = self.club_room_info.params.isDaiFeng
            xamj_mode[7]    = self.club_room_info.params.isQingYiSe
            xamj_mode[8]    = self.club_room_info.params.isHu258Fan
            xamj_mode[9]    = self.club_room_info.params.isJiang258Fan
            xamj_mode[10]   = self.club_room_info.params.canHuQiDui
            xamj_mode[11]   = self.club_room_info.params.people_num
            xamj_mode[12]   = self.club_room_info.params.isQueYiMen
            xamj_jushu      = self.club_room_info.params.total_ju
            if xamj_mode[11] == 2 then
                if xamj_jushu == 1 then
                    xamj_mode[1] = 1
                elseif xamj_jushu == 8 then
                    xamj_mode[1] = 2
                elseif xamj_jushu == 16 then
                    xamj_mode[1] = 3
                elseif xamj_jushu == 104 then
                    xamj_mode[1] = 4
                end
            else
                if xamj_jushu == 1 then
                    xamj_mode[1] = 1
                elseif xamj_jushu == 4 then
                    xamj_mode[1] = 2
                elseif xamj_jushu == 8 then
                    xamj_mode[1] = 3
                elseif xamj_jushu == 101 then
                    xamj_mode[1] = 4
                end
            end
        else
            xamj_str = cc.UserDefault:getInstance():getStringForKey("qyqxamj_opt", "")
            if xamj_str and xamj_str ~= "" then
                local qyqxamj_opt = json.decode(xamj_str)
                for k,v in pairs(qyqxamj_opt) do
                    xamj_mode[k] = v
                end
                -- log()
                if xamj_mode[1] and (xamj_mode[1] == 1 or xamj_mode[1] == 2 or xamj_mode[1] == 3 or xamj_mode[1] == 4) then
                    xamj_mode[1] = xamj_mode[1]
                else
                    xamj_mode[1] = 3
                end
            end
        end
    else
        xamj_str = cc.UserDefault:getInstance():getStringForKey("xamj_opt", "")
        if xamj_str and xamj_str ~= "" then
            local xamj_opt = json.decode(xamj_str)
            for k,v in pairs(xamj_opt) do
                xamj_mode[k] = v
            end
            -- log()
            if xamj_mode[1] and (xamj_mode[1] == 1 or xamj_mode[1] == 2 or xamj_mode[1] == 3 or xamj_mode[1] == 4) then
                xamj_mode[1] = xamj_mode[1]
            else
                xamj_mode[1] = 3
            end
        end
    end

    local xamj_btn_list = {
        ccui.Helper:seekWidgetByName(panel_list[1],"1ju"),           --1  1局
        ccui.Helper:seekWidgetByName(panel_list[1],"4ju"),              --2  4局
        ccui.Helper:seekWidgetByName(panel_list[1],"8ju"),              --3  8局
        ccui.Helper:seekWidgetByName(panel_list[1],"1quan"),            --4 1圈
        ccui.Helper:seekWidgetByName(panel_list[1],"zhizhabuhu"),       --5  只炸不胡
        ccui.Helper:seekWidgetByName(panel_list[1],"xiapaozi"),         --6  下炮子
        ccui.Helper:seekWidgetByName(panel_list[1],"hongzhonglaizi"),   --7 红中癞子
        ccui.Helper:seekWidgetByName(panel_list[1],"258yingjiang"),     --8 258硬将
        ccui.Helper:seekWidgetByName(panel_list[1],"daifan"),           --9 带风
        ccui.Helper:seekWidgetByName(panel_list[1],"qingyise"),         --10 清一色
        ccui.Helper:seekWidgetByName(panel_list[1],"hu258jiafan"),      --11 胡258加番
        ccui.Helper:seekWidgetByName(panel_list[1],"jiang258jiafan"),   --12 将258加番
        ccui.Helper:seekWidgetByName(panel_list[1],"qiduijiafan"),      --13 可胡七对(加番)
        ccui.Helper:seekWidgetByName(panel_list[1],"qiduibujiafan"),    --14 可胡七对(不加番)
        ccui.Helper:seekWidgetByName(panel_list[1],"2ren"),    --15 2人
        ccui.Helper:seekWidgetByName(panel_list[1],"3ren"),    --16 3人
        ccui.Helper:seekWidgetByName(panel_list[1],"4ren"),    --17 4人
        ccui.Helper:seekWidgetByName(panel_list[1],"que1men"), --18 缺一门

    }
    local ltXiAnHasQuesBtn = {'que1men'}

    local ltXiAnQuesContent = {
            ['que1men']  = '勾选后，所用牌不含条字牌',
    }

    local function xianQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel_list[1].tipMsgNode and panel_list[1].tipMsgNode.lnSelectName ~= szName then
                panel_list[1].tipMsgNode:removeFromParent(true)
                panel_list[1].tipMsgNode = nil
            end

            if not panel_list[1].tipMsgNode then
                local tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltXiAnQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel_list[1].tipMsgNode = tipMsgNode
                panel_list[1].tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel_list[1].tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel_list[1].tipMsgNode:removeFromParent(true)
                    panel_list[1].tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel_list[1].tipMsgNode:runAction(seq)
            end
        end
    end

    local btSelect = ccui.Helper:seekWidgetByName(panel_list[1], 'que1men')
    local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
    btQues:addTouchEventListener(xianQuesBtnCallBack)

    local xian_posX = xamj_btn_list[3]:getChildByName("fangka"):getPositionX()
    local function initXAMJShowOpt()
        if xamj_mode[1] == 1 then
            self:setOpt(xamj_btn_list[1], true, true)
            self:setOpt(xamj_btn_list[2], true, false)
            self:setOpt(xamj_btn_list[3], true, false)
            self:setOpt(xamj_btn_list[4], true, false)
        elseif xamj_mode[1] == 2 then
            self:setOpt(xamj_btn_list[1], true, false)
            self:setOpt(xamj_btn_list[2], true, true)
            self:setOpt(xamj_btn_list[3], true, false)
            self:setOpt(xamj_btn_list[4], true, false)
        elseif xamj_mode[1] == 3 then
            self:setOpt(xamj_btn_list[1], true, false)
            self:setOpt(xamj_btn_list[2], true, false)
            self:setOpt(xamj_btn_list[3], true, true)
            self:setOpt(xamj_btn_list[4], true, false)
        elseif xamj_mode[1] == 4 then
            self:setOpt(xamj_btn_list[1], true, false)
            self:setOpt(xamj_btn_list[2], true, false)
            self:setOpt(xamj_btn_list[3], true, false)
            self:setOpt(xamj_btn_list[4], true, true)
        end

        if xamj_mode[2] == 1 then
            self:setOpt(xamj_btn_list[5], false, true)
        else
            self:setOpt(xamj_btn_list[5], false, false)
        end
        if xamj_mode[3] == 1 then
            self:setOpt(xamj_btn_list[6], false, true)
        else
            self:setOpt(xamj_btn_list[6], false, false)
        end
        if xamj_mode[4] == 1 then
            self:setOpt(xamj_btn_list[7], false, true)
        else
            self:setOpt(xamj_btn_list[7], false, false)
        end
        if xamj_mode[5] == 1 then
            self:setOpt(xamj_btn_list[8], false, true)
        else
            self:setOpt(xamj_btn_list[8], false, false)
        end
        if xamj_mode[6] == 1 then
            self:setOpt(xamj_btn_list[9], false, true)
        else
            self:setOpt(xamj_btn_list[9], false, false)
        end
        if xamj_mode[7] == 1 then
            self:setOpt(xamj_btn_list[10], false, true)
        else
            self:setOpt(xamj_btn_list[10], false, false)
        end
        if xamj_mode[8] == 1 then
            self:setOpt(xamj_btn_list[11], false, true)
        else
            self:setOpt(xamj_btn_list[11], false, false)
        end
        if xamj_mode[9] == 1 then
            self:setOpt(xamj_btn_list[12], false, true)
        else
            self:setOpt(xamj_btn_list[12], false, false)
        end
        if xamj_mode[10] == 0 then
            self:setOpt(xamj_btn_list[13], false, false)
            self:setOpt(xamj_btn_list[14], false, false)
        elseif xamj_mode[10] == 1 then
            self:setOpt(xamj_btn_list[13], false, false)
            self:setOpt(xamj_btn_list[14], false, true)
        elseif xamj_mode[10] == 2 then
            self:setOpt(xamj_btn_list[13], false, true)
            self:setOpt(xamj_btn_list[14], false, false)
        end
        if xamj_mode[11] == 2 then
            self:setOpt(xamj_btn_list[15], false, true)
            self:setOpt(xamj_btn_list[16], false, false)
            self:setOpt(xamj_btn_list[17], false, false)
        elseif xamj_mode[11] == 3 then
            self:setOpt(xamj_btn_list[15], false, false)
            self:setOpt(xamj_btn_list[16], false, true)
            self:setOpt(xamj_btn_list[17], false, false)
        elseif xamj_mode[11] == 4 then
            self:setOpt(xamj_btn_list[15], false, false)
            self:setOpt(xamj_btn_list[16], false, false)
            self:setOpt(xamj_btn_list[17], false, true)
        end
        if xamj_mode[11] == 2 then
            xamj_btn_list[2]:setTitleText("8局")
            xamj_btn_list[3]:setTitleText("16局")
            xamj_btn_list[4]:setTitleText("4圈")
            xamj_btn_list[3]:getChildByName("fangka"):setPositionX(xian_posX+10)
            xamj_btn_list[18]:setVisible(true)
        else
            xamj_btn_list[2]:setTitleText("4局")
            xamj_btn_list[3]:setTitleText("8局")
            xamj_btn_list[4]:setTitleText("1圈")
            xamj_btn_list[3]:getChildByName("fangka"):setPositionX(xian_posX)
            xamj_btn_list[18]:setVisible(false)
        end
        if xamj_mode[12] == 1 then
            self:setOpt(xamj_btn_list[18], false, true)
        else
            self:setOpt(xamj_btn_list[18], false, false)
        end
    end

    initXAMJShowOpt()

    for i, v in ipairs(xamj_btn_list) do
        v:addTouchEventListener(function(__,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i==1 then
                    xamj_mode[1] = 1
                    initXAMJShowOpt()
                elseif i==2 then
                    xamj_mode[1] = 2
                    initXAMJShowOpt()
                elseif i== 3 then
                    xamj_mode[1] = 3
                    initXAMJShowOpt()
                elseif i == 4 then
                    xamj_mode[1] = 4
                    initXAMJShowOpt()
                elseif i==5 then
                    if xamj_mode[2] == 1 then
                        xamj_mode[2] = 0
                    else
                        xamj_mode[2] = 1
                    end
                    initXAMJShowOpt()
                elseif i==6 then
                    if xamj_mode[3] == 1 then
                        xamj_mode[3] = 0
                    else
                        xamj_mode[3] = 1
                    end
                    initXAMJShowOpt()
                elseif i==7 then
                   if xamj_mode[4] == 1 then
                        xamj_mode[4] = 0
                    else
                        xamj_mode[4] = 1
                    end
                    initXAMJShowOpt()
                elseif i==8 then
                    if xamj_mode[5] == 1 then
                        xamj_mode[5] = 0
                    else
                        xamj_mode[5] = 1
                    end
                    initXAMJShowOpt()
                elseif i==9 then
                    if xamj_mode[6] == 1 then
                        xamj_mode[6] = 0
                    else
                        xamj_mode[6] = 1
                    end
                    initXAMJShowOpt()
                elseif i==10 then
                    if xamj_mode[7] == 1 then
                        xamj_mode[7] = 0
                    else
                        xamj_mode[7] = 1
                    end
                    initXAMJShowOpt()
                elseif i==11 then
                    if xamj_mode[8] == 1 then
                        xamj_mode[8] = 0
                    else
                        xamj_mode[8] = 1
                    end
                    initXAMJShowOpt()
                elseif i==12 then
                    if xamj_mode[9] == 1 then
                        xamj_mode[9] = 0
                    else
                        xamj_mode[9] = 1
                    end
                    initXAMJShowOpt()
                elseif i==13 then
                    if xamj_mode[10] == 2 then
                        xamj_mode[10] = 0
                    else
                        xamj_mode[10] = 2
                    end
                    initXAMJShowOpt()
                elseif i==14 then
                    if xamj_mode[10] == 1 then
                        xamj_mode[10] = 0
                    else
                        xamj_mode[10] = 1
                    end
                    initXAMJShowOpt()
                elseif i == 15 then
                    xamj_mode[11] = 2
                    initXAMJShowOpt()
                elseif i == 16 then
                    xamj_mode[11] = 3
                    xamj_mode[12] = 0
                    initXAMJShowOpt()
                elseif i == 17 then
                    xamj_mode[11] = 4
                    xamj_mode[12] = 0
                    initXAMJShowOpt()
                elseif i == 18 then
                    if xamj_mode[12] == 1 then
                        xamj_mode[12] = 0
                    else
                        xamj_mode[12] = 1
                    end
                    initXAMJShowOpt()
                end
            end
        end)
    end

    local function onPayTabXACallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then

            if sender then
                AudioManager:playPressSound()
            end
            btnXamj:setTouchEnabled(false)
            btnXamj:setBright(false)
            btnXamj:setScaleX(1.1)

            panel_list[1]:setVisible(true)
            panel_list[1]:setEnabled(true)


        end
    end
    btnXamj:addTouchEventListener(onPayTabXACallback)
    local pay_btn_list = {
            xamj = onPayTabXACallback,
            }
    local pre_key
    if self.clubOpt == 2 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("qyqpre_game2", "xamj")
    elseif self.clubOpt == 3 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("waypre_game2", "xamj")
    else
        pre_key = cc.UserDefault:getInstance():getStringForKey("pre_game2", "xamj")
    end
    if g_author_game then
        pre_key = g_author_game

    end

    local function payCall()
        -- log('@@@@@@@@@@@@@@@@@ ' .. tostring(pre_key))
        if not pay_btn_list[pre_key] then
            onPayTabXACallback(nil, ccui.TouchEventType.ended)
        else
            pay_btn_list[pre_key](nil, ccui.TouchEventType.ended)
        end
    end
    if has_ani then
        ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(false)
        commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "bg"), function()
            ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(true)
            commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):getVirtualRenderer())
            payCall()
        end)
    else
        payCall()
    end
    local ltmake_cards = cc.UserDefault:getInstance():getStringForKey('make_cards', "")
    if ltmake_cards and "" ~= ltmake_cards then
        ltmake_cards = json.decode(ltmake_cards)
    else
        ltmake_cards = nil
    end

    local profile = ProfileManager.GetProfile()
    local function xamjcj(qz)
        AudioManager:playPressSound()
        local xamj_ju = 8
        if xamj_mode[11] == 2 then
            if xamj_mode[1] == 1 then
                xamj_ju = 1
            elseif xamj_mode[1] == 2 then
                xamj_ju = 8
            elseif xamj_mode[1] == 3 then
                xamj_ju = 16
            elseif xamj_mode[1] == 4 then
                xamj_ju = 104
            end
        else
            if xamj_mode[1] == 1 then
                xamj_ju = 1
            elseif xamj_mode[1] == 2 then
                xamj_ju = 4
            elseif xamj_mode[1] == 3 then
                xamj_ju = 8
            elseif xamj_mode[1] == 4 then
                xamj_ju = 101
            end
        end
        local clientIp = gt.getClientIp()
        local net_msg = {
            cmd = NetCmd.C2S_MJ_XIAN_CREATE_ROOM,
            total_ju = xamj_ju,
            people_num = xamj_mode[11],
            -- game_type = "mj_xian",
            isZhiKeZiMo = xamj_mode[2],
            isXiaPaoZi = xamj_mode[3],
            isHongZhong = xamj_mode[4],
            is258Jiang = xamj_mode[5],
            isDaiFeng = xamj_mode[6],
            isQingYiSe = xamj_mode[7],
            isHu258Fan = xamj_mode[8],
            isJiang258Fan = xamj_mode[9],
            canHuQiDui = xamj_mode[10],
            isQueYiMen = xamj_mode[12],
            clubOpt = self.clubOpt,
            room_id = self.room_id,
            club_id = self.club_id,
            qunzhu=self.qunzhu,
            make_cards  = ltmake_cards,
            isGM    = self.isGM,
            lat = clientIp[1],
            lon = clientIp[2],
        }
        ymkj.SendData:send(json.encode(net_msg))
        if self.clubOpt then
            if self.clubOpt ~= 2 then
                cc.UserDefault:getInstance():setStringForKey("qyqxamj_opt", json.encode(xamj_mode))
            end
        else
            cc.UserDefault:getInstance():setStringForKey("xamj_opt", json.encode(xamj_mode))
        end
        cc.UserDefault:getInstance():flush()
    end

    ccui.Helper:seekWidgetByName(panel_room,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1]) and tonumber(clientIp[2]) then
                commonlib.avoidJoinTip()
            else
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            xamjcj(0)
                        end
                    end)
                else
                    xamjcj(0)
                end
            end
            self.xaButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)

    panel_list[1]:setEnabled(true)
    panel_list[1]:setVisible(true)
end

-- 创建扑克创房界面
function CreateLayer:createPokerRoomUI(has_ani)
    local clientIp = gt.getClientIp()
    local panel_room = nil
    if self.panel_roomPK then
        panel_room = self.panel_roomPK
        panel_room:setVisible(true)
        self.panel_room = panel_room
        return
    else
        local csb = DTUI.getInstance().csb_DT_CreateroomLayer_poker
        panel_room = tolua.cast(cc.CSLoader:createNode(csb),"ccui.Widget")
        self:addChild(panel_room)
        self.panel_room = panel_room
        self.panel_roomPK = panel_room
    end

    ccui.Helper:seekWidgetByName(panel_room, "ScrollView_1"):setDirection(0)

    panel_room:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(panel_room)

    if has_ani then
        commonlib.moveTo(ccui.Helper:seekWidgetByName(panel_room, "Panel_Tabbg"), true, function()
        end)
    end

    self:refreshMainGameUI(panel_room)

    ---跑得快
    local panel_pdk = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "pdk"), "ccui.Widget")
    panel_pdk:setVisible(false)
    panel_pdk:setEnabled(false)
    ---斗地主
    local panel_ddz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "ddz"), "ccui.Widget")
    panel_ddz:setVisible(false)
    panel_ddz:setEnabled(false)

    -- 扎股子
    local panel_zgz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "zgz"), "ccui.Widget")
    panel_zgz:setVisible(false)
    panel_zgz:setEnabled(false)

    local panel_jdpdk = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "jdpdk"), "ccui.Widget")
    panel_jdpdk:setVisible(false)
    panel_jdpdk:setEnabled(false)

    self:createJdpdk(panel_jdpdk)

    self:createZhuoHongSan(panel_zgz)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(panel_room,"btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    local btPdk = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btPdk"), "ccui.Button")
    local btDdz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btDdz"), "ccui.Button")
    -- 捉红三
    local btZgz = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btZgz"), "ccui.Button")
    local btJdpdk = tolua.cast(ccui.Helper:seekWidgetByName(panel_room, "btJdpdk"), "ccui.Button")

    -------------------------pdk---------------------
    local pdk_btn_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"10ju"), "ccui.Button"),          --1
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"20ju"), "ccui.Button"),          --2
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"3ren"), "ccui.Button"),          --3
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"2ren"), "ccui.Button"),          --4
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"15zhang"), "ccui.Button"),       --5
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"16zhang"), "ccui.Button"),       --6
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"qie4zhang"), "ccui.Button"),     --7
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"daihouzi"), "ccui.Button"),      --8
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"heitao3bd"), "ccui.Button"),     --9
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"3dz"), "ccui.Button"),           --10
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"ydz"), "ccui.Button"),           --11
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"bkqg"), "ccui.Button"),          --12
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"zdbkc"), "ccui.Button"),         --13
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"paishu"), "ccui.Button"),        --14
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"bdbcd"), "ccui.Button"),         --15
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"copy"), "ccui.Button"),          --16
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"1ju"), "ccui.Button"),           --17
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"4ju"), "ccui.Button"),           --18
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"lldz"), "ccui.Button"),          --19
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"piaofen"), "ccui.Button"),       --20
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"3Aszd"), "ccui.Button"),         --21
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"3dyd"), "ccui.Button"),          --22
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"8ffd"), "ccui.Button"),          --23
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"4d2"), "ccui.Button"),           --24
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"4d3"), "ccui.Button"),           --25
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"bkd"), "ccui.Button"),           --26
        tolua.cast(ccui.Helper:seekWidgetByName(panel_pdk,"zdbsf"), "ccui.Button"),         --27
    }

    pdk_btn_list[14]:setVisible(false)
    pdk_btn_list[16]:setVisible(false)
    local tips = {
                ["15zhang"]     = "    一副无大小王扑克牌，去掉3个2、3"..
                                  "\n    个A、1个K后所用牌为45张，每人发"..
                                  "\n    15张牌",
                ["16zhang"]     = "\n    一副无大小王扑克牌，去掉3个2、1个"..
                                  "\n    A后所用牌为48张，每人发16张牌",
                ["qie4zhang"]   = "\n    一副无大小王扑克牌，随机去掉4张牌"..
                                  "\n    后所用牌为48张，每人发16张牌",
                ["daihouzi"]    = "\n    抓到红桃10的玩家输赢翻倍",
                ["bkqg"]        = "\n 上家出牌下家接牌，致使第三家要不起，\n 而后第一家全关第三家",
                ["bdbcd"]       = "勾选后，若有玩家已报单，则该玩家上家"..
                                  "\n出单牌时，必须出手中最大的单牌。"..
                                  "\n不勾选，该玩家可出手中任意大小牌，"..
                                  "\n若出的牌导致报单玩家跑牌，则该玩家"..
                                  "\n包赔余牌分和飘分，不包赔炸弹分。",
                ["lldz"]        = "\n    首局红桃3当庄，其他局数按逆时针方"..
                                  "\n    向依次当庄。",
                ["3dz"]        =  "\n    每局红桃3当庄，首出可出任意牌型。",
                ["ydz"]        =  "    首局红桃3当庄，首出必须出带红桃3的"..
                                  "\n    牌型，其他局数由上局赢家当庄，首"..
                                  "\n    出任意牌型。",
                ["zdbkc"]       = "    勾选后炸弹不可拆散打(3A除外)，但"..
                                  "\n    可出4带3/4带2牌型,不勾选，炸弹"..
                                  "\n    可拆散打",
                ["piaofen"]     = "    玩家开局前，可进行不同分数的飘分"..
                                  "\n    选择，飘分仅在输赢双方进行结算，"..
                                  "\n    报单不算飘分,飘分不参与加倍。",
                ["3dyd"]        = "若勾选，则玩家正常情况下三张只能带一"..
                                  "\n对,若不勾选,则玩家正常情况下三张只能带"..
                                  "\n2张(2张单牌/对子)以上牌型,最后一手可全"..
                                  "\n部打完时,均可三带任意两张/三带一/三张",
                ["8ffd"]        = "若勾选,则玩家剩余手牌数最多按8张进行"..
                                  "\n计算,炸弹分、飘分、抓鸟造成的翻倍照常"..
                                  "\n进行计算,全关不翻倍。若不勾选,则无封顶"..
                                  "\n限制"
        }
    self:setCreateRoomBtnTips(panel_pdk,tips)
    local pdk_wanfa = ccui.Helper:seekWidgetByName(panel_pdk,"wanfa")
    local pdk_jushu = 2
    local pdk_mode = {  3,  --1     人数
                        1,  --2     牌数 1 16张牌 2 15张牌 3 切4张牌
                        0,  --3     抓鸟(红桃10)
                        0,  --4     首张必出红桃3
                        1,  --5     坐庄类型 1 赢家当庄 2 红桃3当庄 3 轮流坐庄
                        0,  --6     不可强关
                        0,  --7     炸弹不可拆
                        1,  --8     牌数显示
                        1,  --9     报单必出大
                        0,  --10    复制分享
                        0,  --11    飘分
                        0,  --12    3A算炸弹
                        0,  --13    三带一对
                        0,  --14    8分封顶
                        2,  --15    0 不可带 1 四带二 2 四带三
                        0,  --16    炸弹不算分
                    }
    local pdk_str = ""
    local pdk_receivejushu = 1
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "pk_pdk" then
            pdk_mode[1]      = self.club_room_info.params.people_num
            pdk_mode[2]      = self.club_room_info.params.poke_type
            pdk_mode[3]      = self.club_room_info.params.has_houzi
            pdk_mode[4]      = self.club_room_info.params.chu_san
            pdk_mode[5]      = self.club_room_info.params.host_type
            pdk_mode[6]      = self.club_room_info.params.qiang_guan
            pdk_mode[7]      = self.club_room_info.params.zha_chai
            pdk_mode[8]      = self.club_room_info.params.left_show
            pdk_mode[9]      = self.club_room_info.params.bdbcd
            pdk_mode[10]     = self.club_room_info.params.copy
            pdk_mode[11]     = self.club_room_info.params.piaoniao
            pdk_mode[12]     = self.club_room_info.params.sadzd
            pdk_mode[13]     = self.club_room_info.params.sdyd
            pdk_mode[14]     = self.club_room_info.params.pzfd
            pdk_mode[15]     = self.club_room_info.params.zddp
            pdk_mode[16]     = self.club_room_info.params.zdbsf
            pdk_receivejushu = self.club_room_info.params.total_ju

            if pdk_receivejushu == 4 then
                pdk_jushu = 1
            elseif pdk_receivejushu == 8 then
                pdk_jushu = 2
            elseif pdk_receivejushu == 12 then
                pdk_jushu = 3
            elseif pdk_receivejushu == 16 then
                pdk_jushu = 4
            end

            if pdk_mode[2] ~= 1 then
                pdk_mode[12] = 0
            end
            if pdk_mode[4] ~= 1 and pdk_mode[4] ~= 0 then
                pdk_mode[4] = 0
            end
            if pdk_mode[3] ~= 1 and pdk_mode[3] ~= 0 then
                pdk_mode[3] = 0
            end
            if pdk_mode[5] ~= 2 then
                pdk_mode[4] = 0
            end
        else
            pdk_str = cc.UserDefault:getInstance():getStringForKey("qyqpdk_opt", "")
            if pdk_str and pdk_str ~= "" then
                local qyqpdk_opt = json.decode(pdk_str)
                commonlib.echo(qyqpdk_opt)
                for k,v in pairs(qyqpdk_opt.opt) do
                    pdk_mode[k] = v
                end
                pdk_mode[6]  = pdk_mode[6] or 0
                pdk_mode[7]  = pdk_mode[7] or 0
                pdk_mode[8]  = pdk_mode[8] or 0
                pdk_mode[9]  = pdk_mode[9] or 0
                pdk_mode[10] = pdk_mode[10] or 0
                pdk_mode[11] = pdk_mode[11] or 0
                pdk_mode[12] = pdk_mode[12] or 0
                pdk_mode[13] = pdk_mode[13] or 0
                pdk_mode[14] = pdk_mode[14] or 0
                pdk_mode[15] = pdk_mode[15] or 2
                pdk_mode[16] = pdk_mode[16] or 0
                if pdk_mode[2] ~= 1 then
                    pdk_mode[12] = 0
                end
                if pdk_mode[4] ~= 1 and pdk_mode[4] ~= 0 then
                    pdk_mode[4] = 0
                end
                if pdk_mode[3] ~= 1 and pdk_mode[3] ~= 0 then
                    pdk_mode[3] = 0
                end
                if pdk_mode[5] ~= 2 then
                    pdk_mode[4] = 0
                end
                if qyqpdk_opt.jushu and (qyqpdk_opt.jushu == 1 or qyqpdk_opt.jushu == 2 or qyqpdk_opt.jushu == 3 or qyqpdk_opt.jushu == 4) then
                    pdk_jushu = qyqpdk_opt.jushu
                else
                    pdk_jushu = 2
                end
            end
        end
    else
        pdk_str = cc.UserDefault:getInstance():getStringForKey("pdk_opt", "")
        if pdk_str and pdk_str ~= "" then
            local pdk_opt = json.decode(pdk_str)
            commonlib.echo(pdk_opt)
            for k,v in pairs(pdk_opt.opt) do
                pdk_mode[k] = v
            end
            pdk_mode[6] = pdk_mode[6] or 0
            pdk_mode[7] = pdk_mode[7] or 0
            pdk_mode[8] = pdk_mode[8] or 0
            pdk_mode[9] = pdk_mode[9] or 0
            pdk_mode[10] = pdk_mode[10] or 0
            pdk_mode[11] = pdk_mode[11] or 0
            pdk_mode[12] = pdk_mode[12] or 0
            pdk_mode[13] = pdk_mode[13] or 0
            pdk_mode[14] = pdk_mode[14] or 0
            pdk_mode[15] = pdk_mode[15] or 2
            pdk_mode[16] = pdk_mode[16] or 0
            if pdk_mode[2] ~= 1 then
                pdk_mode[12] = 0
            end
            if pdk_mode[4] ~= 1 and pdk_mode[4] ~= 0 then
                pdk_mode[4] = 0
            end
            if pdk_mode[3] ~= 1 and pdk_mode[3] ~= 0 then
                pdk_mode[3] = 0
            end
            if pdk_mode[5] ~= 2 then
                pdk_mode[4] = 0
            end
            if pdk_opt.jushu and (pdk_opt.jushu == 1 or pdk_opt.jushu == 2 or pdk_opt.jushu == 3 or pdk_opt.jushu == 4) then
                pdk_jushu = pdk_opt.jushu
            else
                pdk_jushu = 2
            end

        end
    end

    local function initPDKShowOpt()
        if pdk_jushu == 1 then
            self:setOpt(pdk_btn_list[17], true, true)
            self:setOpt(pdk_btn_list[18], true, false)
            self:setOpt(pdk_btn_list[1], true, false)
            self:setOpt(pdk_btn_list[2], true, false)
        elseif pdk_jushu == 2 then
            self:setOpt(pdk_btn_list[17], true, false)
            self:setOpt(pdk_btn_list[18], true, true)
            self:setOpt(pdk_btn_list[1], true, false)
            self:setOpt(pdk_btn_list[2], true, false)
        elseif pdk_jushu == 3 then
            self:setOpt(pdk_btn_list[17], true, false)
            self:setOpt(pdk_btn_list[18], true, false)
            self:setOpt(pdk_btn_list[1], true, true)
            self:setOpt(pdk_btn_list[2], true, false)
        elseif pdk_jushu == 4 then
            self:setOpt(pdk_btn_list[17], true, false)
            self:setOpt(pdk_btn_list[18], true, false)
            self:setOpt(pdk_btn_list[1], true, false)
            self:setOpt(pdk_btn_list[2], true, true)
        end


        if pdk_mode[1] == 3 then
            self:setOpt(pdk_btn_list[3], true, true, true)
            self:setOpt(pdk_btn_list[4], true, false, true)
        else
            self:setOpt(pdk_btn_list[3], true, false, true)
            self:setOpt(pdk_btn_list[4], true, true, true)
        end

        if pdk_mode[2] == 2 then
            self:setOpt(pdk_btn_list[5], true, true, true)
            self:setOpt(pdk_btn_list[6], true, false, true)
            self:setOpt(pdk_btn_list[7], true, false, true)
            pdk_wanfa:setString("15张牌:一副牌去掉双王,三个2,三个A,一个K,每家15张牌,\n谁先出完谁赢,有大必出,放走包赔")
        elseif pdk_mode[2] == 1 then
            self:setOpt(pdk_btn_list[5], true, false, true)
            self:setOpt(pdk_btn_list[6], true, true, true)
            self:setOpt(pdk_btn_list[7], true, false, true)
            pdk_wanfa:setString("16张牌:一副牌去掉双王,三个2,一个A,每家16张牌,\n谁先出完谁赢,有大必出,放走包赔")
        elseif pdk_mode[2] == 3 then
            self:setOpt(pdk_btn_list[5], true, false, true)
            self:setOpt(pdk_btn_list[6], true, false, true)
            self:setOpt(pdk_btn_list[7], true, true, true)
            pdk_wanfa:setString("切4张牌:一副牌去掉双王和任意4张牌,每家16张牌,\n谁先出完谁赢,有大必出,放走包赔")
        end

        if pdk_mode[3] == 1 then
            self:setOpt(pdk_btn_list[8], false, true)
        else
            self:setOpt(pdk_btn_list[8], false, false)
        end

        if pdk_btn_list[9] then
            if pdk_mode[4] == 1 then
                self:setOpt(pdk_btn_list[9], false, true)
            else
                self:setOpt(pdk_btn_list[9], false, false)
            end
        end

        if pdk_btn_list[10] and pdk_btn_list[11] then
            if pdk_mode[5] == 1 then
                self:setOpt(pdk_btn_list[10], false, false)
                self:setOpt(pdk_btn_list[11], false, true)
                self:setOpt(pdk_btn_list[19], false, false)
            elseif pdk_mode[5] == 2 then
                self:setOpt(pdk_btn_list[10], false, true)
                self:setOpt(pdk_btn_list[11], false, false)
                self:setOpt(pdk_btn_list[19], false, false)
            else
                self:setOpt(pdk_btn_list[10], false, false)
                self:setOpt(pdk_btn_list[11], false, false)
                self:setOpt(pdk_btn_list[19], false, true)
            end
        end

        if pdk_btn_list[12] then
            if pdk_mode[6] == 0 then
                self:setOpt(pdk_btn_list[12], false, false)
            else
                self:setOpt(pdk_btn_list[12], false, true)
            end
        end

        if pdk_btn_list[13] then
            if pdk_mode[7] == 0 then
                self:setOpt(pdk_btn_list[13], false, false)
            else
                self:setOpt(pdk_btn_list[13], false, true)
            end
        end
        if pdk_btn_list[14] then
            if pdk_mode[8] == 0 then
                self:setOpt(pdk_btn_list[14], false, false)
            else
                self:setOpt(pdk_btn_list[14], false, true)
            end
        end
        if pdk_btn_list[15] then
            if pdk_mode[9] == 0 then
                self:setOpt(pdk_btn_list[15], false, false)
            else
                self:setOpt(pdk_btn_list[15], false, true)
            end
        end

        if pdk_btn_list[16] then
            self:setOpt(pdk_btn_list[16], false, pdk_mode[10]==1)
        end

        if pdk_btn_list[20] then
           self:setOpt(pdk_btn_list[20], false, pdk_mode[11]==1)
        end

        if pdk_btn_list[21] then
           self:setOpt(pdk_btn_list[21], false, pdk_mode[12]==1)
        end

        if pdk_btn_list[22] then
           self:setOpt(pdk_btn_list[22], false, pdk_mode[13]==1)
        end

        if pdk_btn_list[23] then
           self:setOpt(pdk_btn_list[23], false, pdk_mode[14]==8)
        end

        if pdk_btn_list[24] and pdk_btn_list[25] and pdk_btn_list[26] then
            self:setOpt(pdk_btn_list[24], false, pdk_mode[15]==1)
            self:setOpt(pdk_btn_list[25], false, pdk_mode[15]==2)
            self:setOpt(pdk_btn_list[26], false, pdk_mode[15]==0)
        end

        if pdk_mode[1] == 2 then
            pdk_btn_list[1]:getChildByName("fangka"):setString("3房卡")
            pdk_btn_list[2]:getChildByName("fangka"):setString("4房卡")
            pdk_btn_list[17]:getChildByName("fangka"):setString("1房卡")
            pdk_btn_list[18]:getChildByName("fangka"):setString("2房卡")
        else
            pdk_btn_list[1]:getChildByName("fangka"):setString("3房卡")
            pdk_btn_list[2]:getChildByName("fangka"):setString("5房卡")
            pdk_btn_list[17]:getChildByName("fangka"):setString("2房卡")
            pdk_btn_list[18]:getChildByName("fangka"):setString("3房卡")
        end

        self:setOpt(pdk_btn_list[27], false, pdk_mode[16]==1)
    end

    for i, v in ipairs(pdk_btn_list) do
        v:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i==17 then
                    pdk_jushu = 1
                    initPDKShowOpt()
                elseif i==18 then
                    pdk_jushu = 2
                    initPDKShowOpt()
                elseif i==1 then
                    pdk_jushu = 3
                    initPDKShowOpt()
                elseif i==2 then
                    pdk_jushu = 4
                    initPDKShowOpt()
                elseif i==3 then
                    pdk_mode[1] = 3
                    initPDKShowOpt()
                elseif i==4 then
                    pdk_mode[1] = 2
                    initPDKShowOpt()
                elseif i==5 then
                    pdk_mode[2] = 2
                    pdk_mode[12] = 0
                    initPDKShowOpt()
                elseif i==6 then
                    pdk_mode[2] = 1
                    initPDKShowOpt()
                elseif i==7 then
                    pdk_mode[2] = 3
                    pdk_mode[12] = 0
                    initPDKShowOpt()
                elseif i==8 then
                    if pdk_mode[3] == 1 then
                        pdk_mode[3] = 0
                    else
                        pdk_mode[3] = 1
                    end
                    initPDKShowOpt()
                elseif i==9 then
                    if pdk_mode[4] ==1 then
                        pdk_mode[4] = 0
                    else
                        pdk_mode[4] = 1
                        pdk_mode[5] = 2
                    end
                    initPDKShowOpt()
                elseif i==10 then
                    pdk_mode[5] = 2
                    initPDKShowOpt()
                elseif i==11 then
                    pdk_mode[5] = 1
                    pdk_mode[4] = 0
                    initPDKShowOpt()
                elseif i==19 then
                    pdk_mode[5] = 3
                    pdk_mode[4] = 0
                    initPDKShowOpt()
                elseif i==12 then
                    if pdk_mode[6] ==1 then
                        pdk_mode[6] = 0
                    else
                        pdk_mode[6] = 1
                    end
                    initPDKShowOpt()
                elseif i==13 then
                    if pdk_mode[7] ==1 then
                        pdk_mode[7] = 0
                    else
                        pdk_mode[7] = 1
                    end
                    initPDKShowOpt()
                elseif i==14 then
                    if pdk_mode[8] ==1 then
                        pdk_mode[8] = 0
                    else
                        pdk_mode[8] = 1
                    end
                    initPDKShowOpt()
                elseif i==15 then
                    if pdk_mode[9] ==1 then
                        pdk_mode[9] = 0
                    else
                        pdk_mode[9] = 1
                    end
                    initPDKShowOpt()
                elseif i==16 then
                    if pdk_mode[10] ==1 then
                        pdk_mode[10] = 0
                    else
                        pdk_mode[10] = 1
                    end
                    initPDKShowOpt()
                elseif i==20 then
                    if pdk_mode[11] ==1 then
                        pdk_mode[11] = 0
                    else
                        pdk_mode[11] = 1
                    end
                    initPDKShowOpt()
                elseif i==21 then
                    if pdk_mode[12] ==1 then
                        pdk_mode[12] = 0
                    else
                        pdk_mode[12] = 1
                        pdk_mode[2] = 1
                    end
                    initPDKShowOpt()
                elseif i==22 then
                    if pdk_mode[13] ==1 then
                        pdk_mode[13] = 0
                    else
                        pdk_mode[13] = 1
                    end
                    initPDKShowOpt()
                elseif i==23 then
                    if pdk_mode[14] == 8 then
                        pdk_mode[14] = 0
                    else
                        pdk_mode[14] = 8
                    end
                    initPDKShowOpt()
                elseif i==24 then
                    pdk_mode[15] = 1
                    initPDKShowOpt()
                elseif i==25 then
                    pdk_mode[15] = 2
                    initPDKShowOpt()
                elseif i==26 then
                    pdk_mode[15] = 0
                    initPDKShowOpt()
                elseif i == 27 then
                    pdk_mode[16] = (pdk_mode[16] == 0 and 1 or 0)
                    initPDKShowOpt()
                end
            end
        end)
    end
    initPDKShowOpt()
    -------------------------ddz---------------------
    -------------------------ddz---------------------
    local ddz_btn_list = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"10ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"20ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"yjdz"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"llzz"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"1fd"), "ccui.Button"),     ---5
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"2fd"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"3fd"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"psxs"), "ccui.Button"),    --牌数显示8
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"3ren"), "ccui.Button"),--9
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"2ren"), "ccui.Button"),--10
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"3zha"), "ccui.Button"),  --11
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"4zha"), "ccui.Button"),  --12
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"5zha"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"buxianbei"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"jiabei"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"4ren"), "ccui.Button"),  --16
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"zhadan"), "ccui.Button"),  --17
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"copy"), "ccui.Button"),  --18
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"1ju"), "ccui.Button"),   --19
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"4ju"), "ccui.Button"),   --20
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"yiersanfen"), "ccui.Button"),   --21
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"wushifen"), "ccui.Button"),   --22
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"fdbhct"), "ccui.Button"),   --23
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"sjdz"),"ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"rang1bei"),"ccui.Button"),         --25    让牌翻一倍
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"rang4bei"),"ccui.Button"),        --26    让牌翻4倍
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"rang16bei"),"ccui.Button"),       --27    让牌翻16倍
        tolua.cast(ccui.Helper:seekWidgetByName(panel_ddz,"rang8bei"),"ccui.Button"),       --28    让牌翻8倍
    }
    local jf =ccui.Helper:seekWidgetByName(panel_ddz,"Text_7")
    local rangpai = ccui.Helper:seekWidgetByName(panel_ddz,"Text_8")

    ddz_btn_list[16]:setVisible(false)
    local shuoming= {14,15,27,22}
    for _,i in pairs(shuoming) do
        ccui.Helper:seekWidgetByName(ddz_btn_list[i],"ques"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                if not panel_ddz.tipMsgNode then

                    local tipMsgNode  = nil
                    if i == 27 then
                        tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                    else
                        tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                    end
                    sender:getParent():addChild(tipMsgNode)
                    tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                    ccui.Helper:doLayout(tipMsgNode)

                    local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")
                    if i == 14 then
                        labTip:setString("限制一局中几个炸弹封顶,打牌中炸弹超\n" ..
                            "出所选数量时,不再增加倍数,火箭也算\n"..
                            "炸弹（由春天、叫分、底分,以及加倍\n"
                            .."玩法所产生的倍数不计算在封顶之内）\n"
                            )
                    elseif i == 15 then
                        labTip:setString("勾选此选项，在叫分后，额外增加一轮，\n" ..
                            "加倍/不加倍流程"
                            )
                    elseif i == 27 then
                        labTip:setString("让牌封顶仅控制玩家抢地主时，底分翻倍倍数\n" ..
                            "1倍：可抢地主4次，每次让牌1张，每次抢都不翻倍\n" ..
                            "4倍：可抢地主4次，每次让牌1张，前2次抢底分翻\n          倍，后2次不翻倍\n" ..
                            "16倍：可抢地主4次，每次让牌1张，每次抢都翻倍\n"
                            )
                    elseif i == 22 then
                        labTip:setString("后面玩家叫分值需大于前面玩家\n" ..
                            "三家均不叫分，则重新发牌\n" ..
                            "有4个2/双王玩家，则必须叫当前可选择\n的最大分数。")
                    end

                    labTip:setPositionY(labTip:getPositionY()-2)

                    local pos = cc.p(sender:getPosition())
                    pos.y = pos.y + 20

                    tipMsgNode:setPosition(pos)

                    local arrow = tipMsgNode:getChildByName("arrow")
                    arrow:setFlippedY(false)
                    arrow:setPositionX(arrow:getPositionX()-17)
                    arrow:setPositionY(arrow:getPositionY()+5)
                    tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))
                    if i == 27 then
                    tipMsgNode:getChildByName("panMsg"):setScale(1.2)
                    labTip:setScale(0.8)
                    end
                    panel_ddz.tipMsgNode = tipMsgNode

                    tipMsgNode:stopAllActions()
                    tipMsgNode:setScale(0, 1)
                    local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                    tipMsgNode:runAction(scaleTo)
                else
                    panel_ddz.tipMsgNode:stopAllActions()
                    local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                    local callfunc = cc.CallFunc:create(function()
                        panel_ddz.tipMsgNode:removeFromParent(true)
                        panel_ddz.tipMsgNode = nil
                    end)
                    local seq = cc.Sequence:create(scaleTo, callfunc)
                    panel_ddz.tipMsgNode:runAction(seq)
                end

            end
        end)
    end
    local ddz_jushu = 2
    local ddz_mode = {3,1,1,8,3,0,1,96,0,3,0,16}  --庄 分 牌数  倍  人  加倍 炸弹 让牌数

    local ddz_str
    local ddz_receivejushu = 4
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "pk_ddz" then
            ddz_mode[1]  = self.club_room_info.params.host_type
            ddz_mode[3]  = self.club_room_info.params.left_show
            ddz_mode[4]  = self.club_room_info.params.max_zhai
            ddz_mode[5]  = self.club_room_info.params.people_num
            ddz_mode[6]  = self.club_room_info.params.can_jiabei
            ddz_mode[9]  = self.club_room_info.params.copy
            ddz_mode[10] = self.club_room_info.params.jiaofen
            ddz_mode[11] = self.club_room_info.params.isFDBHCT
            ddz_mode[12] = self.club_room_info.params.rpfd
            ddz_receivejushu = self.club_room_info.params.total_ju

            if ddz_mode[5] == 2 then
                ddz_mode[2] = 1
            else
                ddz_mode[2] = self.club_room_info.params.difen
            end

            if ddz_receivejushu == 4 then
                ddz_jushu = 1
            elseif ddz_receivejushu == 8 then
                ddz_jushu = 2
            elseif ddz_receivejushu == 12 then
                ddz_jushu = 3
            elseif ddz_receivejushu == 16 then
                ddz_jushu = 4
            end

        else
            ddz_str= cc.UserDefault:getInstance():getStringForKey("qyqddz_opt", "")
            if ddz_str and ddz_str ~= "" then
                local qyqddz_opt = json.decode(ddz_str)
                commonlib.echo(qyqddz_opt)
                if qyqddz_opt.jushu and (qyqddz_opt.jushu == 1 or qyqddz_opt.jushu == 2 or qyqddz_opt.jushu == 3 or qyqddz_opt.jushu == 4) then
                    ddz_jushu = qyqddz_opt.jushu
                else
                    ddz_jushu = 2
                end
                if not ddz_mode or #ddz_mode < 13 then
                     for k,v in pairs(qyqddz_opt.opt) do
                        ddz_mode[k] = v
                    end
                end
            end
        end
    else
        ddz_str= cc.UserDefault:getInstance():getStringForKey("ddz_opt", "")
        if ddz_str and ddz_str ~= "" then
            local ddz_opt = json.decode(ddz_str)
            commonlib.echo(ddz_opt)
            if ddz_opt.jushu and (ddz_opt.jushu == 1 or ddz_opt.jushu == 2 or ddz_opt.jushu == 3 or ddz_opt.jushu == 4) then
                ddz_jushu = ddz_opt.jushu
            else
                ddz_jushu = 2
            end
            if not ddz_mode or #ddz_mode < 13 then
                 for k,v in pairs(ddz_opt.opt) do
                    ddz_mode[k] = v
                end
            end
        end
    end

    local ddz_posX = ddz_btn_list[1]:getChildByName("fangka"):getPositionX()
    local function initDDZShowOpt()
        if ddz_jushu == 1 then
            self:setOpt(ddz_btn_list[19], true, true)
            self:setOpt(ddz_btn_list[20], true, false)
            self:setOpt(ddz_btn_list[1], true, false)
            self:setOpt(ddz_btn_list[2], true, false)
        elseif ddz_jushu == 2 then
            self:setOpt(ddz_btn_list[19], true, false)
            self:setOpt(ddz_btn_list[20], true, true)
            self:setOpt(ddz_btn_list[1], true, false)
            self:setOpt(ddz_btn_list[2], true, false)
        elseif ddz_jushu == 3 then
            self:setOpt(ddz_btn_list[19], true, false)
            self:setOpt(ddz_btn_list[20], true, false)
            self:setOpt(ddz_btn_list[1], true, true)
            self:setOpt(ddz_btn_list[2], true, false)
        elseif ddz_jushu == 4 then
            self:setOpt(ddz_btn_list[19], true, false)
            self:setOpt(ddz_btn_list[20], true, false)
            self:setOpt(ddz_btn_list[1], true, false)
            self:setOpt(ddz_btn_list[2], true, true)
        end

        if ddz_mode[1] == 1 then
            self:setOpt(ddz_btn_list[3], true, true, true)
            self:setOpt(ddz_btn_list[4], true, false, true)
            self:setOpt(ddz_btn_list[24], true, false, true)
        elseif ddz_mode[1] ==2 then
            self:setOpt(ddz_btn_list[3], true, false, true)
            self:setOpt(ddz_btn_list[4], true, true, true)
            self:setOpt(ddz_btn_list[24], true, false ,false)
        elseif ddz_mode[1] == 3 then
            self:setOpt(ddz_btn_list[3], true, false, true)
            self:setOpt(ddz_btn_list[4], true, false, true)
            self:setOpt(ddz_btn_list[24], true, true, true)
        end

        if ddz_mode[2] == 1 then
            self:setOpt(ddz_btn_list[5], true, true, true)
            self:setOpt(ddz_btn_list[6], true, false, true)
            self:setOpt(ddz_btn_list[7], true, false, true)
        elseif ddz_mode[2] == 2 then
            self:setOpt(ddz_btn_list[5], true, false, true)
            self:setOpt(ddz_btn_list[6], true, true, true)
            self:setOpt(ddz_btn_list[7], true, false, true)
        else
            self:setOpt(ddz_btn_list[5], true, false, true)
            self:setOpt(ddz_btn_list[6], true, false, true)
            self:setOpt(ddz_btn_list[7], true, true, true)
        end
        if ddz_mode[3] == 0 then
            self:setOpt(ddz_btn_list[8], false, false)
        else
            self:setOpt(ddz_btn_list[8], false, true)
        end

        if ddz_mode[4] == 8 then
            self:setOpt(ddz_btn_list[11], true, true, true)
            self:setOpt(ddz_btn_list[12], true, false, true)
            self:setOpt(ddz_btn_list[13], true, false, true)
            self:setOpt(ddz_btn_list[14], true, false, true)
        elseif ddz_mode[4] == 16 then
            self:setOpt(ddz_btn_list[11], true, false, true)
            self:setOpt(ddz_btn_list[12], true, true, true)
            self:setOpt(ddz_btn_list[13], true, false, true)
            self:setOpt(ddz_btn_list[14], true, false, true)
        elseif ddz_mode[4] == 32 then
            self:setOpt(ddz_btn_list[11], true, false, true)
            self:setOpt(ddz_btn_list[12], true, false, true)
            self:setOpt(ddz_btn_list[13], true, true, true)
            self:setOpt(ddz_btn_list[14], true, false, true)
        else
            self:setOpt(ddz_btn_list[11], true, false, true)
            self:setOpt(ddz_btn_list[12], true, false, true)
            self:setOpt(ddz_btn_list[13], true, false, true)
            self:setOpt(ddz_btn_list[14], true, true, true)
        end

        if ddz_mode[5] == 3 then
            self:setOpt(ddz_btn_list[9], true, true, true)
            self:setOpt(ddz_btn_list[10], true, false, true)
            self:setOpt(ddz_btn_list[16], true, false, true)
        elseif ddz_mode[5] == 4 then
            self:setOpt(ddz_btn_list[9], true, false, true)
            self:setOpt(ddz_btn_list[10], true, false, true)
            self:setOpt(ddz_btn_list[16], true, true, true)
        else
            self:setOpt(ddz_btn_list[9], true, false, true)
            self:setOpt(ddz_btn_list[10], true, true, true)
            self:setOpt(ddz_btn_list[16], true, false, true)
        end

        if ddz_mode[6] == 1 then
            self:setOpt(ddz_btn_list[15], false, true, true)
        else
            self:setOpt(ddz_btn_list[15], false, false, true)
        end
        if ddz_mode[7] == 2 then
            self:setOpt(ddz_btn_list[17], false, true, true)
        else
            self:setOpt(ddz_btn_list[17], false, false, true)
        end
            self:setOpt(ddz_btn_list[18], false, ddz_mode[9]==1)

        if ddz_mode[10] == 3 then
            self:setOpt(ddz_btn_list[21], false, true, true)
            self:setOpt(ddz_btn_list[22], false, false, true)
        elseif ddz_mode[10] == 10 then
            self:setOpt(ddz_btn_list[21], true, false, true)
            self:setOpt(ddz_btn_list[22], true, true, true)
        end

        if ddz_mode[11] == 0 then
             self:setOpt(ddz_btn_list[23], true, false, true)
        else
             self:setOpt(ddz_btn_list[23], true , true, true)
        end

        if ddz_mode[12] == 1 then
            self:setOpt(ddz_btn_list[25], true, true, true)
            self:setOpt(ddz_btn_list[26], true, false, true)
            self:setOpt(ddz_btn_list[27], true, false, true)
            self:setOpt(ddz_btn_list[28], true, false, true)
        elseif ddz_mode[12] == 4 then
            self:setOpt(ddz_btn_list[25], true, false, true)
            self:setOpt(ddz_btn_list[26], true, true, true)
            self:setOpt(ddz_btn_list[27], true, false, true)
            self:setOpt(ddz_btn_list[28], true, false, true)
        elseif ddz_mode[12] == 8 then
            self:setOpt(ddz_btn_list[25], true, false, true)
            self:setOpt(ddz_btn_list[26], true, false, true)
            self:setOpt(ddz_btn_list[27], true, false, true)
            self:setOpt(ddz_btn_list[28], true, true, true)
        else
            self:setOpt(ddz_btn_list[25], true, false, true)
            self:setOpt(ddz_btn_list[26], true, false, true)
            self:setOpt(ddz_btn_list[27], true, true, true)
            self:setOpt(ddz_btn_list[28], true, false, true)
        end

        if ddz_mode[5] == 2 then
            ddz_btn_list[1]:getChildByName("fangka"):setString("3房卡")
            ddz_btn_list[2]:getChildByName("fangka"):setString("4房卡")
            ddz_btn_list[19]:getChildByName("fangka"):setString("1房卡")
            ddz_btn_list[20]:getChildByName("fangka"):setString("2房卡")
        else
            ddz_btn_list[1]:getChildByName("fangka"):setString("3房卡")
            ddz_btn_list[2]:getChildByName("fangka"):setString("5房卡")
            ddz_btn_list[19]:getChildByName("fangka"):setString("2房卡")
            ddz_btn_list[20]:getChildByName("fangka"):setString("3房卡")
        end
    end

    for i, v in ipairs(ddz_btn_list) do
        v:addTouchEventListener(function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                if i==19 then
                    ddz_jushu = 1
                    initDDZShowOpt()
                elseif i==20 then
                    ddz_jushu = 2
                    initDDZShowOpt()
                elseif i==1 then
                    ddz_jushu = 3
                    initDDZShowOpt()
                elseif i==2 then
                    ddz_jushu = 4
                    initDDZShowOpt()
                elseif i==3 then
                    ddz_mode[1] = 1
                    initDDZShowOpt()
                elseif i==4 then
                    ddz_mode[1] = 2
                    initDDZShowOpt()
                elseif i==24 then
                    ddz_mode[1] = 3
                    initDDZShowOpt()
                elseif i==5 then
                    ddz_mode[2] = 1
                    initDDZShowOpt()
                elseif i==6 then
                    ddz_mode[2] = 2
                    initDDZShowOpt()
                elseif i==7 then
                    ddz_mode[2] = 3
                    initDDZShowOpt()
                elseif i==8 then
                    if ddz_mode[3] == 1 then
                        ddz_mode[3] = 0
                    else
                        ddz_mode[3] = 1
                    end
                    initDDZShowOpt()
                elseif i == 9 then
                    ddz_mode[5] = 3
                    for ii=6,10 do
                        ddz_btn_list[ii]:setVisible(true)
                    end
                    jf:setVisible(true)
                    ddz_btn_list[21]:setVisible(true)
                    ddz_btn_list[22]:setVisible(true)
                    ddz_btn_list[5]:setTouchEnabled(true)
                    ddz_btn_list[15]:setVisible(true)
                    ddz_btn_list[17]:setVisible(false)

                    rangpai:setVisible(false)
                    ddz_btn_list[25]:setVisible(false)
                    ddz_btn_list[26]:setVisible(false)
                    ddz_btn_list[27]:setVisible(false)
                    ddz_btn_list[28]:setVisible(false)
                    initDDZShowOpt()
                elseif i==10 then
                    ddz_mode[5] = 2
                    for ii=6,7 do
                        ddz_btn_list[ii]:setVisible(false)
                    end
                    jf:setVisible(false)
                    ddz_btn_list[21]:setVisible(false)
                    ddz_btn_list[22]:setVisible(false)
                    ddz_btn_list[5]:setTouchEnabled(false)
                    ddz_btn_list[15]:setVisible(false)
                    ddz_btn_list[17]:setVisible(false)

                    rangpai:setVisible(true)
                    ddz_btn_list[25]:setVisible(true)
                    ddz_btn_list[26]:setVisible(true)
                    ddz_btn_list[27]:setVisible(true)
                    ddz_btn_list[28]:setVisible(true)

                    ddz_mode[2] = 1
                    initDDZShowOpt()
                elseif i==16 then
                    ddz_mode[5] = 4
                    for ii=6,7 do
                        ddz_btn_list[ii]:setVisible(true)
                    end
                    ddz_btn_list[5]:setTouchEnabled(true)
                    ddz_btn_list[15]:setVisible(true)
                    ddz_btn_list[17]:setVisible(true)

                    initDDZShowOpt()
                elseif i==11 then
                    ddz_mode[4] = 8
                    initDDZShowOpt()
                elseif i==12 then
                    ddz_mode[4] = 16
                    initDDZShowOpt()
                elseif i==13 then
                    ddz_mode[4] = 32
                    initDDZShowOpt()
                elseif i==14 then
                    ddz_mode[4] = 0
                    initDDZShowOpt()
                elseif i==15 then
                    if ddz_mode[6] == 1 then
                        ddz_mode[6] = 0
                    else
                        ddz_mode[6] = 1
                    end
                    initDDZShowOpt()
                elseif i==17 then
                    if ddz_mode[7] == 1 then
                        ddz_mode[7] = 2
                    else
                        ddz_mode[7] = 1
                    end
                    initDDZShowOpt()
                elseif i==18 then
                    if ddz_mode[9] == 1 then
                        ddz_mode[9] = 0
                    else
                        ddz_mode[9] = 1
                    end
                    initDDZShowOpt()
                elseif i == 21 then
                    ddz_mode[10] = 3
                    initDDZShowOpt()
                elseif i == 22 then
                    ddz_mode[10] = 10
                    initDDZShowOpt()
                elseif i == 23 then
                    if ddz_mode[11] == 0 then
                        ddz_mode[11] = 1
                    else
                        ddz_mode[11] = 0
                    end
                    initDDZShowOpt()
                elseif i == 25 then
                    ddz_mode[12] = 1
                    initDDZShowOpt()
                elseif i == 26 then
                    ddz_mode[12] = 4
                    initDDZShowOpt()
                elseif i == 27 then
                    ddz_mode[12] = 16
                    initDDZShowOpt()
                elseif i == 28 then
                    ddz_mode[12] = 8
                    initDDZShowOpt()
                end
            end
        end)
    end

    if ddz_mode[5] == 2 then
        for i=6,7 do
            ddz_btn_list[i]:setVisible(false)
        end
        rangpai:setVisible(true)
        for i=25,28 do
            ddz_btn_list[i]:setVisible(true)
        end
        ddz_btn_list[5]:setTouchEnabled(false)
        ddz_btn_list[15]:setVisible(false)
        jf:setVisible(false)
        ddz_btn_list[21]:setVisible(false)
        ddz_btn_list[22]:setVisible(false)
        ddz_mode[2] = 1
    elseif ddz_mode[5] == 3 then
        for i=25,28 do
            ddz_btn_list[i]:setVisible(false)
        end
        rangpai:setVisible(false)
    end

    if ddz_mode[5] < 4 then
        ddz_btn_list[17]:setVisible(false)
    end

    initDDZShowOpt()

    local function onPayTabCallback(sender)
        btDdz:setTouchEnabled(sender ~= btDdz)
        btPdk:setTouchEnabled(sender ~= btPdk)
        btZgz:setTouchEnabled(sender ~= btZgz)
        btJdpdk:setTouchEnabled(sender ~= btJdpdk)

        btPdk:setBright(sender ~= btPdk)
        btDdz:setBright(sender ~= btDdz)
        btZgz:setBright(sender ~= btZgz)
        btJdpdk:setBright(sender ~= btJdpdk)

        btDdz:setScaleX(sender == btDdz and 1.1 or 1)
        btPdk:setScaleX(sender == btPdk and 1.1 or 1)
        btZgz:setScaleX(sender == btZgz and 1.1 or 1)
        btJdpdk:setScaleX(sender == btJdpdk and 1.1 or 1)

        panel_pdk:setVisible(btPdk == sender)
        panel_pdk:setEnabled(btPdk == sender)

        panel_ddz:setVisible(btDdz == sender)
        panel_ddz:setEnabled(btDdz == sender)

        panel_zgz:setVisible(btZgz == sender)
        panel_zgz:setEnabled(btZgz == sender)

        panel_jdpdk:setVisible(btJdpdk == sender)
        panel_jdpdk:setEnabled(btJdpdk == sender)
    end
    local function onPayTabPdkCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then

            if sender then
                AudioManager:playPressSound()
            end

            onPayTabCallback(btPdk)
        end
    end
    btPdk:addTouchEventListener(onPayTabPdkCallback)


    local function onPayTabDdzCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then

            if sender then
                AudioManager:playPressSound()
            end
            onPayTabCallback(btDdz)
        end
    end
    btDdz:addTouchEventListener(onPayTabDdzCallback)

    local function onPayTabZhsCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then

            if sender then
                AudioManager:playPressSound()
            end
            onPayTabCallback(btZgz)
        end
    end
    btZgz:addTouchEventListener(onPayTabZhsCallback)

    local function onPayTabJdpdkCallback(sender,eventType)
        if eventType == ccui.TouchEventType.ended  then

            if sender then
                AudioManager:playPressSound()
            end

            onPayTabCallback(btJdpdk)
        end
    end
    btJdpdk:addTouchEventListener(onPayTabJdpdkCallback)

    local pay_call_list = {
        ["pk_ddz"]   = onPayTabDdzCallback,
        ["pk_pdk"]   = onPayTabPdkCallback,
        ['pk_zgz']   = onPayTabZhsCallback,
        ['pk_jdpdk'] = onPayTabJdpdkCallback,
    }
    local pre_key
    if self.clubOpt == 2 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("qyqpre_game3", "pk_ddz")
    elseif self.clubOpt == 3 then
        pre_key = cc.UserDefault:getInstance():getStringForKey("waypre_game3", "pk_ddz")
    else
        pre_key = cc.UserDefault:getInstance():getStringForKey("pre_game3", "pk_ddz")
    end

    local ltmake_cards = cc.UserDefault:getInstance():getStringForKey('make_cards', "")

    if ltmake_cards and "" ~= ltmake_cards then
        ltmake_cards = json.decode(ltmake_cards)
    else
        ltmake_cards = nil
    end

    if g_author_game then
        pre_key = g_author_game
        if g_author_game == "ddz" then
            btDdz:setPosition(cc.p(btPdk:getPosition()))
            btPdk:setVisible(false)
        else
            btDdz:setVisible(false)
        end
    end
    local function payCall()
        -- log('@@@@@@@@@@@@@@@@@ ' .. tostring(pre_key))
        if not pay_call_list[pre_key] then
            onPayTabDdzCallback(nil, ccui.TouchEventType.ended)
        else
            pay_call_list[pre_key](nil, ccui.TouchEventType.ended)
        end
    end

    if has_ani then
        ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(false)
        commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "bg"), function()

            ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):setVisible(true)
            commonlib.fadeIn(ccui.Helper:seekWidgetByName(panel_room, "Panel_1"):getVirtualRenderer())

            payCall()
        end)
    else
        payCall()
    end


    local profile = ProfileManager.GetProfile()


    local function ddzcj()
        AudioManager:playPressSound()
         local di = 1
         local max = ddz_mode[4]
        if ddz_mode[5] >= 3 then
            di = ddz_mode[2]
        end
        local ddz_sendjushu = 4

        if ddz_jushu == 1 then
            ddz_sendjushu = 4
        elseif ddz_jushu == 2 then
            ddz_sendjushu = 8
        elseif ddz_jushu == 3 then
            ddz_sendjushu = 12
        elseif ddz_jushu == 4 then
            ddz_sendjushu = 16
        end

        local net_msg = {}
        if ddz_mode[5] == 4 then
            net_msg = {
                cmd =NetCmd.C2S_DDZ4_CREATE_ROOM,
                total_ju=ddz_jushu,
                host_type=ddz_mode[1],
                difen=di,
                left_show=ddz_mode[3],
                max_zhai=max,
                people_num=ddz_mode[5],
                qunzhu=self.qunzhu,
                can_jiabei=ddz_mode[6],
                zhai_mode=ddz_mode[7],
                copy=ddz_mode[9],
            }
        else
            local clientIp = gt.getClientIp()
            net_msg = {
                cmd =NetCmd.C2S_DDZ_CREATE_ROOM,
                total_ju=ddz_sendjushu,
                host_type=ddz_mode[1],
                difen=di,
                left_show=ddz_mode[3],
                max_zhai=max,
                people_num=ddz_mode[5],
                qunzhu=self.qunzhu,
                can_jiabei=ddz_mode[6],
                copy=ddz_mode[9],
                jiaofen = ddz_mode[10],
                isFDBHCT = ddz_mode[11],
                rpfd = ddz_mode[12],
                lat = clientIp[1],
                lon = clientIp[2],
            }
        end
        net_msg.clubOpt = self.clubOpt
        net_msg.room_id = self.room_id
        net_msg.club_id = self.club_id
        net_msg.isGM    = self.isGM
        ymkj.SendData:send(json.encode(net_msg))
        if self.clubOpt then
            if self.clubOpt ~= 2 then
                cc.UserDefault:getInstance():setStringForKey("qyqddz_opt", json.encode({opt=ddz_mode,jushu=ddz_jushu}))
            end
        else
            cc.UserDefault:getInstance():setStringForKey("ddz_opt", json.encode({opt=ddz_mode,jushu=ddz_jushu}))
        end
        cc.UserDefault:getInstance():flush()
    end

    ccui.Helper:seekWidgetByName(panel_ddz,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])==0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            ddzcj(0)
                        end
                    end)
                else
                    ddzcj(0)
                end
            end
            self.ddzButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)

    local function pdkcj(qz)
        AudioManager:playPressSound()
        local pdk_sendjushu = 8
        if pdk_jushu == 1 then
            pdk_sendjushu = 4
        elseif pdk_jushu == 2 then
            pdk_sendjushu = 8
        elseif pdk_jushu == 3 then
            pdk_sendjushu = 12
        elseif pdk_jushu == 4 then
            pdk_sendjushu = 16
        end

        local clientIp = gt.getClientIp()
        local net_msg = {
            cmd =NetCmd.C2S_PDK_CREATE_ROOM,
            people_num=pdk_mode[1],
            poke_type=pdk_mode[2],
            has_houzi=pdk_mode[3],
            total_ju=pdk_sendjushu,
            chu_san =pdk_mode[4],
            host_type=pdk_mode[5],
            zha_chai=pdk_mode[7],
            qiang_guan=pdk_mode[6],
            left_show = 1,
            bdbcd = pdk_mode[9],
            copy = pdk_mode[10],
            piaoniao = pdk_mode[11],
            sadzd = pdk_mode[12],
            sdyd = pdk_mode[13],
            pzfd = pdk_mode[14],
            zddp = pdk_mode[15],
            zdbsf = pdk_mode[16],
            qunzhu=self.qunzhu,
            clubOpt = self.clubOpt,
            room_id = self.room_id,
            club_id = self.club_id,
            isGM    = self.isGM,
            lat = clientIp[1],
            lon = clientIp[2],
        }
        -- dump(net_msg)
        ymkj.SendData:send(json.encode(net_msg))
        if self.clubOpt then
            if self.clubOpt ~= 2 then
                cc.UserDefault:getInstance():setStringForKey("qyqpdk_opt", json.encode({opt=pdk_mode,jushu=pdk_jushu}))
            end
        else
            cc.UserDefault:getInstance():setStringForKey("pdk_opt", json.encode({opt=pdk_mode,jushu=pdk_jushu}))
        end
        cc.UserDefault:getInstance():flush()
    end

    ccui.Helper:seekWidgetByName(panel_pdk,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])==0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            pdkcj(0)
                        end
                    end)
                else
                    pdkcj(0)
                end
            end

            self.jdpdkButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)

    ccui.Helper:seekWidgetByName(panel_zgz,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])==0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                AudioManager:playPressSound()
                self:sendCreateZhouHongSanRoom(ltmake_cards)
            end

            self.zhsButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)
end

-- 晋中拐三角
function CreateLayer:createJsGsj(panel)

    local desk_mode_str = 'jzgsj_desk_mode'
    local ren_mode_str = 'jzgsj_ren_mode'
    local qyq_opt_str = 'qyqjzgsj_opt'
    local opt_str = 'jzgsj_opt'
    local qipai_type = 'mj_jzgsj'

    local ltListBtn = {
        ['2ren'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "2ren"), "ccui.Button"),
        ['3ren'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "3ren"), "ccui.Button"),

        ['1ju'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "1ju"), "ccui.Button"),
        ['4ju'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "4ju"), "ccui.Button"),
        ['8ju'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "8ju"), "ccui.Button"),
        ['1quan']  = tolua.cast(ccui.Helper:seekWidgetByName(panel, "1quan"), "ccui.Button"),

        ['dkskh']  = tolua.cast(ccui.Helper:seekWidgetByName(panel, "dkskh"), "ccui.Button"),

        ['ghznzm'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "ghznzm"), "ccui.Button"),
        ['glznhl'] = tolua.cast(ccui.Helper:seekWidgetByName(panel, "glznhl"), "ccui.Button"),
        ['lisi']   = tolua.cast(ccui.Helper:seekWidgetByName(panel, "lisi"), "ccui.Button"),
    }

    local ltQuesContent = {
        ['dkskh'] = '勾选时，只要能凑成砍胡，就算砍胡番型。\n'..
                    '如2234455，可胡3、6，则胡3算砍胡，\n'..
                    '胡6不算。'..
                    '不勾选时，仅听一个才算砍胡，\n'..
                    '如:2234455胡3不算砍胡。1233胡3算砍\n'..
                    '胡。',

        ['glznhl']= '若玩家可胡一条龙牌型，如12345678，\n'..
                     '此时玩家可胡369，当该玩家过胡(接炮/自\n'..
                     '摸)3或者6后，该玩家只能胡(接炮/自摸)9',

        ['lisi'] =  '勾选后，手牌中包含4张立牌，\n'..
                    '不勾选，不包含立牌',
    }

    local function JzQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel.tipMsgNode and panel.tipMsgNode.lnSelectName ~= szName then
                panel.tipMsgNode:removeFromParent(true)
                panel.tipMsgNode = nil
            end

            if not panel.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'dkskh' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel.tipMsgNode = tipMsgNode
                panel.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(JzQuesBtnCallBack)
    end

    local desk_mode = 3
    local ren_mode = 3
    local player_mode = {}
    player_mode['dkskh'] = false
    player_mode['ghznzm'] = true
    player_mode['glznhl'] = true
    player_mode['lisi'] = true

    local str
    local jushu = 1

    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            ren_mode            = self.club_room_info.params.people_num
            jushu               = self.club_room_info.params.total_ju
            player_mode['dkskh'] = self.club_room_info.params.isDaiKanSuanKan

            player_mode['ghznzm'] = self.club_room_info.params.isZiMoIfPass
            player_mode['glznhl'] = self.club_room_info.params.isGuoLongHuLong
            player_mode['lisi'] = self.club_room_info.params.isLiSi
            ----------------------------------
            if ren_mode == 2 then
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 8 then
                    desk_mode = 2
                elseif jushu == 16 then
                    desk_mode = 3
                elseif jushu == 104 then
                    desk_mode = 4
                end
            else
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 4 then
                    desk_mode = 2
                elseif jushu == 8 then
                    desk_mode = 3
                elseif jushu == 101 then
                    desk_mode = 4
                end
            end
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                player_mode['dkskh'] = qyq_opt['dkskh'] or false
                player_mode['ghznzm'] = true
                if qyq_opt['ghznzm'] ~= nil then
                    player_mode['ghznzm'] = qyq_opt['ghznzm']
                end
                player_mode['glznhl'] = true
                if qyq_opt['glznhl'] ~= nil then
                    player_mode['glznhl'] = qyq_opt['glznhl']
                end
                if qyq_opt['lisi'] ~= nil then
                    player_mode['lisi'] = qyq_opt['lisi']
                end
                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3 or qyq_opt[desk_mode_str] == 4) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 3
                end
                ren_mode = qyq_opt[ren_mode_str] or 3
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)
            for k,v in pairs(opt) do
                opt[k] = v
            end

            player_mode['dkskh'] = opt['dkskh'] or false
            player_mode['ghznzm'] = true
            if opt['ghznzm'] ~= nil then
                player_mode['ghznzm'] = opt['ghznzm']
            end
            player_mode['glznhl'] = true
            if opt['glznhl'] ~= nil then
                player_mode['glznhl'] = opt['glznhl']
            end
            if opt['lisi'] ~= nil then
                player_mode['lisi'] = opt['lisi']
            end

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 or opt[desk_mode_str] == 4) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 3
            end
            ren_mode = opt[ren_mode_str] or 3
        end
    end

    local posX = ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):getPositionX()
    local function initShowOpt()
        local ltRenMode = {2,3}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if ren_mode == 2 then
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("16局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX+10)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("4圈")
        else
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("4局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("1圈")
        end

        self:setOpt(ltListBtn['1ju'],nil,desk_mode == 1)
        self:setOpt(ltListBtn['4ju'],nil,desk_mode == 2)
        self:setOpt(ltListBtn['8ju'],nil,desk_mode == 3)
        self:setOpt(ltListBtn['1quan'],nil,desk_mode == 4)

        local player_mode_true_false = {'dkskh','ghznzm','glznhl','lisi'}

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.jzgsj_ren_mode = ren_mode
        self.jzgsj_desk_mode = desk_mode
        self.jzgsj_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                ren_mode = 2
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '1ju' then
                desk_mode = 1
            elseif szName == '4ju' then
                desk_mode = 2
            elseif szName == '8ju' then
                desk_mode = 3
            elseif szName == '1quan' then
                desk_mode = 4
            elseif szName == 'dkskh' or
                szName == 'ghznzm' or
                szName == 'glznhl' or
                szName == 'lisi'
                then
                player_mode[szName] = not player_mode[szName]
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

function CreateLayer:sendCreateJsGsjRoom(ltmake_cards)
    local clientIp = gt.getClientIp()
    --  晋中拐三角
    local ju = 8
    -----------------------------------------------
    local ren_mode = self.jzgsj_ren_mode
    local desk_mode = self.jzgsj_desk_mode
    local player_mode = self.jzgsj_player_mode
    local desk_mode_str = 'jzgsj_desk_mode'
    local ren_mode_str = 'jzgsj_ren_mode'
    local qyq_opt_str = 'qyqjzgsj_opt'
    local opt_str = 'jzgsj_opt'
    -----------------------------------------------
    if ren_mode == 2 then
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 8
        elseif desk_mode == 3 then
            ju = 16
        elseif desk_mode == 4 then
            ju = 104
        end
    else
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 4
        elseif desk_mode == 3 then
            jzju_ju = 8
        elseif desk_mode == 4 then
            ju = 101
        end
    end
    local clientIp = gt.getClientIp()
    net_msg = {
        cmd =NetCmd.C2S_MJ_JZGSJ_CREATE_ROOM,
        total_ju=ju,
        people_num=ren_mode,
        qunzhu=self.qunzhu,
        copy=0,

        isDaiKanSuanKan      = player_mode['dkskh'],
        isLiSi               = player_mode['lisi'],
        ----------------------------------------------
        isZiMoIfPass      = player_mode['ghznzm'],
        isGuoLongHuLong       = player_mode['glznhl'],


        make_cards  = ltmake_cards,
        clubOpt = self.clubOpt,
        room_id = self.room_id,
        club_id = self.club_id,
        isGM    = self.isGM,
        lat = clientIp[1],
        lon = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    -- dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode
    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

function CreateLayer:createJz(panel_jzmj)
    -- 晋中
    local ltJzListBtn = {
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "2ren"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "3ren"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "4ren"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "1ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "4ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "1quan"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "ljgg"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "ghznzm"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "ssy"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "kfg"), "ccui.Button"),

        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "gsp"), "ccui.Button"),
        tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, "glznhl"), "ccui.Button")
    }

    local ltJzQuesContent = {
        ['ljgg'] = '无杠剩14张流局。一个杠剩16张流局。\n'..
                    '每多一个杠多剩2张流局。\n'..
                    '不选时，摸完牌流局。',

        ['ssy']  = '可十三幺胡牌，此牌型不需满足缺门\n'..
                   '报听规则，即满足十三幺牌型即可听\n'..
                   '牌。此牌型，可与门清进行叠加，不\n'..
                   '与坎边吊叠加。分数 = 20分。',

        ['kfg']  = '勾选后，手中3张一样的牌，别人打\n'..
                   '出一张，碰后，下轮任然可杠，不勾\n'..
                   '选，不可再杠。',

        ['glznhl'] = '若玩家可胡一条龙牌型，如12345678\n'..
                     '此时玩家可胡369，当该玩家过胡(接炮\n'..
                     '/自摸/抢杠)36后，该玩家只能胡(接炮\n'..
                     '/自摸/抢杠)9。\n',
    }

    local function JzQuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel_jzmj.tipMsgNode and panel_jzmj.tipMsgNode.lnSelectName ~= szName then
                panel_jzmj.tipMsgNode:removeFromParent(true)
                panel_jzmj.tipMsgNode = nil
            end

            if not panel_jzmj.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'fenghaozi' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltJzQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel_jzmj.tipMsgNode = tipMsgNode
                panel_jzmj.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel_jzmj.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel_jzmj.tipMsgNode:removeFromParent(true)
                    panel_jzmj.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel_jzmj.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltJzQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel_jzmj, i)
        local btQues = tolua.cast(ccui.Helper:seekWidgetByName(btSelect,"ques"), "ccui.Button")
        btQues:addTouchEventListener(JzQuesBtnCallBack)
    end

    local jz_desk_mode = 3
    local jz_ren_mode = 4
    local jz_player_mode = {}
    jz_player_mode['ljgg'] = false
    jz_player_mode['ghznzm'] = false
    jz_player_mode['ssy'] = false
    jz_player_mode['kfg'] = false
    jz_player_mode['gsp'] = false
    jz_player_mode['glznhl'] = false

    local jz_str
    local jz_jushu = 1

    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == "mj_jz" then
            jz_ren_mode            = self.club_room_info.params.people_num
            jz_jushu               = self.club_room_info.params.total_ju
            jz_player_mode['ljgg'] = self.club_room_info.params.isLiuJuGenGang
            jz_player_mode['ghznzm'] = self.club_room_info.params.isZiMoIfPass
            jz_player_mode['ssy'] = self.club_room_info.params.is13Yao
            jz_player_mode['kfg'] = self.club_room_info.params.isCanHuanGang
            jz_player_mode['gsp'] = self.club_room_info.params.isPassPeng

            jz_player_mode['glznhl'] = self.club_room_info.params.isGuoLongHuLong


            if jz_ren_mode == 2 then
                if jz_jushu == 1 then
                    jz_desk_mode = 1
                elseif jz_jushu == 8 then
                    jz_desk_mode = 2
                elseif jz_jushu == 16 then
                    jz_desk_mode = 3
                elseif jz_jushu == 104 then
                    jz_desk_mode = 4
                end
            else
                if jz_jushu == 1 then
                    jz_desk_mode = 1
                elseif jz_jushu == 4 then
                    jz_desk_mode = 2
                elseif jz_jushu == 8 then
                    jz_desk_mode = 3
                elseif jz_jushu == 101 then
                    jz_desk_mode = 4
                end
            end
        else
            jz_str = cc.UserDefault:getInstance():getStringForKey("qyqjz_opt", "")
            if jz_str and jz_str ~= "" then
                local qyqjz_opt = json.decode(jz_str)
                commonlib.echo(qyqjz_opt)
                for k,v in pairs(qyqjz_opt) do
                    qyqjz_opt[k] = v
                end

                jz_player_mode['ljgg'] = qyqjz_opt['ljgg'] or false
                jz_player_mode['ghznzm'] = qyqjz_opt['ghznzm'] or false
                jz_player_mode['ssy'] = qyqjz_opt['ssy'] or false
                jz_player_mode['kfg'] = qyqjz_opt['kfg'] or false
                jz_player_mode['gsp'] = qyqjz_opt['gsp'] or false
                jz_player_mode['glznhl'] = qyqjz_opt['glznhl'] or false

                if qyqjz_opt['jz_desk_mode'] and (qyqjz_opt['jz_desk_mode'] == 1 or qyqjz_opt['jz_desk_mode'] == 2 or qyqjz_opt['jz_desk_mode'] == 3 or qyqjz_opt['jz_desk_mode'] == 4) then
                    jz_desk_mode = qyqjz_opt['jz_desk_mode']
                else
                    jz_desk_mode = 3
                end
                jz_ren_mode = qyqjz_opt['jz_ren_mode'] or 4
            end
        end
    else
        jz_str = cc.UserDefault:getInstance():getStringForKey("jz_opt", "")
        if jz_str and jz_str ~= "" then
            local jz_opt = json.decode(jz_str)
            commonlib.echo(jz_opt)
            for k,v in pairs(jz_opt) do
                jz_opt[k] = v
            end

            jz_player_mode['ljgg'] = jz_opt['ljgg'] or false
            jz_player_mode['ghznzm'] = jz_opt['ghznzm'] or false
            jz_player_mode['ssy'] = jz_opt['ssy'] or false
            jz_player_mode['kfg'] = jz_opt['kfg'] or false
            jz_player_mode['gsp'] = jz_opt['gsp'] or false
            jz_player_mode['glznhl'] = jz_opt['glznhl'] or false


            if jz_opt['jz_desk_mode'] and (jz_opt['jz_desk_mode'] == 1 or jz_opt['jz_desk_mode'] == 2 or jz_opt['jz_desk_mode'] == 3 or jz_opt['jz_desk_mode'] == 4) then
                jz_desk_mode = jz_opt['jz_desk_mode']
            else
                jz_desk_mode = 3
            end
            jz_ren_mode = jz_opt['jz_ren_mode'] or 4
        end
    end

    local jz_posX = ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"):getChildByName("fangka"):getPositionX()
    local function initJzShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,jz_ren_mode == ltRenMode[i])
        end

        if jz_ren_mode == 2 then
            ccui.Helper:seekWidgetByName(panel_jzmj, "4ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"):setTitleText("16局")
            ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"):getChildByName("fangka"):setPositionX(jz_posX+10)
            ccui.Helper:seekWidgetByName(panel_jzmj, "1quan"):setTitleText("4圈")
        else
            ccui.Helper:seekWidgetByName(panel_jzmj, "4ju"):setTitleText("4局")
            ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel_jzmj, "8ju"):getChildByName("fangka"):setPositionX(jz_posX)
            ccui.Helper:seekWidgetByName(panel_jzmj, "1quan"):setTitleText("1圈")
        end

        local num = 4
        for i = 1,4 do
            self:setOpt(ltJzListBtn[num],nil,jz_desk_mode == i)
            num = num + 1
        end

        local jz_player_mode_true_false = {'ljgg','ghznzm','ssy','kfg','gsp','glznhl'}

        for i , v in pairs(jz_player_mode_true_false) do
            --log('@!@@@@@@@@@@@@!@!@!@!@! ' .. i)
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, v), "ccui.Button")
            self:setOpt(btnSelect,nil,jz_player_mode[v])
        end

        -- local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel_jzmj, 'difen'), "ccui.Button")
        -- btnSelect:setTitleText(tostring(gsj_player_mode['difen']))

        self.jz_ren_mode = jz_ren_mode
        self.jz_desk_mode = jz_desk_mode
        self.jz_player_mode = jz_player_mode
    end

    initJzShowOpt()

    local function btnJzSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                jz_ren_mode = 2
            elseif szName == '3ren' then
                jz_ren_mode = 3
            elseif szName == '4ren' then
                jz_ren_mode = 4
            elseif szName == '1ju' then
                jz_desk_mode = 1
            elseif szName == '4ju' then
                jz_desk_mode = 2
            elseif szName == '8ju' then
                jz_desk_mode = 3
            elseif szName == '1quan' then
                jz_desk_mode = 4
            elseif szName == 'ljgg' or
                szName == 'ghznzm' or
                szName == 'ssy' or
                szName == 'kfg' or
                szName == 'gsp' or
                szName == 'glznhl'
                then
                jz_player_mode[szName] = not jz_player_mode[szName]
            end
            initJzShowOpt()
        end
    end

    for i , v in pairs(ltJzListBtn) do
        local btnJz = ltJzListBtn[i]
        btnJz:addTouchEventListener(btnJzSelectCallBack)
    end
    ------------------------------------------------------------------------------
end

function CreateLayer:sendCreateJz(ltmake_cards)
    local clientIp = gt.getClientIp()
    local ren_mode = self.jz_ren_mode
    local desk_mode = self.jz_desk_mode
    local player_mode = self.jz_player_mode
    local desk_mode_str = 'jz_desk_mode'
    local ren_mode_str = 'jz_ren_mode'
    local qyq_opt_str = 'qyqjz_opt'
    local opt_str = 'jz_opt'
    --  晋中
    local jz_ju = 8
    if ren_mode == 2 then
        if desk_mode == 1 then
            jz_ju = 1
        elseif desk_mode == 2 then
            jz_ju = 8
        elseif desk_mode == 3 then
            jz_ju = 16
        elseif desk_mode == 4 then
            jz_ju = 104
        end
    else
        if desk_mode == 1 then
            jz_ju = 1
        elseif desk_mode == 2 then
            jz_ju = 4
        elseif desk_mode == 3 then
            jz_ju = 8
        elseif desk_mode == 4 then
            jz_ju = 101
        end
    end
    local clientIp = gt.getClientIp()
    net_msg = {
        cmd =NetCmd.C2S_MJ_JZ_CREATE_ROOM,
        total_ju=jz_ju,
        people_num=ren_mode,
        qunzhu=self.qunzhu,
        copy=0,

        isLiuJuGenGang     = player_mode['ljgg'],

        -- 过胡只能自摸
        isZiMoIfPass     = player_mode['ghznzm'],

        is13Yao     = player_mode['ssy'],
        isCanHuanGang     = player_mode['kfg'],
        isPassPeng = player_mode['gsp'],
        isGuoLongHuLong = player_mode['glznhl'],
        make_cards  = ltmake_cards,
        clubOpt = self.clubOpt,
        room_id = self.room_id,
        club_id = self.club_id,
        isGM    = self.isGM,
        lat = clientIp[1],
        lon = clientIp[2],
    }
    dump(net_msg)
    ymkj.SendData:send(json.encode(net_msg))
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode
    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

-- 河北麻将 （在2113行调用）
function CreateLayer:createHeBei(panel)
    local desk_mode_str = 'hbmj_desk_mode'
    local ren_mode_str = 'hbmj_ren_mode'
    local qyq_opt_str = 'qyqhbmj_opt'
    local opt_str = 'hbmj_opt'
    local qipai_type = 'mj_hebei'

    local ltListBtnName = {
            '2ren','3ren','4ren',
            '1ju','4ju','8ju','1quan',
            'dzx','df','kcp',
            'sjlz','mq','zwk',
            'ddc','hdly','hl',
            'ypdx','dgbg'
        }

    local ltListBtn = {}
    for i , v in ipairs(ltListBtnName) do
        local btnName = v
        ltListBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    local ltQuesContent = {
        -- ['dkskh'] = '勾选时，只要能凑成砍胡，就算砍胡番型。\n'..
        --             '如2234455，可胡3、6，则胡3算砍胡，\n'..
        --             '胡6不算。'..
        --             '不勾选时，仅听一个才算砍胡，\n'..
        --             '如:2234455胡3不算砍胡。1233胡3算砍\n'..
        --             '胡。',
    }

    local function QuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel.tipMsgNode and panel.tipMsgNode.lnSelectName ~= szName then
                panel.tipMsgNode:removeFromParent(true)
                panel.tipMsgNode = nil
            end

            if not panel.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'dkskh' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel.tipMsgNode = tipMsgNode
                panel.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(QuesBtnCallBack)
    end

    local desk_mode = 3
    local ren_mode = 4
    local player_mode = {}
    -- player_mode['dzx'] = true
    -- player_mode['df'] = true
    -- player_mode['kcp'] = false
    -- player_mode['sjlz'] = false
    -- player_mode['mq'] = true
    -- player_mode['zwk'] = true
    -- player_mode['ddc'] = true
    -- player_mode['hdly'] = true
    -- player_mode['hl'] = true
    -- player_mode['ypdx'] = false
    -- player_mode['dgbg'] = true

    local str
    local jushu = 1

    local function setModeOrDefaultTrue(opt)
        local optTable = {'dzx','df','mq','zwk','ddc','hdly','hl','dgbg'}
        for i , v in ipairs(optTable) do
            if nil ~= opt[v] then
                player_mode[v] = opt[v]
            else
                player_mode[v] = true
            end
        end
    end

    local function setModeOrDefaultFalse(opt)
        local optTable = {'kcp','sjlz','ypdx'}
        for i , v in ipairs(optTable) do
            player_mode[v] = opt[v] or false
        end
    end
    setModeOrDefaultTrue({})
    setModeOrDefaultFalse({})
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            ren_mode            = self.club_room_info.params.people_num
            jushu               = self.club_room_info.params.total_ju

            player_mode['dzx'] = self.club_room_info.params.isDaiZhuang
            player_mode['df'] = self.club_room_info.params.isDaiFeng
            player_mode['kcp'] = self.club_room_info.params.isCanChiPai

            player_mode['sjlz'] = self.club_room_info.params.isSuiJiWang
            player_mode['mq'] = self.club_room_info.params.isMenQing
            player_mode['zwk'] = self.club_room_info.params.isZhuo5Kui

            player_mode['ddc'] = self.club_room_info.params.isDaDiaoChe
            player_mode['hdly'] = self.club_room_info.params.isHaiDiLaoYue
            player_mode['hl'] = self.club_room_info.params.isHuaLong

            player_mode['ypdx'] = self.club_room_info.params.isYiPaoDuoHu
            player_mode['dgbg'] = self.club_room_info.params.isDGBG
            ----------------------------------
            if ren_mode == 2 then
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 8 then
                    desk_mode = 2
                elseif jushu == 16 then
                    desk_mode = 3
                elseif jushu == 104 then
                    desk_mode = 4
                end
            else
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 4 then
                    desk_mode = 2
                elseif jushu == 8 then
                    desk_mode = 3
                elseif jushu == 101 then
                    desk_mode = 4
                end
            end
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                local opt = qyq_opt

                setModeOrDefaultTrue(opt)

                setModeOrDefaultFalse(opt)

                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3 or qyq_opt[desk_mode_str] == 4) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 3
                end
                ren_mode = qyq_opt[ren_mode_str] or 3
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)
            for k,v in pairs(opt) do
                opt[k] = v
            end

            local opt = opt

            setModeOrDefaultTrue(opt)

            setModeOrDefaultFalse(opt)

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 or opt[desk_mode_str] == 4) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 3
            end
            ren_mode = opt[ren_mode_str] or 3
        end
    end

    local posX = ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):getPositionX()
    local function initShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if ren_mode == 2 then
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("16局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX+10)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("4圈")
        else
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("4局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("1圈")
        end

        self:setOpt(ltListBtn['1ju'],nil,desk_mode == 1)
        self:setOpt(ltListBtn['4ju'],nil,desk_mode == 2)
        self:setOpt(ltListBtn['8ju'],nil,desk_mode == 3)
        self:setOpt(ltListBtn['1quan'],nil,desk_mode == 4)

        local player_mode_true_false = {'dzx','df','kcp','sjlz','mq','zwk','ddc','hdly','hl','ypdx','dgbg'}

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.hbmj_ren_mode = ren_mode
        self.hbmj_desk_mode = desk_mode
        self.hbmj_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                ren_mode = 2
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '4ren' then
                ren_mode = 4
            elseif szName == '1ju' then
                desk_mode = 1
            elseif szName == '4ju' then
                desk_mode = 2
            elseif szName == '8ju' then
                desk_mode = 3
            elseif szName == '1quan' then
                desk_mode = 4
            elseif szName == 'dzx' or
                szName == 'df' or
                szName == 'kcp' or
                szName == 'mq' or
                szName == 'sjlz' or
                szName == 'zwk' or
                szName == 'ddc' or
                szName == 'hdly' or
                szName == 'hl' or
                szName == 'ypdx' or
                szName == 'dgbg'
                then
                player_mode[szName] = not player_mode[szName]
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

function CreateLayer:sendCreateHeBeiRoom(ltmake_cards)
    local clientIp = gt.getClientIp()
    --  河北麻将
    local ju = 8
    -----------------------------------------------
    local ren_mode = self.hbmj_ren_mode
    local desk_mode = self.hbmj_desk_mode
    local player_mode = self.hbmj_player_mode
    local desk_mode_str = 'hbmj_desk_mode'
    local ren_mode_str = 'hbmj_ren_mode'
    local qyq_opt_str = 'qyqhbmj_opt'
    local opt_str = 'hbmj_opt'
    -----------------------------------------------
    if ren_mode == 2 then
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 8
        elseif desk_mode == 3 then
            ju = 16
        elseif desk_mode == 4 then
            ju = 104
        end
    else
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 4
        elseif desk_mode == 3 then
            jzju_ju = 8
        elseif desk_mode == 4 then
            ju = 101
        end
    end
    local clientIp = gt.getClientIp()
    local net_msg = {
        cmd =NetCmd.C2S_MJ_HEBEI_CREATE_ROOM,
        total_ju=ju,
        people_num=ren_mode,
        qunzhu=self.qunzhu,
        copy=0,

        -- wait_add
        isDaiFeng       = player_mode['df' ]  ,     -- 带风玩法
        isDaiZhuang     = player_mode['dzx']  ,     -- 带庄闲
        isCanChiPai     = player_mode['kcp']  ,     -- 可吃牌
        isSuiJiWang     = player_mode['sjlz'] ,     -- 随机癞子
        isMenQing       = player_mode['mq' ]  ,     -- 门清
        isZhuo5Kui      = player_mode['zwk']  ,     -- 捉五魁
        isDaDiaoChe     = player_mode['ddc']  ,     -- 大吊车
        isHaiDiLaoYue   = player_mode['hdly'] ,     -- 海底捞月
        isHuaLong       = player_mode['hl']   ,     -- 花龙
        isYiPaoDuoHu    = player_mode['ypdx'] ,     -- 可一炮多响
        isDGBG          = player_mode['dgbg'] ,     -- 点杠包杠

        make_cards  = ltmake_cards,
        clubOpt = self.clubOpt,
        room_id = self.room_id,
        club_id = self.club_id,
        isGM    = self.isGM,
        lat = clientIp[1],
        lon = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    -- dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode
    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

-- 河北推倒胡麻将（在2115行调用）
function CreateLayer:createHeBeiTdh(panel)
    local desk_mode_str = 'hbtdh_desk_mode'
    local ren_mode_str = 'hbtdh_ren_mode'
    local qyq_opt_str = 'qyqhbtdh_opt'
    local opt_str = 'hbtdh_opt'
    local qipai_type = 'mj_hbtdh'

    local ltListBtnName = {
            '2ren','3ren','4ren',
            '1ju','4ju','8ju','1quan',
            'dh','ph','btdgbb',
            'bt','df','kcp',
            'hzlz','zkzmh','qym',
            'ypdx','bbtbhbg',
        }

    local ltListBtn = {}
    for i , v in ipairs(ltListBtnName) do
        local btnName = v
        ltListBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    ltListBtn['4ju']:setPositionX(ltListBtn['3ren']:getPositionX())
    ltListBtn['8ju']:setPositionX(ltListBtn['4ren']:getPositionX())
    ltListBtn['1quan']:setVisible(false)
    ltListBtn['1quan']:setTouchEnabled(false)

    local ltQuesContent = {
        ['btdgbb']  = '若勾选，则玩家报听后点杠不包此杠分，\n'..
                      '未勾选，则玩家报听后点杠，需包杠分。\n',
        ['bbtbhbg'] = '若勾选，报听前：点炮包胡牌分，点杠包\n'..
                      '杠分。报听后：点炮三家出，点杠包杠分\n'..
                      '（此处若同时勾选报听点杠不包，则点杠\n'..
                      '三家出）。不勾选，所有分数三家出。',
    }

    local function QuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel.tipMsgNode and panel.tipMsgNode.lnSelectName ~= szName then
                panel.tipMsgNode:removeFromParent(true)
                panel.tipMsgNode = nil
            end

            if not panel.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'dkskh' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel.tipMsgNode = tipMsgNode
                panel.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(QuesBtnCallBack)
    end

    local desk_mode = 2
    local ren_mode = 4
    local player_mode = {}

    local str
    local jushu = 1

    local function setModeOrDefaultTrue(opt)
        local optTable = {'dh','df','ypdx','bbtbhbg', 'qym','hzlz'}
        for i , v in ipairs(optTable) do
            if nil ~= opt[v] then
                player_mode[v] = opt[v]
            else
                player_mode[v] = true
            end
        end
    end
    local function setModeOrDefaultFalse(opt)
        local optTable = {'bt','kcp','zkzmh','btdgbb'}
        for i , v in ipairs(optTable) do
            player_mode[v] = opt[v] or false
        end
    end
    setModeOrDefaultTrue({})
    setModeOrDefaultFalse({})
    player_mode['ph'] = not player_mode['dh']
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            ren_mode            = self.club_room_info.params.people_num
            jushu               = self.club_room_info.params.total_ju

            player_mode['dh'] = self.club_room_info.params.isDaHu
            player_mode['ph'] = self.club_room_info.params.isPingHu
            player_mode['btdgbb'] = self.club_room_info.params.isBTDGBB
            player_mode['df'] = self.club_room_info.params.isDaiFeng
            player_mode['bt'] = self.club_room_info.params.isBaoTing
            player_mode['kcp'] = self.club_room_info.params.isChiPai
            player_mode['hzlz'] = self.club_room_info.params.isHZLZ
            player_mode['zkzmh'] = self.club_room_info.params.isZhiKeZiMo
            player_mode['qym'] = self.club_room_info.params.isQueYiMen
            player_mode['ypdx'] = self.club_room_info.params.isYPDX
            player_mode['bbtbhbg'] = self.club_room_info.params.isBBTBHBG

          -- isBaoTing   = data.isBaoTing
          --   isDaiFeng   = data.isDaiFeng
          --   isZhiKeZiMo = data.isZhiKeZiMo
          --   isGBTKBNG   = false -- @noused
          --   isSJHZ      = false -- @noused
          --   isHZLZ      = data.isHZLZ
          --   isDaHu      = data.isDaHu
          --   isPingHu    = data.isPingHu
          --   isQueYiMen  = data.isQueYiMen
          --   isHPBXQM    = data.isHPBXQM or false
          --   isChiPai    = data.isChiPai
          --   isYPDX      = data.isYPDX
          --   isBBTBHBG   = data.isBBTBHBG
            ----------------------------------
            if ren_mode == 2 then
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 8 then
                    desk_mode = 2
                elseif jushu == 16 then
                    desk_mode = 3
                elseif jushu == 104 then
                    desk_mode = 4
                end
            else
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 4 then
                    desk_mode = 2
                elseif jushu == 8 then
                    desk_mode = 3
                elseif jushu == 101 then
                    desk_mode = 4
                end
            end
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                local opt = qyq_opt

                setModeOrDefaultTrue(opt)

                setModeOrDefaultFalse(opt)

                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3 or qyq_opt[desk_mode_str] == 4) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 3
                end
                ren_mode = qyq_opt[ren_mode_str] or 3
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)

            for k,v in pairs(opt) do
                opt[k] = v
            end

            local opt = opt

            setModeOrDefaultTrue(opt)

            setModeOrDefaultFalse(opt)

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 or opt[desk_mode_str] == 4) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 3
            end
            ren_mode = opt[ren_mode_str] or 3
        end
    end

    local posX = ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):getPositionX()
    local dahuWanfaStr = "玩法：推倒胡，胡牌类型有平胡、七小对、豪华七小对、清一\n色、一条龙、十三幺，还有特殊的红中癞子玩法。"
    local pinghuWanfaStr = "玩法：胡牌类型只有平胡。"

    local function initShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if ren_mode == 2 then
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("16局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX+10)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("4圈")
            ltListBtn['ypdx']:setVisible(false)
            ltListBtn['bbtbhbg']:setVisible(false)
            ltListBtn['btdgbb']:setVisible(false)
            ltListBtn['qym']:setVisible(true)
            ccui.Helper:seekWidgetByName(panel, "suanfen"):setVisible(false)
        else
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("4局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("1圈")
            ltListBtn['ypdx']:setVisible(true)
            ltListBtn['bbtbhbg']:setVisible(true)
            if player_mode['bbtbhbg'] then
                ltListBtn['btdgbb']:setVisible(true)
            else
                ltListBtn['btdgbb']:setVisible(false)
            end
            ltListBtn['qym']:setVisible(false)
            ccui.Helper:seekWidgetByName(panel, "suanfen"):setVisible(true)
        end

        self:setOpt(ltListBtn['1ju'],nil,desk_mode == 1)
        self:setOpt(ltListBtn['4ju'],nil,desk_mode == 2)
        self:setOpt(ltListBtn['8ju'],nil,desk_mode == 3)
        self:setOpt(ltListBtn['1quan'],nil,desk_mode == 4)
        if player_mode['dh'] then
            ccui.Helper:seekWidgetByName(panel, "wanfa"):setString(dahuWanfaStr)
        else
            ccui.Helper:seekWidgetByName(panel, "wanfa"):setString(pinghuWanfaStr)
        end
        local player_mode_true_false = {'dh','ph','btdgbb','df','bt','kcp','hzlz','zkzmh','qym','ypdx','bbtbhbg'}

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.hbtdh_ren_mode = ren_mode
        self.hbtdh_desk_mode = desk_mode
        self.hbtdh_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                ren_mode = 2
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '4ren' then
                ren_mode = 4
            elseif szName == '1ju' then
                desk_mode = 1
            elseif szName == '4ju' then
                desk_mode = 2
            elseif szName == '8ju' then
                desk_mode = 3
            elseif szName == '1quan' then
                desk_mode = 4
            elseif szName == 'dh' then
                player_mode['dh'] = true
                player_mode['ph'] = not player_mode['dh']
            elseif szName == 'ph' then
                player_mode['ph'] = true
                player_mode['dh'] = not player_mode['ph']
            elseif szName == 'df' or
                szName == 'bt' or
                szName == 'btdgbb' or
                szName == 'kcp' or
                szName == 'hzlz' or
                szName == 'zkzmh' or
                szName == 'qym' or
                szName == 'ypdx' or
                szName == 'bbtbhbg'
                then
                player_mode[szName] = not player_mode[szName]
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

function CreateLayer:sendCreateHeBeiTdhRoom(ltmake_cards)
    local clientIp = gt.getClientIp()
    --  河北推倒胡麻将
    local ju = 8
    -----------------------------------------------
    local ren_mode = self.hbtdh_ren_mode
    local desk_mode = self.hbtdh_desk_mode
    local player_mode = self.hbtdh_player_mode
    local desk_mode_str = 'hbtdh_desk_mode'
    local ren_mode_str = 'hbtdh_ren_mode'
    local qyq_opt_str = 'qyqhbtdh_opt'
    local opt_str = 'hbtdh_opt'
    -----------------------------------------------
    if ren_mode == 2 then
        player_mode['ypdx']    = false
        player_mode['bbtbhbg'] = false
        player_mode['btdgbb']  = false
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 8
        elseif desk_mode == 3 then
            ju = 16
        elseif desk_mode == 4 then
            ju = 104
        end
    else
        player_mode['qym'] = false
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 4
        elseif desk_mode == 3 then
            jzju_ju = 8
        elseif desk_mode == 4 then
            ju = 101
        end
    end
    if not player_mode['bbtbhbg'] then
        player_mode['btdgbb'] = false
    end
    local clientIp = gt.getClientIp()
    local net_msg = {
        cmd =NetCmd.C2S_MJ_HBTDH_CREATE_ROOM,
        total_ju=ju,
        people_num=ren_mode,
        qunzhu=self.qunzhu,
        copy=0,

        -- wait_add
          -- isBaoTing   = data.isBaoTing
          --   isDaiFeng   = data.isDaiFeng
          --   isZhiKeZiMo = data.isZhiKeZiMo
          --   isGBTKBNG   = false -- @noused
          --   isSJHZ      = false -- @noused
          --   isHZLZ      = data.isHZLZ
          --   isDaHu      = data.isDaHu
          --   isPingHu    = data.isPingHu
          --   isQueYiMen  = data.isQueYiMen
          --   isHPBXQM    = data.isHPBXQM or false
          --   isChiPai    = data.isChiPai
          --   isYPDX      = data.isYPDX
          --   isBBTBHBG   = data.isBBTBHBG
            ----------------------------------
        isDaHu      = player_mode['dh'],
        isPingHu    = player_mode['ph'],
        isBTDGBB    = player_mode['btdgbb'],
        isDaiFeng   = player_mode['df'],
        isBaoTing   = player_mode['bt'],
        isChiPai    = player_mode['kcp'],
        isHZLZ      = player_mode['hzlz'],
        isZhiKeZiMo = player_mode['zkzmh'],
        isQueYiMen  = player_mode['qym'],
        isYPDX      = player_mode['ypdx'],
        isBBTBHBG   = player_mode['bbtbhbg'],

        make_cards  = ltmake_cards,
        clubOpt = self.clubOpt,
        room_id = self.room_id,
        club_id = self.club_id,
        isGM    = self.isGM,
        lat = clientIp[1],
        lon = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    -- dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode

    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

-- 问号按钮提示信息
function CreateLayer:setCreateRoomBtnTips(panel,tszTipsContent)
    for i , v in pairs(tszTipsContent) do
        local mj_i = i
        local btn = tolua.cast(ccui.Helper:seekWidgetByName(panel,mj_i), "ccui.Button")
        ccui.Helper:seekWidgetByName(btn,"ques"):addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()

                if panel.tipMsgNode and panel.tipMsgNode.mj_i ~= mj_i then
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end

                if not panel.tipMsgNode then
                    local tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                    sender:getParent():addChild(tipMsgNode)
                    tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                    ccui.Helper:doLayout(tipMsgNode)

                    local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")
                    labTip:setString(tszTipsContent[i] or '还没有说明信息。。。')

                    local pos = cc.p(sender:getPosition())
                    local arrow = tipMsgNode:getChildByName("arrow")
                    arrow:setPositionY(arrow:getPositionY()+4)
                    pos.y = pos.y+16

                    tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))
                    if mj_i == 'lldz' or mj_i == 'qie4zhang' or mj_i == '8ffd' then
                        pos.x = pos.x - 30
                    end
                    if mj_i == 'bdbcd' then
                        tipMsgNode:getChildByName("panMsg"):setContentSize(cc.size(375,150))
                        labTip:setPositionY(labTip:getPositionY()+30)
                    end
                    tipMsgNode:setPosition(pos)

                    panel.tipMsgNode = tipMsgNode
                    panel.tipMsgNode.mj_i = mj_i

                    tipMsgNode:stopAllActions()
                    tipMsgNode:setScale(0, 1)
                    local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                    tipMsgNode:runAction(scaleTo)

                else
                    panel.tipMsgNode:stopAllActions()
                    local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                    local callfunc = cc.CallFunc:create(function()
                        panel.tipMsgNode:removeFromParent(true)
                        panel.tipMsgNode = nil
                    end)
                    local seq = cc.Sequence:create(scaleTo, callfunc)
                    panel.tipMsgNode:runAction(seq)
                end

            end
        end)
    end
end

-- 保定打八张麻将（在2117行调用）
function CreateLayer:createBaoDingDbz(panel)
    local desk_mode_str = 'bddbz_desk_mode'
    local ren_mode_str = 'bddbz_ren_mode'
    local qyq_opt_str = 'qyqbddbz_opt'
    local opt_str = 'bddbz_opt'
    local qipai_type = 'mj_dbz'

    local ltListBtnName = {
            '2ren','3ren','4ren',
            '1ju','4ju','8ju','1quan','2quan',
            'dpxb','dpdb','dpsjc',
            'dzx','df',
            'cp','ypdx','gz',
            'kp','dj','kpkj',
            'ybz','gsp','gshz','14zlj',
            '5f','1f',
            'bufeng','16fen','32fen','64fen',
        }

    local ltListBtn = {}
    for i , v in ipairs(ltListBtnName) do
        local btnName = v
        ltListBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    -- ltListBtn['4ju']:setPositionX(ltListBtn['3ren']:getPositionX())
    -- ltListBtn['8ju']:setPositionX(ltListBtn['4ren']:getPositionX())
    -- ltListBtn['1quan']:setVisible(false)
    -- ltListBtn['1quan']:setTouchEnabled(false)

    local ltQuesContent = {
        ['kpkj'] = '勾选时，扣牌自己可见，但不可打出。\n'..
                    '未勾选，扣牌不可见，也不可打出，',
        ['dpxb'] = '点炮玩家出1倍胡牌分，其他玩家不出分',
        ['dpdb'] = '点炮玩家出两倍胡牌分和另外两个玩家\n的1倍胡牌分',
        ['dpsjc']= '点炮玩家出两倍胡牌分，其他玩家出\n1倍胡牌分',
        ['ybz']  = '勾选后，胡牌必须有同花色的牌(万筒条\n风)其中一种张数大于或等于8张，包括点\n炮、自摸的第14张牌，不勾选此选项，\n胡牌时无此限制',
        ['14zlj']= '勾选后，牌墩剩余14张牌流局，不勾\n选，牌墩无牌后流局'
    }

    local function QuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel.tipMsgNode and panel.tipMsgNode.lnSelectName ~= szName then
                panel.tipMsgNode:removeFromParent(true)
                panel.tipMsgNode = nil
            end

            if not panel.tipMsgNode then
                local tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel.tipMsgNode = tipMsgNode
                panel.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(QuesBtnCallBack)

    end
    -- self:setCreateRoomBtnTips(self.panel_roomMJHeiBei, ltQuesContent) -- 可直接使用封装好的函数，省略上面QuesBtnCallBack函数和一个for循环

    local desk_mode = 2
    local ren_mode = 4
    local player_mode = {}

    local str
    local jushu = 1
    local function setModeOrDefaultTrue(opt)
        local optTable = { 'dzx','df','gz','5f','bufeng','ybz','dpdb'}
        for i , v in ipairs(optTable) do
            if nil ~= opt[v] then
                player_mode[v] = opt[v]
            else
                player_mode[v] = true
            end
        end
    end

    local function setModeOrDefaultFalse(opt)
        local optTable = {
            'cp','ypdx',
            'kp','dj','kpkj','1f',
            '16fen','32fen','64fen',
            'dpxb','dpsjc','gsp','gshz','14zlj'}
        for i , v in ipairs(optTable) do
           player_mode[v] = opt[v] or false
        end
    end
    setModeOrDefaultTrue({})
    setModeOrDefaultFalse({})

    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            local difen = 1
            local fengding = 0
            ren_mode            = self.club_room_info.params.people_num
            jushu               = self.club_room_info.params.total_ju
            difen               = self.club_room_info.params.iDiFeng
            fengding            = self.club_room_info.params.iFengDing
            player_mode['dzx']  = self.club_room_info.params.isDaiZhuangXian
            player_mode['df']   = self.club_room_info.params.isDaiFeng
            player_mode['cp']   = self.club_room_info.params.isChiPai
            player_mode['ypdx'] = self.club_room_info.params.isYPDX
            player_mode['gz']   = self.club_room_info.params.isGenZhuang
            player_mode['kp']   = self.club_room_info.params.isKouPai
            player_mode['dj']   = self.club_room_info.params.isDaJiang
            player_mode['kpkj'] = self.club_room_info.params.isKouPaiKeJian
            player_mode['dpxb'] = self.club_room_info.params.isDPXB
            player_mode['dpdb'] = self.club_room_info.params.isDPDB
            player_mode['dpsjc']= self.club_room_info.params.isDPSJC
            player_mode['ybz']  = self.club_room_info.params.isYingBaZhang
            player_mode['gsp']  = self.club_room_info.params.isGuoShouPeng
            player_mode['gshz'] = self.club_room_info.params.isGSHZ
            player_mode['14zlj']= self.club_room_info.params.isSSZLJ

            ----------------------------------
            if difen == 1 then
                if player_mode['16fen'] then
                    fengding = 16
                elseif player_mode['32fen'] then
                    fengding = 32
                elseif player_mode['64fen'] then
                    fengding = 64
                else
                    fengding = 0
                end
            else
                if player_mode['16fen'] then
                    fengding = 80
                elseif player_mode['32fen'] then
                    fengding = 160
                elseif player_mode['64fen'] then
                    fengding = 320
                else
                    fengding = 0
                end
            end

            if fengding == 16 or fengding == 80 then
                player_mode['16fen']  = true
                player_mode['32fen']  = false
                player_mode['64fen']  = false
                player_mode['bufeng'] = false
            elseif fengding == 32 or fengding == 160 then
                player_mode['16fen']  = false
                player_mode['32fen']  = true
                player_mode['64fen']  = false
                player_mode['bufeng'] = false
            elseif fengding == 64 or fengding == 320 then
                player_mode['16fen']  = false
                player_mode['32fen']  = false
                player_mode['64fen']  = true
                player_mode['bufeng'] = false
            else
                player_mode['16fen']  = false
                player_mode['32fen']  = false
                player_mode['64fen']  = false
                player_mode['bufeng'] = true
            end

            if difen == 1 then
                player_mode['1f'] = true
                player_mode['5f'] = false
            else
                player_mode['1f'] = false
                player_mode['5f'] = true
            end
            if ren_mode == 2 then
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 8 then
                    desk_mode = 2
                elseif jushu == 16 then
                    desk_mode = 3
                elseif jushu == 104 then
                    desk_mode = 4
                elseif jushu == 108 then
                    desk_mode = 5
                end
            else
                if jushu == 1 then
                    desk_mode = 1
                elseif jushu == 4 then
                    desk_mode = 2
                elseif jushu == 8 then
                    desk_mode = 3
                elseif jushu == 101 then
                    desk_mode = 4
                elseif jushu == 102 then
                    desk_mode = 5
                end
            end
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                local opt = qyq_opt

                setModeOrDefaultTrue(opt)

                setModeOrDefaultFalse(opt)

                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3 or qyq_opt[desk_mode_str] == 4 or qyq_opt[desk_mode_str] == 5) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 3
                end
                ren_mode = qyq_opt[ren_mode_str] or 3
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)

            for k,v in pairs(opt) do
                opt[k] = v
            end

            local opt = opt

            setModeOrDefaultTrue(opt)

            setModeOrDefaultFalse(opt)

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 or opt[desk_mode_str] == 4 or opt[desk_mode_str] == 5) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 3
            end
            ren_mode = opt[ren_mode_str] or 3
        end
    end

     local posX = ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):getPositionX()

    local function initShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if not (player_mode['df'] and player_mode['kp']) then
            player_mode['dj'] = false
        end
        if player_mode['1f'] then
            ccui.Helper:seekWidgetByName(panel, "16fen"):setTitleText("16分")
            ccui.Helper:seekWidgetByName(panel, "32fen"):setTitleText("32分")
            ccui.Helper:seekWidgetByName(panel, "64fen"):setTitleText("64分")
        else
            ccui.Helper:seekWidgetByName(panel, "16fen"):setTitleText("80分")
            ccui.Helper:seekWidgetByName(panel, "32fen"):setTitleText("  160分")
            ccui.Helper:seekWidgetByName(panel, "64fen"):setTitleText("  320分")
        end
        if player_mode['kp'] then
            ccui.Helper:seekWidgetByName(panel,"kpkj"):setVisible(true)
        else
            ccui.Helper:seekWidgetByName(panel,"kpkj"):setVisible(false)
            player_mode['kpkj'] = false
        end

        if ren_mode == 2 then
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("16局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX+10)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("4圈")
            ccui.Helper:seekWidgetByName(panel, "2quan"):setTitleText("8圈")
        else
            ccui.Helper:seekWidgetByName(panel, "4ju"):setTitleText("4局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):setTitleText("8局")
            ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):setPositionX(posX)
            ccui.Helper:seekWidgetByName(panel, "1quan"):setTitleText("1圈")
            ccui.Helper:seekWidgetByName(panel, "2quan"):setTitleText("2圈")
        end

        self:setOpt(ltListBtn['1ju'],nil,desk_mode == 1)
        self:setOpt(ltListBtn['4ju'],nil,desk_mode == 2)
        self:setOpt(ltListBtn['8ju'],nil,desk_mode == 3)
        self:setOpt(ltListBtn['1quan'],nil,desk_mode == 4)
        self:setOpt(ltListBtn['2quan'],nil,desk_mode == 5)

        local player_mode_true_false = {'dpxb','dpdb','dpsjc','dzx','df','cp','ypdx','gz','kp','dj','kpkj','ybz','gsp','gshz','14zlj','5f','1f','bufeng','16fen','32fen','64fen',}

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.bddbz_ren_mode = ren_mode
        self.bddbz_desk_mode = desk_mode
        self.bddbz_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                ren_mode = 2
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '4ren' then
                ren_mode = 4
            elseif szName == '1ju' then
                desk_mode = 1
            elseif szName == '4ju' then
                desk_mode = 2
            elseif szName == '8ju' then
                desk_mode = 3
            elseif szName == '1quan' then
                desk_mode = 4
            elseif szName == '2quan' then
                desk_mode = 5
            elseif szName == 'dpxb' then
                player_mode['dpxb'] = true
                player_mode['dpdb'] = not player_mode['dpxb']
                player_mode['dpsjc'] = not player_mode['dpxb']
            elseif szName == 'dpdb' then
                player_mode['dpdb'] = true
                player_mode['dpxb'] = not player_mode['dpdb']
                player_mode['dpsjc'] = not player_mode['dpdb']
            elseif szName == 'dpsjc' then
                player_mode['dpsjc'] = true
                player_mode['dpxb'] = not player_mode['dpsjc']
                player_mode['dpdb'] = not player_mode['dpsjc']
            elseif szName == 'cp' then
                player_mode['cp'] = not player_mode['cp']
                if player_mode['kp'] and player_mode['cp'] then
                    player_mode['kp'] = false
                end
            elseif szName == 'kp' then
                player_mode['kp'] = not player_mode['kp']
                --player_mode['cp'] = not player_mode['kp']
                if player_mode['kp'] and player_mode['cp'] then
                    player_mode['cp'] = false
                end
            elseif szName == '5f' then
                player_mode['5f'] = true
                player_mode['1f'] = not player_mode['5f']
            elseif szName == '1f' then
                player_mode['1f'] = true
                player_mode['5f'] = not player_mode['1f']
            elseif szName == 'bufeng' then
                player_mode['bufeng'] = true
                player_mode['16fen'] = not player_mode['bufeng']
                player_mode['32fen'] = not player_mode['bufeng']
                player_mode['64fen'] = not player_mode['bufeng']
            elseif szName == '16fen' then
                player_mode['16fen'] = true
                player_mode['bufeng'] = not player_mode['16fen']
                player_mode['32fen'] = not player_mode['16fen']
                player_mode['64fen'] = not player_mode['16fen']
            elseif szName == '32fen' then
                player_mode['32fen'] = true
                player_mode['16fen'] = not player_mode['32fen']
                player_mode['bufeng'] = not player_mode['32fen']
                player_mode['64fen'] = not player_mode['32fen']
            elseif szName == '64fen' then
                player_mode['64fen'] = true
                player_mode['16fen'] = not player_mode['64fen']
                player_mode['32fen'] = not player_mode['64fen']
                player_mode['bufeng'] = not player_mode['64fen']
            elseif
                szName == 'df' or
                szName == 'ypdx' or
                szName == 'kpkj' or
                szName == 'ybz' or
                szName == 'gsp' or
                szName == 'gshz' or
                szName == '14zlj'
                then
                player_mode[szName] = not player_mode[szName]
            elseif szName == 'dzx' then
                player_mode['dzx'] = not player_mode['dzx']
                if not player_mode['dzx'] then
                    player_mode['gz'] = false
                end
            elseif szName == 'gz' then
                player_mode['gz'] = not player_mode['gz']
                if player_mode['gz'] then
                    player_mode['dzx'] = true
                end
            elseif szName == 'dj' then
                player_mode['dj'] = not player_mode['dj']
                if player_mode['dj'] then
                    player_mode['kp'] = true
                    player_mode['df'] = true
                    player_mode['cp'] = false
                end
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

-- 向服务器发送消息
function CreateLayer:sendCreateBaoDingDbzRoom(ltmake_cards)
    --  保定打八张麻将
    local ju = 8
    -----------------------------------------------
    local clientIp = gt.getClientIp()
    local ren_mode = self.bddbz_ren_mode
    local desk_mode = self.bddbz_desk_mode
    local player_mode = self.bddbz_player_mode
    local desk_mode_str = 'bddbz_desk_mode'
    local ren_mode_str = 'bddbz_ren_mode'
    local qyq_opt_str = 'qyqbddbz_opt'
    local opt_str = 'bddbz_opt'
    local difen = 1
    local fengding = 0
    -----------------------------------------------
    if ren_mode == 2 then
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 8
        elseif desk_mode == 3 then
            ju = 16
        elseif desk_mode == 4 then
            ju = 104
        elseif desk_mode == 5 then
            ju = 108
        end
    else
        if desk_mode == 1 then
            ju = 1
        elseif desk_mode == 2 then
            ju = 4
        elseif desk_mode == 3 then
            jzju_ju = 8
        elseif desk_mode == 4 then
            ju = 101
        elseif desk_mode == 5 then
            ju = 102
        end
    end

    if player_mode['1f'] then
        difen = 1
    else
        difen = 5
    end
    if difen == 1 then
        if player_mode['16fen'] then
            fengding = 16
        elseif player_mode['32fen'] then
            fengding = 32
        elseif player_mode['64fen'] then
            fengding = 64
        else
            fengding = 0
        end
    else
        if player_mode['16fen'] then
            fengding = 80
        elseif player_mode['32fen'] then
            fengding = 160
        elseif player_mode['64fen'] then
            fengding = 320
        else
            fengding = 0
        end
    end

    local net_msg = {
        cmd =NetCmd.C2S_MJ_BDDBZ_CREATE_ROOM,
        total_ju=ju,
        people_num=ren_mode,
        qunzhu=self.qunzhu,
        copy=0,

        ----------------------------------
        isDaiZhuangXian   = player_mode['dzx'],
        isDaiFeng         = player_mode['df'],
        isChiPai          = player_mode['cp'],
        isYPDX            = player_mode['ypdx'],
        isGenZhuang       = player_mode['gz'],
        isKouPai          = player_mode['kp'],
        isDaJiang         = player_mode['dj'],
        isKouPaiKeJian    = player_mode['kpkj'],
        isDPXB            = player_mode['dpxb'],
        isDPDB            = player_mode['dpdb'],
        isDPSJC           = player_mode['dpsjc'],
        isYingBaZhang     = player_mode['ybz'],
        isGuoShouPeng     = player_mode['gsp'],
        isGSHZ            = player_mode['gshz'],
        isSSZLJ           = player_mode['14zlj'],
        iDiFeng           = difen,
        iFengDing         = fengding,

        make_cards  = ltmake_cards,
        clubOpt = self.clubOpt,
        room_id = self.room_id,
        club_id = self.club_id,
        isGM    = self.isGM,
        lat     = clientIp[1],
        lon     = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    --dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode

    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

-- 丰宁麻将
function CreateLayer:createFengNing(panel)
    local desk_mode_str = 'fnmj_desk_mode'
    local ren_mode_str  = 'fnmj_ren_mode'
    local difen_mode_str  = 'fnmj_difen_mode'
    local paofen_mode_str = 'fnmj_paofen_mode'
    local qyq_opt_str   = 'qyqfnmj_opt'
    local opt_str       = 'fnmj_opt'
    local qipai_type    = 'mj_fn'

    local ltListBtnName = {
            '2ren', '3ren', '4ren',
            '4ju', '8ju', '16ju',
            '1fen', '2fen', '5fen', '10fen',
            'bupaofen', 'pao1', 'pao2', 'pao3',
            'dzx', 'qsh', 'bgyjp',
            'dfp', 'mpqt', 'cpht',
            'gshz', 'ghgl', 'zkzm',
        }

    local ltListBtn = {}
    for i , v in ipairs(ltListBtnName) do
        local btnName = v
        ltListBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    -- ltListBtn['4ju']:setPositionX(ltListBtn['3ren']:getPositionX())
    -- ltListBtn['8ju']:setPositionX(ltListBtn['4ren']:getPositionX())
    -- ltListBtn['1quan']:setVisible(false)
    -- ltListBtn['1quan']:setTouchEnabled(false)

    -- self:setCreateRoomBtnTips(self.panel_roomMJHeiBei, ltQuesContent) -- 可直接使用封装好的函数，省略上面QuesBtnCallBack函数和一个for循环
    local difen       = 1
    local paofen      = 0
    local desk_mode   = 2
    local ren_mode    = 4
    local player_mode = {}

    local str
    local jushu = 1
    local function setModeOrDefaultTrue(opt)
        local optTable = {'dzx', 'qsh', 'bgyjp', 'dfp', 'mpqt', 'ghgl', 'zkzm'}
        for i , v in ipairs(optTable) do
            if nil ~= opt[v] then
                player_mode[v] = opt[v]
            else
                player_mode[v] = true
            end
        end
    end

    local function setModeOrDefaultFalse(opt)
        local optTable = {'cpht', 'gshz',}
        for i , v in ipairs(optTable) do
            player_mode[v] = opt[v] or false
        end
    end
    setModeOrDefaultTrue({})
    setModeOrDefaultFalse({})

    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            local paofen_mode = 0
            ren_mode             = self.club_room_info.params.people_num
            jushu                = self.club_room_info.params.total_ju
            difen                = self.club_room_info.params.iDiFeng
            paofen_mode          = self.club_room_info.params.iPaoFen
            player_mode['dzx']   = self.club_room_info.params.isDaiZhuangXian
            player_mode['qsh']   = self.club_room_info.params.isQiShouHua
            player_mode['bgyjp'] = self.club_room_info.params.isBGYJP
            player_mode['dfp']   = self.club_room_info.params.isDaiFeng
            player_mode['mpqt']  = self.club_room_info.params.isMPQT
            player_mode['gshz']  = self.club_room_info.params.isGSHZ
            player_mode['ghgl']  = self.club_room_info.params.isGHGL
            player_mode['zkzm']  = self.club_room_info.params.isZKZM
            player_mode['cpht']  = self.club_room_info.params.isCPHT
            ----------------------------------

            paofen = paofen_mode / difen

            if jushu == 4 then
                desk_mode = 1
            elseif jushu == 8 then
                desk_mode = 2
            elseif jushu == 16 then
                desk_mode = 3
            end

        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                local opt = qyq_opt

                setModeOrDefaultTrue(opt)

                setModeOrDefaultFalse(opt)

                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 3
                end
                ren_mode = qyq_opt[ren_mode_str] or 3
                difen    = qyq_opt[difen_mode_str] or 1
                paofen   = qyq_opt[paofen_mode_str] or 0
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)

            for k,v in pairs(opt) do
                opt[k] = v
            end

            local opt = opt

            setModeOrDefaultTrue(opt)

            setModeOrDefaultFalse(opt)

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 ) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 3
            end
            ren_mode = opt[ren_mode_str] or 3
            difen    = opt[difen_mode_str] or 1
            paofen   = opt[paofen_mode_str] or 0
        end
    end

     local posX = ccui.Helper:seekWidgetByName(panel, "8ju"):getChildByName("fangka"):getPositionX()

    local function initShowOpt()
        local ltRenMode = {2,3,4}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        self:setOpt(ltListBtn['4ju'], nil, desk_mode == 1)
        self:setOpt(ltListBtn['8ju'], nil, desk_mode == 2)
        self:setOpt(ltListBtn['16ju'], nil, desk_mode == 3)

        self:setOpt(ltListBtn['1fen'], nil, difen == 1)
        self:setOpt(ltListBtn['2fen'], nil, difen == 2)
        self:setOpt(ltListBtn['5fen'], nil, difen == 5)
        self:setOpt(ltListBtn['10fen'], nil, difen == 10)

        self:setOpt(ltListBtn['bupaofen'], nil, paofen == 0)
        self:setOpt(ltListBtn['pao1'], nil, paofen == 1)
        self:setOpt(ltListBtn['pao2'], nil, paofen == 2)
        self:setOpt(ltListBtn['pao3'], nil, paofen == 3)

        ltListBtn["pao1"]:setTitleText("跑" .. difen)
        ltListBtn["pao2"]:setTitleText("跑" .. 2 * difen)
        ltListBtn["pao3"]:setTitleText("跑" .. 3 * difen )

        local player_mode_true_false = {'dzx', 'qsh', 'bgyjp',
                                        'dfp', 'mpqt', 'cpht',
                                        'gshz', 'ghgl', 'zkzm',
                                        }

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.fnmj_ren_mode    = ren_mode
        self.fnmj_desk_mode   = desk_mode
        self.fnmj_difen_mode  = difen
        self.fnmj_paofen_mode = paofen
        self.fnmj_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                ren_mode = 2
            elseif szName == '3ren' then
                ren_mode = 3
            elseif szName == '4ren' then
                ren_mode = 4
            elseif szName == '4ju' then
                desk_mode = 1
            elseif szName == '8ju' then
                desk_mode = 2
            elseif szName == '16ju' then
                desk_mode = 3
            elseif szName == '1fen' then
                difen = 1
            elseif szName == '2fen' then
                difen = 2
            elseif szName == '5fen' then
                difen = 5
            elseif szName == '10fen' then
                difen = 10
            elseif szName == 'bupaofen' then
                paofen = 0
            elseif szName == 'pao1' then
                paofen = 1
            elseif szName == 'pao2' then
                paofen = 2
            elseif szName == 'pao3' then
                paofen = 3
            elseif
                szName == 'dzx' or
                szName == 'qsh' or
                szName == 'bgyjp' or
                szName == 'dfp' or
                szName == 'gshz' or
                szName == 'ghgl' or
                szName == 'zkzm'
                then
                player_mode[szName] = not player_mode[szName]
            elseif szName == 'mpqt' then
                player_mode['mpqt'] = not player_mode['mpqt']
                if player_mode['mpqt'] then
                    player_mode['cpht'] = false
                end
            elseif szName == 'cpht' then
                player_mode['cpht'] = not player_mode['cpht']
                if player_mode['cpht'] then
                    player_mode['mpqt'] = false
                end
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

-- 向服务器发送消息
function CreateLayer:sendCreateFengNingRoom(ltmake_cards)
    --  丰宁麻将
    local ju = 8
    -----------------------------------------------
    local clientIp        = gt.getClientIp()
    local ren_mode        = self.fnmj_ren_mode
    local desk_mode       = self.fnmj_desk_mode
    local player_mode     = self.fnmj_player_mode
    local difen_mode      = self.fnmj_difen_mode
    local paofen_mode     = self.fnmj_paofen_mode
    local desk_mode_str   = 'fnmj_desk_mode'
    local ren_mode_str    = 'fnmj_ren_mode'
    local difen_mode_str  = 'fnmj_difen_mode'
    local paofen_mode_str = 'fnmj_paofen_mode'
    local qyq_opt_str     = 'qyqfnmj_opt'
    local opt_str         = 'fnmj_opt'
    local paofen          = 0
    -----------------------------------------------

    if desk_mode == 1 then
        ju = 4
    elseif desk_mode == 2 then
        ju = 8
    elseif desk_mode == 3 then
        ju = 16
    end

    paofen = paofen_mode * difen_mode

    local net_msg = {
        cmd        = NetCmd.C2S_MJ_FN_CREATE_ROOM,
        total_ju   = ju,
        people_num = ren_mode,
        qunzhu     = self.qunzhu,
        copy       = 0,

        ----------------------------------
        iDiFeng         = difen_mode,           -- 底分
        iPaoFen         = paofen,               -- 跑分
        isDaiZhuangXian = player_mode['dzx'],   -- 带庄闲
        isQiShouHua     = player_mode['qsh'],   -- 起手花
        isBGYJP         = player_mode['bgyjp'], -- 补杠一家赔
        isDaiFeng       = player_mode['dfp'],   -- 带风牌
        isMPQT          = player_mode['mpqt'],  -- 摸牌前推
        isCPHT          = player_mode['cpht'],  -- 出牌后推
        isGSHZ          = player_mode['gshz'],  -- 杠随胡走
        isGHGL          = player_mode['ghgl'],  -- 过胡过轮
        isZKZM          = player_mode['zkzm'],  -- 只可自摸
        ------------------------------------

        make_cards = ltmake_cards,
        clubOpt    = self.clubOpt,
        room_id    = self.room_id,
        club_id    = self.club_id,
        isGM       = self.isGM,
        lat        = clientIp[1],
        lon        = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str]   = desk_mode
    mode[ren_mode_str]    = ren_mode
    mode[difen_mode_str]  = difen_mode
    mode[paofen_mode_str] = paofen_mode

    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

function CreateLayer:createZhuoHongSan(panel)
    local desk_mode_str = 'zgz_desk_mode'
    local ren_mode_str  = 'zgz_ren_mode'
    local qyq_opt_str   = 'qyqzgz_opt'
    local opt_str       = 'zgz_opt'
    local qipai_type    = 'pk_zgz'

    local ltListBtnName = {
            '5ren', '6ren',
            '6ju', '8ju', '10ju',
            'zhsbt', 'blfks',
            'xssp', 'hspr', 'hsjf', 'ptwf',
            'zhygbd', 'classic', 'popular',
        }

    local ltListBtn = {}

    for i , v in ipairs(ltListBtnName) do
        local btnName = v
        ltListBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    local ltQuesContent = {
        ['zhsbt'] = '捉红三：方三必亮，红三可选亮或不亮，\n'..
                    '股家默认不扎股',
        ['hsjf']  = '勾选后，三家或股家被关玩家中有亮黑3\n的玩家，'..
                    '则额外多得或者多出1分/2分。',
    }

    local function QuesBtnCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()

            local szName = sender:getParent():getName()

            if panel.tipMsgNode and panel.tipMsgNode.lnSelectName ~= szName then
                panel.tipMsgNode:removeFromParent(true)
                panel.tipMsgNode = nil
            end

            if not panel.tipMsgNode then
                local tipMsgNode = nil
                if szName == 'dkskh' then
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode5Line.csb"),"ccui.Widget")
                else
                    tipMsgNode = tolua.cast(cc.CSLoader:createNode("ui/TipMsgNode.csb"),"ccui.Widget")
                end
                sender:getParent():addChild(tipMsgNode)
                tipMsgNode:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))
                ccui.Helper:doLayout(tipMsgNode)
                local labTip = ccui.Helper:seekWidgetByName(tipMsgNode, "labTip")

                labTip:setString(ltQuesContent[szName] or '内容加载中。。。')

                local pos = cc.p(sender:getPosition())
                local arrow = tipMsgNode:getChildByName("arrow")
                arrow:setPositionX(arrow:getPositionX()-17)
                arrow:setPositionY(arrow:getPositionY()+4)
                pos.y = pos.y+16

                tipMsgNode:getChildByName("panMsg"):setAnchorPoint(cc.p(0.94, 0))

                tipMsgNode:setPosition(pos)

                panel.tipMsgNode = tipMsgNode
                panel.tipMsgNode.lnSelectName = szName

                tipMsgNode:stopAllActions()
                tipMsgNode:setScale(0, 1)
                local scaleTo = cc.ScaleTo:create(0.2, 1, 1)
                tipMsgNode:runAction(scaleTo)
            else
                panel.tipMsgNode:stopAllActions()
                local scaleTo = cc.ScaleTo:create(0.2, 0, 1)
                local callfunc = cc.CallFunc:create(function()
                    panel.tipMsgNode:removeFromParent(true)
                    panel.tipMsgNode = nil
                end)
                local seq = cc.Sequence:create(scaleTo, callfunc)
                panel.tipMsgNode:runAction(seq)
            end
        end
    end

    for i , v in pairs(ltQuesContent) do
        local btSelect = ccui.Helper:seekWidgetByName(panel, i)
        local btQues = ccui.Helper:seekWidgetByName(btSelect,"ques")
        btQues:addTouchEventListener(QuesBtnCallBack)
    end

    local desk_mode      = 2
    local ren_mode       = 5
    local player_mode    = {}
    local jushu          = 1
    local str
    player_mode['style'] = true

    local function setModeOrDefaultTrue(opt)
        local optTable = {'xssp', 'hspr', 'ptwf'}
        for i , v in ipairs(optTable) do
            if nil ~= opt[v] then
                player_mode[v] = opt[v]
            else
                player_mode[v] = true
            end
        end
    end
    local function setModeOrDefaultFalse(opt)
        local optTable = {'blfks', 'zhsbt', 'hsjf', 'zhygbd'}
        for i , v in ipairs(optTable) do
            player_mode[v] = opt[v] or false
        end
    end
    setModeOrDefaultTrue({})
    setModeOrDefaultFalse({})
    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            ren_mode              = self.club_room_info.params.people_num
            jushu                 = self.club_room_info.params.total_ju

            player_mode['zhsbt']  = self.club_room_info.params.zhuo_hong_san
            player_mode['xssp']   = self.club_room_info.params.sheng_pai
            player_mode['hspr']   = self.club_room_info.params.isHSPR
            player_mode['hsjf']   = self.club_room_info.params.isHSJF
            player_mode['blfks']  = self.club_room_info.params.isBLFKS
            player_mode['ptwf']   = self.club_room_info.params.isPTWF
            player_mode['zhygbd'] = self.club_room_info.params.isZHYGBD
            player_mode['style']  = self.club_room_info.params.isJDFG or false

            if jushu == 6 then
                desk_mode = 1
            elseif jushu == 8 then
                desk_mode = 2
            elseif jushu == 10 then
                desk_mode = 3
            end
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end

                local opt = qyq_opt

                setModeOrDefaultTrue(opt)

                setModeOrDefaultFalse(opt)

                if qyq_opt[desk_mode_str] and (qyq_opt[desk_mode_str] == 1 or qyq_opt[desk_mode_str] == 2 or qyq_opt[desk_mode_str] == 3 or qyq_opt[desk_mode_str] == 4) then
                    desk_mode = qyq_opt[desk_mode_str]
                else
                    desk_mode = 1
                end
                ren_mode = qyq_opt[ren_mode_str] or 5
                if qyq_opt['style'] == false then
                    player_mode['style'] = false
                end
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)
            for k,v in pairs(opt) do
                opt[k] = v
            end

            local opt = opt

            setModeOrDefaultTrue(opt)

            setModeOrDefaultFalse(opt)

            if opt[desk_mode_str] and (opt[desk_mode_str] == 1 or opt[desk_mode_str] == 2 or opt[desk_mode_str] == 3 or opt[desk_mode_str] == 4) then
                desk_mode = opt[desk_mode_str]
            else
                desk_mode = 2
            end
            ren_mode = opt[ren_mode_str] or 5

            if opt['style'] == false then
                player_mode['style'] = false
            end
        end
    end

    local function initShowOpt()
        local ltRenMode = {5,6}
        for i = 1,#ltRenMode do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, ltRenMode[i] .. 'ren'), "ccui.Button")
            self:setOpt(btnSelect,nil,ren_mode == ltRenMode[i])
        end

        if ren_mode == 6 then
            player_mode['zhsbt'] = false
            player_mode['blfks'] = false
            player_mode['ptwf']  = true
            player_mode['hsjf'] = false

            ltListBtn['blfks']:setVisible(false)
            ltListBtn['zhsbt']:setVisible(false)
            ltListBtn['hsjf']:setVisible(false)
            ltListBtn['zhygbd']:setVisible(true)
        else
            player_mode['zhygbd'] = false

            ltListBtn['blfks']:setVisible(true)
            ltListBtn['zhsbt']:setVisible(true)
            ltListBtn['hsjf']:setVisible(true)
            ltListBtn['zhygbd']:setVisible(false)
        end

        self:setOpt(ltListBtn['6ju'], nil, desk_mode == 1)
        self:setOpt(ltListBtn['8ju'], nil, desk_mode == 2)
        self:setOpt(ltListBtn['10ju'], nil, desk_mode == 3)

        self:setOpt(ltListBtn['classic'], nil, player_mode['style'] == true)
        self:setOpt(ltListBtn['popular'], nil, player_mode['style'] == false)
        local player_mode_true_false = {'zhsbt','xssp','hspr','hsjf','blfks','ptwf','zhygbd'}

        for i , v in pairs(player_mode_true_false) do
            local btnSelect = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
            self:setOpt(btnSelect,nil,player_mode[v])
        end
        self.zgz_ren_mode = ren_mode
        self.zgz_desk_mode = desk_mode
        self.zhs_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '5ren' then
                ren_mode = 5
            elseif szName == '6ren' then
                ren_mode = 6
            elseif szName == '6ju' then
                desk_mode = 1
            elseif szName == '8ju' then
                desk_mode = 2
            elseif szName == '10ju' then
                desk_mode = 3
            elseif szName == 'zhsbt' then
                player_mode['zhsbt'] = true
                player_mode['blfks'] = false
                player_mode['ptwf']  = false
                ren_mode = 5
            elseif szName == 'blfks' then
                player_mode['zhsbt'] = false
                player_mode['blfks'] = true
                player_mode['ptwf']  = false
                ren_mode = 5
            elseif szName == 'ptwf' then
                player_mode['zhsbt'] = false
                player_mode['blfks'] = false
                player_mode['ptwf']  = true
            elseif szName =='hsjf' then
                player_mode[szName] = not player_mode[szName]
                ren_mode = 5
            elseif szName == 'xssp'
                or szName == 'zhygbd'
                or szName == "hspr" then
                player_mode[szName] = not player_mode[szName]
            elseif szName == 'classic' then
                player_mode["style"] = true
            elseif szName == 'popular' then
                player_mode["style"] = false
            end
            initShowOpt()
        end
    end

    for i , v in pairs(ltListBtn) do
        local btn = ltListBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
end

function CreateLayer:createJdpdk(panel)
    local qyq_opt_str = 'qyqjdpdk_opt'
    local opt_str = 'jdpdk_opt'
    local qipai_type = 'pk_jdpdk'

    local listBtnName = {
            '2ren', '3ren',
            '1ju', '4ju', '8ju',
            'xcht3',
        }

    local listBtn = {}

    for i , v in ipairs(listBtnName) do
        local btnName = v
        listBtn[v] = tolua.cast(ccui.Helper:seekWidgetByName(panel, v), "ccui.Button")
    end

    local tips = {
        ['xcht3'] = '勾选后，开局必须出带有红桃3的牌型，\n'..
                    '不勾选，有红桃3的玩家先出牌，且可\n'..
                    '出任意牌型。',
    }

    self:setCreateRoomBtnTips(panel, tips)

    local player_mode    = {}
    player_mode['renshu'] = 3
    player_mode['jushu'] = 4
    player_mode['chu_san'] = 0

    if self.clubOpt then
        if self.clubOpt == 2 and self.club_room_info.params.qipai_type == qipai_type then
            player_mode['renshu'] = self.club_room_info.params.people_num
            player_mode['jushu']  = self.club_room_info.params.total_ju

            player_mode['chu_san']  = self.club_room_info.params.chu_san
        else
            str = cc.UserDefault:getInstance():getStringForKey(qyq_opt_str, "")
            if str and str ~= "" then
                local qyq_opt = json.decode(str)
                commonlib.echo(qyq_opt)
                for k,v in pairs(qyq_opt) do
                    qyq_opt[k] = v
                end
                player_mode['renshu']  = qyq_opt['renshu']
                player_mode['jushu']   = qyq_opt['jushu']
                player_mode['chu_san'] = qyq_opt['chu_san']
            end
        end
    else
        str = cc.UserDefault:getInstance():getStringForKey(opt_str, "")
        if str and str ~= "" then
            local opt = json.decode(str)
            commonlib.echo(opt)
            for k,v in pairs(opt) do
                opt[k] = v
            end
            player_mode['renshu']  = opt['renshu']
            player_mode['jushu']   = opt['jushu']
            player_mode['chu_san'] = opt['chu_san']
        end
    end

    local function initShowOpt()
        self:setOpt(listBtn['2ren'], nil, player_mode['renshu'] == 2)
        self:setOpt(listBtn['3ren'], nil, player_mode['renshu'] == 3)

        self:setOpt(listBtn['1ju'], nil, player_mode['jushu'] == 1)
        self:setOpt(listBtn['4ju'], nil, player_mode['jushu'] == 4)
        self:setOpt(listBtn['8ju'], nil, player_mode['jushu'] == 8)

        self:setOpt(listBtn['xcht3'], nil, player_mode['chu_san'] == 1)

        self.jdpdk_player_mode = player_mode
    end

    initShowOpt()

    local function btnSelectCallBack(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local szName = sender:getName()
            print(szName)
            if szName == '2ren' then
                player_mode['renshu'] = 2
            elseif szName == '3ren' then
                player_mode['renshu'] = 3
            elseif szName == '1ju' then
                player_mode['jushu'] = 1
            elseif szName == '4ju' then
                player_mode['jushu'] = 4
            elseif szName == '8ju' then
                player_mode['jushu'] = 8
            elseif szName =='xcht3' then
                if player_mode["chu_san"] == 0 then
                    player_mode["chu_san"] = 1
                else
                    player_mode["chu_san"] = 0
                end
            end
            initShowOpt()
        end
    end

    for i , v in pairs(listBtn) do
        local btn = listBtn[i]
        btn:addTouchEventListener(btnSelectCallBack)
    end
    ccui.Helper:seekWidgetByName(panel,"btEnter"):addTouchEventListener(function(sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            local clientIp = gt.getClientIp()
            if not self.isGM and self.isFzb == 1 and tonumber(clientIp[1])==0 and tonumber(clientIp[2]) == 0 then
                commonlib.avoidJoinTip()
            else
                if self.clubOpt and (self.clubOpt == 3 or self.clubOpt == 2) and self.isGM then
                    local str = "本亲友圈"
                    if self.clubOpt == 2 then
                        str = "此桌子"
                    end
                    commonlib.showRoomTipDlg("确定修改"..str.."的玩法吗？", function(ok)
                        if ok then
                            self:sendCreateJdpdk()
                        end
                    end)
                else
                    self:sendCreateJdpdk()
                end
            end

            self.pdkButtonClickTime = buttonClickTime.startButtonClickTimeSchedule(
                function() sender:setTouchEnabled(false) end,
                function() sender:setTouchEnabled(true) end)
        end
    end)
end

function CreateLayer:sendCreateJdpdk()
    local clientIp    = gt.getClientIp()
    local player_mode = self.jdpdk_player_mode
    local qyq_opt_str = 'qyqjdpdk_opt'

    local opt_str = 'jdpdk_opt'
    local net_msg = {
        cmd        = NetCmd.C2S_PDK_CREATE_ROOM,
        total_ju   = player_mode['jushu'],
        people_num = player_mode['renshu'],
        qunzhu     = self.qunzhu,
        copy       = 0,

        chu_san    = player_mode['chu_san'],  -- false:[默认不勾选], true:勾选先出红桃三玩法
        isJDPDK    = true,

        make_cards = ltmake_cards,
        clubOpt    = self.clubOpt,
        room_id    = self.room_id,
        club_id    = self.club_id,
        isGM       = self.isGM,
        lat        = clientIp[1],
        lon        = clientIp[2],
    }

    ymkj.SendData:send(json.encode(net_msg))
    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(player_mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(player_mode))
    end
    cc.UserDefault:getInstance():flush()
end

function CreateLayer:sendCreateZhouHongSanRoom(ltmake_cards)
    local clientIp = gt.getClientIp()
    --  捉红三
    local ju = 8
    -----------------------------------------------
    local ren_mode = self.zgz_ren_mode
    local desk_mode = self.zgz_desk_mode
    local player_mode = self.zhs_player_mode
    local desk_mode_str = 'zgz_desk_mode'
    local ren_mode_str = 'zgz_ren_mode'
    local qyq_opt_str = 'qyqzgz_opt'
    local opt_str = 'zgz_opt'
    -----------------------------------------------

    if desk_mode == 1 then
        ju = 6
    elseif desk_mode == 2 then
        ju = 8
    elseif desk_mode == 3 then
        ju = 10
    end
    local net_msg = {
        cmd           =NetCmd.C2S_ZGZ_CREATE_ROOM,
        total_ju      =ju,
        people_num    =ren_mode,
        qunzhu        =self.qunzhu,
        copy          =0,

        -- wait_add
        zhuo_hong_san = player_mode['zhsbt'],  -- false:[默认不勾选], true:勾选捉红三玩法
        sheng_pai     = player_mode['xssp'],   -- false:[不显示剩牌], true:显示剩牌
        isHSPR        = player_mode['hspr'],   -- false:[黑三不骗人], true:黑三骗人
        isHSJF        = player_mode['hsjf'],   -- false:[黑三不加分], true:黑三加分
        isBLFKS       = player_mode['blfks'],  -- 必亮方块三
        isPTWF        = player_mode['ptwf'],   -- 普通玩法
        isZHYGBD      = player_mode['zhygbd'], -- 最后一股不打
        isJDFG        = player_mode['style'],  -- false:[流行风格], true:[经典风格]

        make_cards    = ltmake_cards,
        clubOpt       = self.clubOpt,
        room_id       = self.room_id,
        club_id       = self.club_id,
        isGM          = self.isGM,
        lat           = clientIp[1],
        lon           = clientIp[2],
    }

    log('CreateLayer:sendCreateZhouHongSanRoom')
    ymkj.SendData:send(json.encode(net_msg))
    log('CreateLayer:sendCreateZhouHongSanRoom')
    -- dump(net_msg)
    local mode = self:tblCopy(player_mode)
    mode[desk_mode_str] = desk_mode
    mode[ren_mode_str] = ren_mode

    if self.clubOpt then
        if self.clubOpt ~= 2 then
            cc.UserDefault:getInstance():setStringForKey(qyq_opt_str, json.encode(mode))
        end
    else
        cc.UserDefault:getInstance():setStringForKey(opt_str, json.encode(mode))
    end
    cc.UserDefault:getInstance():flush()
end

return CreateLayer