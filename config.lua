

local cfg = {
	pixelMaxSpeed   = 40,
	textureMaxSpeed = 40,
	bhopBoost       = 3.0,
	jumpBugPower    = 80,
	longJumpPower   = 90,
	miniJumpPower   = 20,
	aimbotFOV       = 60,
	aimbotSmooth    = 6,
	aimbotButton    = Enum.UserInputType.MouseButton2,
	fogEnd          = 200,
	blurSize        = 10,
}

local ESP_CFG = {
	skeleton_color         = Color3.fromRGB(0, 255, 0),
	crouch_color           = Color3.fromRGB(255, 0, 0),
	skeleton_thickness     = 2,
	skeleton_transparency  = 1,
	crouch_detection       = true,
	crouch_height_threshold = 2,
	box_enabled            = true,
	box_color              = Color3.fromRGB(255, 255, 255),
	box_thickness          = 2,
	box_filled             = false,
	box_fill_color         = Color3.fromRGB(255, 255, 255),
	box_fill_transparency  = 0.2,
	healthbar_enabled      = true,
	healthbar_color_high   = Color3.fromRGB(0, 255, 0),
	healthbar_color_low    = Color3.fromRGB(255, 0, 0),
	name_enabled           = true,
	name_color             = Color3.fromRGB(255, 255, 255),
	name_size              = 14,
	name_outline           = true,
	distance_enabled       = true,
	distance_color         = Color3.fromRGB(200, 200, 200),
	distance_size          = 12,
	tracer_enabled         = false,
	tracer_color           = Color3.fromRGB(255, 255, 255),
	tracer_thickness       = 1,
	tracer_transparency    = 1,
	tracer_from            = "Bottom",
}


local COLORS = {
	background     = Color3.fromRGB(0,0,0), sidebar = Color3.fromRGB(0,0,0), panel = Color3.fromRGB(13,13,13),
	panelStroke    = Color3.fromRGB(26,26,26), windowStroke = Color3.fromRGB(22,22,22), accent = Color3.fromRGB(48,244,38),
	sidebarSelBg   = Color3.fromRGB(28,28,28), divider = Color3.fromRGB(38,38,38), titleBox = Color3.fromRGB(18,18,18),
	title          = Color3.fromRGB(240,240,240), labelOn = Color3.fromRGB(226,226,226), labelOff = Color3.fromRGB(150,150,150),
	sidebarText    = Color3.fromRGB(160,160,160), checkOff = Color3.fromRGB(22,22,22), checkOffStroke = Color3.fromRGB(50,50,50),
	check          = Color3.fromRGB(8,12,8), keybind = Color3.fromRGB(95,95,95)
}

local SIZES = {
	window      = Vector2.new(900, 635),
	sidebarW    = 168,
	contentPad  = 16,
	colGap      = 16,
	colWidth    = 330,
	rowH        = 25,
	rowGap      = 6,
	panelPad    = 12,
	panelGap    = 16,
	titleH      = 28,
	checkbox    = 18,
	labelStartX = 24,
	corner      = 8,
	logoAreaH   = 84,
}

local FONTS = { title=Enum.Font.GothamBold, label=Enum.Font.Gotham, sidebar=Enum.Font.GothamMedium, glyph=Enum.Font.GothamBold }

_G.cfg = cfg
_G.ESP_CFG = ESP_CFG
_G.COLORS = COLORS
_G.SIZES = SIZES
_G.FONTS = FONTS