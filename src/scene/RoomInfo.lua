RoomInfo = RoomInfo or {}

RoomInfo.people_num       = RoomInfo.people_num or 0
RoomInfo.people_total_num = RoomInfo.people_total_num or 0
RoomInfo.isA4To32         = RoomInfo.isA4To32 or nil -- 允许四转32
RoomInfo.club_id          = RoomInfo.club_id or nil -- 房间所属亲友圈ID
RoomInfo.club_name        = RoomInfo.club_name or nil -- 房间所属亲友圈名字
RoomInfo.club_index       = RoomInfo.club_index or nil -- 房间所属亲友圈桌子号
RoomInfo.room_id          = RoomInfo.room_id or nil -- 房间号
RoomInfo.status           = RoomInfo.status or nil -- 房间状态
RoomInfo.cur_ju           = RoomInfo.cur_ju or nil -- 当前局

function RoomInfo.Clear()
    RoomInfo.people_num       = 0
    RoomInfo.people_total_num = 0
end

function RoomInfo.getCurPeopleNum()
    return RoomInfo.people_num
end

function RoomInfo.updateCurPeopleNum(num)
    RoomInfo.people_num = num
end

function RoomInfo.updateTotalPeopleNum(num)
    RoomInfo.people_total_num = num
end

function RoomInfo.getTotalPeopleNum()
    return RoomInfo.people_total_num
end

function RoomInfo.setRoomInfo(room_info, room_id)
    print('------------------------------')
    print('是否允许34转2')
    RoomInfo.isA4To32 = room_info.isA4To32
    print('RoomInfo.isA4To32', RoomInfo.isA4To32)
    print('是否允许34转2')
    print('------------------------------')
    RoomInfo.club_id    = room_info.club_id -- 房间所属亲友圈ID
    RoomInfo.club_name  = room_info.club_name -- 房间所属亲友圈名字
    RoomInfo.club_index = room_info.club_index -- 房间所属亲友圈桌子号
    RoomInfo.params     = room_info
    RoomInfo.room_id    = room_id
    RoomInfo.status     = room_info.status
    RoomInfo.cur_ju     = room_info.cur_ju
end