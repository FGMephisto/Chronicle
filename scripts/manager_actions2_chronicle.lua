--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	GameManager.setFunction("onActionGetRoll", ActionsManager2.onActionGetRoll);
	GameManager.setMultiKeyFunction("onActionPostModRoll", "", ActionsManager2.onActionPostModRoll);
end

-- NOTE: Will only work for PC spell powers through linked actions
-- 			If handling any action queues other than PC spell or weapon powers (such any NPC rolls or non spell/weapon PC rolls),
--			then need to add action data to differentiate in original call and here
function onActionGetRoll(rActor, tActionData)
	if (tActionData.sType or "") == "" then
		return nil;
	end
	if ActorManager.isPC(rActor) then
		if tActionData.bPower then
			local nodePower = DB.getChild(tActionData.node, "...");
			local rAction = PowerManager.getPowerAction(tActionData.node, { rActor = rActor, });
			if not rAction then
				return nil;
			end
			rAction.tChoiceSelections = tActionData.tChoiceSelections;
			rAction.tActionTags = tActionData.tActionTags;
			PowerManager.evalAction(rActor, nodePower, rAction);
			if tActionData.sType == "cast" then
				return ActionCast.getRoll(rActor, rAction);
			elseif tActionData.sType == "attack" then
				return ActionAttack.getRoll(rActor, rAction);
			elseif tActionData.sType == "powersave" then
				return ActionPowerSave.getRoll(rActor, rAction);
			elseif tActionData.sType == "damage" then
				return ActionDamageD20.getRoll(rActor, rAction);
			elseif tActionData.sType == "heal" then
				return ActionHealD20.getRoll(rActor, rAction);
			elseif tActionData.sType == "effect" then
				return ActionEffect.getRoll(rActor, rAction);
			end
		elseif tActionData.bWeapon then
			if tActionData.sType == "attack" then
				local rAction = CharWeaponManager.buildAttackAction(rActor, tActionData.node);
				rAction.tChoiceSelections = tActionData.tChoiceSelections;
				return ActionAttack.getRoll(rActor, rAction);
			elseif tActionData.sType == "damage" then
				local rAction = CharWeaponManager.buildDamageAction(rActor, tActionData.node);
				rAction.tChoiceSelections = tActionData.tChoiceSelections;
				return ActionDamageD20.getRoll(rActor, rAction);
			end
		end
	end
	return nil;
end
function onActionPostModRoll(_, _, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);
end

function setupD20RollBuild(sType, rActor, bSecret)
	return {
		sType = sType,
		aDice = DiceRollManager.getActorDice({ "d20" }, rActor),
		nMod = 0,
		bSecret = bSecret,
		tNotifications = {},
	};
end
function finalizeD20RollBuild(rRoll)
	rRoll.sDesc = table.concat(rRoll.tNotifications, "\r");
	rRoll.tNotifications = nil;
end

function setupD20RollMod(rRoll)
	rRoll.tNotifications = {};

	rRoll.bEffects = false;
	rRoll.tEffectDice = {};
	rRoll.nEffectMod = 0;
end
function applyAbilityEffectsToD20RollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	local nBonusStat, nBonusEffects = ActorManagerD20.getAbilityEffectsBonus(rSource, rRoll.sAbility);
	ActionCore.applyModRollEffect(rRoll, nil, nBonusStat, nBonusEffects);
end
function applyExhaustionEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	local nExhaustLevel = ActorManager5E.getExhaustionLevel(rSource);
	if nExhaustLevel <= 0 then
		return;
	end

	if OptionsManager.isOption("HREX", "") then
		if OptionsManager.isOption("GAVE", "2024") then
			rRoll.bEffects = true;
			rRoll.nEffectMod = rRoll.nEffectMod - (2 * nExhaustLevel);
		else
			if StringManager.contains({ "attack", "save", "death", "death_auto", "concentration", "systemshock", }, rRoll.sType) then
				if nExhaustLevel > 2 then
					rRoll.bEffects = true;
					rRoll.bDIS = true;
				end
			elseif StringManager.contains({ "check", "skill", "init", }, rRoll.sType) then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			end
		end
	else
		local nLevelMod = tonumber(OptionsManager.getOption("HREX")) or 0;
		if nLevelMod ~= 0 then
			rRoll.bEffects = true;
			rRoll.nEffectMod = rRoll.nEffectMod + (nLevelMod * nExhaustLevel);
		end
	end
