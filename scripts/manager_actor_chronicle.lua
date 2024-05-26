-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- NOTE: Non-land vehicles are also immune to "prone" by default
VEHICLE_TYPE_LAND = "land";
tStandardVehicleConditionImmunities = { "blinded", "charmed", "deafened", "frightened", "intoxicated", "paralyzed", "petrified", "poisoned", "stunned", "unconscious" };
tStandardVehicleDamageImmunities = { "poison", "psychic" };

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	initActorHealth();
end

-- ===================================================================================================================
--	HEALTH
-- ===================================================================================================================
function initActorHealth()
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_UNCONSCIOUS, ColorManager.COLOR_HEALTH_DYING_OR_DEAD);

	-- Replacing CoreRPG function with new function
	ActorHealthManager.getWoundPercent = getWoundPercent;
end

-- ===================================================================================================================
-- NOTE: Always default to using CT node as primary to make sure 
--		that all bars and statuses are synchronized in combat tracker
--		(Cross-link network updates between PC and CT fields can occur in either order, 
--		depending on where the scripts or end user updates.)
-- NOTE 2: We can not use default effect checking in this function;
-- 		as it will cause endless loop with conditionals that check health
-- Adjusted
-- ===================================================================================================================
function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	local nHP = 0;
	local nWounds = 0;

	local nodeCT = ActorManager.getCTNode(rActor);

	if nodeCT then
		nHP = math.max(DB.getValue(nodeCT, "hp.total", 0), 0);
		nWounds = math.max(DB.getValue(nodeCT, "hp.wounds", 0), 0);
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0);
			nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0);
		end
	end

	local nPercentWounded = 0;

	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end

	-- ToDo: Wounds and Injuries and status "Defeated"
	local sStatus;
	if nPercentWounded >= 1 then
		-- ToDo: Use proper string management
		sStatus = "Defeated";
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentWounded);
	end
	
	return nPercentWounded, sStatus;
end

-- ===================================================================================================================
-- Set color for damage
-- ===================================================================================================================
function getPCSheetWoundColor(nodePC)
	local nHP = 0;
	local nWounds = 0;

	if nodePC then
		nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0);
		nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0);
	end

	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sColor = ColorManager.getHealthColor(nPercentWounded, false);
	return sColor;
end

-- ===================================================================================================================
--	ABILITY SCORES
-- ===================================================================================================================
-- ToDo: Adjust
function getAbilityEffectsBonus(rActor, sAbility)
	if not rActor or ((sAbility or "") == "") then
		return 0, 0;
	end
	
	local bNegativeOnly = (sAbility:sub(1,1) == "-");
	if bNegativeOnly then
		sAbility = sAbility:sub(2);
	end

	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	if not sAbilityEffect then
		return 0, 0;
	end
	
	local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
	
	local nAbilityScore = ActorManager5E.getAbilityScore(rActor, sAbility);
	if nAbilityScore > 0 then
		local nAffectedScore = math.max(nAbilityScore + nAbilityMod, 0);
		
		local nCurrentBonus = math.floor((nAbilityScore - 10) / 2);
		local nAffectedBonus = math.floor((nAffectedScore - 10) / 2);
		
		nAbilityMod = nAffectedBonus - nCurrentBonus;
	else
		if nAbilityMod > 0 then
			nAbilityMod = math.floor(nAbilityMod / 2);
		else
			nAbilityMod = math.ceil(nAbilityMod / 2);
		end
	end

	if bNegativeOnly and (nAbilityMod > 0) then
		nAbilityMod = 0;
	end

	return nAbilityMod, nAbilityEffects;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getClassLevel(nodeActor, sValue)
	local sClassName = DataCommon.class_valuetoname[sValue];
	if not sClassName then
		return 0;
	end
	sClassName = sClassName:lower();
	
	for _, vNode in ipairs(DB.getChildList(nodeActor, "classes")) do
		if DB.getValue(vNode, "name", ""):lower() == sClassName then
			return DB.getValue(vNode, "level", 0);
		end
	end
	
	return 0;
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getAbilityScore(rActor, sAbility)
	-- Return -1 if no Ability was handed over
	if not sAbility then
		return -1;
	end

	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor);

	-- Return -1 if Actor was not defined
	if not nodeActor then
		return -1;
	end

	local nStatScore = -1;

	-- Convert input to lower case and removing all spaces from the string
	sAbility = StringManager.simplify(sAbility)

	-- Get Ability score
	nStatScore = DB.getValue(nodeActor, "abilities." .. sAbility .. ".score", 0);

	return nStatScore
