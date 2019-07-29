local GameModel = class("GameModel", BaseModel)

function GameModel:ctor()
    self:reset()
end

function GameModel:reset()
    self.GameMsg = {}
end

function GameModel:onRcvGameMsg(rtn_msg)
    self.GameMsg[#self.GameMsg+1] = rtn_msg
end

function GameModel:getGameMsg()
    return self.GameMsg
end

return GameModel