-- ui/menu.lua
-- Main UI window, sidebar, tabs, content building

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local COLORS = _G.COLORS
local SIZES = _G.SIZES
local FONTS = _G.FONTS
local cfg = _G.cfg
local features = _G.features
local toggleFeature = _G.toggleFeature  -- we'll define later in main loader

-- Import UI components
local makeIcon = _G.makeIcon
local buildSlider = _G.buildSlider
local buildToggle = _G.buildToggle
local corner = _G.corner
local stroke = _G.stroke
local padding = _G.padding
local vlist = _G.vlist
local new = _G.new

-- Reference to skin selections from skins module
local skinSelections = _G.Skins.selections
local startSkinLoop = _G.Skins.startLoop
local refreshSkinList = nil  -- will be set later

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClarityMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Watermark (built-in)
local wmFrame = Instance.new("Frame")
wmFrame.Size = UDim2.new(0,0,0,22)
wmFrame.AutomaticSize = Enum.AutomaticSize.X
wmFrame.Position = UDim2.new(1,0,0,8)
wmFrame.AnchorPoint = Vector2.new(1,0)
wmFrame.BackgroundColor3 = Color3.fromRGB(10,10,12)
wmFrame.BorderSizePixel = 0
wmFrame.ZIndex = 10
wmFrame.Parent = screenGui
corner(wmFrame, 4)
stroke(wmFrame, Color3.fromRGB(30,30,38), 1)
local wmPad = Instance.new("UIPadding", wmFrame)
wmPad.PaddingLeft = UDim.new(0,8); wmPad.PaddingRight = UDim.new(0,8)
local wmLayout = Instance.new("UIListLayout", wmFrame)
wmLayout.FillDirection = Enum.FillDirection.Horizontal
wmLayout.VerticalAlignment = Enum.VerticalAlignment.Center
wmLayout.Padding = UDim.new(0,0)

local function wmPart(txt, col)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0,0,1,0)
	l.AutomaticSize = Enum.AutomaticSize.X
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = col
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.ZIndex = 11
	l.Parent = wmFrame
	return l
end
local wmName = wmPart("clarity", Color3.fromRGB(76,210,96))
local wmSep1 = wmPart(" | ", Color3.fromRGB(45,45,55))
local wmUser = wmPart(player.Name, Color3.fromRGB(230,230,230))
local wmSep2 = wmPart(" | ", Color3.fromRGB(45,45,55))
local wmFps = wmPart("0 fps", Color3.fromRGB(90,90,105))

-- FPS counter
local fpsCounter = 0
RunService.RenderStepped:Connect(function(dt)
	fpsCounter = fpsCounter + 1
	if fpsCounter >= 10 then
		fpsCounter = 0
		wmFps.Text = math.floor(1 / math.max(dt, 0.001) + 0.5) .. " fps"
	end
end)

-- Indicator bar
local indBar = Instance.new("Frame")
indBar.Size = UDim2.new(0,0,0,22)
indBar.AutomaticSize = Enum.AutomaticSize.X
indBar.Position = UDim2.new(0.5,0,1,-10)
indBar.AnchorPoint = Vector2.new(0.5,1)
indBar.BackgroundColor3 = Color3.fromRGB(10,10,12)
indBar.BorderSizePixel = 0
indBar.ZIndex = 10
indBar.Parent = screenGui
corner(indBar, 4)
stroke(indBar, Color3.fromRGB(30,30,38), 1)
local ibLayout = Instance.new("UIListLayout", indBar)
ibLayout.FillDirection = Enum.FillDirection.Horizontal
ibLayout.Padding = UDim.new(0,6)
local ibPad = Instance.new("UIPadding", indBar)
ibPad.PaddingLeft = UDim.new(0,8); ibPad.PaddingRight = UDim.new(0,8)
ibPad.PaddingTop = UDim.new(0,3); ibPad.PaddingBottom = UDim.new(0,3)

