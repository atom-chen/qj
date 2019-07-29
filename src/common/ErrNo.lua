-- 错误列表
local ErrNo = {}

ErrNo.SIGN_ERROR = 100 -- 签名错误

ErrNo.FENGHAO                = 1000      -- sdk登录失败
ErrNo.SDK_LOGIN_ERROR        = 1001      -- sdk登录失败
ErrNo.SAVE_ACCOUNT_FAIL      = 1002      -- 保存账户失败
ErrNo.ACCOUNT_PASSWORD_ERROR = 1003      -- 账号或密码不对

ErrNo.APPLY_JIESAN_TIME   = 1004      -- 申请解散间隔60秒
ErrNo.APPLY_JIESAN_STATUS = 1005      -- 当前没有人申请解散

ErrNo.WAIT_BBHU   = 1006      -- 不能出牌，等待板板胡
ErrNo.WANG_NO_OUT = 1007      -- 王不能出

ErrNo.CARD_NOT_ENOUGH = 1008      -- 房卡不足
ErrNo.ROOM_FULL       = 1009      -- 房间满了
ErrNo.ROOM_NOT_EXISTS = 1010      -- 房间不存在
ErrNo.ROOM_START      = 1011      -- 房间已经开始

ErrNo.CANT_OUT_CARD = 1012      -- 不让出牌（原因：有人要起手胡等）
ErrNo.USER_IN_ROOM  = 1013      -- 已经在房间

ErrNo.USER_HAS_BIND     = 1014      -- 用户已经绑定
ErrNo.INVITE_CODE_ERROR = 1015      -- 错误的邀请码
ErrNo.VIP_ROOM_NUM_OVER = 1016      -- vip房间数量超限
ErrNo.HAD_BIND_ACCOUNT  = 1017      -- 已经绑定
ErrNo.ACCOUNT_EXIST     = 1018      -- 账户已经存在
ErrNo.BIND_ACCOUNT_FAIL = 1019      -- 绑定失败
ErrNo.NO_BIND_USER      = 1020      -- 非群主授权用户

ErrNo.APPLY_START_TIME   = 1021      -- 申请快速开始间隔60秒
ErrNo.APPLY_START_STATUS = 1022      -- 当前没有人快速开始

ErrNo.GPS_IP_CLOSE = 1023 -- GPS太近或者IP相同

-- 俱乐部
ErrNo.USER_IS_BANED       = 1040      -- 玩家已被封禁
ErrNo.USER_ID_ERROR       = 1041      -- 房间不属于当前用户
ErrNo.ROOM_INFO_ERROR     = 1042      -- 房主id错误
ErrNo.ROOM_CLOSED         = 1043      -- 房间已经关闭
ErrNo.ROOM_HAS_PLAY       = 1044      -- 房间有人玩
ErrNo.NOT_AGENT           = 1045      -- 您不是代理
ErrNo.CLUB_HAS_BIND       = 1046      -- 已经绑定
ErrNo.CLUB_BIND_FAIL      = 1047      -- 绑定失败
ErrNo.NOT_FIND_USER       = 1048      -- 已经绑定
ErrNo.CLUB_ROOM_TYPE_FULL = 1049      -- 房间类型超上限
ErrNo.CLUB_PLAYING        = 1050      -- 房间已经开始

ErrNo.NO_TJ_CARD     = 1051      -- 没有推荐奖励
ErrNo.CLUB_FREE_MODE = 1052      -- 没有权限开此类型房间
ErrNo.GET_GIFT_ERROR = 1053      -- 条件不满足

-- 领取红包
ErrNo.WRONG_RED_PACK_TYPE    = 1054      -- 错误的红包活动类型
ErrNo.FAILED_TO_GET_RED_PACK = 1055      -- 领取红包失败
ErrNo.NO_RED_PACK            = 1056      -- 没有红包奖励可领取
ErrNo.NEED_BIND_MP           = 1057      -- 首次领取红包需要先绑定微信公众号
ErrNo.HAS_GOT_ALL_RED_PACK   = 1058      -- 已经领取完所有红包奖励
ErrNo.OVERDUE_RED_PACK       = 1059      -- 超过领取时间，红包已失效

-- 跑得快出牌错误
ErrNo.OUT_CARD_TYPE_ERROR = 2010 -- 牌型错误
ErrNo.OUT_CARD_NOT_BIGGER = 2011 -- 没有大于前面牌型
ErrNo.OUT_CARD_MUST_OUT   = 2012 -- 必须出牌

return ErrNo