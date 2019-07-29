local RoomController = {}

function RoomController:getModel()
	return PlayerManager:getModel("Room")
end

cc.exports.RoomController = RoomController