local IND_ORDER = {"ps","tb","lj","mj","jb","bh","amb"}
local IND_MAP = {ps="PixelSurf", tb="TextureBug", lj="LongJump", mj="MiniJump", jb="JumpBug", bh="AutoBhop", amb="FakeAimbot"}
local indicatorLabels = {}
for i, tag in ipairs(IND_ORDER) do
	local key = IND_MAP[tag]
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0,0,1,0)
	l.AutomaticSize = Enum.AutomaticSize.X
	l.BackgroundTransparency = 1
	l.Text = tag
	l.TextColor3 = Color3.fromRGB(45,45,55)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.LayoutOrder = i
	l.ZIndex = 11
	l.Parent = indBar
	indicatorLabels[key] = l
end

local function refreshIndicators()
	for key, lbl in pairs(indicatorLabels) do
		local f = features[key]
		if not f then continue end
		if not f.enabled then
			lbl.TextColor3 = Color3.fromRGB(45,45,55)
		elseif (key == "PixelSurf" or key == "TextureBug") and f.surfing then
			lbl.TextColor3 = Color3.fromRGB(76,210,96)
		else
			lbl.TextColor3 = Color3.fromRGB(230,230,230)
		end
	end
end
RunService.Heartbeat:Connect(refreshIndicators)

-- WASD keys
local WASD_KEY_SIZE = 20
local WASD_GAP = 2
local wasdBar = Instance.new("Frame")
wasdBar.AutomaticSize = Enum.AutomaticSize.XY
wasdBar.Position = UDim2.new(0.5,0,1,-38)
wasdBar.AnchorPoint = Vector2.new(0.5,1)
wasdBar.BackgroundColor3 = Color3.fromRGB(10,10,12)
wasdBar.BorderSizePixel = 0
wasdBar.ZIndex = 10
wasdBar.Parent = screenGui
corner(wasdBar, 4)
stroke(wasdBar, Color3.fromRGB(30,30,38), 1)
local wasdPad = Instance.new("UIPadding", wasdBar)
wasdPad.PaddingTop = UDim.new(0,4); wasdPad.PaddingBottom = UDim.new(0,4)
wasdPad.PaddingLeft = UDim.new(0,4); wasdPad.PaddingRight = UDim.new(0,4)

local WASD_ROW_W = 3 * WASD_KEY_SIZE + 2 * WASD_GAP
local wasdRow1 = Instance.new("Frame", wasdBar)
wasdRow1.Size = UDim2.new(0, WASD_ROW_W, 0, WASD_KEY_SIZE)
wasdRow1.BackgroundTransparency = 1
wasdRow1.BorderSizePixel = 0
wasdRow1.ZIndex = 10

local wasdRow2 = Instance.new("Frame", wasdBar)
wasdRow2.Size = UDim2.new(0, WASD_ROW_W, 0, WASD_KEY_SIZE)
wasdRow2.Position = UDim2.new(0,0,0, WASD_KEY_SIZE + WASD_GAP)
wasdRow2.BackgroundTransparency = 1
wasdRow2.BorderSizePixel = 0
wasdRow2.ZIndex = 10

local function makeKeyBox(parent, label, xOffset)
	local box = Instance.new("Frame", parent)
	box.Size = UDim2.new(0, WASD_KEY_SIZE, 0, WASD_KEY_SIZE)
	box.Position = UDim2.new(0, xOffset, 0, 0)
	box.BackgroundColor3 = Color3.fromRGB(25,25,32)
	box.BorderSizePixel = 0
	box.ZIndex = 11
	corner(box, 3)
	local strokeBox = Instance.new("UIStroke", box)
	strokeBox.Color = Color3.fromRGB(30,30,38)
	strokeBox.Thickness = 1
	local lbl = Instance.new("TextLabel", box)
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(45,45,55)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 10
	lbl.ZIndex = 12
	return box, lbl, strokeBox
end

