local Record = {}

RecordGameType = require('scene.RecordGameType')

local record_max_num = 50

function Record.save_new_record(node, rtn_msg, game_type)
    if node.is_playback then
        local pb_node = node:getChildByTag(9876)
        if pb_node then
            pb_node:removeFromParent(true)
        end
    elseif rtn_msg.log_data_id then
        local mjrecord = nil
        mjrecord       = cc.UserDefault:getInstance():getStringForKey("zzrecord")
        if mjrecord and mjrecord ~= "" then
            mjrecord = json.decode(mjrecord)
        else
            mjrecord = {}
        end
        local exist         = nil
        local room_count    = 0
        local pre_log_ju_id = nil
        for __, v in ipairs(mjrecord) do
            if v.log_data_id == rtn_msg.log_data_id then
                exist = true
                break
            end
            if v.log_ju_id ~= pre_log_ju_id then
                room_count    = room_count + 1
                pre_log_ju_id = v.log_ju_id
            end
        end
        if not exist then
            if room_count >= record_max_num and pre_log_ju_id ~= rtn_msg.log_ju_id then
                pre_log_ju_id = mjrecord[1].log_ju_id
                while mjrecord[1].log_ju_id == pre_log_ju_id do
                    table.remove(mjrecord, 1)
                end
            end
            local new_record = {log_ju_id = rtn_msg.log_ju_id, log_data_id = rtn_msg.log_data_id, cur_ju = rtn_msg.cur_ju, room_id = node.desk, time = rtn_msg.time or os.time(), yx_type = game_type}
            for i, v in ipairs(rtn_msg.players) do
                local play_index = node:indexTrans(v.index)
                local nickname   = nil
                if node.player_ui[play_index].user then
                    nickname = node.player_ui[play_index].user.nickname
                end
                local user_id = nil
                if node.player_ui[play_index].user then
                    user_id = node.player_ui[play_index].user.user_id
                end
                new_record["name"..i]  = nickname or ""
                new_record["score"..i] = v.score
                new_record["userId"..i] = user_id
                if nickname == nil then
                    gt.uploadErr("why node.player_ui[play_index].user is nil?")
                end
            end
            if node.ownername then
                new_record.roomOwner_name = node.ownername
            end
            if node.club_name then
                new_record.owner_name = node.club_name
            end
            mjrecord[#mjrecord + 1] = new_record
            commonlib.echo(mjrecord)
            cc.UserDefault:getInstance():setStringForKey("zzrecord", json.encode(mjrecord))
            cc.UserDefault:getInstance():flush()
        end
        if node.total_ju == 1 and rtn_msg.log_ju_id then
            gt.rmMissJuId(rtn_msg.log_ju_id)
        end
    end
    log('存战绩', game_type)
end

function Record.mj_save_new_record(node, rtn_msg, game_type)
    if node.is_playback then
        local pb_node = node:getChildByTag(9876)
        if pb_node then
            pb_node:removeFromParent(true)
        end
    elseif rtn_msg.log_data_id then
        local mjrecord = nil
        mjrecord       = cc.UserDefault:getInstance():getStringForKey("zzrecord")
        if mjrecord and mjrecord ~= "" then
            mjrecord = json.decode(mjrecord)
        else
            mjrecord = {}
        end
        local exist         = nil
        local room_count    = 0
        local pre_log_ju_id = nil
        for __, v in ipairs(mjrecord) do
            if v.log_data_id == rtn_msg.log_data_id then
                exist = true
                break
            end
            if v.log_ju_id ~= pre_log_ju_id then
                room_count    = room_count + 1
                pre_log_ju_id = v.log_ju_id
            end
        end
        if not exist then
            if room_count >= record_max_num and pre_log_ju_id ~= rtn_msg.log_ju_id then
                pre_log_ju_id = mjrecord[1].log_ju_id
                while mjrecord[1].log_ju_id == pre_log_ju_id do
                    table.remove(mjrecord, 1)
                end
            end
            require('scene.PlayerData')
            local new_record = {log_ju_id = rtn_msg.log_ju_id, log_data_id = rtn_msg.log_data_id, cur_ju = rtn_msg.cur_ju, room_id = node.desk, time = rtn_msg.time or os.time(), yx_type = game_type}
            for i, v in ipairs(rtn_msg.players) do
                -- local play_index = node:indexTrans(v.index)
                local userData = PlayerData.getPlayerDataByServerID(v.index)
                local nickname = nil
                local user_id = nil
                if userData and userData.name then
                    nickname = userData.name
                end
                if userData and userData.uid then
                    user_id = userData.uid
                end
                new_record["name"..i]  = nickname or ""
                new_record["score"..i] = v.score
                new_record["userId"..i] = user_id
                if nickname == nil then
                    gt.uploadErr("why userData.nickname is nil?")
                end
                if user_id == nil then
                    gt.uploadErr("why userData.user_id is nil?")
                end
            end
            if node.ownername then
                new_record.roomOwner_name = node.ownername
            end
            if node.club_name then
                new_record.owner_name = node.club_name
            end
            mjrecord[#mjrecord + 1] = new_record
            commonlib.echo(mjrecord)
            cc.UserDefault:getInstance():setStringForKey("zzrecord", json.encode(mjrecord))
            cc.UserDefault:getInstance():flush()
        end
        if node.total_ju == 1 and rtn_msg.log_ju_id then
            gt.rmMissJuId(rtn_msg.log_ju_id)
        end
    end
    log('存战绩', game_type)
end

return Record