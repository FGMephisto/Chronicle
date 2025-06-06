--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncDnD);

	CombatManager.setCustomRoundStart(CombatManager2.onRoundStart);
	CombatManager.setCustomTurnStart(CombatManager2.onTurnStart);
	CombatManager.setCustomTurnEnd(CombatManager2.onTurnEnd);
	CombatManager.setCustomCombatReset(CombatManager2.resetInit);
	CombatManager.setCustomInitSwapPlayerAllow(CombatManager2.isInitSwapPlayerAllowed);

	-- CombatRecordManager.addStandardVehicleCombatRecordType();

	ActorCommonManager.setDefaultSpaceReachFromActorSizeKey("5E");
	ActorCommonManager.setRecordTypeSpaceReachCallback("charsheet", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("vehicle", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	CombatRecordManager.setRecordTypePostAddCallback("npc", CombatManager2.onNPCPostAdd);
	-- CombatRecordManager.setRecordTypePostAddCallback("vehicle", CombatManager2.onVehiclePostAdd);
end

--
-- TURN FUNCTIONS
--

function onRoundStart(_)
	if OptionsManager.isOption("HRIR", "on") then
		CombatManager2.rollInit();
	end
end

-- Adjusted
function onTurnStart(nodeEntry)
	-- if not nodeEntry then
		-- return;
	-- end

	-- Handle beginning of turn changes
	-- DB.setValue(nodeEntry, "reaction", "number", 0);

	-- Check for exhaustion levels for pre-2024 rules
	-- if nodeEntry then
		-- local sClass, sRecord = DB.getValue(nodeEntry, "link");
		-- if (sClass == "charsheet") and ((sRecord or "") ~= "") then
			-- Get exhaustion modifiers
			-- local nExhaustMod,_ = EffectManager5E.getEffectsBonus(nodeEntry, { "EXHAUSTION" }, true);
			-- local bShowMsg = true;

			-- if OptionsManager.isOption("GAVE", "2024") then
				-- if nExhaustMod > 5 then
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; DEATH", nDuration = 1 }, bShowMsg);
				-- elseif nExhaustMod > 0 then
					-- local nSpeedAdjust = nExhaustMod * 5;
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; Speed -" .. nSpeedAdjust .. " (info only)", nDuration = 1 }, bShowMsg);
				-- end
			-- else
				-- if nExhaustMod > 5 then
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; DEATH", nDuration = 1 }, bShowMsg);
				-- elseif nExhaustMod > 4 then
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; Speed 0, HP MAX HALVED (info only)", nDuration = 1 }, bShowMsg);
				-- elseif nExhaustMod > 3 then
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; Speed Halved, HP MAX HALVED (info only)", nDuration = 1 }, bShowMsg);
				-- elseif nExhaustMod > 1 then
					-- EffectManager.addEffect("", "", nodeEntry, { sName = "Exhausted; Speed Halved (info only)", nDuration = 1 }, bShowMsg);
				-- end
			-- end
		-- end
	-- end

	-- Check for death saves (based on option)
	-- if OptionsManager.isOption("HRST", "on") then
		-- local sClass, sRecord = DB.getValue(nodeEntry, "link");
		-- if (sClass == "charsheet") and ((sRecord or "") ~= "") then
			-- local nHP = DB.getValue(nodeEntry, "hptotal", 0);
			-- local nWounds = DB.getValue(nodeEntry, "wounds", 0);
			-- local nDeathSaveFail = DB.getValue(nodeEntry, "deathsavefail", 0);
			-- if (nHP > 0) and (nWounds >= nHP) and (nDeathSaveFail < 3) then
				-- local rActor = ActorManager.resolveActor(sRecord);
				-- if not EffectManager.hasCondition(rActor, "Stable") then
					-- ActionSave.performDeathRoll(nil, rActor, true);
				-- end
			-- end
		-- end
	-- end
end
function onTurnEnd(nodeEntry)
	EffectManager.removeCondition(ActorManager.resolveActor(nodeEntry), "Surprised");
end

--
-- ADD FUNCTIONS
--

function parseResistances(sResistances)
	local aResults = {};
	sResistances = sResistances:lower();

	for _,v in ipairs(StringManager.split(sResistances, ";\r\n", true)) do
		local aResistTypes = {};

		for _,v2 in ipairs(StringManager.split(v, ",", true)) do
			if StringManager.isWord(v2, DataCommon.dmgtypes) then
				table.insert(aResistTypes, v2);
			else
				local aResistWords = StringManager.parseWords(v2);

				local i = 1;
				while aResistWords[i] do
					if StringManager.isWord(aResistWords[i], DataCommon.dmgtypes) then
						table.insert(aResistTypes, aResistWords[i]);
					elseif StringManager.isWord(aResistWords[i], "cold-forged") and StringManager.isWord(aResistWords[i+1], "iron") then
						i = i + 1;
						table.insert(aResistTypes, "cold-forged iron");
					elseif StringManager.isWord(aResistWords[i], "from") and StringManager.isWord(aResistWords[i+1], "nonmagical") and StringManager.isWord(aResistWords[i+2], { "weapons", "attacks" }) then
						i = i + 2;
						table.insert(aResistTypes, "!magic");
					elseif StringManager.isWord(aResistWords[i], "that") and StringManager.isWord(aResistWords[i+1], "aren't") then
						i = i + 2;

						if StringManager.isWord(aResistWords[i], "silvered") then
							table.insert(aResistTypes, "!silver");
						elseif StringManager.isWord(aResistWords[i], "adamantine") then
							table.insert(aResistTypes, "!adamantine");
						elseif StringManager.isWord(aResistWords[i], "cold-forged") and StringManager.isWord(aResistWords[i+1], "iron") then
							i = i + 1;
							table.insert(aResistTypes, "!cold-forged iron");
						end
					end

					i = i + 1;
				end
			end
		end

		if #aResistTypes > 0 then
			table.insert(aResults, table.concat(aResistTypes, ", "));
		end
	end

	return aResults;
end

function onNPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Fill in spells
	CampaignDataManager2.updateNPCSpells(tCustom.nodeCT);
	CampaignDataManager2.resetNPCSpellcastingSlots(tCustom.nodeCT);

	-- Set current hit points
	local nHP = DB.getValue(tCustom.nodeRecord, "hp", 0);
	local sOptHRNH = OptionsManager.getOption("HRNH");
	if sOptHRNH == "max" then
		local sHD = CombatManager2.onNPCPostAddGetHDStringHelper(tCustom.nodeRecord);
		if sHD ~= "" then
			nHP = StringManager.evalDiceString(sHD, true, true);
		end
	elseif sOptHRNH == "random" then
		local sHD = CombatManager2.onNPCPostAddGetHDStringHelper(tCustom.nodeRecord);
		if sHD ~= "" then
			nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
		end
	end
	DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);

	-- Set initiative from Dexterity modifier
	local nDex = DB.getValue(tCustom.nodeRecord, "abilities.dexterity.score", 10);
	local nDexMod = math.floor((nDex - 10) / 2);
	local nMiscMod = DB.getValue(tCustom.nodeRecord, "initiative.misc", 0);
	DB.setValue(tCustom.nodeCT, "init", "number", nDexMod + nMiscMod);

	-- Decode traits and actions
	local tEffects = {};
	CombatManager2.parseNPCPowers(ActorManager.resolveActor(tCustom.nodeCT), tEffects);
	if #tEffects > 0 then
		EffectManager.addEffect("", "", tCustom.nodeCT, { sName = table.concat(tEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	CombatRecordManager.handleCombatAddInitDnD(tCustom);
end
function onNPCPostAddGetHDStringHelper(nodeRecord)
	local sHD = StringManager.trim(DB.getValue(nodeRecord, "hd", ""));
	if sHD == "" then
		return "";
	end

	local tSplitHD = StringManager.splitByPattern(sHD, "[();]+", true);
	local i = 1;
	while (i <= #tSplitHD) and (tSplitHD[i] == "") do
		i = i + 1;
	end
	return tSplitHD[i] or "";
end

function parseNPCPowers(rActor, tEffects)
	local nodeCT = ActorManager.getCTNode(rActor);
	if not nodeCT then
		return;
	end

	for _,v in ipairs(DB.getChildList(nodeCT, "actions")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "legendaryactions")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "lairactions")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "reactions")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "bonusactions")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "traits")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "innatespells")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects, true);
	end
	for _,v in ipairs(DB.getChildList(nodeCT, "spells")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects, true);
	end
