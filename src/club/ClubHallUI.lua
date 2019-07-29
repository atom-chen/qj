require('scene.ColorDef')

-- 经典UI
ClubHallUIDefault = class('ClubHallUIDefault')
ClubHallUIDefault.csb_file = 'ui/club_hall.csb'
-- ClubHallUIDefault.csb_club_log = 'ui/club_log.csb'
-- ClubHallUIDefault.csb_club_member = 'ui/club_member.csb'
-- ClubHallUIDefault.csb_club_agent_bind_dialog = 'ui/club_agent_bind_dialog.csb'
-- ClubHallUIDefault.csb_club_faka_shuoming = 'ui/club_faka_shuoming.csb'
-- ClubHallUIDefault.csb_club_invite_dialog = 'ui/club_invite_dialog.csb'
-- ClubHallUIDefault.csb_club_notice = 'ui/club_notice.csb'
-- ClubHallUIDefault.csb_club_rank = 'ui/club_rank.csb'
-- ClubHallUIDefault.csb_club_rank_person = 'ui/club_rank_person.csb'
-- ClubHallUIDefault.csb_club_rank_consume = 'ui/club_rank_consume.csb'
-- ClubHallUIDefault.csb_club_rename_club = 'ui/club_rename_club.csb'
-- ClubHallUIDefault.csb_club_reset_ways = 'ui/club_reset_ways.csb'
-- ClubHallUIDefault.csb_club_setting = 'ui/club_setting.csb'
ClubHallUIDefault.csb_club_shuo_ming_node = 'ui/club_shuo_ming_node.csb'
-- ClubHallUIDefault.csb_club_dialog = 'ui/club_dialog.csb'
-- ClubHallUIDefault.csb_club_zhanji = 'ui/club_zhanji.csb'

ClubHallUIDefault.csb_club_log = 'ui/club_log_new_year.csb'
ClubHallUIDefault.csb_club_member = 'ui/club_member_new_year.csb'
ClubHallUIDefault.csb_club_agent_bind_dialog = 'ui/club_agent_bind_dialog_new_year.csb'
ClubHallUIDefault.csb_club_faka_shuoming = 'ui/club_faka_shuoming_new_year.csb'
ClubHallUIDefault.csb_club_invite_dialog = 'ui/club_invite_dialog_new_year.csb'
ClubHallUIDefault.csb_club_notice = 'ui/club_notice_new_year.csb'
ClubHallUIDefault.csb_club_rank = 'ui/club_rank_new_year.csb'
ClubHallUIDefault.csb_club_rank_person = 'ui/club_rank_person_new_year.csb'
ClubHallUIDefault.csb_club_rank_consume = 'ui/club_rank_consume_new_year.csb'
ClubHallUIDefault.csb_club_rename_club = 'ui/club_rename_club_new_year.csb'
ClubHallUIDefault.csb_club_reset_ways = 'ui/club_reset_ways_new_year.csb'
ClubHallUIDefault.csb_club_setting = 'ui/club_setting_new_year.csb'
ClubHallUIDefault.csb_club_dialog = 'ui/club_dialog_new_year.csb'
ClubHallUIDefault.csb_club_zhanji = 'ui/club_zhanji_new_year.csb'
ClubHallUIDefault.csb_club_jiesanroom_dialog = 'ui/club_jiesanroom_dialog_new_year.csb'
ClubHallUIDefault.csb_club_create_join = 'ui/club_create_join.csb'
ClubHallUIDefault.csb_club_charge = 'ui/club_charge_new_year.csb'

ClubHallUIDefault.ModifyBg = "ui/qj_club/dt_clubroom_xiugaiwanfa1.png"
ClubHallUIDefault.DiscardBg = "ui/qj_club/dt_clubroom_jiesan1.png"
ClubHallUIDefault.NoOpertorBg = "ui/qj_club/NoOpertorBg.png"
ClubHallUIDefault.ClubRoomItemBg = 'ui/qj_club/dt_clubroom_itemBg.png'
ClubHallUIDefault.ClubRoomItemPlayingBg = 'ui/qj_club/dt_clubroom_yijinru.png'
ClubHallUIDefault.nameToImg = {
    club = "ui/qj_club/dt_clubroom_club.png",
    log = "ui/qj_club/dt_clubroom_record.png",
    rank = "ui/qj_club/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club/dt_clubroom_quickin.png",
    friend = "ui/qj_club/dt_clubroom_member.png",
    ways = "ui/qj_club/dt_clubroom_play.png",
}

