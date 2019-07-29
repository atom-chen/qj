--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-09-06
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2019-01-10
-- @Desc: 设置对话框
--------------------------------------------------------------------------------
require('scene.DTUI')
require('club.ClubHallUI')

local SetDialog = class("SetDialog", function()
    return gt.createMaskLayer()
end)

function SetDialog:ctor(is_game_start, is_ongame, call_funcBg, call_funcSpeed, call_funcPkCard)
    if IS_SHOW_GRID then
        local gridLayer = require("scene.GridLayer"):create()
        self:addChild(gridLayer, 10000)
    end
    local csb = DTUI.getInstance().csb_main_setting_dialog
    self:addCSNode(csb)
    -- self:printNode()
    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        if call_funcPkCard then
            if self.pkCardType ~= gt.getLocalString("cardType", "classic") then
                call_funcPkCard(true)
            end
        end
        self:removeFromParent(true)
    end)

    self.pnQYQ        = self:seekNode("pnQYQ")        -- 亲友圈三四五桌子
    self.pnSpeed      = self:seekNode("pnSpeed")      -- 出牌速度
    self.pnGps        = self:seekNode("pnGps")        -- GPS按钮相关
    self.pnMusic      = self:seekNode("pnMusic")      -- 音乐
    self.pnTable      = self:seekNode("pnTable")      -- 麻将2d3d
    self.pnBg         = self:seekNode("pnBg")         -- 按钮列表
    self.pnMJBg       = self:seekNode("pnMJBg")       -- 麻将桌布
    self.pnQYQStyle   = self:seekNode('pnQYQStyle')   -- 亲友圈风格
    self.pnStopAction = self:seekNode('pnStopAction') -- 禁止主界面动画
    self.pnHallStyle  = self:seekNode('pnHallStyle')  -- 大厅风格
    self.pnHandCard   = self:seekNode('pnHandCard')   -- 扑克手牌

    self.btnSet      = self:seekNode("btnSet")   -- 游戏设置
    self.btnMusic    = self:seekNode("btnMusic") -- 音乐设置
    self.btnBg       = self:seekNode("btnBg")    -- 亲友设置
    self.btnDesk     = self:seekNode("btnDesk")  -- 桌布设置
    self.btnHall     = self:seekNode("btnHall")  -- 大厅风格设置
    self.btnHandCard = self:seekNode("btnHandCard")  -- 大厅风格设置
    self.btnHall:setVisible(false)

    if not self.btnHall:isVisible() then
        self.btnHandCard:setPositionY(self.btnHall:getPositionY())
    end

    self.pnQYQ:setVisible(false)
    self.pnSpeed:setVisible(false)
    self.pnMusic:setVisible(false)
    self.pnTable:setVisible(false)
    self.pnBg:setVisible(false)
    self.pnMJBg:setVisible(false)
    self.pnQYQStyle:setVisible(false)
    self.pnStopAction:setVisible(false)
    self.pnHallStyle:setVisible(false)
    self.pnHandCard:setVisible(false)

    local function onPayTabCallback(sender)
        self.btnSet:setScaleX(self.btnSet == sender and 1.07 or 1)
        self.btnMusic:setScaleX(self.btnMusic == sender and 1.07 or 1)
        self.btnBg:setScaleX(self.btnBg == sender and 1.07 or 1)
        self.btnDesk:setScaleX(self.btnDesk == sender and 1.07 or 1)
        self.btnHall:setScaleX(self.btnHall == sender and 1.07 or 1)
        self.btnHandCard:setScaleX(self.btnHandCard == sender and 1.07 or 1)

        self.pnQYQ:setVisible(self.btnBg == sender)
        self.pnQYQStyle:setVisible(self.btnBg == sender)
        self.pnSpeed:setVisible(self.btnSet == sender)
        self.pnGps:setVisible(self.btnSet == sender)
        self.pnMusic:setVisible(self.btnMusic == sender)
        self.pnTable:setVisible(self.btnSet == sender)
        self.pnBg:setVisible(self.btnDesk == sender)
        self.pnMJBg:setVisible(self.btnDesk == sender)

        self.pnStopAction:setVisible(self.btnSet == sender and g_close_main_ani)
        self.pnHallStyle:setVisible(self.btnHall == sender)
        self.pnHandCard:setVisible(self.btnHandCard == sender)

        self.btnSet:setTouchEnabled(self.btnSet ~= sender)
        self.btnSet:setBright(self.btnSet ~= sender)
        self.btnMusic:setTouchEnabled(self.btnMusic ~= sender)
        self.btnMusic:setBright(self.btnMusic ~= sender)
        self.btnBg:setTouchEnabled(self.btnBg ~= sender)
        self.btnBg:setBright(self.btnBg ~= sender)
        self.btnDesk:setTouchEnabled(self.btnDesk ~= sender)
        self.btnDesk:setBright(self.btnDesk ~= sender)
        self.btnHall:setTouchEnabled(self.btnHall ~= sender)
        self.btnHall:setBright(self.btnHall ~= sender)
        self.btnHandCard:setTouchEnabled(self.btnHandCard ~= sender)
        self.btnHandCard:setBright(self.btnHandCard ~= sender)
    end
    local function onPayTabSetCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnSet)
    end
    local function onPayTabMusicCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnMusic)
    end
    local function onPayTabBgCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnBg)
    end
    local function onPayTabDeskCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnDesk)
    end
    local function onPayTabHallCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnHall)
    end
    local function onPayTabHandCardCallback(sender)
        if sender then
            AudioManager:playPressSound()
        end
        onPayTabCallback(self.btnHandCard)
    end
    self.btnSet:addClickEventListener(onPayTabSetCallback)
    self.btnMusic:addClickEventListener(onPayTabMusicCallback)
    self.btnBg:addClickEventListener(onPayTabBgCallback)
    self.btnDesk:addClickEventListener(onPayTabDeskCallback)
    self.btnHall:addClickEventListener(onPayTabHallCallback)
    self.btnHandCard:addClickEventListener(onPayTabHandCardCallback)

    if ios_checking then
        self.btnBg:setVisible(false)
        self.pnQYQ:setVisible(false)
        self.pnSpeed:setPositionY(self.pnSpeed:getPositionY() + 150)
        self.pnGps:setPositionY(self.pnGps:getPositionY() + 150)
        self.pnStopAction:setPositionY(self.pnGps:getPositionY() + 150)
    end
    onPayTabCallback(self.btnSet)

    -- 切换主题风格时其设置的默认界面为 设置主题风格 界面。实现玩家的无感关差别
    if gt.getLocalBool("isOpenAgainDialog") then
        onPayTabHallCallback(self.btnHall)
    end

    require('scene.GameSettingDefault')
    -- 游戏风格设置
    -- 麻将桌面设置
    self.bt3D         = self:seekNode("btn3D")
    self.bt2D         = self:seekNode("btn2D")
    self.bt2DBig      = self:seekNode("btn2DBig")
    self.st3DUsing    = self:seekNode("st3DUsing")
    self.st2DUsing    = self:seekNode("st2DUsing")
    self.st2DBigUsing = self:seekNode("st2DBigUsing")
    self.pingmian     = gt.getLocalInt("pingmian", GameSettingDefault.MJ_STYLE)

    -- 默认2d大牌
    if self.pingmian == 0 then
        self.pingmian = GameSettingDefault.MJ_STYLE
    end

    self:refreshPingMian()

    self.bt3D:addClickEventListener(function()
        AudioManager:playPressSound()
        if self.pingmian == 3 then return end
        if is_ongame then
            commonlib.showLocalTip("请去游戏大厅的设置修改")
        else
            self.pingmian = 3
            self:refreshPingMian()
        end
    end)
    self.bt2D:addClickEventListener(function()
        AudioManager:playPressSound()
        if self.pingmian == 2 then return end
        if is_ongame then
            commonlib.showLocalTip("请去游戏大厅的设置修改")
        else
            self.pingmian = 2
            self:refreshPingMian()
        end
    end)
    self.bt2DBig:addClickEventListener(function()
        AudioManager:playPressSound()
        if self.pingmian == 1 then return end
        if is_ongame then
            commonlib.showLocalTip("请去游戏大厅的设置修改")
        else
            self.pingmian = 1
            self:refreshPingMian()
        end
    end)
    -- 桌布设置
    self.btnGreen   = self:seekNode("btnGreen")
    self.btnBlue    = self:seekNode("btnBlue")
    self.btnMjthree = self:seekNode("btnMjthree")
    self.btnMjfour  = self:seekNode("btnMjfour")
    self.btnMjfive  = self:seekNode("btnMjfive")

    self.stGreen   = self:seekNode("stGreen")
    self.stBlue    = self:seekNode("stBlue")
    self.stMjthree = self:seekNode("stMjthree")
    self.stMjfour  = self:seekNode("stMjfour")
    self.stMjfive  = self:seekNode("stMjfive")

    self.zhuobu = gt.getLocalInt("zhuobu", 1)

    self:refreshZhuoBu()

    self.btnGreen:addClickEventListener(function()
        AudioManager:playPressSound()
        self.zhuobu = 1
        self:refreshZhuoBu()
        if call_funcBg then
            call_funcBg(1)
        end
    end)

    self.btnBlue:addClickEventListener(function()
        AudioManager:playPressSound()
        self.zhuobu = 2
        self:refreshZhuoBu()
        if call_funcBg then
            call_funcBg(2)
        end
    end)

    self.btnMjthree:addClickEventListener(function()
        AudioManager:playPressSound()
        self.zhuobu = 3
        self:refreshZhuoBu()
        if call_funcBg then
            call_funcBg(3)
        end
    end)

    self.btnMjfour:addClickEventListener(function()
        AudioManager:playPressSound()
        self.zhuobu = 4
        self:refreshZhuoBu()
        if call_funcBg then
            call_funcBg(4)
        end
    end)

    self.btnMjfive:addClickEventListener(function()
        AudioManager:playPressSound()
        self.zhuobu = 5
        self:refreshZhuoBu()
        if call_funcBg then
            call_funcBg(5)
        end
    end)

    self.btnPkone   = self:seekNode("btnPkone")
    self.btnPktwo   = self:seekNode("btnPktwo")
    self.btnPkthree = self:seekNode("btnPkthree")

    self.stPkone   = self:seekNode("stPkone")
    self.stPktwo   = self:seekNode("stPktwo")
    self.stPkthree = self:seekNode("stPkthree")

    self.pkzhuobu = gt.getLocalInt("pkzhuobu", 1)
    self:refreshPKZhuoBu(is_ongame)

    self.btnPkone:addClickEventListener(function()
        AudioManager:playPressSound()
        self.pkzhuobu = 1
        self:refreshPKZhuoBu(is_ongame)
        if call_funcBg then
            call_funcBg(11)
        end
    end)

    self.btnPktwo:addClickEventListener(function()
        AudioManager:playPressSound()
        self.pkzhuobu = 2
        self:refreshPKZhuoBu(is_ongame)
        if call_funcBg then
            call_funcBg(12)
        end
    end)

    self.btnPkthree:addClickEventListener(function()
        AudioManager:playPressSound()
        self.pkzhuobu = 3
        self:refreshPKZhuoBu(is_ongame)
        if call_funcBg then
            call_funcBg(13)
        end
    end)
    -- 亲友圈设置
    -- 亲友圈桌子设置
    self.btnThree = self:seekNode("btnThree")
    self.btnFour  = self:seekNode("btnFour")
    self.btnFive  = self:seekNode("btnFive")
    self.stThree  = self:seekNode("stThree")
    self.stFour   = self:seekNode("stFour")
    self.stFive   = self:seekNode("stFive")

    -- 亲友圈桌子张数
    self.qyqDesk = gt.getLocalInt("qyqDesk", GameSettingDefault.CLUB_DESK_NUM)

    self:refreshqyqDesk()

    self.btnThree:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqDesk = 3
        self:refreshqyqDesk()
    end)

    self.btnFour:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqDesk = 4
        self:refreshqyqDesk()
    end)

    self.btnFive:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqDesk = 5
        self:refreshqyqDesk()
    end)

    -- 亲友圈风格
    self.BtnSimple  = self:seekNode("BtnSimple")
    self.BtnNewYear = self:seekNode("BtnNewYear")
    self.BtnClassic = self:seekNode("BtnClassic")
    self.stSimple   = self:seekNode("stSimple")
    self.stNewYear  = self:seekNode("stNewYear")
    self.stClassic  = self:seekNode("stClassic")
    self.BtnElegant = self:seekNode("BtnElegant")
    self.stElegant  = self:seekNode("stElegant")

    -- 亲友圈默认风格
    self.qyqStyle = gt.getLocalInt("qyqStyle", GameSettingDefault.CLUB_STYLE)

    self:refreshqyqStyle()

    self.BtnSimple:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqStyle = ClubHallUI.Simple
        self:refreshqyqStyle()
    end)

    self.BtnNewYear:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqStyle = ClubHallUI.NewYear
        self:refreshqyqStyle()
    end)

    self.BtnClassic:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqStyle = ClubHallUI.Classic
        self:refreshqyqStyle()
    end)

    self.BtnElegant:addClickEventListener(function()
        AudioManager:playPressSound()
        self.qyqStyle = ClubHallUI.Elegant
        self:refreshqyqStyle()
    end)

    -- 出牌速度设置
    self.btnQuick = self:seekNode("btnQuick")
    self.btnSlow  = self:seekNode("btnSlow")
    self.ziQuick  = self:seekNode("ziQuick")
    self.ziSlow   = self:seekNode("ziSlow")
    -- 出牌快
    local speed = gt.getLocal("string", "TingAutoOutCard", GameSettingDefault.MJ_TING_OUT_SPEED)
    self:initBtnSpeed(tonumber(speed))

    self.btnQuick:addClickEventListener(function()
        AudioManager:playPressSound()
        self:initBtnSpeed(0.3)
        if call_funcSpeed then
            call_funcSpeed(0.3)
        end
    end)

    self.btnSlow:addClickEventListener(function()
        AudioManager:playPressSound()
        self:initBtnSpeed(0.55)
        if call_funcSpeed then
            call_funcSpeed(0.55)
        end
    end)

    -- 禁止主界面动画设置
    self.btnOpen  = self:seekNode('btnOpen')
    self.btnClose = self:seekNode('btnClose')
    self.ziOpen   = self:seekNode('ziOpen')
    self.ziClose  = self:seekNode('ziClose')
    -- 获得是否播放主界面动画的值，并初始化
    local isMainAction = gt.getLocalBool("isMainAction", GameSettingDefault.PLAY_ANIMATION)
    self:initAction(isMainAction)

    self.btnOpen:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:initAction(true)
    end)

    self.btnClose:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:initAction(false)
    end)

    -- Gps 退出游戏
    self.btRestart  = self:seekNode("btRestart")
    self.btJiesan   = self:seekNode("btJiesan")
    self.btExitGame = self:seekNode("btExitGame")

    self.nGps      = self:seekNode("nGps")
    self.nExitGame = self:seekNode("nExitGame")

    if is_ongame then
        self.btRestart:setVisible(true)
        -- self.btJiesan:setVisible(true)
        self.nExitGame:setVisible(false)

        self.nGps:setPositionX(-280)
        self.btRestart:setPositionX(0)
        -- self.btJiesan:setPositionX(220)
    else
        self.btRestart:setVisible(true)
        self.btJiesan:setVisible(false)
        self.btExitGame:setVisible(true)
    end
    self:addBtListener("btExitGame", function()
        AudioManager:playPressSound()
        commonlib.showTipDlg("您确定要退出游戏？", function(is_ok)
            if is_ok then
                gt.setLocalString("lan_can_sel", "false")
                gt.setLocalString("mmmx1", "")
                gt.setLocalString("mmmx2", "")
                gt.setLocalString("s1s1s1", "")
                gt.setLocalString("s2s2s2", "")
                gt.flushLocal()
                RedBagController:getModel():resetLocal(false)
                AccountController:getModel():reset()
                local scene     = require("scene.LoginScene")
                local gameScene = scene.create_from_main()
                cc.Director:getInstance():replaceScene(gameScene)
            end
        end)
    end)

    self:addBtListener("btGps", function()
        AudioManager:playPressSound()
        local NativeUtil = require("common.NativeUtil")
        NativeUtil:locationSet()
    end)

    self.btRestart:addClickEventListener(function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
        GameController:unregisterEventListener()
        local scene     = require("scene.LoginScene")
        local gameScene = scene.create_for_relogin()
        cc.Director:getInstance():replaceScene(gameScene)
    end)

    self.btJiesan:addClickEventListener(function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
        gt.setLocalString("is_back_fromroom", "false", true)
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
    end)

    -- 方言设置
    self.btDialect = self:seekNode("btDialect")

    self:refreshBtDialect()

    self.btDialect:addClickEventListener(function()
        AudioManager:playPressSound()
        self:refreshBtDialect(true)
    end)

    -- 音乐音效设置
    self.soundSlider = self:seekNode("Slider_Sound")
    self.musicSlider = self:seekNode("Slider_Music")

    self.soundSlider:addClickEventListener(function()
        AudioManager:playPressSound()
        AudioManager:setSoundVolume(self.soundSlider:getPercent() / 100)
        if self.soundSlider:getPercent() == 0 then
            AudioManager:setSoundable(false)
        else
            AudioManager:setSoundable(true)
        end
    end)

    if AudioManager:getSoundable() then
        self.soundSlider:setPercent(AudioManager:getSoundVolume() * 100)
    else
        self.soundSlider:setPercent(0)
    end

    self.musicSlider:addClickEventListener(function()
        AudioManager:playPressSound()
        AudioManager:setMusicVolume(self.musicSlider:getPercent() / 100)
        if self.musicSlider:getPercent() == 0 then
            AudioManager:setMusicable(false)
        else
            AudioManager:setMusicable(true)
        end
    end)

    if AudioManager:getMusicable() then
        self.musicSlider:setPercent(AudioManager:getMusicVolume() * 100)
    else
        self.musicSlider:setPercent(0)
    end

    -- 大厅风格设置
    self.btnHuaijiu = self:seekNode("btnHuaijiu")
    self.stHuaijiu = self:seekNode("stHuaijiu")
    self.btnJingdian = self:seekNode("btnJingdian")
    self.stJingdian = self:seekNode("stJingdian")

    self:refreshHallStyle(gt.getLocalString("hall_style"))

    self.btnHuaijiu:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:refreshHallStyle("huaijiu")
    end)

    self.btnJingdian:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:refreshHallStyle("jingdian")
    end)

    -- 扑克手牌设置
    self.btnPkClassic = self:seekNode("btnClassic")
    self.stPkClassic    = self:seekNode("stPkClassic")
    self.btnRetro     = self:seekNode("btnRetro")
    self.stRetro      = self:seekNode("stRetro")
    self.pkCardType   = gt.getLocalString("cardType", "classic")
    self:refreshHandCardStyle(gt.getLocalString("cardType", "classic"))

    self.btnPkClassic:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:refreshHandCardStyle("classic")
    end)

    self.btnRetro:addClickEventListener(function ()
        AudioManager:playPressSound()
        self:refreshHandCardStyle("retro")
    end)
