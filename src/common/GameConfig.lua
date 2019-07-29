specTextConfig = {
    "大家好！祝大家都有好手气。",
    "出牌啊,这牌你都看出花了。",
    "都别走啊,一会再打两圈。",
    "哎呦,好运来了挡都挡不住。",
    "稍等一下,我接个电话。",
    "刚才在接电话,久等了各位",
    "就是不上牌,没辙！",
    "又断线了,今天这网怎么了？",
    "你是哪的人啊,咱们加个好友吧。",
}

rankTextConfig = [[
一.积   分\n
麻将、字牌、扑克所有游戏积分加减计算\n
（例:麻将赢50积分.字牌输50积分,也就是0积分）\n\n
二.输赢次数\n
（例:积分达到最高分.赢场不是最高,我们将和第二三四名核算.积分和赢场最高为准.）]]

--------------- 这里不要动-------------
-- 是否是调试模式，如果需要在手机上调试打开，打正式包需要关闭
g_is_debug = g_is_debug or false
if g_is_debug then
    g_res_ver   = "1.10.001"
    g_res_ver_1 = "1.10.1"
else
    g_res_ver   = "1.0.001"
    g_res_ver_1 = "1.0.1"
end
g_version_key_1 = "res.ylqp.com"
g_version_key_2 = "pack.ylqp.com"
------------------------------------

-- 用于发送给服务器统计的版本号
-- 规则 从右至左520018000
-- 000小版本号
-- 18能力集
-- 00热更新相关版本
-- 2操作系统1 android 2 ios 0 other
-- 5打包版本
local lua_version   = 0
local UpdateVersion = cc.UserDefault:getInstance():getStringForKey("UpdateVersion", "1.0.0")
local verTab        = string.split(UpdateVersion, ".")
if verTab and verTab[3] then
    local num = tonumber(verTab[3])
    if num then
        lua_version = lua_version + num % 1000
    end
end
local NativeUtil = require("common.NativeUtil")
local abCount    = NativeUtil:getAbilityCount()
lua_version      = lua_version + abCount * 1000
-- 新更新的包增加
-- if package_name == "dbui" then
--     lua_version = lua_version + 100000
-- elseif package_name == "dbui2" then
--     lua_version = lua_version + 200000
-- end
if g_os == "android" then
    lua_version = lua_version + 10000000
elseif g_os == "ios" then
    lua_version = lua_version + 20000000
end
g_version = g_base_ver * 100000000 + lua_version

ios_checking = nil

