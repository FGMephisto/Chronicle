--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- NOTE: Non-land vehicles are also immune to "prone" by default
VEHICLE_TYPE_LAND = "land";
tStandardVehicleConditionImmunities = { "blinded", "charmed", "deafened", "frightened", "intoxicated", "paralyzed", "petrified", "poisoned", "stunned", "unconscious" };
tStandardVehicleDamageImmunities = { "poison", "psychic" };

function onInit()
	GameManager.setFunction("onActorGetAbilityScore", ActorManager5E.getAbilityScore);
	GameManager.setFunction("onActorGetBonus", ActorManager5E.getBonus);
	GameManager.setFunction("onActorGetEffectsBonus", ActorManager5E.getEffectsBonus);
	GameManager.setFunction("onActorGetHealthStatus", ActorManager5E.getWoundPercent);
	GameManager.setFunction("onActorEffectDamageAdjust", ActorManager5E.getEffectsAdjustActor);
	GameManager.setFunction("onActorEffectConditionImmune", ActorManager5E.getConditionImmunities);
	GameManager.setFunction("onActorRest", ActorManager5E.rest);

	ActorCommonManager.addDefaultSizeHandling();
end

--
--	HEALTH
--

-- NOTE: Always default to using CT node as primary to make sure
--		that all bars and statuses are synchronized in combat tracker
--		(Cross-link network updates between PC and CT fields can occur in either order,
--		depending on where the scripts or end user updates.)
-- NOTE 2: We can not use default effect checking in this function;
-- 		as it will cause endless loop with conditionals that check health
function getWoundPercent(rActor)
	local nHP = GameManager.getRecordFieldValueLinked(rActor, "hptotal", 0);
	local nWounds = GameManager.getRecordFieldValueLinked(rActor, "wounds", 0);

	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end

	local sStatus;
	if nPercentWounded >= 1 then
		local nDeathSaveFail = GameManager.getRecordFieldValueLinked(rActor, "deathsavefail", 0);
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
	local nPercentWounded = ActorManager5E.getWoundPercent(nodePC);
	return ColorManager.getHealthColor(nPercentWounded, false);
end

--
--	ABILITY SCORES
--

function getAbilityScore(rActor, sAbility, rEffect)
	if not sAbility then
		return 0;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	local nStatScore = 0;

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
	elseif sShort == "sdc" then
		nStatScore = ActorManager5E.getEffectSpellDC(rActor, rEffect);
	elseif StringManager.contains(DataCommon.classes, sAbility:lower()) then
		nStatScore = ActorManager5E.getClassLevel(nodeActor, sAbility:lower());
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
function getAbilityBonus(rActor, sAbility, rEffect)
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

	local nStatScore = ActorManager5E.getAbilityScore(rActor, sAbility, rEffect);
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

function getEffectSpellDC(rActor, rEffect)
	local nDCMod = EffectManager.getBonusMod(rActor, "DC", { tActionTags = rEffect and rEffect.tActionTags, });

	if rEffect and rEffect.nodeAction then
		return ActorManager5E.getEffectSpellDCFromAction(rActor, rEffect.nodeAction) + nDCMod;
	end
	return ActorManager5E.getEffectSpellDCFromActor(rActor, rEffect) + nDCMod;
end
function getEffectSpellDCFromAction(rActor, nodeAction)
	if not nodeAction then
		return 0;
	end
	local nodePower = DB.getChild(nodeAction, "...");

	local rCastAction;
	for _, v in ipairs(DB.getChildList(nodePower, "actions")) do
		if DB.getValue(v, "type", "") == "cast" then
			rCastAction = PowerManager.getPCPowerActionHelper(rActor, v); 
			break;
		end
	end
	if rCastAction then
		PowerManager.evalAction(rActor, nodePower, rCastAction);
		return rCastAction.savemod;
	end

	local nDC = 8;
	local aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
	if aPowerGroup then
		if (aPowerGroup.sSaveDCStat or "") ~= "" then
			nDC = nDC + ActorCommonManager.getBonus(rActor, aPowerGroup.sSaveDCStat);
		end
		if (aPowerGroup.nSaveDCProf or 0) == 1 then
			nDC = nDC + ActorCommonManager.getBonus(rActor, "prf");
		end
		nDC = nDC + (aPowerGroup.nSaveDCMod or 0);
	end
	return nDC;