end

function SetDialog:refreshBtDialect(isToggle)
    local language = gt.getLocal("string", "language", "gy")
    local isOn     = language == "fy"
    if isToggle then
        isOn = not isOn
    end
    if isOn then
        self.btDialect:loadTextureNormal("ui/qj_setting/dt_setting_btn_kai.png")
        self.btDialect:loadTexturePressed("ui/qj_setting/dt_setting_btn.png")
        language = "fy"
        gt.setLocalString("language", language, true)
    else
        self.btDialect:loadTextureNormal("ui/qj_setting/dt_setting_btn.png")
        self.btDialect:loadTexturePressed("ui/qj_setting/dt_setting_btn_kai.png")
        language = "gy"
        gt.setLocalString("language", language, true)
    end
end

function SetDialog:refreshPingMian()
    if self.pingmian == 1 then -- 绿
        self.bt3D:loadTextureNormal("ui/qj_setting/table3D_nomal.png")
        self.bt2D:loadTextureNormal("ui/qj_setting/table2D_normal.png")
        self.bt2DBig:loadTextureNormal("ui/qj_setting/table2DBig_select.png")
        self.st2DUsing:setVisible(false)
        self.st2DBigUsing:setVisible(true)
        self.st3DUsing:setVisible(false)
    elseif self.pingmian == 2 then -- 黄
        self.bt3D:loadTextureNormal("ui/qj_setting/table3D_nomal.png")
        self.bt2D:loadTextureNormal("ui/qj_setting/table2D_select.png")
        self.bt2DBig:loadTextureNormal("ui/qj_setting/table2DBig_normal.png")
        self.st2DUsing:setVisible(true)
        self.st2DBigUsing:setVisible(false)
        self.st3DUsing:setVisible(false)
    elseif self.pingmian == 3 then -- 3d
        self.bt3D:loadTextureNormal("ui/qj_setting/table3D_select.png")
        self.bt2D:loadTextureNormal("ui/qj_setting/table2D_normal.png")
        self.bt2DBig:loadTextureNormal("ui/qj_setting/table2DBig_normal.png")
        self.st2DUsing:setVisible(false)
        self.st2DBigUsing:setVisible(false)
        self.st3DUsing:setVisible(true)
    end

    gt.setLocalInt("pingmian", self.pingmian, true)
