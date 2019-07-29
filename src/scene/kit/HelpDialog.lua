require('scene.DTUI')

local HelpDialog = class("HelpDialog", function()
    return gt.createMaskLayer()
end)

function HelpDialog:ctor(sel)
    local csb = DTUI.getInstance().csb_main_help_dialog
    self:addCSNode(csb)

    self:addBtListener("btExit", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)

    local listView   = self:seekNode("lvGame")
    local scrollView = self:seekNode("svHelp")
    local tNote      = self:seekNode("tNote")
    local scheTag    = false

    -- 开启事件（和onEnter 与 onExit 配合使用）
    -- self:enableNodeEvents()
    require 'scene.ScrollViewBar'
    local scorllCallBack, touchCallBack = ScrollViewBar.create(scrollView)
    scrollView:addEventListener(scorllCallBack)
    scrollView:addTouchEventListener(touchCallBack)

    local InnerContainerSize = scrollView:getInnerContainerSize()

    local shuoming = require("scene.shuoming")

    local game_list = {
        {key = "tdhmj", normal = "qj_shanxiTDH_normal", sel = "qj_shanxiTDH_select"},
        {key = "kdmj", normal = "qj_koudian_normal", sel = "qj_koudian_select"},
        {key = "lsmj", normal = "qj_lisi_normal", sel = "qj_lisi_select"},
        {key = "gsj", normal = "qj_gsj_normal", sel = "qj_gsj_select"},
        {key = 'jzgsj', normal = 'qj_jzgsj_normal', sel = 'qj_jzgsj_select'},
        {key = "jz", normal = "qj_jinzhong_normal", sel = "qj_jinzhong_select"},
        {key = "xamj", normal = "qj_xian_normal", sel = "qj_xian_select"},
        {key = 'hbmj', normal = 'qj_hebei_normal', sel = 'qj_hebei_select'},
        {key = 'hbtdhmj', normal = 'qj_hebeiTDH_normal', sel = 'qj_hebeiTDH_select'},
        {key = 'bddbzmj', normal = 'qj_bddbz_normal', sel = 'qj_bddbz_select'},
        {key = "ddz", normal = "qj_ddz_normal", sel = "qj_ddz_select"},
        {key = "pdk", normal = "qj_pdk_normal", sel = "qj_pdk_select"},
        {key = 'zgz', normal = 'qj_zgz_normal', sel = 'qj_zgz_select'},
    }
    local select_list = {
        ["tdhmj"]   = 0,
        ["kdmj"]    = 1,
        ["lsmj"]    = 2,
        ["gsj"]     = 3,
        ['jzgsj']   = 4,
        ["jz"]      = 5,
        ["xamj"]    = 6,
        ['hbmj']    = 7,
        ['hbtdhmj'] = 8,
        ['bddbzmj'] = 9,
        ["ddz"]     = 10,
        ["pdk"]     = 11,
        ['zgz']     = 12,
    }
    if sel ~= nil then
        local clone_sel = clone(game_list[select_list[sel] + 1])
        table.remove(game_list, select_list[sel] + 1)
        -- for  i = 1 , #game_list do
        --     if game_list[i].key == sel then
        --         clone_sel = clone(game_list[i])
        --         table.remove(game_list,i)
        --         break
        --     end
        -- end
        table.insert(game_list, 1, clone_sel)
    end

    local function resetScorllView()
        if scrollView:getInnerContainerSize().height < tNote:getContentSize().height then
            scrollView:setInnerContainerSize(cc.size(scrollView:getInnerContainerSize().width, tNote:getContentSize().height))
            tNote:setPositionY(scrollView:getInnerContainerSize().height)
        end
        scrollView:jumpToPercentVertical(0)
    end

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
                            tNote:setString(ymkj.base64Decode(shuoming[cur_sel_item.game.key]))
                        else
                            tNote:setString("敬请期待游戏说明")
                        end
                        resetScorllView()
                    end
                end
            end)
    end

    print('游戏玩法')
    -- print(sel)
    -- if sel ~= nil then
    --     cur_sel_item = listView:getItem(select_list[sel])
    -- else
    --     cur_sel_item = cur_sel_item or listView:getItem(0)
    -- end

    cur_sel_item = cur_sel_item or listView:getItem(0)

    cur_sel_item:loadTexture("ui/qj_createroom/"..cur_sel_item.game.sel..".png")
    cur_sel_item:setScaleX(1.08)

    if shuoming[cur_sel_item.game.key] then
        tNote:setString(ymkj.base64Decode(shuoming[cur_sel_item.game.key]))
    else
        tNote:setString("敬请期待游戏说明")
    end
    resetScorllView()
end

-- function HelpDialog:onExit()
--     if self.scheduler then
--         cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduler)
--     end
-- end

return HelpDialog