end
function parseNPCPower(rActor, nodePower, tEffects, bAllowSpellDataOverride)
	if tEffects then
		CombatManager2.parseNPCPowerBuildEffects(nodePower, tEffects);
	end
	CombatManager2.parseNPCPowerBuildValue(nodePower, rActor, bAllowSpellDataOverride);
end
function parseNPCPowerBuildEffects(nodePower, tEffects)
	local sName = StringManager.simplify(DB.getValue(nodePower, "name", ""));
	if sName == "magicweapons" or sName == "hellishweapons" or sName == "angelicweapons" then
		table.insert(tEffects, "DMGTYPE: magic");
	elseif sName == "regeneration" then
		local sDesc = StringManager.trim(DB.getValue(nodePower, "desc", ""):lower());
		local tPowerWords = StringManager.parseWords(sDesc);

		local sRegenAmount = nil;
		local aRegenBlockTypes = {};
		local i = 1;
		while tPowerWords[i] do
			if StringManager.isWord(tPowerWords[i], "regains") and StringManager.isDiceString(tPowerWords[i+1]) then
				i = i + 1;
				sRegenAmount = tPowerWords[i];
			elseif StringManager.isWord(tPowerWords[i], "takes") then
				while tPowerWords[i+1] do
					if StringManager.isWord(tPowerWords[i+1], {"or"}) then
						-- SKIP
					elseif StringManager.isWord(tPowerWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenBlockTypes, tPowerWords[i+1]);
					elseif StringManager.isWord(tPowerWords[i+1], "cold-forged") and StringManager.isWord(tPowerWords[i+2], "iron") then
						table.insert(aRegenBlockTypes, "cold-forged iron");
					else
						break;
					end

					i = i + 1;
				end
			end

			i = i + 1;
		end

		if sRegenAmount then
			local sRegen = "REGEN: " .. sRegenAmount;
			if #aRegenBlockTypes > 0 then
				sRegen = sRegen .. " " .. table.concat(aRegenBlockTypes, ",");
				EffectManager.addEffect("", "", DB.getChild(nodePower, "..."), { sName = sRegen, nDuration = 0, nGMOnly = 1 }, false);
			else
				table.insert(tEffects, sRegen);
			end
		end
	elseif sName:match("^damagethreshold") then
		local sNumber = DB.getValue(nodePower, "desc", ""):match("%d+");
		if sNumber then
			table.insert(tEffects, "DT: " .. sNumber);
		end
	end
