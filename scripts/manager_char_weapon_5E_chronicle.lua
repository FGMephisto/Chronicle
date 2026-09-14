-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

WEAPON_TYPE_RANGED = "ranged";

WEAPON_PROP_AMMUNITION = "ammunition";
WEAPON_PROP_CRITRANGE = "crit range %(?(%d+)%)?";
WEAPON_PROP_FINESSE = "finesse";
WEAPON_PROP_HEAVY = "heavy";
WEAPON_PROP_LIGHT = "light";
WEAPON_PROP_MAGIC = "magic";
WEAPON_PROP_REACH = "reach";
WEAPON_PROP_REROLL = "reroll %(?(%d+)%)?";
WEAPON_PROP_THROWN = "thrown";
WEAPON_PROP_TWOHANDED = "two%-handed";
WEAPON_PROP_VERSATILE = "versatile %(?%d?(d%d+)%)?";

WEAPON_TYPE_BOWS = "bows";
WEAPON_TYPE_CROSSBOWS = "crossbows";
WEAPON_PROP_ADAPTABLE = "adaptable";
WEAPON_PROP_POWERFUL = "powerful";
WEAPON_PROP_OFFHAND = "offhand";
WEAPON_PROP_DEFENSIVE = "defensive";

function onInit()
	DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", CharWeaponManager.onItemIDChanged);
end

--
--	Weapon inventory management
--

function addToWeaponDB(nodeItem)
	-- Parameter validation
	if not ItemManager.isWeapon(nodeItem) then
		return;
	end

	-- Get the weapon list we are going to add to
	local nodeChar = DB.getChild(nodeItem, "...");
	local nodeWeapons = DB.createChild(nodeChar, "weaponlist");
	if not nodeWeapons then
		return;
	end

	-- Set new weapons as equipped
	DB.setValue(nodeItem, "carried", "number", 2);

	-- Determine identification
	local nItemID = 0;
	if LibraryData.getIDState("item", nodeItem, true) then
		nItemID = 1;
	end

	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end

	-- Set default values for unidentified weapons
	local sWeaponSpeciality = "";
	local nWeaponTraining = 0;
	local sWeaponDmgAbility = "";
	local nWeaponDmgBonus = 0;

	-- Get weapon qualities
	local sWeaponQualities = DB.getValue(nodeItem, "weapon_qualities", "");

	-- Get data for identified weapons
	if nItemID == 1 then
		sWeaponSpeciality = DB.getValue(nodeItem, "weapon_speciality", "");
		nWeaponTraining = DB.getValue(nodeItem, "weapon_training", 0);
		sWeaponDmgAbility = DB.getValue(nodeItem, "weapon_dmg_ability", "");
		nWeaponDmgBonus = DB.getValue(nodeItem, "weapon_dmg_bonus", 0);
	end

	-- Set default Weapon Handling depending on weapon qualities
	local nWeaponHandling = 0;
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) then
		nWeaponHandling = 1;
	end
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_OFFHAND) then
		nWeaponHandling = 2;
	end
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_DEFENSIVE) then
		nWeaponHandling = 3;
	end

	-- Create weapon entries
	local nodeWeapon = DB.createChild(nodeWeapons);
	if nodeWeapon then
		DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
		DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. DB.getName(nodeItem));

		DB.setValue(nodeWeapon, "name", "string", sName);

		DB.setValue(nodeWeapon, "atk_skill", "string", sWeaponSpeciality);
		DB.setValue(nodeWeapon, "wpn_training", "number", nWeaponTraining);

		DB.setValue(nodeWeapon, "dmg_stat", "string", sWeaponDmgAbility);
		DB.setValue(nodeWeapon, "dmg_bonus", "number", nWeaponDmgBonus);

		DB.setValue(nodeWeapon, "wpn_qualities", "string", sWeaponQualities);
		DB.setValue(nodeWeapon, "wpn_handling", "number", nWeaponHandling);
	end

	-- Determine weapon type
	local bMelee = true;
	local bRanged = false;
	local bThrown = false;
	local sType = DB.getValue(nodeItem, "subtype", ""):lower();

	-- Check for Bows and Crossbows
	if sType:find(WEAPON_TYPE_BOWS) or sType:find(WEAPON_TYPE_CROSSBOWS) then
		bMelee = false;
		bRanged = true;
		bThrown = false;
	-- Check for Throwing weapons
	elseif sType:find(WEAPON_PROP_THROWN) then
		bMelee = false;
		bRanged = false;
		bThrown = true;
	end

	-- Set weapon ability and type
	if bMelee then
		DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("fighting"));
		DB.setValue(nodeWeapon, "wpn_type", "number", 0);
	elseif bRanged and not bThrown then
		DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("marksmanship"));
		DB.setValue(nodeWeapon, "wpn_type", "number", 1);
	elseif bThrown then
		DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("marksmanship"));
		DB.setValue(nodeWeapon, "wpn_type", "number", 2);
	end
