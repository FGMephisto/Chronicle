-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
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
WEAPON_PROP_TWOHANDED = "two-handed";
WEAPON_PROP_VERSATILE = "versatile %(?%d?(d%d+)%)?";

WEAPON_TYPE_BOWS = "bows"
WEAPON_TYPE_CROSSBOWS = "crossbows"
WEAPON_TYPE_THROWN = "thrown"
WEAPON_PROP_ADAPTABLE = "adaptable"
WEAPON_PROP_POWERFUL = "powerful"
WEAPON_PROP_OFFHAND = "offhand"
WEAPON_PROP_DEFENSIVE = "defensive"

function onInit()
	DB.addHandler("charsheet.*.inventorylist.*.isidentified", "onUpdate", onItemIDChanged);
end

--
--	Weapon inventory management
--

-- Adjusted - Adds weapon data to Weapon Action List if a weapon is dropped to the Inventory List
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
	
	-- Set default values for all weapons
	local sWeaponSpeciality = "";
	local nWeaponTraining = 0;
	local sWeaponDmgAbility = "";
	local nWeaponDmgBonus = 0;
	
	-- Grab some information from the source node to populate the new weapon entries
	local sName;
	if nItemID == 1 then
		sName = DB.getValue(nodeItem, "name", "");
		sWeaponSpeciality = DB.getValue(nodeItem, "weapon_speciality", "");
		nWeaponTraining = DB.getValue(nodeItem, "weapon_training", 0);
		sWeaponDmgAbility = DB.getValue(nodeItem, "weapon_dmg_ability", "");
		nWeaponDmgBonus = DB.getValue(nodeItem, "weapon_dmg_bonus", 0);
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		sName = "** " .. sName .. " **";
	end
	-- local nBonus = 0;
	-- if nItemID == 1 then
		-- nBonus = DB.getValue(nodeItem, "bonus", 0);
	-- end

	-- Get weapon qualities
	local sWeaponQualities = DB.getValue(nodeItem, "weapon_qualities", "");

	-- Set default Weapon Handling depending on weapon qualities
	local nWeaponHandling = 0;

	-- Set Weapon Handling depending on weapon qualities
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) == true then
		nWeaponHandling = 1;
	end
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_OFFHAND) == true then
		nWeaponHandling = 2;
	end
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_DEFENSIVE) == true then
		nWeaponHandling = 3;
	end

	-- Parse damage field
	-- local sDamage = DB.getValue(nodeItem, "damage", "");
	
	-- local aDmgClauses = {};
	-- local aWords = StringManager.parseWords(sDamage:lower());
	-- local i = 1;
	-- while aWords[i] do
		-- local aDiceString = {};
		
		-- while StringManager.isDiceString(aWords[i]) do
			-- table.insert(aDiceString, aWords[i]);
			-- i = i + 1;
		-- end
		-- if #aDiceString == 0 then
			-- break;
		-- end
		
		-- local aDamageTypes = {};
		-- while StringManager.contains(DataCommon.dmgtypes, aWords[i]) do
			-- table.insert(aDamageTypes, aWords[i]);
			-- i = i + 1;
		-- end
		-- if bMagic then
			-- table.insert(aDamageTypes, "magic");
		-- end
		
		-- local rDmgClause = {};
		-- rDmgClause.aDice, rDmgClause.nMod = StringManager.convertStringToDice(table.concat(aDiceString, " "));
		-- rDmgClause.dmgtype = table.concat(aDamageTypes, ",");
		-- table.insert(aDmgClauses, rDmgClause);
		
		-- if StringManager.contains({ "+", "plus" }, aWords[i]) then
			-- i = i + 1;
		-- end
	-- end

	-- Create weapon entries
	local nodeWeapon = DB.createChild(nodeWeapons);

	if nodeWeapon then
		DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
		DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. nodeItem.getName());

		DB.setValue(nodeWeapon, "name", "string", sName);

		DB.setValue(nodeWeapon, "atk_skill", "string", sWeaponSpeciality);
		DB.setValue(nodeWeapon, "wpn_training", "number", nWeaponTraining);

		DB.setValue(nodeWeapon, "dmg_stat", "string", sWeaponDmgAbility);
		DB.setValue(nodeWeapon, "dmg_bonus", "number", nWeaponDmgBonus);

		DB.setValue(nodeWeapon, "wpn_qualities", "string", sWeaponQualities)	;	

		-- Handle qualities
		DB.setValue(nodeWeapon, "wpn_handling", "number", nWeaponHandling)

	end

	-- Determine weapon type
	-- Assume Melee weapon as default
	local bMelee = true
	local bRanged = false
	local bThrown = false
	local sType = DB.getValue(nodeItem, "subtype", ""):lower()

	-- Check for Bows and Crossbows
	if sType:find(WEAPON_TYPE_BOWS) or sType:find(WEAPON_TYPE_CROSSBOWS) then
		bMelee = false;
		bRanged = true;
		bThrown = false;
	-- Check for Throwing weapons
	elseif sType:find(WEAPON_TYPE_THROWN) then
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
		local sClass, sRecord = DB.getValue(v, "shortcut", "", "");
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