end
function getEffectSpellDCFromActor(rActor, rEffect)
	local sAbility = ActorManager5E.getSpellcastingAbility(rActor);
	if ((sAbility or "") == "") then
		local nSpellcastDC = ActorManager5E.getSpellcastingDC(rActor);
		if nSpellcastDC then
			return nSpellcastDC;
		end
	end
	return 8 + ActorCommonManager.getBonus(rActor, "prf") + ActorCommonManager.getBonus(rActor, sAbility);
end

function getSpellcastingAbility(rActor)
	if ActorManager.isPC(rActor) then
		for _,v in ipairs(DB.getChildList(ActorManager.getCreatureNode(rActor), "featurelist")) do
			local sName = StringManager.simplify(DB.getValue(v, "name", ""));
			if StringManager.startsWith(sName, "spellcasting") or StringManager.startsWith(sName, "pactmagic") then
				local sDesc = DB.getText(v, "text", ""):lower();
				local sAbility = ActorManager5E.getSpellcastingAbilityFromText(sDesc);
				if sAbility then
					return sAbility;
				end
			end
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		for _,v in ipairs(DB.getChildList(nodeActor, "traits")) do
			local s = StringManager.simplify(DB.getValue(v, "name", ""));
			if StringManager.startsWith(s, "spellcasting") or
					StringManager.startsWith(s, "pactmagic") or
					StringManager.startsWith(s, "innatespellcasting") then
				local sDesc = DB.getText(v, "desc", ""):lower();
				local sAbility = ActorManager5E.getSpellcastingAbilityFromText(sDesc);
				if sAbility then
					return sAbility;
				end
			end
		end
		if not nSpellcastAbilityBonus then
			for _,v in ipairs(DB.getChildList(nodeActor, "actions")) do
				local s = StringManager.simplify(DB.getValue(v, "name", ""));
				if StringManager.startsWith(s, "spellcasting") then
					local sDesc = DB.getText(v, "desc", ""):lower();
					local sAbility = ActorManager5E.getSpellcastingAbilityFromText(sDesc);
					if sAbility then
						return sAbility;
					end
				end
			end
		end
	end
	return "";
end
function getSpellcastingAbilityFromText(s)
	if (s or "") == "" then
		return nil;
	end
	local sAbility = s:match("(%a+) is your spellcasting ability");
	if not sAbility then
		sAbility = s:match("(%a+) is the spellcasting ability");
	end
	if not sAbility then
		sAbility = s:match("using (%w+) as the spellcasting ability");
	end
	if not sAbility then
		sAbility = s:match("spellcasting ability is (%w+)")
	end
	return sAbility;
end
function getSpellcastingDC(rActor)
	if not ActorManager.isRecordType(rActor, "npc") then
		return nil;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	for _,v in ipairs(DB.getChildList(nodeActor, "traits")) do
		local s = StringManager.simplify(DB.getValue(v, "name", ""));
		if StringManager.startsWith(s, "spellcasting") or
				StringManager.startsWith(s, "pactmagic") or
				StringManager.startsWith(s, "innatespellcasting") then
			local sDesc = DB.getText(v, "desc", ""):lower();
			local sDC = sDesc:match("spell save dc (%d+)");
			if sDC then
				return tonumber(sDC);
			end
		end
	end
	if not nSpellcastAbilityBonus then
		for _,v in ipairs(DB.getChildList(nodeActor, "actions")) do
			local s = StringManager.simplify(DB.getValue(v, "name", ""));
			if StringManager.startsWith(s, "spellcasting") then
				local sDesc = DB.getText(v, "desc", ""):lower();
				local sDC = sDesc:match("spell save dc (%d+)");
				if sDC then
					return tonumber(sDC);
				end
			end
		end
	end
	return nil;
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
	return EffectManager.hasText(rActor, s) or ActorManager5E.hasTrait(rActor, s);
end
function hasRollFeature(rActor, s)
	return EffectManager.hasText(rActor, s) or ActorManager5E.hasFeature(rActor, s);
end
function hasRollFeat(rActor, s)
	return EffectManager.hasText(rActor, s) or ActorManager5E.hasFeat(rActor, s);
