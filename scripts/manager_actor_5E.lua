--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- NOTE: Non-land vehicles are also immune to "prone" by default
VEHICLE_TYPE_LAND = "land";
tStandardVehicleConditionImmunities = { "blinded", "charmed", "deafened", "frightened", "intoxicated", "paralyzed", "petrified", "poisoned", "stunned", "unconscious" };
tStandardVehicleDamageImmunities = { "poison", "psychic" };

function onInit()
	ActorManager5E.initActorHealth();
end

--
--	HEALTH
--

function initActorHealth()
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_UNCONSCIOUS, ColorManager.getUIColor("health_dyingordead"));

	ActorHealthManager.getWoundPercent = ActorManager5E.getWoundPercent;
end

-- NOTE: Always default to using CT node as primary to make sure
--		that all bars and statuses are synchronized in combat tracker
--		(Cross-link network updates between PC and CT fields can occur in either order,
--		depending on where the scripts or end user updates.)
-- NOTE 2: We can not use default effect checking in this function;
-- 		as it will cause endless loop with conditionals that check health
function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v);

	local nHP = 0;
	local nWounds = 0;
	local nDeathSaveFail = 0;

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		nHP = math.max(DB.getValue(nodeCT, "hptotal", 0), 0);
		nWounds = math.max(DB.getValue(nodeCT, "wounds", 0), 0);
		nDeathSaveFail = DB.getValue(nodeCT, "deathsavefail", 0);
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor);
		if nodePC then
			nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0);
			nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0);
			nDeathSaveFail = DB.getValue(nodePC, "hp.deathsavefail", 0);
		end
	end

	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end

	local sStatus;
	if nPercentWounded >= 1 then
		if nDeathSaveFail >= 3 then
			sStatus = ActorHealthManager.STATUS_DEAD;
		else
			sStatus = ActorHealthManager.STATUS_DYING;
		end
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentWounded);
	end

	return nPercentWounded, sStatus;
end

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

--
--	ABILITY SCORES
--

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
function getAbilityScore(rActor, sAbility)
	if not sAbility then
		return -1;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return -1;
	end

	local nStatScore = -1;

	local sShort = sAbility:sub(1, 3):lower();
	if sShort == "str" then
		nStatScore = DB.getValue(nodeActor, "abilities.strength.score", 0);
	elseif sShort == "dex" then
		nStatScore = DB.getValue(nodeActor, "abilities.dexterity.score", 0);
	elseif sShort == "con" then
		nStatScore = DB.getValue(nodeActor, "abilities.constitution.score", 0);
	elseif sShort == "int" then
		nStatScore = DB.getValue(nodeActor, "abilities.intelligence.score", 0);
	elseif sShort == "wis" then
		nStatScore = DB.getValue(nodeActor, "abilities.wisdom.score", 0);
	elseif sShort == "cha" then
		nStatScore = DB.getValue(nodeActor, "abilities.charisma.score", 0);
	elseif sShort == "prf" then
		if ActorManager.isPC(rActor) then
			nStatScore = DB.getValue(nodeActor, "profbonus", 2);
		elseif ActorManager.isRecordType(rActor, "npc") then
			local nCR = tonumber(DB.getValue(nodeActor, "cr", ""):match("^%d+$")) or 0;
			nStatScore = math.max(2, math.floor((nCR - 1) / 4) + 2);
		end
	elseif sShort == "lev" or sShort == "lvl" then
		if ActorManager.isPC(rActor) then
			nStatScore = DB.getValue(nodeActor, "level", 0);
		elseif ActorManager.isRecordType(rActor, "npc") then
			local sHD = StringManager.trim(DB.getValue(nodeActor, "hd", ""));
			nStatScore = 0;
			for sLevelSub in sHD:gmatch("(%d+)[dD](%d+)") do
				nStatScore = nStatScore + (tonumber(sLevelSub) or 0);
			end
		end
	elseif StringManager.contains(DataCommon.classes, sAbility) then
		nStatScore = ActorManager5E.getClassLevel(nodeActor, sAbility);
	end

	return nStatScore;
end
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

	local nStatVal;
	if StringManager.contains(DataCommon.abilities, sAbility) or DataCommon.ability_stol[sAbility:upper()] then
		nStatVal = math.floor((nStatScore - 10) / 2);
	else
		nStatVal = nStatScore;
	end

	if bNegativeOnly and nStatVal > 0 then
		nStatVal = 0;
	end

	return nStatVal;
end

--
--	TRAITS
--