end

function removeFromWeaponDB(nodeItem)
	if not nodeItem then
		return false;
	end

	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local sItemNode = DB.getPath(nodeItem);
	local sItemNode2 = "....inventorylist." .. DB.getName(nodeItem);
	local bFound = false;
	for _,v in ipairs(DB.getChildList(nodeItem, "...weaponlist")) do
		local _,sRecord = DB.getValue(v, "shortcut", "", "");
		if sRecord == sItemNode or sRecord == sItemNode2 then
			bFound = true;
			DB.deleteNode(v);
		end
	end

	return bFound;
end

--
--	Identification handling
--

function onItemIDChanged(nodeItemID)
	local nodeItem = DB.getChild(nodeItemID, "..");
	local nodeChar = DB.getChild(nodeItemID, "....");

	local sPath = DB.getPath(nodeItem);
	for _,vWeapon in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
		local _,sRecord = DB.getValue(vWeapon, "shortcut", "", "");
		if sRecord == sPath then
			CharWeaponManager.checkWeaponIDChange(vWeapon);
		end
	end
end

function checkWeaponIDChange(nodeWeapon)
	local _,sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	if sRecord == "" then
		return;
	end

	local nodeItem = DB.findNode(sRecord);
	if not nodeItem then
		return;
	end

	local bItemID = LibraryData.getIDState("item", nodeItem, true);
	local bWeaponID = (DB.getValue(nodeWeapon, "isidentified", 1) == 1);
	if bItemID == bWeaponID then
		return;
	end

	local sName;
	if bItemID then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		if sName == "" then
			sName = Interface.getString("item_unidentified");
		end
		sName = "** " .. sName .. " **";
	end
	DB.setValue(nodeWeapon, "name", "string", sName);

	if bItemID then
		DB.setValue(nodeWeapon, "atk_skill", "string", DB.getValue(nodeItem, "weapon_speciality", ""));
		DB.setValue(nodeWeapon, "wpn_training", "number", DB.getValue(nodeItem, "weapon_training", 0));
		DB.setValue(nodeWeapon, "dmg_stat", "string", DB.getValue(nodeItem, "weapon_dmg_ability", ""));
		DB.setValue(nodeWeapon, "dmg_bonus", "number", DB.getValue(nodeItem, "weapon_dmg_bonus", 0));
		DB.setValue(nodeWeapon, "isidentified", "number", 1);
	else
		DB.setValue(nodeWeapon, "atk_skill", "string", "");
		DB.setValue(nodeWeapon, "wpn_training", "number", 0);
		DB.setValue(nodeWeapon, "dmg_stat", "string", "");
		DB.setValue(nodeWeapon, "dmg_bonus", "number", 0);
		DB.setValue(nodeWeapon, "isidentified", "number", 0);
	end
end

--
--	Property helpers
--

