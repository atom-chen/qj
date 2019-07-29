local NetCmd = {
    C2S_HEARTBEAT = 5,
    S2C_HEARTBEAT = 6,

    C2S_LOGIN     = 11,   -- 登陆
    S2C_LOGIN     = 12,
    C2S_RECONNECT = 13,   -- 重连
    S2C_RECONNECT = 14,
    C2S_REGISTER  = 15,   -- 注册，win32使用
    S2C_REGISTER  = 16,
    S2C_TELLME    = 17,   -- @noused 把通知发送给客户端

    C2S_CHARGE = 18,   -- 充值，由watchdog调用，最终是由充值站点调用
    S2C_CHARGE = 19,

    C2S_LOGDATA     = 20,   -- 得到小局战绩详细信息
    S2C_LOGDATA     = 21,
    S2C_LOGIN_OTHER = 22,   -- 在别的地方登陆通知消息

    C2S_ADD_CARD = 23,   -- web加卡
    S2C_ADD_CARD = 24,

    C2S_SHOP_ORDER  = 25,   -- 购买商品
    S2C_SHOP_ORDER  = 26,   -- 购买商品信息，客户端根据这些信息去实际支付
    C2S_APPLE_TRANS = 27,   -- 苹果支付，购买商品
    S2C_APPLE_TRANS = 28,

    C2S_SHOP        = 30,   -- 客户端请求商城商品信息
    S2C_SHOP        = 31,
    C2S_BIND_INVITE = 32,   -- @noused 绑定邀请码
    S2C_BIND_INVITE = 33,

    C2S_CLOSE_ROOM       = 34,   -- web 关闭房间
    C2S_ACCOUNT_ONLINE   = 35,   -- web 检查玩家是否在线，并将玩家踢下线
    C2S_ONLINE_NUM       = 36,   -- web 在线玩家数
    C2S_CLEAN_EMPTY_LINK = 37,   -- web 清除没有登陆成功的玩家

    C2S_GET_USER_JU         = 40,   -- 大局信息
    S2C_GET_USER_JU         = 41,
    C2S_GET_USER_JU_RECORDS = 42,   -- 大局中的所有小局信息
    S2C_GET_USER_JU_RECORDS = 43,

    C2S_GET_ROOM_LIST_BYID = 50,   -- @noused 得到亲友圈中所有房间
    S2C_GET_ROOM_LIST_BYID = 51,
    C2S_CLUB_CLOSE_ROOM    = 52,   -- @noused关闭亲友圈房间
    S2C_CLUB_CLOSE_ROOM    = 53,
    S2C_ROOM_STATUS        = 54,   -- 同步房间状态
    C2S_GET_CLUB_LIST      = 55,   -- 得到玩家的所有亲友圈
    S2C_GET_CLUB_LIST      = 56,
    S2C_CLUB_ADD_ROOM      = 57,   -- 添加亲友圈房间

    C2S_CLUB_USER_LIST     = 58,   -- 亲友圈玩家列表
    S2C_CLUB_USER_LIST     = 59,
    C2S_CLUB_ADD_BIND_USER = 60,   -- 添加玩家
    S2C_CLUB_ADD_BIND_USER = 61,
    C2S_CLUB_DEL_BIND_USER = 62,   -- 亲友圈删除玩家, 包括群主踢人和玩家主动退出
    S2C_CLUB_DEL_BIND_USER = 63,
    C2S_CLUB_FIND_USER     = 64,   -- 查找玩家
    S2C_CLUB_FIND_USER     = 65,
    C2S_CLUB_VIP_LIST      = 66,   -- 亲友圈战绩列表
    S2C_CLUB_VIP_LIST      = 67,
    C2S_CLUB_BROAD_CAST    = 68,   -- @noused亲友圈广播
    S2C_CLUB_BROAD_CAST    = 69,
    C2S_CLUB_MODIFY        = 70,   -- 修改亲友圈: 如亲友圈名字，相关开关
    S2C_CLUB_MODIFY        = 71,
    C2S_CLUB_TIREN         = 72,   -- @noused 踢人
    S2C_CLUB_TIREN         = 73,
    C2S_CLUB_ADD_ROOM      = 74,   -- 添加房间

    C2S_CLUB_FIND_BYID = 75,   -- @noused 查找亲友圈
    S2C_CLUB_FIND_BYID = 76,

    C2S_CLUB_APPLY_JOIN     = 77,   -- 申请加入亲友圈
    S2C_CLUB_APPLY_JOIN     = 78,
    C2S_CLUB_GET_APPLY_LIST = 79,   -- 得到申请加入亲友圈玩家列表
    S2C_CLUB_GET_APPLY_LIST = 80,
    C2S_CLUB_DO_APPLY       = 81,   -- 同意玩家加入亲友圈
    S2C_CLUB_DO_APPLY       = 82,

    C2S_CLUB_RED_HOT  = 83,   -- @noused 亲友圈红点消息: 有玩家申请或者有申请被同意
    S2C_CLUB_RED_HOT  = 84,   -- @noused id_list = {1,2} 代表申请消息
    C2S_CLUB_MSG      = 85,   -- @noused 广播亲友圈消息
    S2C_CLUB_MSG      = 86,
    C2S_CLUB_MSG_LIST = 87,   -- @noused 得到亲友圈聊天消息
    S2C_CLUB_MSG_LIST = 88,

    C2S_CLUB_LOG            = 800,   -- 得到亲友圈日志
    S2C_CLUB_LOG            = 801,
    C2S_CLUB_RANK           = 802,   -- 得到亲友圈排行榜
    S2C_CLUB_RANK           = 803,
    C2S_CLUB_RANK_DETAIL    = 804,   -- 得到亲友圈排行榜某个玩家详情
    S2C_CLUB_RANK_DETAIL    = 805,
    C2S_CLUB_JIESAN_ROOM    = 806,   -- 解散亲友圈房间
    S2C_CLUB_JIESAN_ROOM    = 807,
    C2S_CLUB_IDLE_PLAYERS   = 808,   -- 得到空闲玩家
    S2C_CLUB_IDLE_PLAYERS   = 809,
    S2C_CLUB_CHANGE_ROOM    = 810,   -- 修改玩法
    S2C_CLUB_SYNC_CARD      = 811,   -- 同步亲友圈房卡
    C2S_CLUB_ADD_CARD       = 812,   -- web加亲友圈卡
    C2S_CLUB_INVITE_PLAY    = 813,   -- 邀请进入房间游戏
    S2C_CLUB_INVITE_PLAY    = 814,
    C2S_CLUB_TIME_CARD      = 815,   -- web加时间卡
    C2S_CLUB_AGENT_BIND_UID = 816,   -- web代理请求绑定id
    C2S_CLUB_UID_BIND_AGENT = 817,   -- 用户同意绑定代理
    C2S_CLUB_EXCHANGE_CARD  = 818,   -- 亲友圈房卡交换
    S2C_CLUB_EXCHANGE_CARD  = 819,
    C2S_CLUB_ROOM_STATUS    = 820,   -- 得到亲友圈状态
    S2C_CLUB_ROOM_STATUS    = 821,
    C2S_CLUB_USER_TYPE      = 822,   -- 设置亲友圈成员类型
    S2C_CLUB_USER_TYPE      = 823,
    C2S_CLUB_MODIFY_WEB     = 824,   -- web 修改亲友圈信息

    C2S_GET_TJ_DATA   = 89,   -- 获取推荐数据
    S2C_GET_TJ_DATA   = 90,
    C2S_GET_TJ_CARD   = 91,   -- 领取推荐奖励
    S2C_GET_TJ_CARD   = 92,
    C2S_SET_USER_ICON = 93,   -- icon:1-6
    S2C_SET_USER_ICON = 94,

    C2S_SET_FREE_MODE = 95,   -- 自由场扣卡模式
    S2C_SET_FREE_MODE = 96,

    C2S_SYNC_CLUB_NOTIFY = 97,   -- @noused
    S2C_SYNC_CLUB_NOTIFY = 98,   -- 亲友圈通知消息。 tag: 1 申请同意；2 申请拒绝；3 管理员踢出, 4 有玩家申请, 5 有代理请求绑定, 6 创建亲友圈

    C2S_BOARD_ACTIVITY = 99,   -- 弹窗活动信息提交
    S2C_BOARD_ACTIVITY = 100,

    C2S_GAME_ROOM_SERVER = 101,  -- 生成唯一房间号
    S2C_GAME_ROOM_SERVER = 102,
    S2C_JOIN_ROOM_SERVER = 103,

    -- 通用C2s加入房间
    C2S_JOIN_ROOM       = 104,
    C2S_JOIN_ROOM_AGAIN = 105,

    -- 麻将S2C加入房间
    S2C_MJ_JOIN_ROOM       = 107,
    S2C_MJ_JOIN_ROOM_AGAIN = 109,

    C2S_GET_RED_PACK = 110,   -- 领取红包
    S2C_GET_RED_PACK = 111,

    -- 推倒胡麻将
    C2S_MJ_TDH_CREATE_ROOM = 150,
    S2C_MJ_TDH_CREATE_ROOM = 151,

    -- 抠点麻将
    C2S_MJ_KD_CREATE_ROOM = 152,
    S2C_MJ_KD_CREATE_ROOM = 153,

    -- 西安麻将
    C2S_MJ_XIAN_CREATE_ROOM = 154,
    S2C_MJ_XIAN_CREATE_ROOM = 155,

    -- 立四麻将
    C2S_MJ_LISI_CREATE_ROOM = 156,
    S2C_MJ_LISI_CREATE_ROOM = 157,

    -- 拐三角麻将
    C2S_MJ_GSJ_CREATE_ROOM = 158,
    S2C_MJ_GSJ_CREATE_ROOM = 159,

    -- 晋中麻将
    C2S_MJ_JZ_CREATE_ROOM = 160,
    S2C_MJ_JZ_CREATE_ROOM = 161,

    -- 晋中拐三角
    C2S_MJ_JZGSJ_CREATE_ROOM = 162,
    S2C_MJ_JZGSJ_CREATE_ROOM = 163,

    -- 河北麻将
    C2S_MJ_HEBEI_CREATE_ROOM = 164,
    S2C_MJ_HEBEI_CREATE_ROOM = 165,

    -- 河北推倒胡麻将
    C2S_MJ_HBTDH_CREATE_ROOM = 166,
    S2C_MJ_HBTDH_CREATE_ROOM = 167,

    -- 保定打八张麻将
    C2S_MJ_BDDBZ_CREATE_ROOM = 168,
    S2C_MJ_BDDBZ_CREATE_ROOM = 169,

    -- 丰宁麻将
    C2S_MJ_FN_CREATE_ROOM = 170,
    S2C_MJ_FN_CREATE_ROOM = 171,

    C2S_PDK_CREATE_ROOM     = 201,
    S2C_PDK_CREATE_ROOM     = 202,
    S2C_PDK_JOIN_ROOM       = 203,
    S2C_PDK_JOIN_ROOM_AGAIN = 204,
    S2C_PDK_TABLE_USER_INFO = 205,
    S2C_PDK_GAME_STATUS     = 207,
    S2C_PDK_GAME_INFO       = 208,
    S2C_PDK_GAME_START      = 209,
    C2S_PDK_OUT_CARD        = 210,
    S2C_PDK_OUT_CARD        = 211,
    S2C_PDK_RESULT          = 212,

    C2S_ZGZ_CREATE_ROOM     = 221,
    S2C_ZGZ_CREATE_ROOM     = 222,
    S2C_ZGZ_JOIN_ROOM       = 223,
    S2C_ZGZ_JOIN_ROOM_AGAIN = 224,
    S2C_ZGZ_GAME_START      = 225,
    C2S_ZGZ_SHUO_HUA        = 226,
    S2C_ZGZ_SHUO_HUA        = 227,

    C2S_OPER_OTHER = 228, -- 玩法中，不是通用的其他操作，统一使用这个，通过type来区分不同操作类型
    S2C_OPER_OTHER = 229,

    C2S_TUOGUAN = 296, -- 托管。 tag:  true 托管;  false 取消托管
    S2C_TUOGUAN = 297,

    C2S_ROOM_CHAT_BQ = 298,  -- 表情
    S2C_ROOM_CHAT_BQ = 299,

    S2C_TABLE_USER_INFO = 300,
    S2C_GAME_STATUS     = 302,
    S2C_GAME_INFO       = 303,
    S2C_GAME_START      = 304,
    S2C_CALL_SCORE      = 305,
    S2C_SHOW_BANKER     = 306,
    S2C_OUT_CARD        = 307,
    S2C_RESULT          = 308,

    -- public
    C2S_SITE_DOWN          = 309,
    S2C_SITE_DOWN          = 310,
    C2S_READY              = 311,
    S2C_READY              = 312,
    C2S_ROOM_CHAT          = 315,
    S2C_ROOM_CHAT          = 316,
    C2S_LEAVE_ROOM         = 317,  -- 房主在设置中点击解散房间或者其它玩家点击任何地方的解散房间
    S2C_LEAVE_ROOM         = 318,
    C2S_JIESAN             = 319,  -- 房主在房间界面点击解散房间
    S2C_JIESAN             = 320,
    C2S_APPLY_JIESAN       = 321,
    S2C_APPLY_JIESAN       = 322,
    C2S_APPLY_JIESAN_AGREE = 323,
    S2C_APPLY_JIESAN_AGREE = 324,
    C2S_PASS               = 325,
    S2C_PASS               = 326,

    S2C_OUT_LINE = 330,
    S2C_IN_LINE  = 331,

    C2S_DDZ_CREATE_ROOM     = 335,
    S2C_DDZ_CREATE_ROOM     = 336,
    S2C_DDZ_JOIN_ROOM       = 337,
    S2C_DDZ_JOIN_ROOM_AGAIN = 338,
    S2C_DDZ_TABLE_USER_INFO = 339,
    S2C_DDZ_COOL_DOWN       = 340,
    C2S_DDZ_CALL_SCORE      = 341,
    S2C_DDZ_CALL_SCORE      = 342,
    S2C_DDZ_SHOW_BANKER     = 343,
    C2S_DDZ_OUT_CARD        = 344,
    S2C_DDZ_OUT_CARD        = 345,
    S2C_DDZ_RESULT          = 346,
    S2C_DDZ_GAME_START      = 347,

    C2S_DDZ_CALL_HOST  = 332,
    S2C_DDZ_CALL_HOST  = 333,
    C2S_DDZ_QIANG_HOST = 348,
    S2C_DDZ_QIANG_HOST = 349,
    C2S_DDZ_JIABEN     = 703,
    S2C_DDZ_JIABEN     = 704,

    S2C_MJ_TABLE_USER_INFO = 350,
    S2C_MJ_GAME_STATUS     = 352,
    S2C_MJ_GAME_INFO       = 353,
    S2C_MJ_GAME_START      = 354,
    S2C_MJ_COOL_DOWN       = 358,
    C2S_MJ_OUT_CARD        = 359,
    S2C_MJ_OUT_CARD        = 360,
    S2C_MJ_DRAW_CARD       = 361,
    C2S_MJ_PENG            = 362,
    S2C_MJ_PENG            = 363,
    C2S_MJ_GANG            = 364,
    S2C_MJ_GANG            = 365,
    C2S_MJ_CHI_CARD        = 366,
    S2C_MJ_CHI_CARD        = 367,
    C2S_MJ_CHI_HU          = 368,
    S2C_MJ_CHI_HU          = 369,
    C2S_MJ_HU              = 370,
    S2C_MJ_HU              = 371,
    C2S_MJ_BBHU            = 372,
    S2C_MJ_BBHU            = 373,
    C2S_MJ_DO_PASS_HU      = 374,
    S2C_MJ_DO_PASS_HU      = 375,
    S2C_MJ_SEND_BBHU_DATA  = 380,
    C2S_MJ_KAIGANG         = 381,
    S2C_MJ_KAIGANG         = 382,
    S2C_MJ_NEED_HAIDI      = 383,
    C2S_MJ_HAIDI           = 384,
    S2C_MJ_HAIDI           = 385,
    S2C_MJ_NIAO            = 386,
    C2S_MJ_QIPAI           = 387,
    S2C_MJ_QIPAI           = 388,
    S2C_MJ_OVER            = 399,
    S2C_NO_ACTION          = 400,
    C2S_MJ_TINGPAI         = 401,
    S2C_MJ_TINGPAI         = 402,
    C2S_MJ_KOUPAI          = 403,  -- 扣牌
    S2C_MJ_KOUPAI          = 404,

    S2C_LOAD_USER_DATA    = 500,  -- 同步所有user schema数据
    S2C_SYNC_USER_DATA    = 501,  -- 同步单个user schema数据
    C2S_SMS_GET_CODE      = 502,  -- 请求手机验证码
    S2C_SMS_GET_CODE      = 503,
    C2S_SMS_BIND          = 504,  -- 绑定手机
    S2C_SMS_BIND          = 505,
    C2S_APPLY_START       = 506,  -- 申请立即开局
    S2C_APPLY_START       = 507,
    C2S_APPLY_START_AGREE = 508,  -- 申请立即开局同意结果
    S2C_APPLY_START_AGREE = 509,

    C2S_RANK    = 601,
    S2C_RANK    = 602,
    S2C_HUODONG = 603,
    S2C_BROAD   = 604,
    C2S_BROAD   = 605,
    S2C_QUNZHU  = 606,

    C2S_INFO     = 607,  -- 玩家所有任务，包括系统任务和玩家私人任务
    S2C_INFO     = 608,
    C2S_INFO_MAX = 609,  -- 得到玩家是不是有新的任务或者得到玩家亲友圈信息或者删除亲友圈
    S2C_INFO_MAX = 610,

    C2S_GET_INFO_REWARD = 611,
    S2C_GET_INFO_REWARD = 612,

    C2S_NOTICE = 613,  -- 登录时的通知消息
    S2C_NOTICE = 614,

    C2S_ZHUANPAN      = 900,
    S2C_ZHUANPAN      = 901,
    C2S_BIND_ACCOUNT  = 902,
    S2C_BIND_ACCOUNT  = 903,
    C2S_ZHUANPAN_DATA = 904,
    S2C_ZHUANPAN_DATA = 905,
    C2S_ZHUANPAN_GIFT = 906,
    S2C_ZHUANPAN_GIFT = 907,

    -- 邮件协议
    S2C_ADD_MAILS  = 1001,
    C2S_SEND_MAILS = 1002,
    S2C_SEND_MAILS = 1003,

    -- 聊天协议
    C2S_WORLD_CAHT = 1051,
    S2C_WORLD_CAHT = 1052,

    C2S_BIND_APPID = 1061,
    S2C_BIND_APPID = 1062,

    C2S_HUO_DONG_NOTIFY = 1070, -- 活动通知
    S2C_HUO_DONG_NOTIFY = 1071,
}

return NetCmd