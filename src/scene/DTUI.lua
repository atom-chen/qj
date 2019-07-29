-- 经典UI
DTUIDefault                              = class('DTUIDefault')
DTUIDefault.csb_file                     = 'ui/DTUI.csb'
DTUIDefault.csb_main_message_dialog      = 'ui/main_message_dialog.csb'
DTUIDefault.csb_main_help_dialog         = 'ui/main_help_dialog.csb'
DTUIDefault.csb_DT_RecordLayer           = 'ui/DT_RecordLayer.csb'
DTUIDefault.csb_main_share_dialog        = 'ui/main_share_dialog.csb'
DTUIDefault.csb_main_fankui_dialog       = 'ui/main_fankui_dialog.csb'
DTUIDefault.csb_main_setting_dialog      = 'ui/main_setting_dialog.csb'
DTUIDefault.csb_main_userinfo_dialog     = 'ui/main_userinfo_dialog.csb'
DTUIDefault.csb_DT_RelNameLayer          = 'ui/DT_RelNameLayer.csb'
DTUIDefault.csb_Tips                     = 'ui/Tips.csb'
DTUIDefault.csb_copyroomtip              = 'ui/copyroomtip.csb'
DTUIDefault.csb_jiesanroom               = 'ui/jiesanroom.csb'
DTUIDefault.csb_jiesanxq                 = 'ui/jiesanxq.csb'
DTUIDefault.csb_avoidJoinTips            = 'ui/avoidJoinTips.csb'
DTUIDefault.csb_DT_CreateroomLayer_sxmj1 = 'ui/DT_CreateroomLayer_sxmj1.csb'
DTUIDefault.csb_DT_CreateroomLayer_sxmj2 = 'ui/DT_CreateroomLayer_sxmj2.csb'
DTUIDefault.csb_DT_CreateroomLayer_poker = 'ui/DT_CreateroomLayer_poker.csb'
DTUIDefault.csb_DT_CreateroomLayer_hebei = 'ui/DT_CreateroomLayer_hebei.csb'
DTUIDefault.csb_DT_UserinfoLayer         = 'ui/DT_UserinfoLayer.csb'
DTUIDefault.csb_DT_kefu                  = 'ui/DT_kefu.csb'
DTUIDefault.csb_agree                    = 'ui/agree.csb'
DTUIDefault.csb_debug                    = 'ui/debug.csb'
DTUIDefault.csb_returnroomtips           = 'ui/returnroomtips.csb'
DTUIDefault.csb_recordshare              = 'ui/recordshare.csb'
DTUIDefault.csb_main_moremsg_dialog      = 'ui/main_moremsg_dialog.csb'
DTUIDefault.csb_bindphone_dialog         = 'ui/bindphone_dialog.csb'
DTUIDefault.csb_RoomSettingLayer         = 'ui/RoomSettingLayer.csb'

-- 新年大厅UI
DTUINewYear = class("DTUINewYear", DTUIDefault)
-- DTUINewYear.csb_file = 'ui/DTUINewYear.csb'
DTUINewYear.csb_main_message_dialog      = 'ui/main_message_dialog_new_year.csb'
DTUINewYear.csb_main_help_dialog         = 'ui/main_help_dialog_new_year.csb'
DTUINewYear.csb_DT_RecordLayer           = 'ui/DT_RecordLayer_new_year.csb'
DTUINewYear.csb_main_share_dialog        = 'ui/main_share_dialog_new_year.csb'
DTUINewYear.csb_main_fankui_dialog       = 'ui/main_fankui_dialog_new_year.csb'
DTUINewYear.csb_main_setting_dialog      = 'ui/main_setting_dialog_new_year.csb'
DTUINewYear.csb_main_userinfo_dialog     = 'ui/main_userinfo_dialog_new_year.csb'
DTUINewYear.csb_DT_RelNameLayer          = 'ui/DT_RelNameLayer_new_year.csb'
DTUINewYear.csb_Tips                     = 'ui/Tips_new_year.csb'
DTUINewYear.csb_Tips_push_qinliao        = 'ui/Tips_push_qinliao.csb'
DTUINewYear.csb_Tips_jiebang_qinliao     = 'ui/Tips_jiebang_qinliao.csb'
DTUINewYear.csb_copyroomtip              = 'ui/copyroomtip_new_year.csb'
DTUINewYear.csb_jiesanroom               = 'ui/jiesanroom_new_year.csb'
DTUINewYear.csb_jiesanxq                 = 'ui/jiesanxq_new_year.csb'
DTUINewYear.csb_avoidJoinTips            = 'ui/avoidJoinTips_new_year.csb'
DTUINewYear.csb_quickstart               = 'ui/quickstart_new_year.csb'
DTUINewYear.csb_DT_CreateroomLayer_sxmj1 = 'ui/DT_CreateroomLayer_sxmj1_new_year.csb'
DTUINewYear.csb_DT_CreateroomLayer_sxmj2 = 'ui/DT_CreateroomLayer_sxmj2_new_year.csb'
DTUINewYear.csb_DT_CreateroomLayer_poker = 'ui/DT_CreateroomLayer_poker_new_year.csb'
DTUINewYear.csb_DT_CreateroomLayer_hebei = 'ui/DT_CreateroomLayer_hebei_new_year.csb'
DTUINewYear.csb_DT_UserinfoLayer         = 'ui/DT_UserinfoLayer_new_year.csb'
DTUINewYear.csb_DT_kefu                  = 'ui/DT_kefu_new_year.csb'
DTUINewYear.csb_agree                    = 'ui/agree_new_year.csb'
DTUINewYear.csb_returnroomtips           = 'ui/returnroomtips_new_year.csb'
DTUINewYear.csb_recordshare              = 'ui/recordshare_new_year.csb'
DTUINewYear.csb_main_moremsg_dialog      = 'ui/main_moremsg_dialog_new_year.csb'
DTUINewYear.csb_bindphone_dialog         = 'ui/bindphone_dialog_new_year.csb'
DTUINewYear.csb_RoomSettingLayer         = 'ui/RoomSettingLayer_new_year.csb'


--怀旧版大厅UI
DTUIHuaiJiu = class("DTUIHuaiJiu", DTUINewYear)
DTUIHuaiJiu.csb_file                    = 'ui/DTUIBefore.csb'

DTUI = {}
function DTUI.getInstance()
    -- 加载主界面怀旧风格的csb
    if gt.getLocalString("hall_style") == "huaijiu" then
        return DTUIHuaiJiu
    end
    -- 加载主界面经典风格的csb
    return DTUINewYear
end