-- Adjusted - Change weapon name in Weapon DB if the items "identified" value changes
function checkWeaponIDChange(nodeWeapon)
	local _,sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
	if sRecord == "" then
		return;
	end
	local nodeItem = DB.findNode(sRecord);
	if not nodeItem then
		return;
	end
	
	local bItemID = LibraryData.getIDState("item", DB.findNode(sRecord), true);
	local bWeaponID = (DB.getValue(nodeWeapon, "isidentified", 1) == 1);
	if bItemID == bWeaponID then
		return;
	end
	
	local sName;
	if bItemID then
		sName = DB.getValue(nodeItem, "name", "");
	else
		sName = DB.getValue(nodeItem, "nonid_name", "");
		sName = "** " .. sName .. " **";
	end
	DB.setValue(nodeWeapon, "name", "string", sName);

	-- local nBonus = 0;
	-- if bItemID then
		-- DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		-- local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		-- if #aDamageNodes > 0 then
			-- DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		-- end
	-- else
		-- DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		-- local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		-- if #aDamageNodes > 0 then
			-- DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		-- end
	-- end
	
	if bItemID then
		DB.setValue(nodeWeapon, "isidentified", "number", 1);
	else
		DB.setValue(nodeWeapon, "isidentified", "number", 0);
	end
end

--
--	Property helpers
--

-- Adjusted
function getRange(nodeChar, nodeWeapon)
	local nType = DB.getValue(nodeWeapon, "wpn_type", 0);
	if (nType == 1) or (nType == 2) then
		return "R";
	end
	return "M";
end

-- Adjusted
function getCritRange(nodeChar, nodeWeapon)
	-- local nCritThreshold = 20;

	-- if CharWeaponManager.getRange(nodeChar, nodeWeapon) == "R" then
		-- nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.ranged", 20);
	-- else
		-- nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.melee", 20);
	-- end

	-- Check for crit range property
	-- local nPropCritRange = getPropertyNumber(nodeWeapon, CharWeaponManager.WEAPON_PROP_CRITRANGE);
	-- if nPropCritRange and nPropCritRange < nCritThreshold then
		-- nCritThreshold = nPropCritRange;
	-- end

	-- return nCritThreshold;
end

-- Adjusted
function checkProperty(v, sTargetProperty)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "wpn_qualities", "");
	elseif sVarType == "string" then
		sProperties = v;
	else
		return nil;
	end

	-- Get rid of some problem characters and make lowercase
	sTargetProperty = sTargetProperty:gsub("’", "'")
	sTargetProperty = sTargetProperty:gsub("%-", "")
	sTargetProperty = sTargetProperty:lower()
	
	local tProps = StringManager.split(sProperties:lower(), ",", true);
	for _,s in ipairs(tProps) do
		if s:match("^" .. sTargetProperty) then
			return true;
		end
	end
	return false;
end

-- Adjusted
function getProperty(v, sTargetPattern)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "wpn_qualities", "");
	elseif sVarType == "string" then
		sProperties = v;
	else
		return nil;
	end

	-- Get rid of some problem characters, and make lowercase
	sTargetProperty = sTargetProperty:gsub("’", "'")
	sTargetProperty = sTargetProperty:gsub("%-", "")
	sTargetProperty = sTargetProperty:lower()

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

-- Adjusted
function getAttackAbility(nodeChar, nodeWeapon)
	-- local sAbility = DB.getValue(nodeWeapon, "attackstat", "");
	-- if sAbility ~= "" then
		-- return sAbility;
	-- end

	-- local nType = DB.getValue(nodeWeapon, "type", 0);
	-- if nType == 1 then -- Ranged
		-- return "dexterity";
	-- end

	-- Melee or Thrown
	-- local bFinesse = CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE);
	-- if bFinesse then
		-- local nSTR = ActorManager5E.getAbilityBonus(nodeChar, "strength");
		-- local nDEX = ActorManager5E.getAbilityBonus(nodeChar, "dexterity");
		-- if nDEX > nSTR then
			-- return "dexterity";
		-- end
	-- end

	-- return "strength";
end