ClubHallUIDefault.nameToImgPress = {
    club = "ui/qj_club/dt_clubroom_club1.png",
    log = "ui/qj_club/dt_clubroom_record1.png",
    rank = "ui/qj_club/dt_clubroom_rank1.png",
    quckjoin ="ui/qj_club/dt_clubroom_quickin1.png",
    friend = "ui/qj_club/dt_clubroom_member1.png",
    ways = "ui/qj_club/dt_clubroom_play1.png",
}

ClubHallUIDefault.topClubNameItemBg = {
    left = "ui/qj_club/dt_clubroom_biaoqianbg_0.png",
    mid = "ui/qj_club/dt_clubroom_biaoqianbg_1.png",
    right = "ui/qj_club/dt_clubroom_biaoqianbg_2.png",
}

ClubHallUIDefault.topClubNameItemPressBg = {
    left = "ui/qj_club/dt_clubroom_biaoqianbg_0.png",
    mid = "ui/qj_club/dt_clubroom_biaoqianbg_1.png",
    right = "ui/qj_club/dt_clubroom_biaoqianbg_2.png",
}

ClubHallUIDefault.topHLClubNameItemBg = {
    left = "ui/qj_club/dt_clubroom_biaoqian_0.png",
    mid = "ui/qj_club/dt_clubroom_biaoqian_1.png",
    right = "ui/qj_club/dt_clubroom_biaoqian_2.png",
}

ClubHallUIDefault.topHLClubNameItemPressBg = {
    left = "ui/qj_club/dt_clubroom_biaoqian_0.png",
    mid = "ui/qj_club/dt_clubroom_biaoqian_1.png",
    right = "ui/qj_club/dt_clubroom_biaoqian_2.png",
}

-- 高度对齐长度
ClubHallUIDefault.HeightAlign3Ren = 70
ClubHallUIDefault.HeightAlign4Ren = 80
ClubHallUIDefault.HeightAlign5Ren = 70
-- 高度缩放系统
ClubHallUIDefault.HeightScale3Ren = 1
ClubHallUIDefault.HeightScale4Ren = 0.8
ClubHallUIDefault.HeightScale5Ren = 0.7

ClubHallUIDefault.RoomItemHeight3R = 420
ClubHallUIDefault.RoomItemHeight4R = 350
ClubHallUIDefault.RoomItemHeight5R = 300

ClubHallUIDefault.RoomItemScale3R = 1
ClubHallUIDefault.RoomItemScale4R = 0.8
ClubHallUIDefault.RoomItemScale5R = 0.7

ClubHallUIDefault.RoomFirstPosX3R = 55
ClubHallUIDefault.RoomFirstPosX5R = 10
ClubHallUIDefault.RoomFirstPosX4R = 30

-- 当前亲友圈名字颜色
ClubHallUIDefault.curClubNameColor = cc.c3b(0x77,0x45,0x45)
-- 其它亲友圈名字颜色
ClubHallUIDefault.otherClubNameColor = cc.c3b(0x77,0x45,0x45)

ClubHallUIDefault.p2chair1Pos = cc.p(293.82,177)
ClubHallUIDefault.p2chair3Pos = cc.p(60.18,177)

ClubHallUIDefault.p3chair1Pos = cc.p(293.82,177)
ClubHallUIDefault.p3chair2Pos = cc.p(177,295.12)
ClubHallUIDefault.p3chair3Pos = cc.p(60.18,177)

ClubHallUIDefault.p4chair1Pos = cc.p(293.82,177)
ClubHallUIDefault.p4chair2Pos = cc.p(177,295.12)
ClubHallUIDefault.p4chair3Pos = cc.p(60.18,177)
ClubHallUIDefault.p4chair4Pos = cc.p(177,60.18)

