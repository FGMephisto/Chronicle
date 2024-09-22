-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Process modifiers added on the desktop via buttons
function encodeDesktopMods(rRoll)
	local aAddDesc = {}
	local nAddTest = 0
	local nAddBonus = 0
	local nAddPenalty = 0

	-- Process Test dice modifiers
	if ModifierManager.getKey("PLUS1") then
		nAddTest = nAddTest + 1
	end

	if ModifierManager.getKey("PLUS2") then
		nAddTest = nAddTest + 2
	end

	if ModifierManager.getKey("PLUS4") then
		nAddTest = nAddTest + 4
	end

	-- If Test dice are selected, process them
	if nAddTest > 0 then
		rRoll.nTest = rRoll.nTest + nAddTest
		table.insert(aAddDesc, "[+" .. nAddTest .. "D] ")
		for i = 1, nAddTest do
			table.insert(rRoll.aDice, {type = "d6"})
		end
	end

	-- Process Bonus dice modifiers
	if ModifierManager.getKey("BONUS1") then
		nAddBonus = nAddBonus + 1
	end

	if ModifierManager.getKey("BONUS2") then
		nAddBonus = nAddBonus + 2
	end

	if ModifierManager.getKey("BONUS4") then
		nAddBonus = nAddBonus + 4
	end

	-- If Bonus dice are selected, process them
	if nAddBonus > 0 then
		rRoll.nBonus = rRoll.nBonus + nAddBonus
		table.insert(aAddDesc, "[+" .. nAddBonus .. "B] ")
		for i = 1, nAddBonus do
			table.insert(rRoll.aDice, {type = "d6"})
		end

	end

	-- Process Penalty dice modifiers
	if ModifierManager.getKey("MINUS1") then
		nAddPenalty = nAddPenalty + 1
	end

	if ModifierManager.getKey("MINUS2") then
		nAddPenalty = nAddPenalty + 2
	end

	if ModifierManager.getKey("MINUS4") then
		nAddPenalty = nAddPenalty + 4
	end

	-- If Penalty dice are selected, process them
	if nAddPenalty > 0 then
		rRoll.nPenalty = rRoll.nPenalty + nAddPenalty
		table.insert(aAddDesc, "[-" .. nAddPenalty .. "P] ")
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
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
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	if (bADV and not bDIS) or (bDIS and not bADV) then
		table.insert(rRoll.aDice, 2, "d20");
		rRoll.aDice.expr = nil;
	end
end
function decodeAdvantage(rRoll)
	local bADV = string.match(rRoll.sDesc, "%[ADV%]");
	local bDIS = string.match(rRoll.sDesc, "%[DIS%]");
	if (bADV and not bDIS) or (bDIS and not bADV) then
		if #(rRoll.aDice) > 1 then
			local nDecodeDie;
			if (bADV and not bDIS) then
				if rRoll.aDice[1].result < rRoll.aDice[2].result then
					local tTemp = rRoll.aDice[1];
					rRoll.aDice[1] = rRoll.aDice[2];
					rRoll.aDice[2] = tTemp;
				end
				nDroppedDie = rRoll.aDice[2].result;
				rRoll.aDice[1].type = "g" .. string.sub(rRoll.aDice[1].type, 2);
			else
				if rRoll.aDice[1].result > rRoll.aDice[2].result then
					local tTemp = rRoll.aDice[1];
					rRoll.aDice[1] = rRoll.aDice[2];
					rRoll.aDice[2] = tTemp;
				end
				nDroppedDie = rRoll.aDice[2].result;
				rRoll.aDice[1].type = "r" .. string.sub(rRoll.aDice[1].type, 2);
			end
			rRoll.aDice[1].value = nil;
			rRoll.aDice[2].value = nil;
			rRoll.aDice[2].dropped = true;
			rRoll.aDice[2].backcolor = "80808080";
			rRoll.aDice[2].iconcolor = "80FFFFFF";
			rRoll.aDice.expr = nil;
			rRoll.sDesc = rRoll.sDesc .. " [DROPPED " .. nDroppedDie .. "]";
		end
	end	
end

function applyGeneralRollModifiers(rRoll)
	local bMax = rRoll.sDesc:match("%[MAX%]");
	if bMax then
		local nDice = #rRoll.aDice;
		for i = 1, nDice do
			ActionsManager2.helperHandleMax(rRoll, i);
		end
		return;
	end

	local sMinValue = rRoll.sDesc:match("%[MIN (%d+)%]");
	if sMinValue then
		local nMinValue = tonumber(sMinValue) or 0;
		local nDice = #rRoll.aDice;
		for i = 1, nDice do
			ActionsManager2.helperHandleMinValue(rRoll, i, nMinValue);
		end
	end
end

function handleLuckTrait(rActor, rRoll)
	if not ActorManager.isPC(rActor) then
		return;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not CharManager.hasTrait(nodeActor, CharManager.TRAIT_LUCK) and not CharManager.hasTrait(nodeActor, CharManager.TRAIT_LUCKY) then
		return;
	end

	if not ActionsManager2.helperHandleSingleReroll(rRoll, 1, 1) then
		local bADV = rRoll.sDesc:match("%[ADV%]");
		local bDIS = rRoll.sDesc:match("%[DIS%]");
		if (not bADV and not bDIS) or (bADV and bDIS) then
			return;
		end
		if not ActionsManager2.helperHandleSingleReroll(rRoll, 2, 1) then
			return;
		end
	end
	rRoll.sDesc = string.format("%s [%s]", rRoll.sDesc, Interface.getString("roll_msg_trait_luck"));
