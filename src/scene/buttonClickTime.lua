local buttonClickTime = class('buttonClickTime')

local buttonClickTimeTable = {}

function buttonClickTime:ctor(startFunc, endFunc, time)
    self.startFunc = startFunc
    self.endFunc   = endFunc
    self.time      = time or 1
end

function buttonClickTime:startTimeSchedule()
    self:closeTimeSchedule()
    if self.startFunc then
        self.startFunc()
    end
    local function startTimeCallBack()
        if self.endFunc then
            self.endFunc()
        end
        self:closeTimeSchedule()
    end
    self.buttonClickTimeSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(startTimeCallBack, self.time, false)

    buttonClickTimeTable[self] = self
end

function buttonClickTime:closeTimeSchedule()
    if self.buttonClickTimeSchedule then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.buttonClickTimeSchedule)
        self.buttonClickTimeSchedule = nil
    end

    buttonClickTimeTable[self] = nil
end

function buttonClickTime.closeButtonClickTimeSchedule(object)
    if buttonClickTimeTable[object] then
        object:closeTimeSchedule()
        buttonClickTimeTable[object] = nil
    end
end

function buttonClickTime.startButtonClickTimeSchedule(startFunc, endFunc, time)
    local newButtonClickTime = buttonClickTime.new(startFunc, endFunc, time)
    newButtonClickTime:startTimeSchedule()

    return newButtonClickTime
end

return buttonClickTime