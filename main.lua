-- main.lua
-- Loader: fetches and executes all modules in order

local REPO_RAW = "https://raw.githubusercontent.com/monerro/chud.tk/main/"
local MODULES = {
	"config.lua",
	"utils/helpers.lua",
	"utils/drawing.lua",
	"features/movement.lua",
	"features/aimbot.lua",
	"features/esp.lua",
	"features/visuals.lua",
	"features/skins.lua",
	"ui/components.lua",
	"ui/menu.lua",
}

-- We need to define toggleFeature before menu uses it; it uses features and Movement.stopFeature etc.
-- We'll define it after features is populated.
_G.features = {}
local function initFeatures()
	_G.features = {
		PixelSurf  = { enabled=false, conn=nil, surfing=false, glideDir=nil, glideSpeed=0 },
		TextureBug = { enabled=false, conn=nil, surfing=false, glideDir=nil, glideSpeed=0 },
		AutoBhop   = { enabled=false, conn=nil },
		JumpBug    = { enabled=false, conn=nil },
		LongJump   = { enabled=false, conn=nil },
		MiniJump   = { enabled=false, conn=nil },
		FakeAimbot = { enabled=false, conn=nil },
	}
end
initFeatures()

-- toggleFeature depends on Movement.stopFeature and the start functions
local function toggleFeature(key)
	local f = _G.features[key]
	f.enabled = not f.enabled
	if f.enabled then
		if     key == "PixelSurf" then _G.Movement.makeSurf(key, Vector3.new(0,0,0), function() return _G.cfg.pixelMaxSpeed end)
		elseif key == "TextureBug" then _G.Movement.makeSurf(key, Vector3.new(0,2.5,0), function() return _G.cfg.textureMaxSpeed end)
		elseif key == "AutoBhop"   then _G.Movement.bhop_start()
		elseif key == "JumpBug"    then _G.Movement.jumpbug_start()
		elseif key == "LongJump"   then _G.Movement.longjump_start()
		elseif key == "MiniJump"   then _G.Movement.minijump_start()
		elseif key == "FakeAimbot" then _G.Aimbot.start()
		end
	else
		_G.Movement.stopFeature(key)
		if key == "FakeAimbot" then _G.Aimbot.stop() end
	end
	-- Update indicators if menu is loaded
	if _G.Menu and _G.Menu.refreshIndicators then _G.Menu.refreshIndicators() end
end
_G.toggleFeature = toggleFeature

-- Load each module
for _, path in ipairs(MODULES) do
	local url = REPO_RAW .. path
	local success, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)
	if not success then
		warn("Failed to load " .. path .. ": " .. tostring(result))
	end
end


_G.Skins.startLoop()


local player = game:GetService("Players").LocalPlayer
player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	for key, f in pairs(_G.features) do
		if f.enabled then
			if key == "PixelSurf" then
				_G.Movement.makeSurf(key, Vector3.new(0,0,0), function() return _G.cfg.pixelMaxSpeed end)
			elseif key == "TextureBug" then
				_G.Movement.makeSurf(key, Vector3.new(0,2.5,0), function() return _G.cfg.textureMaxSpeed end)
			elseif key == "AutoBhop" then _G.Movement.bhop_start()
			elseif key == "JumpBug" then _G.Movement.jumpbug_start()
			elseif key == "LongJump" then _G.Movement.longjump_start()
			elseif key == "MiniJump" then _G.Movement.minijump_start()
			elseif key == "FakeAimbot" then _G.Aimbot.start()
			end
		end
	end
	if _G.ESP and _G.ESP.refresh then _G.ESP.refresh() end
	if _G.Visuals and _G.Visuals.toggleMomentum and _G.momentumEnabled then
		_G.Visuals.toggleMomentum(false)
		_G.Visuals.toggleMomentum(true)
	end
end)
