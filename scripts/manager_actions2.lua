-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

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
	if rRoll.bADV then
		table.insert(rRoll.tNotifications, "[ADV]");
	end
	if rRoll.bDIS then
		table.insert(rRoll.tNotifications, "[DIS]");
	end

	rRoll.sDesc = table.concat(rRoll.tNotifications, " ");

	rRoll.bADV = nil;
	rRoll.bDIS = nil;
	rRoll.tNotifications = nil;
end

function setupD20RollMod(rRoll)
	if rRoll.sDesc:match(" %[ADV%]") then
		rRoll.bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	else
		rRoll.bADV = false;
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		rRoll.bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	else
		rRoll.bDIS = false;
	end

	rRoll.tNotifications = {};

	rRoll.bEffects = false;
	rRoll.tEffectDice = {};
	rRoll.nEffectMod = 0;
end
function applyAbilityEffectsToD20RollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, rRoll.sAbility);
	if nBonusEffects > 0 then
		rRoll.bEffects = true;
		rRoll.nEffectMod = rRoll.nEffectMod + nBonusStat;
	end
end
function finalizeEffectsToD20RollMod(rRoll)
	if rRoll.bEffects then
		for _,v in ipairs(rRoll.tEffectDice) do
			if v:sub(1,1) == "-" then
				table.insert(rRoll.aDice, "-p" .. v:sub(3));
			else
				table.insert(rRoll.aDice, "p" .. v:sub(2));
			end
		end
		rRoll.nMod = rRoll.nMod + rRoll.nEffectMod;
		local sMod = StringManager.convertDiceToString(rRoll.tEffectDice, rRoll.nEffectMod, true);
		table.insert(rRoll.tNotifications, EffectManager.buildEffectOutput(sMod));
	end
	if rRoll.bReliable then
		table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
	end
end
function finalizeD20RollMod(rRoll)
	if #(rRoll.tNotifications) > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(rRoll.tNotifications, " ");
	end

	rRoll.tNotifications = nil;
	rRoll.bEffects = nil;
	rRoll.tEffectDice = nil;
	rRoll.nEffectMod = nil;

	ActionsManager2.encodeDesktopMods(rRoll);
	ActionsManager2.encodeAdvantage(rRoll);
end

function setupD20RollResolve(rRoll, rSource)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);
end

function encodeDesktopMods(rRoll)
	local nMod = 0;
	
	if ModifierManager.getKey("PLUS2") then
		nMod = nMod + 2;
	end
	if ModifierManager.getKey("MINUS2") then
		nMod = nMod - 2;
	end
	if ModifierManager.getKey("PLUS5") then
		nMod = nMod + 5;
	end
	if ModifierManager.getKey("MINUS5") then
		nMod = nMod - 5;
	end
	
	if nMod == 0 then
		return;
	end
	
	rRoll.nMod = rRoll.nMod + nMod;
	rRoll.sDesc = rRoll.sDesc .. string.format(" [%+d]", nMod);
end

-- ADV/DIS are encoded in roll now.  Still process Legacy parameters (bADV/bDIS) for now
function encodeAdvantage(rRoll, bADV, bDIS)
	if ModifierManager.getKey("ADV") or bADV then
		rRoll.bADV = true;
	end
	if ModifierManager.getKey("DIS") or bDIS then
		rRoll.bDIS = true;
	end

	if rRoll.bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if rRoll.bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	if (rRoll.bADV and not rRoll.bDIS) or (rRoll.bDIS and not rRoll.bADV) then
		if rRoll.aDice[1] then
			table.insert(rRoll.aDice, 2, UtilityManager.copyDeep(rRoll.aDice[1]));
			rRoll.aDice.expr = nil;
		end
	end
end
function decodeAdvantage(rRoll)
	local bADV = string.match(rRoll.sDesc, "%[ADV%]");
	local bDIS = string.match(rRoll.sDesc, "%[DIS%]");
	if (bADV and not bDIS) or (bDIS and not bADV) then
		if #(rRoll.aDice) > 1 then
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
	if not ActorManager5E.hasRollTrait(rActor, CharManager.TRAIT_LUCK) and not ActorManager5E.hasTrait(rActor, CharManager.TRAIT_LUCKY) then
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
	if not ActorManager5E.hasRollFeat2024(rActor, CharManager.FEAT_HEALER) then
		return;
	end

	local nDice = #rRoll.aDice;
	for i = 1, nDice do
		ActionsManager2.helperHandleSingleReroll(rRoll, i, 1);
	end
	rRoll.sDesc = string.format("%s [%s]", rRoll.sDesc, Interface.getString("roll_msg_feat_healer"));
end
function handleElvenAccuracyFeatMod(rRoll, rActor)
	if not ActorManager5E.hasRollFeat2014(rActor, CharManager.FEAT_ELVEN_ACCURACY) then
		return;
	end
	if not rRoll.bADV or not StringManager.contains({ "dexterity", "intelligence", "wisdom", "charisma", }, rRoll.sAbility) then
		return;
	end
	if not rRoll.aDice[1] then
		return;
	end
	table.insert(rRoll.aDice, 2, UtilityManager.copyDeep(rRoll.aDice[1]));
	rRoll.aDice.expr = nil;
	rRoll.sDesc = string.format("%s [%s]", rRoll.sDesc, Interface.getString("roll_msg_feat_elvenaccuracy"));
end
function handleElvenAccuracyFeatResolve(rRoll)
	if not rRoll then
		return;
	end
	if not rRoll.sDesc:match(string.format("%%[%s%%]", Interface.getString("roll_msg_feat_elvenaccuracy"))) then
		return;
	end
	if #(rRoll.aDice) > 2 then
		if rRoll.aDice[1].result < rRoll.aDice[3].result then
			local tTemp = rRoll.aDice[1];
			rRoll.aDice[1] = rRoll.aDice[3];
			rRoll.aDice[3] = tTemp;
			rRoll.aDice[3].type = "d" .. string.sub(rRoll.aDice[3].type, 2);
		end
		nDroppedDie = rRoll.aDice[3].result;
		rRoll.aDice[1].type = "g" .. string.sub(rRoll.aDice[1].type, 2);
		rRoll.aDice[1].value = nil;
		rRoll.aDice[3].value = nil;
		rRoll.aDice[3].dropped = true;
		rRoll.aDice[3].backcolor = "80808080";
		rRoll.aDice[3].iconcolor = "80FFFFFF";
		rRoll.aDice.expr = nil;
		rRoll.sDesc = rRoll.sDesc .. " [DROPPED " .. nDroppedDie .. "]";
	end
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
