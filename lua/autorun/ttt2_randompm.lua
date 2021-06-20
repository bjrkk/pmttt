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
local pm_models = {}

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

local pm_OriginalSetPlayerModel;

function pm_SetPlayerModel(gm, ply)
	pm_OriginalSetPlayerModel(gm, ply)

	if not IsValid(ply) then return end
	if not cv_enable:GetBool() then return end
	
	local tbl = pm_models
	local role
	local firstrole
	
	-- [bjrkk] in order to maintain compatibility, i'll just do this
	
	if TTT2 then
		role = roles.GetByIndex(ply:GetRole()).name
		firstrole = roles.GetByIndex(0).name
	else
		local ttt1_roles = 
		{
			[ROLE_TRAITOR]   = "traitor",
			[ROLE_INNOCENT]  = "innocent",
			[ROLE_DETECTIVE] = "detective"
		}
	
		role = ttt1_roles[ply:GetRole()]
		firstrole = ttt1_roles[ROLE_NONE]
	end
	
	if tbl[role] then tbl = tbl[role]
	else tbl = tbl[firstrole] or tbl[1] end
	
	if cv_ordertype:GetInt() == 0 then ply:SetTTTPMValue(ply:UserID()) end
	
	local x = math.floor(ply:GetTTTPMValue() * #tbl) + 1
	if tbl[x] and tbl[x] != "" then 
		if util.IsValidModel(tbl[x]) then ply:SetModel(Model(tbl[x]))
		else print("[pmTTT] Model '" .. tbl[x] "' is not valid!") end
	end
	
	-- [bjrkk] Interesting solution, but this eliminates the need to store the specific bodygroups to use, 
	--         which either way would make things a bit more complicated (since we'd need to extract the bodygroup info from the model data itself)
	
	math.randomseed(ply:GetTTTPMValue())
	if cv_randbodygroups:GetBool() then pm_RandomizeBodyGroups(ply) end
	if cv_randskin:GetBool() then ply:SetSkin(math.random(0, ply:SkinCount())) end
	math.randomseed(os.time())
end

function pm_PlayerInitialSpawn(ply, transition)
	ply:SetTTTPMValue(math.random())
end

function pm_TTTPrepareRound()
	if cv_ordertype:GetInt() == 2 then
		local plys = player.GetAll()
		for i = 1, #plys do
			plys[i]:SetTTTPMValue(math.random())
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

function pm_RoleSync(ply, tmp) hook.Run("PlayerSetModel", ply) end

-- Hooks
hook.Add("PostPlayerDeath", "pm_PostPlayerDeath", pm_PostPlayerDeath)
hook.Add("PlayerInitialSpawn", "pm_PlayerInitialSpawn", pm_PlayerInitialSpawn)
hook.Add("TTTPrepareRound", "pm_TTTPrepareRound", pm_TTTPrepareRound)

hook.Add("PostGamemodeLoaded", "pm_Overrides", 
	function()
		-- [bjrkk] the actual function gets called right after the hooks, 
		--         therefore the gamemode overrides the custom playermodel.
		--         so let's just override the function
		pm_OriginalSetPlayerModel = gmod:GetGamemode().PlayerSetModel
		gmod:GetGamemode().PlayerSetModel = pm_SetPlayerModel
		
		-- [bjrkk] this is really not as nice, but since TTT1 doesn't provide any hooks for role syncing, we just have to hack it through
		if TTT2 then
			hook.Add("TTT2SpecialRoleSyncing", "pm_TTT2SpecialRoleSyncing", pm_RoleSync)
		else
			hook.Add("TTTBeginRound", "pm_TTTBeginRound", function()
				local plys = player.GetAll()
				for i = 1, #plys do
					pm_RoleSync(plys[i], {})
				end
			end)
		end
	end
)

-- Configuration/Init

local pm_default_table = 
{
	innocent = 
	{
		"models/player/phoenix.mdl",
		"models/player/arctic.mdl",
		"models/player/guerilla.mdl",
		"models/player/leet.mdl"
	},
	
	traitor =
	{
		"models/player/arctic.mdl",
		"models/player/guerilla.mdl",
	},
	
	detective =
	{
		"models/player/gasmask.mdl",
		"models/player/riot.mdl",
		"models/player/swat.mdl",
		"models/player/urban.mdl"
	},
	
	maps = 
	{
		gm_flatgrass =
		{
			innocent = { "models/player/kleiner.mdl" },
			detective = { "models/player/kleiner.mdl" }
		},
		
		gm_construct =
		{
			innocent = { "models/player/kleiner.mdl" },
			detective = { "models/player/kleiner.mdl" }
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
	
	local root = tbl
	
	if tbl["maps"] != nil then
		if tbl["maps"][game.GetMap()] then
			print("[pmTTT] Using " .. game.GetMap() .. " specific config")
			root = tbl["maps"][game.GetMap()]
		end
	end
	
	pm_models = root
	
	PrintTable(pm_models)
	print("[pmTTT] Verifying models...")
	
	for x=1, #root do
		for y=1, #root[x] do
			if !util.IsValidModel(root[x][y]) then
				print("[pmTTT] WARNING: Model " .. root[x][y] .. " is not valid.")
			end
		end
	end
	
	print("[pmTTT] Finished reading config!")
end

concommand.Add("ttt_pm_loadconfig", load_config)
load_config()