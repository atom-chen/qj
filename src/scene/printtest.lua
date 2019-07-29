local max_msg_num = 20
local msg_table   = {}

function printToScreen(node, msg)
    print('--------------------')
    print(msg)
    print('--------------------')
    msg                       = tostring(msg)
    msg_table[#msg_table + 1] = msg
    if #msg_table > max_msg_num then
        table.remove(msg_table, 1)
    end
    local str = ''
    for i = 1, #msg_table do
        str = str .. msg_table[i] .. '\n'
    end
    print('--------------------')
    print(str)
    print('--------------------')
    local center = node:getChildByName('PrintNode')
    local s      = cc.Director:getInstance():getWinSize()
    if not center then
        center = cc.LabelTTF:create()
        center:setName('PrintNode')
        node:addChild(center, 99999)
        center:setFontSize(32)
        center:setPosition(cc.p(100, s.height - 30))
        center:setAnchorPoint(cc.p(0, 1))
        center:setFontFillColor(cc.c4b(255, 0, 0, 100))
    end
    center:setString(str)
end

local max_msg_num_r = 20
local msg_table_r   = {}

function printToRightScreen(node, msg)
    print('--------------------')
    print(msg)
    print('--------------------')
    msg                           = tostring(msg)
    msg_table_r[#msg_table_r + 1] = msg
    if #msg_table_r > max_msg_num_r then
        table.remove(msg_table_r, 1)
    end
    local str = ''
    for i = 1, #msg_table_r do
        str = str .. msg_table_r[i] .. '\n'
    end
    print('--------------------')
    print(str)
    print('--------------------')
    local center = node:getChildByName('PrintNode_r')
    local s      = cc.Director:getInstance():getWinSize()
    if not center then
        center = cc.LabelTTF:create()
        center:setName('PrintNode_r')
        node:addChild(center, 99999)
        center:setFontSize(32)
        center:setPosition(cc.p(s.width - 200, s.height - 30))
        center:setAnchorPoint(cc.p(0, 1))
        center:setFontFillColor(cc.c4b(0, 0, 255, 100))
    end
    center:setString(str)
end