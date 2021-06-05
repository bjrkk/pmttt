print("[pmTTT] Script start")

if engine.ActiveGamemode() != 'terrortown' then
    print("[pmTTT] Currently not in TTT, stopping code execution")
    return
end

if not SERVER then
	print("[pmTTT] Not in server, stopping code execution")
    return
end

local pm_configfile = "pmttt_config.json"
local pm_terrorists =
{
	Model("models/player/phoenix.mdl"),
	Model("models/player/arctic.mdl"),
	Model("models/player/guerilla.mdl"),
	Model("models/player/leet.mdl")
}
local pm_detective = pm_terrorists

local cv_enable = CreateConVar("ttt_pm_enable", "1", FCVAR_ARCHIVE)
local cv_randbodygroups = CreateConVar("ttt_pm_randbodygroups", "1", FCVAR_ARCHIVE)
local cv_ordertype = CreateConVar("ttt_pm_ordertype", "0", FCVAR_ARCHIVE)

function load_config()
	if not file.Exists(pm_configfile, "DATA") then
		print("[pmTTT] Config does not exist!")
		return
	end
	
	print("[pmTTT] Reading config...")
	local cfg = file.Read(pm_configfile, "DATA")
	local tbl = util.JSONToTable(cfg)
	if tbl == nil then
		print("[pmTTT] Error: Failed to convert JSON to table")
	end	
	
	local root = tbl
	
	if tbl["maps"][game.GetMap()] then
		print("[pmTTT] Loading " .. game.GetMap() .. " specific config")
		root = tbl["maps"][game.GetMap()]
	end
	
	pm_terrorists = root["terror"]
	pm_detective = root["detective"]
	
	PrintTable(pm_terrorists)
	PrintTable(pm_detective)
	print("[pmTTT] Finished")
end

concommand.Add("ttt_pm_loadconfig", load_config)

local plymeta = FindMetaTable("Player")

function plymeta:GetTTTPMValue()
	return self.tttpm_val or 1
end
function plymeta:SetTTTPMValue(i)
	self.tttpm_val = i
end

function pm_RandomizeBodyGroups(ply)
	for i = 0, ply:GetNumBodyGroups() do
		ply:SetBodygroup(i, math.random(0, ply:GetBodygroupCount(i)))
	end
end
function pm_SetPlayerModel(ply)
	if cv_enable:GetBool() == false then return end
	
	print("[pmTTT] setting player model for " .. ply:Name())
	local x = 1
	if (ply:IsDetective()) then
		if cv_ordertype:GetInt() == 2 then
			x = math.random(#pm_detective)
		elseif cv_ordertype:GetInt() == 1 then
			x = ply:GetTTTPMValue() % (#pm_detective - 1) + 1
		elseif cv_ordertype:GetInt() == 0 then
			x = ply:UserID() % (#pm_detective - 1) + 1
		end
			
		ply:SetModel(pm_detective[x])
	else
		if cv_ordertype:GetInt() == 2 then
			x = math.random(#pm_terrorists)
		elseif cv_ordertype:GetInt() == 1 then
			x = ply:GetTTTPMValue() % (#pm_terrorists - 1) + 1
		elseif cv_ordertype:GetInt() == 0 then
			x = ply:UserID() % (#pm_terrorists - 1) + 1
		end
	
		ply:SetModel(pm_terrorists[x])
	end
	
	if cv_randbodygroups:GetBool() == true then
		pm_RandomizeBodyGroups(ply)
	end
end

function pm_PlayerInitialSpawn(ply, transition)
	ply:SetTTTPMValue(math.random(#pm_detective + #pm_terrorists))
	print("[pmTTT] Assigned PM value " .. ply:GetTTTPMValue() .. " to " .. ply:Name())
end

hook.Add("TTTPlayerSetColor", "pm_SetPlayerModel", pm_SetPlayerModel)
hook.Add("PlayerInitialSpawn", "pm_PlayerInitialSpawn", pm_PlayerInitialSpawn)

load_config()