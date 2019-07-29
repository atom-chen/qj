
local MJClickAction = {}

local atr = 1/180 * math.pi
local atrRight = 30 * atr
local artLeft = (180-atrRight) * atr

function getAngleByPos(p1,p2)
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y

    local atr = math.atan2(p.y,p.x)
    return atr
    -- print()
    -- local r = math.atan2(p.y,p.x)*180/math.pi
    -- print('弧度:' .. atr, "夹角[-180~180]:".. r)
    -- return r
end

function MJClickAction.MoveChangeCard(node,xx,yy,preX,preY,sel_init_posx)

    preX = preX or xx
    preY = preY or yy

    local height = node.hand_card_list[1][node.my_sel_index]:getContentSize().height
    if yy > height then
        return sel_init_posx,preX,preY
    end

    local pos1 = cc.p(preX,preY)
    local pos2 = cc.p(xx,yy)
    local atr = getAngleByPos(pos1,pos2)
    if atr > atrRight and atr < artLeft then
        return sel_init_posx,preX,preY
    end

    local pos = cc.p(xx, yy)
    for i, v in ipairs(node.hand_card_list[1]) do
        local go_next = false
        if node.tdh_need_bTing then
            local card_id = v.card_id
            if not node.ting_list[card_id] or 0 == #node.ting_list[card_id] then
                go_next = true
            end
        end
        if v.sort == 0 and not go_next then
            local p = v:convertToNodeSpace(pos)
            local s = v:getContentSize()

            local rect = cc.rect(0, 0, s.width, s.height)

            if cc.rectContainsPoint(rect, p) then
                if node.mjTypeWanFa == "fnmj" and v.card_id == node.wang_cards[1] then
                    return
                end
                if node.my_sel_index and node.my_sel_index ~= i then

                    AudioManager:playDWCSound("sound/mj/card_click_effect.mp3")

                    ---------------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setPosition(cc.p(sel_init_posx, node.hand_card_pos_list[1].init_pos.y))
                    ---------------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x)
                    node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y)
                    ---------------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1)

                    node.my_sel_index = i

                    node.my_sel_index_sceond = nil

                    node.selected_card_index = i
                    node.selected_card_posx = node.hand_card_list[1][i]:getPositionX()
                    node.selected_card_posy = node.hand_card_pos_list[1].init_pos.y

                    preX = xx
                    preY = yy
                    sel_init_posx =  node.hand_card_list[1][node.my_sel_index]:getPositionX()

                    node:placeHandCard(1)
                    ---------------------------------------------------------
                    --node.hand_card_list[1][node.my_sel_index]:setPosition(cc.p(sel_init_posx, node.hand_card_pos_list[1].init_pos.y+20))
                    ---------------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x*node.card_scale)
                    node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y*node.card_scale)
                    ---------------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1+14)

                    node:checkTingTip(node.hand_card_list[1][i].card_id)
                end
            end
        end
    end
    return sel_init_posx,preX,preY
end

function MJClickAction.isCollsion(x1, y1, x2, y2, w, h)
    if (x1 >= x2 and x1 <= x2 + w and y1 >= y2 and y1 <= y2 + h) then
        return true
    end
    return false
end