end
function parseNPCPowerBuildValue(nodePower, rActor, bAllowSpellDataOverride)
	local sDisplay = DB.getValue(nodePower, "name", "");
	local tDisplayOptions = {};

	local tAbilities = PowerManager.parseNPCPower(nodePower, bAllowSpellDataOverride);
	for _,v in ipairs(tAbilities) do
		PowerManager.evalAction(rActor, nodePower, v);
		if v.type == "attack" then
			if v.nomod then
				if v.range then
					table.insert(tDisplayOptions, string.format("[%s]", v.range));
				end
				if v.spell then
					table.insert(tDisplayOptions, "[ATK: SPELL]");
				elseif v.weapon then
					table.insert(tDisplayOptions, "[ATK: WEAPON]");
				else
					table.insert(tDisplayOptions, "[ATK]");
				end
			else
				if v.range then
					table.insert(tDisplayOptions, string.format("[%s]", v.range));
					if v.rangedist and v.rangedist ~= "5" then
						table.insert(tDisplayOptions, string.format("[RNG: %s]", v.rangedist));
					end
				end
				table.insert(tDisplayOptions, string.format("[ATK: %+d]", v.modifier or 0));
			end

		elseif v.type == "powersave" then
			local sSaveVs = string.format("[SAVEVS: %s", v.save);
			sSaveVs = sSaveVs .. " " .. (v.savemod or 0);
			if v.onmissdamage == "half" then
				sSaveVs = sSaveVs .. " (H)";
			end
			if v.magic then
				sSaveVs = sSaveVs .. " (magic)";
			end
			sSaveVs = sSaveVs .. "]";
			table.insert(tDisplayOptions, sSaveVs);

		elseif v.type == "damage" then
			local aDmgDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sDmg = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				if vClause.dmgtype and vClause.dmgtype ~= "" then
					sDmg = sDmg .. " " .. vClause.dmgtype;
				end
				table.insert(aDmgDisplay, sDmg);
			end
			table.insert(tDisplayOptions, string.format("[DMG: %s]", table.concat(aDmgDisplay, " + ")));

		elseif v.type == "heal" then
			local aHealDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sHeal = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				table.insert(aHealDisplay, sHeal);
			end

			local sHeal = table.concat(aHealDisplay, " + ");
			if v.subtype then
				sHeal = sHeal .. " " .. v.subtype;
			end

			table.insert(tDisplayOptions, string.format("[HEAL: %s]", sHeal));

		elseif v.type == "effect" then
			table.insert(tDisplayOptions, EffectManager5E.encodeEffectForCT(v));

		end
	end

	-- Remove melee / ranged attack in title
	sDisplay = sDisplay:gsub("^[Mm]elee attack%s*[-�]+%s*", "");
	sDisplay = sDisplay:gsub("^[Rr]anged attack%s*[-�]+%s*", "");
	sDisplay = StringManager.capitalize(sDisplay);

	-- Remove recharge in title, and move to details
	local sRecharge = sDisplay:match("[Rr]echarge (%d)");
	if sRecharge then
		sDisplay = sDisplay:gsub("%s?%([Rr]echarge %d[-�]*%d?%)", "");
		table.insert(tDisplayOptions, "[R:" .. sRecharge .. "]");
	end

	-- Set the value field to the short version
	if #tDisplayOptions > 0 then
		sDisplay = string.format("%s %s", sDisplay, table.concat(tDisplayOptions, " "));
	end
	DB.setValue(nodePower, "value", "string", sDisplay);
