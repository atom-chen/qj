local PKCommond = {}

-- 手牌间距
PKCommond.handMarginX = 55
-- 手牌宽度（cardWidth * scale）
local handCardWidth = 108
-- 出牌间距
PKCommond.outMarginX = 30
-- 出牌宽度
local outCarWidth = 85

-- 孤度
local des_r = 255
-- 初始高度
local hand_card_height = 63
-- 不同分辨率下控制点的比例
local size = (1280/791)/(g_visible_size.width/g_visible_size.height)

PKCommond.Bezier = {}
PKCommond.BezierContorl = {}

local watcher_lab_pos = {
    [1] = cc.p(g_visible_size.width/2-23, g_visible_size.height/2.26),
    [2] = cc.p(g_visible_size.width-95, g_visible_size.height-126),
    [3] = cc.p(400, g_visible_size.height-126),
}

local baoting_pos = {
    [2] = cc.p(g_visible_size.width-165, g_visible_size.height-130),
    [3] = cc.p(165, g_visible_size.height-130),
}

PKCommond.hand_card_pos = {
    [1] = cc.p((g_visible_size.width-10*50-25)/2, hand_card_height),
    [2] = cc.p(g_visible_size.width-165, g_visible_size.height-145),
    [3] = cc.p(165, g_visible_size.height-145),
}

PKCommond.hand_card_scale = {
    [1] = 0.9,
    [2] = 1,
    [3] = 1,
}

PKCommond.self_hand_card = {}

function PKCommond.getCardById(paramPokerId, showCardBack, isRetro)
    if not showCardBack then
        if paramPokerId >= 78 then
            paramPokerId = paramPokerId - 13
        end
        local color = 4-math.floor(paramPokerId/16)
        if color > 4 or color < 0 then
            commonlib.showLocalTip("花色不正确")
            return
        end
        local value = paramPokerId%16
        if value > 13 or value < 1 then
            commonlib.showLocalTip("牌值不正确")
            return
        end
        local colorImgName ="w"
        if color==1 then
            colorImgName = "S@2x"
        elseif color==2 then
            colorImgName = "H@2x"
        elseif color==3 then
            colorImgName = "C@2x"
        elseif color==4 then
            colorImgName = "D@2x"
        end
        if isRetro then
            return PKCommond.creteNewCard(color, value)
        end
        if color ~= 0 then
            if value == 1 then
                value = "A"
            elseif value == 11 then
                value = "J"
            elseif value == 12 then
                value = "Q"
            elseif value == 13 then
                value = "K"
            end
            local card = cc.Sprite:create("ui/Majiang/pai/"..value..colorImgName..".png")
            return card
        else
            local card = cc.Sprite:create("poker/"..colorImgName..value..".png")
            return card
        end
    else
        if isRetro then
            return PKCommond.creteNewCard(nil, nil, showCardBack)
        end

        local card = cc.Sprite:create("ui/dt_ddz_play/dt_ddz_play_otherCards.png")
        return card
    end
end

