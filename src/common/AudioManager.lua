local AudioManager = class("AudioManager")

local KEY_IS_MUSICABLE = "isMusicable"
local KEY_IS_SOUNDABLE = "isSoundable"
local KEY_MUSIC_VOLUME = "musicVolume"
local KEY_SOUND_VOLUME = "soundVolume"

function AudioManager:ctor()
    self.isMusicable = cc.UserDefault:getInstance():getBoolForKey(KEY_IS_MUSICABLE, true);
    self.isSoundable = cc.UserDefault:getInstance():getBoolForKey(KEY_IS_SOUNDABLE, true);

    self.musicVolume = cc.UserDefault:getInstance():getFloatForKey(KEY_MUSIC_VOLUME, 0.5)
    self.soundVolume = cc.UserDefault:getInstance():getFloatForKey(KEY_SOUND_VOLUME, 0.5)

    self.musicPath      = nil
    self.isMusicStarted = false

    self:setMusicVolume(self:getMusicVolume())
    self:setSoundVolume(self:getSoundVolume())
end

function AudioManager:restartManager()
    audio.restartAudio()
    self:setMusicVolume(self:getMusicVolume())
    self:setSoundVolume(self:getSoundVolume())
end

function AudioManager:playMusic(filePath, bLoop)
    if self.musicPath ~= nil and self.musicPath == filePath and self.isMusicStarted then
        return
    end
    self.musicPath = filePath
    if self.isMusicable then
        if self.isMusicStarted then
            audio.resumeMusic()
            audio.setMusicVolume(self.musicVolume)
        else
            if g_os == "ios" then
                audio.preloadMusic(filePath)
            end
            audio.playMusic(filePath, bLoop or false)
            audio.setMusicVolume(self.musicVolume)
        end
        self.isMusicStarted = true
    end
end

function AudioManager:playSound(filePath, bLoop)
    if self.isSoundable then
        audio.playSound(filePath, bLoop)
    end
end

function AudioManager:playPubBgMusic()
    self:playMusic("sound/bgMain.mp3", true)
end

function AudioManager:playDWCBgMusic(music_name)
    self:playMusic(music_name, true)
end

function AudioManager:stopPubBgMusic()
    audio.stopMusic(false)
    self.musicPath      = nil
    self.isMusicStarted = false
end

function AudioManager:playPressSound()
    self:playSound("sound/Button32.mp3")
end

function AudioManager:playDropGoldSound()
    self:playSound("music/luojinbi.mp3")
end

function AudioManager:playDWCSound(sound_name)
    self:playSound(sound_name)
end

function AudioManager:playLongSound(sound_name)
    return self:playSound(sound_name, true)
end

function AudioManager:pauseMusic()
    audio.pauseMusic()
    -- audio.setMusicVolume(0)
    self.isMusicStarted = false
end

function AudioManager:resumeMusic()
    -- self:playMusic(self.musicPath)
    audio.resumeMusic()
end

function AudioManager:stopSound(soundId)
    if soundId then
        audio.stopSound(soundId)
    end
end

function AudioManager:stopAllEff()
    audio.stopAllSounds()
end

-- 音乐音效音量 get set方法,只接受0-1范围的小数，与实际参数一致
function AudioManager:setMusicVolume(set)
    if not set or type(set) ~= "number" then return end

    audio.setMusicVolume(set)
    self.musicVolume = set
    cc.UserDefault:getInstance():setFloatForKey(KEY_MUSIC_VOLUME, self.musicVolume)
    cc.UserDefault:getInstance():flush()
end

function AudioManager:getMusicVolume()
    return self.musicVolume
end

-- 音乐音效音量 get set方法,只接受0-1范围的小数，与实际参数一致
function AudioManager:setSoundVolume(set)
    if not set or type(set) ~= "number" then return end

    audio.setSoundsVolume(set)
    self.soundVolume = set
    cc.UserDefault:getInstance():setFloatForKey(KEY_SOUND_VOLUME, self.soundVolume)
    cc.UserDefault:getInstance():flush()
end

function AudioManager:getSoundVolume()
    return self.soundVolume
end

function AudioManager:getMusicable()
    return self.isMusicable
end

function AudioManager:setMusicable(isMusicable)
    if self.isMusicable == isMusicable then
        return
    end

    self.isMusicable = isMusicable
    cc.UserDefault:getInstance():setBoolForKey(KEY_IS_MUSICABLE, self.isMusicable)
    cc.UserDefault:getInstance():flush()

    if self.isMusicable then
        self:playMusic(self.musicPath)
    else
        self:pauseMusic()
    end
end

function AudioManager:getSoundable()
    return self.isSoundable
end

function AudioManager:setSoundable(isSoundable)
    if self.isSoundable == isSoundable then
        return
    end

    self.isSoundable = isSoundable
    cc.UserDefault:getInstance():setBoolForKey(KEY_IS_SOUNDABLE, self.isSoundable)
    cc.UserDefault:getInstance():flush()
end

return AudioManager