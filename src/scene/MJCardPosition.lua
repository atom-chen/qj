local VW = g_visible_size.width
local VH = g_visible_size.height
local single_scale = VW*1280/(1136*VW)

local OC3S = 0.65

local HC2DBW = 75
local HC2DBH = 113
--2d大牌放大系数
local HC2DBS = 1.18

local HC2DW = 75
local HC2DH = 113
--2d经典放大系统
local HC2DS = 1.15

-- 3d放大系统
local HC3DW = 102
local HC3DH = 143
local HC3DS = 1

local SWS = VW/1280

local SWH = VH/720

SWS = math.min(SWS,SWH)
SWH = SWS

local single_card_size = cc.size((VW-40*SWS)/14, (VW-40*SWS)/14/80*116)

local SCW = single_card_size.width
local SCH = single_card_size.height

local MJCardPosition = {

    mj2dBigLastLineDistance = {
                                cc.p(0,20*SWH),
                                cc.p(-10*SWS,0),
                                cc.p(0,-10*SWH),
                                cc.p(10*SWS,0)
                                },

    single_scale = single_scale,

    single_card_size = single_card_size,

    out_card_3d_scale = OC3S,

    hand_card_2dbig_scale = HC2DBS,

    hand_card_2d_scale = HC2DS,

    hand_card_3d_scale = HC3DS,

    hand_card_2dbig_width = HC2DBW,

    hand_card_2d_width = HC2DW,

    hand_card_3d_width = HC3DW,

    open_card_pos_list = {
        [1] = cc.p(VW/2, SCH*(VH/640*1.4)),
        [2] = cc.p(VW-SCH*2.5, VH*0.6),
        [3] = cc.p(VW/2, VH-SCH*(VH/640*1.3)),
        [4] = cc.p(SCH*2.5, VH*0.6)
    },

    open_card_ani_pos_list = {
        [1] = cc.p(VW/2, SCH*(VH/640*1.2)),
        [2] = cc.p(VW-SCH*1.8, VH*0.6),
        [3] = cc.p(VW/2, VH-SCH*(VH/640*1.2)),
        [4] = cc.p(SCH*1.8, VH*0.6)
    },

    show_param = {
        hand_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2-666.57*SWS,
                                 65.49*SWH + HC3DH/2*(HC3DS - 1)
                                 ),
                    space_result=cc.p(88.57*SWS,0),

                    space=cc.p(HC3DS*88.57*SWS,0),

                    space_replay = cc.p(HC3DS*88.57*SWS,0)
                    },
            [2] = {init_pos=cc.p(VW - 150*SWS,
                                VH/2 - 186*SWH),
                    space=cc.p(-5.3*SWS, 30*SWH),

                    space_replay=cc.p(-5.3*SWS, 30*SWH),
                    },

            [3] = {init_pos=cc.p(VW/2 + 400*SWS,
                                VH - 35*SWH),
                    space=cc.p(-38*SWS, 0),

                    space_replay=cc.p(-48*SWS, 0)
                    },
            [4] = {init_pos=cc.p(246*SWS,
                                VH/2 + 220*SWH),
                    space=cc.p(-5.3*SWS, -30*SWH),

                    space_replay=cc.p(-5.3*SWS, -30*SWH)
                    ,}
        },

        out_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2 - 90*SWS,
                                300*SWH),
                    space=cc.p(OC3S*53.14*SWS, 0),
                    two_hei=cc.p(OC3S*-1*SWS, OC3S*-64.21*SWH)},
            [2] = {init_pos=cc.p(VW - 480*SWS,
                                VH/2 - 10*SWH),
                    space=cc.p(OC3S*-2*SWS, OC3S*38.08*SWH),
                    two_hei=cc.p(OC3S*65.49*SWS, 0)},
            [3] = {init_pos=cc.p(VW/2 + 80*SWS,
                                VH - 200*SWH),
                    space=cc.p(OC3S*-48.71*SWS, 0),
                    two_hei=cc.p(OC3S*-0.5*SWS, OC3S*55.22*SWH)},
            [4] = {init_pos=cc.p(480*SWS,
                                VH/2 + 115*SWH),
                    space=cc.p(OC3S*-2*SWS, OC3S*-38.08*SWH),
                    two_hei=cc.p(OC3S*-59.07*SWS, 0)},
        },
        --站立牌间距缩放比例：相对正常手牌间距
        scard_space_scale = {0.8, 0.8*single_scale, 1.1*single_scale, 0.8*single_scale},
        --站立牌组间距比例：相对于正常手牌间距
        z_p_s = {0.25, 0.6*single_scale, 0.4*single_scale, 0.65*single_scale},
        -- z_p_s = {0,0,0,0},
    },



    pm_show_param = {
        hand_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2 - 565.72 *SWS,
                                55*SWH + HC2DBH/2*(HC2DBS - 1)
                                ),
                    space=cc.p(HC2DBS*74.57*SWS,0),

                    space_result=cc.p(74.57*SWS,0),

                    space_replay=cc.p(HC2DBS*74.57*SWS,0),
                    },
            [2] = {init_pos=cc.p(VW - 165*SWS,
                                VH/2 - 250*SWH),
                    space=cc.p(0, 30*SWH),

                    space_replay=cc.p(0, 35*SWH)},
            [3] = {init_pos=cc.p(VW/2 + 330 *SWS,
                                VH - 90*SWH),
                    space=cc.p(-38*SWS, 0),

                    space_replay=cc.p(-35*SWS, 0)},
            [4] = {init_pos=cc.p(165*SWS,
                                VH/2 + 280*SWH),
                    space=cc.p(0, - 30*SWH),

                    space_replay=cc.p(0, -35*SWH)},
        },
        out_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2 - 126*SWS,
                                265*SWH),
                    space=cc.p(42.28*SWS, 0),
                    two_hei=cc.p(0, -51.78*SWH)},
            [2] = {init_pos=cc.p(VW - 440*SWS,
                                VH/2 - 105*SWH),
                    space=cc.p(0, 36.5*SWH),
                    two_hei=cc.p(59*SWS, 0)},
            [3] = {init_pos=cc.p(VW/2 + 121.82*SWS,
                                VH - 265*SWH),
                    space=cc.p(-41.28*SWS, 0),
                    two_hei=cc.p(0, 52.64*SWH)},
            [4] = {init_pos=cc.p(440*SWS,
                                VH/2 + 105*SWH),
                    space=cc.p(0, -36.5*SWH),
                    two_hei=cc.p(-59*SWS, 0)},
        },
        scard_space_scale = {0.72*SWS, 1.1*SWH, 0.92*SWS, 1.1*SWH},
        z_p_s = {0.25, 0.88*single_scale, 0.4*single_scale, 0.88*single_scale},
        -- z_p_s = {0,0,0,0},
    },



    pm_yellow_show_param = {
        hand_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2 - 565.72 *SWS,
                                55*SWH + HC2DH/2*(HC2DS - 1)
                                ),
                    space=cc.p(HC2DS*74.57*SWS,0),

                    space_result=cc.p(74.57*SWS,0),

                    space_replay=cc.p(HC2DS*74.57*SWS,0)},
            [2] = {init_pos=cc.p(VW - 165*SWS,
                                VH/2 - 200*SWH),
                    space=cc.p(0, 25*SWH),

                    space_replay=cc.p(0, 28*SWH)},
            [3] = {init_pos=cc.p(VW/2 + 330 *SWS,
                                VH - 90*SWH),
                    space=cc.p(-38*SWS, 0),

                    space_replay=cc.p(-35*SWS, 0)},
            [4] = {init_pos=cc.p(165*SWS,
                                VH/2 + 230*SWH),
                    space=cc.p(0, - 25*SWH),

                    space_replay=cc.p(0, - 28*SWH)},
        },
        out_card_pos_list = {
            [1] = {init_pos=cc.p(VW/2 - 190 *SWS,
                                210*SWH),
                    space=cc.p(37.28*SWS, 0),
                    two_hei=cc.p(0, 45*SWH)},
            [2] = {init_pos=cc.p(VW - 270*SWS,
                                VH/2 - 145*SWH),
                    space=cc.p(0, 28.62*SWH),
                    two_hei=cc.p(- 50*SWS, 0)},
            [3] = {init_pos=cc.p(VW/2 + 185*SWS,
                                VH - 210*SWH),
                    space=cc.p(-37.28*SWS, 0),
                    two_hei=cc.p(0, -45*SWH)},
            [4] = {init_pos=cc.p(270*SWS,
                                VH/2 + 150*SWH),
                    space=cc.p(0, -28.62*SWH),
                    two_hei=cc.p(50*SWS, 0)},
        },
        z_p_s = {0.25, 0.88*single_scale, 0.4*single_scale, 0.88*single_scale},
    },
}

