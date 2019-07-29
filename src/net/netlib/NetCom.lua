local SimpleTCP = require("net.netlib.SimpleTCP")
local ByteArray = require("common.ByteArray")
local scheduler = require("common.scheduler")

NetCom = {}

local PACKET_HEAD_LEN = 2
local PACKET_MESSAGE_ID_LEN = 2
local PACKET_PAYLOAD_LEN = 2
local PACKET_HEADER_LEN = (PACKET_HEAD_LEN + PACKET_MESSAGE_ID_LEN + PACKET_PAYLOAD_LEN)

function NetCom:connect(host, port)
    --print("NetCom:connect",host, port)
    self.simpleTcp = SimpleTCP.new(host,port,function(event,data)
        if event ~= "Data" then
            print("EVENT",event)
        end
        if event == SimpleTCP.EVENT_CONNECTING then
        elseif event == SimpleTCP.EVENT_FAILED then
            self.simpleTcp:close()
            self:_connectFailure()
        elseif event == SimpleTCP.EVENT_CLOSED then
            self:_onClosed()
        elseif event == SimpleTCP.EVENT_CONNECTED then
            self:_onConnected()
        elseif event == SimpleTCP.EVENT_DATA then
            self:_onData(data)
        end
    end)
    self.simpleTcp:connect()
    self._buf = ByteArray.new(ByteArray.ENDIAN_LITTLE)
end

function NetCom:send(protoId, msgTab)
    msgTab = msgTab or {}
    local package = json.encode(msgTab)
    local lenOfPackage = string.len(package)
    -- 对msg部分进行数据加密
    -- 拼接协议号和包体
    package = table.concat({
        string.char(math.floor((lenOfPackage+4) / 256)),
        string.char((lenOfPackage+4) % 256),
        string.char(math.floor(lenOfPackage / 256)),
        string.char(lenOfPackage % 256),
        string.char(math.floor(protoId / 256)),
        string.char(protoId % 256),
        package
    })
    if protoId ~= EventEnum.C2S_RB_HEART then
        -- print(">>>>>>>>>>>>发送协议ID------------->>",EventEnumReverse[protoId],protoId,"长度.....",lenOfPackage)
        -- dump(msgTab)
    end
    self.simpleTcp:send(package)
end

function NetCom:close()
    print("NetCom:close")
    if self.simpleTcp then
        print("self.simpleTcp.close")
        if self.simpleTcp.tcp and self.simpleTcp.tcp.close then
            self.simpleTcp.tcp:close()
        end
        if self.simpleTcp.globalUpdateHandler then
            scheduler.unscheduleGlobal(self.simpleTcp.globalUpdateHandler)
            self.simpleTcp.globalUpdateHandler = nil
        end
    end
end

function NetCom:_parseMessage(msg)
    local msgTab = {}
    local len = 0
    if msg.payload and msg.payload ~= "" then
        len = string.len(msg.payload)
        msgTab = json.decode(msg.payload)
    end
    if msg.id ~= EventEnum.S2C_RB_HEART then
        -- print("<<<<<<<<<<<<<<<接收协议ID-------------<<<",EventEnumReverse[msg.id],msg.id,"长度.....",len)
    end
    EventBus:dispatchEvent(msg.id,msgTab)
end

function NetCom:_parsePackets(byteString)
    local msgs = {}
    local pos = 0
    self._buf:setPos(self._buf:getLen()+1)
    self._buf:writeString(byteString)
    self._buf:setPos(1)
    local flags = nil
    local payloadLen = 0
    local messageId = 0
    local isBroken = nil
    while self._buf:getAvailable() >= PACKET_HEADER_LEN do
        local headStr = self._buf:readString(PACKET_HEADER_LEN)
        local sign1 = string.byte(headStr, 1)
        local sign2 = string.byte(headStr, 2)
        local payloadLen = string.byte(headStr, 3) * 256 + string.byte(headStr, 4)
        local messageId = string.byte(headStr, 5) * 256 + string.byte(headStr, 6)
        local payload1 = math.floor((payloadLen+4)/256)
        local payload2 = math.floor((payloadLen+4)%256)
        if payload1==sign1 and payload2==sign2 then
            if self._buf:getAvailable() < payloadLen then
                self._buf:setPos(self._buf:getPos() - PACKET_HEADER_LEN)
                break
            else
                local msg = {}
                msg.id = messageId
                msg.payload = nil
                if payloadLen > 0 then
                    msg.payload = self._buf:readString(payloadLen)
                end
                msgs[#msgs+1] = msg
            end
        else
            isBroken = true
            break
        end
    end
    if isBroken then
        --TODO
    else
        if self._buf:getAvailable() <= 0 then
            self._buf = ByteArray.new(ByteArray.ENDIAN_LITTLE)
        else
            local tmp = ByteArray.new(ByteArray.ENDIAN_LITTLE)
            self._buf:readBytes(tmp, 1, self._buf:getAvailable())
            self._buf = tmp
        end
    end
    return msgs;
end

function NetCom:_onData(data)
    local msgs = self:_parsePackets(data)
    for i=1,#msgs do
        self:_parseMessage(msgs[i])
    end
end

function NetCom:_onConnected()
    EventBus:dispatchEvent(EventEnum.onRBConnect)
end

function NetCom:_connectFailure()
    EventBus:dispatchEvent(EventEnum.onRBConnectFail)
end

function NetCom:_onClosed()
    EventBus:dispatchEvent(EventEnum.onRBClosed)
end