function MJClickAction.MoveCard(node,xx,yy,preX,preY,sel_init_posx,has_move)
    -- local starttime = os.clock()
    if node.my_sel_index then
        -- local width = node.hand_card_list[1][node.my_sel_index]:getContentSize().width
        -- local height = node.hand_card_list[1][node.my_sel_index]:getContentSize().height
        -- for i, v in ipairs(node.hand_card_list[1]) do
        --     if node.my_sel_index ~= i then
        --         local anchorPos  = node.hand_card_list[1][node.my_sel_index]:getAnchorPoint()
        --         local x1 = node.hand_card_list[1][node.my_sel_index]:getPositionX() - width*anchorPos.x
        --         local y1 = node.hand_card_list[1][node.my_sel_index]:getPositionY() - height*anchorPos.y

        --         local anchorPos  = node.hand_card_list[1][i]:getAnchorPoint()
        --         local x2 = node.hand_card_list[1][i]:getPositionX() - width*anchorPos.x
        --         local y2 = node.hand_card_list[1][i]:getPositionY() - height*anchorPos.y
        --         if MJClickAction.isCollsion(x1,y1,x2,y2,width,height) then
        --             print('不能出牌!!!!!!!!!!!!!! ' .. node.my_sel_index .. '_' .. i)
        --             return
        --         end
        --     end
        -- end

        local height = node.hand_card_list[1][node.my_sel_index]:getContentSize().height
        local spY = node.hand_card_pos_list[1].init_pos.y -- +20
        local anchorPos  = node.hand_card_list[1][node.my_sel_index]:getAnchorPoint()
        local posY = spY + height*anchorPos.y
        if posY > yy then
            node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x*node.card_scale)
            node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y*node.card_scale)

            ---------------------------------------------------
            -- node.hand_card_list[1][node.my_sel_index]:setPosition(cc.p(sel_init_posx,spY))
            ---------------------------------------------------
            node:placeHandCard(1)
            ---------------------------------------------------

            preX = xx
            preY = yy
            return preX,preY,has_move
        end
        node.hand_card_list[1][node.my_sel_index]:setPosition(cc.p(xx,yy))
        has_move = true
        -- preX = xx
        -- preY = yy
    end
    preX = xx
    preY = yy
    -- local endtime = os.clock()
    -- print(string.format("@@@@@@@@@  MJClickAction.MoveCard cost time  : %.4f", endtime - starttime))
    return preX,preY,has_move
end

function MJClickAction.Move(node,xx,yy,preX,preY,sel_init_posx,has_move)

    if node.cancleSelectCardStatus then
        return
    end
    if not node.my_sel_index then
        return
    end
    -- local starttime = os.clock()
    sel_init_posx,preX,preY = MJClickAction.MoveChangeCard(node,xx,yy,preX,preY,sel_init_posx)
    preX,preY,has_move = MJClickAction.MoveCard(node,xx,yy,preX,preY,sel_init_posx,has_move)

    -- local endtime = os.clock()
    -- print(string.format("@@@@@@@@@  MJClickAction.Move cost time  : %.4f", endtime - starttime))

    return sel_init_posx,preX,preY,has_move
end

