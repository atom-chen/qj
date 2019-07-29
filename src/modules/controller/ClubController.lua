local ClubController = {}

function ClubController:getModel()
	return PlayerManager:getModel("Club")
end

function ClubController:registerEventListener()
    -- if self.registed then return end
    -- self.registed = true
    local CUSTOM_LISTENERS = {
        ["send_club_uid"]               = handler(self, self.resSendClubUid),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function ClubController:unregisterEventListener()
    local LISTENER_NAMES = {
        ["send_club_uid"]               = handler(self, self.resSendClubUid),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function ClubController:reqSendClubUid()
    local club_id = self:getModel():getClubId()
    if not club_id then
        return
    end
    local sendedClubId = self:getModel():getSendedClubId()
    local uid = AccountController:getModel():getId()
    if sendedClubId ~= club_id then
        -- print("====================reqSendClubUid",club_id,uid)
        local url = gt.getConf("send_club_uid_url")
        gt.reqHttpGet("send_club_uid",url,{
            club_id = club_id,
            uid = uid,
        })
        -- print("====================reqSendClubUid",club_id,url)
    end


end

function ClubController:resSendClubUid(rtn_msg)
    -- print("====================resSendClubUid",rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = nil
    local function jsonDecode()
        data = json.decode(rtn_msg)
    end
    if not pcall(jsonDecode) then
        print('resSendClubUid decode faild')
        gt.uploadErr(tostring(rtn_msg))
        return
    end
    if data then
        if tonumber(data.code) == 0 and data.club_id then
            self:getModel():setSendedClubId(data.club_id)
        end
    end
end

cc.exports.ClubController = ClubController