-- Adjusted
function getAttackBonus(nodeChar, nodeWeapon)
	-- local sAbility = CharWeaponManager.getAttackAbility(nodeChar, nodeWeapon);
	
	-- local nMod = DB.getValue(nodeWeapon, "attackbonus", 0);
	-- nMod = nMod + ActorManager5E.getAbilityBonus(nodeChar, sAbility);
	-- if DB.getValue(nodeWeapon, "prof", 0) == 1 then
		-- nMod = nMod + DB.getValue(nodeChar, "profbonus", 0);
	-- end

	-- return nMod, sAbility;
end

--
--	Action helpers
--

function buildAttackAction(nodeChar, nodeWeapon)
	local rAction = {
		bWeapon = true,
		label = DB.getValue(nodeWeapon, "name", ""),
		range = CharWeaponManager.getRange(nodeChar, nodeWeapon),
		tAddText = {},
	};

	-- rAction.modifier, rAction.stat = getAttackBonus(nodeChar, nodeWeapon);
	
	-- local nCritThreshold = CharWeaponManager.getCritRange(nodeChar, nodeWeapon);
	-- if nCritThreshold > 1 and nCritThreshold < 20 then
		-- rAction.nCritRange = nCritThreshold;
	-- end

	-- if ((rAction.nCritRange or 20) > 18) and CharManager.hasFeature(nodeChar, CharManager.FEATURE_SUPERIOR_CRITICAL) then
		-- rAction.nCritRange = 18;
		-- table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feature_superior_critical")));
	-- elseif ((rAction.nCritRange or 20) > 19) and CharManager.hasFeature(nodeChar, CharManager.FEATURE_IMPROVED_CRITICAL) then
		-- rAction.nCritRange = 19;
		-- table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feature_improved_critical")));
	-- end

	-- if (DB.getValue(nodeWeapon, "type", 0) == 1) and CharManager.hasFeat2024(nodeChar, CharManager.FEAT_ARCHERY) then
		-- rAction.modifier = (rAction.modifier or 0) + 2;
		-- table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_archery")));
	-- end

	rAction.nodeWeapon = nodeWeapon;
	rAction.nStat, rAction.nSkill, rAction.nPenalty, rAction.nMod, rAction.sStat, rAction.sSkill = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);

	return rAction;
end

function decrementAmmo(nodeChar, nodeWeapon)
	local nMaxAmmo = DB.getValue(nodeWeapon, "maxammo", 0);
	if nMaxAmmo > 0 then
		local nUsedAmmo = DB.getValue(nodeWeapon, "ammo", 0);
		if nUsedAmmo >= nMaxAmmo then
			local rActor = ActorManager.resolveActor(nodeChar);
			ChatManager.Message(Interface.getString("char_message_atkwithnoammo"), true, rActor);
		else
			DB.setValue(nodeWeapon, "ammo", "number", nUsedAmmo + 1);
		end
	end
end

-- Adjusted
function getDamageBaseAbility(nodeChar, nodeWeapon)
	local sAbility = "";

	-- Use ability based on type
	-- local nWeaponType = DB.getValue(nodeWeapon, "type", 0);
	-- Ranged
	-- if nWeaponType == 1 then
		-- sAbility = "dexterity";
	-- Melee or Thrown
	-- else
		-- sAbility = "strength";

		-- local bFinesse = CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE);
		-- if bFinesse then
			-- local nSTR = ActorManager5E.getAbilityBonus(nodeChar, "strength");
			-- local nDEX = ActorManager5E.getAbilityBonus(nodeChar, "dexterity");
			-- if nDEX > nSTR then
				-- sAbility = "dexterity";
			-- end
		-- end
	-- end

	-- However, if off-hand without two-weapon fighting, only use negative ability
	-- if (DB.getValue(nodeWeapon, "handling", 0) == 2) then
		-- local bTwoWeaponStyle = (DB.getValue(nodeChar, "weapon.twoweaponfighting", 0) == 1) or CharManager.hasFeat2024(nodeChar, CharManager.FEAT_TWO_WEAPON_FIGHTING);
		-- if not bTwoWeaponStyle then
			-- sAbility = "-" .. sAbility;
		-- end
	-- end

	sAbility = DB.getValue(nodeWeapon, "dmg_stat", "Athletics");
	return sAbility;
end