ClubHallUIDefault.p5chair1Pos = cc.p(300.90,177)
ClubHallUIDefault.p5chair2Pos = cc.p(177,295.12)
ClubHallUIDefault.p5chair3Pos = cc.p(53.10,177)
ClubHallUIDefault.p5chair4Pos = cc.p(113.28,47.79)
ClubHallUIDefault.p5chair5Pos = cc.p(240.72,47.79)

ClubHallUIDefault.p6chair1Pos = cc.p(300.90,177)
ClubHallUIDefault.p6chair2Pos = cc.p(240.72,295.12)
ClubHallUIDefault.p6chair3Pos = cc.p(113.28,295.12)
ClubHallUIDefault.p6chair4Pos = cc.p(53.10,177)
ClubHallUIDefault.p6chair5Pos = cc.p(113.28,47.79)
ClubHallUIDefault.p6chair6Pos = cc.p(240.72,47.79)


function ClubHallUIDefault:getBtnImgByName(str)
    return self.nameToImg[str]
end

function ClubHallUIDefault:getBtnImgPressByName(str)
    return self.nameToImgPress[str]
end

function ClubHallUIDefault:loadCsbFile()
    INFO('加载亲友圈csb',self.csb_file)
    local node = tolua.cast(cc.CSLoader:createNode(self.csb_file),"ccui.Widget")
    return node
end

-- 修改
function ClubHallUIDefault:getModifyBg()
    return self.ModifyBg
end

-- 解散
function ClubHallUIDefault:getDiscardBg()
    return self.DiscardBg
end

-- 没有操作
function ClubHallUIDefault:getNoOpertorBg()
    return self.NoOpertorBg
end

-- 桌子背景图
function ClubHallUIDefault:getRoomItemBg()
    return self.ClubRoomItemBg
end

-- 桌子开始背景图
function ClubHallUIDefault:getRoomItemPlayingBg()
    return self.ClubRoomItemPlayingBg
end

-- 亲友圈顶上名字底图
function ClubHallUIDefault:getTopClubNameItemBg(str)
    return self.topClubNameItemBg[str]
end

-- 亲友圈顶上名字按下底图
function ClubHallUIDefault:getTopClubNameItemPressBg(str)
    return self.topClubNameItemPressBg[str]
end

-- 亲友圈顶上名字底图
function ClubHallUIDefault:getTopHLClubNameItemBg(str)
    return self.topHLClubNameItemBg[str]
end

-- 亲友圈顶上名字按下底图
function ClubHallUIDefault:getTopHLClubNameItemPressBg(str)
    return self.topHLClubNameItemPressBg[str]
end

-- 开打房间游戏名字颜色
function ClubHallUIDefault:getPlayingDeskGameNameColor()
    return self.playingDeskGameNameColor
end

--
function ClubHallUIDefault:getPlayingDeskOptColor()
    return self.playingDeskOptColor
end

function ClubHallUIDefault:getFreeDeskGameNameColor()
    return self.freeDeskGameNameColor
end

-- 闲置房间游戏可操作颜色
function ClubHallUIDefault:getFreeDeskOptColor()
    return self.freeDeskOptColor
end

