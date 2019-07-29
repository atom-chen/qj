local ClubModel = class("ClubModel", BaseModel)

function ClubModel:ctor()
	self:reset()
end

function ClubModel:reset()
    self.data = nil
    self.sendedClubId = nil
end

function ClubModel:setClubData(rtn_msg)
    -- dump(rtn_msg,"rtn_msg",10)
    -- print("===================设置亲友圈数据")
    self.data = rtn_msg
end

function ClubModel:getClubId()
    if self.data and self.data.club_info then
        return self.data.club_info.club_id
    end
end

function ClubModel:setSendedClubId(_clubId)
    self.sendedClubId = _clubId
end

function ClubModel:getSendedClubId()
    return self.sendedClubId
end

return ClubModel