function MJClickAction.Began(node,xx,yy,preX,preY,sel_init_posx,has_move)
    if node.cancleSelectCardStatus then
        return
    end
    preX = xx
    preY = yy
    has_move = nil
    local pos = cc.p(xx, yy)
    for i, v in ipairs(node.hand_card_list[1]) do
        if v.sort == 0 then
            local p = v:convertToNodeSpace(pos)
            local s = v:getContentSize()

            node.card_scale_init_x = node.card_scale_init_x or v:getScaleX()
            node.card_scale_init_y = node.card_scale_init_y or v:getScaleY()

            local rect = cc.rect(0, 0, s.width, s.height)
            if cc.rectContainsPoint(rect, p) then
                if node.tdh_need_bTing then
                    local card_id = v.card_id
                    if not node.ting_list[card_id] or 0 == #node.ting_list[card_id] then
                        return false,sel_init_posx,preX,preY,has_move
                    end
                end

                if node.my_sel_index == i then
                    node.my_sel_index_sceond = i
                    return true,sel_init_posx,preX,preY,has_move
                    -- if self.MJClickAction.doubleClickSchedule() then
                    --     return true
                    -- end
                    -- self.my_sel_index = nil
                    -- if self.bbh_data or self.bbh_wait or (self.ting_status and i ~= #self.hand_card_list[1]) then
                    --     self.hand_card_list[1][i]:setPositionY(self.hand_card_pos_list[1].init_pos.y)
                    --     self.hand_card_list[1][i]:setLocalZOrder(self.ZOrder.HAND_CARD_ZORDER_1)
                    -- else

                    --     self.selected_card_index = i
                    --     self.selected_card_posx = self.hand_card_list[1][i]:getPositionX()
                    --     self.selected_card_posy = self.hand_card_pos_list[1].init_pos.y

                    --     log('self.selected_card_index ' .. self.selected_card_index)
                    --     log('self.selected_card_posx ' .. self.selected_card_posx)
                    --     log('self.selected_card_posy ' .. self.selected_card_posy)

                    --     local card = self.hand_card_list[1][i]
                    --     if card then
                    --         if self.show_pai then
                    --             self.show_pai:removeFromParent(true)
                    --             self.show_pai = nil
                    --         end
                    --         self.show_pai = self:getCardById(1, card.card_id)
                    --         self.show_pai:setPosition(cc.p(card:getPosition()))

                    --         self.node:addChild(self.show_pai, self.ZOrder.HAND_CARD_ZORDER_1+14)
                    --         self.show_pai.card = card
                    --         self.show_pai.card:setVisible(false)

                    --         local card_id = card.card_id
                    --         if self.tdh_need_bTing and self.ting_list[card.card_id] and 0 ~= #self.ting_list[card.card_id] then
                    --             self:sendOperate(nil,self.TING_OPERATOR,card_id)
                    --         else
                    --             self:sendOutCards(card_id)
                    --         end

                    --      if self.hasHu or self.hasGang then
                    --             return
                    --         end

                    --         self:setImgGuoHuIndexVisible(1, false)

                    --         self.can_opt = nil
                    --         self.tdh_need_bTing = false

                    --         self:removeCardShadow()
                    --     end
                    -- end
                    -- self:checkTingTip()
                    -- return
                else
                    local card = node.hand_card_list[1][i]
                    if node.mjTypeWanFa == "fnmj" then
                        if card and (card.card_id == node.wang_cards[1] or card.card_id == node.wang_cards[2]) then
                            return
                        end
                    end

                    if node.my_sel_index then
                        ---------------------------------------------------
                        -- self.hand_card_list[1][self.my_sel_index]:setPositionY(self.hand_card_pos_list[1].init_pos.y)
                        ---------------------------------------------------
                        node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x)
                        node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y)
                        ---------------------------------------------------

                        node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1)
                    end
                    node.my_sel_index = i
                    ---------------------------------------------------
                    -- self.hand_card_list[1][self.my_sel_index]:setPositionY(self.hand_card_pos_list[1].init_pos.y+20)
                    ---------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x*node.card_scale)
                    node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y*node.card_scale)
                    ---------------------------------------------------

                    node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1+14)

                    node:placeHandCard(1)

                    sel_init_posx =  node.hand_card_list[1][node.my_sel_index]:getPositionX()

                    node.selected_card_index = i
                    node.selected_card_posx = node.hand_card_list[1][node.selected_card_index]:getPositionX()
                    node.selected_card_posy = node.hand_card_pos_list[1].init_pos.y

                    -- log('self.selected_card_index ' .. self.selected_card_index)
                    -- log('self.selected_card_posx ' .. self.selected_card_posx)
                    -- log('self.selected_card_posy ' .. self.selected_card_posy)

                    node:checkTingTip(node.hand_card_list[1][i].card_id)
                    return true,sel_init_posx,preX,preY,has_move
                end
                break
            end
        end
    end
    return false,sel_init_posx,preX,preY,has_move
end

