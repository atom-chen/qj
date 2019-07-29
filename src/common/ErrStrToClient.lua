-- 错误列表
local ErrNo = require("common.ErrNo")

local ErrStrToClient = {}

ErrStrToClient[ErrNo.SIGN_ERROR] = "签名错误"

ErrStrToClient[ErrNo.FENGHAO]                = "sdk登录失败"
ErrStrToClient[ErrNo.SDK_LOGIN_ERROR]        = "sdk登录失败"
ErrStrToClient[ErrNo.SAVE_ACCOUNT_FAIL]      = "保存账户失败"
ErrStrToClient[ErrNo.ACCOUNT_PASSWORD_ERROR] = "账号或密码不对"

ErrStrToClient[ErrNo.APPLY_JIESAN_TIME]   = "申请解散间隔60秒"
ErrStrToClient[ErrNo.APPLY_JIESAN_STATUS] = "当前没有人申请解散"

ErrStrToClient[ErrNo.WAIT_BBHU]   = "不能出牌，等待板板胡"
ErrStrToClient[ErrNo.WANG_NO_OUT] = "王不能出"

ErrStrToClient[ErrNo.CARD_NOT_ENOUGH] = "房卡不足"
ErrStrToClient[ErrNo.ROOM_FULL]       = "房间满了"
ErrStrToClient[ErrNo.ROOM_NOT_EXISTS] = "房间不存在"
ErrStrToClient[ErrNo.ROOM_START]      = "房间已经开始"

ErrStrToClient[ErrNo.CANT_OUT_CARD] = "不让出牌（原因：有人要起手胡等）"
ErrStrToClient[ErrNo.USER_IN_ROOM]  = "已经在房间"

ErrStrToClient[ErrNo.USER_HAS_BIND]     = "用户已经绑定"
ErrStrToClient[ErrNo.INVITE_CODE_ERROR] = "错误的邀请码"
ErrStrToClient[ErrNo.VIP_ROOM_NUM_OVER] = "vip房间数量超限"
ErrStrToClient[ErrNo.HAD_BIND_ACCOUNT]  = "已经绑定"
ErrStrToClient[ErrNo.ACCOUNT_EXIST]     = "账户已经存在"
ErrStrToClient[ErrNo.BIND_ACCOUNT_FAIL] = "绑定失败"
ErrStrToClient[ErrNo.NO_BIND_USER]      = "非群主授权用户"

ErrStrToClient[ErrNo.APPLY_START_TIME]   = "申请快速开始间隔60秒"
ErrStrToClient[ErrNo.APPLY_START_STATUS] = "当前没有人快速开始"

ErrStrToClient[ErrNo.GPS_IP_CLOSE] = "GPS太近或者IP相同"

-- 俱乐部]
ErrStrToClient[ErrNo.USER_IS_BANED]       = "您当前处于被封禁状态，无法在当前亲友圈打牌，请联系圈主/管理员解封!"
ErrStrToClient[ErrNo.USER_ID_ERROR]       = "房间不属于当前用户"
ErrStrToClient[ErrNo.ROOM_INFO_ERROR]     = "房主id错误"
ErrStrToClient[ErrNo.ROOM_CLOSED]         = "房间已经关闭"
ErrStrToClient[ErrNo.ROOM_HAS_PLAY]       = "房间有人玩"
ErrStrToClient[ErrNo.NOT_AGENT]           = "您不是代理"
ErrStrToClient[ErrNo.CLUB_HAS_BIND]       = "已经绑定"
ErrStrToClient[ErrNo.CLUB_BIND_FAIL]      = "绑定失败"
ErrStrToClient[ErrNo.NOT_FIND_USER]       = "已经绑定"
ErrStrToClient[ErrNo.CLUB_ROOM_TYPE_FULL] = "房间类型超上限"
ErrStrToClient[ErrNo.CLUB_PLAYING]        = "房间已经开始"

ErrStrToClient[ErrNo.NO_TJ_CARD]     = "没有推荐奖励"
ErrStrToClient[ErrNo.CLUB_FREE_MODE] = "没有权限开此类型房间"
ErrStrToClient[ErrNo.GET_GIFT_ERROR] = "条件不满足"

-- 领取红包]
ErrStrToClient[ErrNo.WRONG_RED_PACK_TYPE]    = "错误的红包活动类型"
ErrStrToClient[ErrNo.FAILED_TO_GET_RED_PACK] = "领取红包失败"
ErrStrToClient[ErrNo.NO_RED_PACK]            = "没有红包奖励可领取"
ErrStrToClient[ErrNo.NEED_BIND_MP]           = "首次领取红包需要先绑定微信公众号"
ErrStrToClient[ErrNo.HAS_GOT_ALL_RED_PACK]   = "已经领取完所有红包奖励"
ErrStrToClient[ErrNo.OVERDUE_RED_PACK]       = "超过领取时间，红包已失效"

-- 跑得快出牌错误
ErrStrToClient[ErrNo.OUT_CARD_TYPE_ERROR] = "牌型错误"
ErrStrToClient[ErrNo.OUT_CARD_NOT_BIGGER] = "没有大于前面牌型"
ErrStrToClient[ErrNo.OUT_CARD_MUST_OUT]   = "必须出牌"

return ErrStrToClient