function getListRecordByName(nodeActor, sList, s)
	if not nodeActor or ((sList or "") == "") or ((s or "") == "") then
		return nil;
	end
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeActor, sList)) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getListRecordByName2024(nodeActor, sList, s)
	if not nodeActor or ((sList or "") == "") or ((s or "") == "") then
		return nil;
	end
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeActor, sList)) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if DB.getValue(v, "version", "") == "2024" then
				return v;
			end
		end
	end
	return nil;
end
function getListRecordByName2014(nodeActor, sList, s)
	if not nodeActor or ((sList or "") == "") or ((s or "") == "") then
		return nil;
	end
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeActor, sList)) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if DB.getValue(v, "version", "") ~= "2024" then
				return v;
			end
		end
	end
	return nil;
end

function hasRollTrait(rActor, s)
	return EffectManager5E.hasEffectCondition(rActor, s) or ActorManager5E.hasTrait(rActor, s);
end
function hasRollFeature(rActor, s)
	return EffectManager5E.hasEffectCondition(rActor, s) or ActorManager5E.hasFeature(rActor, s);
end
function hasRollFeat(rActor, s)
	return EffectManager5E.hasEffectCondition(rActor, s) or ActorManager5E.hasFeat(rActor, s);
end
function hasRollFeat2024(rActor, s)
	return EffectManager5E.hasEffectCondition(rActor, s) or ActorManager5E.hasFeat2024(rActor, s);
end
function hasRollFeat2014(rActor, s)
	return EffectManager5E.hasEffectCondition(rActor, s) or ActorManager5E.hasFeat2014(rActor, s);
end

function hasTrait(rActor, s)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.hasPCTrait(ActorManager.getCreatureNode(rActor), s);
	elseif ActorManager.isRecordType(rActor, "npc") then
		return ActorManager5E.hasNPCTrait(ActorManager.getCreatureNode(rActor), s);
	end
	return false;
end
function hasFeature(rActor, s)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.hasPCFeature(ActorManager.getCreatureNode(rActor), s);
	elseif ActorManager.isRecordType(rActor, "npc") then
		return ActorManager5E.hasNPCFeature(ActorManager.getCreatureNode(rActor), s);
	end
	return false;
end
function hasFeat(rActor, s)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.hasPCFeat(ActorManager.getCreatureNode(rActor), s);
	elseif ActorManager.isRecordType(rActor, "npc") then
		return ActorManager5E.hasNPCFeat(ActorManager.getCreatureNode(rActor), s);
	end
	return false;
end
function hasFeat2024(rActor, s)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.hasPCFeat2024(ActorManager.getCreatureNode(rActor), s);
	elseif ActorManager.isRecordType(rActor, "npc") then
		return ActorManager5E.hasNPCFeat2024(ActorManager.getCreatureNode(rActor), s);
	end
	return false;
end
function hasFeat2014(rActor, s)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.hasPCFeat2014(ActorManager.getCreatureNode(rActor), s);
	elseif ActorManager.isRecordType(rActor, "npc") then
		return ActorManager5E.hasNPCFeat2014(ActorManager.getCreatureNode(rActor), s);
	end
	return false;
end

function hasPCTrait(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "traitlist", s) ~= nil);
end
function hasNPCTrait(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "traits", s) ~= nil);
end
function hasPCFeature(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "featurelist", s) ~= nil);
end
function hasNPCFeature(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "traits", s) ~= nil) or (ActorManager5E.getListRecordByName(nodeActor, "actions", s) ~= nil);
end
function hasPCFeat(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "featlist", s) ~= nil);
end
function hasNPCFeat(nodeActor, s)
	return (ActorManager5E.getListRecordByName(nodeActor, "traits", s) ~= nil) or (ActorManager5E.getListRecordByName(nodeActor, "actions", s) ~= nil);
end
function hasPCFeat2024(nodeActor, s)
	return (ActorManager5E.getListRecordByName2024(nodeActor, "featlist", s) ~= nil);
end
function hasNPCFeat2024(nodeActor, s)
	if DB.getValue(nodeActor, "version", "") ~= "2024" then
		return false;
	end
	return (ActorManager5E.getListRecordByName(nodeActor, "traits", s) ~= nil) or (ActorManager5E.getListRecordByName(nodeActor, "actions", s) ~= nil);
end
function hasPCFeat2014(nodeActor, s)
	return (ActorManager5E.getListRecordByName2014(nodeActor, "featlist", s) ~= nil);
end
function hasNPCFeat2014(nodeActor, s)
	if DB.getValue(nodeActor, "version", "") == "2024" then
		return false;
	end
	return (ActorManager5E.getListRecordByName(nodeActor, "traits", s) ~= nil) or (ActorManager5E.getListRecordByName(nodeActor, "actions", s) ~= nil);