end

function onVehiclePostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	-- Set current hit points
	local nHP = DB.getValue(tCustom.nodeRecord, "hp", 0);
	DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);

	-- Set initiative from Dexterity modifier
	local nDex = DB.getValue(tCustom.nodeRecord, "abilities.dexterity.score", 10);
	local nDexMod = math.floor((nDex - 10) / 2);
	DB.setValue(tCustom.nodeCT, "init", "number", nDexMod);

	-- Track additional damage types and intrinsic effects
	local tEffects = {};

	-- Decode traits and actions
	local rActor = ActorManager.resolveActor(tCustom.nodeRecord);
	for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "traits")) do
		CombatManager2.parseNPCPower(rActor, v, tEffects);
	end
	for _,vComponent in ipairs(DB.getChildList(tCustom.nodeCT, "components")) do
		DB.setValue(vComponent, "locked", "number", 1);

		for _,v in ipairs(DB.getChildList(vComponent, "actions")) do
			CombatManager2.parseNPCPower(rActor, v, tEffects);

			local sValue = DB.getValue(v, "value", "");
			if sValue ~= "" then
				local nLoad = DB.getValue(v, "actions_load", 0);
				local nAim = DB.getValue(v, "actions_aim", 0);
				local nFire = DB.getValue(v, "actions_fire", 0);
				if (nLoad ~= 0) or (nAim ~= 0) or (nFire ~= 0) then
					sValue = string.format("%s (LAF:%d/%d/%d)", sValue, nLoad, nAim, nFire);
					DB.setValue(v, "value", "string", sValue);
				end
			end
		end
	end

	-- Add effects
	if #tEffects > 0 then
		EffectManager.addEffect("", "", tCustom.nodeCT, { sName = table.concat(tEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	CombatRecordManager.handleCombatAddInitDnD(tCustom);
end

--
-- PARSE CT ATTACK LINE
--

function parseAttackLine(sLine)
	local rPower = nil;

	local nIntroStart, nIntroEnd, sName = sLine:find("([^%[]*)[%[]?");
	if nIntroStart then
		rPower = {};
		rPower.name = PowerManager.cleanNPCPowerName(sName);
		rPower.aAbilities = {};
		nIndex = nIntroEnd;

		local nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nIntroEnd);
		while nAbilityStart do
			if sAbility == "M" or sAbility == "R" then
				rPower.range = sAbility;

			elseif sAbility:sub(1,4) == "ATK:" and #sAbility > 4 then
				local rAttack = {};
				rAttack.sType = "attack";
				rAttack.nStart = nAbilityStart + 1;
				rAttack.nEnd = nAbilityEnd;
				rAttack.label = rPower.name;
				rAttack.range = rPower.range;
				local sAttack, sCritRange = sAbility:sub(7):match("([+-]?%d+)%s*%((%d+)%)");
				if sAttack then
					rAttack.modifier = tonumber(sAttack) or 0;
					rAttack.nCritRange = tonumber(sCritRange) or 0;
					if rAttack.nCritRange < 2 or rAttack.nCritRange > 19 then
						rAttack.nCritRange = nil;
					end
				else
					rAttack.modifier = tonumber(sAbility:sub(5)) or 0;
				end
				table.insert(rPower.aAbilities, rAttack);

			elseif sAbility:sub(1,7) == "SAVEVS:" and #sAbility > 7 then
				local aWords = StringManager.parseWords(sAbility:sub(7));

				local rSave = {};
				rSave.sType = "powersave";
				rSave.nStart = nAbilityStart + 1;
				rSave.nEnd = nAbilityEnd;
				rSave.label = rPower.name;
				rSave.save = aWords[1];
				rSave.savemod = tonumber(aWords[2]) or 0;
				if StringManager.isWord(aWords[3], "H") then
					rSave.onmissdamage = "half";
				end
				if StringManager.isWord(aWords[3], "magic") or StringManager.isWord(aWords[4], "magic") then
					rSave.magic = true;
				end
				table.insert(rPower.aAbilities, rSave);

			elseif sAbility:sub(1,4) == "DMG:" and #sAbility > 4 then
				local rDamage = {};
				rDamage.sType = "damage";
				rDamage.nStart = nAbilityStart + 1;
				rDamage.nEnd = nAbilityEnd;
				rDamage.label = rPower.name;
				rDamage.range = rPower.range;
				rDamage.clauses = {};

				local tPowerWords = StringManager.parseWords(sAbility:sub(5));
				local i = 1;
				while tPowerWords[i] do
					if StringManager.isDiceString(tPowerWords[i]) then
						local aDmgDiceStr = {};
						table.insert(aDmgDiceStr, tPowerWords[i]);
						while StringManager.isDiceString(tPowerWords[i+1]) do
							table.insert(aDmgDiceStr, tPowerWords[i+1]);
							i = i + 1;
						end
						local aClause = {};
						aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aDmgDiceStr));

						local aDmgType = {};
						while tPowerWords[i+1] and not StringManager.isDiceString(tPowerWords[i+1]) and not StringManager.isWord(tPowerWords[i+1], {"and", "plus"}) do
							table.insert(aDmgType, tPowerWords[i+1]);
							i = i + 1;
						end
						aClause.dmgtype = table.concat(aDmgType, ",");

						table.insert(rDamage.clauses, aClause);
					end

					i = i + 1;
				end
				table.insert(rPower.aAbilities, rDamage);

			elseif sAbility:sub(1,5) == "HEAL:" and #sAbility > 5 then
				local rHeal = {};
				rHeal.sType = "heal";
				rHeal.nStart = nAbilityStart + 1;
				rHeal.nEnd = nAbilityEnd;
				rHeal.label = rPower.name;
				rHeal.clauses = {};

				local tPowerWords = StringManager.parseWords(sAbility:sub(6));
				local i = 1;
				local aHealDiceStr = {};
				while StringManager.isDiceString(tPowerWords[i]) do
					table.insert(aHealDiceStr, tPowerWords[i]);
					i = i + 1;
				end

				local aClause = {};
				aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aHealDiceStr));
				table.insert(rHeal.clauses, aClause);

				if StringManager.isWord(tPowerWords[i], "temp") then
					rHeal.subtype = "temp";
				end

				table.insert(rPower.aAbilities, rHeal);

			elseif sAbility:sub(1,4) == "EFF:" and #sAbility > 4 then
				local rEffect = EffectManager5E.decodeEffectFromCT(sAbility);
				if rEffect then
					rEffect.nStart = nAbilityStart + 1;
					rEffect.nEnd = nAbilityEnd;
					table.insert(rPower.aAbilities, rEffect);
				end

			elseif sAbility:sub(1,2) == "R:" and #sAbility == 3 then
				local rUsage = {};
				rUsage.sType = "usage";

				local nUsedStart, nUsedEnd, sUsage = string.find(sLine, "%[(USED)%]");
				if nUsedStart then
					rUsage.nStart = nUsedStart + 1;
					rUsage.nEnd = nUsedEnd;
				else
					rUsage.nStart = nAbilityStart + 1;
					rUsage.nEnd = nAbilityEnd;
					sUsage = sAbility;
				end
				table.insert(rPower.aAbilities, rUsage);

				rPower.sUsage = sUsage;
				rPower.nUsageStart = rUsage.nStart;
				rPower.nUsageEnd = rUsage.nEnd;
			end

			nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nAbilityEnd + 1);
		end
	end

	return rPower;
