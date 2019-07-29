-- total error 21 lines ylqj/1.0.21012
require("common.logger.inspect_utils")

require('scene.RoomInfo')

PlayerData = PlayerData or {}

function printUploadStr(str)
    local x = inspect(str)
    print(x)
    gt.uploadErr(x)
end

function getDebugStr(str)
    local timedata = os.date("%Y-%m-%d %H:%M:%S", os.time())
    str            = str .. ' t:' .. timedata .. ' ri:' .. tostring(RoomInfo.room_id) .. ' mi:' .. tostring(PlayerData.MyServerIndex)

    return str
end

function getPlayerDataDebugStr()
    local x = inspect(PlayerData.IDToUserData)

    return x
end

function printDebug(str)
    local timedata = os.date("%Y-%m-%d %H:%M:%S", os.time())
    str            = str .. ' t:' .. timedata .. ' ri:' .. tostring(RoomInfo.room_id) .. ' mi:' .. tostring(PlayerData.MyServerIndex)
    gt.uploadErr(str)
    printUploadStr(PlayerData.IDToUserData)
    print('--------------------')
    print(str)
    print('--------------------')
end

PlayerData.IDToUserData  = PlayerData.IDToUserData or {} -- key : ID  value : userData
PlayerData.MyServerIndex = PlayerData.MyServerIndex or nil

function printUserData(userDataTable)
    for i, v in pairs (userDataTable or {}) do
        local str = string.format('index:%s,\tuid:%s,\tserver_index:%s,\tclient_index:%s, \tname:%s', tostring(i), tostring(v.uid), tostring(v.index), tostring(v.client_index), tostring(v.name))
        print(str)
    end
end

function printAllUserDataTable()
    print('_______________ IDToUserData __________________________')
    printUserData(PlayerData.IDToUserData)
end

function PlayerData.getPlayerDataByUserID(id)
    local userData = PlayerData.IDToUserData[id]
    return userData
end

function PlayerData.getPlayerDataByClientID(client_index)
    for i, v in pairs(PlayerData.IDToUserData) do
        local client = PlayerData.getPlayerClientIDByServerID(v.index)
        if client == client_index then
            return v
        end
    end
    return nil
end

function PlayerData.getPlayerDataByServerID(server_index)
    for i, v in pairs(PlayerData.IDToUserData) do
        if v.index == server_index then
            return v
        end
    end
    return nil
end

function PlayerData.setServerIDToClientIDDelegate(func)
    PlayerData.getPlayerClientIDByServerIDDelegate = func
end

function PlayerData.getPlayerClientIDByServerID(server_index)
    if PlayerData.getPlayerClientIDByServerIDDelegate then
        -- log('是否是这里')
        local client_index = PlayerData.getPlayerClientIDByServerIDDelegate(server_index)
        -- print('server_index',server_index,'client_index',client_index)
        return client_index
    end
    local client_index = PlayerData.getPlayerClientIDByServerID_(server_index)
    return client_index
end

function PlayerData.getPlayerClientIDByServerID_(index)
    local my_index = PlayerData.MyServerIndex
    if index == PlayerData.MyServerIndex then
        return 1
    end
    local pp = people_num or RoomInfo.getTotalPeopleNum()
    if pp == 2 then
        return 3
    elseif pp == 3 then
        if my_index == 1 then
            if index == 3 then
                return 4
            else
                return 2
            end
        elseif my_index == 2 then
            if index == 1 then
                return 4
            else
                return 2
            end
        else
            if index == 2 then
                return 4
            else
                return 2
            end
        end
    else
        if index > my_index then
            return index - my_index + 1
        end
        if index < my_index then
            return index - my_index + 5
        end
    end
end

