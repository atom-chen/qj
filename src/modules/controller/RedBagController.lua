local scheduler = require("common.scheduler")

local RedBagController = {}

function RedBagController:getModel()
	return PlayerManager:getModel("RedBag")
end

function RedBagController:registerEventListener()
    -- if self.registed then return end
    -- self.registed = true
	local CUSTOM_LISTENERS = {
        ["req_redbag_info"]               = handler(self, self.resRedBagInfo),
        ["req_redbag_lqjl"]               = handler(self, self.resRedBagLqjl),
        ["req_redbag_time"]               = handler(self, self.resRedBagTime),
        ["req_redbag_my"]                 = handler(self, self.resRedBagMy),
        ["req_redbag_phb"]                = handler(self, self.resRedBagPhb),
        ["req_redbag_notice_php"]         = handler(self, self.resRedBagNoticePhp),
    }
    for k, v in pairs(CUSTOM_LISTENERS) do
        gt.addCustomEventListener(k, v)
    end
end

function RedBagController:unregisterEventListener()
    local LISTENER_NAMES = {
        ["req_redbag_info"]               = handler(self, self.resRedBagInfo),
        ["req_redbag_lqjl"]               = handler(self, self.resRedBagLqjl),
        ["req_redbag_time"]               = handler(self, self.resRedBagTime),
        ["req_redbag_my"]                 = handler(self, self.resRedBagMy),
        ["req_redbag_phb"]                = handler(self, self.resRedBagPhb),
        ["req_redbag_notice_php"]         = handler(self, self.resRedBagNoticePhp),
    }
    for k, v in pairs(LISTENER_NAMES) do
        cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(k)
    end
end

function RedBagController:registerEvent()
    local events = {
        {
            eType = EventEnum.S2C_RB,
            func = handler(self,self.S2C_RB),
        },
        {
            eType = EventEnum.S2C_RB_VALID,
            func = handler(self,self.S2C_RB_VALID),
        },
        {
            eType = EventEnum.S2C_RB_INFO,
            func = handler(self,self.S2C_RB_INFO),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function RedBagController:unregisterEvent()
    for i,v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function RedBagController:S2C_RB(rtn_msg)
    self:getModel():push(rtn_msg)
end

function RedBagController:S2C_RB_VALID(rtn_msg)
    self:getModel():setIsValid(tonumber(rtn_msg.isValid) == 1)
end

function RedBagController:S2C_RB_INFO(rtn_msg)
    self:getModel():setUserInfo(rtn_msg)
end

--红包引导信息
function RedBagController:setHBPlay(rtn_msg)
    self:getModel():setHBPlay(rtn_msg)
end

--红包引导播放
function RedBagController:HBPlay()
    local data = self:getModel():getHBPlay()
    if data and data.code == 0 then
        if data.read == 0 then  --新用户红包引导动画
            self:getModel():setIsGuided(true)
            return true
        end
    end
    return false
end

--红包信息
function RedBagController:reqRedBagInfo()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_info",url,{
        cmd = 120,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
    })
end

function RedBagController:resRedBagInfo(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            self:getModel():setHBInfo(data)
            EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "refreshHBInfo"})
        elseif data.code == -1 then
            print("获取红包数量请求 缺少参数")
        end
    end
end

--红包领取记录
function RedBagController:reqRedBagLqjl()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_lqjl",url,{
        cmd = 121,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
        status = 1,
        page = 1,
    })
end

function RedBagController:resRedBagLqjl(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            self:getModel():setHBLqjl(data.data)
            -- EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "refreshHBLqjl"})
        elseif data.code == -1 then
            print("领取记录请求 缺少参数")
        end
    end
end

--活动时间及内容请求
function RedBagController:reqRedBagTime()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_time",url,{
        cmd = 123,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
    })
end

function RedBagController:resRedBagTime(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    -- dump("RedBagController:resRedBagTime===",rtn_msg,10)
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            self:getModel():setHBTime(data)
            EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "refreshHBGuiZe"})
        elseif data.code == -1 then
            print("活动时间及内容请求 缺少参数")
        else
            print("code错误")
        end
    end
end

--我的红包
function RedBagController:reqRedBagMy()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_my",url,{
        cmd = 121,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
        status = 2,
        page = 0,
    })
end

function RedBagController:resRedBagMy(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            self:getModel():setHBMy(data.data)
            EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "refreshHBMy"})
        elseif data.code == -1 then
            print("缺少参数")
        elseif data.code == -2 then
            print("没有红包记录")
        end
    end
end

--排行榜
function RedBagController:reqRedBagPhb()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_phb",url,{
        cmd = 122,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
    })
end


function RedBagController:resRedBagPhb(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            self:getModel():setHBPhb(data)
            EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "refreshHBPhb"})
        elseif data.code == -1 then
            print("排行榜请求 缺少参数")
        end
    end
end

--分享成功通知后台
function RedBagController:reqRedBagNoticePhp()
    local url = gt.getConf("redbag_url")
    gt.reqHttpGet("req_redbag_notice_php",url,{
        cmd = 124,
        app_id = gt.getConf("redbag_appid"),
        uid = AccountController:getModel():getId(),
    })
end

function RedBagController:resRedBagNoticePhp(rtn_msg)
    if not rtn_msg or rtn_msg == "" then
        return
    end
    local data = json.decode(rtn_msg)
    if data then
        if data.code == 0 then
            EventBus:dispatchEvent(EventEnum.RedBagLayer,{layerName = "RedBagLayer",funcName = "sharedSuccess"})
        end
    end
end

function RedBagController:connect()
    local close_redbag = gt.getConf("close_redbag")
    if close_redbag then return end
    local redbag_server = gt.getConf("redbag_server")
    local serverList = string.split(redbag_server,"@")
    local ser = serverList[math.random(1,#serverList)]
    local tab = string.split(ser,":")
    RedBagClient:connect(tab[1],tonumber(tab[2]))
end

cc.exports.RedBagController = RedBagController