-- MJCardPosition.pm_yellow_show_param.hand_card_pos_list = MJCardPosition.pm_show_param.hand_card_pos_list

MJCardPosition.show_param.ori_out_card_pos_list =
{
    [1] = {x=VW/2 - 260*SWS,
                y=MJCardPosition.show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=VW/2 + 240*SWS,
                y=MJCardPosition.show_param.out_card_pos_list[3].init_pos.y}
}

MJCardPosition.pm_show_param.ori_out_card_pos_list =
{
    [1] = {x=VW/2 - 318*SWS,
        y=MJCardPosition.pm_show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=VW/2 + 310*SWS,
        y=MJCardPosition.pm_show_param.out_card_pos_list[3].init_pos.y}
}

MJCardPosition.pm_yellow_show_param.ori_out_card_pos_list =
{
    [1] = {x=VW/2 - 355*SWS,
        y=MJCardPosition.pm_yellow_show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=VW/2 + 355*SWS,
        y=MJCardPosition.pm_yellow_show_param.out_card_pos_list[3].init_pos.y}
}

---------------------------------------------------------------------
MJCardPosition.show_param.ori_out_card_pos_list_34r =
{
    [1] = {x=MJCardPosition.show_param.out_card_pos_list[1].init_pos.x,
            y=MJCardPosition.show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=MJCardPosition.show_param.out_card_pos_list[3].init_pos.x,
            y=MJCardPosition.show_param.out_card_pos_list[3].init_pos.y}
}

MJCardPosition.pm_show_param.ori_out_card_pos_list_34r =
{
    [1] = {x=MJCardPosition.pm_show_param.out_card_pos_list[1].init_pos.x,
            y=MJCardPosition.pm_show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=MJCardPosition.pm_show_param.out_card_pos_list[3].init_pos.x,
            y=MJCardPosition.pm_show_param.out_card_pos_list[3].init_pos.y}
}

MJCardPosition.pm_yellow_show_param.ori_out_card_pos_list_34r =
{
    [1] = {x=MJCardPosition.pm_yellow_show_param.out_card_pos_list[1].init_pos.x,
            y=MJCardPosition.pm_yellow_show_param.out_card_pos_list[1].init_pos.y},
    [3] = {x=MJCardPosition.pm_yellow_show_param.out_card_pos_list[3].init_pos.x,
            y=MJCardPosition.pm_yellow_show_param.out_card_pos_list[3].init_pos.y}
}
---------------------------------------------------------------------

MJCardPosition.pm_yellow_show_param.scard_space_scale = MJCardPosition.pm_show_param.scard_space_scale

MJCardPosition.Scale = 1.3

return MJCardPosition