end

--
--	DEFENSES
--

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
			nValue = nValue + DB.getValue(nodeActor, "profbonus", 2);
		end

		-- Check for armor non-proficiency
		if StringManager.contains({"strength", "dexterity"}, sSave) then
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				table.insert(aAddText, Interface.getString("roll_msg_armor_nonprof"));
				bDIS = true;
			end
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		if DB.getValue(nodeActor, "version", "") == "2024" then
			nValue = nValue + DB.getValue(nodeActor, "abilities." .. sSave .. ".savemodifier", 0);
		else
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
	elseif ActorManager.isRecordType(rActor, "vehicle") then
		if DB.getValue(nodeActor, "version", "") == "2024" then
			nValue = nValue + DB.getValue(nodeActor, "abilities." .. sSave .. ".savemodifier", 0);
		end
	end

	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

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
				table.insert(aAddText, string.format("[%s]", Interface.getString("roll_msg_armor_disstealth")));
				bDIS = true;
			end
		end
	end

	return nValue, bADV, bDIS, table.concat(aAddText, " ");
end

function getDefenseAdvantage(rAttacker, rDefender, aAttackFilter)
	if not rDefender then
		return false, false;
	end

	-- Check effects
	local bADV = false;
	local bDIS = false;
	local bProne = false;

	if ActorManager.hasCT(rDefender) then
		local bDefenderFrozen = EffectManager5E.hasEffectCondition(rDefender, "Paralyzed") or
				EffectManager5E.hasEffectCondition(rDefender, "Petrified") or
				EffectManager5E.hasEffectCondition(rDefender, "Stunned") or
				EffectManager5E.hasEffectCondition(rDefender, "Unconscious");

		if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "ADVATK", aAttackFilter, rDefender, true)) > 0 then
			bADV = true;
		elseif EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAttacker) then
			bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTADVATK", aAttackFilter, rAttacker)) > 0 then
			bADV = true;
		elseif bDefenderFrozen then
			bADV = true;
		elseif EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			bADV = true;
		elseif EffectManager5E.hasEffect(rDefender, "Blinded", rAttacker) then
			bADV = true;
		elseif EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			bADV = true;
		end

		if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rAttacker, "DISATK", aAttackFilter, rDefender, true)) > 0 then
			bDIS = true;
		elseif EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAttacker) then
			bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rDefender, "GRANTDISATK", aAttackFilter, rAttacker)) > 0 then
			bDIS = true;
		elseif EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			bDIS = true;
		end

		if EffectManager.hasCondition(rDefender, "Prone") then
			bProne = true;
		end
		if EffectManager5E.hasEffect(rDefender, "Dodge", rAttacker) and
				not (bDefenderFrozen or
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

function getDefenseValue(rAttacker, rDefender, rRoll)
	if not rDefender or not rRoll then
		return nil, 0, 0, false, false;
	end

	-- Base calculations
	local sAttack = rRoll.sDesc;

	local sAttackType = ActionAttackCore.decodeRangeText(sAttack);
	local bOpportunity = sAttack:match("%[OPPORTUNITY%]");
	local nCover = tonumber(sAttack:match("%[COVER %-(%d)%]")) or 0;

	local nodeDefender = ActorManager.getCreatureNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, false, false;
	end

	local nDefense;
	local sDefenseStat = "dexterity";
	if ActorManager.isPC(rDefender) then
		nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 10);
		sDefenseStat = DB.getValue(nodeDefender, "ac.sources.ability", "");
		if sDefenseStat == "" then
			sDefenseStat = "dexterity";
		end
	elseif ActorManager.isRecordType(rDefender, "npc") or ActorManager.isRecordType(rDefender, "vehicle") then
		if (rRoll.sSubtargetPath or "") ~= "" then
			nDefense = DB.getValue(DB.getPath(rRoll.sSubtargetPath, "ac"), 10);
		else
			nDefense = DB.getValue(nodeDefender, "ac", 10);
		end
	else
		return nil, 0, 0, false, false;
	end
	nDefenseStatMod = ActorManager5E.getAbilityBonus(rDefender, sDefenseStat);

	-- Effects
	local nDefenseEffectMod = 0;
	local bADV = false;
	local bDIS = false;
	if ActorManager.hasCT(rDefender) then
		local nBonusAC = 0;
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

		local aACEffects,_ = EffectManager5E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker);
		for _,v in pairs(aACEffects) do
			nBonusAC = nBonusAC + v.mod;
		end

		local nBonusStat = ActorManager5E.getAbilityEffectsBonus(rDefender, sDefenseStat);
		if ActorManager.isPC(rDefender) and (nBonusStat > 0) then
			local sMaxDexBonus = DB.getValue(nodeDefender, "defenses.ac.dexbonus", "");
			if sMaxDexBonus == "no" then
				nBonusStat = 0;
			elseif sMaxDexBonus == "max2" then
				nBonusStat = math.min(math.max(2 - nBonusStat, 0), nBonusStat);
			elseif sMaxDexBonus == "max3" then
				nBonusStat = math.min(math.max(3 - nBonusStat, 0), nBonusStat);
			end
		end

		local bDefenderFrozen = EffectManager5E.hasEffectCondition(rDefender, "Paralyzed") or
				EffectManager5E.hasEffectCondition(rDefender, "Petrified") or
				EffectManager5E.hasEffectCondition(rDefender, "Stunned") or
				EffectManager5E.hasEffectCondition(rDefender, "Unconscious");

		if EffectManager5E.hasEffect(rAttacker, "ADVATK", rDefender, true) then
			bADV = true;
		elseif bDefenderFrozen then
			bADV = true;
		elseif EffectManager5E.hasEffect(rDefender, "GRANTADVATK", rAttacker) then
			bADV = true;
		elseif EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			bADV = true;
		elseif EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			bADV = true;
		end

		if EffectManager5E.hasEffect(rAttacker, "DISATK", rDefender, true) then
			bDIS = true;
		elseif EffectManager5E.hasEffect(rDefender, "GRANTDISATK", rAttacker) then
			bDIS = true;
		elseif EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			bDIS = true;
		end

		if EffectManager.hasCondition(rDefender, "Prone") then
			if sAttackType == "M" then
				bADV = true;
			elseif sAttackType == "R" then
				bDIS = true;
			end
		end

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
	return nDefense, 0, nDefenseEffectMod, bADV, bDIS;
