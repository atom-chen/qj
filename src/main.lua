cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

math.randomseed(tostring(os.time()):reverse():sub(1, 6))

require("config")
require("cocos.init")

g_os = ymkj.baseInfo(10)
g_mac_addr = ymkj.baseInfo(2)

is_test = (g_os=="win")
g_channel_id = 800002
g_package_ver = 18 --限制游客登录标志
--6 初始包
--7 优化电量信号量
--8 添加speex
--9 重写热更新
--10 添加亲聊
--11 更换亲聊SDK
g_base_ver = 11 --是否强制整包更新标志 老包：<7 新包：7
g_can_ddshare = nil
g_is_multi_wechat = nil
--1 秦晋体验版  true 秦晋测试
test_package = nil
-- g_author_game = "csmj"
--是否是新版热更新
g_is_new_update = true

--qjui 秦晋更换ui的新版本
--qjupd 秦晋重写热更新的版本
package_name = "qjupd"

--是否播放主界面动画
--nil 原包，播动画，不显示
--true 特殊包，不播动画，显示
g_close_main_ani = true

if g_os == "win" then
    require("YYServer")
end

local function main()
    -- require("app.MyApp"):create():run()

    if g_os == 'win' then
        cc.Director:getInstance():setDisplayStats(CC_SHOW_FPS)
    end

    local director = cc.Director:getInstance()

    --turn on display FPS
    --director:setDisplayStats(true)

    --set FPS. the default value is 1.0/60 if you don't call this
    director:setAnimationInterval(1.0 / 30)

    cc.exports.g_visible_size = director:getVisibleSize()

    if createResDownloadDir then
        local downloadResDir = createResDownloadDir()
        cc.FileUtils:getInstance():addSearchPath(downloadResDir, true)
        cc.FileUtils:getInstance():addSearchPath(string.format("%s/src/", downloadResDir), true)
        cc.FileUtils:getInstance():addSearchPath(string.format("%s/res/", downloadResDir), true)
    end

    local downloadDir = createDownloadDir()
    cc.FileUtils:getInstance():addSearchPath(downloadDir, true)
    cc.FileUtils:getInstance():addSearchPath(string.format("%s/src/",downloadDir), true)
    cc.FileUtils:getInstance():addSearchPath(string.format("%s/res/",downloadDir), true)
    if g_is_new_update then
        local scene = require("launcher.UpdateScene"):create()
        cc.Director:getInstance():runWithScene(scene)
    else
        local scene = require("scene.LoginScene"):create()
        cc.Director:getInstance():runWithScene(scene)
    end
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end