function MJClickAction.End(node,xx,yy,preX,preY,sel_init_posx,has_move,callFunc,outCardAppedMsgFun)

    if node.cancleSelectCardStatus then
        return
    end
    if not node.my_sel_index then
        return
    end
    local times = 1
    while 1 do
        -- log('点击结束循环',times)
        times = times + 1
        if node.my_sel_index and (has_move or node.my_sel_index_sceond) then
            if not node.my_sel_index_sceond and
                node.hand_card_list[1][node.my_sel_index]:getPositionY() < node.hand_card_pos_list[1].init_pos.y+node.single_card_size.height*0.3 then
                ---------------------------------------------------
                -- self.hand_card_list[1][self.my_sel_index]:setPosition(cc.p(sel_init_posx, self.hand_card_pos_list[1].init_pos.y+20))
                ---------------------------------------------------
                ---------------------------------------------------
                node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x*node.card_scale)
                node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y*node.card_scale)
                node:placeHandCard(1)
                ---------------------------------------------------

                node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1+14)
            else
                if node.bbh_data or node.bbh_wait or (node.ting_status and node.my_sel_index ~= #node.hand_card_list[1]) then
                    ---------------
                    -- self.hand_card_list[1][self.my_sel_index]:setPosition(cc.p(sel_init_posx, self.hand_card_pos_list[1].init_pos.y))
                    ---------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setScaleX(node.card_scale_init_x*node.card_scale)
                    node.hand_card_list[1][node.my_sel_index]:setScaleY(node.card_scale_init_y*node.card_scale)
                    node:placeHandCard(1)
                    ---------------------------------------------------
                    node.hand_card_list[1][node.my_sel_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1+14)
                else
                    local card = node.hand_card_list[1][node.my_sel_index]
                    if card then
                        if node.show_pai then
                            node.show_pai:removeFromParent(true)
                            node.show_pai = nil
                        end
                        node.show_pai = node:getCardById(1, card.card_id)
                        node.show_pai:setPosition(cc.p(card:getPosition()))

                        node.node:addChild(node.show_pai, node.ZOrder.HAND_CARD_ZORDER_1+14)

                        node.show_pai:setScaleX(card:getScaleX())
                        node.show_pai:setScaleY(card:getScaleY())

                        node.show_pai.card = card
                        node.show_pai.card:setVisible(false)

                        local card_id = card.card_id
                        if node.tdh_need_bTing and node.ting_list[card.card_id] and 0 ~= #node.ting_list[card.card_id] then
                            if outCardAppedMsgFun then
                                outCardAppedMsgFun(card)
                            end
                            if node.mjTypeWanFa == 'fnmj' then
                                node:sendOperate(nil, 23, card_id)
                            else
                                node:sendOperate(nil, node.TING_OPERATOR, card_id)
                            end
                        else
                            node:sendOutCards(card_id)
                        end

                        local bBreak = false
                        if callFunc then
                            -- log('AAAAAAAAAAAAAAAA')
                            if callFunc() then
                                --log('AAAAAAAAAAAAAAAAAAAAA')
                                -- node.my_sel_index = nil
                                has_move = nil
                                node.my_sel_index_sceond = nil
                                node:placeHandCard(1)
                                return has_move
                            end
                        end

                        node:setImgGuoHuIndexVisible(1, false)

                        node.tdh_need_bTing = false

                        node:removeCardShadow()

                        node.my_sel_index = nil

                        -- log('11111111111111111111111111111111111',node.can_opt)

                        node.can_opt = nil

                        node:placeHandCard(1)
                    end
                end
                node:checkTingTip()
            end
            has_move = nil
            node.my_sel_index_sceond = nil
        end
        break
    end

    return has_move
end

function MJClickAction.resetClickSelected(node)
    node.selected_card_index = nil
    node.selected_card_posx = nil
    node.selected_card_posy = nil
    node.my_sel_index = nil
    node.my_sel_index_sceond = nil
end

function MJClickAction.resetCard(node)
    if not node.selected_card_index or
        not node.hand_card_list or
        not node.hand_card_list[1] or
        not node.hand_card_list[1][node.selected_card_index] or
        not node.selected_card_posx or
        not node.selected_card_posy or
        not node.card_scale_init_x or
        not node.card_scale_init_y
        then
        return
    end
    node.hand_card_list[1][node.selected_card_index]:setPositionX(node.selected_card_posx)
    node.hand_card_list[1][node.selected_card_index]:setPositionY(node.selected_card_posy)
    node.hand_card_list[1][node.selected_card_index]:setLocalZOrder(node.ZOrder.HAND_CARD_ZORDER_1 + 14)
    node.hand_card_list[1][node.selected_card_index]:setVisible(true)

    -------------------------------------------
    node.hand_card_list[1][node.selected_card_index]:setScaleX(node.card_scale_init_x)
    node.hand_card_list[1][node.selected_card_index]:setScaleY(node.card_scale_init_y)
    node:placeHandCard(1)
    -------------------------------------------

    node.selected_card_index = nil
    node.selected_card_posx = nil
    node.selected_card_posy = nil
end

MJClickAction.OutTime = true

function MJClickAction.doubleClickSchedule()
    local function startClickSchedule()
        local function mjClickTimeCallBack()
            MJClickAction.closeClickSchedule()
            MJClickAction.OutTime = true
        end

        MJClickAction.OutTime = false

        MJClickAction.MJClickTimeSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(mjClickTimeCallBack, 0.5, false)
    end

    local bOutTime = clone(MJClickAction.OutTime)
    MJClickAction.closeClickSchedule()
    startClickSchedule()
    print('```````````````` ' .. tostring(bOutTime))
    return bOutTime
end

function MJClickAction.closeClickSchedule()
    MJClickAction.OutTime = true
    if MJClickAction.MJClickTimeSchedule then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(MJClickAction.MJClickTimeSchedule)
        MJClickAction.MJClickTimeSchedule = nil
    end
end

return MJClickAction