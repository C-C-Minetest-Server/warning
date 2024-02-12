-- warning/init.lua
-- Emphasize warnings sent by the moderation team
--[[
    warning: Emphasize warnings sent by the moderation team
    Copyright (C) 2024  1F616EMO

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
]]

local S = minetest.get_translator("warning")

local function get_warning_string(name, param)
    local color = minetest.settings:get("warning.color")
    if not color or color == "" then
        color = "yellow"
    end

    return minetest.colorize(color, "[" .. S("MODERATOR WARNING") .. "]") .. " <" .. name .. "> " .. param
end

minetest.register_chatcommand("warn", {
    description = S("Give moderator warnings"),
    privs = {ban = true},
    func = function(name, param)
        param = string.trim(param)
        if param == "" then
            return false, S("Message must not be empty.")
        end

        minetest.chat_send_all(get_warning_string(name, param))
        return true
    end
})

minetest.register_chatcommand("dmwarn", {
    description = S("Give moderator warnings via private message"),
    privs = {ban = true},
    func = function(name, param)
        local res = string.split(param, " ", false, 1)
        local targ, msg = res[1], res[2]
        if not targ or targ == "" then
            return false, S("Target must not be empty.")
        end

        if not minetest.get_player_by_name(targ) then
            return false, S("The player is not online.")
        end

        msg = string.trim(msg or "")
        if msg == "" then
            return false, S("Message must not be empty.")
        end

        local warnstr = get_warning_string(name, msg)
        minetest.chat_send_player(targ, S("(dm)") .. " " .. warnstr)
        return true, S("(dm to @1)", targ) .. " " .. warnstr
    end
})