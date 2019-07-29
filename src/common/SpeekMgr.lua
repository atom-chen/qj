--
-- Author: chenglong
-- Date: 2017-03-25 14:50:02
--

local NativeUtil = require("common.NativeUtil")

local javaClassName = "com/ems358/tfaudiomanager/TFAudioManager"

local SpeekMgr = class("SpeekMgr")

function SpeekMgr:ctor()
    self.isRecording  = false
    self.speekTime    = 0
    self.isForeground = true
end

function SpeekMgr:setSpeekTime()
    self.speekTime = os.clock()
end

function SpeekMgr:getSpeekTime()
    return self.speekTime
end

function SpeekMgr:setRecording(_bool)
    self.isRecording = _bool
end

function SpeekMgr:getRecording()
    return self.isRecording
end

function SpeekMgr:addDelegate()
    local function recordCallback(_data)
        local info = _data
        if device.platform == "android" then
            info = json.decode(_data)
        end
        dump(info, "recordCallback")
        if not info or (not info.Event) then
            return
        end
        if info.Event == "OnRecordStart" then
            EventBus:dispatchEvent(EventEnum.onRecordStart)
        elseif info.Event == "OnRecordStop" then
            --[[
                Param = {
                    Url,         录音完成后可以在语音服务器上下载的语音地址
                    BCancel,     是否是取消录音 1 是 0 否
                }
            ]]
            EventBus:dispatchEvent(EventEnum.onRecordStop, info)
        elseif info.Event == "OnRecordTimeOut" then
            -- cc.vv.log("录音超时")
            EventBus:dispatchEvent(EventEnum.onRecordTimeOut)
        elseif info.Event == "OnRecordFaild" then
            -- cc.vv.log("录音失败")
            EventBus:dispatchEvent(EventEnum.onRecordFaild)
        elseif info.Event == "OnWillPlay" then
            EventBus:dispatchEvent(EventEnum.onWillPlay, info)
        elseif info.Event == "OnPlayStop" then
            EventBus:dispatchEvent(EventEnum.onPlayStop, {mType = "speex"})
        end
    end
    self:setDelegate(recordCallback)
end

function SpeekMgr:removeDelegate()
    local function recordCallback(_data)

    end
    self:setDelegate(recordCallback)
end

function SpeekMgr:setDelegate(_callback)
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "setDelegate"
        local javaParams = {
            _callback,
        }
        local javaMethodSig = "(I)V"
        local luaj          = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        -- 如果采用之前的新语言已经ios审核通过，则目前不写这个if判断。
        local data = {
            delegate = function(info)
                -- 添加保护
                pcall(function()
                    _callback(info)
                end)
            end,
        }
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "setDelegate", data)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        else
            -- ShowTip("初始化录音失败")
        end
    end
end

function SpeekMgr:startRecord()
    print("SpeekMgr:startRecord")
    if not NativeUtil:getAbility("speex") then return end
    local roomid = 100000
    if device.platform == "android" then
        local javaMethodName = "startRecord"
        local data = {
            userid = "" .. gt.getData("uid"),
            token  = "123456",
            appid  = "8",
            roomid = "" .. roomid,
            url    = gt.getConf("voice_url"),
        }
        local jsonData = json.encode(data)
        local javaParams = {
            jsonData,
        }
        local javaMethodSig = "(Ljava/lang/String;)V"
        local luaj          = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local data = {
            userid = "" .. gt.getData("uid"),
            token  = "123456",
            appid  = "8",
            roomid = "" .. roomid,
            url    = gt.getConf("voice_url"),
        }
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "startRecord", data)
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:cancelRecord()
    print("SpeekMgr:cancelRecord")
    if not NativeUtil:getAbility("speex") then return end
    self.speekTime = 0
    if device.platform == "android" then
        local javaMethodName = "cancelRecord"
        local javaParams     = {}
        local javaMethodSig  = "()V"
        local luaj           = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "cancelRecord")
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:stopRecord()
    print("SpeekMgr:stopRecord")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "stopRecord"
        local javaParams     = {}
        local javaMethodSig  = "()V"
        local luaj           = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "stopRecord")
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:addPlay(_url)
    print("SpeekMgr:addPlay")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "addPlay"
        local data = {
            url = _url,
        }
        local jsonData = json.encode(data)
        local javaParams = {
            jsonData,
        }
        local javaMethodSig = "(Ljava/lang/String;)V"
        local luaj          = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local data = {
            url = _url,
        }
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "addPlay", data)
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:passPlay()
    print("SpeekMgr:passPlay")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "passPlay"
        local javaParams     = {}
        local javaMethodSig  = "()V"
        local luaj           = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "passPlay")
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:stopPlay()
    print("SpeekMgr:stopPlay")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "stopPlay"
        local javaParams     = {}
        local javaMethodSig  = "()V"
        local luaj           = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "stopPlay")
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:cleanPlaysCache()
    print("SpeekMgr:cleanPlaysCache")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "cleanPlaysCache"
        local javaParams     = {}
        local javaMethodSig  = "()V"
        local luaj           = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then
            -- cc.vv.abilityMgr:setNewRecord(true)
        end
    elseif device.platform == "ios" then
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "cleanPlaysCache")
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

function SpeekMgr:playOneLast(_userid)
    print("SpeekMgr:playOneLast")
    if not NativeUtil:getAbility("speex") then return end
    if device.platform == "android" then
        local javaMethodName = "playOneLast"
        local data = {
            userid = "" .. _userid,
        }
        local jsonData = json.encode(data)
        local javaParams = {
            jsonData,
        }
        local javaMethodSig = "(Ljava/lang/String;)V"
        local luaj          = require("cocos.cocos2d.luaj")
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if ok then

        end
    elseif device.platform == "ios" then
        local data = {
            userid = _userid,
        }
        local luaoc = require("cocos.cocos2d.luaoc")
        local ok, ret = luaoc.callStaticMethod("TFAudioManager", "playOneLast", data)
        if not ok then
            -- ShowTip(cc.vv.TipMsg.Msg_57)
        end
    end
end

cc.exports.SpeekMgr = SpeekMgr.new()