end

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

function getDamageVulnerabilities(rActor, rSource)
	local tOutput = {};

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		ActorManager5E.helperGetDamageVulnResistImmuneFromField(tOutput, rActor, "damagevulnerabilities");
	end

	ActorManager5E.helperGetDamageVulnResistImmuneEffect(tOutput, "VULN", rActor, rSource);

	return tOutput;
end
function getDamageResistances(rActor, rSource)
	local tOutput = {};

	if ActorManager5E.hasRollFeat2024(rActor, CharManager.FEAT_HEAVY_ARMOR_MASTER) then
		if CharArmorManager.isWearingHeavyArmor(rActor) then
			local nProf = ActorManager5E.getAbilityBonus(rActor, "prf");
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "bludgeoning", { nMod = nProf });
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "piercing", { nMod = nProf });
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "slashing", { nMod = nProf });
		end
	elseif ActorManager5E.hasRollFeat2014(rActor, CharManager.FEAT_HEAVY_ARMOR_MASTER) then
		if CharArmorManager.isWearingHeavyArmor(rActor) then
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "bludgeoning", { nMod = 3, tNegatives = { "magic", }, });
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "piercing", { nMod = 3, tNegatives = { "magic", }, });
			ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, "slashing", { nMod = 3, tNegatives = { "magic", }, });
		end
	end

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		ActorManager5E.helperGetDamageVulnResistImmuneFromField(tOutput, rActor, "damageresistances");
	end

	ActorManager5E.helperGetDamageVulnResistImmuneEffect(tOutput, "RESIST", rActor, rSource);

	return tOutput;
end
function getDamageImmunities(rActor, rSource)
	local tOutput = {};

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		ActorManager5E.helperGetDamageVulnResistImmuneFromField(tOutput, rActor, "damageimmunities");
		ActorManager5E.helperGetDamageVulnResistImmuneVehicle(tOutput, rActor);
	end

	ActorManager5E.helperGetDamageVulnResistImmuneEffect(tOutput, "IMMUNE", rActor, rSource);

	return tOutput;
end
function helperGetDamageVulnResistImmuneFromField(tOutput, rActor, sField)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

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
				ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, v, { nMod = 0, tNegatives = tNegationTypes, });
			end
		end
	end
end
function helperGetDamageVulnResistImmuneVehicle(tOutput, rActor)
	if ActorManager.getRecordType(rActor) ~= "vehicle" then
		return;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end
	if (DB.getValue(nodeActor, "disablestandarddamageimmunities", 0) == 1) then
		return;
	end

	for _,s in ipairs(ActorManager5E.tStandardVehicleDamageImmunities) do
		ActorManager5E.helperGetDamageVulnResistImmuneAddBasic(tOutput, s);
	end
