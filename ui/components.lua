-- ui/components.lua
-- Reusable UI building functions

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local COLORS = _G.COLORS
local SIZES = _G.SIZES
local FONTS = _G.FONTS

-- Helper to create instances
local function new(class, props)
	local obj = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do obj[k] = v end
	if parent then obj.Parent = parent end
	return obj
end

function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

function stroke(parent, color, thickness)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent
	})
end

function padding(parent, all)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		Parent = parent
	})
end

function vlist(parent, gap)
	return new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
		Parent = parent
	})
end

-- Icon maker (Lucide or glyph fallback)
local ICON_NAMES = {
	movement = "move", aimbot = "crosshair", visuals = "eye", misc = "settings-2",
	inventory = "sword", config = "cog",
}
local GLYPH = {
	movement = "\u{2725}", aimbot = "\u{25CE}", visuals = "\u{25C9}", misc = "\u{2261}",
	inventory = "\u{25A6}", config = "\u{2699}",
}

local Lucide = nil
local function loadLucide()
	if Lucide then return end
	local module = nil
	local rs = game:GetService("ReplicatedStorage")
	local direct = rs:FindFirstChild("Lucide") or rs:FindFirstChild("lucide-roblox")
	if direct and direct:IsA("ModuleScript") then module = direct end
	if not module then
		for _, d in ipairs(rs:GetDescendants()) do
			if d:IsA("ModuleScript") and (d.Name == "Lucide" or d.Name == "lucide-roblox") then
				module = d; break
			end
		end
	end
	if module then
		local ok, mod = pcall(require, module)
		if ok and type(mod) == "table" and mod.GetAsset then Lucide = mod end
	end
	if not Lucide then
		local ok, mod = pcall(function() return loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/download/0.1.3/lucide-roblox.luau"))() end)
		if ok and type(mod) == "table" and mod.GetAsset then Lucide = mod end
	end
end

function makeIcon(name, color, size)
	loadLucide()
	local iconName = ICON_NAMES[name]
	if Lucide and iconName then
		local ok, asset = pcall(Lucide.GetAsset, iconName, 48)
		if ok and asset then
			return new("ImageLabel", {
				BackgroundTransparency = 1,
				Image = asset.Url,
				ImageRectSize = asset.ImageRectSize,
				ImageRectOffset = asset.ImageRectOffset,
				ImageColor3 = color,
				Size = UDim2.fromOffset(size, size)
			})
		end
	end
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Text = GLYPH[name] or "\u{2022}",
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = size,
		Size = UDim2.fromOffset(size, size),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center
	})
end

-- Slider builder
function buildSlider(parent, xOff, yOff, labelTxt, minV, maxV, initV, trackW, onCh)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -xOff, 0, 14)
	row.Position = UDim2.new(0, xOff, 0, yOff)
	row.BackgroundTransparency = 1
	row.ZIndex = 6
	row.Parent = parent

	local sLbl = Instance.new("TextLabel")
	sLbl.Size = UDim2.new(0,34,1,0)
	sLbl.BackgroundTransparency = 1
	sLbl.Text = labelTxt
	sLbl.TextColor3 = COLORS.labelOff
	sLbl.Font = FONTS.label
	sLbl.TextSize = 9
	sLbl.TextXAlignment = Enum.TextXAlignment.Left
	sLbl.ZIndex = 7
	sLbl.Parent = row

	local track = Instance.new("Frame")
	track.Size = UDim2.new(0, trackW, 0, 2)
	track.Position = UDim2.new(0,36,0.5,-1)
	track.BackgroundColor3 = COLORS.checkOff
	track.BorderSizePixel = 0
	track.ZIndex = 7
	track.Parent = row
	corner(track, 1)

	local frac = math.clamp((initV - minV) / (maxV - minV), 0, 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(frac,0,1,0)
	fill.BackgroundColor3 = COLORS.accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 8
	fill.Parent = track
	corner(fill, 1)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0,8,0,8)
	knob.AnchorPoint = Vector2.new(0.5,0.5)
	knob.Position = UDim2.new(frac,0,0.5,0)
	knob.BackgroundColor3 = COLORS.title
	knob.BorderSizePixel = 0
	knob.ZIndex = 9
	knob.Parent = track
	corner(knob, 4)

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(0,32,1,0)
	valLbl.Position = UDim2.new(0, trackW + 40, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(initV)
	valLbl.TextColor3 = COLORS.title
	valLbl.Font = FONTS.label
	valLbl.TextSize = 9
	valLbl.TextXAlignment = Enum.TextXAlignment.Left
	valLbl.ZIndex = 7
	valLbl.Parent = row

	local sd = false
	local function apply(ax)
		local t = math.clamp((ax - track.AbsolutePosition.X) / trackW, 0, 1)
		local v = math.floor(minV + t * (maxV - minV) + 0.5)
		local f2 = (v - minV) / (maxV - minV)
		fill.Size = UDim2.new(f2, 0, 1, 0)
		knob.Position = UDim2.new(f2, 0, 0.5, 0)
		valLbl.Text = tostring(v)
		onCh(v)
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			sd = true
			apply(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if sd and i.UserInputType == Enum.UserInputType.MouseMovement then
			apply(i.Position.X)
		end
	end)
end

-- Toggle builder (returns row with box, label, button, and setState)
function buildToggle(row, item, getState, setState)
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0,0.5)
	box.Position = UDim2.new(0,0,0.5,0)
	box.Size = UDim2.fromOffset(SIZES.checkbox, SIZES.checkbox)
	box.BackgroundColor3 = COLORS.checkOff
	box.BorderSizePixel = 0
	box.Parent = row
	corner(box, 5)
	local boxStroke = stroke(box, COLORS.checkOffStroke, 1)

	local check = Instance.new("TextLabel")
	check.Text = "\u{2714}"
	check.Font = Enum.Font.GothamBlack
	check.TextSize = 14
	check.TextColor3 = COLORS.check
	check.BackgroundTransparency = 1
	check.Size = UDim2.fromScale(1,1)
	check.Parent = box

	local label = Instance.new("TextLabel")
	label.Text = item.label
	label.Font = FONTS.label
	label.TextSize = 14
	label.TextColor3 = COLORS.labelOff
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, SIZES.labelStartX, 0,0)
	label.Size = UDim2.new(1, -SIZES.labelStartX - 22, 1, 0)
	label.Parent = row

	if item.hint then
		local hint = Instance.new("TextLabel")
		hint.Text = item.hint
		hint.Font = FONTS.label
		hint.TextSize = 12
		hint.TextColor3 = COLORS.labelOff
		hint.TextXAlignment = Enum.TextXAlignment.Right
		hint.TextYAlignment = Enum.TextYAlignment.Center
		hint.BackgroundTransparency = 1
		hint.Position = UDim2.new(1, -70, 0, 0)
		hint.Size = UDim2.new(0, 60, 1, 0)
		hint.Parent = row
	end

	local button = Instance.new("TextButton")
	button.Text = ""
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromScale(1,1)
	button.AutoButtonColor = false
	button.Parent = row

	local function render()
		local on = getState()
		box.BackgroundColor3 = on and COLORS.accent or COLORS.checkOff
		boxStroke.Enabled = not on
		check.Visible = on
		check.TextColor3 = Color3.fromRGB(255,255,255)
		label.TextColor3 = on and COLORS.labelOn or COLORS.labelOff
	end

	button.MouseButton1Click:Connect(function()
		setState(not getState())
		render()
	end)

	render()
	return { box = box, boxStroke = boxStroke, check = check, label = label, button = button, render = render }
end