end

function SetDialog:refreshZhuoBu()
    if self.zhuobu == 1 then
        self.btnGreen:loadTextureNormal("ui/qj_setting/mj3_select.png")
        self.btnBlue:loadTextureNormal("ui/qj_setting/mj1_normal.png")
        self.btnMjthree:loadTextureNormal("ui/qj_setting/mj2_normal.png")
        self.btnMjfour:loadTextureNormal("ui/qj_setting/mj4_normal.png")
        self.btnMjfive:loadTextureNormal("ui/qj_setting/mj5-normal.png")
        self.stGreen:setVisible(true)
        self.stBlue:setVisible(false)
        self.stMjthree:setVisible(false)
        self.stMjfour:setVisible(false)
        self.stMjfive:setVisible(false)
    elseif self.zhuobu == 2 then
        self.btnGreen:loadTextureNormal("ui/qj_setting/mj3_normal.png")
        self.btnBlue:loadTextureNormal("ui/qj_setting/mj1_select.png")
        self.btnMjthree:loadTextureNormal("ui/qj_setting/mj2_normal.png")
        self.btnMjfour:loadTextureNormal("ui/qj_setting/mj4_normal.png")
        self.btnMjfive:loadTextureNormal("ui/qj_setting/mj5-normal.png")
        self.stGreen:setVisible(false)
        self.stBlue:setVisible(true)
        self.stMjthree:setVisible(false)
        self.stMjfour:setVisible(false)
        self.stMjfive:setVisible(false)
    elseif self.zhuobu == 3 then
        self.btnGreen:loadTextureNormal("ui/qj_setting/mj3_normal.png")
        self.btnBlue:loadTextureNormal("ui/qj_setting/mj1_normal.png")
        self.btnMjthree:loadTextureNormal("ui/qj_setting/mj2_select.png")
        self.btnMjfour:loadTextureNormal("ui/qj_setting/mj4_normal.png")
        self.btnMjfive:loadTextureNormal("ui/qj_setting/mj5-normal.png")
        self.stGreen:setVisible(false)
        self.stBlue:setVisible(false)
        self.stMjthree:setVisible(true)
        self.stMjfour:setVisible(false)
        self.stMjfive:setVisible(false)
    elseif self.zhuobu == 4 then
        self.btnGreen:loadTextureNormal("ui/qj_setting/mj3_normal.png")
        self.btnBlue:loadTextureNormal("ui/qj_setting/mj1_normal.png")
        self.btnMjthree:loadTextureNormal("ui/qj_setting/mj2_normal.png")
        self.btnMjfour:loadTextureNormal("ui/qj_setting/mj4_select.png")
        self.btnMjfive:loadTextureNormal("ui/qj_setting/mj5-normal.png")
        self.stGreen:setVisible(false)
        self.stBlue:setVisible(false)
        self.stMjthree:setVisible(false)
        self.stMjfour:setVisible(true)
        self.stMjfive:setVisible(false)
    elseif self.zhuobu == 5 then
        self.btnGreen:loadTextureNormal("ui/qj_setting/mj3_normal.png")
        self.btnBlue:loadTextureNormal("ui/qj_setting/mj1_normal.png")
        self.btnMjthree:loadTextureNormal("ui/qj_setting/mj2_normal.png")
        self.btnMjfour:loadTextureNormal("ui/qj_setting/mj4_normal.png")
        self.btnMjfive:loadTextureNormal("ui/qj_setting/mj5_select.png")
        self.stGreen:setVisible(false)
        self.stBlue:setVisible(false)
        self.stMjthree:setVisible(false)
        self.stMjfour:setVisible(false)
        self.stMjfive:setVisible(true)
    end

    gt.setLocalInt("zhuobu", self.zhuobu, true)