end
function finalizeEffectsToD20RollMod(rRoll)
	if rRoll.bReliable then
		table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
	end
end
function finalizeD20RollMod(rRoll)
	ActionD20.encodeAdvantage(rRoll);
end

function setupD20RollResolve(rRoll, rSource)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionD20.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);
end

function handleLuckTrait(rActor, rRoll)
	if not ActorManager5E.hasRollTrait(rActor, CharManager.TRAIT_LUCK) and not ActorManager5E.hasTrait(rActor, CharManager.TRAIT_LUCKY) then
		return;
	end

	if not ActionsManager2.handleSingleReroll(rRoll, 1, 1) then
		if (not rRoll.bADV and not rRoll.bDIS) or (rRoll.bADV and rRoll.bDIS) then
			return;
		end
		if not ActionsManager2.handleSingleReroll(rRoll, 2, 1) then
			if rRoll.sDesc:match(string.format("%%[%s%%]", Interface.getString("roll_msg_feat_elvenaccuracy"))) then
				if not ActionsManager2.handleSingleReroll(rRoll, 3, 1) then
					return;
				end
			end
			return;
		end
	end
	rRoll.sDesc = string.format("%s\r[%s]", rRoll.sDesc, Interface.getString("roll_msg_trait_luck"));
	rRoll.nTotal = ActionsManager.total(rRoll);
end
function handleReliable(_, rRoll)
	local bReliable = string.match(rRoll.sDesc or "", "%[" .. Interface.getString("roll_msg_feature_reliable") .. "%]");
	if not bReliable then
		return;
	end

	ActionCore.applyRollMinDie(rRoll, 1, 10);
	rRoll.nTotal = ActionsManager.total(rRoll);
end
function handleHealerFeat(rActor, rRoll)
	if not ActorManager5E.hasRollFeat2024(rActor, CharManager.FEAT_HEALER) then
		return;
	end

	rRoll.sDesc = string.format("%s\r[%s]", rRoll.sDesc, Interface.getString("roll_msg_feat_healer"));
	local nDice = #rRoll.aDice;
	for i = 1, nDice do
		ActionsManager2.handleSingleReroll(rRoll, i, 1);
	end
	rRoll.nTotal = ActionsManager.total(rRoll);
end
function handleElvenAccuracyFeatMod(rRoll, rActor)
	if not ActorManager5E.hasRollFeat2014(rActor, CharManager.FEAT_ELVEN_ACCURACY) then
		return;
	end
	if not rRoll.aDice[1] then
		return;
	end
	if rRoll.bDIS or not rRoll.bADV then
		return;
	end
	local sAbility = rRoll.sAbility;
	if not sAbility then
		if rRoll.sRange == "R" then
			sAbility = "dexterity";
		else
			sAbility = "strength";
		end
	end
	if not StringManager.contains({ "dexterity", "intelligence", "wisdom", "charisma", }, sAbility) then
		return;
	end
	table.insert(rRoll.aDice, 2, UtilityManager.copyDeep(rRoll.aDice[1]));
	rRoll.aDice.expr = nil;
	rRoll.sDesc = string.format("%s\r[%s]", rRoll.sDesc, Interface.getString("roll_msg_feat_elvenaccuracy"));
end
function handleElvenAccuracyFeatResolve(rRoll)
	if not rRoll then
		return;
	end
	if not rRoll.sDesc:match(string.format("%%[%s%%]", Interface.getString("roll_msg_feat_elvenaccuracy"))) then
		return;
	end
	if #(rRoll.aDice) < 3 then
		return;
	end

	if rRoll.aDice[1].result < rRoll.aDice[3].result then
		local tTemp = rRoll.aDice[1];
		rRoll.aDice[1] = rRoll.aDice[3];
		rRoll.aDice[3] = tTemp;
		rRoll.aDice[3].type = "d" .. string.sub(rRoll.aDice[3].type, 2);
	end
	local nDroppedDie = rRoll.aDice[3].result;
	rRoll.aDice[1].type = "g" .. string.sub(rRoll.aDice[1].type, 2);
	rRoll.aDice[1].value = nil;
	rRoll.aDice[3].value = nil;
	rRoll.aDice[3].dropped = true;
	rRoll.aDice[3].backcolor = "80808080";
	rRoll.aDice[3].iconcolor = "80FFFFFF";
	rRoll.aDice.expr = nil;
	rRoll.sDesc = rRoll.sDesc .. "\r[DROPPED " .. nDroppedDie .. "]";

	rRoll.nTotal = ActionsManager.total(rRoll);
