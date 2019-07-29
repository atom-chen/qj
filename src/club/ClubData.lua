local ClubData = {}
--ClubData.data key: club_id  value :data
--ClubData.clubs key: index value: club_id

function ClubData.getData(club_id)
    ClubData.data = ClubData.data or {}
    return ClubData.data[club_id]
end

function ClubData.getClubs()
    ClubData.clubs = ClubData.clubs or {}
    return ClubData.clubs
end

function copyTable(oldData, newData)
    for k, v in pairs(newData or {}) do
        oldData[k] = v
    end
    return oldData
end

function ClubData.onRcvInfoMax(rtn_msg)
    -- dump(rtn_msg)
    if not rtn_msg then
        return
    end
    local club_info = rtn_msg.club_info
    if not club_info then
        return
    end
    local club_id = club_info.club_id
    if not club_id then
        return
    end

    ClubData.data = ClubData.data or {}
    ClubData.data[club_id] = rtn_msg
end

function ClubData.onRcvGetClubList(rtn_msg)
    ClubData.clubs = rtn_msg.clubs

    local ownerClubs = nil
    for i , v in ipairs(ClubData.clubs) do
        if v.club_id == gt.getData('uid') then
            ownerClubs = v
            table.remove(ClubData.clubs,i)
            break
        end
    end
    if ownerClubs then
        table.insert(ClubData.clubs,1,ownerClubs)
    end

    for i , v in ipairs(ClubData.clubs) do
        ClubData.data = ClubData.data or {}
        ClubData.data[v.club_id] = ClubData.data[v.club_id] or {}
        ClubData.data[v.club_id].club_info = ClubData.data[v.club_id].club_info or {}
        ClubData.data[v.club_id].club_info = copyTable(ClubData.data[v.club_id].club_info,v)
    end
end

function ClubData.onRcvClubJieSanRoom(rtn_msg)
    ClubData.data = ClubData.data or {}
    for club_id , v in pairs(ClubData.data) do
        ClubData.data[club_id] = ClubData.data[club_id] or {}
        ClubData.data[club_id].club_rooms = ClubData.data[club_id].club_rooms or {}
        local club_rooms = ClubData.data[club_id].club_rooms
        for i = 1, table.maxn(club_rooms) do
            local room = club_rooms[i]
            if room and room.room_id == rtn_msg.room_id then
                club_rooms[i] = copyTable(club_rooms[i],rtn_msg)
            end
        end
    end
end

function ClubData.onRcvClubAddRoom(rtn_msg)
    -- dump(rtn_msg)
    if rtn_msg.clubOpt == 2 then
        ClubData.data = ClubData.data or {}
        local club_id = rtn_msg.club_id
        if not club_id then
            return
        end
        local params = rtn_msg.params
        if not params then
            return
        end
        local room_id = params.room_id
        if not room_id then
            return
        end
        ClubData.data[club_id] = ClubData.data[club_id] or {}
        ClubData.data[club_id].club_rooms = ClubData.data[club_id].club_rooms or {}


        local club_rooms = ClubData.data[club_id].club_rooms
        for i = 1, table.maxn(club_rooms) do
            local room = club_rooms[i]
            if room and room.room_id == room_id then
                club_rooms[i] = copyTable(club_rooms[i],rtn_msg)
            end
        end
        ClubData.data[club_id].club_rooms = club_rooms
    end
end

function ClubData.onRcvClubModify(rtn_msg)
    local club_id = rtn_msg.club_id
    if not club_id then
        return
    end
    ClubData.data = ClubData.data or {}
    ClubData.data[club_id] = ClubData.data[club_id] or {}
    ClubData.data[club_id].club_info = ClubData.data[club_id].club_info or {}
    local club_info = ClubData.data[club_id].club_info
    if (rtn_msg.isACWF == 0 or rtn_msg.isACWF == 1) then
        club_info.isACWF = rtn_msg.isACWF
    elseif (rtn_msg.isOpen == 0 or rtn_msg.isOpen == 1) then
        club_info.isOpen = rtn_msg.isOpen
    elseif (rtn_msg.isAKFK == 0 or rtn_msg.isAKFK == 1) then
        club_info.isAKFK = rtn_msg.isAKFK
    elseif (rtn_msg.isAKZJ == 0 or rtn_msg.isAKZJ == 1) then
        club_info.isAKZJ = rtn_msg.isAKZJ
    elseif (rtn_msg.isAllowCharge == 0 or rtn_msg.isAllowCharge == 1) then
        club_info.isAllowCharge = rtn_msg.isAllowCharge
    elseif (rtn_msg.isFZB == 0 or rtn_msg.isFZB == 1) then
        club_info.isFZB = rtn_msg.isFZB
    elseif (rtn_msg.is4To32 == 0 or rtn_msg.is4To32 == 1) then
        club_info.is4To32 = rtn_msg.is4To32
    elseif (rtn_msg.isJZBQ == 0 or rtn_msg.isJZBQ == 1) then
        club_info.isJZBQ = rtn_msg.isJZBQ
    elseif (rtn_msg.isJSAA == 0 or rtn_msg.isJSAA == 1) then
        club_info.isJSAA = rtn_msg.isJSAA
    elseif (rtn_msg.cTGT and rtn_msg.cTGT >= 0) then
        club_info.cTGT = rtn_msg.cTGT
    elseif rtn_msg.name then
        club_info.club_name = rtn_msg.name
        for i,club in ipairs(ClubData.clubs or {}) do
            if club.club_id == rtn_msg.club_id then
                club.club_name = rtn_msg.name
                break
            end
        end
    end
end

function ClubData.onRcvRoomStatus(rtn_msg)
    if not rtn_msg then
        return
    end
    if not rtn_msg.club_id then
        return
    end
    local club_id = rtn_msg.club_id
    if not club_id then
        return
    end
    local room_id = rtn_msg.room_id
    if not rtn_msg.room_id then
        return
    end
    ClubData.data = ClubData.data or {}
    ClubData.data[club_id] = ClubData.data[club_id] or {}
    ClubData.data[club_id].club_rooms = ClubData.data[club_id].club_rooms or {}
    local club_rooms = ClubData.data[club_id].club_rooms
    -- for i,room in ipairs(club_rooms) do
    for i = 1, table.maxn(club_rooms) do
        local room = club_rooms[i]
        if room and room.room_id == room_id then
            club_rooms[i] = copyTable(club_rooms[i],rtn_msg)
        end
    end
end

function ClubData.onRcvClubSyncCard(rtn_msg)
    if not rtn_msg then
        return
    end
    local club_id = rtn_msg.club_id
    if not club_id then
        return
    end
    local card = rtn_msg.card
    if not card then
        return
    end
    ClubData.data = ClubData.data or {}
    ClubData.data[club_id] = ClubData.data[club_id] or {}
    ClubData.data[club_id].club_info = ClubData.data[club_id].club_info or {}
    local club_info = ClubData.data[club_id].club_info
    club_info.card = rtn_msg.card
    if rtn_msg.endTime then
        club_info.endTime = rtn_msg.endTime
    end
end

return ClubData