end

function SetDialog:refreshPKZhuoBu(is_ongame)
    local num = 1
    if is_ongame == "zgz" then
        num = 4
        self.btnPkone:loadTexturePressed("ui/qj_setting/pk4_select.png")
    end

    if self.pkzhuobu == 1 then
        self.btnPkone:loadTextureNormal("ui/qj_setting/pk" .. num .. "_select.png")
        self.btnPktwo:loadTextureNormal("ui/qj_setting/pk3_normal.png")
        self.btnPkthree:loadTextureNormal("ui/qj_setting/pk2_normal.png")

        self.stPkone:setVisible(true)
        self.stPktwo:setVisible(false)
        self.stPkthree:setVisible(false)
    elseif self.pkzhuobu == 2 then
        self.btnPkone:loadTextureNormal("ui/qj_setting/pk" .. num .. "_normal.png")
        self.btnPktwo:loadTextureNormal("ui/qj_setting/pk3_select.png")
        self.btnPkthree:loadTextureNormal("ui/qj_setting/pk2_normal.png")

        self.stPkone:setVisible(false)
        self.stPktwo:setVisible(true)
        self.stPkthree:setVisible(false)
    elseif self.pkzhuobu == 3 then
        self.btnPkone:loadTextureNormal("ui/qj_setting/pk" .. num .. "_normal.png")
        self.btnPktwo:loadTextureNormal("ui/qj_setting/pk3_normal.png")
        self.btnPkthree:loadTextureNormal("ui/qj_setting/pk2_select.png")

        self.stPkone:setVisible(false)
        self.stPktwo:setVisible(false)
        self.stPkthree:setVisible(true)
    end

    gt.setLocalInt("pkzhuobu", self.pkzhuobu, true)
