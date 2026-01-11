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
		sName = "** " .. sName .. " **";
	end
	local nBonus = 0;
	if nItemID == 1 then
		nBonus = DB.getValue(nodeItem, "bonus", 0);
	end

	-- Handle special weapon properties
	local sProps = DB.getValue(nodeItem, "properties", "");
	local sMastery = DB.getValue(nodeItem, "mastery", "");

	local bThrown = CharWeaponManager.checkProperty(sProps, CharWeaponManager.WEAPON_PROP_THROWN);
	local bMagic = CharWeaponManager.checkProperty(sProps, CharWeaponManager.WEAPON_PROP_MAGIC);

	local sType = DB.getValue(nodeItem, "subtype", ""):lower();
	local bMelee = true;
	local bRanged = false;
	if sType:find(CharWeaponManager.WEAPON_TYPE_RANGED) then
		bMelee = false;
		bRanged = true;
	end

	-- Parse damage field
	local sDamage = DB.getValue(nodeItem, "damage", "");

	local aDmgClauses = {};
	local aWords = StringManager.parseWords(sDamage:lower());
	local i = 1;
	while aWords[i] do
		local aDiceString = {};

		while StringManager.isDiceString(aWords[i]) do
			table.insert(aDiceString, aWords[i]);
			i = i + 1;
		end
		if #aDiceString == 0 then
			break;
		end

		local aDamageTypes = {};
		while StringManager.contains(DataCommon.dmgtypes, aWords[i]) do
			table.insert(aDamageTypes, aWords[i]);
			i = i + 1;
		end
		if bMagic then
			table.insert(aDamageTypes, "magic");
		end

		local rDmgClause = {};
		rDmgClause.aDice, rDmgClause.nMod = StringManager.convertStringToDice(table.concat(aDiceString, " "));
		rDmgClause.dmgtype = table.concat(aDamageTypes, ",");
		table.insert(aDmgClauses, rDmgClause);

		if StringManager.contains({ "+", "plus" }, aWords[i]) then
			i = i + 1;
		end
	end

	-- Create weapon entries
	if bMelee then
		local nodeWeapon = DB.createChild(nodeWeapons);
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. DB.getName(nodeItem));

			local sAttackAbility = "";
			local sDamageAbility = "base";

			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 0);
			DB.setValue(nodeWeapon, "properties", "string", sProps);
			DB.setValue(nodeWeapon, "mastery", "string", sMastery);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
	end

	if bRanged and not bThrown then
		local nodeWeapon = DB.createChild(nodeWeapons);
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. DB.getName(nodeItem));

			local sAttackAbility = "";
			local sDamageAbility = "base";

			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 1);
			DB.setValue(nodeWeapon, "properties", "string", sProps);
			DB.setValue(nodeWeapon, "mastery", "string", sMastery);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
	end

	if bThrown then
		local nodeWeapon = DB.createChild(nodeWeapons);
		if nodeWeapon then
			DB.setValue(nodeWeapon, "isidentified", "number", nItemID);
			DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", "....inventorylist." .. DB.getName(nodeItem));

			local sAttackAbility = "";
			local sDamageAbility = "base";

			DB.setValue(nodeWeapon, "name", "string", sName);
			DB.setValue(nodeWeapon, "type", "number", 2);
			DB.setValue(nodeWeapon, "properties", "string", sProps);
			DB.setValue(nodeWeapon, "mastery", "string", sMastery);

			DB.setValue(nodeWeapon, "attackstat", "string", sAttackAbility);
			DB.setValue(nodeWeapon, "attackbonus", "number", nBonus);

			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				for kClause,rClause in ipairs(aDmgClauses) do
					local nodeDmg = DB.createChild(nodeDmgList);
					if nodeDmg then
						DB.setValue(nodeDmg, "dice", "dice", rClause.aDice);
						if kClause == 1 then
							DB.setValue(nodeDmg, "stat", "string", sDamageAbility);
							DB.setValue(nodeDmg, "bonus", "number", nBonus + rClause.nMod);
						else
							DB.setValue(nodeDmg, "bonus", "number", rClause.nMod);
						end
						DB.setValue(nodeDmg, "type", "string", rClause.dmgtype);
					end
				end
			end
		end
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

	if bItemID then
		DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) + DB.getValue(nodeItem, "bonus", 0));
		end
	else
		DB.setValue(nodeWeapon, "attackbonus", "number", DB.getValue(nodeWeapon, "attackbonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
		if #aDamageNodes > 0 then
			DB.setValue(aDamageNodes[1], "bonus", "number", DB.getValue(aDamageNodes[1], "bonus", 0) - DB.getValue(nodeItem, "bonus", 0));
		end
	end

	if bItemID then
		DB.setValue(nodeWeapon, "isidentified", "number", 1);
	else
		DB.setValue(nodeWeapon, "isidentified", "number", 0);
	end
end

--
--	Property helpers
--

function getRange(_, nodeWeapon)
	local nType = DB.getValue(nodeWeapon, "type", 0);
	if (nType == 1) or (nType == 2) then
		return "R";
	end
	return "M";
end

function getCritRange(nodeChar, nodeWeapon)
	local nCritThreshold;
	if CharWeaponManager.getRange(nodeChar, nodeWeapon) == "R" then
		nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.ranged", 20);
	else
		nCritThreshold = DB.getValue(nodeChar, "weapon.critrange.melee", 20);
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
		sProperties = DB.getValue(v, "properties", "");
	elseif sVarType == "string" then
		sProperties = v;
	else
		return nil;
	end

	local tProps = StringManager.split(sProperties:lower(), ",", true);
	for _,s in ipairs(tProps) do
		if s:match("^" .. sTargetProperty) then
			return true;
		end
	end
	return false;
end

function getProperty(v, sTargetPattern)
	local sProperties;
	local sVarType = type(v);
	if sVarType == "databasenode" then
		sProperties = DB.getValue(v, "properties", "");
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

function getAttackAbility(nodeChar, nodeWeapon)
	local sAbility = DB.getValue(nodeWeapon, "attackstat", "");
	if sAbility ~= "" then
		return sAbility;
	end

	local nType = DB.getValue(nodeWeapon, "type", 0);
	if nType == 1 then -- Ranged
		return "dexterity";
	end

	-- Melee or Thrown
	local bFinesse = CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE);
	if bFinesse then
		local nSTR = ActorManager5E.getAbilityBonus(nodeChar, "strength");
		local nDEX = ActorManager5E.getAbilityBonus(nodeChar, "dexterity");
		if nDEX > nSTR then
			return "dexterity";
		end
	end

	return "strength";
end

function getAttackBonus(nodeChar, nodeWeapon)
	local sAbility = CharWeaponManager.getAttackAbility(nodeChar, nodeWeapon);

	local nMod = DB.getValue(nodeWeapon, "attackbonus", 0);
	nMod = nMod + ActorManager5E.getAbilityBonus(nodeChar, sAbility);
	if DB.getValue(nodeWeapon, "prof", 1) == 1 then
		nMod = nMod + DB.getValue(nodeChar, "profbonus", 2);
	end

	return nMod, sAbility;
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

function buildAttackAction(nodeChar, nodeWeapon)
	local rAction = {
		bWeapon = true,
		label = DB.getValue(nodeWeapon, "name", ""),
		range = CharWeaponManager.getRange(nodeChar, nodeWeapon),
		tAddText = {},
	};

	rAction.modifier, rAction.stat = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);

	local nCritThreshold = CharWeaponManager.getCritRange(nodeChar, nodeWeapon);
	if nCritThreshold > 1 and nCritThreshold < 20 then
		rAction.nCritRange = nCritThreshold;
	end

	if (DB.getValue(nodeWeapon, "type", 0) == 1) and CharManager.hasFeat2024(nodeChar, CharManager.FEAT_ARCHERY) then
		rAction.modifier = (rAction.modifier or 0) + 2;
		table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_archery")));
	end

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

