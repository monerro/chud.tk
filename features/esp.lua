

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local cfg = _G.ESP_CFG  -- use ESP config
local features = _G.features
local isEnemy = _G.isEnemy
local w2s = _G.w2s
local create_line, create_text, create_square = _G.create_line, _G.create_text, _G.create_square

local espEnabled = false
local espConn = nil
local espObjects = {}
local crouching = {}

local r15_bones = {
	{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local r6_bones = {
	{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
	{"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}
local custom_bones = {
	{"Head", "Torso"}, {"Torso", "Left Upper Arm"}, {"Left Upper Arm", "Left Lower Arm"}, {"Left Lower Arm", "Left Hand"},
	{"Torso", "Right Upper Arm"}, {"Right Upper Arm", "Right Lower Arm"}, {"Right Lower Arm", "Right Hand"},
	{"Torso", "Left Upper Leg"}, {"Left Upper Leg", "Left Lower Leg"}, {"Left Lower Leg", "Left Foot"},
	{"Torso", "Right Upper Leg"}, {"Right Upper Leg", "Right Lower Leg"}, {"Right Lower Leg", "Right Foot"}
}

local function rig(c)
	local h = c:FindFirstChildOfClass("Humanoid")
	if h and h.RigType == Enum.HumanoidRigType.R15 then return r15_bones end
	if c:FindFirstChild("Left Upper Arm") then return custom_bones end
	return r6_bones
end

local function get_character_bounds(c)
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local corners = {}
	local size = hrp.Size
	local cf = hrp.CFrame
	local offsets = {
		Vector3.new(size.X/2, size.Y/2, size.Z/2), Vector3.new(-size.X/2, size.Y/2, size.Z/2),
		Vector3.new(size.X/2, -size.Y/2, size.Z/2), Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
		Vector3.new(size.X/2, size.Y/2, -size.Z/2), Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
		Vector3.new(size.X/2, -size.Y/2, -size.Z/2), Vector3.new(-size.X/2, -size.Y/2, -size.Z/2)
	}
	for _, offset in ipairs(offsets) do
		local worldPos = cf:PointToWorldSpace(offset)
		local screenPos, onScreen = w2s(worldPos)
		if onScreen then table.insert(corners, screenPos) end
	end
	if #corners == 0 then return nil end
	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	for _, corner in pairs(corners) do
		minX = math.min(minX, corner.X); maxX = math.max(maxX, corner.X)
		minY = math.min(minY, corner.Y); maxY = math.max(maxY, corner.Y)
	end
	return {
		topLeft = Vector2.new(minX, minY),
		size = Vector2.new(maxX - minX, maxY - minY),
		center = Vector2.new((minX + maxX) / 2, (minY + maxY) / 2)
	}
end

local function cl(p)
	if espObjects[p] then
		if espObjects[p].lines then
			for _, bone_data in pairs(espObjects[p].lines) do
				if bone_data.line then bone_data.line:Remove() end
			end
		end
		if espObjects[p].box then espObjects[p].box:Remove() end
		if espObjects[p].box_outline then espObjects[p].box_outline:Remove() end
		if espObjects[p].box_fill then espObjects[p].box_fill:Remove() end
		if espObjects[p].healthbar_bg then espObjects[p].healthbar_bg:Remove() end
		if espObjects[p].healthbar then espObjects[p].healthbar:Remove() end
		if espObjects[p].name then espObjects[p].name:Remove() end
		if espObjects[p].distance then espObjects[p].distance:Remove() end
		if espObjects[p].tracer then espObjects[p].tracer:Remove() end
		if espObjects[p].tracer_outline then espObjects[p].tracer_outline:Remove() end
		espObjects[p] = nil
	end
	crouching[p] = nil
end

local function makeESP(p)
	if not p:IsA("Player") or not espEnabled then return end
	if p.Team == player.Team and p.Team ~= nil then cl(p); return end
	cl(p)
	local c = p.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return end
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if cfg.crouch_detection then crouching[p] = h.HipHeight < cfg.crouch_height_threshold end

	local bones = rig(c)
	local lines = {}
	for _, bone in pairs(bones) do
		local part1 = c:FindFirstChild(bone[1])
		local part2 = c:FindFirstChild(bone[2])
		if part1 and part2 then
			local line = create_line()
			table.insert(lines, {line = line, p1 = part1, p2 = part2})
		end
	end

	local box = cfg.box_enabled and create_square() or nil
	local box_outline = (cfg.box_enabled and cfg.box_thickness > 0) and create_square() or nil
	local box_fill = (cfg.box_enabled and cfg.box_filled) and create_square() or nil
	if box_outline then
		box_outline.Thickness = cfg.box_thickness + 1
		box_outline.Color = Color3.new(0,0,0)
	end
	if box_fill then
		box_fill.Filled = true
		box_fill.Color = cfg.box_fill_color
		box_fill.Transparency = cfg.box_fill_transparency
	end
	local healthbar_bg = cfg.healthbar_enabled and create_square() or nil
	local healthbar = cfg.healthbar_enabled and create_square() or nil
	if healthbar_bg then
		healthbar_bg.Filled = true
		healthbar_bg.Color = Color3.new(0,0,0)
		healthbar_bg.Transparency = 0.5
	end
	if healthbar then healthbar.Filled = true end
	local name_text = cfg.name_enabled and create_text() or nil
	if name_text then
		name_text.Size = cfg.name_size
		name_text.Color = cfg.name_color
		name_text.Outline = cfg.name_outline
	end
	local distance_text = cfg.distance_enabled and create_text() or nil
	if distance_text then
		distance_text.Size = cfg.distance_size
		distance_text.Color = cfg.distance_color
		distance_text.Outline = true
	end
	local tracer = cfg.tracer_enabled and create_line() or nil
	local tracer_outline = (cfg.tracer_enabled and cfg.tracer_thickness > 1) and create_line() or nil
	if tracer then
		tracer.Thickness = cfg.tracer_thickness
		tracer.Color = cfg.tracer_color
		tracer.Transparency = cfg.tracer_transparency
	end
	if tracer_outline then
		tracer_outline.Thickness = cfg.tracer_thickness + 2
		tracer_outline.Color = Color3.new(0,0,0)
		tracer_outline.Transparency = cfg.tracer_transparency * 0.5
	end

	espObjects[p] = {
		lines = lines,
		character = c,
		humanoid = h,
		box = box,
		box_outline = box_outline,
		box_fill = box_fill,
		healthbar_bg = healthbar_bg,
		healthbar = healthbar,
		name = name_text,
		distance = distance_text,
		tracer = tracer,
		tracer_outline = tracer_outline
	}
end

local function updateESP()
	for p, data in pairs(espObjects) do
		local c = data.character
		local h = data.humanoid
		if not c or not c.Parent or not h or h.Health <= 0 then cl(p); continue end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hrp then cl(p); continue end
		if cfg.crouch_detection and h then crouching[p] = h.HipHeight < cfg.crouch_height_threshold end
		local is_crouching = crouching[p]
		local skel_color = is_crouching and cfg.crouch_color or cfg.skeleton_color

		if data.lines then
			for _, bone_data in pairs(data.lines) do
				local line = bone_data.line
				local p1 = bone_data.p1
				local p2 = bone_data.p2
				if p1 and p1.Parent and p2 and p2.Parent then
					local pos1, on1 = w2s(p1.Position)
					local pos2, on2 = w2s(p2.Position)
					if on1 and on2 then
						line.From = pos1
						line.To = pos2
						line.Color = skel_color
						line.Thickness = cfg.skeleton_thickness
						line.Transparency = cfg.skeleton_transparency
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		end

		local bounds = get_character_bounds(c)
		if bounds then
			if cfg.box_enabled and data.box then
				if data.box_outline then
					data.box_outline.Position = bounds.topLeft - Vector2.new(1,1)
					data.box_outline.Size = bounds.size + Vector2.new(2,2)
					data.box_outline.Visible = true
				end
				if data.box_fill then
					data.box_fill.Position = bounds.topLeft
					data.box_fill.Size = bounds.size
					data.box_fill.Visible = true
				end
				data.box.Position = bounds.topLeft
				data.box.Size = bounds.size
				data.box.Color = cfg.box_color
				data.box.Thickness = cfg.box_thickness
				data.box.Visible = true
			else
				if data.box then data.box.Visible = false end
				if data.box_outline then data.box_outline.Visible = false end
				if data.box_fill then data.box_fill.Visible = false end
			end

			if cfg.healthbar_enabled and data.healthbar and data.healthbar_bg then
				local barWidth = 3
				local barHeight = bounds.size.Y
				local healthPercent = h.Health / h.MaxHealth
				data.healthbar_bg.Position = Vector2.new(bounds.topLeft.X - barWidth - 3, bounds.topLeft.Y)
				data.healthbar_bg.Size = Vector2.new(barWidth, barHeight)
				data.healthbar_bg.Visible = true
				local currentHeight = barHeight * healthPercent
				data.healthbar.Position = Vector2.new(bounds.topLeft.X - barWidth - 3, bounds.topLeft.Y + barHeight - currentHeight)
				data.healthbar.Size = Vector2.new(barWidth, currentHeight)
				data.healthbar.Color = cfg.healthbar_color_high:Lerp(cfg.healthbar_color_low, 1 - healthPercent)
				data.healthbar.Visible = true
			else
				if data.healthbar then data.healthbar.Visible = false end
				if data.healthbar_bg then data.healthbar_bg.Visible = false end
			end

			if cfg.name_enabled and data.name then
				data.name.Text = p.DisplayName
				data.name.Position = Vector2.new(bounds.center.X, bounds.topLeft.Y - 15)
				data.name.Color = cfg.name_color
				data.name.Size = cfg.name_size
				data.name.Visible = true
			elseif data.name then data.name.Visible = false end

			if cfg.distance_enabled and data.distance then
				local dist = (hrp.Position - camera.CFrame.Position).Magnitude
				data.distance.Text = string.format("%d studs", math.floor(dist))
				data.distance.Position = Vector2.new(bounds.center.X, bounds.topLeft.Y + bounds.size.Y + 2)
				data.distance.Color = cfg.distance_color
				data.distance.Size = cfg.distance_size
				data.distance.Visible = true
			elseif data.distance then data.distance.Visible = false end
		else
			if data.box then data.box.Visible = false end
			if data.box_outline then data.box_outline.Visible = false end
			if data.box_fill then data.box_fill.Visible = false end
			if data.healthbar then data.healthbar.Visible = false end
			if data.healthbar_bg then data.healthbar_bg.Visible = false end
			if data.name then data.name.Visible = false end
			if data.distance then data.distance.Visible = false end
		end

		if cfg.tracer_enabled and data.tracer then
			local pos, onscreen = w2s(hrp.Position)
			if onscreen then
				local fromPos
				if cfg.tracer_from == "Bottom" then
					fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				elseif cfg.tracer_from == "Middle" then
					fromPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
				elseif cfg.tracer_from == "Top" then
					fromPos = Vector2.new(camera.ViewportSize.X / 2, 0)
				elseif cfg.tracer_from == "Mouse" then
					fromPos = Vector2.new(mouse.X, mouse.Y)
				end
				if data.tracer_outline then
					data.tracer_outline.From = fromPos
					data.tracer_outline.To = pos
					data.tracer_outline.Visible = true
				end
				data.tracer.From = fromPos
				data.tracer.To = pos
				data.tracer.Color = cfg.tracer_color
				data.tracer.Visible = true
			else
				data.tracer.Visible = false
				if data.tracer_outline then data.tracer_outline.Visible = false end
			end
		else
			if data.tracer then data.tracer.Visible = false end
			if data.tracer_outline then data.tracer_outline.Visible = false end
		end
	end
end

local function toggleESP(enabled)
	espEnabled = enabled
	if enabled then
		refreshESP()
		espConn = RunService.RenderStepped:Connect(updateESP)
	else
		if espConn then espConn:Disconnect(); espConn = nil end
		for _, p in pairs(Players:GetPlayers()) do cl(p) end
	end
end

function refreshESP()
	if not espEnabled then
		for _, p in pairs(Players:GetPlayers()) do cl(p) end
		return
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then makeESP(p) end
	end
end

-- Player added/removed connections
Players.PlayerAdded:Connect(function(p)
	if not espEnabled then return end
	p.CharacterAdded:Connect(function()
		task.wait(1)
		if p ~= player and espEnabled then makeESP(p) end
	end)
end)
Players.PlayerRemoving:Connect(function(p)
	if espEnabled then cl(p) end
end)

_G.ESP = {
	toggle = toggleESP,
	refresh = refreshESP
}