function getRange(vActor, nodeWeapon)
	local nType = DB.getValue(nodeWeapon, "wpn_type", -1);
	if nType == -1 then
		nType = DB.getValue(nodeWeapon, "type", 0);
	end
	if (nType == 1) or (nType == 2) then
		return "R";
	end
	return "M";
end

function getCritRange(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local nCritThreshold;
	if CharWeaponManager.getRange(rActor, nodeWeapon) == "R" then
		nCritThreshold = DB.getValue(ActorManager.getCreatureNode(rActor), "weapon.critrange.ranged", 20);
	else
		nCritThreshold = DB.getValue(ActorManager.getCreatureNode(rActor), "weapon.critrange.melee", 20);
	end

	-- Check for crit range property
	local nPropCritRange = CharWeaponManager.getPropertyNumber(nodeWeapon, CharWeaponManager.WEAPON_PROP_CRITRANGE);
	if nPropCritRange and nPropCritRange < nCritThreshold then
		nCritThreshold = nPropCritRange;
	end

	return nCritThreshold;
end

function checkProperty(v, sTargetProperty)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "wpn_qualities", "");
		if sProperties == "" then
			sProperties = DB.getValue(v, "properties", "");
		end
	elseif sVarType == "string" then
		sProperties = v;
	else
		return false;
	end

	sTargetProperty = sTargetProperty:gsub("’", "'"):gsub("%-", ""):lower();
	local tProps = StringManager.split(sProperties:lower(), ",", true);
	for _,s in ipairs(tProps) do
		local sClean = s:gsub("’", "'"):gsub("%-", "");
		if sClean:match("^" .. sTargetProperty) then
			return true;
		end
	end
	return false;
end

function getProperty(v, sTargetPattern)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "wpn_qualities", "");
		if sProperties == "" then
			sProperties = DB.getValue(v, "properties", "");
		end
	elseif sVarType == "string" then
		sProperties = v;
	else
		return nil;
	end

	local tProps = StringManager.split(sProperties:lower(), ",", true);
	for _,s in ipairs(tProps) do
		local result = s:match("^" .. sTargetPattern);
		if result then
			return result;
		end
	end
	return nil;
end

function getPropertyNumber(v, sTargetPattern)
	local sProp = CharWeaponManager.getProperty(v, sTargetPattern);
	if sProp then
		return tonumber(sProp) or 0;
	end
	return nil;
end


function getAttackAbility(vActor, nodeWeapon)
	local sAbility = DB.getValue(nodeWeapon, "atk_stat", "");
	if sAbility ~= "" then
		return sAbility;
	end
	sAbility = DB.getValue(nodeWeapon, "attackstat", "");
	if sAbility ~= "" then
		return sAbility;
	end

	local nType = DB.getValue(nodeWeapon, "wpn_type", -1);
	if nType == -1 then
		nType = DB.getValue(nodeWeapon, "type", 0);
	end
	if nType == 1 then
		return "dexterity";
	end

	local rActor = ActorManager.resolveActor(vActor);
	if CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE) then
		if ActorManager5E.getAbilityBonus(rActor, "dexterity") > ActorManager5E.getAbilityBonus(rActor, "strength") then
			return "dexterity";
		end
	end

	return "strength";
end

