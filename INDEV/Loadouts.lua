--[[
--=====================================================================================================--
Script Name: LoadOut, for SAPP (PC & CE)
Description: N/A

~ acknowledgements ~
Concept credit goes to OSH Clan, a gaming community operating on Halo CE.
- website:  https://oldschoolhalo.boards.net/

Copyright (c) 2020, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/Halo-Scripts-Phasor-V2-/blob/master/LICENSE

* Written by Jericho Crosby (Chalwk)
--=====================================================================================================--
]]--

api_version = "1.12.0.0"
-- Configuration Begins --
local loadout = {

    default_class = "Regeneration",
    starting_level = 1,

    classes = {
        ["Regeneration"] = {
            command = "regen",
            weapons = {
                -- primary, secondary, tertiary, quaternary
                [1] = { 1, 2, nil, nil },
                [2] = { 1, 2, nil, nil },
                [3] = { 1, 2, nil, nil },
                [4] = { 1, 2, nil, nil },
                [5] = { 1, 2, nil, nil },
            }
        },
        ["Armor Boost"] = {
            command = "armor",
        },
        ["Partial Camo"] = {
            command = "camo",
        },
        ["Recon"] = {
            command = "speed",
        }
    },

    weapon_tags = {
        -- ============= [ STOCK WEAPONS ] ============= --
        [1] = "weapons\\pistol\\pistol",
        [2] = "weapons\\sniper rifle\\sniper rifle",
        [3] = "weapons\\plasma_cannon\\plasma_cannon",
        [4] = "weapons\\rocket launcher\\rocket launcher",
        [5] = "weapons\\plasma pistol\\plasma pistol",
        [6] = "weapons\\plasma rifle\\plasma rifle",
        [7] = "weapons\\assault rifle\\assault rifle",
        [8] = "weapons\\flamethrower\\flamethrower",
        [9] = "weapons\\needler\\mp_needler",
        [10] = "weapons\\shotgun\\shotgun",

        -- ============= [ CUSTOM WEAPONS ] ============= --
        [11] = "some_random\\weapon\\epic",

        -- repeat the structure to add more weapon tags:
        [31] = "some_random\\weapon\\epic",
    }
}
-- Configuration Ends --

local gmatch, gsub = string.gmatch, string.gsub
local lower, upper = string.lower, string.upper

local function Init()
    loadout.players = { }
    for i = 1, 16 do
        if player_present(i) then
            InitPlayer(i, false)
        end
    end
end

function OnScriptLoad()

    register_callback(cb["EVENT_TICK"], "OnTick")

    register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")

    register_callback(cb["EVENT_COMMAND"], "OnServerCommand")

    register_callback(cb["EVENT_SPAWN"], "OnPlayerSpawn")
    register_callback(cb["EVENT_JOIN"], "OnPlayerConnect")
    register_callback(cb["EVENT_LEAVE"], "OnPlayerDisconnect")

    if (get_var(0, '$gt') ~= "n/a") then
        Init()
    end
end

function OnScriptUnload()

end

function OnGameStart()
    if (get_var(0, '$gt') ~= "n/a") then
        Init()
    end
end

function OnGameEnd()

end

local function CmdSplit(Cmd)
    local t, i = {}, 1
    for Args in gmatch(Cmd, "([^%s]+)") do
        t[i] = Args
        i = i + 1
    end
    return t
end

function OnServerCommand(Executor, Command, _, _)
    local Args = CmdSplit(Command)
    if (Args == nil) then
        return
    else

        Args[1] = (lower(Args[1]) or upper(Args[1]))
        for class, v in pairs(loadout.classes) do
            if (Args[1] == v.command) then
                if (loadout.players[Executor].class == class) then
                    return Respond(Executor, "You already have that class!", "rprint", 12)
                end
            end
        end
    end
end

local function GetWeapon(WeaponIndex)
    return loadout.weapon_tags[WeaponIndex]
end

function OnTick()
    for i, player in pairs(loadout.players) do
        if (i) and player_alive(i) then
            if (player.assign) then

                local DyN = get_dynamic_player(i)
                local coords = getXYZ(DyN)

                if (not coords.invehicle) then
                    player.assign = false
                    execute_command("wdel " .. i)

                    local weapon_table = loadout.classes[player.class].weapons[player.level]

                    for Slot, WeaponIndex in pairs(weapon_table) do
                        if (Slot == 1 or Slot == 2) then
                            assign_weapon(spawn_object("weap", GetWeapon(WeaponIndex), coords.x, coords.y, coords.z), i)
                        elseif (Slot == 3 or Slot == 4) then
                            timer(250, "DelaySecQuat", i, GetWeapon(WeaponIndex), coords.x, coords.y, coords.z)
                        end
                    end
                end
            end
        end
    end
end

function InitPlayer(Ply, Reset)
    if (Reset) then
        loadout.players[Ply] = { }
    else
        loadout.players[Ply] = {
            exp = 0,
            assign = true,
            rank_up = false,
            class = loadout.default_class,
            level = loadout.starting_level,
        }
    end
end

function OnPlayerConnect(Ply)
    InitPlayer(Ply, false)
end

function OnPlayerDisconnect(Ply)
    InitPlayer(Ply, true)
end

function OnPlayerSpawn(Ply)
    loadout.players[Ply].assign = true
end

function Respond(Ply, Message, Type, Color)

    Color = Color or 10
    execute_command("msg_prefix \"\"")

    Message = gsub(Message, "%%script_prefix%%", loadout.script_prefix)

    if (Ply == 0) then
        cprint(Message, Color)
    end

    if (Type == "rprint") then
        rprint(Ply, Message)
    elseif (Type == "say") then
        say(Ply, Message)
    elseif (Type == "say_all") then
        say_all(Message)
    end
    execute_command("msg_prefix \" " .. loadout.serverPrefix .. "\"")
end

function DelaySecQuat(Ply, Weapon, x, y, z)
    assign_weapon(spawn_object("weap", Weapon, x, y, z), Ply)
end

function getXYZ(DyN)
    local coords, x, y, z = { }

    local VehicleID = read_dword(DyN + 0x11C)
    if (VehicleID == 0xFFFFFFFF) then
        coords.invehicle = false
        x, y, z = read_vector3d(DyN + 0x5c)
    else
        coords.invehicle = true
        x, y, z = read_vector3d(get_object_memory(VehicleID) + 0x5c)
    end

    coords.x, coords.y, coords.z = x, y, z
    return coords
end