--[[
--=====================================================================================================--
Script Name: Deployable Mines, for SAPP (PC & CE)
Description: Deploy super-explosive mines while driving.
             To Deploy a mine, press your flashlight key.

Copyright (c) 2021, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/HALO-SCRIPT-PROJECTS/blob/master/LICENSE
--=====================================================================================================--
]]--

-- Configuration Starts --
local Mines = {

    -- The number of mines players will spawn with:
    mines_per_life = 20,
    --

    -- Time (in seconds) until a mine despawns:
    despawn_rate = 60,
    --

    -- Trigger explosion when player is <= this many w/units
    trigger_radius = 0.7,
    --

    ["bloodgulch"] = {
        -- Object that represents the mine:
        "powerups\\health pack",

        -- (proj) Object used to simulate explosion:
        -- We spawn a rocket projectile and instantly make it explode:
        "weapons\\rocket launcher\\rocket",

        -- (!jpt) Tag path of the projectile used to simulate explosion:
        "weapons\\rocket launcher\\explosion"
    },

    ["deathisland"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["icefields"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["infinity"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["sidewinder"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["timberland"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["dangercanyon"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["beavercreek"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["boardingaction"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["carousel"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["chillout"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["damnation"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["gephyrophobia"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["hangemhigh"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["longest"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["prisoner"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["putput"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["ratrace"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["wizard"] = {
        "powerups\\health pack",
        "weapons\\rocket launcher\\rocket",
        "weapons\\rocket launcher\\explosion"
    },
    ["tsce_multiplayerv1"] = {
        "cmt\\powerups\\human\\powerup_pack\\powerups\\health_pack",
        "cmt\\weapons\\evolved_h1-spirit\\rocket_launcher\\projectiles\\rocket_launcher_rocket\\rocket_launcher_rocket",
        "cmt\\weapons\\evolved_h1-spirit\\rocket_launcher\\damage_effects\\rocket_launcher_rocket_explosion"
    },
    --

    -- vehicle tag paths --
    -- Set to false to disable vehicle dispensing on per-vehicle basis:
    vehicles = {

        ["vehicles\\ghost\\ghost_mp"] = true,
        ["vehicles\\rwarthog\\rwarthog"] = true,
        ["vehicles\\warthog\\mp_warthog"] = true,
        ["vehicles\\banshee\\banshee_mp"] = true,
        ["vehicles\\scorpion\\scorpion_mp"] = true,
        ["vehicles\\c gun turret\\c gun turret_mp"] = true,

        -- tsce_multiplayerv1 vehicles--
        ["soi\\vehicles\\scorpion\\scorpion"] = true,
        ["cmt\\vehicles\\evolved_h1-spirit\\ghost\\_ghost_mp\\ghost_mp"] = true,
        ["cmt\\vehicles\\evolved_h1-spirit\\warthog\\_warthog_mp\\warthog_mp"] = true,
        ["cmt\\vehicles\\evolved_h1-spirit\\warthog\\_warthog_rocket\\warthog_rocket"] = true
    },
    --

    -- A message relay function temporarily removes the server prefix
    -- and will restore it to this when the relay is finished:
    server_prefix = "**SAPP**"
    --
}

-- Configuration Ends --

local team_play
local rocket_meta
local dma_original, dma
local tag_count, tag_address

local sqrt = math.sqrt
local time_scale = 1 / 30

api_version = "1.12.0.0"

function OnScriptLoad()
    register_callback(cb["EVENT_GAME_START"], "OnGameStart")
    OnGameStart()
end

function Mines:InitPlayer(Ply, Reset)

    if (not Reset) then
        self.players[Ply] = {
            key = nil,
            damage_meta = nil,
            killer = nil,
            mines = self.mines_per_life,
            name = get_var(Ply, "$name"),
        }
        return
    end

    self.players[Ply] = nil
end

local function GetTag(Type, Name)
    local Tag = lookup_tag(Type, Name)
    return (Tag ~= 0 and read_dword(Tag + 0xC)) or nil
end

local function TagName(TAG)
    if (TAG ~= nil and TAG ~= 0) then
        return read_string(read_dword(read_word(TAG) * 32 + 0x40440038))
    end
    return ""
end

function Mines:Init()

    self.game_in_progress = false

    if (get_var(0, "$gt") ~= "n/a") then

        local map = get_var(0, "$map")
        if (self[map]) then

            self.map = map

            register_callback(cb["EVENT_TICK"], "OnTick")
            register_callback(cb["EVENT_DIE"], "CheckDamage")
            register_callback(cb["EVENT_JOIN"], "OnPlayerJoin")
            register_callback(cb["EVENT_GAME_END"], "OnGameEnd")
            register_callback(cb["EVENT_LEAVE"], "OnPlayerQuit")
            register_callback(cb["EVENT_SPAWN"], "OnPlayerSpawn")
            register_callback(cb["EVENT_DAMAGE_APPLICATION"], "CheckDamage")

            tag_count = read_dword(0x4044000C)
            tag_address = read_dword(0x40440000)

            dma = sig_scan("8B42348A8C28D500000084C9") + 3
            dma_original = read_dword(dma)

            self.game_in_progress = true

            team_play = (get_var(0, "$ffa") == "0") or false
            rocket_meta = GetTag("jpt!", "weapons\\rocket launcher\\explosion")

            self:ClearAllMines()
            self.players = { }

            for i = 1, 16 do
                if player_present(i) then
                    self:InitPlayer(i, false)
                end
            end
            return
        end

        unregister_callback(cb["EVENT_TICK"])
        unregister_callback(cb["EVENT_DIE"])
        unregister_callback(cb["EVENT_JOIN"])
        unregister_callback(cb["EVENT_GAME_END"])
        unregister_callback(cb["EVENT_LEAVE"])
        unregister_callback(cb["EVENT_SPAWN"])
        unregister_callback(cb["EVENT_DAMAGE_APPLICATION"])
    end
end

function OnGameStart()
    Mines:Init()
end

function OnGameEnd()
    Mines.game_in_progress = false
    Mines:ClearAllMines()
end

local function GetPos(DyN)
    local pos = { }

    local VehicleID = read_dword(DyN + 0x11C)
    local Object = get_object_memory(VehicleID)

    if (VehicleID == 0xFFFFFFFF) then
        pos.x, pos.y, pos.z = read_vector3d(DyN + 0x5c)
    elseif (Object ~= 0) then
        pos.object = Object
        pos.seat = read_word(DyN + 0x2F0)
        pos.x, pos.y, pos.z = read_vector3d(Object + 0x5c)
    end

    return pos
end

function Mines:NewMine(Ply, X, Y, Z)

    local mine = spawn_object("eqip", self[self.map][1], X, Y, Z)
    local object = get_object_memory(mine)

    self.mines[mine] = {
        x = X,
        y = Y,
        z = Z,
        timer = 0,
        owner = Ply,
        object = object
    }

    local mines_left = self.players[Ply].mines
    rprint(Ply, "Mine Deployed! " .. mines_left .. "/" .. self.mines_per_life)
end

function Mines:InProximity(px, py, pz, mx, my, mz)
    return sqrt((px - mx) ^ 2 + (py - my) ^ 2 + (pz - mz) ^ 2) <= self.trigger_radius
end

function Mines:OnTick()

    if (self.game_in_progress) then

        for i, v in pairs(self.players) do

            local DyN = get_dynamic_player(i)
            if (player_alive(i) and DyN ~= 0) then
                local key = read_bit(DyN + 0x208, 4)
                if (self.key ~= key and key == 1) then
                    if (v.mines > 0) then
                        local pos = GetPos(DyN)
                        if (pos.seat and pos.seat == 0) then
                            for tag, enabled in pairs(self.vehicles) do
                                if (TagName(pos.object) == tag and enabled) then
                                    pos.in_vehicle = true
                                    v.mines = v.mines - 1
                                    self:NewMine(i, pos.x, pos.y, pos.z)
                                    break
                                end
                            end
                        end
                    else
                        rprint(i, "You have 0 mines left for this life!")
                    end
                end
                self.key = key
            end
        end

        for k, v in pairs(self.mines) do

            v.timer = v.timer + time_scale
            if (v.timer >= self.despawn_rate) then
                self:Destroy(k)
            else

                local object = get_object_memory(k)
                if (object ~= 0) then

                    if (not player_present(v.owner)) then
                        self:Destroy(k)
                    else

                        local mx, my, mz = read_vector3d(object + 0x5c)
                        v.x, v.y, v.z = mx, my, mz
                        for i, Ply in pairs(self.players) do

                            if (i ~= v.owner) then

                                local DyN = get_dynamic_player(i)
                                if (player_alive(i) and DyN ~= 0) then

                                    local pos = GetPos(DyN)
                                    if self:InProximity(pos.x, pos.y, pos.z, v.x, v.y, v.z) then
                                        if (not team_play or get_var(i, "$team") ~= get_var(v.owner, "$team")) then

                                            EditRocket(false)

                                            local tag = GetTag("proj", self[self.map][2])

                                            local projectile = spawn_projectile(tag, i, v.x, v.y, v.z)
                                            local proj_obj = get_object_memory(projectile)

                                            write_float(proj_obj + 0x68, 0)
                                            write_float(proj_obj + 0x6C, 0)
                                            write_float(proj_obj + 0x70, -9999)

                                            timer(1000, "EditRocket", "true")

                                            Ply.killer = v.owner
                                            self:Destroy(k)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Mines:Destroy(mine)
    destroy_object(mine)
    self.mines[mine] = nil
end

function Mines:ClearAllMines()
    self.mines = self.mines or { }
    for k, _ in pairs(self.mines) do
        destroy_object(k)
    end
    self.mines = { }
end

function OnPlayerJoin(Ply)
    Mines:InitPlayer(Ply, false)
end

function Mines:OnPlayerSpawn(Ply)
    if (self.players and self.players[Ply]) then
        self.players[Ply].key = nil
        self.players[Ply].killer = nil
        self.players[Ply].damage_meta = nil
        self.players[Ply].mines = self.mines_per_life
    end
end

function OnPlayerQuit(Ply)
    Mines:InitPlayer(Ply, true)
end

function Mines:CheckDamage(Ply, Server, MetaID, _, _)
    Server = tonumber(Server)

    if (self.players and self.players[Ply]) then
        if (Server == 0 and MetaID) then
            self.players[Ply].damage_meta = MetaID
        elseif (Server == 0 and self.players[Ply].damage_meta == rocket_meta) then

            local name = self.players[Ply].name
            local KID = self.players[Ply].killer
            if (KID) then

                safe_write(true)
                write_dword(dma, 0x03EB01B1)
                safe_write(false)

                execute_command("msg_prefix \"\"")
                say_all(name .. " was blown up by " .. self.players[KID].name .. "'s mine!")
                execute_command("msg_prefix \" **" .. self.server_prefix .. "**\"")

                safe_write(true)
                write_dword(dma, dma_original)
                safe_write(false)
            end

            return false
        end
    end
end

function EditRocket(rollback)
    for i = 0, tag_count - 1 do
        local tag = tag_address + 0x20 * i
        local tag_name = read_string(read_dword(tag + 0x10))
        local tag_class = read_dword(tag)
        if (tag_class == 1785754657 and tag_name == Mines[Mines.map][3]) then
            local tag_data = read_dword(tag + 0x14)
            if (not rollback) then
                write_dword(tag_data + 0x1d0, 1148846080)
                write_dword(tag_data + 0x1d4, 1148846080)
                write_dword(tag_data + 0x1d8, 1148846080)
                write_dword(tag_data + 0x1f4, 1092616192)
            else
                write_dword(tag_data + 0x1d0, 1117782016)
                write_dword(tag_data + 0x1d4, 1133903872)
                write_dword(tag_data + 0x1d8, 1134886912)
                write_dword(tag_data + 0x1f4, 1086324736)
            end
            break
        end
    end
end

function OnScriptUnload()
    Mines:ClearAllMines()
end

function OnTick()
    return Mines:OnTick()
end
function CheckDamage(V, C, M)
    return Mines:CheckDamage(V, C, M)
end
function OnPlayerSpawn(Ply)
    return Mines:OnPlayerSpawn(Ply)
end

return Mines