function getAttackBonus(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local sAbility = DB.getValue(nodeWeapon, "atk_stat", "");
	local sSkill = ActionsManager2.ConvertToTechnical(DB.getValue(nodeWeapon, "atk_skill", ""));
	local nStat = ActorManager5E.getAbilityScore(rActor, sAbility);
	local nSkill = ActorManager5E.getSkillRank(rActor, sSkill);
	local nTraining = DB.getValue(nodeWeapon, "wpn_training", 0);
	local nBonus = DB.getValue(nodeWeapon, "atk_bonus", 0);
	local nPenalty = 0;

	-- Calculate Bonus dice after Training
	if nTraining > nSkill then
		nPenalty = nTraining - nSkill;
		nSkill = 0;
	else
		nSkill = nSkill - nTraining;
	end

	return nStat, nSkill, nPenalty, nBonus, sAbility, sSkill;
end

local _bWeaponMasteryUpdating = false;
function onWeaponMasteryChanged(nodeWeapon)
	if _bWeaponMasteryUpdating then
		return;
	end
	_bWeaponMasteryUpdating = true;

	local _, sWeaponRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	local nValue = DB.getValue(nodeWeapon, "masteryknown", 0);
	for _,node in ipairs(DB.getChildList(nodeWeapon, "..")) do
		if node ~= nodeWeapon then
			local _, sRecord = DB.getValue(node, "shortcut", "", "");
			if sRecord == sWeaponRecord then
				DB.setValue(node, "masteryknown", "number", nValue);
			end
		end
	end

	_bWeaponMasteryUpdating = false;
end

--
--	Action helpers
--

function buildAttackAction(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local rAction = {
		bWeapon = true,
		label = DB.getValue(nodeWeapon, "name", ""),
		range = CharWeaponManager.getRange(rActor, nodeWeapon),
		nodeWeapon = nodeWeapon,
		tAddText = {},
	};

	rAction.nStat, rAction.nSkill, rAction.nPenalty, rAction.nMod, rAction.sStat, rAction.sSkill = CharWeaponManager.getAttackBonus(rActor, nodeWeapon);

	if rAction.range == "R" then
		local sProperties = DB.getValue(nodeWeapon, "wpn_qualities", "");
		if sProperties == "" then
			sProperties = DB.getValue(nodeWeapon, "properties", "");
		end
		sProperties = sProperties:lower();
		local sRange, sRangeLong = sProperties:match("range (%d+)[\\/](%d+)");
		if not sRange then
			sRange = sProperties:match("range (%d+)");
		end
		rAction.nRange = tonumber(sRange) or 0;
		rAction.nRangeLong = tonumber(sRangeLong) or 0;
	end

	return rAction;
end

function decrementAmmo(vActor, nodeWeapon)
	local nMaxAmmo = DB.getValue(nodeWeapon, "maxammo", 0);
	if nMaxAmmo <= 0 then
		return;
	end

	local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
	if nUsedAmmo >= nMaxAmmo then
		ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, ActorManager.resolveActor(vActor));
		return;
	end

	DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + 1);
end

function getDamageBaseAbility(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local sAbility = DB.getValue(nodeWeapon, "dmg_stat", "");
	if sAbility ~= "" then
		return sAbility;
	end

	local nWeaponType = DB.getValue(nodeWeapon, "wpn_type", -1);
	if nWeaponType == -1 then
		nWeaponType = DB.getValue(nodeWeapon, "type", 0);
	end

	if nWeaponType == 1 then
		sAbility = "dexterity";
	else
		sAbility = "strength";
		if CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE) then
			local nSTR = ActorManager5E.getAbilityBonus(rActor, "strength");
			local nDEX = ActorManager5E.getAbilityBonus(rActor, "dexterity");
			if nDEX > nSTR then
				sAbility = "dexterity";
			end
		end
	end

	if (DB.getValue(nodeWeapon, "wpn_handling", 0) == 2) or (DB.getValue(nodeWeapon, "handling", 0) == 2) then
		sAbility = "-" .. sAbility;
	end

	return sAbility;
end