end

function handleSingleReroll(rRoll, kDie, nTriggerLow)
	if not rRoll or not rRoll.aDice then
		return false;
	end
	local tDie = rRoll.aDice[kDie];
	if not tDie then
		return false;
	end

	local sSign,_,sDieSides = tDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
	if not sDieSides or (sDieSides == "F") or (sSign == "-") then
		return false;
	end
	local nDieSides = tonumber(sDieSides) or 0;
	if nDieSides < 2 then
		return false;
	end

	local nTriggerLow = tonumber(nTriggerLow) or 0;
	if (nTriggerLow < 1) or (tDie.result > nTriggerLow) then
		return false;
	end

	rRoll.sDesc = string.format("%s\r[REROLL D%d=%d]", rRoll.sDesc, kDie, tDie.result);

	local tDroppedDie = UtilityManager.copyDeep(tDie);
	tDroppedDie.type = "d" .. string.sub(tDroppedDie.type, 2);
	tDroppedDie.value = nil;
	tDroppedDie.dropped = true;
	tDroppedDie.backcolor = "80808080";
	tDroppedDie.iconcolor = "80FFFFFF";
	table.insert(rRoll.aDice, tDroppedDie);

	tDie.result = math.random(nDieSides);
	tDie.value = nil;
	return true;
end

--
-- CHRONICLE CUSTOM SYSTEMS
--

function encodeDesktopMods(rRoll)
	local aAddDesc = {};
	local nAddTest = 0;
	local nAddBonus = 0;
	local nAddPenalty = 0;

	-- Process Test dice modifiers
	if ModifierManager.getKey("PLUS1") then
		nAddTest = nAddTest + 1;
	end
	if ModifierManager.getKey("PLUS2") then
		nAddTest = nAddTest + 2;
	end
	if ModifierManager.getKey("PLUS4") then
		nAddTest = nAddTest + 4;
	end

	-- If Test dice are selected, process them
	if nAddTest > 0 then
		rRoll.nTest = (rRoll.nTest or 0) + nAddTest;
		table.insert(aAddDesc, "[+" .. nAddTest .. "D] ");
		if not rRoll.aDice then
			rRoll.aDice = {};
		end
		for i = 1, nAddTest do
			table.insert(rRoll.aDice, {type = "d6"});
		end
	end

	-- Process Bonus dice modifiers
	if ModifierManager.getKey("BONUS1") then
		nAddBonus = nAddBonus + 1;
	end
	if ModifierManager.getKey("BONUS2") then
		nAddBonus = nAddBonus + 2;
	end
	if ModifierManager.getKey("BONUS4") then
		nAddBonus = nAddBonus + 4;
	end

	-- If Bonus dice are selected, process them
	if nAddBonus > 0 then
		rRoll.nBonus = (rRoll.nBonus or 0) + nAddBonus;
		table.insert(aAddDesc, "[+" .. nAddBonus .. "B] ");
		if not rRoll.aDice then
			rRoll.aDice = {};
		end
		for i = 1, nAddBonus do
			table.insert(rRoll.aDice, {type = "d6"});
		end
	end

	-- Process Penalty dice modifiers
	if ModifierManager.getKey("MINUS1") then
		nAddPenalty = nAddPenalty + 1;
	end
	if ModifierManager.getKey("MINUS2") then
		nAddPenalty = nAddPenalty + 2;
	end
	if ModifierManager.getKey("MINUS4") then
		nAddPenalty = nAddPenalty + 4;
	end

	-- If Penalty dice are selected, process them
	if nAddPenalty > 0 then
		rRoll.nPenalty = (rRoll.nPenalty or 0) + nAddPenalty;
		table.insert(aAddDesc, "[-" .. nAddPenalty .. "P] ");
	end

	-- Standard flat modifier desktop buttons (+2, -2, +5, -5) if applied to non-Chronicle D20 rolls
	local nMod = 0;
	if ModifierManager.getKey("PLUS5") then
		nMod = nMod + 5;
	end
	if ModifierManager.getKey("MINUS5") then
		nMod = nMod - 5;
	end
	if nMod ~= 0 then
		table.insert(aAddDesc, string.format("[%+d] ", nMod));
		rRoll.nMod = (rRoll.nMod or 0) + nMod;
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = (rRoll.sDesc or "") .. "\n" .. table.concat(aAddDesc);
	end