end

function SetDialog:refreshqyqDesk()
    if self.qyqDesk == 3 then
        self.btnThree:loadTextureNormal("ui/qj_setting/btnThree_select.png")
        self.btnFour:loadTextureNormal("ui/qj_setting/btnFour_normal.png")
        self.btnFive:loadTextureNormal("ui/qj_setting/btnFive_normal.png")
        self.stThree:setVisible(true)
        self.stFour:setVisible(false)
        self.stFive:setVisible(false)
    elseif self.qyqDesk == 4 then
        self.btnThree:loadTextureNormal("ui/qj_setting/btnThree_normal.png")
        self.btnFour:loadTextureNormal("ui/qj_setting/btnFour_select.png")
        self.btnFive:loadTextureNormal("ui/qj_setting/btnFive_normal.png")
        self.stThree:setVisible(false)
        self.stFour:setVisible(true)
        self.stFive:setVisible(false)
    elseif self.qyqDesk == 5 then
        self.btnThree:loadTextureNormal("ui/qj_setting/btnThree_normal.png")
        self.btnFour:loadTextureNormal("ui/qj_setting/btnFour_normal.png")
        self.btnFive:loadTextureNormal("ui/qj_setting/btnFive_select.png")
        self.stThree:setVisible(false)
        self.stFour:setVisible(false)
        self.stFive:setVisible(true)
    end

    gt.setLocalInt("qyqDesk", self.qyqDesk, true)
