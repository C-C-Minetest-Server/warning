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
local builtin_S = minetest.get_translator("__builtin")

local function get_warning_string(msg)
    local color = minetest.settings:get("warning.color")
    if not color or color == "" then
        color = "yellow"
    end

    return minetest.colorize(color, "[" .. S("MODERATOR WARNING") .. "] ") .. msg
end

local send_msg, send_dm
if minetest.get_modpath("beerchat") then
    -- From beerchat
    send_msg = function(name, msg)
        local channel
        if name == "CONSOLE" and minetest.get_modpath("szutil_consocket") then
            channel = beerchat.main_channel_name
        else
            channel = beerchat.get_player_channel(name)
            if not channel then
                beerchat.fix_player_channel(name, false)
                return false, "Channel "..beerchat.currentPlayerChannel[name].." does not exist, switching back to "..
                    beerchat.main_channel_name..". Please resend your message"
            elseif not beerchat.playersChannels[name][channel] then
                return false, "You need to join channel " .. channel
                    .. " in order to be able to send messages to it"
            end
        end
        beerchat.send_on_channel({
            name=name,
            channel=channel,
            message=get_warning_string(msg)
        })
        minetest.sound_play("warning_alarm", {
            gain = 0.3,
        }, true)
        return true
    end
    send_dm = function(name, target, msg)
        local formatted_msg = get_warning_string(msg)
        if beerchat.execute_callbacks("before_send_pm", name, formatted_msg, target) then
			-- Sending the message
			minetest.chat_send_player(
				target,
				beerchat.format_message(
					"[PM] from (${from_player}) ${message}", {
						from_player = name,
						to_player = target,
						message = formatted_msg
					}
				)
			)
            minetest.chat_send_player(
                name,
                beerchat.format_message(
                    "[PM] sent to @(${to_player}) ${message}", {
                        to_player = target,
                        message = formatted_msg
                    }
                )
            )
            beerchat.sound_play(target, "beerchat_chime")
			beerchat.sound_play(target, "warning_alarm")
			return true
		end
    end
else
    send_msg = function(name, msg)
        minetest.chat_send_all(minetest.format_chat_message(name, get_warning_string(msg)))
        minetest.sound_play("warning_alarm", {
            gain = 0.3,
        }, true)
        return true
    end
    send_dm = function(name, target, msg)
        if not minetest.get_player_by_name(target) then
            return false, builtin_S("The player @1 is not online.", target)
        end
        local formatted_msg = get_warning_string(msg)
        minetest.chat_send_player(target, builtin_S("DM from @1: @2", name, formatted_msg))
        minetest.sound_play("warning_alarm", {
            to_player = target,
            gain = 0.3,
        }, true)
        return true, S("DM to @1: @2", target, formatted_msg)
    end
end

minetest.register_chatcommand("warn", {
    description = S("Give moderator warnings"),
    privs = {ban = true},
    func = function(name, param)
        param = string.trim(param)
        if param == "" then
            return false, S("Message must not be empty.")
        end

        return send_msg(name, param)
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

        msg = string.trim(msg or "")
        if msg == "" then
            return false, S("Message must not be empty.")
        end

        return send_dm(name, targ, msg)
    end
})