if g_channel_id == 800002 then
    g_share_url = "http://yl04.nnzzh.com/ylqj/"..g_os.."qj.htm?v=" .. os.date("%m%d%H", os.time())
    g_act_url   = "http://share.yl04.nnzzh.com/ylqj/qj.htm?v=" .. os.date("%m%d%H", os.time())

    g_game_name = "【秦晋棋牌】"

    if g_is_multi_wechat then
        g_game_pack = "ylqj_wechat_1"
        ymkj.registerApp("wx023871851a2b168c")
    elseif gt.getPackageName() == "com.hnwstf.qinjin" then
        -- 上appstore的包(秦晋游戏)
        g_game_pack = "ylqj_wechat_2"
        ymkj.registerApp("wx68d6bda9242b3498")
    elseif gt.getPackageName() == "com.hnthj.hlhbmj" then
        -- 上appstore的包(秦晋娱乐,从满贯湖北麻将升级)
        g_game_pack = "ylqj_appstore_1"
        ymkj.registerApp("wxd3ec995faeb43edd")
    elseif gt.getPackageName() == "com.hnthj.nxqp" then
        -- 上appstore的包(秦晋麻将,从闲云阁宁乡棋牌升级)
        g_game_pack = "ylqj_appstore_2"
        ymkj.registerApp("wxd295e3fe1196468e")
    elseif gt.getPackageName() == "com.qinjin.youmei.xuanlu" then
        -- 秦晋优美旋律
        g_game_pack = "ylqj_appstore_3"
        ymkj.registerApp("wx0b962d8274adfce8")
    elseif gt.getPackageName() == "com.xzkj.qwer.qjty" or gt.getPackageName() == "com.sy18.qjty" then
        -- 秦晋体验版
        g_game_pack = "ylqj_wechat_tyb"
        ymkj.registerApp("wx503b6b0d6ae8e95f")
    else
        -- 签名包(秦晋棋牌)
        g_game_pack = "ylqj_wechat_1"
        ymkj.registerApp("wx023871851a2b168c")
    end

    local record_count = 0
    local record_key   = {"mjrecord", "pdkrecord", "phzrecord", "whzrecord", "zzrecord", "hzrecord", "ddzrecord", "tdhrecord"}
    for _, key in ipairs(record_key) do
        local recordString = cc.UserDefault:getInstance():getStringForKey(key)
        if recordString and recordString ~= "" then
            local records = json.decode(recordString)
            if records and #records > 0 then
                record_count = record_count + (#records)
            end
        end
    end
    local s3 = tonumber(cc.UserDefault:getInstance():getStringForKey("s3s3s3", "0"))
    local s4 = math.max(tonumber(cc.UserDefault:getInstance():getStringForKey("s4s4s4", "0")), math.floor(record_count / 8))
    if s3 == 0 then
        if record_count < 10 then
            local s5 = tonumber(cc.UserDefault:getInstance():getStringForKey("s5s5s5", "-1"))
            if s5 == -1 then
                g_ip_url = "http://yl04.nnzzh.com/ylqj/yl.txt"
            else
                local addr_list = {"ox", "tq", "i8", "7r", "cc", "ao", "9p", "3l", "y6", "ff"}
                g_ip_url        = "http://yl04.nnzzh.com/ylqj/"..addr_list[s5 % 10 + 1] .. ".txt"
            end
        elseif s4 < 11 then
            local s5 = tonumber(cc.UserDefault:getInstance():getStringForKey("s5s5s5", "-1"))
            if s5 == -1 then
                g_ip_url = "http://yl04.nnzzh.com/ylqj/yl.txt"
            else
                local addr_list = {"qw", "as", "zx", "er", "df", "cv", "ty", "gh", "bn", "ui"}
                g_ip_url        = "http://yl04.nnzzh.com/ylqj/"..addr_list[s5 % 10 + 1] .. ".txt"
            end
        elseif s4 < 22 then
            g_ip_url = "http://yl04.nnzzh.com/xfid/ylqj.txt"
        else
            g_ip_url = "http://yl04.nnzzh.com/iii3/ylqj.txt"
        end
    elseif s3 < 100 then
        g_ip_url = "http://yl04.nnzzh.com/ppik/ylqj.txt"
    else
        g_ip_url = "http://yl04.nnzzh.com/ddxi/ylqj.txt"
    end
    if test_package then
        if test_package == 1 then
            g_ip_url = string.gsub(g_ip_url, "/ylqj/", "/ylqjtyb/")
            g_ip_url = string.gsub(g_ip_url, "/ylqj.txt", "/ylqjtyb.txt")
        else
            yy_ip_url = "http://47.96.62.50/gametxt/pre_release_ylqj.txt"
        end
    end
    -- yy_ip_url = "http://test.99xzkj.com/test_ylqj.txt"
end

kefuTextConfig = {
    wx        = "联系官方微信",
    qq        = "联系官方QQ",
    delegate  = "联系官方代理",
    youhui    = "",
    broadcast = {"欢迎来到【秦晋棋牌】", "禁止赌博 仅供娱乐"}
}

g_ip_url = yy_ip_url or g_ip_url

-------- 兼容微信接口变化-------
g_wxhead_addr = nil

if not cc.Sprite.downloadImgT then
    cc.Sprite.downloadImgT = cc.Sprite.downloadImg
    cc.Sprite.downloadImg = function(self, head, url)
        -- if not ios_checking then
        if url then
            self:downloadImgT(head, url)
        else
            local pos  = string.find(head, "/", 20)
            local url  = string.sub(head, 1, pos - 1)
            local name = string.sub(head, pos + 1)
            self:downloadImgT(name, url)
        end
        -- end
    end
end

if not ccui.ImageView.downloadImgT then
    ccui.ImageView.downloadImgT = ccui.ImageView.downloadImg
    ccui.ImageView.downloadImg = function(self, head, url)
        -- if not ios_checking then
        if url then
            self:downloadImgT(head, url)
        else
            local pos  = string.find(head, "/", 20)
            local url  = string.sub(head, 1, pos - 1)
            local name = string.sub(head, pos + 1)
            self:downloadImgT(name, url)
        end
        -- end
    end
end

function commonlib.wxHead(head)
    if (not head or head == "" or string.len(head) < 24) then
        head = "http://thirdwx.qlogo.cn/mmopen/vi_32/Iy3rGQO05UlcA1o6yWLVCEicxBj1Uq0yy7ubMuDQ1BHvtiaHoCWSg8ZXsZKsf4wbmHnfEicSsgAiamxrp3nsDPIGzA/132"
    end
    local head_url = head
    if string.sub(head, -2, -1) == "/0" then
        head_url = string.sub(head, 1, -2) .. "132"
    end
    return head_url
end

function commonlib.lixian(node, float_node_name, time)
    if node._lixian then
        node._lixian:removeFromParent(true)
        node._lixian = nil
    end
    if not float_node_name then
        node:getChildByName("lixian"):setVisible(false)
        return
    end

    node:getChildByName("lixian"):setVisible(true)

    local lixian = tolua.cast(cc.CSLoader:createNode("ui/OutLineNode.csb"), "ccui.Widget")
    lixian:setPosition(cc.p(ccui.Helper:seekWidgetByName(node, float_node_name):getPosition()))
    node:addChild(lixian, 1000)

    local time     = time or 0
    local time_lbl = ccui.Helper:seekWidgetByName(lixian, "labTip")
    time_lbl:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        time_lbl:setString(string.format("%02d : %02d", math.floor(time / 60), time % 60))
        time = time + 1
    end))))
    node._lixian = lixian
end

function COPY_MSG(str, portrait, parent)
end