local wBox, wLbl, wStroke = makeKeyBox(wasdRow1, "w", WASD_KEY_SIZE + WASD_GAP)
local aBox, aLbl, aStroke = makeKeyBox(wasdRow2, "a", 0)
local sBox, sLbl, sStroke = makeKeyBox(wasdRow2, "s", WASD_KEY_SIZE + WASD_GAP)
local dBox, dLbl, dStroke = makeKeyBox(wasdRow2, "d", (WASD_KEY_SIZE + WASD_GAP) * 2)

local function setKeyLit(box, lbl, strokeBox, lit)
	if lit then
		box.BackgroundColor3 = Color3.fromRGB(30,80,40)
		strokeBox.Color = Color3.fromRGB(76,210,96)
		lbl.TextColor3 = Color3.fromRGB(76,210,96)
	else
		box.BackgroundColor3 = Color3.fromRGB(25,25,32)
		strokeBox.Color = Color3.fromRGB(30,30,38)
		lbl.TextColor3 = Color3.fromRGB(45,45,55)
	end
end

RunService.RenderStepped:Connect(function()
	setKeyLit(wBox, wLbl, wStroke, UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up))
	setKeyLit(aBox, aLbl, aStroke, UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left))
	setKeyLit(sBox, sLbl, sStroke, UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down))
	setKeyLit(dBox, dLbl, dStroke, UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right))
end)

-----------------------------------------------------------
-- MAIN WINDOW
-----------------------------------------------------------
local win = Instance.new("Frame")
win.Name = "Window"
win.AnchorPoint = Vector2.new(0.5,0.5)
win.Position = UDim2.fromScale(0.5,0.5)
win.Size = UDim2.fromOffset(SIZES.window.X, SIZES.window.Y)
win.BackgroundColor3 = COLORS.background
win.BorderSizePixel = 0
win.ClipsDescendants = true
win.Visible = false
win.Parent = screenGui
corner(win, SIZES.corner)
stroke(win, COLORS.windowStroke, 1)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIZES.sidebarW, 1, 0)
sidebar.BackgroundColor3 = COLORS.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = win
padding(sidebar, 14)
new("UIPadding", { PaddingTop = UDim.new(0,20), Parent = sidebar })

-- Logo
local logoHolder = Instance.new("Frame")
logoHolder.Size = UDim2.new(1,0,0, SIZES.logoAreaH)
logoHolder.BackgroundTransparency = 1
logoHolder.LayoutOrder = 0
logoHolder.Parent = sidebar
local logo = Instance.new("ImageLabel")
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://136135909152944"  -- your logo
logo.ScaleType = Enum.ScaleType.Fit
logo.AnchorPoint = Vector2.new(0.5,0.5)
logo.Position = UDim2.fromScale(0.5,0.5)
logo.Size = UDim2.fromOffset(64,64)
logo.Parent = logoHolder

local nav = Instance.new("Frame")
nav.Size = UDim2.new(1,0,1,-SIZES.logoAreaH)
nav.Position = UDim2.new(0,0,0, SIZES.logoAreaH)
nav.BackgroundTransparency = 1
nav.Parent = sidebar
vlist(nav, 3)

-- Sidebar data
local SIDEBAR = {
	{ name="aimbot",    icon="aimbot",    defaultSub="main" },
	{ name="movement",  icon="movement",  subs={"main","recorder"} },
	{ name="visuals",   icon="visuals",   defaultSub="enemy" },
	{ name="misc",      icon="misc",      defaultSub="hud" },
	{ name="inventory", icon="inventory", defaultSub="skinchanger" },
	{ name="config",    icon="config",    defaultSub="soon" },
}

local categoryButtons = {}
local subButtons = {}
local activeCategory = nil
local activeSub = nil