end

function onNPCSummonPowerDataChanged(nodeRecord)
	local rActor = ActorManager.resolveActor(nodeRecord);
	CombatManager2.parseNPCPowers(rActor);

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		DB.setValue(nodeCT, "hptotal", "number", DB.getValue(nodeCT, "hp", 0));
	end
end

--
-- RESET FUNCTIONS
--

function resetInit()
	function resetCombatantInit(nodeCT)
		DB.setValue(nodeCT, "initresult", "number", 0);
		DB.setValue(nodeCT, "reaction", "number", 0);
	end
	CombatManager.callForEachCombatant(CombatManager2.resetCombatantInit);
end

function resetHealth(nodeCT, bLong)
	if bLong then
		DB.setValue(nodeCT, "wounds", "number", 0);
		DB.setValue(nodeCT, "hptemp", "number", 0);
		DB.setValue(nodeCT, "deathsavesuccess", "number", 0);
		DB.setValue(nodeCT, "deathsavefail", "number", 0);

		local rActor = ActorManager.resolveActor(nodeCT);
		EffectManager.removeCondition(rActor, "Stable");
		EffectManager.removeCondition(rActor, "Unconscious");
		CombatManager2.reduceExhaustion(nodeCT);
	end
end
function reduceExhaustion(nodeCT)
	local nExhaustMod = EffectManager5E.getEffectsBonus(ActorManager.resolveActor(nodeCT), { "EXHAUSTION" }, true);
	if nExhaustMod > 0 then
		nExhaustMod = nExhaustMod - 1;
		EffectManager5E.removeEffectByType(nodeCT, "EXHAUSTION");
		if nExhaustMod > 0 then
			EffectManager.addEffect("", "", nodeCT, { sName = "EXHAUSTION: " .. nExhaustMod, nDuration = 0 }, false);
		end
	end
