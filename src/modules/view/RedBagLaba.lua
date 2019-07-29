local RedBagLaba = class("RedBagLaba",function(args)
    return cc.Node:create()
end)

local function Font_fnt(args)
    local font_name = nil
    if args.layer then
        font_name = display.newBMFontLabel({
            text = args.text,
            font = args.font,
        })
        font_name:setAnchorPoint(args.acp)
        args.layer:addChild(font_name)
        font_name:setPosition(args.pst)
    end
    return font_name
end

function RedBagLaba:ctor(_scene)
    self._scene = _scene
    self.aniRefCount = 0
    self:enableNodeEvents()
end

function RedBagLaba:onEnter()
    local node = tolua.cast(cc.CSLoader:createNode("ui/ui_redbagLaba.csb"),"ccui.Widget")
    self:addChild(node)
    node:setPosition(cc.p(0,g_visible_size.height*0.87))
    self.node = node

    self:onUpdate(function(dt)
        self:update(dt)
    end)
    self.node:setVisible(false)
end

function RedBagLaba:update(dt)
    if self.aniRefCount <= 0 then
        local data = RedBagController:getModel():pop()
        if not data then return end
        dump(data,"data")
        self:playRedBag(data)
        local room_id = RoomController:getModel():getRoomId()
        -- print("roomNum=======",room_id)
        if data.roomNum == room_id then
            if data.type == 1 then
                self:playCaiShen(data)
            elseif data.type == 2 then
                self:playRain(data)
            end
        end
    end
end

--播放大喇叭
function RedBagLaba:playRedBag(data)
    local Panel_msg = ccui.Helper:seekWidgetByName(self.node,"Panel_msg")
    local RichLabel = require("modules.view.RichLabel")
    self.node:setVisible(true)
    local spriteHbGg = display.newNode()
    Panel_msg:addChild(spriteHbGg)
    spriteHbGg:setPosition(cc.p(0,0))
    local Hb_type = "巧遇财神到"
    local label ={}
    for i=1,#data.reds do
        local amountRmb = data.reds[i].amount/100
        if data.type == 1 then
            Hb_type = "巧遇财神到"
        elseif data.type == 2 then
            Hb_type = "遭遇红包雨"
        end
        local nameCut = data.reds[i].name

        if pcall(commonlib.GetMaxLenString, nameCut, 6) then
            nameCut = commonlib.GetMaxLenString(nameCut, 6)
        end

        label[i] = RichLabel:create({
            fontName = "ui/zhunyuan.ttf",
            fontSize = 25,
            fontColor = cc.c3b(255, 0, 0),
            dimensions = cc.size(800, 200),
            text = "[fontColor=ffffff fontSize=25]玩家[/fontColor]".."[fontColor=ff5047 fontSize=25]"..nameCut.."[/fontColor]".."[fontColor=ffffff fontSize=25]"..Hb_type.."[/fontColor]"..
            "[fontColor=ffffff fontSize=25],获得￥[/fontColor]".."[fontColor=ff5047 fontSize=25]"..amountRmb.."[/fontColor]".."[fontColor=ffffff fontSize=25]元红包[/fontColor]",
        })
        spriteHbGg:addChild(label[i])
        label[i]:setAnchorPoint(cc.p(0,0.5))
        label[i]:setPosition(cc.p(90, 7-50*(i -1)))
    end

    local motion = transition.sequence({
        cc.MoveBy:create(1.5,cc.p(0,25)),
        cc.DelayTime:create(1.0),
        cc.MoveBy:create(1.0,cc.p(0,25)),
    })

    local motion1 = cc.Repeat:create(motion,#data.reds)
    spriteHbGg:runAction(
        transition.sequence({
            motion1,
            cc.CallFunc:create(function()
                self.aniRefCount = self.aniRefCount-1
                self.node:setVisible(false)
                spriteHbGg:removeSelf()
            end)
        })
    )
    self.aniRefCount = self.aniRefCount + 1
end

--播放红包雨
function RedBagLaba:playRain(data)
    local particle_1 = cc.ParticleSystemQuad:create("ani/hongbao/hongbaoyulz.plist")
    self:addChild(particle_1)
    particle_1:setPosition(cc.p(g_visible_size.width*0.5, g_visible_size.height *1.1))
    local _args = {
        layer = self,
        path = "hongbao",
        effname = "hongbao",
        pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),
        callback = function()
            local player_s = {}
            local redbags = {}
            for i,v in ipairs(data.reds) do
                local index = RoomController:getModel():getIndexById(v.userId)
                local weizhi = self._scene:indexTrans(index)
                local player_ui = self._scene.player_ui[weizhi]
                local size = player_ui:getContentSize()
                local endPst = cc.p(player_ui:getPosition())

                local args_delay = {
                    layer = self,
                    path = "hongbao",
                    effname = "hongbaodao1",
                    pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),
                    callback = function()
                        local args_s = {
                            layer = self,
                            path = "hongbao",
                            effname = "hongbaodao2",
                            pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),    --起始位置
                            time = 0.3,                      --移动的时间
                            pstend = cc.p(endPst.x,endPst.y),
                            callback = function()
                                local _pos = cc.p(endPst.x,endPst.y)
                                player_s[i] = display.newSprite("ui/qj_redbag/redbagsLog.png")
                                self:addChild(player_s[i])
                                player_s[i]:setPosition(_pos)
                                local act = {
                                    layer = player_s[i],
                                    text = " ￥ "..string.format("%.2f",v.amount/100),
                                    font = "ui/qj_redbag/redbag_money.fnt",
                                    acp = cc.p(0.5,0.5),
                                    pst = cc.p(size.width*0.5,size.height*0.5)
                                }
                                redbags[i] = Font_fnt(act)
                                player_s[i]:runAction(
                                    transition.sequence({
                                        cc.DelayTime:create(2),
                                        cc.Spawn:create(
                                            cc.MoveBy:create(2, cc.p(0,60)),
                                            cc.FadeOut:create(2)
                                            ),
                                        cc.CallFunc:create(function()
                                            for k,v in ipairs(redbags) do
                                                if player_s[k] then
                                                    player_s[k]:removeSelf()
                                                    player_s[k] = nil
                                                end
                                            end
                                            player_s = {}
                                            redbags = {}
                                            if particle_1 then
                                                particle_1:removeSelf()
                                                particle_1 = nil
                                            end
                                            if i == 1 then
                                                self.aniRefCount = self.aniRefCount - 1
                                            end
                                        end)
                                    })
                                )
                            end
                        }
                        AudioManager:playDWCSound("sound/hongbaolaile.mp3")
                        self:ShowEff(args_s)
                    end
                }
                self:ShowEff(args_delay)
            end
        end,
    }
    AudioManager:playDWCSound("sound/hongbaoyu.mp3")
    self:ShowEff(_args)
    self.aniRefCount = self.aniRefCount + 1
