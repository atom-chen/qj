local RedBagModel = class("RedBagModel", BaseModel)

function RedBagModel:ctor()
	self:reset()
end

function RedBagModel:reset()
    self.hb_info = {}
    self.hb_my = {}
    self.hb_phb = {}
    self.hb_list = {}
    self.hb_lqjl = {}
    self.hb_data = {out_time = '2017-09-12 08:48:56',content = '红包天天乐，红包大放送！'}
    self.user_info = {}
    self.is_valid = false
    self.is_canPlay = {}

    self.config = {
        pyq = "我在秦晋棋牌领取到了%.2f元，888红包等你来领取偶。",
        hy = "财神主动找你了，还在等什么，赶快点我领取红包吧!",
        share_tip = "亲爱的玩家\n\n首次进行红包领取时,需分享链接\n至微信且点击此链接,方可进行红包领取哦。",
    }
end

function RedBagModel:getConf(_name)
    return self.config[_name]
end

function RedBagModel:resetLocal(_isFlush)
    cc.UserDefault:getInstance():setStringForKey("isguided","0")
    if _isFlush then
        cc.UserDefault:getInstance():flush()
    end
end

function RedBagModel:setIsGuided(_bool)
    cc.UserDefault:getInstance():setStringForKey("isguided",_bool and "1" or "0")
    cc.UserDefault:getInstance():flush()
end

function RedBagModel:getIsGuided()
    local isguided = cc.UserDefault:getInstance():getStringForKey("isguided","0")
    return isguided == "1"
end

--红包信息
function RedBagModel:setHBInfo(data)
    self.hb_info = data
    dump(self.hb_info,"self.hb_info")
end

function RedBagModel:getHBInfo()
    return self.hb_info
end

--红包领取记录
function RedBagModel:setHBLqjl(data)
    self.hb_lqjl = data
    dump(self.hb_lqjl,"self.hb_lqjl")
end

function RedBagModel:getHBLqjl()
    return self.hb_lqjl
end

--活动时间及内容请求
function RedBagModel:setHBTime(data)
    self.hb_data = data
    dump(self.hb_data,"self.hb_time")
end

function RedBagModel:getHBTime()
    return self.hb_data
end

--我的红包
function RedBagModel:setHBMy(data)
    self.hb_my = data
    dump(self.hb_my,"self.hb_my")
end

function RedBagModel:getHBMy()
    return self.hb_my
end

--排行榜
function RedBagModel:getHBPhb()
    return self.hb_phb
end

function RedBagModel:setHBPhb(data)
    self.hb_phb = data
    dump(self.hb_phb,"self.hb_phb")
end

function RedBagModel:push(data)
    if #self.hb_list > 10 then
        for k,v in pairs(data.reds) do
            --为了防止存储过多数据 不是本房间 钱少于6块的 不加入广播队列
            if not RoomController:getModel():getInRoomById(v.userId) and v.amount<600 then
                return
            end
        end
    end
    self.hb_list[#self.hb_list+1] = data
    -- dump(self.hb_list,"self.hb_list")
end

function RedBagModel:pop()
    if #self.hb_list > 0 then
        return table.remove(self.hb_list,1)
    end
end

function RedBagModel:setIsValid(b)
    self.is_valid = b
end

function RedBagModel:getIsValid()
    return self.is_valid
end

function RedBagModel:setUserInfo(data)
    for i,v in ipairs(data.userRedInfo) do
        self.user_info[v.userId] = v
    end
    -- dump(self.user_info,"self.user_info======================")
end

function RedBagModel:getUserInfoById(_id)
    return self.user_info[_id] or {userId = _id,roomAmount = 0,sumAmount = 0}
end

--设置红包引导消息
function RedBagModel:setHBPlay(data)
    self.is_canPlay = data
end

--返回红包引导消息
function RedBagModel:getHBPlay()
    return self.is_canPlay
end

return RedBagModel