-- 新年UI
ClubHallUINewYear = class("ClubHallUINewYear", ClubHallUIDefault)
ClubHallUINewYear.csb_file = 'ui/club_hall_new_year.csb'
-- ClubHallUINewYear.csb_club_log = 'ui/club_log_new_year.csb'
-- ClubHallUINewYear.csb_club_member = 'ui/club_member_new_year.csb'
-- ClubHallUINewYear.csb_club_agent_bind_dialog = 'ui/club_agent_bind_dialog_new_year.csb'
-- ClubHallUINewYear.csb_club_faka_shuoming = 'ui/club_faka_shuoming_new_year.csb'
-- ClubHallUINewYear.csb_club_invite_dialog = 'ui/club_invite_dialog_new_year.csb'
-- ClubHallUINewYear.csb_club_notice = 'ui/club_notice_new_year.csb'
-- ClubHallUINewYear.csb_club_rank = 'ui/club_rank_new_year.csb'
-- ClubHallUINewYear.csb_club_rank_person = 'ui/club_rank_person_new_year.csb'
-- ClubHallUINewYear.csb_club_rank_consume = 'ui/club_rank_consume_new_year.csb'
-- ClubHallUINewYear.csb_club_rename_club = 'ui/club_rename_club_new_year.csb'
-- ClubHallUINewYear.csb_club_reset_ways = 'ui/club_reset_ways_new_year.csb'
-- ClubHallUINewYear.csb_club_setting = 'ui/club_setting_new_year.csb'
-- ClubHallUINewYear.csb_club_dialog = 'ui/club_dialog_new_year.csb'
-- ClubHallUINewYear.csb_club_zhanji = 'ui/club_zhanji_new_year.csb'

ClubHallUINewYear.ModifyBg = "ui/qj_club_new_year/title2-fs8.png"
ClubHallUINewYear.DiscardBg = "ui/qj_club_new_year/title1-fs8.png"
ClubHallUINewYear.NoOpertorBg = 'ui/qj_club_new_year/title1-fs8.png'
ClubHallUINewYear.ClubRoomItemBg = 'ui/qj_club_new_year/ditan-fs8.png'
ClubHallUINewYear.ClubRoomItemPlayingBg = 'ui/qj_club_new_year/mask-fs8.png'
ClubHallUINewYear.nameToImg = {
    club = "ui/qj_club_new_year/dt_clubroom_club.png",
    log = "ui/qj_club_new_year/dt_clubroom_record.png",
    rank = "ui/qj_club_new_year/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_new_year/dt_clubroom_quickin.png",
    friend = "ui/qj_club_new_year/dt_clubroom_member.png",
    ways = "ui/qj_club_new_year/dt_clubroom_play.png",
}

ClubHallUINewYear.nameToImgPress = {
    club = "ui/qj_club_new_year/dt_clubroom_club.png",
    log = "ui/qj_club_new_year/dt_clubroom_record.png",
    rank = "ui/qj_club_new_year/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_new_year/dt_clubroom_quickin.png",
    friend = "ui/qj_club_new_year/dt_clubroom_member.png",
    ways = "ui/qj_club_new_year/dt_clubroom_play.png",
}

-- -- 高度对齐长度
ClubHallUINewYear.HeightAlign3Ren = 100
ClubHallUINewYear.HeightAlign4Ren = 100
ClubHallUINewYear.HeightAlign5Ren = 100
-- 高度缩放系统
ClubHallUINewYear.HeightScale3Ren = 1
ClubHallUINewYear.HeightScale4Ren = 0.8
ClubHallUINewYear.HeightScale5Ren = 0.7

ClubHallUINewYear.RoomItemHeight3R = 450
ClubHallUINewYear.RoomItemHeight4R = 370
ClubHallUINewYear.RoomItemHeight5R = 300

ClubHallUINewYear.RoomItemScale3R = 0.98
ClubHallUINewYear.RoomItemScale4R = 0.76
ClubHallUINewYear.RoomItemScale5R = 0.62

ClubHallUINewYear.RoomFirstPosX3R = 64
ClubHallUINewYear.RoomFirstPosX5R = 24
ClubHallUINewYear.RoomFirstPosX4R = 40

-- 古风UI
ClubHallUISimple = class("ClubHallUISimple", ClubHallUIDefault)
ClubHallUISimple.csb_file = 'ui/club_hall_simple.csb'
-- ClubHallUISimple.ModifyBg = "ui/qj_club_simple/title2-fs8.png"
-- ClubHallUISimple.DiscardBg = "ui/qj_club_simple/title1-fs8.png.png"
-- ClubHallUISimple.NoOpertorBg = 'ui/qj_club_simple/title2-fs8.png'
ClubHallUISimple.ClubRoomItemBg = 'ui/qj_club_simple/table-di-fs8.png'
ClubHallUISimple.ClubRoomItemPlayingBg = 'ui/qj_club_simple/forbidden-fs8.png'
ClubHallUISimple.nameToImg = {
    club = "ui/qj_club_simple/dt_clubroom_club.png",
    log = "ui/qj_club_simple/dt_clubroom_record.png",
    rank = "ui/qj_club_simple/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_simple/dt_clubroom_quickin.png",
    friend = "ui/qj_club_simple/dt_clubroom_member.png",
    ways = "ui/qj_club_simple/dt_clubroom_play.png",
}