end
function hasRollFeat2024(rActor, s)
	return EffectManager.hasText(rActor, s) or ActorManager5E.hasFeat2024(rActor, s);
end
function hasRollFeat2014(rActor, s)
	return EffectManager.hasText(rActor, s) or ActorManager5E.hasFeat2014(rActor, s);
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

function getDefenseAdvantage(rAttacker, rDefender, tAttackFilter)
	if not rDefender then
		return false, false;
	end
	if not ActorManager.hasCT(rDefender) then
		return false, false;
	end

	-- Check effects
	local bADV = false;
	local bDIS = false;
	local bProne = false;

	local bDefenderFrozen = EffectManager.hasCondition(rDefender, "Paralyzed") or
			EffectManager.hasCondition(rDefender, "Petrified") or
			EffectManager.hasCondition(rDefender, "Stunned") or
			EffectManager.hasCondition(rDefender, "Unconscious");
	local tAttEffData = { rTarget = rDefender, bTargetedOnly = true, tFilter = tAttackFilter, };
	local tDefEffData = { rTarget = rAttacker, tFilter = tAttackFilter, };

	if bDefenderFrozen then
		bADV = true;
	elseif EffectManager.hasTextOrTag(rAttacker, "ADVATK", tAttEffData) then
		bADV = true;
	elseif EffectManager.hasTextOrTag(rDefender, "@ADVATK", tDefEffData) then
		bADV = true;
	elseif EffectManager.hasTextOrTag(rDefender, "GRANTADVATK", tDefEffData) then
		bADV = true;
	elseif EffectManager.hasText(rAttacker, "Invisible", tAttEffData) then
		bADV = true;
	elseif EffectManager.hasCondition(rDefender, "Blinded") then
		bADV = true;
	elseif EffectManager.hasCondition(rDefender, "Restrained") then
		bADV = true;
	end

	if EffectManager.hasTextOrTag(rAttacker, "DISATK", tAttEffData) then
		bDIS = true;
	elseif EffectManager.hasTextOrTag(rDefender, "@DISATK", tDefEffData) then
		bDIS = true;
	elseif EffectManager.hasTextOrTag(rDefender, "GRANTDISATK", tDefEffData) then
		bDIS = true;
	elseif EffectManager.hasText(rDefender, "Invisible", tDefEffData) then
		bDIS = true;
	end

	if EffectManager.hasCondition(rDefender, "Prone") then
		bProne = true;
	end
	if EffectManager.hasText(rDefender, "Dodge", tDefEffData) and
			not (bDefenderFrozen or
			EffectManager.hasCondition(rDefender, "Grappled") or
			EffectManager.hasCondition(rDefender, "Restrained")) then
		bDIS = true;
	end

	if bProne then
		if StringManager.contains(tAttackFilter, "melee") then
			bADV = true;
		elseif StringManager.contains(tAttackFilter, "ranged") then
			bDIS = true;
		end
	end

	return bADV, bDIS;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	if not rDefender or not rRoll then
		return nil, 0, 0, false, false;
	end
	local nodeDefender = ActorManager.getCreatureNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, false, false;
	end

	-- Base calculations
	local sAttack = rRoll.sDesc;

	local sAttackType = ActionAttackCore.decodeRangeText(sAttack);
	local bOpportunity = sAttack:match("%[OPPORTUNITY%]");
	local nCover = tonumber(sAttack:match("%[COVER %-(%d)%]")) or 0;

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
		local tAttackFilter = ActionCore.buildEffectFilter({ sRange = sAttackType, bOpportunity = bOpportunity, });
		local tAttEffData = { rTarget = rDefender, bTargetedOnly = true, tFilter = tAttackFilter, };
		local tDefEffData = { rTarget = rAttacker, tFilter = tAttackFilter, };
		
		local nBonusAC = EffectManager.getBonusMod(rDefender, "AC", tDefEffData);

		local nBonusStat = ActorManagerD20.getAbilityEffectsBonus(rDefender, sDefenseStat);
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

		local bDefenderFrozen = EffectManager.hasCondition(rDefender, "Paralyzed") or
				EffectManager.hasCondition(rDefender, "Petrified") or
				EffectManager.hasCondition(rDefender, "Stunned") or
				EffectManager.hasCondition(rDefender, "Unconscious");

		if EffectManager.hasText(rAttacker, "ADVATK", tAttEffData) then
			bADV = true;
		elseif bDefenderFrozen then
			bADV = true;
		elseif EffectManager.hasText(rDefender, "GRANTADVATK", tDefEffData) then
			bADV = true;
		elseif EffectManager.hasText(rAttacker, "Invisible", tAttEffData) then
			bADV = true;
		elseif EffectManager.hasCondition(rDefender, "Restrained") then
			bADV = true;
		end

		if EffectManager.hasText(rAttacker, "DISATK", tAttEffData) then
			bDIS = true;
		elseif EffectManager.hasText(rDefender, "GRANTDISATK", tDefEffData) then
			bDIS = true;
		elseif EffectManager.hasText(rDefender, "Invisible", tDefEffData) then
			bDIS = true;
		end

		if EffectManager.hasCondition(rDefender, "Prone") then
			if sAttackType == "M" then
				bADV = true;
			elseif sAttackType == "R" then
				bDIS = true;
			end
		end

		local nBonusSituational = 0;
		if nCover < 5 then
			if EffectManager.hasTextOrTag(rDefender, "SCOVER", tDefEffData) then
				nBonusSituational = nBonusSituational + 5 - nCover;
			elseif nCover < 2 then
				if EffectManager.hasTextOrTag(rDefender, "COVER", tDefEffData) then
					nBonusSituational = nBonusSituational + 2 - nCover;
				end
			end
		end

		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational;
	end

	-- Results
	return nDefense, 0, nDefenseEffectMod, bADV, bDIS;