end

function clearExpiringEffects()
	local function checkEffectExpire(nodeEffect)
		local sLabel = DB.getValue(nodeEffect, "label", "");
		local nDuration = DB.getValue(nodeEffect, "duration", 0);

		if nDuration ~= 0 or sLabel == "" then
			DB.deleteNode(nodeEffect);
		end
	end
	CombatManager.callForEachCombatantEffect(checkEffectExpire);
end

function rest(bLong)
	CombatManager.resetInit();
	CombatManager2.clearExpiringEffects();

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local bHandled = false;
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				CharManager.rest(nodePC, bLong);
				bHandled = true;
			end
		end

		if not bHandled then
			CombatManager2.resetHealth(v, bLong);
		end
	end
end

--
-- INIT FUNCTIONS
--

function isInitSwapPlayerAllowed(nodeCT)
	if not CombatManager.isOwnedPlayerCT(nodeCT) then
		return false;
	end
	local _,sRecord = DB.getValue(nodeCT, "link", "", "");
	return CharManager.hasFeat2024(DB.findNode(sRecord), CharManager.FEAT_ALERT);
end

function rollInit(sType)
	CombatManager.rollTypeInit(sType, CombatManager2.rollEntryInit);
end
function rollEntryInit(nodeEntry)
	CombatManager.rollStandardEntryInit(CombatManager2.getEntryInitRecord(nodeEntry));
end
function getEntryInitRecord(nodeEntry)
	if not nodeEntry then
		return nil;
	end

	local tInit = { nodeEntry = nodeEntry };

	-- Start with the base initiative bonus
	tInit.nMod = DB.getValue(nodeEntry, "init", 0);

	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);
	local bEffects, aEffectDice, nEffectMod, bEffectADV, bEffectDIS = ActionInit.getEffectAdjustments(rActor);
	if bEffects then
		tInit.nMod = tInit.nMod + StringManager.evalDice(aEffectDice, nEffectMod);
		if bEffectADV then
			tInit.bADV = true;
		end
		if bEffectDIS then
			tInit.bDIS = true;
		end
	end

	tInit.fnRollRandom = CombatManager2.rollRandomInit;

	return tInit;