end

--播放财神到
function RedBagLaba:playCaiShen(data)
    local index = RoomController:getModel():getIndexById(data.reds[1].userId)
    local weizhi = self._scene:indexTrans(index)
    local player_ui = self._scene.player_ui[weizhi]
    local size = player_ui:getContentSize()
    local endPst = cc.p(player_ui:getPosition())
    local _args = {
        layer = self,
        path = "gongxifacai",
        effname = "caisheng",
        pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),
        callback = function()
            local args_delay = {
                layer = self,
                path = "gongxifacai",
                effname = "touxiang1",
                pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),
                callback = function()
                    player_s = {}
                    redbags = {}
                    local i=1
                    local args_s = {
                        layer = self,
                        path = "gongxifacai",
                        effname = "touxiang2",
                        pst = cc.p(g_visible_size.width*0.5,g_visible_size.height*0.5),    --起始位置
                        time = 0.3,                      --移动的时间
                        pstend = cc.p(endPst.x,endPst.y),
                        callback = function()
                            local _pos = cc.p(endPst.x,endPst.y)  -- +size.height
                            player_s[i] = display.newSprite("ui/qj_redbag/redbagsLog.png")
                            self:addChild(player_s[i])
                            player_s[i]:setPosition(_pos)
                            local act = {
                                layer = player_s[i],
                                text = " ￥ "..string.format("%.2f",data.reds[1].amount/100),
                                font = "ui/qj_redbag/redbag_money.fnt",
                                acp = cc.p(0.5,0.5),
                                pst = cc.p(size.width*0.4,size.height*0.7)
                            }
                            redbags[i] = Font_fnt(act)
                            player_s[i]:runAction(
                                transition.sequence({
                                    cc.DelayTime:create(2),
                                    cc.Spawn:create(
                                        cc.MoveBy:create(2, cc.p(0,60)),
                                        cc.FadeOut:create(2)
                                        ),
                                    cc.CallFunc:create(function()
                                        for k,v in ipairs(redbags) do
                                            if player_s[k] then
                                                player_s[k]:removeSelf()
                                                player_s[k] = nil
                                            end
                                        end
                                        player_s = {}
                                        redbags = {}
                                        if i == 1 then
                                            self.aniRefCount = self.aniRefCount - 1
                                        end
                                    end)
                                })
                            )
                        end
                    }
                    AudioManager:playDWCSound("sound/hongbaolaile.mp3")
                    self:ShowEff(args_s)
                end,
            }
            self:ShowEff(args_delay)
        end,
    }
    AudioManager:playDWCSound("sound/caishendao.mp3")
    self:ShowEff(_args)
    self.aniRefCount = self.aniRefCount + 1
end

function RedBagLaba:ShowEff(args)
    if args.layer then
        local node = display.newNode()
        args.layer:addChild(node,999)
        node:setPosition(args.pst)
        local manager = ccs.ArmatureDataManager:getInstance()
        local path = string.format("ani/%s/%s.ExportJson",args.path,args.path)
        manager:addArmatureFileInfo(path)
        local armature = ccs.Armature:create(args.path)
        local function animationEvent(armatureBack,movementType,movementID)
            -- ccs.MovementEventType = {
            --     start = 0,
            --     complete = 1,
            --     loopComplete = 2,
            -- }
            if movementType == 2 then
                if args.callback then
                    args.callback(armature)
                end
                armature:removeSelf()
            end
        end
        armature:getAnimation():setMovementEventCallFunc(animationEvent)
        node:addChild(armature,999)
        armature:getAnimation():play(args.effname)
        if args.time and args.pstend then
            local action = transition.sequence({
                cc.MoveTo:create(args.time,args.pstend),       --飞到玩家位置
            })
            node:runAction(action)
        end
        return armature
    end
end

function RedBagLaba:onExit()

end

return RedBagLaba