local EventBus = class("EventBus")

function EventBus:ctor()
    self._events = {}
end

function EventBus:addEventListener(eType, func)
    self._events[eType] = self._events[eType] or {}
    if nil == self._events[eType][func] then
        self._events[eType][func] = func
        return self._events[eType][func]
    end
end

function EventBus:removeEventListener(eType, func)
    if nil ~= self._events[eType] and nil ~= self._events[eType][func] then
        self._events[eType][func] = nil
    end
end

function EventBus:dispatchEvent(eType, eventData)
    if nil ~= self._events[eType] then
        for __, func in pairs(self._events[eType]) do
            local eventData = eventData or {}
            eventData.eType = eType
            func(eventData)
        end
    end
end

cc.exports.EventBus = EventBus.new()