ClubHallUISimple.nameToImgPress = {
    club = "ui/qj_club_simple/dt_clubroom_club.png",
    log = "ui/qj_club_simple/dt_clubroom_record.png",
    rank = "ui/qj_club_simple/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_simple/dt_clubroom_quickin.png",
    friend = "ui/qj_club_simple/dt_clubroom_member.png",
    ways = "ui/qj_club_simple/dt_clubroom_play.png",
}

ClubHallUISimple.topHLClubNameItemBg = {
    left = "ui/qj_club_simple/qj_club_name2.png",
    mid = "ui/qj_club_simple/qj_club_name.png",
    right = "ui/qj_club_simple/qj_club_name3.png",
}

ClubHallUISimple.topHLClubNameItemPressBg = {
    left = "ui/qj_club_simple/qj_club_name2.png",
    mid = "ui/qj_club_simple/qj_club_name.png",
    right = "ui/qj_club_simple/qj_club_name3.png",
}

-- 当前亲友圈名字颜色
ClubHallUISimple.curClubNameColor = Color.WHITE
-- 其它亲友圈名字颜色
ClubHallUISimple.otherClubNameColor = cc.c3b(0xa8,0x6d,0x2d)

-- 清雅版UI
ClubHallUIElegant = class("ClubHallUIElegant", ClubHallUIDefault)
ClubHallUIElegant.csb_file = 'ui/club_hall_elegant.csb'
ClubHallUIElegant.ModifyBg = "ui/qj_club_elegant/title1-fs8.png"
ClubHallUIElegant.DiscardBg = "ui/qj_club_elegant/title2-fs8.png"
ClubHallUIElegant.NoOpertorBg = 'ui/qj_club_elegant/title1-fs8.png'
ClubHallUIElegant.ClubRoomItemBg = 'ui/qj_club_elegant/ditan-fs8.png'
ClubHallUIElegant.ClubRoomItemPlayingBg = 'ui/qj_club_elegant/mask-fs8.png'

ClubHallUIElegant.nameToImg = {
    club = "ui/qj_club_elegant/dt_clubroom_club.png",
    log = "ui/qj_club_elegant/dt_clubroom_record.png",
    rank = "ui/qj_club_elegant/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_elegant/dt_clubroom_quickin.png",
    friend = "ui/qj_club_elegant/dt_clubroom_member.png",
    ways = "ui/qj_club_elegant/dt_clubroom_play.png",
}

ClubHallUIElegant.nameToImgPress = {
    club = "ui/qj_club_elegant/dt_clubroom_club.png",
    log = "ui/qj_club_elegant/dt_clubroom_record.png",
    rank = "ui/qj_club_elegant/dt_clubroom_rank.png",
    quckjoin ="ui/qj_club_elegant/dt_clubroom_quickin.png",
    friend = "ui/qj_club_elegant/dt_clubroom_member.png",
    ways = "ui/qj_club_elegant/dt_clubroom_play.png",
}

ClubHallUIElegant.topClubNameItemBg = {
    left = "ui/qj_button/anniu1.png",
    mid = "ui/qj_button/anniu1.png",
    right = "ui/qj_button/anniu1.png",
}

ClubHallUIElegant.topClubNameItemPressBg = {
    left = "ui/qj_button/anniu1.png",
    mid = "ui/qj_button/anniu1.png",
    right = "ui/qj_button/anniu1.png",
}


ClubHallUIElegant.topHLClubNameItemBg = {
    left = "ui/qj_club_elegant/qj_club_name2.png",
    mid = "ui/qj_club_elegant/qj_club_name.png",
    right = "ui/qj_club_elegant/qj_club_name3.png",
}

