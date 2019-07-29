local BaseLayer = class("BaseLayer",function()
    return cc.Layer:create()
end)

function BaseLayer:ctor()
    self:enableNodeEvents()
end

function BaseLayer:onEnter()
    self:registerEvent()
end

function BaseLayer:onExit()
    self:unregisterEvent()
end

function BaseLayer:registerEvent()
    local events = {
        {
            eType = EventEnum.RedBagLayer,
            func = handler(self,self.onRefresh),
        },
    }
    for i,v in ipairs(events) do
        EventBus:addEventListener(v.eType, v.func)
    end
    self._events = events
end

function BaseLayer:unregisterEvent()
    for i,v in ipairs(self._events) do
        EventBus:removeEventListener(v.eType, v.func)
    end
end

function BaseLayer:onRefresh(data)
    if not data then
        return
    end
    if self:getName() ~= data.layerName then
        return
    end
    if not data.funcName then
        return
    end
    self[data.funcName](self)
end

return BaseLayer