end
function handleReliable(rActor, rRoll)
	local bReliable = string.match(rRoll.sDesc or "", "%[" .. Interface.getString("roll_msg_feature_reliable") .. "%]");
	if not bReliable then
		return;
	end

	ActionsManager2.helperHandleMinValue(rRoll, 1, 10);
end
function handleHealerFeat(rActor, rRoll)
	if not ActorManager.isPC(rActor) then
		return;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not CharManager.hasFeat2024(nodeActor, CharManager.FEAT_HEALER) then
		return;
	end

	local nDice = #rRoll.aDice;
	for i = 1, nDice do
		ActionsManager2.helperHandleSingleReroll(rRoll, i, 1);
	end
	rRoll.sDesc = string.format("%s [%s]", rRoll.sDesc, Interface.getString("roll_msg_feat_healer"));
end

function helperHandleMax(rRoll, kDie)
	if not rRoll or not rRoll.aDice then
		return false;
	end
	local tDie = rRoll.aDice[kDie];
	if not tDie then
		return false;
	end
	local sSign, sColor, sDieSides = tDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
	if not sDieSides or (sSign == "-") then
		return false;
	end

	local nResult;
	if sDieSides == "F" then
		nResult = 1;
	else
		nResult = tonumber(sDieSides) or 0;
	end

	if nResult == tDie.result then
		return false;
	end
	
	tDie.result = nResult;
	tDie.value = nil;
	return true;
end
function helperHandleMinValue(rRoll, kDie, nMinValue)
	if not rRoll or not rRoll.aDice then
		return false;
	end
	local tDie = rRoll.aDice[kDie];
	if not tDie then
		return false;
	end

	local sSign, sColor, sDieSides = tDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
	if not sDieSides or (sDieSides == "F") or (sSign == "-") then
		return false;
	end
	local nDieSides = tonumber(sDieSides) or 0;
	if nDieSides < 2 then
		return false;
	end

	local nMinValue = tonumber(nMinValue) or 0;
	if (nMinValue < 2) or (tDie.result >= nMinValue) then
		return false;
	end

	rRoll.sDesc = string.format("%s [DROPPED D%d=%d]", rRoll.sDesc, kDie, tDie.result);

	local tDroppedDie = UtilityManager.copyDeep(tDie);
	tDroppedDie.type = "d" .. string.sub(tDroppedDie.type, 2);
	tDroppedDie.value = nil;
	tDroppedDie.dropped = true;
	tDroppedDie.backcolor = "80808080";
	tDroppedDie.iconcolor = "80FFFFFF";
	table.insert(rRoll.aDice, tDroppedDie);

	tDie.result = nMinValue;
	tDie.value = nil;
	return true;
end
function helperHandleSingleReroll(rRoll, kDie, nTriggerLow)
	if not rRoll or not rRoll.aDice then
		return false;
	end
	local tDie = rRoll.aDice[kDie];
	if not tDie then
		return false;
	end

	local sSign, sColor, sDieSides = tDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
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

	rRoll.sDesc = string.format("%s [REROLL D%d=%d]", rRoll.sDesc, kDie, tDie.result);

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

-- Added
-- Process modifiers resulting from wounds, injuries or fatigue
function encodeHealthMods(rActor, rRoll)
	local aAddDesc = {}

	-- Failsafe
	if not rActor then
		return
	end

	-- Consider Wounds
	local nTrauma = ActorManager5E.getHealthTrauma(rActor)
	if nTrauma > 0 then
		rRoll.nPenalty = rRoll.nPenalty + nTrauma
		table.insert(aAddDesc, "[Wounded -" .. nTrauma .. "P] ")
	end

	-- Consider Injuries
	local nInjuries = ActorManager5E.getHealthInjuries(rActor)
	if nInjuries > 0 then
		rRoll.nMod = rRoll.nMod - nInjuries
		table.insert(aAddDesc, "[Injuried -" .. nInjuries .. "] ")
	end

	-- Consider Fatigue
	local nFatigue = ActorManager5E.getHealthFatigue(rActor)
	if nFatigue > 0 then
		rRoll.nMod = rRoll.nMod - nFatigue
		table.insert(aAddDesc, "[Fatigued -" .. nFatigue .. "] ")
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
	end
end

-- Added
-- Process modifiers resulting from armor
function encodeArmorMods(rRoll)
	local aAddDesc = {}

	if StringManager.contains({ "agility" }, rRoll.sStat) then
		-- Process Armor Penalty
		if rRoll.nAP > 0 then
			rRoll.nMod = rRoll.nMod - rRoll.nAP
			table.insert(aAddDesc, "[Armor Penalty -" .. rRoll.nAP .. "] ")
		end

		-- Concatenate description strings and add to rRoll.sDesc
		if #aAddDesc > 0 then
			rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
		end
	end
end