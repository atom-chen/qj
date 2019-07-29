local RoomModel = class("RoomModel", BaseModel)

function RoomModel:ctor()
    self:reset()
end

function RoomModel:reset()
    self._data = {}
    self.player_list = {}
end

function RoomModel:setRoomInfo(netData)
    for k,v in pairs(netData) do
        self._data[k] = v
    end
    if self._data.room_info then
        self:addPlayer(self._data.room_info.player_info)
        for i,v in ipairs(self._data.room_info.other or {}) do
            self:addPlayer(v)
        end
    end
    -- dump(self._data,"RoomModel:setRoomInfo",10)
    -- dump(self.player_list,"self.player_list",10)
end

function RoomModel:addPlayer(data)
    if not data or not data.index then
        return
    end
    self.player_list[data.index] = data
    -- dump(self.player_list,"self.player_list",10)
end

function RoomModel:getRoomId()
    -- TODO
    return tonumber(self._data["room_id"]) or 0
    -- return 123456
end

function RoomModel:getIndexById(_id)
    local index = nil
    for k,v in pairs(self.player_list) do
        if v.uid == _id then
            index = k
        end
    end
    -- TODO
    return index or 1
    -- return math.random(1,4)
end
--红包消息是否在本房间
function RoomModel:getInRoomById(_id)
    local isIn = false
    for k,v in pairs(self.player_list) do
        if v.uid == _id then
            isIn = true
        end
    end
    return isIn 
end


return RoomModel