-- Adjusted
function getDamageClauses(nodeChar, nodeWeapon)
	local rActor = ActorManager.resolveActor(nodeChar);
	local clauses = {};

	-- Get damage modifiers
	local sDmgAbility = DB.getValue(nodeWeapon, "dmg_stat", "");
	local nDmgBase = ActorManager5E.getAbilityScore(rActor, sDmgAbility);
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

	-- If Weapon Grade is "Extraordinar", add +1 damage
	if sWeaponGrade == "Extraordinary" then
		nDmgTotal = nDmgTotal + 1;
	end

	-- If Weapon Handling is "two-handed" and weapon has quality "Adaptable", add +1 damage
	if nWeaponHandling == 1 and bWEAPON_PROP_ADAPTABLE == true then
		nDmgTotal = nDmgTotal + 1;
	end

	-- If weapon has quality "Powerful", add Strength Skill rank as damage bonus
	if bWEAPON_PROP_POWERFUL == true then
		-- Get Strength modificator
		nStrengthBonus = ActorManager5E.getSkillRank(rActor, "strength");
		nDmgTotal = nDmgTotal + nStrengthBonus;
	end

	-- Set minimum damage
	if nDmgTotal < 1 then
		nDmgTotal = 1;
	end

	-- Add clause to list of clauses
	table.insert(clauses, { dice = {}, stat = sDmgAbility, modifier = nDmgTotal });

	return clauses;
end

function buildDamageAction(nodeChar, nodeWeapon)
	local rAction = {
		bWeapon = true,
		label = DB.getValue(nodeWeapon, "name", ""),
		tAddText = {},
	};

	rAction.nodeWeapon = nodeWeapon;
	rAction.handling = DB.getValue(nodeWeapon, "wpn_handling", 0);

	if rAction.nWeaponHandling == 1 then
		rAction.label = rAction.label .. " (2H)";
	elseif rAction.nWeaponHandling == 2 then
		rAction.label = rAction.label .. " (OH)";
	end

	-- Determine range
	rAction.range = CharWeaponManager.getRange(nodeChar, nodeWeapon);
	
	-- Check for reroll property
	local nPropReroll = CharWeaponManager.getPropertyNumber(nodeWeapon, CharWeaponManager.WEAPON_PROP_REROLL);
	if nPropReroll and (nPropReroll > 0) then
		rAction.nReroll = nPropReroll;
	end
	
	-- Build damage clauses
	rAction.clauses = CharWeaponManager.getDamageClauses(nodeChar, nodeWeapon);

	-- Determine Degrees of Success
	rAction.nDoS = DB.getValue(nodeWeapon, "dmg_multiplier", "") + 1

	return rAction;
end

function buildDamageString(nodeChar, nodeWeapon)
	local aDamage = {};
	local sBaseAbility = CharWeaponManager.getDamageBaseAbility(nodeChar, nodeWeapon);
	local clauses = CharWeaponManager.getDamageClauses(nodeChar, nodeWeapon, sBaseAbility);
	for _,v in ipairs(clauses) do
		if (#(v.dice) > 0) or (v.modifier ~= 0) then
			local sDamage = StringManager.convertDiceToString(v.dice, v.modifier);
			if (v.dmgtype or "") ~= "" then
				sDamage = sDamage .. " " .. v.dmgtype;
			end
			table.insert(aDamage, sDamage);
		end
	end
	return table.concat(aDamage, "\n");
end

-- Added
function getAttackBonus(nodeChar, nodeWeapon)
	-- Debug.chat("FN: getAttackBonus in manager_char_weapon")
	local sAbility = DB.getValue(nodeWeapon, "atk_stat", 0)
	local sSkill = StringManager.simplify(DB.getValue(nodeWeapon, "atk_skill", ""))
	local nStat = ActorManager5E.getAbilityScore(nodeChar, sAbility)
	local nSkill = ActorManager5E.getSkillRank(nodeChar, sSkill)
	local nTraining = DB.getValue(nodeWeapon, "wpn_training", 0)
	local nBonus = DB.getValue(nodeWeapon, "atk_bonus", 0)
	local nPenalty = 0

	-- Calculate Bonus dice after Training
	if nTraining > nSkill then
		nPenalty = nTraining - nSkill
		nSkill = 0
	else
		nSkill = nSkill - nTraining
	end

	return nStat, nSkill, nPenalty, nBonus, sAbility, sSkill
end

-- Added
-- ToDo Check against checkProperty
function getPropertyValue(v, sTargetProperty)
	-- Debug.chat("FN: getPropertyValue in manager_char_weapon")
	local sQualities
	local sVarType = type(v)

	if sVarType == "databasenode" then
		sQualities = DB.getValue(v, "wpn_qualities", "")
	elseif sVarType == "string" then
		sQualities = v
	else
		return nil
	end

	-- Get rid of some problem characters, and make lowercase
	sTargetProperty = sTargetProperty:gsub("’", "'")
	sTargetProperty = sTargetProperty:gsub("%-", "")
	sTargetProperty = sTargetProperty:lower()

	local tProps = StringManager.split(sQualities:lower(), ",", true)

	for _, s in ipairs(tProps) do
		s = s:gsub("%-", "")
		local result = s:match("^" .. sTargetProperty)
		if result then
			s = s:gsub("%a+", "")
			return tonumber(s)
		end
	end

	return nil
end