function PKCommond.getQuadBezier(origin, control, destination, segments)
    local vertices = {}

    local t = 0.0

    for i = 1, segments-1 do
        vertices[#vertices+1] = {}
        vertices[#vertices].x = (1-t)*(1-t) * origin.x + 2.0*(1-t)*t* control.x + t*t *destination.x
        vertices[#vertices].y = (1-t)*(1-t) * origin.y + 2.0*(1-t)*t* control.y + t*t *destination.y

        local dr = {}
        dr.x = origin.x * 2*(1-t)*(-1)+ 2* control.x * ((1-t) + (-1)*t) + destination.x * 2 * t
        dr.y = origin.y * 2*(1-t)*(-1)+ 2* control.y * ((1-t) + (-1)*t) + destination.y * 2 * t

        vertices[#vertices].r = -math.atan2(dr.y,dr.x)*180/math.pi

        print(vertices[#vertices].x,vertices[#vertices].y,vertices[#vertices].r)

        t = t + 1.0/(segments-1)
    end
    vertices[segments] = {}
    vertices[segments].x = destination.x

    if vertices[1] and vertices[1].r then
        if segments == 2 then
            vertices[1].r = 0
            vertices[2].r = 0
            vertices[1].y = destination.y +30
            vertices[2].y = destination.y +30
        else
            vertices[segments].r = -vertices[1].r
            vertices[segments].y = destination.y
        end

    else
        vertices[segments].r = 0
        vertices[segments].y = destination.y +30
    end

    return vertices
end


function PKCommond.calHandCardPos(playerIndex, totalNum, cardIndex, shape, style2)
    if style2 then
        PKCommond.hand_card_pos[1].y = 130
    else
        PKCommond.hand_card_pos[1].y = 63
    end
    local posX = PKCommond.hand_card_pos[playerIndex].x
    local posY = PKCommond.hand_card_pos[playerIndex].y
    if shape == 'normal' then
        if 1 == playerIndex then
            local totalCardWidth = PKCommond.handMarginX * (totalNum - 1) + handCardWidth
            local iniPosX        = (g_visible_size.width - totalCardWidth) / 2
            posX                 = iniPosX + (cardIndex - 1) * PKCommond.handMarginX + handCardWidth / 2
        end
        return cc.p(posX, posY+20), 0
    else
        if PKCommond.Bezier[totalNum] then
            local Bezier = PKCommond.Bezier[totalNum][cardIndex]
            return cc.p(Bezier.x,Bezier.y) , Bezier.r
        end
        local firstPosX = nil
        local lastPosX  = nil
        if 1 == playerIndex then
            local totalCardWidth = PKCommond.handMarginX * (totalNum - 1) + handCardWidth
            print('牌总宽', totalCardWidth)
            local iniPosX = (g_visible_size.width - totalCardWidth) / 2
            print('牌初始坐标')
            --posX = iniPosX + (cardIndex - 1) * PKCommond.handMarginX + handCardWidth / 2
            firstPosX = iniPosX + (1 - 1) * PKCommond.handMarginX + handCardWidth / 2
            lastPosX  = iniPosX + (totalNum - 1) * PKCommond.handMarginX + handCardWidth / 2
        end
        local controlHeight
        if style2 then
            controlHeight = g_visible_size.height/2 - (des_r + (10 - totalNum)*10)*size + 78
        else
            controlHeight = g_visible_size.height/2 - (des_r + (10 - totalNum)*10)*size
        end
        PKCommond.BezierContorl = cc.p(g_visible_size.width/2, controlHeight)
        local vertices = PKCommond.getQuadBezier(
            cc.p(firstPosX,posY),
            PKCommond.BezierContorl,
            cc.p(lastPosX,posY),
            totalNum)

        PKCommond.Bezier[totalNum] = vertices

        local Bezier = vertices[cardIndex]
        return cc.p(Bezier.x,Bezier.y) , Bezier.r
    end

end

PKCommond.ZhuoBu = {
                "ui/dt_ddz_play/dt_ddz_play_bg4.jpg",
                "ui/dt_ddz_play/de_ddz_play_bg3.jpg",
                "ui/dt_ddz_play/dt_ddz_play_bg_2.jpg"
                }

function PKCommond.setZhuoBu(node, pkZhuoBuIndex)
    local pkzhuobu =  pkZhuoBuIndex or gt.getLocal("int", "pkzhuobu", 1)
    node:loadTexture(PKCommond.ZhuoBu[pkzhuobu])
end

function PKCommond.setOutCardPos(out_card_pos)
    PKCommond.out_card_pos = out_card_pos
end

-- 计算出牌位置
function PKCommond.calOutCarPos(playerIndex, totalNum, cardIndex,is_playback, style2)
    local posX = PKCommond.out_card_pos[playerIndex].y
    local posY = PKCommond.out_card_pos[playerIndex].y
    local totalCardWidth = PKCommond.outMarginX * (totalNum - 1) + outCarWidth
    local iniPosX = 0
    if style2 then
        if 1 == playerIndex then
            iniPosX = (g_visible_size.width - totalCardWidth * 1.25) / 2
            posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX  * 1.25 + outCarWidth / 2
        else
            totalCardWidth = PKCommond.outMarginX * (totalNum - 1) + outCarWidth
            if 2 == playerIndex or 3 == playerIndex then
                iniPosX = PKCommond.out_card_pos[playerIndex].x - totalCardWidth
            elseif 5 == playerIndex or 6 == playerIndex then
                iniPosX = PKCommond.out_card_pos[playerIndex].x
            elseif 4 == playerIndex then
                iniPosX = PKCommond.out_card_pos[playerIndex].x - totalCardWidth / 2
            end
            if not is_playback then
                posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX + outCarWidth / 2
            else
                posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX + outCarWidth / 2 - 80
            end
        end
    else
        if 1 == playerIndex then
            iniPosX = (g_visible_size.width - totalCardWidth) / 2
            posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX  * 1.25 + outCarWidth / 2
        else
            totalCardWidth = PKCommond.outMarginX * (totalNum - 1) + outCarWidth
            iniPosX = PKCommond.out_card_pos[playerIndex].x - totalCardWidth / 2
            if not is_playback then
                posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX + outCarWidth / 2
            else
                posX = iniPosX + (cardIndex - 1) * PKCommond.outMarginX + outCarWidth / 2 - 80
            end
        end
    end
    local desPos = cc.p(posX, posY)
    return desPos
end

function PKCommond.creteNewCard(color, num, showCardBack)
    local colorImgName = "joker"
    if color == 1 then
        colorImgName = "spade"
    elseif color == 2 then
        colorImgName = "heart"
    elseif color == 3 then
        colorImgName = "club"
    elseif color == 4 then
        colorImgName = "diamond"
    end

    local texture  = cc.Director:getInstance():getTextureCache():addImage("ui/qj_zgz/card.png")
    local filePath =  cc.FileUtils:getInstance():fullPathForFilename("ui/qj_zgz/card.json")
    local jsonData = nil
    local f = io.open(filePath, "r")
    local t = f:read("*all")
    f:close()
    jsonData = json.decode(t)
    local cardFrames = nil
    local card       =  nil
    if showCardBack then
        cardFrames = cc.SpriteFrame:createWithTexture(texture, cc.rect(
            jsonData.frames.card_back.x + 5,
            jsonData.frames.card_back.y + 5,
            jsonData.frames.card_back.w - 10,
            jsonData.frames.card_back.h - 10)
        )
        card = cc.Sprite:createWithSpriteFrame(cardFrames)
        card:setScale(0.5)
    else
        cardFrames = cc.SpriteFrame:createWithTexture(texture, cc.rect(
            jsonData.frames[colorImgName .. "_".. num].x,
            jsonData.frames[colorImgName .. "_".. num].y,
            jsonData.frames[colorImgName .. "_".. num].w,
            jsonData.frames[colorImgName .. "_".. num].h)
        )
        card = cc.Sprite:createWithSpriteFrame(cardFrames)
    end

    return card
end

return PKCommond