end

-- ===================================================================================================================
-- ===================================================================================================================
function getAbilityBonus(rActor, sAbility)
	if (sAbility or "") == "" then
		return 0;
	end
	if not rActor then
		return 0;
	end

	local bNegativeOnly = (sAbility:sub(1,1) == "-");
	if bNegativeOnly then
		sAbility = sAbility:sub(2);
	end
	
	local nStatScore = ActorManager5E.getAbilityScore(rActor, sAbility);
	if nStatScore < 0 then
		return 0;
	end
	
	local nStatVal = 0;
	if StringManager.contains(DataCommon.abilities, sAbility) then
		nStatVal = math.floor((nStatScore - 10) / 2);
	else
		nStatVal = nStatScore;
	end

	if bNegativeOnly and nStatVal > 0 then
		nStatVal = 0;
	end
	
	return nStatVal;
end

-- ===================================================================================================================
--	DEFENSES
-- ===================================================================================================================
function getSave(rActor, sSave)
	local bADV = false;
	local bDIS = false;
	local nValue = ActorManager5E.getAbilityBonus(rActor, sSave);
	local aAddText = {};
	
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0, false, false, "";
	end

	if ActorManager.isPC(rActor) then
		nValue = nValue + DB.getValue(nodeActor, "abilities." .. sSave .. ".savemodifier", 0);

		-- Check for saving throw proficiency
		if DB.getValue(nodeActor, "abilities." .. sSave .. ".saveprof", 0) == 1 then
			nValue = nValue + DB.getValue(nodeActor, "profbonus", 0);
		end

		-- Check for armor non-proficiency
		if StringManager.contains({"strength", "dexterity"}, sSave) then
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				table.insert(aAddText, Interface.getString("roll_msg_armor_nonprof"));
				bDIS = true;
			end
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		local sSaves = DB.getValue(nodeActor, "savingthrows", "");
		for _,v in ipairs(StringManager.split(sSaves, ",;\r\n", true)) do
			local sAbility, sSign, sMod = v:match("(%w+)%s*([%+%-–]?)(%d+)");
			if sAbility then
				if DataCommon.ability_stol[sAbility:upper()] then
					sAbility = DataCommon.ability_stol[sAbility:upper()];
				elseif DataCommon.ability_ltos[sAbility:lower()] then
					sAbility = sAbility:lower();
				else
					sAbility = nil;
				end
				
				if sAbility == sSave then
					nValue = tonumber(sMod) or 0;
					if sSign == "-" or sSign == "–" then
						nValue = 0 - nValue;
					end
					break;
				end
			end
		end
	end
	
	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