end

--
--	BONUS
--

function getBonus(rActor, sKey, ...)
	if (sKey or "") ~= "" then
		sKey = DataCommon.ability_stol[sKey:upper()] or sKey:lower();
	end
	if StringManager.contains(DataCommon.abilities, sKey) then
		return ActorManager5E.getAbilityBonus(rActor, sKey, ...);
	end
	return ActorManager5E.getAbilityScore(rActor, sKey, ...);
end
function getEffectsBonus(rActor, sKey, ...)
	if (sKey or "") ~= "" then
		sKey = DataCommon.ability_stol[sKey:upper()] or sKey:lower();
	end
	if StringManager.contains(DataCommon.abilities, sKey) then
		return ActorManagerD20.getAbilityEffectsBonus(rActor, sKey, ...);
	end
	return 0, 0;
end

--
--	EFFECTS
--

function getEffectsAdjustActor(sEffectTag, rActor, rSource, rRoll, tApplyData)
	if sEffectTag == "ABSORB" then
		return ActorManager5E.getDamageAbsorbEffects(sEffectTag, rActor, rSource, rRoll, tApplyData);
	elseif sEffectTag == "IMMUNE" then
		return ActorManager5E.getDamageImmuneEffects(sEffectTag, rActor, rSource, rRoll, tApplyData);
	elseif sEffectTag == "RESIST" then
		return ActorManager5E.getDamageResistEffects(sEffectTag, rActor, rSource, rRoll, tApplyData);
	elseif sEffectTag == "VULN" then
		return ActorManager5E.getDamageVulnEffects(sEffectTag, rActor, rSource, rRoll, tApplyData);
	end
	return {};
end
function getDamageAbsorbEffects(sEffectTag, rActor, rSource, rRoll, tApplyData)
	local tEffects = ActorCommonManager.getEffectsDamageAdjustDefault(sEffectTag, rActor, rSource, rRoll, tApplyData);

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			for _,v in ipairs(DB.getChildList(nodeActor, "traits")) do
				local sName = DB.getValue(v, "name", ""):lower();
				if sName:match("absorption$") then
					local sType = sName:match("^([^ ]+) ");
					if sType and ActionCore.isDamageType(sType) then
						table.insert(tEffects, { type = "ABSORB", remainder = { sType, }, });
					end
				end
			end
		end
	end

	return tEffects;