function getDamageClauses(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local clauses = {};

	-- Get damage modifiers
	local sDmgAbility = DB.getValue(nodeWeapon, "dmg_stat", "");
	local nDmgBase = ActorManager5E.getAbilityScore(rActor, sDmgAbility);
	if nDmgBase < 0 then
		nDmgBase = 0;
	end
	local nDmgBonus = DB.getValue(nodeWeapon, "dmg_bonus", 0);
	local nDmgMod = DB.getValue(nodeWeapon, "dmg_mod", 0);
	local nDmgTotal = nDmgBase + nDmgBonus + nDmgMod;

	-- Get all weapon qualities
	local sWeaponGrade = DB.getValue(nodeWeapon, "wpn_grade", "");
	local sWeaponQualities = DB.getValue(nodeWeapon, "wpn_qualities", "");
	local bWEAPON_PROP_ADAPTABLE = CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_ADAPTABLE);
	local bWEAPON_PROP_POWERFUL = CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_POWERFUL);

	-- Get current weapon handling
	local nWeaponHandling = DB.getValue(nodeWeapon, "wpn_handling", 0);

	-- If Weapon Grade is "Extraordinary", add +1 damage
	if sWeaponGrade == "Extraordinary" then
		nDmgTotal = nDmgTotal + 1;
	end

	-- If Weapon Handling is "two-handed" and weapon has quality "Adaptable", add +1 damage
	if nWeaponHandling == 1 and bWEAPON_PROP_ADAPTABLE then
		nDmgTotal = nDmgTotal + 1;
	end

	-- If weapon has quality "Powerful", add Strength Skill rank as damage bonus
	if bWEAPON_PROP_POWERFUL then
		local nStrengthBonus = ActorManager5E.getSkillRank(rActor, "strength");
		if nStrengthBonus > 0 then
			nDmgTotal = nDmgTotal + nStrengthBonus;
		end
	end

	-- Set minimum damage
	if nDmgTotal < 1 then
		nDmgTotal = 1;
	end

	-- Add clause to list of clauses
	table.insert(clauses, { dice = {}, stat = sDmgAbility, modifier = nDmgTotal });

	return clauses;
end

function buildDamageAction(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local rAction = {
		bWeapon = true,
		nodeWeapon = nodeWeapon,
		label = DB.getValue(nodeWeapon, "name", ""),
		tAddText = {},
	};

	local nWeaponHandling = DB.getValue(nodeWeapon, "wpn_handling", 0);
	rAction.handling = nWeaponHandling;
	if nWeaponHandling == 1 then
		rAction.label = rAction.label .. " (2H)";
	elseif nWeaponHandling == 2 then
		rAction.label = rAction.label .. " (OH)";
	end

	rAction.range = CharWeaponManager.getRange(rActor, nodeWeapon);
	rAction.clauses = CharWeaponManager.getDamageClauses(rActor, nodeWeapon);
	rAction.nDoS = (tonumber(DB.getValue(nodeWeapon, "dmg_multiplier", 0)) or 0) + 1;

	return rAction;
end

function buildDamageString(vActor, nodeWeapon)
	local rActor = ActorManager.resolveActor(vActor);
	local aDamage = {};
	local clauses = CharWeaponManager.getDamageClauses(rActor, nodeWeapon);

	for _,v in ipairs(clauses) do
		if (v.modifier ~= 0) or (#(v.dice or {}) > 0) then
			local sDamage = StringManager.convertDiceToString(v.dice, v.modifier);
			table.insert(aDamage, sDamage);
		end
	end

	return table.concat(aDamage, "\n");
end

--
--	CHRONICLE CUSTOM SYSTEMS
--

function getPropertyValue(v, sTargetProperty)
	local sQualities;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sQualities = DB.getValue(v, "wpn_qualities", "");
		if sQualities == "" then
			sQualities = DB.getValue(v, "properties", "");
		end
	elseif sVarType == "string" then
		sQualities = v;
	else
		return nil;
	end

	sTargetProperty = sTargetProperty:gsub("’", "'"):gsub("%-", ""):lower();
	local tProps = StringManager.split(sQualities:lower(), ",", true);
	for _, s in ipairs(tProps) do
		local sClean = s:gsub("’", "'"):gsub("%-", "");
		local result = sClean:match("^" .. sTargetProperty);
		if result then
			local sNum = sClean:gsub("%a+", "");
			return tonumber(sNum);
		end
	end

	return nil;
end