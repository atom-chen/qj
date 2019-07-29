--------------------------------------------------------------------------------
-- @Author: liyongjin
-- @Date: 2018-09-07
-- @Last Modified by: liyongjin2020@126.com
-- @Last Modified time: 2018-09-07
-- @Desc: 亲友圈代理绑定
--------------------------------------------------------------------------------
require('club.ClubHallUI')

local ClubAgentBind = class("ClubAgentBind", function()
    return gt.createMaskLayer()
end)

function ClubAgentBind:ctor(agentId, clubCard, freeDay)

    self:setName('ClubAgentBind')

    local csb = ClubHallUI.getInstance().csb_club_agent_bind_dialog
    self:addCSNode(csb)

    self:setData(agentId, clubCard, freeDay)

    self:addBtListener("btOk", function()
        AudioManager:playPressSound()
        GameGlobal.openClubCreate = 1
        local CreateLayer         = require("scene.CreateLayer")
        director:getRunningScene():addChild(CreateLayer:create({
            clubOpt   = 1,
            qunzhu    = 1,
            mainScene = director:getRunningScene(),
            isGM      = true,
        }))
        self:removeFromParent(true)
    end, true)
    self:addBtListener("btCancel", function()
        AudioManager:playPressSound()
        local net_msg = {
            cmd  = NetCmd.C2S_CLUB_UID_BIND_AGENT,
            type = 0
        }
        ymkj.SendData:send(json.encode(net_msg))
        self:removeFromParent(true)
    end, true)

    self:addBtListener("btClose", function()
        AudioManager:playPressSound()
        self:removeFromParent(true)
    end)
end

function ClubAgentBind:setData(agentId, clubCard, freeDay)
    local tAgentApply = self:seekNode("tAgentApply")
    tAgentApply:setString(string.format("%d 申请绑定此游戏ID", agentId))

    local tClubCard = self:seekNode("tClubCard")
    if not freeDay then
        tClubCard:setString(string.format("%d 张房卡", clubCard))
    else
        tClubCard:setString(string.format("%d 张房卡，%d 日无限畅玩", clubCard, freeDay))
    end
end

return ClubAgentBind