end
function rollRandomInit(tInit)
	local tSuffix = {};
	if (tInit.nMod or 0) ~= 0 then
		table.insert(tSuffix, string.format("(%+d)", tInit.nMod));
	end

	local nInitResult = math.random(20);
	if tInit.bADV and not tInit.bDIS then
		local nInitResult2 = math.random(20);
		table.insert(tSuffix, string.format("[ADV] (DROPPED %d)", math.min(nInitResult, nInitResult2)));
		nInitResult = math.max(nInitResult, nInitResult2);
	elseif tInit.bDIS and not tInit.bADV then
		local nInitResult2 = math.random(20);
		table.insert(tSuffix, string.format("[DIS] (DROPPED %d)", math.max(nInitResult, nInitResult2)));
		nInitResult = math.min(nInitResult, nInitResult2);
	end
	tInit.sSuffix = table.concat(tSuffix, " ");

	return nInitResult + (tInit.nMod or 0);
end

--
--	XP FUNCTIONS
--

function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	local nXP = 0;
	for _, vNPCItem in ipairs(DB.getChildList(nodeBattle, sTargetNPCList)) do
		local _,sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * DB.getValue(nodeNPC, "xp", 0));
			else
				local sMsg = string.format(Interface.getString("battle_error_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end
	end

	DB.setValue(nodeBattle, "exp", "number", nXP);
end
function calcBattleCR(nodeBattle)
	CombatManager2.calcBattleXP(nodeBattle);

	local nXP = DB.getValue(nodeBattle, "exp", 0);

	local sCR = "";
	if nXP > 0 then
		if nXP <= 10 then
			sCR = "0";
		elseif nXP <= 25 then
			sCR = "1/8";
		elseif nXP <= 50 then
			sCR = "1/4";
		elseif nXP <= 100 then
			sCR = "1/2";
		elseif nXP <= 200 then
			sCR = "1";
		elseif nXP <= 450 then
			sCR = "2";
		elseif nXP <= 700 then
			sCR = "3";
		elseif nXP <= 1100 then
			sCR = "4";
		elseif nXP <= 1800 then
			sCR = "5";
		elseif nXP <= 2300 then
			sCR = "6";
		elseif nXP <= 2900 then
			sCR = "7";
		elseif nXP <= 3900 then
			sCR = "8";
		elseif nXP <= 5000 then
			sCR = "9";
		elseif nXP <= 5900 then
			sCR = "10";
		elseif nXP <= 7200 then
			sCR = "11";
		elseif nXP <= 8400 then
			sCR = "12";
		elseif nXP <= 10000 then
			sCR = "13";
		elseif nXP <= 11500 then
			sCR = "14";
		elseif nXP <= 13000 then
			sCR = "15";
		elseif nXP <= 15000 then
			sCR = "16";
		elseif nXP <= 18000 then
			sCR = "17";
		elseif nXP <= 20000 then
			sCR = "18";
		elseif nXP <= 22000 then
			sCR = "19";
		elseif nXP <= 25000 then
			sCR = "20";
		elseif nXP <= 33000 then
			sCR = "21";
		elseif nXP <= 41000 then
			sCR = "22";
		elseif nXP <= 50000 then
			sCR = "23";
		elseif nXP <= 62000 then
			sCR = "24";
		elseif nXP <= 75000 then
			sCR = "25";
		elseif nXP <= 90000 then
			sCR = "26";
		elseif nXP <= 105000 then
			sCR = "27";
		elseif nXP <= 120000 then
			sCR = "28";
		elseif nXP <= 135000 then
			sCR = "29";
		elseif nXP <= 155000 then
			sCR = "30";
		else
			sCR = "31+";
		end
	end

	DB.setValue(nodeBattle, "cr", "string", sCR);
end

--
--	COMBAT ACTION FUNCTIONS
--

function addRightClickDiceToClauses(rRoll)
	if #rRoll.clauses > 0 then
		local nOrigDamageDice = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nOrigDamageDice = nOrigDamageDice + #vClause.dice;
		end
		if #rRoll.aDice > nOrigDamageDice then
			for i = nOrigDamageDice + 1,#rRoll.aDice do
				if type(rRoll.aDice[i]) == "table" then
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i].type);
				else
					table.insert(rRoll.clauses[1].dice, rRoll.aDice[i]);
				end
			end
		end
	end
end