--[[
--=====================================================================================================--
Script Name: Spawn From Sky, for SAPP (PC & CE)
Description: Read the title!

             Each map has an associative array:
             ["bloodgulch"] = {

                 -- RED BASE {x,y,z, spawn height above ground}
                 { 95.687797546387, -159.44900512695, -0.10000000149012, 35 },

                 -- BLUE BASE {x,y,z, spawn height above ground}
                 { 40.240600585938, -79.123199462891, -0.10000000149012, 35 },
             },

Copyright (c) 2016-2021, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS/blob/master/LICENSE
--=====================================================================================================--
]]

api_version = "1.12.0.0"

-- config begins --
local maps = {
    ["bloodgulch"] = {
        { 95.687797546387, -159.44900512695, -0.10000000149012, 35 },
        { 40.240600585938, -79.123199462891, -0.10000000149012, 35 },
    },
    ["beavercreek"] = {
        { 29.055599212646, 13.732000350952, -0.10000000149012, 35 },
        { -0.86037802696228, 13.764800071716, -0.0099999997764826, 35 },
    },
    ["boardingaction"] = {
        { 1.723109960556, 0.4781160056591, 0.60000002384186, 35 },
        { 18.204000473022, -0.53684097528458, 0.60000002384186, 35 },
    },
    ["carousel"] = {
        { 5.6063799858093, -13.548299789429, -3.2000000476837, 35 },
        { -5.7499198913574, 13.886699676514, -3.2000000476837, 35 },
    },
    ["chillout"] = {
        { 7.4876899719238, -4.49059009552, 2.5, 35 },
        { -7.5086002349854, 9.750340461731, 0.10000000149012, 35 },
    },
    ["dangercanyon"] = {
        { -12.104507446289, -3.4351840019226, -2.2419033050537, 35 },
        { 12.007399559021, -3.4513700008392, -2.2418999671936, 35 },
    },
    ["deathisland"] = {
        { -26.576030731201, -6.9761986732483, 9.6631727218628, 35 },
        { 29.843469619751, 15.971487045288, 8.2952880859375, 35 },
    },
    ["gephyrophobia"] = {
        { 26.884338378906, -144.71551513672, -16.049139022827, 35 },
        { 26.727857589722, 0.16621616482735, -16.048349380493, 35 },
    },
    ["icefields"] = {
        { 24.85000038147, -22.110000610352, 2.1110000610352, 35 },
        { -77.860000610352, 86.550003051758, 2.1110000610352, 35 },
    },
    ["infinity"] = {
        { 0.67973816394806, -164.56719970703, 15.039022445679, 35 },
        { -1.8581243753433, 47.779975891113, 11.791272163391, 35 },
    },
    ["sidewinder"] = {
        { -32.038200378418, -42.066699981689, -3.7000000476837, 35 },
        { 30.351499557495, -46.108001708984, -3.7000000476837, 35 },
    },
    ["timberland"] = {
        { 17.322099685669, -52.365001678467, -17.751399993896, 35 },
        { -16.329900741577, 52.360000610352, -17.741399765015, 35 },
    },
    ["hangemhigh"] = {
        { 13.047902107239, 9.0331249237061, -3.3619771003723, 35 },
        { 32.655700683594, -16.497299194336, -1.7000000476837, 35 },
    },
    ["ratrace"] = {
        { -4.2277698516846, -0.85564690828323, -0.40000000596046, 35 },
        { 18.613000869751, -22.652599334717, -3.4000000953674, 35 },
    },
    ["damnation"] = {
        { 9.6933002471924, -13.340399742126, 6.8000001907349, 35 },
        { -12.17884349823, 14.982703208923, -0.20000000298023, 35 },
    },
    ["putput"] = {
        { -18.89049911499, -20.186100006104, 1.1000000238419, 35 },
        { 34.865299224854, -28.194700241089, 0.10000000149012, 35 },
    },
    ["prisoner"] = {
        { -9.3684597015381, -4.9481601715088, 5.6999998092651, 35 },
        { 9.3676500320435, 5.1193399429321, 5.6999998092651, 35 },
    },
    ["wizard"] = {
        { -9.2459697723389, 9.3335800170898, -2.5999999046326, 35 },
        { 9.1828498840332, -9.1805400848389, -2.5999999046326, 35 },
    },
    ["longest"] = {
        { -12.791899681091, -21.6422996521, -0.40000000596046, 35 },
        { 11.034700393677, -7.5875601768494, -0.40000000596046, 35 },
    }
}
-- config ends --

local players
local map_table

function OnScriptLoad()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    OnGameStart()
end

local function RegisterSAPPEvents(Load)
    if (Load) then
        register_callback(cb["EVENT_TICK"], "OnTick")
        register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
        register_callback(cb['EVENT_SPAWN'], "OnPlayerSpawn")
        register_callback(cb['EVENT_PRESPAWN'], "OnPreSpawn")
    else
        unregister_callback(cb["EVENT_TICK"])
        unregister_callback(cb["EVENT_JOIN"])
        unregister_callback(cb['EVENT_SPAWN'])
        unregister_callback(cb['EVENT_PRESPAWN'])
    end
end

function OnGameStart()
    if (get_var(0, "$gt") ~= "n/a") then

        players = { }
        map_table = nil

        local map = get_var(0, "$map")
        if (maps[map]) then
            map_table = maps[map]
            RegisterSAPPEvents(true)
        else
            RegisterSAPPEvents(false)
            cprint("[Spawn From Sky] " .. map .. " is not listed!", 12)
        end
    end
end

function OnTick()
    for i, _ in pairs(players) do
        if (i) then
            local DyN = get_dynamic_player(i)
            if (DyN ~= 0) then
                local state = read_byte(DyN + 0x2A3)
                if (state == 21 or state == 22) then
                    execute_command("ungod " .. i)
                    write_word(DyN + 0x104, 0)
                    players[i] = nil
                end
            end
        end
    end
end

local function InitPlayer(Ply)
    players[Ply] = true
end

function OnPlayerJoin(Ply)
    InitPlayer(Ply)
end

function OnPlayerSpawn(Ply)
    if (players[Ply]) then
        execute_command("god " .. Ply)
    end
end

function OnPreSpawn(Ply)
    if (players[Ply]) then
        local DyN = get_dynamic_player(Ply)
        if (DyN ~= 0) then
            local x, y, z, h
            local team = get_var(Ply, "$team")
            if (team == "red") then
                x, y, z, h = map_table[1][1], map_table[1][2], map_table[1][3], map_table[1][4]
            else
                x, y, z, h = map_table[2][1], map_table[2][2], map_table[2][3], map_table[2][4]
            end
            write_vector3d(DyN + 0x5C, x, y, z + h)
        end
    end
end