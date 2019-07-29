cc.exports.ProfileManager = cc.exports.ProfileManager or {}

if(not ProfileManager.profiles) then ProfileManager.profiles = {}; end

if(not ProfileManager.game_list) then ProfileManager.game_list = {}; end

if(not ProfileManager.room_list) then ProfileManager.room_list = {}; end

function ProfileManager.SetUID(uid)
    ProfileManager.uid = uid
end

function ProfileManager.GetUID()
    return ProfileManager.uid
end

function ProfileManager.IsCurrentUser(uid)
    if(ProfileManager.uid and ProfileManager.uid ~= "") then
        return (uid == nil or uid == "" or uid == "loggedinuser" or uid == ProfileManager.uid)
    end
end

-------------------------- profile-------------------
local Profile = {}
function Profile:new(o)
    o = o or {}; -- create object if user does not provide one

    if(o.uid == nil) then
        -- the profile's uid must not be nil.
        print("error: YMKJ.data.Profile:new:new(o), uid must not be nil\n");
        o.uid = 0;
    end
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function ProfileManager.GetProfile(uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    uid = uid or ""
    return ProfileManager.profiles[uid]
end

function ProfileManager.SetProfile(profile, uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    if(uid and type(profile) == "table") then
        profile.uid                  = uid;  -- set init uid
        profile                      = Profile:new(profile)
        ProfileManager.profiles[uid] = profile;
    end
end

function ProfileManager.UpdateProfile(profile, uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    if(uid and type(profile) == "table") then
        local old_profile = ProfileManager.profiles[uid]
        local k, v;
        for k, v in pairs(profile) do
            old_profile[k] = v;
        end
        ProfileManager.profiles[uid] = old_profile
    end
end

-------------------------- game-------------------
function ProfileManager.Get_game_list(uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    uid = uid or ""
    return ProfileManager.game_list[uid]
end

function ProfileManager.Get_my_game_from_id(id, uid)
    local game_list = ProfileManager.Get_game_list(uid);
    if(game_list) then
        return game_list[id];
    end
end

function ProfileManager.Set_game_list(game_list, uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    if uid then
        local my_game_list = {}
        for _, game in ipairs(game_list or {}) do
            if game.r_t_id then
                my_game_list[game.r_t_id] = game
            end
        end
        ProfileManager.game_list[uid] = my_game_list
    end
end

function ProfileManager.Get_cur_game_name()
    local profile   = ProfileManager.GetProfile()
    local room      = ProfileManager.Get_my_room_from_id(tostring(profile.cur_room_id or 1))
    local game_list = ProfileManager.Get_game_list()
    for k, v in pairs(game_list) do
        if v.r_t_id == room.room_type_id then
            return v.r_t_name
        end
    end
end
-------------------------- room-------------------
function ProfileManager.Get_room_list(uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    uid = uid or ""
    return ProfileManager.room_list[uid]
end

function ProfileManager.Get_my_room_from_id(id, uid)
    local room_list = ProfileManager.Get_room_list(uid);
    if(room_list) then
        return room_list[id];
    end
end

function ProfileManager.Set_room_list(room_list, uid)
    if(ProfileManager.IsCurrentUser(uid)) then
        uid = ProfileManager.GetUID()
    end
    if uid then
        local my_room_list = {}
        for _, room in ipairs(room_list or {}) do
            if room.game_room_id then
                my_room_list[room.game_room_id] = room
            end
        end
        ProfileManager.room_list[uid] = my_room_list
    end
end