local function selectCategory(name)
	activeCategory = name
	for cat, ctrl in pairs(categoryButtons) do
		ctrl.setSelected(cat == name)
	end
	local showSubs = (name == "movement")
	for _, ctrl in pairs(subButtons) do
		ctrl.btn.Visible = showSubs
	end
	if showSubs then
		if activeSub ~= "main" and activeSub ~= "recorder" then activeSub = "main" end
		for subName, ctrl in pairs(subButtons) do
			ctrl.setSelected(subName == activeSub)
		end
		rebuildContent("movement", activeSub)
	else
		local entry = nil
		for _, e in ipairs(SIDEBAR) do
			if e.name == name then entry = e; break end
		end
		if entry and entry.defaultSub then
			rebuildContent(name, entry.defaultSub)
		end
	end
end

local function selectSub(name)
	if activeCategory ~= "movement" then return end
	activeSub = name
	for subName, ctrl in pairs(subButtons) do
		ctrl.setSelected(subName == name)
	end
	rebuildContent("movement", name)
end

local function buildCategory(entry, order)
	local row = Instance.new("Frame")
	row.Name = entry.name
	row.Size = UDim2.new(1,0,0,30)
	row.BackgroundColor3 = COLORS.sidebarSelBg
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = nav
	corner(row, 6)
	new("UIPadding", { PaddingLeft = UDim.new(0,8), Parent = row })
	local icon = makeIcon(entry.icon, COLORS.accent, 17)
	icon.AnchorPoint = Vector2.new(0,0.5)
	icon.Position = UDim2.new(0,0,0.5,0)
	icon.Parent = row
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = entry.name
	label.Font = FONTS.sidebar
	label.TextSize = 14
	label.TextColor3 = COLORS.sidebarText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.new(0,26,0,0)
	label.Size = UDim2.new(1,-26,1,0)
	label.Parent = row
	local button = Instance.new("TextButton")
	button.Text = ""
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromScale(1,1)
	button.AutoButtonColor = false
	button.Parent = row

	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	categoryButtons[entry.name] = {
		setSelected = function(sel)
			TweenService:Create(row, tweenInfo, { BackgroundTransparency = sel and 0 or 1 }):Play()
			TweenService:Create(label, tweenInfo, { TextColor3 = sel and COLORS.accent or COLORS.sidebarText }):Play()
		end
	}
	button.MouseButton1Click:Connect(function()
		selectCategory(entry.name)
	end)
end

local function buildSubButtons()
	local order = 20
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, subName in ipairs({"main","recorder"}) do
		local row = Instance.new("Frame")
		row.Name = subName
		row.Size = UDim2.new(1,0,0,24)
		row.BackgroundColor3 = COLORS.sidebarSelBg
		row.BackgroundTransparency = 1
		row.LayoutOrder = order
		row.Parent = nav
		row.Visible = false
		order += 1
		corner(row, 6)
		new("UIPadding", { PaddingLeft = UDim.new(0,34), Parent = row })
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Text = subName
		label.Font = FONTS.sidebar
		label.TextSize = 13
		label.TextColor3 = COLORS.sidebarText
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Position = UDim2.new(0,0,0,0)
		label.Size = UDim2.new(1,0,1,0)
		label.Parent = row
		local button = Instance.new("TextButton")
		button.Text = ""
		button.BackgroundTransparency = 1
		button.Size = UDim2.fromScale(1,1)
		button.AutoButtonColor = false
		button.Parent = row

		subButtons[subName] = {
			btn = row,
			setSelected = function(sel)
				TweenService:Create(row, tweenInfo, { BackgroundTransparency = sel and 0 or 1 }):Play()
				TweenService:Create(label, tweenInfo, { TextColor3 = sel and COLORS.accent or COLORS.sidebarText }):Play()
			end
		}
		button.MouseButton1Click:Connect(function() selectSub(subName) end)
	end
end

do
	local order = 0
	for _, entry in ipairs(SIDEBAR) do
		order += 10
		buildCategory(entry, order)
	end
	buildSubButtons()
end

-- Content area
local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.new(0, SIZES.sidebarW, 0, 0)
content.Size = UDim2.new(1, -SIZES.sidebarW, 1, 0)
content.BackgroundTransparency = 1
content.Parent = win
padding(content, SIZES.contentPad)

