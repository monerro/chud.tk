

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- World to screen
function w2s(pos)
	local vec, onscreen = camera:WorldToViewportPoint(pos)
	return Vector2.new(vec.X, vec.Y), onscreen
end

-- Check if another player is enemy
function isEnemy(p)
	local myTeam = player.Team
	if myTeam == nil then return true end
	return p.Team ~= myTeam
end

-- Resolve skin part name (remove spaces)
function resolvePartName(skinEntryName)
	return skinEntryName:gsub("%s+", "")
end

-- Get equipped gun name from character
function getEquippedGunName()
	local char = player.Character
	if not char then return nil end
	local gun = char:FindFirstChild("Gun")
	return gun and gun:GetAttribute("GunName")
end

-- Get arms from camera
function getArms()
	local cam = workspace:FindFirstChild("Camera")
	return cam and cam:FindFirstChild("Arms")
end