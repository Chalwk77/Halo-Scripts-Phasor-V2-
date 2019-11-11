--[[
--=====================================================================================================--
Script Name: One In The Chamber (v1.0), for SAPP (PC & CE)
Description: Each player is given a pistol - and only a pistol - with one bullet. 
             Use it wisely. Every shot kills. 
             If you miss, you're limited to Melee-Combat. 
             Every time you kill a player, you get a bullet. 
             Success requires a combination of precision and reflexes. Know when to go for the shot or close in for the kill.

Copyright (c) 2019, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/Halo-Scripts-Phasor-V2-/blob/master/LICENSE

* Written by Jericho Crosby (Chalwk)
--=====================================================================================================--
]]--

api_version = "1.12.0.0"

-- Configuration Starts --
local starting_primary_ammo = 1
local starting_secondary_ammo = 0
local ammo_per_kill = 1
local starting_frags = 0
local starting_plasmas = 0
local weapon = "weapons\\pistol\\pistol"
local bullet_damage_multiplier = 10
local hud_message = "Bullets: %count%"
-- Configuration Ends --

-- # Do Not Touch # --
local players, game_over = {}, false
local gsub = string.gsub

function OnScriptLoad()
    register_callback(cb["EVENT_TICK"], "OnTick")
    register_callback(cb['EVENT_DIE'], "OnPlayerKill")
    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    register_callback(cb["EVENT_SPAWN"], "OnPlayerSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerConnect")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerDisconnect")
    register_callback(cb['EVENT_DAMAGE_APPLICATION'], "OnDamageApplication")

    -- Disable all vehicles
    execute_command("disable_all_vehicles 0 1")

    -- Disable weapon pick ups:
    execute_command("disable_object 'weapons\\assault rifle\\assault rifle'")
    execute_command("disable_object 'weapons\\flamethrower\\flamethrower'")
    execute_command("disable_object 'weapons\\needler\\mp_needler'")
    execute_command("disable_object 'weapons\\pistol\\pistol'")
    execute_command("disable_object 'weapons\\plasma pistol\\plasma pistol'")
    execute_command("disable_object 'weapons\\plasma rifle\\plasma rifle'")
    execute_command("disable_object 'weapons\\plasma_cannon\\plasma_cannon'")
    execute_command("disable_object 'weapons\\rocket launcher\\rocket launcher'")
    execute_command("disable_object 'weapons\\shotgun\\shotgun'")
    execute_command("disable_object 'weapons\\sniper rifle\\sniper rifle'")

    -- Disable grenade pick ups:
    execute_command("disable_object 'weapons\\frag grenade\\frag grenade'")
    execute_command("disable_object 'weapons\\plasma grenade\\plasma grenade'")
    if (get_var(0, "$gt") ~= "n/a") then
        players = {}
        for i = 1, 16 do
            if player_present(i) then
                InitPlayer(i, true)
            end
        end
    end
end

function OnGameStart()
    if (get_var(0, "$gt") ~= "n/a") then
        players = {}
    end
end

function OnGameEnd()
    game_over = true
end

function OnTick()
    if (not game_over) then
        for i, player in pairs(players) do
            if player_present(i) and player_alive(i) then
                if (player.assign) then
                    local player_object = get_dynamic_player(i)
                    local coords = getXYZ(i, player_object)
                    if (not coords.invehicle) then
                        player.assign = false
                        execute_command("wdel " .. i)
                        assign_weapon(spawn_object("weap", weapon, coords.x, coords.y, coords.z), i)
                        SetAmmo(i, "loaded", starting_primary_ammo)
                        SetAmmo(i, "unloaded", starting_secondary_ammo)
                    end
                else
                    cls(i, 25)
                    local ammo = GetAmmo(i, "loaded")
                    rprint(i, gsub(hud_message, "%%count%%", ammo))
                end
            end
        end
    end
end

function OnPlayerConnect(PlayerIndex)
    InitPlayer(PlayerIndex, true)
end

function OnPlayerDisconnect(PlayerIndex)
    InitPlayer(PlayerIndex, false)
end

function OnPlayerKill(VictimIndex, KillerIndex)
    if (not game_over) then

        local killer = tonumber(KillerIndex)
        local victim = tonumber(VictimIndex)

        for i, _ in pairs(players) do
            if (i == killer) then
                local ammo = GetAmmo(i, "loaded") + (ammo_per_kill)
                SetAmmo(i, "loaded", ammo)
            elseif (i == victim) then
                InitPlayer(i, true)
            end
        end
    end
end

function GetAmmo(PlayerIndex, Type)
    local player_object = get_dynamic_player(PlayerIndex)
    if (player_object ~= 0) then
        local WeaponID = read_dword(player_object + 0x118)
        if (WeaponID ~= 0) then
            local WeaponObject = get_object_memory(WeaponID)
            if (WeaponObject ~= 0) then
                if (Type == "unloaded") then
                    return read_dword(WeaponObject + 0x2B6)
                elseif (Type == "loaded") then
                    return read_dword(WeaponObject + 0x2B8)
                end
            end
        end
    end
    return 0
end

function SetAmmo(PlayerIndex, Type, Amount)
    local player_object = get_dynamic_player(PlayerIndex)
    if (player_object ~= 0) then
        local WeaponID = read_dword(player_object + 0x118)
        if (WeaponID ~= 0) then
            for w = 1, 4 do
                if (Type == "unloaded") then
                    execute_command("ammo " .. PlayerIndex .. " " .. Amount .. " " .. w)
                elseif (Type == "loaded") then
                    execute_command("mag " .. PlayerIndex .. " " .. Amount .. " " .. w)
                end
            end
        end
    end
end

function OnPlayerSpawn(PlayerIndex)
    local player_object = get_dynamic_player(PlayerIndex)
    if (player_object ~= 0) then
        write_byte(player_object + 0x31E, starting_frags)
        write_byte(player_object + 0x31F, starting_plasmas)
        players[PlayerIndex].assign = true
    end
end

function OnDamageApplication(PlayerIndex, CauserIndex, MetaID, Damage, HitString, Backtap)
    if (tonumber(CauserIndex) > 0 and PlayerIndex ~= CauserIndex) then
        if (MetaID == GetTag("jpt!", "weapons\\pistol\\bullet")) then
            return true, Damage * bullet_damage_multiplier
        end
    end
end

function InitPlayer(PlayerIndex, Init)
    if (Init) then
        players[PlayerIndex] = { assign = false }
    else
        players[PlayerIndex] = nil
    end
end

function getXYZ(PlayerIndex, PlayerObject)
    local coords, x, y, z = { }

    local VehicleID = read_dword(PlayerObject + 0x11C)
    if (VehicleID == 0xFFFFFFFF) then
        coords.invehicle = false
        x, y, z = read_vector3d(PlayerObject + 0x5c)
    else
        coords.invehicle = true
        x, y, z = read_vector3d(get_object_memory(VehicleID) + 0x5c)
    end
    coords.x, coords.y, coords.z = x, y, z
    return coords
end

function cls(PlayerIndex, Count)
    Count = Count or 25
    for _ = 1, Count do
        rprint(PlayerIndex, " ")
    end
end

function GetTag(obj_type, obj_name)
    local tag = lookup_tag(obj_type, obj_name)
    return tag ~= 0 and read_dword(tag + 0xC) or nil
end

function OnScriptUnload()
    --
end