end
function helperGetDamageVulnResistImmuneEffect(tOutput, sEffectType, rActor, rSource)
	local tEffects = EffectManager5E.getEffectsByType(rActor, sEffectType, {}, rSource);
	for _,rEffect in pairs(tEffects) do
		local tData = {
			nMod = DiceManager.evalDice(rEffect.dice, rEffect.mod),
			tNegatives = {},
		};

		for _,s in pairs(rEffect.remainder) do
			if StringManager.startsWith(s, "!") or StringManager.startsWith(s, "~") then
				if StringManager.contains(DataCommon.dmgtypes, s:sub(2)) then
					table.insert(tData.tNegatives, s:sub(2));
				end
			end
		end

		for _,s in pairs(rEffect.remainder) do
			if (s ~= "untyped") and (s ~= "") and
					not StringManager.startsWith(s, "!") and
					not StringManager.startsWith(s, "~") then
				if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" then
					ActorManager5E.helperGetDamageVulnResistImmuneAdd(tOutput, s, tData);
				end
			end
		end
	end
end
function helperGetDamageVulnResistImmuneAddBasic(tOutput, kData)
	if not tOutput or not kData then
		return;
	end
	tOutput[kData] = tOutput[kData] or {};
	tOutput[kData].tBasic = tOutput[kData].tBasic or {};
	table.insert(tOutput[kData].tBasic, {});
end
function helperGetDamageVulnResistImmuneAdd(tOutput, kData, tData)
	if not tOutput or not kData or not tData then
		return;
	end
	tOutput[kData] = tOutput[kData] or {};
	if (tData.nMod or 0) == 0 then
		tOutput[kData].tBasic = tOutput[kData].tBasic or {};
		table.insert(tOutput[kData].tBasic, tData);
	else
		tOutput[kData].tNumeric = tOutput[kData].tNumeric or {};
		table.insert(tOutput[kData].tNumeric, tData);
	end
end

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
	for _,tEffect in pairs(tImmuneEffects) do
		for _,s in ipairs(tEffect.remainder) do
			local sLower = s:lower();
			if StringManager.contains(DataCommon.conditions, sLower) then
				table.insert(tResults, sLower);
			end
		end
	end

	return tResults;
end
function getNonPCActorConditionImmunitiesHelper(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return {};
	end

	local tResults = {};

	local bIs2024 = (DB.getValue(nodeActor, "version", "") == "2024");
	local sActorImmune;
	if bIs2024 then
		sActorImmune = DB.getValue(nodeActor, "damageimmunities", ""):lower();
	else
		sActorImmune = DB.getValue(nodeActor, "conditionimmunities", ""):lower();
	end
	local tActorImmuneWords = StringManager.split(sActorImmune, ",", true);
	for _,v in ipairs(tActorImmuneWords) do
		local vLower = v:lower();
		if StringManager.contains(DataCommon.conditions, vLower) then
			table.insert(tResults, vLower);
		end
	end

	if ActorManager.isRecordType(rActor, "vehicle") then
		local bAddStandard;
		if bIs2024 then
			bAddStandard = (DB.getValue(nodeActor, "disablestandarddamageimmunities", 0) == 0);
		else
			bAddStandard = (DB.getValue(nodeActor, "disablestandardconditionimmunities", 0) == 0);
		end
		if bAddStandard then
			for _,v in ipairs(ActorManager5E.tStandardVehicleConditionImmunities) do
				table.insert(tResults, v);
			end
			local sType = StringManager.simplify(DB.getValue(nodeActor, "type", ""));
			if sType ~= ActorManager5E.VEHICLE_TYPE_LAND then
				table.insert(tResults, "prone");
			end
		end
	end

	return tResults;
end

-- DEPRECATED (2025-03)

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
function getDamageVulnResistImmuneEffectHelper(rActor, sEffectType, rSource)
	local tResults = {};

	local aEffects = EffectManager5E.getEffectsByType(rActor, sEffectType, {}, rSource);
	for _,v in pairs(aEffects) do
		local r = {
			mod = DiceManager.evalDice(v.dice, v.mod),
			aNegatives = {},
		};

		for _,s in pairs(v.remainder) do
			if StringManager.startsWith(s, "!") or StringManager.startsWith(s, "~") then
				if StringManager.contains(DataCommon.dmgtypes, s:sub(2)) then
					table.insert(r.aNegatives, s:sub(2));
				end
			end
		end

		for _,s in pairs(v.remainder) do
			if (s ~= "untyped") and (s ~= "") and
					not StringManager.startsWith(s, "!") and
					not StringManager.startsWith(s, "~") then
				if StringManager.contains(DataCommon.dmgtypes, s) or s == "all" then
					tResults[s] = r;
				end
			end
		end
	end

	return tResults;
end
