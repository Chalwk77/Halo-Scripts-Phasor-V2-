--[[
--=====================================================================================================--
Script Name: Auto Message, for SAPP (PC & CE)
Description: This script will periodically announce defined messages from an announcements array.
You can manually broadcast a message from this array with a simple command (see below).

Command Syntax:
/broadcast list (view list of available announcements)
/broadcast [message id] (force immediate announcement broadcast)

Copyright (c) 2021, Jericho Crosby <jericho.crosby227@gmail.com>
* Notice: You can use this document subject to the following conditions:
https://github.com/Chalwk77/Halo-Scripts-Phasor-V2-/blob/master/LICENSE

* Written by Jericho Crosby (Chalwk)
--=====================================================================================================--
]]--

local AutoMessage = {

    -- ANNOUNCEMENTS ARRAY --
    announcements = {
        { "Message 1 (line 1)", "Message 1 (line 2)" }, -- message 1
        { "Like us on Facebook | facebook.com/page_id" }, -- message 2
        { "Follow us on Twitter | twitter.com/twitter_id" }, -- message 3
        { "We are recruiting. Sign up on our website | website url" }, -- message 4
        { "Rules / Server Information" }, -- message 5
        { "announcement 6" }, -- message 6
        { "other information here" }, -- message 7
    },

    -- Time (in seconds) between message announcements:
    interval = 300,

    -- Set to false to send messages to player console:
    show_announcements_in_chat = true,

    -- If true, messages will also be printed to server console terminal (in pink):
    show_announcements_on_console = true,

    -- Custom command used to view or broadcast announcements:
    command = "broadcast",

    -- Minimum permission level required to execute custom broadcast command:
    permission = 1,

    -- A message relay function temporarily removes the server prefix
    -- and will restore it to this when the relay is finished:
    server_prefix = "**SAPP**"
    --
}

api_version = "1.12.0.0"

local time_scale = 1 / 30
local lower, gmatch = string.lower, string.gmatch

function OnScriptLoad()
    register_callback(cb['EVENT_TICK'], "OnTick")
    register_callback(cb['EVENT_GAME_END'], "OnGameEnd")
    register_callback(cb['EVENT_GAME_START'], "OnNewGame")
    register_callback(cb['EVENT_COMMAND'], "OnServerCommand")
    AutoMessage:Timer(true)
end

function AutoMessage:Timer(START)
    if (get_var(0, "$gt") ~= "n/a") then
        self.index, self.timer = 1, 0
        if (START) then
            self.init = true
        else
            self.init = false
        end
    end
end

function OnNewGame()
    AutoMessage:Timer(true)
end

function OnGameEnd()
    AutoMessage:Timer(false)
end

function AutoMessage:GameTick()
    if (self.init) then
        self.timer = self.timer + time_scale
        if (self.timer >= self.interval) then
            self.timer = 0

            for _ = 1, #self.announcements do
                if (self.index == #self.announcements + 1) then
                    self.index = 1
                end
            end

            self:Show(self.announcements[self.index])
            self.index = self.index + 1
        end
    end
end

function AutoMessage:Show(TAB)
    for _, Msg in pairs(TAB) do
        if (self.show_announcements_on_console) then
            cprint(Msg, 13)
        end
        if (self.show_announcements_in_chat) then
            execute_command("msg_prefix \"\"")
            say_all(Msg)
            execute_command("msg_prefix \" **" .. self.server_prefix .. "**\"")
            return
        end
        for i = 1, 16 do
            if player_present(i) then
                rprint(i, Msg)
            end
        end
    end
end

function AutoMessage:Respond(Ply, Msg, Color)
    Color = Color or 10
    if (Ply == 0) then
        cprint(Msg, Color)
    else
        rprint(Ply, Msg)
    end
end

local function CMDSplit(CMD)
    local Args = { }
    for Params in gmatch(CMD, "([^%s]+)") do
        Args[#Args + 1] = lower(Params)
    end
    return Args
end

function AutoMessage:OnServerCommand(Ply, Command, _, _)
    local Args = CMDSplit(Command)
    if (Args) then
        if (Args[1] == self.command) then
            local lvl = tonumber(get_var(Ply, "$lvl"))
            if (lvl >= self.permission or Ply == 0) then

                local invalid
                if (Args[2] ~= nil) then

                    if (Args[2] == Args[2]:match("list")) then
                        local t = self.announcements
                        for i = 1, #t do
                            for _, v in pairs(t[i]) do
                                self:Respond(Ply, "[" .. i .. "] " .. v)
                            end
                        end

                    elseif (Args[2]:match("^%d+$") and Args[3] == nil) then
                        local n = tonumber(Args[2])
                        if (self.announcements[n]) then
                            self:Show(self.announcements[n])
                        else
                            self:Respond(Ply, "Invalid Broadcast ID", 12)
                            self:Respond(Ply, "Please enter a number between 1-" .. #self.announcements, 12)
                        end
                    else
                        invalid = true
                    end
                else
                    invalid = true
                end
                if (invalid) then
                    self:Respond(Ply, "Invalid Command Syntax. Please try again!", 12)
                end
            end
            return false
        end
    end
end

function OnTick()
    return AutoMessage:GameTick()
end

function OnServerCommand(P, C, _, _)
    return AutoMessage:OnServerCommand(P, C, _, _)
end