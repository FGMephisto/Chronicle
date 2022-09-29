-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

local rsname = "Chronicle";
local rsmajorversion = 8;

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	if Session.IsHost or Session.IsLocal then
		VersionManager2.updateCampaign();
	end

	DB.onAuxCharLoad = onCharImport;
	DB.onImport = onImport;
	Module.onModuleLoad = onModuleLoad;
end

-- ===================================================================================================================
-- ===================================================================================================================
function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	VersionManager2.updateChar(nodePC, aMajor[rsname]);
end

-- ===================================================================================================================
-- ===================================================================================================================
function onImport(node)
	local apath = StringManager.split(node.getPath(), ".");
	if #apath == 2 and apath[1] == "charsheet" then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		VersionManager2.updateChar(node, aMajor[rsname]);
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	VersionManager2.updateModule(sModule, aMajor[rsname]);
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateCampaign()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];

	if not major then
		return;
	end

	if major > 0 and major < rsmajorversion then
		print("Migrating campaign database to latest data version.");
		DB.backup();
		
		-- Check for campaign major version
		if major < 5 then
			for _, nodeChar in pairs (DB.getChildren("charsheet")) do
				VersionManager2.migrateChar5(nodeChar);
			end
		end

		-- Check for campaign major version
		if major < 6 then
			for _, nodeChar in pairs (DB.getChildren("charsheet")) do
				VersionManager2.migrateChar6(nodeChar)
			end

			for _, nodeNPC in pairs (DB.getChildren("npc")) do
				VersionManager2.migrateNPC6(nodeNPC)
			end

			for _, nodeCT in pairs (DB.getChildren("combattracker.list")) do
				VersionManager2.migrateCT6(nodeCT)
			end
		end

		-- Check for campaign major version
		if major < 7 then
			for _, nodeChar in pairs (DB.getChildren("charsheet")) do
				VersionManager2.migrateChar7(nodeChar)
			end

			for _, nodeNPC in pairs (DB.getChildren("npc")) do
				VersionManager2.migrateNPC7(nodeNPC)
			end

			for _, nodeCT in pairs (DB.getChildren("combattracker.list")) do
				VersionManager2.migrateCT7(nodeCT)
			end
		end

		-- Check for campaign major version
		if major < 8 then
			for _, nodeNPC in pairs (DB.getChildren("npc")) do
				VersionManager2.migrateNPC8(nodeNPC)
			end

			for _, nodeCT in pairs (DB.getChildren("combattracker.list")) do
				VersionManager2.migrateCT8(nodeCT)
			end
		end

		-- Check for campaign major version
		if major < 9 then
			for _, nodeChar in pairs (DB.getChildren("charsheet")) do
				VersionManager2.migrateChar8(nodeChar)
			end
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end
	
	if nVersion < rsmajorversion then
		if nVersion < 5 then
			VersionManager2.migrateChar5(nodePC);
		end
		if nVersion < 6 then
			VersionManager2.migrateChar6(nodePC);
		end
		if nVersion < 7 then
			VersionManager2.migrateChar7(nodePC);
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateModule(sModule, nVersion)
	return;
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateChar5(nodeChar)
	-- Delete data node as we will rebuild it
	DB.deleteChild(nodeChar, "abilities");

	-- Create "Abilities" & "SkillList" nodes if missing
	local EntryMap = {}
	local nodeAbilities = DB.createChild(nodeChar, "abilities")
	local nodeSkillList = DB.createChild(nodeChar, "skilllist")

	-- Create all Abilities in the "abilities" node if missing
	for key, value in pairs (DataCommon.abilities) do
		nodeAbilityCreated = DB.createChild(nodeAbilities, DataCommon.abilities[key])
		DB.setValue(nodeAbilityCreated, "score", "number", "2")
	end

	-- Get Abilities for migration
	for _, nodeListAbilities in pairs (DB.getChildren(nodeChar, "listabilities")) do
		-- Get Ability values we migrate from
		sListAbilityName = string.lower(DB.getValue(nodeListAbilities, "name", ""))
		sListAbilityTestDice = DB.getValue(nodeListAbilities, "dicetest", "")
		
		-- Get Ability node we migrate to
		nodeAbilityName = DB.getChild(nodeAbilities, sListAbilityName, "")
		
		-- Migrate Ability data
		DB.setValue(nodeAbilityName, "score", "number", sListAbilityTestDice)
		
		-- Get Specialties for migration
		for key , nodeSkill in pairs (DB.getChildren(nodeListAbilities, "listspecialities")) do
			-- Get Skill values we migrate from
			sSkillName = string.lower(DB.getValue(nodeSkill, "name", ""))
			nSkillBonusDice = DB.getValue(nodeSkill, "dicebonus", "")

			-- Add the sSkillName and nSkillBonusDice to the EntryMap which we will use to create and fill missing Skill nodes
			if sSkillName ~= "" then
				EntryMap[sSkillName] = nSkillBonusDice
			end
		end
	end

	-- Use the EntryMap to create and fill missing Skill nodes
	for key, dice in pairs (EntryMap) do
		local keyupper = ""
		nodeSkillCreated = DB.createChild(nodeSkillList)

		-- Capitalize first letter of every word
		for word in key:gmatch("%w+") do
			if keyupper ~= "" then
				keyupper = keyupper .. " " .. word:gsub("^%l", string.upper)
			end

			if keyupper == "" then
				keyupper = keyupper .. word:gsub("^%l", string.upper)
			end
		end

		-- Set values
		DB.setValue(nodeSkillCreated, "misc", "number", dice)
		DB.setValue(nodeSkillCreated, "name", "string", keyupper)
		DB.setValue(nodeSkillCreated, "stat", "string", DataCommon.skilldata[keyupper].stat)
	end

	-- Delete old data node
	DB.deleteChild(nodeChar, "listabilities");
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateChar6(nodeChar)
	-- Get nodes for migration
	for _, nodeWeapon in pairs (DB.getChildren(nodeChar, "weaponlist")) do
		-- Migrate values from old to new DB entries
		DB.setValue(nodeWeapon, "wpn_handling", "number", DB.getValue(nodeWeapon, "handling", 0))
		DB.setValue(nodeWeapon, "wpn_qualities", "string", DB.getValue(nodeWeapon, "qualities", ""))
		DB.setValue(nodeWeapon, "wpn_type", "number", DB.getValue(nodeWeapon, "type", 0))
		DB.setValue(nodeWeapon, "wpn_grade", "string", DB.getValue(nodeWeapon, "weapon_grade", "Common"))
		DB.setValue(nodeWeapon, "wpn_training", "number", DB.getValue(nodeWeapon, "weapon_training", 0))

		-- Delete non-required DB entries
		DB.deleteChild(nodeWeapon, "atkskill")
		DB.deleteChild(nodeWeapon, "atkstat")
		DB.deleteChild(nodeWeapon, "dmgbonus")
		DB.deleteChild(nodeWeapon, "dmgmod")
		DB.deleteChild(nodeWeapon, "dmgstat")
		DB.deleteChild(nodeWeapon, "dmg_base")
		DB.deleteChild(nodeWeapon, "grade")
		DB.deleteChild(nodeWeapon, "training")
		DB.deleteChild(nodeWeapon, "wpngrade")

		-- Delete old migrated DB entries
		DB.deleteChild(nodeWeapon, "handling")
		DB.deleteChild(nodeWeapon, "qualities")
		DB.deleteChild(nodeWeapon, "type")
		DB.deleteChild(nodeWeapon, "weapon_grade")
		DB.deleteChild(nodeWeapon, "weapon_training")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateChar7(nodeChar)
	-- Get nodes for migration
	for _, nodeSkills in pairs (DB.getChildren(nodeChar, "skilllist")) do
		-- Delete old migrated DB entries
		DB.deleteChild(nodeWeapon, "wpn_name")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateChar8(nodeChar)
	-- Get nodes for migration
	for _, nodeSkills in pairs (DB.getChildren(nodeChar, "skilllist")) do
		-- Delete old migrated DB entries
		DB.deleteChild(nodeSkills, "statshort")
		DB.deleteChild(nodeSkills, "total")		
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateNPC6(nodeNPC)
	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeNPC, "actions")) do
		-- Migrate values from old to new DB entries
		DB.setValue(nodeAction, "atk_bonus", "number", DB.getValue(nodeAction, "atk_modifier", 0))
		DB.setValue(nodeAction, "wpn_handling", "number", DB.getValue(nodeAction, "atk_handling", 0))
		DB.setValue(nodeAction, "wpn_qualities", "string", DB.getValue(nodeAction, "desc", ""))
		DB.setValue(nodeAction, "wpn_type", "number", DB.getValue(nodeAction, "atk_type", 0))

		-- Delete old migrated DB entries
		DB.deleteChild(nodeAction, "atk_handling")
		DB.deleteChild(nodeAction, "atk_modifier")
		DB.deleteChild(nodeAction, "atk_type")
		DB.deleteChild(nodeAction, "desc")
		DB.deleteChild(nodeAction, "handling")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateNPC7(nodeNPC)
	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeNPC, "actions")) do
		-- Delete old migrated DB entries
		DB.deleteChild(nodeAction, "wpn_name")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateNPC8(nodeNPC)
	-- Create target node
	nodeNPC.createChild("weaponlist")

	-- Get new path to weaponlist
	nodeWeapon = DB.getPath(nodeNPC, "weaponlist")

	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeNPC, "actions")) do
		-- Copy actions nodes to weaponlist nodes
		DB.copyNode(nodeAction , nodeWeapon)
	end
	
	-- Delete old actions node
	DB.deleteNode(DB.getPath(nodeNPC, "actions"))
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateCT6(nodeCT)
	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeCT, "actions")) do
		-- Migrate values from old to new DB entries
		DB.setValue(nodeAction, "atk_bonus", "number", DB.getValue(nodeAction, "atk_modifier", 0))
		DB.setValue(nodeAction, "wpn_handling", "number", DB.getValue(nodeAction, "atk_handling", 0))
		DB.setValue(nodeAction, "wpn_qualities", "string", DB.getValue(nodeAction, "desc", ""))
		DB.setValue(nodeAction, "wpn_type", "number", DB.getValue(nodeAction, "atk_type", 0))

		-- Delete old migrated DB entries
		DB.deleteChild(nodeAction, "atk_handling")
		DB.deleteChild(nodeAction, "atk_modifier")
		DB.deleteChild(nodeAction, "atk_type")
		DB.deleteChild(nodeAction, "desc")
		DB.deleteChild(nodeAction, "handling")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateCT7(nodeCT)
	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeCT, "actions")) do
		-- Delete old migrated DB entries
		DB.deleteChild(nodeAction, "wpn_name")
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function migrateCT8(nodeCT)
	-- Create target node
	nodeCT.createChild("weaponlist")

	-- Get new path to weaponlist
	nodeWeapon = DB.getPath(nodeCT, "weaponlist")

	-- Get nodes for migration
	for _, nodeAction in pairs (DB.getChildren(nodeCT, "actions")) do
		-- Copy actions nodes to weaponlist nodes
		DB.copyNode(nodeAction , nodeWeapon)
	end
	
	-- Delete old actions node
	DB.deleteNode(DB.getPath(nodeCT, "actions"))
end