function getDamageBaseAbility(nodeChar, nodeWeapon)
	-- Use ability based on type
	local sAbility;
	local nWeaponType = DB.getValue(nodeWeapon, "type", 0);
	-- Ranged
	if nWeaponType == 1 then
		sAbility = "dexterity";
	-- Melee or Thrown
	else
		sAbility = "strength";

		local bFinesse = CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_FINESSE);
		if bFinesse then
			local nSTR = ActorManager5E.getAbilityBonus(nodeChar, "strength");
			local nDEX = ActorManager5E.getAbilityBonus(nodeChar, "dexterity");
			if nDEX > nSTR then
				sAbility = "dexterity";
			end
		end
	end

	-- However, if off-hand without two-weapon fighting, only use negative ability
	if (DB.getValue(nodeWeapon, "handling", 0) == 2) then
		local bTwoWeaponStyle = (DB.getValue(nodeChar, "weapon.twoweaponfighting", 0) == 1) or CharManager.hasFeat2024(nodeChar, CharManager.FEAT_TWO_WEAPON_FIGHTING);
		if not bTwoWeaponStyle then
			sAbility = "-" .. sAbility;
		end
	end

	return sAbility;
end

function getDamageClauses(nodeChar, nodeWeapon, sBaseAbility, nReroll)
	local clauses = {};

	-- Check for versatile property and two-handed usage
	local sVersatile = nil;
	local nWeaponHands = DB.getValue(nodeWeapon, "handling", 0);
	if nWeaponHands == 1 then
		sVersatile = CharWeaponManager.getProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_VERSATILE);
	end

	-- Iterate over database nodes in order they are displayed
	local rActor = ActorManager.resolveActor(nodeChar);
	local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeWeapon, "damagelist");
	for _,v in ipairs(aDamageNodes) do
		-- Build basic damage clause information
		local sDmgAbility = DB.getValue(v, "stat", "");
		if sDmgAbility == "base" then
			sDmgAbility = sBaseAbility;
		end
		local nAbilityBonus = ActorManager5E.getAbilityBonus(rActor, sDmgAbility);
		local nMult = DB.getValue(v, "statmult", 1);
		if nAbilityBonus > 0 and nMult ~= 1 then
			nAbilityBonus = math.floor(nMult * nAbilityBonus);
		end
		local aDmgDice = DB.getValue(v, "dice", {});
		local nDmgMod = nAbilityBonus + DB.getValue(v, "bonus", 0);
		local sDmgType = DB.getValue(v, "type", "");

		-- Handle versatile value, if any
		if sVersatile and #aDmgDice > 0 then
			aDmgDice[1] = sVersatile;
			sVersatile = nil;
		end

		-- Handle reroll value, if any
		local aDmgReroll = nil;
		if nReroll then
			aDmgReroll = {};
			for kDie,_ in ipairs(aDmgDice) do
				aDmgReroll[kDie] = nReroll;
			end
		end

		-- Add clause to list of clauses
		table.insert(clauses, { dice = aDmgDice, stat = sDmgAbility, statmult = nMult, modifier = nDmgMod, dmgtype = sDmgType, reroll = aDmgReroll });
	end

	return clauses;
