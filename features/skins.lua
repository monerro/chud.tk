-- features/skins.lua
-- Skins system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local getEquippedGunName = _G.getEquippedGunName
local getArms = _G.getArms
local resolvePartName = _G.resolvePartName

local skinSelections = {}
local skinOriginals = {}
local skinConn = nil
local skinMapCache = {}

local function snapshotOriginals(gunName, arms)
	if skinOriginals[gunName] then return end
	local snap = {}
	for _, p in ipairs(arms:GetChildren()) do
		if p:IsA("MeshPart") then snap[p.Name] = p.TextureID end
	end
	skinOriginals[gunName] = snap
end

local function buildSkinMap(gunName, skinName)
	local gunSkins = ReplicatedStorage:FindFirstChild("Skins") and ReplicatedStorage.Skins:FindFirstChild(gunName)
	if not gunSkins then return nil end
	local skin = gunSkins:FindFirstChild(skinName)
	if not skin then return nil end
	local map = {}
	local function add(sv)
		if sv:IsA("StringValue") then
			map[sv.Name] = sv.Value
			map[resolvePartName(sv.Name)] = sv.Value
		end
	end
	local wm = skin:FindFirstChild("WorldModel")
	if wm then
		for _, sv in ipairs(wm:GetChildren()) do add(sv) end
	end
	for _, sv in ipairs(skin:GetChildren()) do add(sv) end
	return map
end

local function startSkinLoop()
	if skinConn then skinConn:Disconnect() end
	skinConn = RunService.RenderStepped:Connect(function()
		local arms = getArms()
		if not arms then return end
		local gunName = getEquippedGunName()
		if not gunName then return end
		snapshotOriginals(gunName, arms)
		local sel = skinSelections[gunName]
		if sel then
			local cacheKey = gunName .. "|" .. sel
			local map = skinMapCache[cacheKey]
			if map == nil then
				map = buildSkinMap(gunName, sel) or false
				skinMapCache[cacheKey] = map
			end
			if map then
				for _, p in ipairs(arms:GetChildren()) do
					if p:IsA("MeshPart") then
						local tex = map[p.Name] or map[resolvePartName(p.Name)]
						if tex and p.TextureID ~= tex then p.TextureID = tex end
					end
				end
			end
		else
			local orig = skinOriginals[gunName]
			if orig then
				for _, p in ipairs(arms:GetChildren()) do
					if p:IsA("MeshPart") and orig[p.Name] and p.TextureID ~= orig[p.Name] then
						p.TextureID = orig[p.Name]
					end
				end
			end
		end
	end)
end

local function stopSkinLoop()
	if skinConn then skinConn:Disconnect(); skinConn = nil end
end

_G.Skins = {
	startLoop = startSkinLoop,
	stopLoop = stopSkinLoop,
	selections = skinSelections,
	originals = skinOriginals,
	cache = skinMapCache,
	snapshotOriginals = snapshotOriginals,
	buildSkinMap = buildSkinMap
}