end

function SetDialog:refreshqyqStyle()
    if self.qyqStyle == ClubHallUI.NewYear then
        self.BtnSimple:loadTextureNormal("ui/qj_setting/btn_simple_normal.png")
        self.BtnNewYear:loadTextureNormal("ui/qj_setting/btn_new_year_select.png")
        self.BtnClassic:loadTextureNormal("ui/qj_setting/btn_classic_normal.png")
        self.BtnElegant:loadTextureNormal("ui/qj_setting/btn_elegant_normal.png")
        self.stSimple:setVisible(false)
        self.stNewYear:setVisible(true)
        self.stClassic:setVisible(false)
        self.stElegant:setVisible(false)
    elseif self.qyqStyle == ClubHallUI.Simple then
        self.BtnSimple:loadTextureNormal("ui/qj_setting/btn_simple_normal_press.png")
        self.BtnNewYear:loadTextureNormal("ui/qj_setting/btn_new_year_normal.png")
        self.BtnClassic:loadTextureNormal("ui/qj_setting/btn_classic_normal.png")
        self.BtnElegant:loadTextureNormal("ui/qj_setting/btn_elegant_normal.png")
        self.stSimple:setVisible(true)
        self.stNewYear:setVisible(false)
        self.stClassic:setVisible(false)
        self.stElegant:setVisible(false)
    elseif self.qyqStyle == ClubHallUI.Classic then
        self.BtnSimple:loadTextureNormal("ui/qj_setting/btn_simple_normal.png")
        self.BtnNewYear:loadTextureNormal("ui/qj_setting/btn_new_year_normal.png")
        self.BtnClassic:loadTextureNormal("ui/qj_setting/btn_classic_press.png")
        self.BtnElegant:loadTextureNormal("ui/qj_setting/btn_elegant_normal.png")
        self.stSimple:setVisible(false)
        self.stNewYear:setVisible(false)
        self.stClassic:setVisible(true)
        self.stElegant:setVisible(false)
    elseif self.qyqStyle == ClubHallUI.Elegant then
        self.BtnSimple:loadTextureNormal("ui/qj_setting/btn_simple_normal.png")
        self.BtnNewYear:loadTextureNormal("ui/qj_setting/btn_new_year_normal.png")
        self.BtnClassic:loadTextureNormal("ui/qj_setting/btn_classic_normal.png")
        self.BtnElegant:loadTextureNormal("ui/qj_setting/btn_elegant_press.png")
        self.stSimple:setVisible(false)
        self.stNewYear:setVisible(false)
        self.stClassic:setVisible(false)
        self.stElegant:setVisible(true)
    end

    ClubHallUI.setClubStyle(self.qyqStyle)

    gt.setLocalInt("qyqStyle", self.qyqStyle, true)
