local Launcher = class("Launcher")

function Launcher:startGame()
    package.loaded["launcher.util"] = nil
    local util = require("launcher.util")
	util:clearLoadedFiles()
    local LoginScene = require("scene.LoginScene")
    LoginScene.isUpdated = true
    local scene = LoginScene.create()
    cc.Director:getInstance():replaceScene(scene)
end

return Launcher