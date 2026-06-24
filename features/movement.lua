

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local cfg = _G.cfg
local features = _G.features or {}
_G.features = features  -- ensure global

-- Character references
local character, humanoid, hrp
local function bindCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
end
if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

-- Constants for surfing
local WALL_RANGE = 2.0
local W_ACCEL = 14
local BASE_SPEED = 40
local TRAIL_LIFE = 1.8
local TRAIL_WIDTH = 0.06
local PARAMS = RaycastParams.new()
PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local WALL_DIRS = {
	Vector3.new(1,0,0), Vector3.new(-1,0,0),
	Vector3.new(0,0,1), Vector3.new(0,0,-1),
	Vector3.new(1,0,1).Unit, Vector3.new(-1,0,1).Unit,
	Vector3.new(1,0,-1).Unit, Vector3.new(-1,0,-1).Unit,
}

-- Trail system
local trailFolder = Instance.new("Folder")
trailFolder.Name = "DwbiTrail"
trailFolder.Parent = workspace
local segments = {}
local lastPos = {PixelSurf=nil, TextureBug=nil}
local TRAIL_STEP = 1.2

local function spawnSegment(pos)
	local seg = Instance.new("Part")
	seg.Anchored=true; seg.CanCollide=false; seg.CanQuery=false; seg.CastShadow=false
	seg.Size=Vector3.new(TRAIL_WIDTH,TRAIL_WIDTH,TRAIL_WIDTH)
	seg.CFrame=CFrame.new(pos); seg.Material=Enum.Material.Neon
	seg.Color=Color3.new(1,1,1); seg.Transparency=0; seg.Parent=trailFolder
	table.insert(segments,{part=seg,born=tick()})
end

local function updateTrail(pos, active, key)
	local now=tick()
	if active then
		if not lastPos[key] or (pos-lastPos[key]).Magnitude>=TRAIL_STEP then
			spawnSegment(pos); lastPos[key]=pos
		end
	else lastPos[key]=nil end
	local i=1
	while i<=#segments do
		local s=segments[i]; local age=now-s.born
		if age>=TRAIL_LIFE then s.part:Destroy(); table.remove(segments,i)
		else s.part.Transparency=age/TRAIL_LIFE; i=i+1 end
	end
end

local function findWall(originOffset)
	PARAMS.FilterDescendantsInstances = {character}
	local up = Vector3.new(0,1,0)
	local origin = hrp.Position + originOffset
	local vel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
	local hVel = Vector3.new(vel.X,0,vel.Z)
	for _, dir in ipairs(WALL_DIRS) do
		local hit = workspace:Raycast(origin, dir * WALL_RANGE, PARAMS)
		if not hit then continue end
		local n = hit.Normal
		if math.abs(n:Dot(up)) >= 0.43 then continue end
		local inst = hit.Instance
		if not inst:IsA("BasePart") then continue end
		if inst.Size.Y * 0.5 < 2.0 then continue end
		if hVel.Magnitude > 1 then
			if hVel.Unit:Dot(-n) < 0.1 then continue end
		end
		return n
	end
	return nil
end

