local CorePackages = game:GetService("CorePackages")

local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Cryo = require(CorePackages.Packages.Cryo)
local Rodux = require(CorePackages.Packages.Rodux)
local AddMessage = require(script.Parent.Parent.Actions.AddMessage)
local RemoveMessage = require(script.Parent.Parent.Actions.RemoveMessage)
local PlayerRemoved = require(RobloxGui.Modules.VoiceChat.Actions.PlayerRemoved)

local GetFFlagBubbleVoiceCleanupOnLeave = require(RobloxGui.Modules.Flags.GetFFlagBubbleVoiceCleanupOnLeave)

local userMessages = Rodux.createReducer({
	-- [userId] = { messageId, ... }
}, {
	-- Adds the message's ID to the specific user's list of sent messages. This
	-- is used with ChatBubbles so that we can efficiently grab the user's last
	-- few messages, instead of iterating over the entire list of messages.
	[AddMessage.name] = function(state, action)
		local messages = state[action.message.userId] or {}

		return Cryo.Dictionary.join(state, {
			[action.message.userId] = Cryo.List.join(messages, { action.message.id })
		})
	end,

	[RemoveMessage.name] = function(state, action)
		local messages = state[action.message.userId]

		if messages then
			if #messages == 1 and messages[1] == action.message.id then
				return Cryo.Dictionary.join(state, {
					[action.message.userId] = Cryo.None,
				})
			else
				return Cryo.Dictionary.join(state, {
					[action.message.userId] = Cryo.List.filter(messages, function(messageId)
						return messageId ~= action.message.id
					end)
				})
			end
		else
			return state
		end
	end,

	[PlayerRemoved.name] = function(state, action)
		-- This shouldn't get called if the flag is off, but just to be safe.
		if not GetFFlagBubbleVoiceCleanupOnLeave() then
			return state
		end

		local messages = state[action.userId]

		if messages then
			return Cryo.Dictionary.join(state, {
				[action.userId] = Cryo.None,
			})
		else
			return state
		end
	end
})

return userMessages