end

function SetDialog:initBtnSpeed(speed)
    if speed == 0.3 then
        self.btnQuick:loadTextureNormal("ui/qj_setting/speedBtn_select.png")
        self.btnQuick:loadTexturePressed("ui/qj_setting/speedBtn_normal.png")
        self.btnSlow:loadTextureNormal("ui/qj_setting/speedBtn_normal.png")
        self.btnSlow:loadTexturePressed("ui/qj_setting/speedBtn_select.png")
        self.ziQuick:loadTexture("ui/qj_setting/quick_select.png")
        self.ziSlow:loadTexture("ui/qj_setting/slow_normal.png")
        gt.setLocalString("TingAutoOutCard", "0.3", true)
    else
        self.btnQuick:loadTextureNormal("ui/qj_setting/speedBtn_normal.png")
        self.btnQuick:loadTexturePressed("ui/qj_setting/speedBtn_select.png")
        self.btnSlow:loadTextureNormal("ui/qj_setting/speedBtn_select.png")
        self.btnSlow:loadTexturePressed("ui/qj_setting/speedBtn_normal.png")
        self.ziQuick:loadTexture("ui/qj_setting/quick_normal.png")
        self.ziSlow:loadTexture("ui/qj_setting/slow_select.png")
        gt.setLocalString("TingAutoOutCard", "0.55", true)
    end
