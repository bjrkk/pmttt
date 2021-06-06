print("[pmTTT] Script start")

-- Dummy checks

if engine.ActiveGamemode() != 'terrortown' then
    print("[pmTTT] Currently not in TTT, stopping code execution")
    return
end

if not SERVER then
	print("[pmTTT] Not in server, stopping code execution")
    return
end

-- Local variables

local pm_configfile = "pmttt_config.json"
local pm_terrorists = {}
local pm_detective = {}

local cv_enable = CreateConVar("ttt_pm_enable", "1", FCVAR_ARCHIVE)
local cv_randbodygroups = CreateConVar("ttt_pm_randbodygroups", "1", FCVAR_ARCHIVE)
local cv_randskin = CreateConVar("ttt_pm_randskin", "1", FCVAR_ARCHIVE)
local cv_ordertype = CreateConVar("ttt_pm_ordertype", "0", FCVAR_ARCHIVE)

-- Player metadata code

local plymeta = FindMetaTable("Player")

function plymeta:GetTTTPMValue() return self.tttpm_val or 1 end
function plymeta:SetTTTPMValue(i) self.tttpm_val = i end

-- Main logic

function pm_RandomizeBodyGroups(ply)
	for i = 0, ply:GetNumBodyGroups() do
		ply:SetBodygroup(i, math.random(0, ply:GetBodygroupCount(i)))
	end
end

function pm_SetPlayerModel(ply)
	if not cv_enable:GetBool() then return end
	
	local tbl = pm_terrorists

	if cv_ordertype:GetInt() == 0 then ply:SetTTPMValue(ply:UserID()) end
	local x = ply:GetTTTPMValue() % (#tbl - 1) + 1
	
	if ply:IsDetective() then tbl = pm_detective end
	if tbl[x] and tbl[x] != "" then ply.defaultModel = tbl[x] end
end

function pm_SetPlayerColor(ply)
	if not cv_enable:GetBool() then return end
	
	-- [bjrkk] Interesting solution, but this eliminates the need to store the specific bodygroups to use, 
	--         which either way would make things a bit more complicated (since we'd need to extract the bodygroup info from the model data itself)
	
	math.randomseed(ply:GetTTTPMValue())
	if cv_randbodygroups:GetBool() then pm_RandomizeBodyGroups(ply) end
	if cv_randskin:GetBool() then ply:SetSkin(math.random(0, ply:SkinCount())) end
	math.randomseed(os.time())
end

function pm_PlayerInitialSpawn(ply, transition)
	ply:SetTTTPMValue(math.random(#pm_detective + #pm_terrorists))
end

function pm_TTTPrepareRound()
	if cv_ordertype:GetInt() == 2 then
		local plys = player.GetAll()
		for i = 1, #plys do
			plys[i]:SetTTTPMValue(math.random(#pm_detective + #pm_terrorists))
		end
	end
end

function pm_PostPlayerDeath(ply)
	-- TTT bug thing, whatever; let's try to mitigate it for now!
	for i = 0, ply:GetNumBodyGroups() do
		ply.server_ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
	end
	ply.server_ragdoll:SetSkin(ply:GetSkin())
end

hook.Add("PostPlayerDeath", "pm_PostPlayerDeath", pm_PostPlayerDeath)
hook.Add("PlayerSetModel", "pm_SetPlayerModel", pm_SetPlayerModel)
hook.Add("PlayerInitialSpawn", "pm_PlayerInitialSpawn", pm_PlayerInitialSpawn)
hook.Add("TTTPlayerSetColor", "pm_SetPlayerColor", pm_SetPlayerColor)
hook.Add("TTTPrepareRound", "pm_TTTPrepareRound", pm_TTTPrepareRound)

-- Configuration/Init

local pm_default_table = 
{
	terror = 
	{
		Model("models/player/phoenix.mdl"),
		Model("models/player/arctic.mdl"),
		Model("models/player/guerilla.mdl"),
		Model("models/player/leet.mdl")
	},
	
	detective =
	{
		Model("models/player/phoenix.mdl"),
		Model("models/player/arctic.mdl"),
		Model("models/player/guerilla.mdl"),
		Model("models/player/leet.mdl")
	},
	
	maps = 
	{
		gm_flatgrass =
		{
			terror = { Model("models/player/kleiner.mdl") },
			detective = { Model("models/player/kleiner.mdl") }
		},
		
		gm_construct =
		{
			terror = { Model("models/player/kleiner.mdl") },
			detective = { Model("models/player/kleiner.mdl") }
		}
	}
}

function load_config()
	if not file.Exists(pm_configfile, "DATA") then
		print("[pmTTT] Config does not exist! Creating file...")
		file.Write(pm_configfile, util.TableToJSON(pm_default_table, true))
	end
	
	print("[pmTTT] Reading config...")
	local cfg = file.Read(pm_configfile, "DATA")
	local tbl = util.JSONToTable(cfg)
	if tbl == nil then
		print("[pmTTT] Error: Failed to convert JSON to table")
		return
	end
	
	-- [bjrkk] store table with the terror and detective objects into a variable, this makes the code really simple and i like it
	local root = tbl
	
	if tbl["maps"] != nil then
		if tbl["maps"][game.GetMap()] then
			print("[pmTTT] Using " .. game.GetMap() .. " specific config")
			root = tbl["maps"][game.GetMap()]
		end
	end
	
	pm_terrorists = root["terror"]
	pm_detective = root["detective"]
	
	PrintTable(pm_terrorists)
	PrintTable(pm_detective)
	
	print("[pmTTT] Finished reading config!")
end

concommand.Add("ttt_pm_loadconfig", load_config)
load_config()