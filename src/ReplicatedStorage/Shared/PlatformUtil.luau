--!strict
--[=[
	@class PlatformUtil
	Cross-platform detection utilities.
]=]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local PlatformUtil = {}

function PlatformUtil.IsMobile(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function PlatformUtil.IsConsole(): boolean
	return GuiService:IsTenFootInterface()
end

function PlatformUtil.IsPC(): boolean
	return UserInputService.KeyboardEnabled and not GuiService:IsTenFootInterface()
end

function PlatformUtil.HasGamepad(): boolean
	return UserInputService.GamepadEnabled
end

function PlatformUtil.FormatNumber(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end

	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
	local magnitude = math.floor(math.log10(math.abs(n)) / 3)
	magnitude = math.clamp(magnitude, 0, #suffixes - 1)

	local scaled = n / (10 ^ (magnitude * 3))
	if scaled >= 100 then
		return string.format("%d%s", math.floor(scaled), suffixes[magnitude + 1])
	elseif scaled >= 10 then
		return string.format("%.1f%s", scaled, suffixes[magnitude + 1])
	else
		return string.format("%.2f%s", scaled, suffixes[magnitude + 1])
	end
end

return PlatformUtil