end

function SetDialog:initAction(is_open)
    if is_open then
        -- 改变其点中时的样子
        self.btnOpen:loadTextureNormal("ui/qj_setting/speedBtn_select.png")
        self.btnOpen:loadTexturePressed("ui/qj_setting/speedBtn_normal.png")
        self.btnClose:loadTextureNormal("ui/qj_setting/speedBtn_normal.png")
        self.btnClose:loadTexturePressed("ui/qj_setting/speedBtn_select.png")
        self.ziOpen:loadTexture("ui/qj_setting/open-select.png")
        self.ziClose:loadTexture("ui/qj_setting/close-normal.png")
        -- 设置本地的bool值
        gt.setLocalBool("isMainAction", true, true)
        if self:getParent() and self:getParent().isPlayMainAction then
            -- 调用父类（MainScene）中播放主界面动画函数
            self:getParent():isPlayMainAction(true)
        end
    else
        self.btnOpen:loadTextureNormal("ui/qj_setting/speedBtn_normal.png")
        self.btnOpen:loadTexturePressed("ui/qj_setting/speedBtn_select.png")
        self.btnClose:loadTextureNormal("ui/qj_setting/speedBtn_select.png")
        self.btnClose:loadTexturePressed("ui/qj_setting/speedBtn_normal.png")
        self.ziOpen:loadTexture("ui/qj_setting/open-normal.png")
        self.ziClose:loadTexture("ui/qj_setting/close-select.png")
        gt.setLocalBool("isMainAction", false, true)
        if self:getParent() and self:getParent().isPlayMainAction then
            -- 调用父类（MainScene）中播放主界面动画函数
            self:getParent():isPlayMainAction(false)
        end
    end
end

-- 设置大厅风格
function SetDialog:refreshHallStyle(styletype)
    gt.setLocalString("hall_style", styletype, true)
    if styletype == "huaijiu" then
        self.stHuaijiu:setVisible(true)
        self.stJingdian:setVisible(false)
        self.btnHuaijiu:loadTextureNormal("ui/qj_setting/huaijiu1.png")
        self.btnJingdian:loadTextureNormal("ui/qj_setting/jingdian0.png")
    else
        self.stHuaijiu:setVisible(false)
        self.stJingdian:setVisible(true)
        self.btnHuaijiu:loadTextureNormal("ui/qj_setting/huaijiu0.png")
        self.btnJingdian:loadTextureNormal("ui/qj_setting/jingdian1.png")
    end
    if self:getParent() and self:getParent().updateHallStyle then
        -- 调用父类（MainScene）中
        self:getParent():updateHallStyle()
    end
end

-- 设置扑克手牌风格
function SetDialog:refreshHandCardStyle(styletype)
    gt.setLocalString("cardType", styletype, true)
    if styletype == "retro" then
        self.stPkClassic:setVisible(false)
        self.stRetro:setVisible(true)
        self.btnPkClassic:loadTextureNormal("ui/qj_setting/pkclassic_normal.png")
        self.btnRetro:loadTextureNormal("ui/qj_setting/retro_choose.png")
    else
        self.stPkClassic:setVisible(true)
        self.stRetro:setVisible(false)
        self.btnPkClassic:loadTextureNormal("ui/qj_setting/pkclassic_choose.png")
        self.btnRetro:loadTextureNormal("ui/qj_setting/retro_normal.png")
    end
end
return SetDialog