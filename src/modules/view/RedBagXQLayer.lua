local RedBagXQLayer = class("RedBagXQLayer",function(args)
    return cc.Node:create()
end)
--传入场景 和 标志位（区分麻将和扑克游戏）
function RedBagXQLayer:ctor(args)
    self.isMJ = args.isMJ
    self._scene = args._scene
    self:enableNodeEvents()
end

function RedBagXQLayer:onEnter()
    local node = tolua.cast(cc.CSLoader:createNode("ui/ui_play_redbags.csb"),"ccui.Widget")
    self:addChild(node)
    node:setPosition(cc.p(0,0))
    self.node = node

    self.node:setVisible(false)
    self:intiUI()
end



function RedBagXQLayer:intiUI()
    self.ListView_HB = ccui.Helper:seekWidgetByName(self.node,"listview_hb")
    self.ListView_HB:setVisible(false)
    self.ListView_HB:setTouchEnabled(false)


    local backBtn = ccui.Helper:seekWidgetByName(self.node,"panel")
    backBtn:addTouchEventListener(
        function(sender,eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:setHbVisibale(false)
            end
        end
    )

end

function RedBagXQLayer:setHbVisibale(bool)
    self.node:setVisible(bool)
end


function RedBagXQLayer:reFreshHB()
    local player_ui = self._scene.player_ui

    if self.listView_clone then
        self.listView_clone:removeSelf()
        self.listView_clone = nil 
    end

    self.listView_clone = self.ListView_HB:clone()
    self.listView_clone:setVisible(true)
    self.listView_clone:setTouchEnabled(true)

    self.hbxq_item = ccui.Helper:seekWidgetByName(self.listView_clone,"xqItem")
    local panel_hbxq = ccui.Helper:seekWidgetByName(self.node,"panel_hbxq")
    panel_hbxq:addChild(self.listView_clone)
    
    --赋值
    for index , player_ui_item in ipairs(player_ui) do 
        local userData = nil
        local PorkData = {}
        local itemData = nil

        --麻将获取数据
        if self.isMJ then
            userData = PlayerData.getPlayerDataByClientID(index)   
        else
            if player_ui_item.user then
                PorkData.PorkName = player_ui_item.user.nickname
                PorkData.PorkUid = player_ui_item.user.user_id
            end
        end

        --如果没有数据 直接就不执行本次循环 测试数据item必有 正式数据item根据uid获取可以用itemData测试
        local isHaveData = true	
        if nil == userData and self.isMJ then
            -- print("未获取到userData数据")
            isHaveData = false 
        end

        if nil == next(PorkData) and not self.isMJ then
            -- print("未获取到PorkData数据")
            isHaveData = false 
        end

        if isHaveData then
            if userData then
                --根据玩家ID获取数据            
                itemData = RedBagController:getModel():getUserInfoById(userData.uid)
            elseif PorkData then
                -- --扑克获取红包详细信息数据
                itemData = RedBagController:getModel():getUserInfoById(PorkData.PorkUid)
            end

            if nil == itemData then
                -- print("未获取到itemData数据")
                break
            end 

            --获取添加的详情Item
            local item = self.hbxq_item
            if(index>1) then
                item = self.hbxq_item:clone()
                self.listView_clone:pushBackCustomItem(item)
            end
     
            --如果不设置就会直接克隆第一个item的数据 麻将游戏设置名字
            if userData then
                if pcall(commonlib.GetMaxLenString, userData.name, 12) then
                    ccui.Helper:seekWidgetByName(item, "wanjia_name"):setString(commonlib.GetMaxLenString(userData.name, 12))
                else
                    ccui.Helper:seekWidgetByName(item, "wanjia_name"):setString(userData.name)
                end
            end
            --扑克类游戏设置名字
            if PorkData and nil ~= next(PorkData) then
                if pcall(commonlib.GetMaxLenString, PorkData.PorkName, 12) then
                    ccui.Helper:seekWidgetByName(item, "wanjia_name"):setString(commonlib.GetMaxLenString(PorkData.PorkName, 12))
                else
                    ccui.Helper:seekWidgetByName(item, "wanjia_name"):setString(PorkData.PorkName)
                end
            end

            if itemData then
                ccui.Helper:seekWidgetByName(item, "benju_hb"):setString(""..itemData.roomAmount*0.01)
                ccui.Helper:seekWidgetByName(item, "leiji_hb"):setString(""..itemData.sumAmount*0.01)            
            end
        end

        --目前最多为4个防止超出
        if(index>4) then
            break
        end
    end
end

function RedBagXQLayer:onExit()

end

return RedBagXQLayer