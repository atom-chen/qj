
local GameController = {}

function GameController:getModel()
    return PlayerManager:getModel("Game")
end

function GameController:registerEventListener()
    if self.register then
        return
    end

    self.register = true

    local NETMSG_LISTENERS = {
        -- 游戏公共消息
        [NetCmd.S2C_BROAD]                = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_READY]                = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_JIESAN]               = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_APPLY_JIESAN]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]   = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_ROOM_CHAT]            = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_ROOM_CHAT_BQ]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_LEAVE_ROOM]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_IN_LINE]              = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_OUT_LINE]             = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_SYNC_USER_DATA]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]     = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_CLUB_MODIFY]          = handler(self, self.onRcvGameMsg),

        -- MJ
        -- [NetCmd.S2C_MJ_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GAME_START]       = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_COOL_DOWN]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_DRAW_CARD]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_PENG]             = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GANG]             = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_CHI_CARD]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_HU]               = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_CHI_HU]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_KOUPAI]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_RESULT]              = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),

        -- [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvGameMsg),

        -- [NetCmd.S2C_MJ_DO_PASS_HU]       = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GAME_INFO]        = handler(self, self.onRcvGameMsg),

        -- -- PDK
        [NetCmd.S2C_PDK_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_GAME_START]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_RESULT]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),

        -- -- DDZ
        [NetCmd.S2C_DDZ_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_GAME_START]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_CALL_SCORE]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_JIABEN]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_CALL_HOST]        = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_QIANG_HOST]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_SHOW_BANKER]      = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_RESULT]           = handler(self, self.onRcvGameMsg),

    }
    for k, v in pairs(NETMSG_LISTENERS) do
        gt.addNetMsgListener(k, v)
    end
end

function GameController:unregisterEventListener()
    self.register = false

    local LISTENER_NAMES = {
        -- 游戏公共消息
        [NetCmd.S2C_BROAD]                = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_READY]                = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_JIESAN]               = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_APPLY_JIESAN]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_APPLY_JIESAN_AGREE]   = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_ROOM_CHAT]            = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_ROOM_CHAT_BQ]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_LEAVE_ROOM]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_IN_LINE]              = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_OUT_LINE]             = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_SYNC_USER_DATA]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_SYNC_CLUB_NOTIFY]     = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_CLUB_MODIFY]          = handler(self, self.onRcvGameMsg),

        -- MJ
        -- [NetCmd.S2C_MJ_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GAME_START]       = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_COOL_DOWN]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_DRAW_CARD]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_PENG]             = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GANG]             = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_CHI_CARD]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_HU]               = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_CHI_HU]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_KOUPAI]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_RESULT]              = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_ROOM_CHAT]           = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_ROOM_CHAT_BQ]        = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),

        -- [NetCmd.S2C_APPLY_START]         = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_APPLY_START_AGREE]   = handler(self, self.onRcvGameMsg),

        -- [NetCmd.S2C_MJ_DO_PASS_HU]       = handler(self, self.onRcvGameMsg),
        -- [NetCmd.S2C_MJ_GAME_INFO]        = handler(self, self.onRcvGameMsg),

        -- -- PDK
        [NetCmd.S2C_PDK_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_GAME_START]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_RESULT]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_PDK_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),

        -- -- DDZ
        [NetCmd.S2C_DDZ_TABLE_USER_INFO]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_GAME_START]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_JOIN_ROOM_AGAIN]  = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_CALL_SCORE]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_JIABEN]           = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_CALL_HOST]        = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_QIANG_HOST]       = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_SHOW_BANKER]      = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_OUT_CARD]         = handler(self, self.onRcvGameMsg),
        [NetCmd.S2C_DDZ_RESULT]           = handler(self, self.onRcvGameMsg),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function GameController:onRcvGameMsg(rtn_msg)
    print('---------------------------------')
    print(rtn_msg.cmd)
    print('---------------------------------')
    self:getModel():onRcvGameMsg(rtn_msg)
    EventBus:dispatchEvent(EventEnum.onRcvGameMsg)
end

cc.exports.GameController = GameController