-- ===================================================================================================================
-- ===================================================================================================================
function getCheck(rActor, sCheck, sSkill)
	local bADV = false;
	local bDIS = false;
	local nValue = ActorManager5E.getAbilityBonus(rActor, sCheck);
	local aAddText = {};

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0, false, false, "";
	end

	if ActorManager.isPC(rActor) then
		nValue = nValue + DB.getValue(nodeActor, "abilities." .. sCheck .. ".checkmodifier", 0);

		-- Check for armor non-proficiency
		if StringManager.contains({"strength", "dexterity"}, sCheck) then
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				table.insert(aAddText, Interface.getString("roll_msg_armor_nonprof"));
				bDIS = true;
			end
		end
		
		-- Check for armor stealth disadvantage
		if sSkill and sSkill:lower() == Interface.getString("skill_value_stealth"):lower() then
			if DB.getValue(nodeActor, "defenses.ac.disstealth", 0) == 1 then
				table.insert(aAddText, Interface.getString("roll_msg_armor_disstealth"));
				bDIS = true;
			end
		end
	end
	
	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDefenseAdvantage(rAttacker, rDefender, aAttackFilter)
	if not rDefender then
		return false, false;
	end
	
	-- Check effects
	local bADV = false;
	local bDIS = false;
	local bProne = false;
	
	if ActorManager.hasCT(rDefender) then
		if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "ADVATK", aAttackFilter, rDefender, true)) > 0 then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "DISATK", aAttackFilter, rDefender, true)) > 0 then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAttacker) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTADVATK", aAttackFilter, rAttacker)) > 0 then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAttacker) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTDISATK", aAttackFilter, rAttacker)) > 0 then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Blinded", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			bDIS = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
			bADV = true;
		end
		if EffectManager.hasCondition(rDefender, "Prone") then
			bProne = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
			bADV = true;
		end
		if EffectManager.hasCondition(rDefender, "Unconscious") then
			bADV = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Dodge", rAttacker) and 
				not (EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Incapacitated", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Grappled", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker)) then
			bDIS = true;
		end
		
		if bProne then
			if StringManager.contains(aAttackFilter, "melee") then
				bADV = true;
			elseif StringManager.contains(aAttackFilter, "ranged") then
				bDIS = true;
			end
		end
	end
	-- if bProne then
		-- local nodeAttacker = ActorManager.getCTNode(rAttacker);
		-- local nodeDefender = ActorManager.getCTNode(rDefender);
		-- if nodeAttacker and nodeDefender then
			-- local tokenAttacker = CombatManager.getTokenFromCT(nodeAttacker);
			-- local tokenDefender = CombatManager.getTokenFromCT(nodeDefender);
			-- if tokenAttacker and tokenDefender then
				-- local nodeAttackerContainer = tokenAttacker.getContainerNode();
				-- local nodeDefenderContainer = tokenDefender.getContainerNode();
				-- if DB.getPath(nodeAttackerContainer) == DB.getPath(nodeDefenderContainer) then
					-- local nDU = GameSystem.getDistanceUnitsPerGrid();
					-- local nAttackerSpace = math.ceil(DB.getValue(nodeAttacker, "space", nDU) / nDU);
					-- local nDefenderSpace = math.ceil(DB.getValue(nodeDefender, "space", nDU) / nDU);
					-- local xAttacker, yAttacker = tokenAttacker.getPosition();
					-- local xDefender, yDefender = tokenDefender.getPosition();
					-- local nGrid = nodeAttackerContainer.getGridSize();
					
					-- local xDiff = math.abs(xAttacker - xDefender);
					-- local yDiff = math.abs(yAttacker - yDefender);
					-- local gx = math.floor(xDiff / nGrid);
					-- local gy = math.floor(yDiff / nGrid);
					
					-- local nSquares = 0;
					-- local nStraights = 0;
					-- if gx > gy then
						-- nSquares = nSquares + gy;
						-- nSquares = nSquares + gx - gy;
					-- else
						-- nSquares = nSquares + gx;
						-- nSquares = nSquares + gy - gx;
					-- end
					-- nSquares = nSquares - (nAttackerSpace / 2);
					-- nSquares = nSquares - (nDefenderSpace / 2);
					-- -- DEBUG - FINISH - Need to be able to get grid type and grid size from token container node
				-- end
			-- end
		-- end
	-- end

	return bADV, bDIS;
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getDefenseValue(rAttacker, rDefender, rRoll)
	if not rDefender or not rRoll then
		return nil, 0, 0, false, false;
	end
	
	-- Base calculations
	local sAttack = rRoll.sDesc;
	
	local sAttackType = sAttack:match("%[ATTACK.*%((%w+)%)%]");
	local bOpportunity = sAttack:match("%[OPPORTUNITY%]");
	local nCover = tonumber(sAttack:match("%[COVER %-(%d)%]")) or 0;

	local nDefense = 0;
	local nodeDefender = ActorManager.getCreatureNode(rDefender)

	-- Exits if no defender was provided
	local sDefenderNodeType, nodeDefender = ActorManager.getTypeAndNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, false, false;
	end

	-- Get Combat Defense
	if sDefenderNodeType == "pc" then
		nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 0);
	elseif StringManager.contains({ "ct", "npc", "vehicle" }, sDefenderNodeType) then
		nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 0);
	else
		return nil, 0, 0, false, false;
	end

	-- Effects
	local nDefenseEffectMod = 0;

	if ActorManager.hasCT(rDefender) then
		local nBonusAC = 0;
		local nBonusStat = 0;
		local nBonusSituational = 0;
		
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end

		local aACEffects, nACEffectCount = EffectManager5E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
		for _,v in pairs(aACEffects) do
			nBonusAC = nBonusAC + v.mod;
		end
		
		nBonusStat = ActorManager5E.getAbilityEffectsBonus(rDefender, sDefenseStat);
		
		local bProne = false;
		if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAtracker) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAtracker) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
			-- Placeholder
		end
		if EffectManager.hasCondition(rDefender, "Prone") then
			bProne = true
		end
		if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
			-- Placeholder
		end
		if EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) then
			-- Placeholder
		end

		-- ToDo: Check this
		if nCover < 5 then
			local aCover = EffectManager5E.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
			if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "SCOVER", rAttacker) then
				nBonusSituational = nBonusSituational + 5 - nCover;
			elseif nCover < 2 then
				aCover = EffectManager5E.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
				if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "COVER", rAttacker) then
					nBonusSituational = nBonusSituational + 2 - nCover;
				end
			end
		end
		
		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
	end
	
	-- Results
	return nDefense, 0, nDefenseEffectMod;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageThreshold(rActor)
	local nResult = 0;

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			local nActorDT = DB.getValue(nodeActor, "damagethreshold", 0);
			nResult = math.max(nResult, nActorDT);
		end
	end

	local tEffects = EffectManager5E.getEffectsByType(rActor, "DT");
	for _,v in pairs(tEffects) do
		nResult = math.max(nResult, v.mod);
	end

	return nResult;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getMishapThreshold(rActor)
	local nResult = 0;

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "vehicle") then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			local nActorMT = DB.getValue(nodeActor, "mishapthreshold", 0);
			nResult = math.max(nResult, nActorMT);
		end
	end

	return nResult;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageVulnerabilities(rActor, rSource)
	local tResults = {};

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		tResults = ActorManager5E.parseDamageVulnResistImmuneHelper(rActor, "damagevulnerabilities");
	end

	local tEffectResults = ActorManager5E.getDamageVulnResistImmuneEffectHelper(rActor, "VULN", rSource);
	for k,v in pairs(tEffectResults) do
		tResults[k] = v;
	end

	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageResistances(rActor, rSource)
	local tResults = {};

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		tResults = ActorManager5E.parseDamageVulnResistImmuneHelper(rActor, "damageresistances");
	end

	local tEffectResults = ActorManager5E.getDamageVulnResistImmuneEffectHelper(rActor, "RESIST", rSource);
	for k,v in pairs(tEffectResults) do
		tResults[k] = v;
	end

	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageImmunities(rActor, rSource)
	local tResults = {};

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		tResults = ActorManager5E.parseDamageVulnResistImmuneHelper(rActor, "damageimmunities");

		if sRecordType == "vehicle" then
			local nodeActor = ActorManager.getCreatureNode(rActor);
			if nodeActor then
				if (DB.getValue(nodeActor, "disablestandarddamageimmunities", 0) == 0) then
					for _,v in ipairs(ActorManager5E.tStandardVehicleDamageImmunities) do
						tResults[v] = { mod = 0, aNegatives = {} };
					end
				end
			end
		end
	end

	local tEffectResults = ActorManager5E.getDamageVulnResistImmuneEffectHelper(rActor, "IMMUNE", rSource);
	for k,v in pairs(tEffectResults) do
		tResults[k] = v;
	end

	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function parseDamageVulnResistImmuneHelper(rActor, sField)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return {};
	end

	local tResults = {};

	local s = DB.getValue(nodeActor, sField, ""):lower();
	for _,v in ipairs(StringManager.split(s, ";\r\n", true)) do
		local tResistTypes = {};
		local tNegationTypes = {};
		
		for _,v2 in ipairs(StringManager.split(v, ",", true)) do
			if StringManager.isWord(v2, DataCommon.dmgtypes) then
				table.insert(tResistTypes, v2);
			else
				local aResistWords = StringManager.parseWords(v2);
				
				local i = 1;
				while aResistWords[i] do
					if StringManager.isWord(aResistWords[i], DataCommon.dmgtypes) then
						table.insert(tResistTypes, aResistWords[i]);
					elseif StringManager.isWord(aResistWords[i], "cold-forged") and StringManager.isWord(aResistWords[i+1], "iron") then
						i = i + 1;
						table.insert(tResistTypes, "cold-forged iron");
					elseif StringManager.isWord(aResistWords[i], "from") and StringManager.isWord(aResistWords[i+1], "nonmagical") and StringManager.isWord(aResistWords[i+2], { "weapons", "attacks" }) then
						i = i + 2;
						table.insert(tNegationTypes, "magic");
					elseif StringManager.isWord(aResistWords[i], "that") and StringManager.isWord(aResistWords[i+1], "is") and StringManager.isWord(aResistWords[i+2], "nonmagical") then
						i = i + 2;
						table.insert(tNegationTypes, "magic");
					elseif StringManager.isWord(aResistWords[i], "that") and StringManager.isWord(aResistWords[i+1], "aren't") then
						i = i + 2;
						
						if StringManager.isWord(aResistWords[i], "silvered") then
							table.insert(tNegationTypes, "silver");
						elseif StringManager.isWord(aResistWords[i], "adamantine") then
							table.insert(tNegationTypes, "adamantine");
						elseif StringManager.isWord(aResistWords[i], "cold-forged") and StringManager.isWord(aResistWords[i+1], "iron") then
							i = i + 1;
							table.insert(tNegationTypes, "cold-forged iron");
						end
					end
					
					i = i + 1;
				end
			end
		end

		if #tResistTypes > 0 then
			for _,v in ipairs(tResistTypes) do
				tResults[v] = { mod = 0, aNegatives = tNegationTypes };
			end
		end
	end
	
	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageVulnResistImmuneEffectHelper(rActor, sEffectType, rSource)
	local tResults = {};

	local aEffects = EffectManager5E.getEffectsByType(rActor, sEffectType, {}, rSource);
	for _,v in pairs(aEffects) do
		local r = {};
		
		r.mod = v.mod;
		r.aNegatives = {};
		for _,vType in pairs(v.remainder) do
			if #vType > 1 and ((vType:sub(1,1) == "!") or (vType:sub(1,1) == "~")) then
				if StringManager.contains(DataCommon.dmgtypes, vType:sub(2)) then
					table.insert(r.aNegatives, vType:sub(2));
				end
			end
		end

		for _,vType in pairs(v.remainder) do
			if vType ~= "untyped" and vType ~= "" and vType:sub(1,1) ~= "!" and vType:sub(1,1) ~= "~" then
				if StringManager.contains(DataCommon.dmgtypes, vType) or vType == "all" then
					tResults[vType] = r;
				end
			end
		end
	end

	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getConditionImmunities(rActor, rSource)
	local tResults = {};

	local sActorType = ActorManager.getRecordType(rActor);
	if (sActorType == "npc") or (sActorType == "vehicle") then
		local tActorImmune = ActorManager5E.getNonPCActorConditionImmunitiesHelper(rActor);
		for _,v in ipairs(tActorImmune) do
			table.insert(tResults, v);
		end
	end


	local tImmuneEffects = EffectManager5E.getEffectsByType(rActor, "IMMUNE", {}, rSource);
	for _,v in pairs(tImmuneEffects) do
		for _,v in pairs(v.remainder) do
			local vLower = v:lower();
			if StringManager.contains(DataCommon.conditions, vLower) then
				table.insert(tResults, vLower);
			end
		end
	end

	return tResults;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getNonPCActorConditionImmunitiesHelper(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return {};
	end

	local tResults = {};

	local sActorImmune = DB.getValue(nodeActor, "conditionimmunities", ""):lower();
	local tActorImmuneWords = StringManager.split(sActorImmune, ",", true);
	for _,v in ipairs(tActorImmuneWords) do
		local vLower = v:lower();
		if StringManager.contains(DataCommon.conditions, vLower) then
			table.insert(tResults, vLower);
		end
	end

	if ActorManager.isRecordType(rActor, "vehicle") then
		if (DB.getValue(nodeActor, "disablestandardconditionimmunities", 0) == 0) then
			for _,v in ipairs(ActorManager5E.tStandardVehicleConditionImmunities) do
				table.insert(tResults, v);
			end
			local sType = StringManager.trim(DB.getValue(nodeActor, "type", "")):lower();
			if sType ~= ActorManager5E.VEHICLE_TYPE_LAND then
				table.insert(tResults, "prone");
			end
		end
	end

	return tResults;
end

-- ===================================================================================================================
-- Added
-- ===================================================================================================================
function getArmorPenalty(rActor)
	local nAP = 0

	-- Determine DB nodes
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)

	-- Return 0 if Actor was not defined
	if not nodeActor then
		return 0
	end

	-- Get Armor Penalty
	nAP = DB.getValue(nodeActor, "defenses.armor.penalty", 0)

	return nAP
