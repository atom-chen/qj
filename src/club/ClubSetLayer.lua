require('club.ClubHallUI')

local ClubSetLayer = class("ClubSetLayer", function()
    return cc.Layer:create()
end)

function ClubSetLayer:create(args)
    local layer   = ClubSetLayer.new()
    layer.isBoss  = args.isBoss
    layer.isAdmin = args.isAdmin
    layer.data    = args.data
    layer.clubs   = args.clubs or {}
    layer:setName("ClubSetLayer")
    layer:createLayerMenu()
    return layer
end

function ClubSetLayer:registerEventListener()
    local CUSTOM_LISTENERS = {
        ["qinliao_push_url"]      = handler(self, self.onQinLiaoPush),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function ClubSetLayer:unregisterEventListener()
    local LISTENER_NAMES = {
        ["qinliao_push_url"]            = handler(self, self.onQinLiaoPush),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function ClubSetLayer:onQinLiaoPush(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        print("onQinLiaoPush no rtn_msg")
        return
    end
    local tab = json.decode(rtn_msg)
    if tab and tab.code == 200 and tab.data then
        ymkj.copyClipboard(tab.data)
        commonlib.showPushQinLiaoTip(tab.data)
    else
        commonlib.showLocalTip(tab.msg or "" .. tab.code or "未知错误")
    end
end

function ClubSetLayer:exitLayer()
    self:unregisterEventListener()
    self:removeFromParent(true)
end

function ClubSetLayer:setBtnState(btn)
    if btn.isOpen == 0 then
        btn:loadTextureNormal("ui/qj_button/dt_setting_btn_close.png")
        btn:loadTexturePressed("ui/qj_button/dt_setting_btn_close.png")
    else
        btn:loadTextureNormal("ui/qj_button/dt_setting_btn_open.png")
        btn:loadTexturePressed("ui/qj_button/dt_setting_btn_open.png")
    end
end

function ClubSetLayer:isImgTimeOpen()
    if self.openCSTGBtn.isOpen ~= 0 then
        self.openImgTime:setVisible(true)
        if self.openImgTime.isOpen then
            self.imgTime:setVisible(true)
            self.openImgTime:setScaleX(-1)
        else
            self.imgTime:setVisible(false)
            self.openImgTime:setScaleX(1)
        end
    else
        self.openImgTime:setVisible(false)
        self.imgTime:setVisible(false)
    end
    self.imgOpenPush:setVisible(not self.imgTime:isVisible())
end

function ClubSetLayer:timeBtnStatus()
    for i, v in pairs(self.timeBtn) do
        if self.openImgTime.time == i then
            v:getChildByName("imgbtn"):loadTexture("ui/qj_setting/speedBtn_select.png")
            self.label_time:setString("(" .. self.openImgTime.time .. "秒)")
        else
            v:getChildByName("imgbtn"):loadTexture("ui/qj_setting/speedBtn_normal.png")
        end
    end
end

function ClubSetLayer:onClubModify(rtn_msg)
    local club_id = self.data.club_info.club_id
    if (rtn_msg.isACWF == 0 or rtn_msg.isACWF == 1) and club_id == rtn_msg.club_id then
        if self.setPlayBtn then
            self.setPlayBtn.isOpen = rtn_msg.isACWF
            self:setBtnState(self.setPlayBtn)
        end
        self.data.club_info.isACWF = rtn_msg.isACWF
    elseif (rtn_msg.isOpen == 0 or rtn_msg.isOpen == 1) and club_id == rtn_msg.club_id then
        if self.openQyqBtn then
            self.openQyqBtn.isOpen = rtn_msg.isOpen
            self:setBtnState(self.openQyqBtn)
        end
        self.data.club_info.isOpen = rtn_msg.isOpen
    elseif (rtn_msg.isAKFK == 0 or rtn_msg.isAKFK == 1) and club_id == rtn_msg.club_id then
        if self.openCardBtn then
            self.openCardBtn.isOpen = rtn_msg.isAKFK
            self:setBtnState(self.openCardBtn)
        end
        self.data.club_info.isAKFK = rtn_msg.isAKFK
    elseif (rtn_msg.isAKZJ == 0 or rtn_msg.isAKZJ == 1) and club_id == rtn_msg.club_id then
        if self.openZhanjiBtn then
            self.openZhanjiBtn.isOpen = rtn_msg.isAKZJ
            self:setBtnState(self.openZhanjiBtn)
        end
        self.data.club_info.isAKZJ = rtn_msg.isAKZJ
    elseif (rtn_msg.isFZB == 0 or rtn_msg.isFZB == 1) and club_id == rtn_msg.club_id then
        if self.openFZBBtn then
            self.openFZBBtn.isOpen = rtn_msg.isFZB
            self:setBtnState(self.openFZBBtn)
        end
        self.data.club_info.isFZB = rtn_msg.isFZB
        self.tipStr.isFZB         = true
        -- commonlib.avoidJoinTip(nil,true)
    elseif (rtn_msg.is4To32 == 0 or rtn_msg.is4To32 == 1) and club_id == rtn_msg.club_id then
        print('--------------------------------')
        if self.openLJKJBtn then
            self.openLJKJBtn.isOpen = rtn_msg.is4To32
            self:setBtnState(self.openLJKJBtn)
        end
        self.data.club_info.is4To32 = rtn_msg.is4To32
        print('--------------------------------')
        self.tipStr.is4To32 = true
        -- commonlib.avoidJoinTip(nil,true)
    elseif (rtn_msg.isJZBQ == 0 or rtn_msg.isJZBQ == 1) and club_id == rtn_msg.club_id then
        if self.openBQBtn then
            self.openBQBtn.isOpen = rtn_msg.isJZBQ
            self:setBtnState(self.openBQBtn)
        end
        self.data.club_info.isJZBQ = rtn_msg.isJZBQ
        self.tipStr.isJZBQ         = true
    elseif (rtn_msg.isJSAA == 0 or rtn_msg.isJSAA == 1) and club_id == rtn_msg.club_id then
        if self.openJSAABtn then
            self.openJSAABtn.isOpen = rtn_msg.isJSAA
            self:setBtnState(self.openJSAABtn)
        end
        self.data.club_info.isJSAA = rtn_msg.isJSAA
        self.tipStr.isJSAA         = true
    elseif (rtn_msg.cTGT and rtn_msg.cTGT >= 0) and club_id == rtn_msg.club_id then
        if self.openCSTGBtn then
            self.openCSTGBtn.isOpen = rtn_msg.cTGT
            if rtn_msg.cTGT ~= 0 then
                self.openImgTime.time   = rtn_msg.cTGT
                self:timeBtnStatus()
                cc.UserDefault:getInstance():setIntegerForKey("cstg_time", rtn_msg.cTGT)
                cc.UserDefault:getInstance():flush()
            end
            self:setBtnState(self.openCSTGBtn)
            self:isImgTimeOpen()
        end
        self.data.club_info.cTGT = rtn_msg.cTGT
        self.tipStr.cTGT         = true
    elseif rtn_msg.name then
        if self.data.club_info.club_id == rtn_msg.club_id then
            local tQyqName = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "tQyqName")
            tQyqName:setString(tostring(self.data.club_info.club_name))

            self.data.club_info.isChangedName = true
        end
        -- local function setClubName(panel,club_id,club_name)
        --     local listView = panel:getChildByName("ClubList")
        --     local all_items = tolua.cast(listView, "ccui.ListView"):getItems()

        --     for i, item in ipairs(all_items) do
        --         print("item.club_id",item.club_id)
        --         if item.club_id == club_id then
        --             local name = item:getChildByName("name")
        --             name:setString(club_name or "")
        --             break
        --         end
        --     end
        -- end
        -- if self.isBoss or self.isAdmin then
        --     setClubName(self.ClubBossPanel,rtn_msg.club_id,rtn_msg.name)
        -- else
        --     setClubName(self.ClubPanel,rtn_msg.club_id,rtn_msg.name)
        -- end
    end
end

function ClubSetLayer:createLayerMenu()
    -- dump(self.data,"self.data")
    local csb  = ClubHallUI.getInstance().csb_club_setting
    local node = tolua.cast(cc.CSLoader:createNode(csb), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    self.ClubPanel     = ccui.Helper:seekWidgetByName(node, "ClubPanel")
    self.ClubBossPanel = ccui.Helper:seekWidgetByName(node, "ClubBossPanel")

    -- 允许修改玩法
    local imgSetPlay    = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgSetPlay")
    self.setPlayBtn     = ccui.Helper:seekWidgetByName(imgSetPlay, "btn")
    -- 允许查看房卡
    local imgOpenCard   = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenCard")
    self.openCardBtn    = ccui.Helper:seekWidgetByName(imgOpenCard, "btn")
    -- 允许查看战绩
    local imgOpenZhanji = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenZhanji")
    self.openZhanjiBtn  = ccui.Helper:seekWidgetByName(imgOpenZhanji, "btn")

    if self.isBoss or self.isAdmin then
        self:initBossUI()
    else
        self:initUI()
    end
    local tipStr   = {}
    tipStr.is4To32 = false
    tipStr.isFZB   = false
    tipStr.isJZBQ  = false
    tipStr.isJSAA  = false
    self.tipStr    = tipStr

    local btExit = tolua.cast(ccui.Helper:seekWidgetByName(node, "btn-exit"), "ccui.Button")
    btExit:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local str = ""
            if self.tipStr.is4To32 then
                str = str .. "立即开局、"
            end
            if self.tipStr.isFZB then
                str = str .. "防作弊、"
            end
            if self.tipStr.isJZBQ then
                str = str .. "禁止表情、"
            end
            if self.tipStr.cTGT then
                str = str .. "超时托管、"
            end
            if #str ~= 0 then
                str = string.sub(str, 1, -4)
                commonlib.avoidJoinTip(nil, str)
            end
            self:exitLayer()
        end
    end)

    self:registerEventListener()

    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"))
    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_1"))
    -- 功能设置
    local btnSet    = ccui.Helper:seekWidgetByName(node, "btnSet")
    -- 亲友列表
    local btnList   = ccui.Helper:seekWidgetByName(node, "btnList")
    local panelSet  = ccui.Helper:seekWidgetByName(node, "ClubSetPanel")
    local panelList = ccui.Helper:seekWidgetByName(node, "ClubListPanel")

    panelSet:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.openImgTime.isOpen = false
            self:isImgTimeOpen()
        end
    end)

    local function onPayTabCallback(sender)
        btnSet:setScaleX(btnSet == sender and 1.07 or 1)
        btnList:setScaleX(btnList == sender and 1.07 or 1)

        btnSet:setTouchEnabled(btnSet ~= sender)
        btnSet:setBright(btnSet ~= sender)
        btnList:setTouchEnabled(btnList ~= sender)
        btnList:setBright(btnList ~= sender)

        panelSet:setVisible(sender == btnSet)
        panelList:setVisible(sender == btnList)
    end
    local function onPayTabSetCallback(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if sender then
                AudioManager:playPressSound()
            end
            onPayTabCallback(btnSet)
        end
    end
    local function onPayTabListCallback(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if sender then
                AudioManager:playPressSound()
            end
            onPayTabCallback(btnList)
        end
    end

    btnSet:addTouchEventListener(onPayTabSetCallback)
    btnList:addTouchEventListener(onPayTabListCallback)

    onPayTabCallback(btnSet)

    self:enableNodeEvents()
end

function ClubSetLayer:refreshSetUi(clubs, data)
    if self.isBoss or self.isAdmin then
        self:initBossUI(clubs)
    else
        self:initUI(clubs)
    end
    self.data = data
end

function ClubSetLayer:initUI(clubs)
    self.clubs     = clubs or self.clubs
    local baseItem = self.ClubPanel:getChildByName("item")
    baseItem:setVisible(false)
    self.ClubBossPanel:setVisible(false)

    local listView = self.ClubPanel:getChildByName("ClubList")
    listView:removeAllItems()
    for i, club in ipairs(self.clubs) do
        local item = baseItem:clone()
        item:setVisible(true)
        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        local head = item:getChildByName("touxiang")
        head:downloadImg(commonlib.wxHead(club.head))
        local name = item:getChildByName("name")
        if pcall(commonlib.GetMaxLenString, club.club_name, 12) then
            name:setString(commonlib.GetMaxLenString(club.club_name, 12))
        else
            name:setString(club.club_name)
        end
        local id = item:getChildByName("id")
        id:setString(string.format("亲友圈ID:%s", tostring(club.club_id)))
        local btnDel = item:getChildByName("btn-del")
        if club.club_id == gt.getData('uid') then
            btnDel:setVisible(false)
        end
        btnDel:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local args = {
                    msg = string.format("确定要退出%s的亲友圈吗?", club.club_name),
                    okFunc = function()
                        print('member btnDel')
                        local input_msg = {
                            cmd     = NetCmd.C2S_CLUB_DEL_BIND_USER,
                            uid     = gt.getData('uid'),
                            name    = gt.getData('name'),
                            club_id = club.club_id,
                            isBoss  = false,
                        }
                        ymkj.SendData:send(json.encode(input_msg))
                    end,
                    cancelFunc = function()
                        -- body
                    end,
                }
                local ClubTipLayer = require("club.ClubTipLayer")
                self:addChild(ClubTipLayer:create(args), 100)
            end
        end)
        item.club_id = club.club_id
        listView:pushBackCustomItem(item)
    end
end

function ClubSetLayer:initBossUI(clubs)
    self.clubs     = clubs or self.clubs
    -- 亲友列表中ITEM
    local baseItem = self.ClubBossPanel:getChildByName("ClubListPanel"):getChildByName("item")
    self.ClubPanel:setVisible(false)
    self.ClubBossPanel:setVisible(true)
    baseItem:setVisible(false)
    -- 亲友圈名字
    local tQyqName = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "tQyqName")
    if pcall(commonlib.GetMaxLenString, tostring(self.data.club_info.club_name), 12) then
        tQyqName:setString(commonlib.GetMaxLenString(tostring(self.data.club_info.club_name), 12))
    else
        tQyqName:setString(tostring(self.data.club_info.club_name))
    end
    -- 改名按钮
    local btRename = self.ClubBossPanel:getChildByName("ClubSetPanel"):getChildByName("btRename")
    btRename:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local ClubRenameLayer = require("club.ClubRenameLayer")
            local layer           = ClubRenameLayer:create({data = self.data})
            self:addChild(layer)
        end
    end)

    -- 允许修改玩法
    self.setPlayBtn.isOpen = self.data.club_info.isACWF
    self:setBtnState(self.setPlayBtn)
    self.setPlayBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.setPlayBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isACWF  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 开启亲友圈
    local imgOpenQyq       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenQyq")
    self.openQyqBtn        = ccui.Helper:seekWidgetByName(imgOpenQyq, "btn")
    self.openQyqBtn.isOpen = self.data.club_info.isOpen
    self:setBtnState(self.openQyqBtn)
    self.openQyqBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openQyqBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isOpen  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 允许查看房卡
    self.openCardBtn.isOpen = self.data.club_info.isAKFK
    self:setBtnState(self.openCardBtn)
    self.openCardBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openCardBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isAKFK  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 允许查看战绩
    self.openZhanjiBtn.isOpen = self.data.club_info.isAKZJ or 1
    self:setBtnState(self.openZhanjiBtn)
    self.openZhanjiBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openZhanjiBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isAKZJ  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 防作弊、
    local imgOpenFZB       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenFZB")
    self.openFZBBtn        = ccui.Helper:seekWidgetByName(imgOpenFZB, "btn")
    self.openFZBBtn.isOpen = self.data.club_info.isFZB or 0
    self:setBtnState(self.openFZBBtn)
    imgOpenFZB:setVisible(true)
    self.openFZBBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openFZBBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isFZB   = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 立即开局 4转3，2
    local imgOpenLJKJ = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenLJKJ")
    self.openLJKJBtn  = ccui.Helper:seekWidgetByName(imgOpenLJKJ, "btn")
    self.openLJKJBtn.isOpen = self.data.club_info.is4To32 or 0
    self:setBtnState(self.openLJKJBtn)
    imgOpenLJKJ:setVisible(true)
    self.openLJKJBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openLJKJBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                is4To32 = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 屏互动表情
    local imgOpenBQ       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenBQ")
    self.openBQBtn        = ccui.Helper:seekWidgetByName(imgOpenBQ, "btn")
    self.openBQBtn.isOpen = self.data.club_info.isJZBQ or 0
    self:setBtnState(self.openBQBtn)
    self.openBQBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openBQBtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isJZBQ  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 向亲聊推送战绩
    local imgOpenPush       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenPush")
    imgOpenPush:setVisible(true)
    self.imgOpenPush        = imgOpenPush
    self.openPushBtn        = ccui.Helper:seekWidgetByName(imgOpenPush, "btn")
    self.openPushBtn.isOpen = cc.UserDefault:getInstance():getIntegerForKey("imgOpenPush",0)
    self:setBtnState(self.openPushBtn)
    self.openPushBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            if self.openPushBtn.isOpen == 0 then
                self.openPushBtn.isOpen = 1
                local qinliao_push_url = gt.getConf("qinliao_push_url")
                gt.reqHttpGet("qinliao_push_url",qinliao_push_url,{
                    uid = self.data.club_info.club_id,
                })
            elseif self.openPushBtn.isOpen == 1 then
                self.openPushBtn.isOpen = 0
                commonlib.showJieBangQinLiaoTip()
            end
            cc.UserDefault:getInstance():setIntegerForKey("imgOpenPush",self.openPushBtn.isOpen)
            cc.UserDefault:getInstance():flush()
            self:setBtnState(self.openPushBtn)
        end
    end)

    -- 解散需要全部同意
    local imgOpenJSAA       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenJS")
    self.openJSAABtn        = ccui.Helper:seekWidgetByName(imgOpenJSAA, "btn")
    self.openJSAABtn.isOpen = self.data.club_info.isJSAA or 0
    self:setBtnState(self.openJSAABtn)
    self.openJSAABtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openJSAABtn.isOpen == 1 then
                isOpen = 0
            end
            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                isJSAA  = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    -- 超时托管
    local imgOpenCSTG       = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgOpenCSTG")
    self.label_time         = ccui.Helper:seekWidgetByName(imgOpenCSTG, "label_time")
    self.imgTime            = ccui.Helper:seekWidgetByName(self.ClubBossPanel, "imgTime")
    self.openCSTGBtn        = ccui.Helper:seekWidgetByName(imgOpenCSTG, "btn")
    -- 右边箭头按钮
    self.openImgTime        = ccui.Helper:seekWidgetByName(imgOpenCSTG, "btn_open")
    self.openCSTGBtn.isOpen = self.data.club_info.cTGT or 0
    self.openImgTime.isOpen = true
    local cstg_time = cc.UserDefault:getInstance():getIntegerForKey("cstg_time", 60)
    self.openImgTime.time   = self.data.club_info.cTGT == 0 and cstg_time or (self.data.club_info.cTGT or 60)
    self:setBtnState(self.openCSTGBtn)

    self.openCSTGBtn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            local isOpen = 1
            if self.openCSTGBtn.isOpen ~= 0 then
                isOpen = 0
            else
                isOpen = self.openImgTime.time
            end

            local input_msg = {
                cmd     = NetCmd.C2S_CLUB_MODIFY,
                cTGT    = isOpen,
                club_id = self.data.club_info.club_id,
            }
            ymkj.SendData:send(json.encode(input_msg))
        end
    end)

    self:isImgTimeOpen()
    self.openImgTime:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            AudioManager:playPressSound()
            self.openImgTime.isOpen = not self.openImgTime.isOpen
            self:isImgTimeOpen()
        end
    end)

    -- 托管时间按钮
    self.timeBtn = {
        [30]  = ccui.Helper:seekWidgetByName(self.imgTime, "btn_30"),
        [60]  = ccui.Helper:seekWidgetByName(self.imgTime, "btn_60"),
        [120] = ccui.Helper:seekWidgetByName(self.imgTime, "btn_120"),
    }

    self:timeBtnStatus()
    for i, v in pairs(self.timeBtn) do
        v:addTouchEventListener(function (sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                local input_msg = {
                    cmd     = NetCmd.C2S_CLUB_MODIFY,
                    cTGT    = i,
                    club_id = self.data.club_info.club_id,
                }
                ymkj.SendData:send(json.encode(input_msg))
            end
        end)
    end

    local listView = self.ClubBossPanel:getChildByName("ClubListPanel"):getChildByName("ClubList")
    listView:removeAllItems()
    for i, club in ipairs(self.clubs) do
        local item = baseItem:clone()
        item:setVisible(true)
        if i % 2 == 0 then
            item:loadTexture("ui/qj_club/dt_contest_rank_bg1.png")
        end
        local head = item:getChildByName("touxiang")
        head:downloadImg(commonlib.wxHead(club.head))
        local name = item:getChildByName("name")

        if pcall(commonlib.GetMaxLenString, club.club_name, 12) then
            name:setString(commonlib.GetMaxLenString(club.club_name, 12))
        else
            name:setString(club.club_name)
        end

        local id = item:getChildByName("id")
        id:setString(string.format("亲友圈ID:%s", tostring(club.club_id)))
        local btnDel       = item:getChildByName("btn-del")
        local btnShare     = item:getChildByName("btn-share")
        local profile      = ProfileManager.GetProfile()
        local bas          = ymkj.base64Encode(tostring(club.club_id))
        local qyqshare_url = string.format("%s%s", gt.getConf("qyqshare_url"), bas)
        if test_package == 1 then
            qyqshare_url = string.format("%s%s", gt.getConf("qyqshare_url_tyb"), bas)
        end

        local gmUids  = self.data.club_info.gmUids
        local isAdmin = false
        for i = 1, #gmUids do
            if profile.uid == gmUids[i] and club.club_id == self.data.club_info.club_id then
                isAdmin = true
                break
            end
        end
        if (type(profile) == "table" and profile.uid == club.club_id) or isAdmin then
            btnDel:setVisible(false)
            btnShare:setVisible(true)
            btnShare:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local title   = string.format("亲友圈ID:{%s}快来加入我的亲友圈吧", tostring(club.club_id))
                    local content = "点击将自动申请加入此亲友圈，同时可进行游戏下载，还有更多功能等你体验。"
                    gt.wechatShareChatStart()
                    ymkj.wxReq(2, content, title, qyqshare_url)
                    gt.wechatShareChatEnd()
                end
            end)
        else
            btnShare:setVisible(false)
            btnDel:setVisible(true)
            btnDel:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    local args = {
                        msg = string.format("确定要退出%s的亲友圈吗?", club.club_name),
                        okFunc = function()
                            print('btnDel')
                            local input_msg = {
                                cmd     = NetCmd.C2S_CLUB_DEL_BIND_USER,
                                uid     = gt.getData('uid'),
                                name    = gt.getData('name'),
                                club_id = club.club_id,
                                isBoss  = false,
                            }
                            ymkj.SendData:send(json.encode(input_msg))
                        end,
                        cancelFunc = function()
                            -- body
                        end,
                    }
                    local ClubTipLayer = require("club.ClubTipLayer")
                    self:addChild(ClubTipLayer:create(args), 100)
                end
            end)
        end
        item.club_id = club.club_id
        listView:pushBackCustomItem(item)
    end
end

return ClubSetLayer