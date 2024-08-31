-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncDnD);

	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomCombatReset(resetInit);

	CombatRecordManager.addStandardVehicleCombatRecordType();

	ActorCommonManager.setDefaultSpaceReachFromActorSizeKey("5E");
	ActorCommonManager.setRecordTypeSpaceReachCallback("charsheet", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("vehicle", ActorCommonManager.getSpaceReachFromSizeFieldCore);
	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
	CombatRecordManager.setRecordTypePostAddCallback("vehicle", onVehiclePostAdd);
end

--
-- TURN FUNCTIONS
--

function onRoundStart(nCurrent)
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
	
	-- Check for death saves (based on option)
	-- if OptionsManager.isOption("HRST", "on") then
		-- if nodeEntry then
			-- local sClass, sRecord = DB.getValue(nodeEntry, "link");
			-- if sClass == "charsheet" and sRecord then
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
	-- end
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
	-- CampaignDataManager2.updateNPCSpells(tCustom.nodeCT);
	-- CampaignDataManager2.resetNPCSpellcastingSlots(tCustom.nodeCT);
	-- Set current hit points
	local nHP = DB.getValue(tCustom.nodeRecord, "hp", 0);
	-- local sOptHRNH = OptionsManager.getOption("HRNH");
	-- if sOptHRNH == "max" then
		-- local sHD = CombatManager2.onNPCPostAddGetHDStringHelper(tCustom.nodeRecord);
		-- if sHD ~= "" then
			-- nHP = StringManager.evalDiceString(sHD, true, true);
		-- end
	-- elseif sOptHRNH == "random" then
		-- local sHD = CombatManager2.onNPCPostAddGetHDStringHelper(tCustom.nodeRecord);
		-- if sHD ~= "" then
			-- nHP = math.max(StringManager.evalDiceString(sHD, true), 1);
		-- end
	-- end
	DB.setValue(tCustom.nodeCT, "hptotal", "number", nHP);
	
	-- Set initiative from Dexterity modifier
	-- local nDex = DB.getValue(tCustom.nodeRecord, "abilities.dexterity.score", 10);
	-- local nDexMod = math.floor((nDex - 10) / 2);
	-- DB.setValue(tCustom.nodeCT, "init", "number", nDexMod);
	
	-- Track additional damage types and intrinsic effects
	-- local aEffects = {};
	
	-- Decode traits and actions
	-- local rActor = ActorManager.resolveActor(tCustom.nodeRecord);
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "actions")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "legendaryactions")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "lairactions")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "reactions")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "bonusactions")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "traits")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "innatespells")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects, true);
	-- end
	-- for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "spells")) do
		-- CombatManager2.parseNPCPower(rActor, v, aEffects, true);
	-- end

	-- Add special effects
	if #aEffects > 0 then
		EffectManager.addEffect("", "", tCustom.nodeCT, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	CombatManager2.handleCombatAddInitChronicle(tCustom);
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

function parseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	local sDisplay = DB.getValue(nodePower, "name", "");
	local aDisplayOptions = {};
	
	local sName = StringManager.trim(sDisplay:lower());
	if sName == "avoidance" then
		table.insert(aEffects, "Avoidance");
	elseif sName == "evasion" then
		table.insert(aEffects, "Evasion");
	elseif sName == "magic resistance" then
		table.insert(aEffects, "Magic Resistance");
	elseif sName == "gnome cunning" then
		table.insert(aEffects, "Gnome Cunning");
	elseif sName == "magic weapons" or sName == "hellish weapons" or sName == "angelic weapons" then
		table.insert(aEffects, "DMGTYPE: magic");
	elseif sName == "improved critical" then
		table.insert(aEffects, "CRIT: 19");
	elseif sName == "superior critical" then
		table.insert(aEffects, "CRIT: 18");
	elseif sName == "regeneration" then
		local sDesc = StringManager.trim(DB.getValue(nodePower, "desc", ""):lower());
		local aPowerWords = StringManager.parseWords(sDesc);
		
		local sRegenAmount = nil;
		local aRegenBlockTypes = {};
		local i = 1;
		while aPowerWords[i] do
			if StringManager.isWord(aPowerWords[i], "regains") and StringManager.isDiceString(aPowerWords[i+1]) then
				i = i + 1;
				sRegenAmount = aPowerWords[i];
			elseif StringManager.isWord(aPowerWords[i], "takes") then
				while aPowerWords[i+1] do
					if StringManager.isWord(aPowerWords[i+1], {"or"}) then
						-- SKIP
					elseif StringManager.isWord(aPowerWords[i+1], DataCommon.dmgtypes) then
						table.insert(aRegenBlockTypes, aPowerWords[i+1]);
					elseif StringManager.isWord(aPowerWords[i+1], "cold-forged") and StringManager.isWord(aPowerWords[i+2], "iron") then
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
				table.insert(aEffects, sRegen);
			end
		end
	elseif sName:match("^damage threshold") then
		local sNumber = DB.getValue(nodePower, "desc", ""):match("%d+");
		if sNumber then
			table.insert(aEffects, "DT: " .. sNumber);
		end
	-- Handle all the other traits and actions (i.e. look for recharge, attacks, damage, saves, reach, etc.)
	else
		local aAbilities = PowerManager.parseNPCPower(nodePower, bAllowSpellDataOverride);
		for _,v in ipairs(aAbilities) do
			PowerManager.evalAction(rActor, nodePower, v);
			if v.type == "attack" then
				if v.nomod then
					if v.range then
						table.insert(aDisplayOptions, string.format("[%s]", v.range));
					end
					if v.spell then
						table.insert(aDisplayOptions, "[ATK: SPELL]");
					elseif v.weapon then
						table.insert(aDisplayOptions, "[ATK: WEAPON]");
					else
						table.insert(aDisplayOptions, "[ATK]");
					end
				else
					if v.range then
						table.insert(aDisplayOptions, string.format("[%s]", v.range));
						if v.rangedist and v.rangedist ~= "5" then
							table.insert(aDisplayOptions, string.format("[RNG: %s]", v.rangedist));
						end
					end
					table.insert(aDisplayOptions, string.format("[ATK: %+d]", v.modifier or 0));
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
				table.insert(aDisplayOptions, sSaveVs);
			
			elseif v.type == "damage" then
				local aDmgDisplay = {};
				for _,vClause in ipairs(v.clauses) do
					local sDmg = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
					if vClause.dmgtype and vClause.dmgtype ~= "" then
						sDmg = sDmg .. " " .. vClause.dmgtype;
					end
					table.insert(aDmgDisplay, sDmg);
				end
				table.insert(aDisplayOptions, string.format("[DMG: %s]", table.concat(aDmgDisplay, " + ")));
				
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
				
				table.insert(aDisplayOptions, string.format("[HEAL: %s]", sHeal));
			
			elseif v.type == "effect" then
				table.insert(aDisplayOptions, EffectManager5E.encodeEffectForCT(v));
			
			end
		end

		-- Remove melee / ranged attack in title
		sDisplay = sName:gsub("^[Mm]elee attack%s*[-–]+%s*", "");
		sDisplay = sDisplay:gsub("^[Rr]anged attack%s*[-–]+%s*", "");
		sDisplay = StringManager.capitalize(sDisplay);

		-- Remove recharge in title, and move to details
		local sRecharge = string.match(sName, "recharge (%d)");
		if sRecharge then
			sDisplay = string.gsub(sDisplay, "%s?%([Rr]echarge %d[-–]*%d?%)", "");
			table.insert(aDisplayOptions, "[R:" .. sRecharge .. "]");
		end
	end
	
	-- Set the value field to the short version
	if #aDisplayOptions > 0 then
		sDisplay = sDisplay .. " " .. table.concat(aDisplayOptions, " ");
	end
	DB.setValue(nodePower, "value", "string", sDisplay);
end

--
-- Adjusted
--
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
	local aEffects = {};
	
	-- Decode traits and actions
	local rActor = ActorManager.resolveActor(tCustom.nodeRecord);
	for _,v in ipairs(DB.getChildList(tCustom.nodeCT, "traits")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end
	for _,vComponent in ipairs(DB.getChildList(tCustom.nodeCT, "components")) do
		DB.setValue(vComponent, "locked", "number", 1);
		
		for _,v in ipairs(DB.getChildList(vComponent, "actions")) do
			CombatManager2.parseNPCPower(rActor, v, aEffects);

			local sValue = DB.getValue(v, "value", "");
			if sValue ~= "" then
				local tActions = {};
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
	if #aEffects > 0 then
		EffectManager.addEffect("", "", tCustom.nodeCT, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	CombatManager2.handleCombatAddInitChronicle(tCustom);
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
				
				local aPowerWords = StringManager.parseWords(sAbility:sub(5));
				local i = 1;
				while aPowerWords[i] do
					if StringManager.isDiceString(aPowerWords[i]) then
						local aDmgDiceStr = {};
						table.insert(aDmgDiceStr, aPowerWords[i]);
						while StringManager.isDiceString(aPowerWords[i+1]) do
							table.insert(aDmgDiceStr, aPowerWords[i+1]);
							i = i + 1;
						end
						local aClause = {};
						aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aDmgDiceStr));
						
						local aDmgType = {};
						while aPowerWords[i+1] and not StringManager.isDiceString(aPowerWords[i+1]) and not StringManager.isWord(aPowerWords[i+1], {"and", "plus"}) do
							table.insert(aDmgType, aPowerWords[i+1]);
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

				local aPowerWords = StringManager.parseWords(sAbility:sub(6));
				local i = 1;
				local aHealDiceStr = {};
				while StringManager.isDiceString(aPowerWords[i]) do
					table.insert(aHealDiceStr, aPowerWords[i]);
					i = i + 1;
				end

				local aClause = {};
				aClause.dice, aClause.modifier = StringManager.convertStringToDice(table.concat(aHealDiceStr));
				table.insert(rHeal.clauses, aClause);
				
				if StringManager.isWord(aPowerWords[i], "temp") then
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

				local nUsedStart, nUsedEnd, sUsage = string.find(sLine, "%[(USED)%]", nIndex);
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

--
-- RESET FUNCTIONS
--

function resetInit()
	function resetCombatantInit(nodeCT)
		DB.setValue(nodeCT, "initresult", "number", 0);
		DB.setValue(nodeCT, "reaction", "number", 0);
	end
	CombatManager.callForEachCombatant(resetCombatantInit);
end

--
-- Adjusted
--
function resetHealth(nodeCT, bLong)
	if bLong then
		DB.setValue(nodeCT, "wounds", "number", 0);
		-- DB.setValue(nodeCT, "hptemp", "number", 0);
		-- DB.setValue(nodeCT, "deathsavesuccess", "number", 0);
		-- DB.setValue(nodeCT, "deathsavefail", "number", 0);
		
		local rActor = ActorManager.resolveActor(nodeCT);
		EffectManager.removeCondition(rActor, "Stable");
		EffectManager.removeCondition(rActor, "Unconscious");
		-- CombatManager2.reduceExhaustion(nodeCT);
	end
end
function reduceExhaustion(nodeCT)
	local nExhaustMod = EffectManager5E.getEffectsBonus(ActorManager.resolveActor(nodeCT), {"EXHAUSTION"}, true);
	if nExhaustMod > 0 then
		nExhaustMod = nExhaustMod - 1;
		EffectManager5E.removeEffectByType(nodeCT, "EXHAUSTION");
		if nExhaustMod > 0 then
			EffectManager.addEffect("", "", nodeCT, { sName = "EXHAUSTION: " .. nExhaustMod, nDuration = 0 }, false);
		end
	end
end

function clearExpiringEffects()
	function checkEffectExpire(nodeEffect)
		local sLabel = DB.getValue(nodeEffect, "label", "");
		local nDuration = DB.getValue(nodeEffect, "duration", 0);
		local sApply = DB.getValue(nodeEffect, "apply", "");
		
		if nDuration ~= 0 or sApply ~= "" or sLabel == "" then
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
	local nInitResult = math.random(20);
	if tInit.bADV and not tInit.bDIS then
		nInitResult = math.max(nInitResult, math.random(20));
	elseif tInit.bDIS and not tInit.bADV then
		nInitResult = math.min(nInitResult, math.random(20));
	end
	return nInitResult + (tInit.nMod or 0);
end

--
--	XP FUNCTIONS
--

function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";

	local nXP = 0;
	for _, vNPCItem in ipairs(DB.getChildList(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * DB.getValue(nodeNPC, "xp", 0));
			else
				local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
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
			local v = rRoll.clauses[#rRoll.clauses].dice;
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

--
-- Added
--
function handleCombatAddInitChronicle(tCustom)
	ActionInit.performRoll(draginfo, tCustom.nodeCT, true);
end																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																			   