local columnList = Instance.new("UIListLayout")
columnList.FillDirection = Enum.FillDirection.Horizontal
columnList.SortOrder = Enum.SortOrder.LayoutOrder
columnList.Padding = UDim.new(0, SIZES.colGap)
columnList.HorizontalAlignment = Enum.HorizontalAlignment.Left
columnList.VerticalAlignment = Enum.VerticalAlignment.Top
columnList.Parent = content

local columns = {}

local function clearContent()
	for _, col in pairs(columns) do col:Destroy() end
	columns = {}
end

local function makeColumn(order)
	local col = Instance.new("Frame")
	col.Size = UDim2.new(0, SIZES.colWidth, 0,0)
	col.AutomaticSize = Enum.AutomaticSize.Y
	col.BackgroundTransparency = 1
	col.LayoutOrder = order
	col.Parent = content
	vlist(col, SIZES.panelGap)
	return col
end

-- Panel builder
local function makePanel(colIndex, def)
	local col = columns[colIndex]
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1,0,0,0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = COLORS.panel
	panel.BorderSizePixel = 0
	panel.Parent = col
	corner(panel, SIZES.corner)
	stroke(panel, COLORS.panelStroke, 1)
	vlist(panel, 10)

	local header = Instance.new("Frame")
	header.BackgroundColor3 = COLORS.titleBox
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0, SIZES.titleH)
	header.LayoutOrder = 1
	header.Parent = panel
	stroke(header, COLORS.divider, 1)
	new("UIPadding", { PaddingLeft = UDim.new(0,10), Parent = header })
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = def.title
	headerLabel.Font = FONTS.title
	headerLabel.TextSize = 14
	headerLabel.TextColor3 = COLORS.title
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextYAlignment = Enum.TextYAlignment.Center
	headerLabel.BackgroundTransparency = 1
	headerLabel.Size = UDim2.fromScale(1,1)
	headerLabel.Parent = header

	local rows = Instance.new("Frame")
	rows.Size = UDim2.new(1,0,0,0)
	rows.AutomaticSize = Enum.AutomaticSize.Y
	rows.BackgroundTransparency = 1
	rows.LayoutOrder = 2
	rows.Parent = panel
	padding(rows, SIZES.panelPad)
	vlist(rows, SIZES.rowGap)

	for i, item in ipairs(def.items) do
		local rowH = SIZES.rowH
		if item.slider then rowH = rowH + 20 end
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,0,0,rowH)
		row.BackgroundTransparency = 1
		row.Parent = rows

		if item.type == "toggle" then
			local getState, setState
			if item.key and features[item.key] ~= nil then
				getState = function() return features[item.key].enabled end
				setState = function(on)
					if features[item.key].enabled ~= on then toggleFeature(item.key) end
					if item.onToggle then item.onToggle(on) end
				end
			else
				local localState = item.init or false
				getState = function() return localState end
				setState = function(on)
					localState = on
					if item.onToggle then item.onToggle(on) end
				end
			end
			buildToggle(row, item, getState, setState)

			if item.slider then
				buildSlider(row, 0, SIZES.rowH + 4, item.sliderLabel or "value", item.min, item.max, item.init, 90, item.onChange)
			end
		elseif item.type == "label" then
			local l = Instance.new("TextLabel")
			l.Text = item.text
			l.Font = FONTS.label
			l.TextSize = 14
			l.TextColor3 = COLORS.labelOff
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1,0,0,20)
			l.Parent = row
		end
	end
end