local function makeSurf(key, originOffset, getMaxSpeed)
	local f = features[key]
	f.conn = RunService.Heartbeat:Connect(function(dt)
		if not hrp or not humanoid then return end
		local state = humanoid:GetState()
		local airborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
		if not airborne then f.surfing=false; f.glideDir=nil; f.glideSpeed=0; updateTrail(hrp.Position, false, key); return end
		local wNormal = findWall(originOffset)
		if not wNormal then f.surfing=false; f.glideDir=nil; f.glideSpeed=0; updateTrail(hrp.Position, false, key); return end
		if f.surfing and (UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.Right)) then
			f.surfing=false; f.glideDir=nil; f.glideSpeed=0; updateTrail(hrp.Position, false, key); return
		end
		local maxSpd = getMaxSpeed()
		if not f.surfing then
			f.surfing = true
			local look = hrp.CFrame.LookVector
			local proj = look - wNormal * look:Dot(wNormal)
			proj = Vector3.new(proj.X,0,proj.Z)
			f.glideDir = proj.Magnitude > 0.01 and proj.Unit or Vector3.new(-wNormal.Z,0,wNormal.X).Unit
			local vel = hrp.AssemblyLinearVelocity
			f.glideSpeed = math.min(math.max(Vector3.new(vel.X,0,vel.Z).Magnitude, BASE_SPEED), maxSpd)
		end
		f.glideSpeed = math.min(f.glideSpeed, maxSpd)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			f.glideSpeed = math.min(f.glideSpeed + W_ACCEL * dt, maxSpd)
		end
		hrp.AssemblyLinearVelocity = Vector3.new(f.glideDir.X * f.glideSpeed, 0, f.glideDir.Z * f.glideSpeed)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		updateTrail(hrp.Position + originOffset, true, key)
	end)
end

-- Bhop
local function bhop_start()
	features.AutoBhop.conn = RunService.RenderStepped:Connect(function()
		if not humanoid or not hrp then return end
		if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
		if humanoid.FloorMaterial~=Enum.Material.Air then humanoid.Jump=true
		else local md=humanoid.MoveDirection; if md.Magnitude>0 then hrp.CFrame=hrp.CFrame+(md*cfg.bhopBoost) end end
	end)
end

-- JumpBug
local function jumpbug_start()
	features.JumpBug.conn = humanoid.StateChanged:Connect(function(_,new)
		if new==Enum.HumanoidStateType.Jumping and UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			task.defer(function() if hrp then local vel=hrp.AssemblyLinearVelocity; hrp.AssemblyLinearVelocity=Vector3.new(vel.X,vel.Y+cfg.jumpBugPower,vel.Z) end end)
		end
	end)
end

-- LongJump
local lj_used=false
local function longjump_start()
	features.LongJump.conn = UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode~=Enum.KeyCode.E then return end
		if not humanoid or not hrp then return end
		if humanoid:GetState()~=Enum.HumanoidStateType.Running and humanoid:GetState()~=Enum.HumanoidStateType.RunningNoPhysics then return end
		if lj_used then return end
		lj_used=true
		local look=hrp.CFrame.LookVector; local vel=hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity=Vector3.new(look.X*cfg.longJumpPower,vel.Y+25,look.Z*cfg.longJumpPower)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local landConn; landConn=humanoid.StateChanged:Connect(function(_,new)
			if new==Enum.HumanoidStateType.Landed or new==Enum.HumanoidStateType.Running then lj_used=false; landConn:Disconnect() end
		end)
	end)
end

-- MiniJump
local mj_cd=0
local function minijump_start()
	features.MiniJump.conn = UserInputService.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode~=Enum.KeyCode.C then return end
		if not humanoid or not hrp then return end
		local now=tick(); if now-mj_cd<0.3 then return end; mj_cd=now
		if humanoid:GetState()~=Enum.HumanoidStateType.Running and humanoid:GetState()~=Enum.HumanoidStateType.RunningNoPhysics then return end
		local vel=hrp.AssemblyLinearVelocity; hrp.AssemblyLinearVelocity=Vector3.new(vel.X,cfg.miniJumpPower,vel.Z)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
end

-- Export functions for toggleFeature (used in UI)
_G.Movement = {
	makeSurf = makeSurf,
	bhop_start = bhop_start,
	jumpbug_start = jumpbug_start,
	longjump_start = longjump_start,
	minijump_start = minijump_start,
	stopFeature = function(key)  -- used by toggleFeature
		local f = features[key]
		if f and f.conn then f.conn:Disconnect(); f.conn = nil end
		if key=="PixelSurf" or key=="TextureBug" then
			f.surfing=false; f.glideDir=nil; f.glideSpeed=0; updateTrail(Vector3.zero,false,key)
		end
		if key=="LongJump" then lj_used=false end
	end
}