end

function encodeAdvantage(rRoll, bADV, bDIS)
	local bButtonADV = ModifierManager.getKey("ADV");
	local bButtonDIS = ModifierManager.getKey("DIS");
	if bButtonADV then
		bADV = true;
	end
	if bButtonDIS then
		bDIS = true;
	end

	if bADV then
		rRoll.sDesc = (rRoll.sDesc or "") .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = (rRoll.sDesc or "") .. " [DIS]";
	end
	if (bADV and not bDIS) or (bDIS and not bADV) then
		table.insert(rRoll.aDice, 2, "d20");
		rRoll.aDice.expr = nil;
	end
end

function decodeAdvantage(rRoll)
	local bADV = string.match(rRoll.sDesc or "", "%[ADV%]");
	local bDIS = string.match(rRoll.sDesc or "", "%[DIS%]");
	if (bADV and not bDIS) or (bDIS and not bADV) then
		if #(rRoll.aDice) > 1 then
			local nDecodeDie;
			local nDroppedDie;
			if (bADV and not bDIS) then
				nDecodeDie = math.max(rRoll.aDice[1].result, rRoll.aDice[2].result);
				nDroppedDie = math.min(rRoll.aDice[1].result, rRoll.aDice[2].result);
				rRoll.aDice[1].type = "g" .. string.sub(rRoll.aDice[1].type, 2);
			else
				nDecodeDie = math.min(rRoll.aDice[1].result, rRoll.aDice[2].result);
				nDroppedDie = math.max(rRoll.aDice[1].result, rRoll.aDice[2].result);
				rRoll.aDice[1].type = "r" .. string.sub(rRoll.aDice[1].type, 2);
			end
			rRoll.aDice[1].result = nDecodeDie;
			rRoll.aDice[1].value = nil;
			table.remove(rRoll.aDice, 2);
			rRoll.aDice.expr = nil;
			rRoll.sDesc = rRoll.sDesc .. " [DROPPED " .. nDroppedDie .. "]";
		end
	end
end

function encodeHealthMods(rActor, rRoll)
	local aAddDesc = {};

	-- Failsafe
	if not rActor then
		return;
	end

	-- Consider Wounds
	local nTrauma = ActorManager5E.getHealthTrauma(rActor);
	if nTrauma > 0 then
		rRoll.nPenalty = (rRoll.nPenalty or 0) + nTrauma;
		table.insert(aAddDesc, "[Wounded -" .. nTrauma .. "P] ");
	end

	-- Consider Injuries
	local nInjuries = ActorManager5E.getHealthInjuries(rActor);
	if nInjuries > 0 then
		rRoll.nMod = (rRoll.nMod or 0) - nInjuries;
		table.insert(aAddDesc, "[Injured -" .. nInjuries .. "] ");
	end

	-- Consider Fatigue
	local nFatigue = ActorManager5E.getHealthFatigue(rActor);
	if nFatigue > 0 then
		rRoll.nMod = (rRoll.nMod or 0) - nFatigue;
		table.insert(aAddDesc, "[Fatigued -" .. nFatigue .. "] ");
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = (rRoll.sDesc or "") .. "\n" .. table.concat(aAddDesc);
	end
end

function encodeArmorMods(rRoll)
	local aAddDesc = {};

	if StringManager.contains({ "agility" }, rRoll.sStat) then
		-- Process Armor Penalty
		local nAP = tonumber(rRoll.nAP) or 0;
		if nAP > 0 then
			rRoll.nMod = (rRoll.nMod or 0) - nAP;
			table.insert(aAddDesc, "[Armor Penalty -" .. nAP .. "] ");
		end

		-- Concatenate description strings and add to rRoll.sDesc
		if #aAddDesc > 0 then
			rRoll.sDesc = (rRoll.sDesc or "") .. "\n" .. table.concat(aAddDesc);
		end
	end
end

function ConvertToTechnical(sInput)
	local sOutput = (sInput or ""):gsub("%s+", ""):lower();
	return sOutput;
end