-- Movement sections (left/right columns)
local MOVEMENT_MAIN_SECTIONS = {
	{ col=1, title="general", items={
		{ type="toggle", label="auto bunnyhop",   key="AutoBhop",   hint="[space]", slider=true, sliderLabel="boost", min=1, max=100, init=math.floor(cfg.bhopBoost*10+0.5), onChange=function(v) cfg.bhopBoost=v/10 end },
		{ type="toggle", label="auto pixelsurf",  key="PixelSurf",  hint="auto",    slider=true, sliderLabel="speed", min=20, max=200, init=cfg.pixelMaxSpeed, onChange=function(v) cfg.pixelMaxSpeed=v end },
		{ type="toggle", label="auto texturebug", key="TextureBug", hint="auto",    slider=true, sliderLabel="speed", min=20, max=200, init=cfg.textureMaxSpeed, onChange=function(v) cfg.textureMaxSpeed=v end },
		{ type="toggle", label="mini jump",        key="MiniJump",   hint="[c]",     slider=true, sliderLabel="power", min=5, max=80, init=cfg.miniJumpPower, onChange=function(v) cfg.miniJumpPower=v end },
		{ type="toggle", label="long jump",        key="LongJump",   hint="[e]",     slider=true, sliderLabel="power", min=20, max=200, init=cfg.longJumpPower, onChange=function(v) cfg.longJumpPower=v end },
		{ type="toggle", label="jump bug",         key="JumpBug",    hint="[q]",     slider=true, sliderLabel="power", min=10, max=200, init=cfg.jumpBugPower, onChange=function(v) cfg.jumpBugPower=v end },
	}},
	{ col=1, title="strafe", items={ { type="label", text="coming soon.." } } },
	{ col=2, title="other", items={
		{ type="toggle", label="auto wallstuck", key="dummy1" },
		{ type="toggle", label="auto wallhop", key="dummy2" }
	}},
	{ col=2, title="utility", items={ { type="label", text="venthop assist (soon)" } } },
}

local RECORDER_SOON = { { col=1, title="recorder", items={ { type="label", text="soon" } } } }

-- Other tab panels
local TAB_PANELS = {
	aimbot = {
		main = {
			{ col=1, title="main", items={
				{ type="toggle", label="aimbot", key="FakeAimbot", slider=true, sliderLabel="smooth", min=1, max=100, init=cfg.aimbotSmooth, onChange=function(v) cfg.aimbotSmooth=v end },
				{ type="slider", label="fov", sliderLabel="fov", min=1, max=100, init=cfg.aimbotFOV, onChange=function(v) cfg.aimbotFOV=v end },
				{ type="slider", label="smooth", sliderLabel="smooth", min=1, max=100, init=cfg.aimbotSmooth, onChange=function(v) cfg.aimbotSmooth=v end },
				{ type="toggle", label="fov view", key="fovView" },
				{ type="label", text="change aimbot part (soon)" },
			}}
		}
	},
	visuals = {
		enemy = {
			{ col=1, title="enemy", items={ { type="toggle", label="esp", key="espToggle", onToggle=function(v) _G.ESP.toggle(v) end } } }
		}
	},
	misc = {
		hud = {
			{ col=1, title="hud", items={
				{ type="toggle", label="watermark", key="wm", init=true, onToggle=function(v) wmFrame.Visible=v end },
				{ type="toggle", label="larp watermark", key="larp", onToggle=function(v) _G.Visuals.toggleLarpWatermark(v) end },
				{ type="label", text="velocity graph (soon)" },
				{ type="toggle", label="momentum", key="mom", onToggle=function(v) _G.Visuals.toggleMomentum(v) end },
				{ type="toggle", label="indicators", key="ind", init=true, onToggle=function(v) indBar.Visible=v; wasdBar.Visible=v end },
			}}
		}
	},
	inventory = {
		skinchanger = { col=1, title="skinchanger", items={} }  -- special handled below
	},
	config = {
		soon = { { col=1, title="soon", items={ { type="label", text="soon" } } } }
	},
}