ClubHallUIElegant.topHLClubNameItemPressBg = {
    left = "ui/qj_club_elegant/qj_club_name2.png",
    mid = "ui/qj_club_elegant/qj_club_name.png",
    right = "ui/qj_club_elegant/qj_club_name3.png",
}


-- 当前亲友圈名字颜色
ClubHallUIElegant.curClubNameColor = cc.c3b(0x58,0x7e,0x3c)
-- 其它亲友圈名字颜色
ClubHallUIElegant.otherClubNameColor = cc.c3b(0xad,0xa4,0x77)

-- 当前正在打的桌子
ClubHallUIElegant.playingDeskGameNameColor = cc.c3b(0xff,0xf6,0xe4)
ClubHallUIElegant.playingDeskOptColor = cc.c3b(0xff,0xcd,0xf0)

-- 当前空闲桌子
ClubHallUIElegant.freeDeskGameNameColor = cc.c3b(0x28,0x79,0)
ClubHallUIElegant.freeDeskOptColor = cc.c3b(0xf4,0xff,0xcf)

-- ClubHallUIElegant.p2chair1Pos = cc.p(284.82,177)
-- ClubHallUIElegant.p2chair3Pos = cc.p(67.26,177)

-- ClubHallUIElegant.p3chair1Pos = cc.p(284.82,177)
-- ClubHallUIElegant.p3chair2Pos = cc.p(177,283)
-- ClubHallUIElegant.p3chair3Pos = cc.p(67.26,177)

-- ClubHallUIElegant.p4chair1Pos = cc.p(284.82,177)
-- ClubHallUIElegant.p4chair2Pos = cc.p(177,283)
-- ClubHallUIElegant.p4chair3Pos = cc.p(67.26,177)
-- ClubHallUIElegant.p4chair4Pos = cc.p(177,74.34)

-- ClubHallUIElegant.p5chair1Pos = cc.p(284.82,177)
-- ClubHallUIElegant.p5chair2Pos = cc.p(177,283)
-- ClubHallUIElegant.p5chair3Pos = cc.p(67.26,177)
-- ClubHallUIElegant.p5chair4Pos = cc.p(113.28,74.34)
-- ClubHallUIElegant.p5chair5Pos = cc.p(240.72,74.34)

-- ClubHallUIElegant.p6chair1Pos = cc.p(284.82,177)
-- ClubHallUIElegant.p6chair2Pos = cc.p(240.72,283)
-- ClubHallUIElegant.p6chair3Pos = cc.p(113.28,283)
-- ClubHallUIElegant.p6chair4Pos = cc.p(67.26,177)
-- ClubHallUIElegant.p6chair5Pos = cc.p(113.28,74.34)
-- ClubHallUIElegant.p6chair6Pos = cc.p(240.72,74.34)

ClubHallUI = {}

ClubHallUI.Simple = 1
ClubHallUI.NewYear = 2
ClubHallUI.Classic = 3
ClubHallUI.Elegant = 4

ClubHallUI.Style = nil

function ClubHallUI.getInstance()
    require 'scene.GameSettingDefault'
    ClubHallUI.Style = ClubHallUI.Style or gt.getLocal("int", "qyqStyle", GameSettingDefault.CLUB_STYLE)
    local qyqStyle = ClubHallUI.Style
    if qyqStyle == ClubHallUI.Simple then
        return ClubHallUISimple
    elseif qyqStyle == ClubHallUI.NewYear then
        return ClubHallUINewYear
    elseif qyqStyle == ClubHallUI.Classic then
        return ClubHallUIDefault
    elseif qyqStyle == ClubHallUI.Elegant then
        return ClubHallUIElegant
    end
end

function ClubHallUI.setClubStyle(style)
    ClubHallUI.Style = style
end

function ClubHallUI.getClubStyle()
    require 'scene.GameSettingDefault'
    ClubHallUI.Style = ClubHallUI.Style or gt.getLocal("int", "qyqStyle", GameSettingDefault.CLUB_STYLE)
    return ClubHallUI.Style
end