end

function buildDamageAction(nodeChar, nodeWeapon)
	local rAction = {
		bWeapon = true,
		label = DB.getValue(nodeWeapon, "name", ""),
		tAddText = {},
	};

	local nWeaponHands = DB.getValue(nodeWeapon, "handling", 0);
	if nWeaponHands == 1 then
		rAction.label = rAction.label .. " (2H)";
	elseif nWeaponHands == 2 then
		rAction.label = rAction.label .. " (OH)";
	end
	rAction.range = CharWeaponManager.getRange(nodeChar, nodeWeapon);

	-- Check for reroll property
	local nPropReroll = CharWeaponManager.getPropertyNumber(nodeWeapon, CharWeaponManager.WEAPON_PROP_REROLL);
	if nPropReroll and (nPropReroll > 0) then
		rAction.nReroll = nPropReroll;
	end

	-- Build damage clauses
	local sBaseAbility = CharWeaponManager.getDamageBaseAbility(nodeChar, nodeWeapon);
	rAction.clauses = CharWeaponManager.getDamageClauses(nodeChar, nodeWeapon, sBaseAbility, rAction.nReroll);

	if (DB.getValue(nodeWeapon, "type", 0) == 2) then
		if rAction.clauses[1] and CharManager.hasFeat2024(nodeChar, CharManager.FEAT_THROWN_WEAPON_FIGHTING) then
			rAction.clauses[1].modifier = (rAction.clauses[1].modifier or 0) + 2;
			table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_thrownweaponfighting")));
		end
	elseif (DB.getValue(nodeWeapon, "type", 0) == 0) then
		if rAction.clauses[1] and CharManager.hasFeat2024(nodeChar, CharManager.FEAT_DUELING) then
			if DB.getValue(nodeWeapon, "handling", 0) == 0 then
				local bOtherWeaponEquipped = false;
				local _,sRecord = DB.getValue(nodeWeapon, "shortcut", "", "");
				for _,nodeOther in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
					if (nodeOther ~= nodeWeapon) and (DB.getValue(nodeOther, "carried", 0) == 2) then
						local _,sRecordOther = DB.getValue(nodeOther, "shortcut", "", "");
						if ((sRecordOther or "") == "") or (sRecordOther ~= sRecord) then
							bOtherWeaponEquipped = true;
							break;
						end
					end
				end
				if not bOtherWeaponEquipped then
					rAction.clauses[1].modifier = (rAction.clauses[1].modifier or 0) + 2;
					table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_dueling")));
				end
			end
		end
		if CharManager.hasFeat2024(nodeChar, CharManager.FEAT_GREAT_WEAPON_FIGHTING) then
			if CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_TWOHANDED) or CharWeaponManager.checkProperty(nodeWeapon, CharWeaponManager.WEAPON_PROP_VERSATILE) then
				table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_greatweaponfighting")));
				local nWeaponDice = 0;
				for _,tClause in ipairs(rAction.clauses) do
					nWeaponDice = nWeaponDice + #(tClause.dice or {});
				end
				table.insert(rAction.tAddText, string.format("[MIN 3 %dD]", nWeaponDice));
			end
		end
	end

	if (DB.getValue(nodeWeapon, "handling", 0) == 2) then
		local bTwoWeaponStyle = (DB.getValue(nodeChar, "weapon.twoweaponfighting", 0) == 1) or CharManager.hasFeat2024(nodeChar, CharManager.FEAT_TWO_WEAPON_FIGHTING);
		if bTwoWeaponStyle then
			table.insert(rAction.tAddText, string.format("[%s]", Interface.getString("roll_msg_feat_twoweaponfighting")));
		end
	end
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