end

-- ===================================================================================================================
-- Added
-- ===================================================================================================================
function getHealthFatigue(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	-- Get number of Fatigue
	local nInjuries = DB.getValue(nodeActor, "hp.fatigue", 0)

	return nInjuries
end

-- ===================================================================================================================
-- Added
-- ===================================================================================================================
function getHealthInjuries(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
							   
		return -1
	end

	-- Get number of Injuries
	local nInjuries = DB.getValue(nodeActor, "hp.injuries", 0)

	return nInjuries
end

-- ===================================================================================================================
-- Added
-- ===================================================================================================================
function getHealthTrauma(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	-- Get number of Trauma
	local nTrauma = DB.getValue(nodeActor, "hp.trauma", 0)

	return nTrauma
end

-- ===================================================================================================================
-- Added
-- ===================================================================================================================
function getSkillRank(rActor, sSkill)
	local nodeActor = ActorManager.getCreatureNode(rActor)
	local nSkillRank = -1
	local nodeSkill = nil

	if not sSkill or sSkill == "-" or sSkill == "None" then return -1 end;
	if not nodeActor then return -1 end;

	-- Convert input to lower case and removing all spaces from the string
	sSkill = StringManager.simplify(sSkill)

	-- Get Skill node
	for _, vSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
		if StringManager.simplify(DB.getValue(vSkill, "name", "")) == sSkill then
			nodeSkill = vSkill
			break
		end
	end

	-- Avoid a timing issue where on the CT the name of a Skill is not yet set in the DB and we end up in nodeSkill == nil
	if nodeSkill == nil then
		for _, vSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
			nodeSkill = vSkill
			break
		end
	end

	-- Get Skill rank saved as "misc"
	nSkillRank = DB.getValue(nodeSkill, "misc", 0)

	return nSkillRank
end