

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cfg = _G.cfg
local features = _G.features
local isEnemy = _G.isEnemy  -- from helpers

local function getNearestHead()
	local closest, closestDist = nil, math.huge
	local camCF = camera.CFrame; local camPos = camCF.Position; local camLook = camCF.LookVector
	local fovRad = math.rad(cfg.aimbotFOV)
	for _, p in ipairs(Players:GetPlayers()) do
		if p == player or not isEnemy(p) then continue end
		local char = p.Character; if not char then continue end
		local head = char:FindFirstChild("Head")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not head or not hum or hum.Health <= 0 then continue end
		local toHead = head.Position - camPos
		local dist = toHead.Magnitude
		local angle = math.acos(math.clamp(camLook:Dot(toHead.Unit), -1, 1))
		if angle > fovRad then continue end
		if dist < closestDist then closestDist = dist; closest = head end
	end
	return closest
end

local function fakeaimbot_start()
	features.FakeAimbot.conn = RunService.RenderStepped:Connect(function(dt)
		local held = false
		local btn = cfg.aimbotButton
		if typeof(btn) == "EnumItem" then
			if btn.EnumType == Enum.UserInputType then held = UserInputService:IsMouseButtonPressed(btn)
			elseif btn.EnumType == Enum.KeyCode then held = UserInputService:IsKeyDown(btn) end
		end
		if not held then return end
		local head = getNearestHead()
		if not head then return end
		local dir = (head.Position - camera.CFrame.Position).Unit
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + dir), math.min(dt * cfg.aimbotSmooth, 1))
	end)
end

_G.Aimbot = {
	start = fakeaimbot_start,
	stop = function()
		if features.FakeAimbot.conn then features.FakeAimbot.conn:Disconnect(); features.FakeAimbot.conn = nil end
	end
}