function PlayerData.updatePlayerInfo(playerinfo_list, room_info)
    if room_info.status ~= 0 then
        local num = 0
        for i, v in ipairs(playerinfo_list) do
            num = num + 1
        end
        if num ~= room_info.people_num then
            printDebug('game reconnect playerinfo_list num ~= room_info.people_num')
            printDebug('room_info.people_num ' .. tostring(room_info and room_info.people_num or ''))
            printDebug('room_info.status:' .. tostring(room_info.status) .. ' room_info.cur_ju:' .. tostring(room_info.cur_ju))
            printUploadStr(playerinfo_list)
        end
    end

    PlayerData.IDToUserData  = {}
    PlayerData.MyServerIndex = playerinfo_list and playerinfo_list[1] and playerinfo_list[1].index
    for i, v in ipairs(playerinfo_list) do
        PlayerData.IDToUserData[v.uid] = v
    end
    print('房间人物数据 ___________________________________')
    printAllUserDataTable()
    print('房间人物数据 ___________________________________')

    if RoomInfo.status ~= 0 then
        local num = 0
        for i, v in pairs(PlayerData.IDToUserData) do
            num = num + 1
        end
        if num ~= RoomInfo.getTotalPeopleNum() then
            printDebug('game reconnect PlayerData.IDToUserData num ~= RoomInfo.getTotalPeopleNum')
            printDebug('RoomInfo.people_num ' .. tostring(RoomInfo and RoomInfo.people_total_num or ''))
            printDebug('RoomInfo.status:' .. tostring(RoomInfo.status) .. ' RoomInfo.cur_ju:' .. tostring(RoomInfo.cur_ju))
            printUploadStr(PlayerData.IDToUserData)
        end
    end
end

function PlayerData.updatePlayerInfoByTableUserInfo(rtn_msg)
    if not rtn_msg then
        return
    end
    local index = rtn_msg.index
    if not index then
        return
    end
    local uid = rtn_msg.uid
    if not uid then
        return
    end
    PlayerData.IDToUserData[uid] = rtn_msg
    print('玩家进入 tableuserinfo _________________________________')
    printAllUserDataTable()
    print('玩家进入 tableuserinfo _________________________________')
end

function PlayerData.updateIndexByGameStart(rtn_msg)
    if not rtn_msg then
        dump(rtn_msg)
        return
    end

    local players = rtn_msg.players
    if not players then
        dump(players)
        return
    end

    print('游戏开始 坐位检查前 _________________________________')
    printAllUserDataTable()
    print('游戏开始 坐位检查前 _________________________________')
    local uid = gt.getData('uid')
    -- 清除退出房间的玩家
    local tUid = {}
    for i, v in ipairs(players) do
        tUid[v.uid] = true
    end
    for i, v in pairs(PlayerData.IDToUserData) do
        if not tUid[i] then
            PlayerData.IDToUserData[i] = nil
        end
    end
    for i, v in ipairs(players) do
        if v.uid == uid then
            PlayerData.MyServerIndex = v.index
        end
    end
    for i, v in ipairs(players) do
        local index = v.index
        local uid   = v.uid

        PlayerData.IDToUserData[uid].index = index
    end
    print('游戏开始 坐位检查后 _________________________________')
    printAllUserDataTable()
    print('游戏开始 坐位检查后 _________________________________')

    g_PlayerData = PlayerData
end

function PlayerData.getMyServerID()
    return PlayerData.MyServerIndex
end

function PlayerData.updatePlayerInfoByLeaveRoom(rtn_msg)
    dump(rtn_msg)
    if not rtn_msg then
        return
    end
    local index = rtn_msg.index
    if not index then
        return
    end
    for i, v in pairs(PlayerData.IDToUserData) do
        if v.index == index then
            PlayerData.IDToUserData[i] = nil
            break
        end
    end
    print('玩家退出_________________________________')
    printAllUserDataTable()
    print('玩家退出_________________________________')
end

function PlayerData.updatePlayerInfoByReady(players)
    if not players then
        return
    end
    local uid = gt.getData('uid')
    for i, v in pairs(players) do
        PlayerData.IDToUserData[v.uid].index = v.index
        if v.uid == uid then
            PlayerData.MyServerIndex = v.index
        end
    end
end