-- Skin list panel (special)
function buildSkinPanel(colIndex)
	local col = columns[colIndex]
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(1,0,0,0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = COLORS.panel
	panel.BorderSizePixel = 0
	panel.Parent = col
	corner(panel, SIZES.corner)
	stroke(panel, COLORS.panelStroke, 1)
	vlist(panel, 10)

	local header = Instance.new("Frame")
	header.BackgroundColor3 = COLORS.titleBox
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1,0,0, SIZES.titleH)
	header.LayoutOrder = 1
	header.Parent = panel
	stroke(header, COLORS.divider, 1)
	new("UIPadding", { PaddingLeft = UDim.new(0,10), Parent = header })
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Text = "skinchanger"
	headerLabel.Font = FONTS.title
	headerLabel.TextSize = 14
	headerLabel.TextColor3 = COLORS.title
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.TextYAlignment = Enum.TextYAlignment.Center
	headerLabel.BackgroundTransparency = 1
	headerLabel.Size = UDim2.fromScale(1,1)
	headerLabel.Parent = header

	local rows = Instance.new("Frame")
	rows.Size = UDim2.new(1,0,0,0)
	rows.AutomaticSize = Enum.AutomaticSize.Y
	rows.BackgroundTransparency = 1
	rows.LayoutOrder = 2
	rows.Parent = panel
	padding(rows, SIZES.panelPad)
	vlist(rows, SIZES.rowGap)

	local currentGunLabel = Instance.new("TextLabel")
	currentGunLabel.Text = "no weapon equipped"
	currentGunLabel.Font = FONTS.label
	currentGunLabel.TextSize = 11
	currentGunLabel.TextColor3 = COLORS.labelOff
	currentGunLabel.BackgroundTransparency = 1
	currentGunLabel.Size = UDim2.new(1,0,0,20)
	currentGunLabel.Parent = rows

	local skinListHolder = Instance.new("Frame")
	skinListHolder.Size = UDim2.new(1,0,0,0)
	skinListHolder.AutomaticSize = Enum.AutomaticSize.Y
	skinListHolder.BackgroundTransparency = 1
	skinListHolder.Parent = rows
	vlist(skinListHolder, 2)

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Text = "refresh"
	refreshBtn.Font = FONTS.label
	refreshBtn.TextSize = 11
	refreshBtn.TextColor3 = COLORS.title
	refreshBtn.BackgroundColor3 = COLORS.titleBox
	refreshBtn.Size = UDim2.new(1,-20,0,28)
	refreshBtn.ZIndex = 5
	refreshBtn.Parent = rows
	corner(refreshBtn, 4)
	refreshBtn.MouseButton1Click:Connect(function()
		refreshSkinList(skinListHolder, currentGunLabel)
	end)

	-- define refreshSkinList using closures
	refreshSkinList = function(holder, gunLabel)
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		local gunName = _G.getEquippedGunName()
		if gunName then
			gunLabel.Text = "current: " .. gunName
		else
			gunLabel.Text = "no weapon equipped"
			return
		end
		local gunSkins = game:GetService("ReplicatedStorage"):FindFirstChild("Skins") and game:GetService("ReplicatedStorage").Skins:FindFirstChild(gunName)
		if not gunSkins then
			gunLabel.Text = gunName .. " (no skins)"
			return
		end

		local function addSkinEntry(name, isSelected)
			local wrap = Instance.new("Frame")
			wrap.Size = UDim2.new(1,0,0,28)
			wrap.BackgroundColor3 = COLORS.panel
			wrap.BorderSizePixel = 0
			wrap.ZIndex = 3
			wrap.Parent = holder
			local lbl = Instance.new("TextLabel")
			lbl.Text = name
			lbl.Font = FONTS.label
			lbl.TextSize = 11
			lbl.TextColor3 = isSelected and COLORS.accent or COLORS.labelOff
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.new(1,-16,1,0)
			lbl.Position = UDim2.new(0,8,0,0)
			lbl.ZIndex = 4
			lbl.Parent = wrap
			local btn = Instance.new("TextButton")
			btn.Text = ""
			btn.BackgroundTransparency = 1
			btn.Size = UDim2.fromScale(1,1)
			btn.AutoButtonColor = false
			btn.Parent = wrap
			btn.MouseButton1Click:Connect(function()
				skinSelections[gunName] = name
				startSkinLoop()
				refreshSkinList(holder, gunLabel)
			end)
		end

		-- default option
		local defWrap = Instance.new("Frame")
		defWrap.Size = UDim2.new(1,0,0,28)
		defWrap.BackgroundColor3 = COLORS.panel
		defWrap.BorderSizePixel = 0
		defWrap.ZIndex = 3
		defWrap.Parent = holder
		local defLbl = Instance.new("TextLabel")
		defLbl.Text = "default"
		defLbl.Font = FONTS.label
		defLbl.TextSize = 11
		defLbl.TextColor3 = (skinSelections[gunName] == nil) and COLORS.accent or COLORS.labelOff
		defLbl.TextXAlignment = Enum.TextXAlignment.Left
		defLbl.BackgroundTransparency = 1
		defLbl.Size = UDim2.new(1,-16,1,0)
		defLbl.Position = UDim2.new(0,8,0,0)
		defLbl.ZIndex = 4
		defLbl.Parent = defWrap
		local defBtn = Instance.new("TextButton")
		defBtn.Text = ""
		defBtn.BackgroundTransparency = 1
		defBtn.Size = UDim2.fromScale(1,1)
		defBtn.AutoButtonColor = false
		defBtn.Parent = defWrap
		defBtn.MouseButton1Click:Connect(function()
			skinSelections[gunName] = nil
			startSkinLoop()
			refreshSkinList(holder, gunLabel)
		end)

		for _, skin in ipairs(gunSkins:GetChildren()) do
			addSkinEntry(skin.Name, skinSelections[gunName] == skin.Name)
		end
	end

	-- initial refresh
	refreshSkinList(skinListHolder, currentGunLabel)
