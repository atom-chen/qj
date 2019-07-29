local HelpLayer = class("HelpLayer", function()
    return cc.Layer:create()
end)

function HelpLayer:create(sel)
    local layer = HelpLayer.new()
    layer:createLayerMenu(sel)
    return layer
end

function HelpLayer:createLayerMenu(sel)
    local node = tolua.cast(cc.CSLoader:createNode("ui/DT_HelpLayer.csb"), "ccui.Widget")

    self:addChild(node)

    node:setContentSize(cc.size(g_visible_size.width, g_visible_size.height))

    ccui.Helper:doLayout(node)

    local backBtn = tolua.cast(ccui.Helper:seekWidgetByName(node, "btExit"), "ccui.Button")
    backBtn:addTouchEventListener(
        function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                AudioManager:playPressSound()
                self:removeFromParent(true)
            end
        end
    )

    local listView   = ccui.Helper:seekWidgetByName(node, "lvGame")
    local scrollView = ccui.Helper:seekWidgetByName(node, "svHelp")
    listView:setClippingEnabled(false)
    scrollView:setClippingEnabled(false)
    local InnerContainerSize = scrollView:getInnerContainerSize()
    commonlib.scaleIn(ccui.Helper:seekWidgetByName(node, "Panel_2"), function()
        scrollView:setClippingEnabled(true)
    end)
    local nn = ccui.Helper:seekWidgetByName(node, "tNote")

    local shuoming = require ("scene.shuoming")

    local game_list = {
        {key = "tdhmj", normal = "qj_tdh_normal", sel = "qj_tdh_select"},
        {key = "xamj", normal = "qj_xian_normal", sel = "qj_xian_select"},
        {key = "lsmj", normal = "qj_lisi_normal", sel = "qj_lisi_select"},
        {key = "kdmj", normal = "qj_koudian_normal", sel = "qj_koudian_select"},
        {key = "pdk", normal = "qj_pdk_normal", sel = "qj_pdk_select"},
        {key = "ddz", normal = "qj_ddz_normal", sel = "qj_ddz_select"},
    }
    local select_list = {
        ["tdhmj"] = 0,
        ["xamj"]  = 1,
        ["lsmj"]  = 2,
        ["kdmj"]  = 3,
        ["pdk"]   = 4,
        ["ddz"]   = 5,
    }
    local itemModel    = listView:getItem(0)
    local cur_sel_item = nil
    for i, v in ipairs(game_list) do

        local item = itemModel
        if i ~= 1 then
            item = itemModel:clone()
            listView:pushBackCustomItem(item)
        end
        item:loadTexture("ui/qj_createroom/"..v.normal..".png")
        item.game = v

        item:addTouchEventListener(
            function(__, eventType)
                if eventType == ccui.TouchEventType.ended then
                    AudioManager:playPressSound()
                    if item ~= cur_sel_item then
                        cur_sel_item:loadTexture("ui/qj_createroom/"..cur_sel_item.game.normal..".png")
                        cur_sel_item:setScaleX(1)
                        cur_sel_item = item

                        cur_sel_item:loadTexture("ui/qj_createroom/"..cur_sel_item.game.sel..".png")
                        cur_sel_item:setScaleX(1.08)
                        if shuoming[cur_sel_item.game.key] then
                            nn:setString(ymkj.base64Decode(shuoming[cur_sel_item.game.key]))
                        else
                            nn:setString("敬请期待游戏说明")
                        end
                        scrollView:jumpToPercentVertical(0)
                    end
                end
            end)
    end

    if sel ~= nil then
        cur_sel_item = listView:getItem(select_list[sel])
    else
        cur_sel_item = cur_sel_item or listView:getItem(0)
    end
    cur_sel_item:loadTexture("ui/qj_createroom/"..cur_sel_item.game.sel..".png")
    cur_sel_item:setScaleX(1.08)

    if shuoming[cur_sel_item.game.key] then
        nn:setString(ymkj.base64Decode(shuoming[cur_sel_item.game.key]))
    else
        nn:setString("敬请期待游戏说明")
    end

    commonlib.fadeIn(ccui.Helper:seekWidgetByName(node, "Panel_2"), function()
        listView:setClippingEnabled(true)
        nn:setVisible(true)
    end)
end

return HelpLayer