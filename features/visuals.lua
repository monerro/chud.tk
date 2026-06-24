-- features/visuals.lua
-- Fog, blur, watermark, momentum, etc.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cfg = _G.cfg

local Lighting = game:GetService("Lighting")
local origFogEnd = Lighting.FogEnd
local origFogStart = Lighting.FogStart
local origFogColor = Lighting.FogColor
local blurEffect = nil
local fogConn, blurConn = nil, nil

local function setFog(enabled)
	if enabled then
		fogConn = RunService.Heartbeat:Connect(function()
			pcall(function()
				Lighting.FogEnd = cfg.fogEnd
				Lighting.FogStart = math.max(0, cfg.fogEnd - 60)
				Lighting.FogColor = Color3.fromRGB(190, 190, 190)
			end)
		end)
	else
		if fogConn then fogConn:Disconnect(); fogConn = nil end
		pcall(function()
			Lighting.FogEnd = origFogEnd
			Lighting.FogStart = origFogStart
			Lighting.FogColor = origFogColor
		end)
	end
end

local prevCamPos = nil
local function setBlur(enabled)
	if enabled then
		if not blurEffect then
			blurEffect = Instance.new("BlurEffect")
			blurEffect.Size = 0
			blurEffect.Parent = Lighting
		end
		prevCamPos = camera.CFrame.Position
		blurConn = RunService.RenderStepped:Connect(function()
			if not blurEffect then return end
			local curPos = camera.CFrame.Position
			local moved = (curPos - prevCamPos).Magnitude
			local target = math.clamp(moved * cfg.blurSize, 0, 56)
			blurEffect.Size = blurEffect.Size + (target - blurEffect.Size) * 0.3
			prevCamPos = curPos
		end)
	else
		if blurConn then blurConn:Disconnect(); blurConn = nil end
		if blurEffect then blurEffect:Destroy(); blurEffect = nil end
	end
end

-- Larp Watermark
local larpWatermarkGui = nil
local larpWatermarkEnabled = false
local larpRenderConnection = nil

function toggleLarpWatermark(enabled)
	larpWatermarkEnabled = enabled
	if enabled then
		if larpWatermarkGui then larpWatermarkGui:Destroy() end
		larpWatermarkGui = Instance.new("ScreenGui")
		larpWatermarkGui.Name = "LarpWatermark"
		larpWatermarkGui.ResetOnSpawn = false
		larpWatermarkGui.IgnoreGuiInset = true
		larpWatermarkGui.Parent = player:WaitForChild("PlayerGui")
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 149, 0, 28)
		mainFrame.AnchorPoint = Vector2.new(1, 0)
		mainFrame.Position = UDim2.new(1, -15, 0, 38)
		mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
		mainFrame.BorderSizePixel = 0
		mainFrame.ClipsDescendants = true
		mainFrame.Parent = larpWatermarkGui
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60,60,60)
		stroke.Thickness = 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = mainFrame
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0,8)
		corner.Parent = mainFrame
		local logoImage = Instance.new("ImageLabel")
		logoImage.Size = UDim2.new(0, 63, 0, 63)
		logoImage.Position = UDim2.new(0, -15, 0.2, -25)
		logoImage.BackgroundTransparency = 1
		logoImage.Image = "rbxassetid://133887132709020"
		logoImage.ImageTransparency = 0.7
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.ZIndex = 1
		logoImage.Parent = mainFrame
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -10, 1, 0)
		textLabel.Position = UDim2.new(0, 8, 0, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "larp | user | 0 fps"
		textLabel.TextColor3 = Color3.fromRGB(255,255,255)
		textLabel.Font = Enum.Font.GothamMedium
		textLabel.TextSize = 13
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.ZIndex = 2
		textLabel.RichText = true
		textLabel.Parent = mainFrame
		local lastUpdate = tick()
		local frameCount = 0
		local fps = 0
		local function updateDisplay()
			frameCount = frameCount + 1
			if tick() - lastUpdate >= 0.5 then
				fps = math.floor(frameCount / (tick() - lastUpdate))
				frameCount = 0
				lastUpdate = tick()
				textLabel.Text = string.format('<font color="rgb(79,144,85)" face="GothamBold">larp</font> <font color="rgb(80,80,80)">|</font> <font color="rgb(150,150,150)">%s</font> <font color="rgb(80,80,80)">|</font> <font face="GothamBold">%d</font> <font color="rgb(150,150,150)">fps</font>', player.Name, fps)
			end
		end
		larpRenderConnection = RunService.RenderStepped:Connect(updateDisplay)
	else
		if larpRenderConnection then larpRenderConnection:Disconnect(); larpRenderConnection = nil end
		if larpWatermarkGui then larpWatermarkGui:Destroy(); larpWatermarkGui = nil end
	end
end

-- Momentum tracker
local momentumGui = nil
local momentumEnabled = false
local momentumConnection = nil
local jumpConnection = nil
local charConnection = nil

function toggleMomentum(enabled)
	momentumEnabled = enabled
	if enabled then
		if momentumGui then momentumGui:Destroy() end
		momentumGui = Instance.new("ScreenGui")
		momentumGui.Name = "ClarityMomentum"
		momentumGui.ResetOnSpawn = false
		momentumGui.IgnoreGuiInset = true
		momentumGui.Parent = player:WaitForChild("PlayerGui")
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(0, 400, 0, 50)
		textLabel.Position = UDim2.new(0.5, -200, 0.85, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "0 (0)"
		textLabel.Font = Enum.Font.Nunito
		textLabel.TextSize = 30
		textLabel.TextColor3 = Color3.fromRGB(255,255,255)
		textLabel.ZIndex = 2
		textLabel.RichText = true
		textLabel.Parent = momentumGui
		local lastJumpSpeed = 0
		local function bindJump(char)
			if jumpConnection then jumpConnection:Disconnect() end
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				jumpConnection = hum.StateChanged:Connect(function(old, new)
					if new == Enum.HumanoidStateType.Jumping then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							lastJumpSpeed = math.floor(Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude)
						end
					end
				end)
			end
		end
		if player.Character then bindJump(player.Character) end
		charConnection = player.CharacterAdded:Connect(bindJump)
		momentumConnection = RunService.RenderStepped:Connect(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = player.Character.HumanoidRootPart
				local vel = hrp.AssemblyLinearVelocity
				local speed = math.floor(Vector3.new(vel.X, 0, vel.Z).Magnitude)
				local targetTransparency = 1 - math.clamp(speed / 15, 0, 1)
				if speed < 2 then targetTransparency = 1 end
				textLabel.TextTransparency = textLabel.TextTransparency + (targetTransparency - textLabel.TextTransparency) * 0.1
				textLabel.Text = string.format("%d (%d)", speed, lastJumpSpeed)
			end
		end)
	else
		if momentumConnection then momentumConnection:Disconnect(); momentumConnection = nil end
		if jumpConnection then jumpConnection:Disconnect(); jumpConnection = nil end
		if charConnection then charConnection:Disconnect(); charConnection = nil end
		if momentumGui then momentumGui:Destroy(); momentumGui = nil end
	end
end

_G.Visuals = {
	setFog = setFog,
	setBlur = setBlur,
	toggleLarpWatermark = toggleLarpWatermark,
	toggleMomentum = toggleMomentum
}