end

function rebuildContent(catName, subName)
	clearContent()
	columns[1] = makeColumn(1)
	columns[2] = makeColumn(2)

	if catName == "movement" then
		local sections
		if subName == "main" then sections = MOVEMENT_MAIN_SECTIONS
		elseif subName == "recorder" then sections = RECORDER_SOON
		else return end
		for _, sec in ipairs(sections) do
			makePanel(sec.col, sec)
		end
	elseif catName == "inventory" and subName == "skinchanger" then
		buildSkinPanel(1)
	else
		local defs = TAB_PANELS[catName] and TAB_PANELS[catName][subName]
		if defs then
			for _, def in ipairs(defs) do
				makePanel(def.col, def)
			end
		end
	end
end

-- Drag
local dragging, dragStart, dragOrigin = false, nil, nil
win.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		dragOrigin = win.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		win.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
	end
end)

-- Menu toggle
local menuOpen = false
local function setMenuOpen(open)
	menuOpen = open
	win.Visible = open
	if open then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end
RunService.RenderStepped:Connect(function()
	if menuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end)

-- Unload hotkey (U+O)
local unloadHeld = {}
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.Insert then
		setMenuOpen(not menuOpen)
	end
	if not gpe then
		unloadHeld[input.KeyCode] = true
		if unloadHeld[Enum.KeyCode.U] and unloadHeld[Enum.KeyCode.O] then
			-- unload all features
			for key in pairs(features) do
				if features[key].conn then features[key].conn:Disconnect() end
			end
			_G.ESP.toggle(false)
			_G.Skins.stopLoop()
			_G.Visuals.toggleLarpWatermark(false)
			_G.Visuals.toggleMomentum(false)
			_G.Visuals.setFog(false)
			_G.Visuals.setBlur(false)
			-- clean up
			local trailFolder = workspace:FindFirstChild("DwbiTrail")
			if trailFolder then trailFolder:Destroy() end
			screenGui:Destroy()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	unloadHeld[input.KeyCode] = nil
end)

-- Export for loader
_G.Menu = {
	screenGui = screenGui,
	setMenuOpen = setMenuOpen,
	rebuildContent = rebuildContent,
	selectCategory = selectCategory
}

-- Initial selection
selectCategory("movement")