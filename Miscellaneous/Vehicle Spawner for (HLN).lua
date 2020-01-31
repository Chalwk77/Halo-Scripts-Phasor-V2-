--[[
--======================================================================================================--
Script Name: HLN Vehicle Spawner (v1.0), for SAPP (PC & CE)
Description: N/A (details to come)

NOTE: This script has missing logic and does not function 100% at this time. Download at your own risk.

Copyright (c) 2020, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/Halo-Scripts-Phasor-V2-/blob/master/LICENSE

* Written by Jericho Crosby (Chalwk)
--======================================================================================================--
]]--

api_version = "1.12.0.0"

-- Configuration [Starts] ---------------------------------------------
local settings = {

	spawns_per_game = 10, -- Number of vehicles the player can spawn PER GAME.
	despawn_time = 30,
	cooldown_duration = 5,
	
	on_spawn = "Vehicle spawns remaining: %total%",
	please_wait = "Please wait %seconds% to spawn another vehicle",
	
	insufficient_spawns = "You have exceeded your Vehicle Spawn Limit for this game.",

	-- Valid Seats:
	--	0 = drivers
	--	1 = passengers
	--	3 = gunners
	--	4 = passengers (tank)
	--	5 = passengers (tank)
	--	6 = passengers (tank)
	--  7 (custom) - driver/gunner seat 
	
	["hog"] = {
		-- valid seats: 
		seat = 0, -- warthog - driver only
		vehicle = "vehicles\\warthog\\mp_warthog",
	},
	
	["hog2"] = {
		seat = 7, -- warthog - drive as gunner
		vehicle = "vehicles\\warthog\\mp_warthog",
	},
	
	["rhog"] = {
		seat = 0, -- warthog - driver only
		vehicle = "vehicles\\rwarthog\\rwarthog",
	},
	
	["rhog2"] = {
		seat = 7, -- warthog - drive as gunner
		vehicle = "vehicles\\rwarthog\\rwarthog",
	},
	
	-- It's now set up so that you will drive as gunner for the warthog but not for the Rhog (for testing)
}
-- Configuration [Ends] ---------------------------------------------


-- do not touch unless you know what you are doing:
local spawns = {}
local vehicle_objects = {}
local time_scale = 0.03333333333333333
local gmatch, gsub = string.gmatch, string.gsub

function InitPlayer(PlayerIndex, Reset)
	if not (Reset) then
		spawns[PlayerIndex] = {
			cooldown = settings.cooldown_duration,
			trigger = false,
			count = settings.spawns_per_game,
		}
	else
		-- clear the array for this player:
		spawns[PlayerIndex] = {}
	end
end

function OnScriptLoad()
	register_callback(cb["EVENT_JOIN"], "OnPlayerConnect")
	register_callback(cb["EVENT_LEAVE"], "OnPlayerDisconnect")
	register_callback(cb["EVENT_CHAT"], "OnPlayerChat")
	register_callback(cb["EVENT_TICK"], "OnTick")
	register_callback(cb["EVENT_DIE"], "OnPlayerDeath")
	
	if (get_var(0, "$gt") ~= "n/a") then
		for i = 1,16 do
			InitPlayer(i, false)
		end
	end
end

function OnTick()
	for i = 1,16 do
		if player_present(i) and player_alive(i) then
			local t = spawns[i]
			if (t.trigger) then
				t.cooldown = t.cooldown - time_scale
				if (t.cooldown <= 1) then
					t.cooldown = settings.cooldown_duration
					t.trigger = false
				end
			end
		end
	end
	
	for k,v in pairs(vehicle_objects) do
		if vehicle_objects[k] ~= nil then
			local vehicle = get_object_memory(k)
			
			-- TODO: 
			-- Occupation Logic
			if (vehicle == 0xFFFFFFFF) then

			
				vehicle_objects[k].timer = vehicle_objects[k].timer - time_scale
				if (vehicle_objects[k].timer <= 0) then
					destroy_object(k)
					vehicle_objects[k] = nil
				end
			end
		end
	end
end

function OnPlayerChat(PlayerIndex, Message, Type)
    local msg = stringSplit(Message)
    local p = tonumber(PlayerIndex)
	
	if (Type ~= 6) then
		if (#msg == 0) then
			return false
		else
			for k,v in pairs(settings) do
				if (msg[1] == k) then
				
					local t = spawns[PlayerIndex]
				
					if (t.count > 0) then
						if (not t.trigger) then
						
							local player_object = get_dynamic_player(PlayerIndex)
							local coords = getXYZ(PlayerIndex, player_object)
							
							if not (coords.invehicle) then
								t.trigger = true
								t.count = t.count - 1
								
								local vehicle = spawn_object("vehi", settings[k].vehicle, coords.x, coords.y, coords.z)
								
								local vehicle_object_memory = get_object_memory(vehicle)
								
								if (vehicle_object_memory ~= 0) then
									vehicle_objects[vehicle] = {
										occupied = true,
										timer = settings.despawn_time,
									}
								end								
								
								if (tonumber(settings[k].seat) == 7) then
									enter_vehicle(vehicle, PlayerIndex, 0)
									enter_vehicle(vehicle, PlayerIndex, 2)
								else
									enter_vehicle(vehicle, PlayerIndex, 0)
								end		
								
								local msg = gsub(settings.on_spawn, "%%total%%", tostring(t.count))
								rprint(PlayerIndex, msg)
								
								return false
							else
								rprint(PlayerIndex, "You are already in a vehicle!")
								return false
							end
						else
							local message = gsub(settings.please_wait, "%%seconds%%", tostring(math.floor(t.cooldown)))
							rprint(PlayerIndex, message)
							return false
						end
					else
						rprint(PlayerIndex, settings.insufficient_spawns)
						return false
					end
				end
			end
		end
	end
end

function OnPlayerConnect(PlayerIndex)
	InitPlayer(PlayerIndex, false)
end

function OnPlayerDisconnect(PlayerIndex)
	InitPlayer(PlayerIndex, true)
end

function OnPlayerDeath(PlayerIndex)
	spawns[PlayerIndex].trigger = false
	spawns[PlayerIndex].cooldown = settings.cooldown_duration
end

function stringSplit(Command)
    local t, i = {}, 1
    for String in gmatch(Command, "([^%s]+)") do
        t[i] = String
        i = i + 1
    end
    return t
end

function getXYZ(PlayerIndex, PlayerObject)
    local coords, x, y, z = { }
    if player_alive(PlayerIndex) then
        local VehicleID = read_dword(PlayerObject + 0x11C)
        if (VehicleID == 0xFFFFFFFF) then
            coords.invehicle = false
            x, y, z = read_vector3d(PlayerObject + 0x5c)
        else
            coords.invehicle = true
            x, y, z = read_vector3d(get_object_memory(VehicleID) + 0x5c)
        end

        if (coords.invehicle) then
            z = z + 1
        end
        coords.x, coords.y, coords.z = x, y, z
    end
    return coords
end