end
function getDamageImmuneEffects(sEffectTag, rActor, rSource, rRoll, tApplyData)
	local tEffects = ActorCommonManager.getEffectsDamageAdjustDefault(sEffectTag, rActor, rSource, rRoll, tApplyData);

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		for _,v in ipairs(ActorManager5E.getDamageAdjustEffectsFromField(rActor, "damageimmunities", "IMMUNE")) do
			table.insert(tEffects, v);
		end
		for _,v in ipairs(ActorManager5E.getDamageAdjustEffectsVehicle(rActor)) do
			table.insert(tEffects, v);
		end
	end

	return tEffects;
end
function getDamageResistEffects(sEffectTag, rActor, rSource, rRoll, tApplyData)
	local tEffects = ActorCommonManager.getEffectsDamageAdjustDefault(sEffectTag, rActor, rSource, rRoll, tApplyData);

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		for _,v in ipairs(ActorManager5E.getDamageAdjustEffectsFromField(rActor, "damageresistances", "RESIST")) do
			table.insert(tEffects, v);
		end
	end

	local setDmgTypes = SetManager.new();
	for sDmgType,_ in pairs(tApplyData.tDamageTypes or {}) do
		SetManager.add(setDmgTypes, StringManager.split(sDmgType, ",", true));
	end
	local bBasicDmg = SetManager.contains(setDmgTypes, "bludgeoning") or SetManager.contains(setDmgTypes, "piercing") or SetManager.contains(setDmgTypes, "slashing");
	if bBasicDmg then
		if ActorManager5E.hasRollFeat2024(rActor, CharManager.FEAT_HEAVY_ARMOR_MASTER) then
			if CharArmorManager.isWearingHeavyArmor(rActor) then
				table.insert(tApplyData.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feat_heavyarmormaster")));
				local nProf = ActorManager5E.getAbilityBonus(rActor, "prf");
				table.insert(tEffects, { type = "RESIST", mod = nProf, remainder = { "bludgeoning", }, });
				table.insert(tEffects, { type = "RESIST", mod = nProf, remainder = { "piercing", }, });
				table.insert(tEffects, { type = "RESIST", mod = nProf, remainder = { "slashing", }, });
			end
		elseif ActorManager5E.hasRollFeat2014(rActor, CharManager.FEAT_HEAVY_ARMOR_MASTER) then
			if CharArmorManager.isWearingHeavyArmor(rActor) then
				table.insert(tApplyData.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feat_heavyarmormaster")));
				table.insert(tEffects, { type = "RESIST", mod = 3, remainder = { "bludgeoning", "!magic", }, });
				table.insert(tEffects, { type = "RESIST", mod = 3, remainder = { "piercing", "!magic", }, });
				table.insert(tEffects, { type = "RESIST", mod = 3, remainder = { "slashing", "!magic", }, });
			end
		end
	end

	return tEffects;
end
function getDamageVulnEffects(sEffectTag, rActor, rSource, rRoll, tApplyData)
	local tEffects = ActorCommonManager.getEffectsDamageAdjustDefault(sEffectTag, rActor, rSource, rRoll, tApplyData);

	local sRecordType = ActorManager.getRecordType(rActor);
	if (sRecordType == "npc") or (sRecordType == "vehicle") then
		for _,v in ipairs(ActorManager5E.getDamageAdjustEffectsFromField(rActor, "damagevulnerabilities", "VULN")) do
			table.insert(tEffects, v);
		end
	end

	return tEffects;
end
function getDamageAdjustEffectsFromField(rActor, sField, sEffectTag)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return {};
	end

	local tEffects = {};
	local s = DB.getValue(nodeActor, sField, ""):lower();
	for _,v in ipairs(StringManager.split(s, ";\r\n", true)) do
		local tResistTypes = {};
		local tNegationTypes = {};

		for _,v2 in ipairs(StringManager.split(v, ",", true)) do
			if ActionCore.isDamageType(v2) then
				table.insert(tResistTypes, v2);
			else
				local aResistWords = StringManager.parseWords(v2);

				local i = 1;
				while aResistWords[i] do
					if ActionCore.isDamageType(aResistWords[i]) then
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

		for _,v in ipairs(tResistTypes) do
			local tEffect = { type = sEffectTag, remainder = { v }, };
			for _,vNegation in ipairs(tNegationTypes) do
				table.insert(tEffect.remainder, "!" .. vNegation);
			end
			table.insert(tEffects, tEffect);
		end
	end
	return tEffects;
end
function getDamageAdjustEffectsVehicle(tOutput, rActor)
	if ActorManager.getRecordType(rActor) ~= "vehicle" then
		return {};
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return {};
	end
	if (DB.getValue(nodeActor, "disablestandarddamageimmunities", 0) == 1) then
		return {};
	end

	local tEffects = {};
	for _,s in ipairs(ActorManager5E.tStandardVehicleDamageImmunities) do
		table.insert(tEffects, { type = "IMMUNE", remainder = { s, }, });
	end
	return tEffects;
end

function getConditionImmunities(rActor, rSource)
	local tResults = ActorCommonManager.getEffectsConditionImmunitiesDefault(rActor, rSource);

	local sActorType = ActorManager.getRecordType(rActor);
	if (sActorType == "npc") or (sActorType == "vehicle") then
		local tActorImmune = ActorManager5E.getNonPCActorConditionImmunitiesHelper(rActor);
		for _,s in ipairs(tActorImmune) do
			if not StringManager.contains(tResults, s) then
				table.insert(tResults, s);
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
	local tActorImmuneWords = StringManager.split(sActorImmune, ";,", true);
	for _,v in ipairs(tActorImmuneWords) do
		local vLower = v:lower();
		if ActionCore.isCondition(vLower) then
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

--
--	REST
--

function rest(rActor, sRestType)
	if ActorManager.isPC(rActor) then
		return ActorManager5E.restPC(rActor, sRestType);
	end

	if not ActorCommonManager.restDefault(rActor, sRestType) then
		return false;
	end

	if sRestType == "long" then
		ActorManager5E.reduceExhaustion(rActor);
	end
	return true;
end
function restPC(rActor, sRestType)
	if not ActorManager.checkRest(rActor, sRestType) then
		return false;
	end

	ActorManager5E.resetHealthPC(rActor, sRestType);

	local nodeChar = ActorManager.getCreatureNode(rActor);
	PowerManager.resetPowers(nodeChar, (sRestType == "long"));

	if sRestType == "short" then
		if ActorManager5E.hasFeature(rActor, CharManager.FEATURE_TIRELESS) then
			ActorManager5E.reduceExhaustion(rActor);
		end
	elseif sRestType == "long" then
		ActorManager5E.reduceExhaustion(rActor);

		if ActorManager5E.hasTrait(rActor, CharManager.TRAIT_RESOURCEFUL) then
			if DB.getValue(nodeChar, "inspiration", 0) <= 0 then
				DB.setValue(nodeChar, "inspiration", "number", 1);
			end
		end
	end
	return true;
end
function resetHealthPC(rActor, sRestType)
	local bResetWounds = false;
	local bResetTemp = false;
	local bResetHitDice = false;
	local bResetHalfHitDice = false;
	local bResetQuarterHitDice = false;

	local sOptHRHV = OptionsManager.getOption("HRHV");
	if sOptHRHV == "fast" then
		if sRestType == "long" then
			bResetWounds = true;
			bResetTemp = true;
			bResetHitDice = true;
		else
			bResetQuarterHitDice = true;
		end
	elseif sOptHRHV == "slow" then
		if sRestType == "long" then
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	else
		if sRestType == "long" then
			bResetWounds = true;
			bResetTemp = true;
			if OptionsManager.isOption("GAVE", "2024") then
				bResetHitDice = true;
			else
				bResetHalfHitDice = true;
			end
		end
	end

	-- Reset health fields and conditions
	if bResetWounds then
		if not ActorManager.canHeal(rActor, "rest") then
			ChatManager.Message(Interface.getString("message_healblocked"), true, rActor);
		else
			GameManager.setRecordFieldValue(rActor, "wounds", "number", 0);
			GameManager.setRecordFieldValue(rActor, "deathsavesuccess", "number", 0);
			GameManager.setRecordFieldValue(rActor, "deathsavefail", "number", 0);

			EffectManager.removeCondition(rActor, "Stable");
			EffectManager.removeCondition(rActor, "Unconscious");
		end
	end
	if bResetTemp then
		GameManager.setRecordFieldValue(rActor, "hptemp", "number", 0);
	end

	local nodeChar = ActorManager.getCreatureNode(rActor);
	-- Reset all hit dice
	if bResetHitDice then
		for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
			DB.setValue(vClass, "hdused", "number", 0);
		end
	end

	-- Reset half or quarter of hit dice (assume biggest hit dice selected first)
	if bResetHalfHitDice or bResetQuarterHitDice then
		local nHDUsed, nHDTotal = CharManager.getClassHDUsage(nodeChar);
		if nHDUsed > 0 then
			local nHDRecovery;
			if bResetQuarterHitDice then
				nHDRecovery = math.max(math.floor(nHDTotal / 4), 1);
			else
				nHDRecovery = math.max(math.floor(nHDTotal / 2), 1);
			end
			if nHDRecovery >= nHDUsed then
				for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
					DB.setValue(vClass, "hdused", "number", 0);
				end
			else
				local nodeClassMax, nClassMaxHDSides, nClassMaxHDUsed;
				while nHDRecovery > 0 do
					nodeClassMax = nil;
					nClassMaxHDSides = 0;
					nClassMaxHDUsed = 0;

					for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
						local nClassHDUsed = DB.getValue(vClass, "hdused", 0);
						if nClassHDUsed > 0 then
							local aClassDice = DB.getValue(vClass, "hddie", {});
							if #aClassDice > 0 then
								local nClassHDSides = tonumber(aClassDice[1]:sub(2)) or 0;
								if nClassHDSides > 0 and nClassMaxHDSides < nClassHDSides then
									nodeClassMax = vClass;
									nClassMaxHDSides = nClassHDSides;
									nClassMaxHDUsed = nClassHDUsed;
								end
							end
						end
					end

					if nodeClassMax then
						if nHDRecovery >= nClassMaxHDUsed then
							DB.setValue(nodeClassMax, "hdused", "number", 0);
							nHDRecovery = nHDRecovery - nClassMaxHDUsed;
						else
							DB.setValue(nodeClassMax, "hdused", "number", nClassMaxHDUsed - nHDRecovery);
							nHDRecovery = 0;
						end
					else
						break;
					end
				end
			end
		end
	end
end

function getExhaustionLevel(rActor)
	local nExhaustTagMod = EffectManager.getBonusMod(rActor, "EXHAUSTION");
	local nExhaustTextMod = #(EffectManager.getCompsDataByText(rActor, "Exhaustion"));
	return nExhaustTagMod + nExhaustTextMod;
end
function setExhaustionLevel(rActor, n)
	EffectManager.removeEffectsByTag(rActor, "EXHAUSTION");
	EffectManager.removeEffectsByText(rActor, "Exhaustion");

	if n > 0 then
		if n == 1 then
			EffectManager.addEffectByText(rActor, "Exhaustion");
		else
			EffectManager.addEffectByText(rActor, string.format("EXHAUSTION: %d", n));
		end
	end
end
function reduceExhaustion(rActor)
	if EffectManager.hasCondition(rActor, "STAYEXHAUST") then
		return;
	end
	local nExhaustLevel = ActorManager5E.getExhaustionLevel(rActor);
	if nExhaustLevel <= 0 then
		return;
	end
	ActorManager5E.setExhaustionLevel(rActor, nExhaustLevel - 1);
end

--
--	DEPRECATED (2026-04)
--

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
			if ActionCore.isDamageType(v2) then
				table.insert(tResistTypes, v2);
			else
				local aResistWords = StringManager.parseWords(v2);

				local i = 1;
				while aResistWords[i] do
					if ActionCore.isDamageType(aResistWords[i]) then
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
function helperGetDamageVulnResistImmuneEffect(tOutput, sEffectTag, rActor, rSource)
	for _,rEffect in ipairs(EffectManager.getCompsDataByTag(rActor, sEffectTag, { rTarget = rSource, })) do
		local tData = {
			nMod = DiceManager.evalDice(rEffect.dice, rEffect.mod),
			tNegatives = {},
		};

		for _,s in pairs(rEffect.remainder) do
			if StringManager.startsWith(s, "!") then
				if ActionCore.isDamageType(s:sub(2)) then
					table.insert(tData.tNegatives, s:sub(2));
				end
			end
		end

		for _,s in pairs(rEffect.remainder) do
			if (s ~= "") and not StringManager.startsWith(s, "!") then
				if ActionCore.isDamageType(s) or (s == "all") then
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
