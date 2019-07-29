local scheduler = require("common.scheduler")

local RedBagClient = {}

function RedBagClient:init()
    --断线重连超时时间
    self.resumeTime = 10
    --心跳消息重连时间
    self.heartTime = 5
    --发送心跳时间
    self.heartbeatCD = self.heartTime
    --心跳回复时间间隔
    self.curReplayIntervar = 0

    local events = {
        {
            eType = EventEnum.onRBConnect,
            func = handler(self,self.onRBConnect),
        },
        {
            eType = EventEnum.onRBConnectFail,
            func = handler(self,self.onRBConnectFail),
        },
        {
            eType = EventEnum.onRBClosed,
            func = handler(self,self.onRBClosed),
        },
        {
            eType = EventEnum.S2C_RB_LOGIN,
            func = handler(self,self.S2C_RB_LOGIN),
        },
        {
            eType = EventEnum.S2C_RB_HEART,
            func = handler(self,self.S2C_RB_HEART),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
end

function RedBagClient:heartInterval(dt)
    -- print("dt",dt)
    if self.heartbeatCD >=0 then
        self.heartbeatCD = self.heartbeatCD - dt
        if self.heartbeatCD < 0 then
            self:sendHeartbeat()
        end
    else
        self.curReplayIntervar = self.curReplayIntervar + dt
        if self.curReplayIntervar >= self.resumeTime then
            self.heartbeatCD = self.heartTime
            RedBagController:connect()
        end
    end
end

function RedBagClient:startHeart()
    self:stopHeart()
    self.heartHandle = scheduler.scheduleGlobal(function(dt)
        self:heartInterval(dt)
    end, 1)
end

function RedBagClient:stopHeart()
    if self.heartHandle then
        scheduler.unscheduleGlobal(self.heartHandle)
        self.heartHandle = nil
    end
end

function RedBagClient:sendHeartbeat()
    NetCom:send(EventEnum.C2S_RB_HEART,{})
    self.curReplayIntervar = 0
    self.heartbeatCD = -1
end

function RedBagClient:connect(ip,port)
    NetCom:close()
    NetCom:connect(ip,port)
end

function RedBagClient:onRBConnect(msgTab)
    -- dump(msgTab,"onRBConnect")
    local uid = AccountController:getModel():getId()
    NetCom:send(EventEnum.C2S_RB_LOGIN,{
        appId = gt.getConf("redbag_appid"),
        userId = uid,
        -- gameType = gt.getConf("redbag_appid"),
    })
end

function RedBagClient:onRBConnectFail()
    RedBagController:connect()
end

function RedBagClient:onRBClosed()
    self:stopHeart()
    RedBagController:connect()
end

function RedBagClient:S2C_RB_LOGIN(msgTab)
    -- dump(msgTab,"S2C_RB_LOGIN")
    self:startHeart()
end

function RedBagClient:S2C_RB_HEART(msgTab)
    -- dump(msgTab,"S2C_RB_HEART")
    self.heartbeatCD = self.heartTime
end

RedBagClient:init()

cc.exports.RedBagClient = RedBagClient