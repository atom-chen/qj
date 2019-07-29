local EventEnum = {
    -- 客户端内部事件
    onRecordStart   = 10001,
    onRecordStop    = 10002,
    onRecordTimeOut = 10003,
    onRecordFaild   = 10004,
    onWillPlay      = 10005,
    onPlayStop      = 10006,
    onRcvSpeek      = 10007,
    onMjSound       = 10008,
    onPokerSound    = 10009,
    onReconnect     = 10010,
    onRBConnect     = 10011,
    onRBConnectFail = 10012,
    onRBClosed      = 10013,
    RedBagLayer     = 10014,
    playOneLast     = 10015,

    -- 红包消息事件
    C2S_RB_HEART = 20000,
    S2C_RB_HEART = 20000,
    C2S_RB_LOGIN = 20001,
    S2C_RB_LOGIN = 20001,
    S2C_RB_VALID = 20002,
    S2C_RB       = 20003,
    S2C_RB_INFO  = 20004,

    -- 游戏消息事件
    onRcvGameMsg = 30000,
}

cc.exports.EventEnum = EventEnum

local EventEnumReverse = {}
for k, v in pairs(EventEnum) do
    EventEnumReverse[v] = k
end

cc.exports.EventEnumReverse = EventEnumReverse