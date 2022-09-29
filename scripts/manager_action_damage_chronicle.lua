-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

OOB_MSGTYPE_APPLYDMG = "applydmg";
OOB_MSGTYPE_APPLYDMGSTATE = "applydmgstate";

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMGSTATE, handleApplyDamageState);

	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerResultHandler("damage", onDamage);
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function handleApplyDamage(msgOOB)
-- Step 12
	-- Debug.chat("FN: handleApplyDamage in manager_action_damage")
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	rActor.sWeaponQualities = msgOOB.sWeaponQualities

	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end
	
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionDamage.applyDamage(rActor, rTarget, rRoll);
end

-- ===================================================================================================================
-- Modified
-- Communicate damage roll to Clients
-- ===================================================================================================================
function notifyApplyDamage(rActor, rTarget, rRoll)
-- Step 11
	-- Debug.chat("FN: notifyApplyDamage in manager_action_damage")
	if not rTarget then
		return;
	end

	rRoll.bSecret = rRoll.bTower;

	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionDamage.OOB_MSGTYPE_APPLYDMG;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rActor);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	msgOOB.nTargetOrder = rTarget.nOrder;
	msgOOB.sWeaponQualities = rActor.sWeaponQualities

	Comm.deliverOOBMessage(msgOOB, "");
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function getRoll(rActor, rAction)
-- Step 2
	-- Debug.chat("FN: getRoll in manager_action_damage")
	local rRoll = {};
	rRoll.sType = "damage";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	rRoll.bWeapon = rAction.bWeapon;
	rRoll.nDoS = DB.getValue(rAction.nodeWeapon, "dmg_multiplier", "number", 0) + 1

	-- ToDo: Do we need these?
	rRoll.sLabel = rAction.label;
	rRoll.nOrder = rAction.order;
	rRoll.sRange = rAction.range;
	rRoll.range = rAction.range; -- Legacy

	rRoll.sDesc = "[DAMAGE";

	-- Save sWeaponQualities to rActor to pass it down in the process
	rActor.sWeaponQualities = DB.getValue(rAction.nodeWeapon, "wpn_qualities", "")

	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end

	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range ..")";
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;

	-- Save the damage properties in the roll structure
	rRoll.clauses = rAction.clauses;

	-- Add the dice and modifiers
	for _,vClause in ipairs(rRoll.clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(rRoll.aDice, vDie);
		end
		rRoll.nMod = rRoll.nMod + vClause.modifier;
	end

	-- if rAction.nReroll then
		-- rRoll.sDesc = rRoll.sDesc .. " [REROLL " .. rAction.nReroll.. "]";
	-- end

	-- Encode the damage types
	ActionDamage.encodeDamageTypes(rRoll);

	return rRoll;
end

-- ===================================================================================================================
-- ===================================================================================================================
function performRoll(draginfo, rActor, rAction)
-- Step 1
	-- Debug.chat("FN: performRoll in manager_action_damage")
	local rRoll = ActionDamage.getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- ===================================================================================================================
-- ===================================================================================================================
function modDamage(rActor, rTarget, rRoll)
-- Step 3
	-- Debug.chat("FN: modDamage in manager_action_damage")
	ActionDamage.setupModRoll(rRoll, rActor, rTarget);

	if rActor then
		ActionDamage.applyAbilityEffectsToModRoll(rRoll, rActor, rTarget);
		ActionDamage.applyDmgEffectsToModRoll(rRoll, rActor, rTarget);
		ActionDamage.applyEffectModNotificationToModRoll(rRoll);

		ActionDamage.applyDmgTypeEffectsToModRoll(rRoll, rActor, rTarget);
	end
	
	if rRoll.bCritical then
		ActionDamage.applyCriticalToModRoll(rRoll, rActor, rTarget);
	end
	ActionDamage.finalizeModRoll(rRoll);
end

-- ===================================================================================================================
-- ===================================================================================================================
function onDamageRoll(rActor, rRoll)
	-- Handle max damage
	local bMax = rRoll.sDesc:match("%[MAX%]");
	if bMax then
		for _,vDie in ipairs(rRoll.aDice) do
			local sSign, sColor, sDieSides = vDie.type:match("^([%-%+]?)([dDrRgGbBpP])([%dF]+)");
			if sDieSides then
				local nResult;
				if sDieSides == "F" then
					nResult = 1;
				else
					nResult = tonumber(sDieSides) or 0;
				end
				
				if sSign == "-" then
					nResult = 0 - nResult;
				end
				
				vDie.result = nResult;
				vDie.value = vDie.result;
				if sColor == "d" or sColor == "D" then
					if sSign == "-" then
						vDie.type = "-b" .. sDieSides;
					else
						vDie.type = "b" .. sDieSides;
					end
				end
			end
		end
		if rRoll.aDice.expr then
			rRoll.aDice.expr = nil;
		end
	end
	
	ActionDamage.decodeDamageTypes(rRoll, true);
end

-- ===================================================================================================================
-- Display damage in chat
-- ===================================================================================================================
function onDamage(rActor, rTarget, rRoll)
-- Step 10
	-- Debug.chat("FN: onDamage in manager_action_damage")
	-- Rebuild detail fields if dragging from chat window
	-- ToDo: Do we need this?
	if not rRoll.nOrder then
		rRoll.nOrder = tonumber(rRoll.sDesc:match("%[DAMAGE.*#%d+")) or nil;
	end

	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[DAMAGE.*%((%w+)%)%]");
		rRoll.range = rRoll.sRange; -- Legacy
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[DAMAGE.*%]([^%[]+)"));
	end

	local rMessage = ActionsManager.createActionMessage(rActor, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");

	-- Send the chat message. Obsolete as we don't do a damage roll.
	-- local bShowMsg = true;
	-- if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		-- bShowMsg = false;
	-- end
	-- if bShowMsg then
		-- Comm.deliverChatMessage(rMessage);
	-- end

	-- Apply damage to the PC or CT entry referenced
	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.sDesc = rMessage.text;

	-- Multiple damage by Degrees of Success
	rRoll.nTotal = rRoll.nTotal * tonumber(rRoll.nDoS)

	ActionDamage.notifyApplyDamage(rActor, rTarget, rRoll);
end

-- ===================================================================================================================
-- MOD ROLL HELPERS
-- ===================================================================================================================
function setupModRoll(rRoll, rActor, rTarget)
-- Step 4
	-- Debug.chat("FN: setupModRoll in manager_action_damage")

	-- ToDo: Interesting
	-- ActionDamage.decodeDamageTypes(rRoll);
	-- CombatManager2.addRightClickDiceToClauses(rRoll);

	rRoll.tNotifications = {};

	rRoll.bCritical = rRoll.bCritical or ModifierManager.getKey("DMG_CRIT") or Input.isShiftPressed();

	if ActionAttack.isCrit(rActor, rTarget) then
		rRoll.bCritical = true;
	end

	rRoll.tAttackFilter = {};
	if rRoll.sRange == "R" then
		table.insert(rRoll.tAttackFilter, "ranged");
	elseif rRoll.sRange == "M" then
		table.insert(rRoll.tAttackFilter, "melee");
	end
	rRoll.nOrigClauses = #(rRoll.clauses);

	rRoll.bEffects = false;
	rRoll.tEffectDice = {};
	rRoll.nEffectMod = 0;
end

-- ===================================================================================================================
-- NOTE: Ability effects do not support targeting
-- ===================================================================================================================
function applyAbilityEffectsToModRoll(rRoll, rActor, rTarget)
-- Step 5
	-- Debug.chat("FN: applyAbilityEffectsToModRoll in manager_action_damage")
	-- NOTE: Ability effects do not support targeting

	-- for _,rClause in ipairs(rRoll.clauses) do
		-- local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rActor, rClause.stat);
		-- if nBonusEffects > 0 then
			-- rRoll.bEffects = true;
			-- local nMult = rClause.statmult or 1;
			-- if nBonusStat > 0 and nMult ~= 1 then
				-- nBonusStat = math.floor(nMult * nBonusStat);
			-- end
			-- rRoll.nEffectMod = rRoll.nEffectMod + nBonusStat;
			-- rClause.modifier = rClause.modifier + nBonusStat;
			-- rRoll.nMod = rRoll.nMod + nBonusStat;
		-- end
	-- end
	rRoll.nEffectMod = rRoll.nEffectMod;
	-- rClause.modifier = rClause.modifier;
	rRoll.nMod = rRoll.nMod;
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyDmgEffectsToModRoll(rRoll, rActor, rTarget)
-- Step 6
	-- Debug.chat("FN: applyDmgEffectsToModRoll in manager_action_damage")
	local tDmgEffects, nDmgEffects = EffectManager5E.getEffectsBonusByType(rActor, "DMG", true, rRoll.tAttackFilter, rTarget);
	if nDmgEffects > 0 then
		local sEffectBaseType = "";
		if #(rRoll.clauses) > 0 then
			sEffectBaseType = rRoll.clauses[1].dmgtype or "";
		end

		for _,v in pairs(tDmgEffects) do
			local bCritEffect = false;
			local aEffectDmgType = {};
			local aEffectSpecialDmgType = {};
			for _,sType in ipairs(v.remainder) do
				if StringManager.contains(DataCommon.specialdmgtypes, sType) then
					table.insert(aEffectSpecialDmgType, sType);
					if sType == "critical" then
						bCritEffect = true;
					end
				elseif StringManager.contains(DataCommon.dmgtypes, sType) then
					table.insert(aEffectDmgType, sType);
				end
			end
			
			if not bCritEffect or rRoll.bCritical then
				rRoll.bEffects = true;

				local rClause = {};

				rClause.dice = {};

				for _,vDie in ipairs(v.dice) do
					table.insert(rRoll.tEffectDice, vDie);
					table.insert(rClause.dice, vDie);
					if rClause.reroll then
						table.insert(rClause.reroll, 0);
					end
					if vDie:sub(1,1) == "-" then
						table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
					else
						table.insert(rRoll.aDice, "p" .. vDie:sub(2));
					end
				end

				rRoll.nEffectMod = rRoll.nEffectMod + v.mod;
				rClause.modifier = v.mod;
				rRoll.nMod = rRoll.nMod + v.mod;
				
				rClause.stat = "";

				if #aEffectDmgType == 0 then
					table.insert(aEffectDmgType, sEffectBaseType);
				end
				for _,vSpecialDmgType in ipairs(aEffectSpecialDmgType) do
					table.insert(aEffectDmgType, vSpecialDmgType);
				end
				rClause.dmgtype = table.concat(aEffectDmgType, ",");

				table.insert(rRoll.clauses, rClause);
			end
		end
	end
end

-- ===================================================================================================================
-- Add applying effect to description
-- ===================================================================================================================
function applyEffectModNotificationToModRoll(rRoll)
-- Step 7
	-- Debug.chat("FN: applyEffectModNotificationToModRoll in manager_action_damage")
	if rRoll.bEffects then
		local sEffects = "";
		local sMod = StringManager.convertDiceToString(rRoll.tEffectDice, rRoll.nEffectMod, true);
		if sMod ~= "" then
			sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
		else
			sEffects = "[" .. Interface.getString("effects_tag") .. "]";
		end
		table.insert(rRoll.tNotifications, sEffects);
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyDmgTypeEffectsToModRoll(rRoll, rActor, rTarget)
-- Step 8
	-- Debug.chat("FN: applyDmgTypeEffectsToModRoll in manager_action_damage")
	local tAddDmgTypes = {};
	local tDmgTypeEffects = EffectManager5E.getEffectsByType(rActor, "DMGTYPE", nil, rTarget);
	for _,rEffectComp in ipairs(tDmgTypeEffects) do
		for _,v in ipairs(rEffectComp.remainder) do
			local tSplitDmgTypes = StringManager.split(v, ",", true);
			for _,v2 in ipairs(tSplitDmgTypes) do
				table.insert(tAddDmgTypes, v2);
			end
		end
	end

	if #tAddDmgTypes > 0 then
		for _,rClause in ipairs(rRoll.clauses) do
			local tSplitDmgTypes = StringManager.split(rClause.dmgtype, ",", true);
			for _,v in ipairs(tAddDmgTypes) do
				if not StringManager.contains(tSplitDmgTypes, v) then
					if rClause.dmgtype ~= "" then
						rClause.dmgtype = rClause.dmgtype .. "," .. v;
					else
						rClause.dmgtype = v;
					end
				end
			end
		end

		local sNotification = "[" .. Interface.getString("effects_tag") .. " " .. table.concat(tAddDmgTypes, ",") .. "]";
		table.insert(rRoll.tNotifications, sNotification);
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyCriticalToModRoll(rRoll, rActor, rTarget)
	-- Debug.chat("FN: applyCriticalToModRoll in manager_action_damage")
	table.insert(rRoll.tNotifications, "[CRITICAL]");
	
	-- Double the dice, and add extra critical dice
	local aNewClauses = {};
	local aNewDice = {};
	local nMaxSides = 0;
	local nMaxClause = 0;
	local nMaxDieIndex = 0;

	-- Insert the original dice
	local nOldDieIndex = 1;
	for _,vClause in ipairs(rRoll.clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(aNewDice, rRoll.aDice[nOldDieIndex]);
			nOldDieIndex = nOldDieIndex + 1;
		end
	end

	-- Add critical dice by clause
	for kClause,vClause in ipairs(rRoll.clauses) do
		local bApplyCritToClause = true;
		local aSplitByDmgType = StringManager.split(vClause.dmgtype, ",", true);
		for _,vDmgType in ipairs(aSplitByDmgType) do
			if vDmgType == "critical" then
				bApplyCritToClause = false;
				break;
			end
		end

		if bApplyCritToClause then
			local bNewMax = false;
			local aCritClauseDice = {};
			local aCritClauseReroll = {};
			for kDie,vDie in ipairs(vClause.dice) do
				if vDie:sub(1,1) == "-" then
					table.insert(aNewDice, "-g" .. vDie:sub(3));
				else
					table.insert(aNewDice, "g" .. vDie:sub(2));
				end
				table.insert(aCritClauseDice, vDie);
				if vClause.reroll then
					table.insert(aCritClauseReroll, vClause.reroll[kDie]);
				end
				
				if kClause <= rRoll.nOrigClauses and vDie:sub(1,1) ~= "-" then
					local nDieSides = tonumber(vDie:sub(2)) or 0;
					if nDieSides > nMaxSides then
						bNewMax = true;
						nMaxSides = nDieSides;
					end
				end
			end

			if #aCritClauseDice > 0 then
				local rNewClause = { dice = {}, reroll = {}, modifier = 0, stat = "", bCritical = true };
				if vClause.dmgtype == "" then
					rNewClause.dmgtype = "critical";
				else
					rNewClause.dmgtype = vClause.dmgtype .. ",critical";
				end
				for kDie, vDie in ipairs(aCritClauseDice) do
					table.insert(rNewClause.dice, vDie);
					table.insert(rNewClause.reroll, aCritClauseReroll[kDie]);
				end
				table.insert(aNewClauses, rNewClause);
				
				if bNewMax then
					nMaxClause = #aNewClauses;
					nMaxDieIndex = #aNewDice + 1;
				end
			end
		end
	end
	if nMaxSides > 0 then
		local nCritDice = 0;
		if rRoll.bWeapon then
			local sSourceNodeType, nodeSource = ActorManager.getTypeAndNode(rActor);
			if nodeSource and (sSourceNodeType == "pc") then
				if rRoll.sRange == "R" then
					nCritDice = DB.getValue(nodeSource, "weapon.critdicebonus.ranged", 0);
				else
					nCritDice = DB.getValue(nodeSource, "weapon.critdicebonus.melee", 0);
				end
			end
		end
		
		if nCritDice > 0 then
			for i = 1, nCritDice do
				table.insert(aNewDice, nMaxDieIndex, "g" .. nMaxSides);
				table.insert(aNewClauses[nMaxClause].dice, "d" .. nMaxSides);
				if aNewClauses[nMaxClause].reroll then
					table.insert(aNewClauses[nMaxClause].reroll, aNewClauses[nMaxClause].reroll[1]);
				end
			end
		end
	end
	local aFinalClauses = {};
	for _,vClause in ipairs(aNewClauses) do
		table.insert(rRoll.clauses, vClause);
	end
	rRoll.aDice = aNewDice;
end

-- ===================================================================================================================
-- Needed?
-- ===================================================================================================================
function applyFixedDamageOptionToModRoll(rRoll, rActor, rTarget)
	local aFixedClauses = {};
	local aFixedDice = {};
	local nFixedPositiveCount = 0;
	local nFixedNegativeCount = 0;
	local nFixedMod = 0;

	for kClause,vClause in ipairs(rRoll.clauses) do
		if kClause <= rRoll.nOrigClauses then
			local nClauseFixedMod = 0;
			for kDie,vDie in ipairs(vClause.dice) do
				if vDie:sub(1,1) == "-" then
					nFixedNegativeCount = nFixedNegativeCount + 1;
					nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
					if nFixedNegativeCount % 2 == 0 then
						nClauseFixedMod = nClauseFixedMod - 1;
					end
				else
					nFixedPositiveCount = nFixedPositiveCount + 1;
					nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
					if nFixedPositiveCount % 2 == 0 then
						nClauseFixedMod = nClauseFixedMod + 1;
					end
				end
				vClause.modifier = vClause.modifier + nClauseFixedMod;
			end
			vClause.dice = {};
			nFixedMod = nFixedMod + nClauseFixedMod;
		else
			for _,vDie in ipairs(vClause.dice) do
				if vClause.bCritical then
					if vDie:sub(1,1) == "-" then
						table.insert(aFixedDice, "-g" .. vDie:sub(3));
					else
						table.insert(aFixedDice, "g" .. vDie:sub(2));
					end
				else
					table.insert(aFixedDice, vDie);
				end
			end
		end
		
		table.insert(aFixedClauses, vClause);
	end
	
	rRoll.clauses = aFixedClauses;
	rRoll.aDice = aFixedDice;
	rRoll.nMod = rRoll.nMod + nFixedMod;
end

-- ===================================================================================================================
-- Needed?
-- ===================================================================================================================
function applyModifierKeysToModRoll(rRoll, rActor, rTarget)
	if ModifierManager.getKey("DMG_MAX") then
		table.insert(rRoll.tNotifications, "[MAX]");
	end
	if ModifierManager.getKey("DMG_HALF") then
		table.insert(rRoll.tNotifications, "[HALF]");
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function finalizeModRoll(rRoll)
-- Step 9
	-- Debug.chat("FN: finalizeModRoll in manager_action_damage")
	if #(rRoll.tNotifications) > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(rRoll.tNotifications, " ");
	end

	rRoll.tNotifications = nil;
	rRoll.tAttackFilter = nil;
	rRoll.bEffects = nil;
	rRoll.tEffectDice = nil;
	rRoll.nEffectMod = nil;

	-- ActionDamage.encodeDamageTypes(rRoll);
	ActionsManager2.encodeDesktopMods(rRoll);
end

-- ===================================================================================================================
-- APPLY DAMAGE EFFECT HELPERS
-- ===================================================================================================================
-- NOTE: Dice determined randomly, instead of rolled
-- ===================================================================================================================
function applyTargetedDmgEffectsToDamageOutput(rDamageOutput, rSource, rTarget)
	local tTargetedDamage = EffectManager5E.getEffectsBonusByType(rSource, "DMG", true, rDamageOutput.aDamageFilter, rTarget, true);

	local nDamageEffectTotal = 0;
	local nDamageEffectCount = 0;
	for k, v in pairs(tTargetedDamage) do
		local bValid = true;
		local aSplitByDmgType = StringManager.split(k, ",", true);
		for _,vDmgType in ipairs(aSplitByDmgType) do
			if vDmgType == "critical" and not rDamageOutput.bCritical then
				bValid = false;
			end
		end
		
		if bValid then
			local nSubTotal = StringManager.evalDice(v.dice, v.mod);
			
			local sDamageType = rDamageOutput.sFirstDamageType;
			if sDamageType then
				sDamageType = sDamageType .. "," .. k;
			else
				sDamageType = k;
			end

			rDamageOutput.aDamageTypes[sDamageType] = (rDamageOutput.aDamageTypes[sDamageType] or 0) + nSubTotal;
			
			nDamageEffectTotal = nDamageEffectTotal + nSubTotal;
			nDamageEffectCount = nDamageEffectCount + 1;
		end
	end

	if nDamageEffectCount > 0 then
		local sNotification;
		if nDamageEffectTotal ~= 0 then
			sNotification = string.format("[" .. Interface.getString("effects_tag") .. " %+d]", nDamageEffectTotal);
		else
			sNotification = "[" .. Interface.getString("effects_tag") .. "]";
		end
		table.insert(rDamageOutput.tNotifications, sNotification);
	end

	rDamageOutput.nVal = rDamageOutput.nVal + nDamageEffectTotal;
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyTargetedDmgTypeEffectsToDamageOutput(rDamageOutput, rSource, rTarget)
	local tAddDmgTypes = {};
	local tDmgTypeEffects = EffectManager5E.getEffectsByType(rSource, "DMGTYPE", nil, rTarget, true);
	for _,rEffectComp in ipairs(tDmgTypeEffects) do
		for _,v in ipairs(rEffectComp.remainder) do
			local tSplitDmgTypes = StringManager.split(v, ",", true);
			for _,v2 in ipairs(tSplitDmgTypes) do
				table.insert(tAddDmgTypes, v2);
			end
		end
	end
	if #tAddDmgTypes > 0 then
		local tNewDmgTypes = {};
		for k,v in pairs(rDamageOutput.aDamageTypes) do
			local tSplitDmgTypes = StringManager.split(k, ",", true);
			for _,v2 in ipairs(tAddDmgTypes) do
				if not StringManager.contains(tSplitDmgTypes, v2) then
					if k ~= "" then
						k = k .. "," .. v2;
					else
						k = v2;
					end
				end
			end
			tNewDmgTypes[k] = v;
		end
		rDamageOutput.aDamageTypes = tNewDmgTypes;

		local sNotification = "[" .. Interface.getString("effects_tag") .. " " .. table.concat(tAddDmgTypes, ",") .. "]";
		table.insert(rDamageOutput.tNotifications, sNotification);
	end
end

-- ===================================================================================================================
-- UTILITY FUNCTIONS
-- ===================================================================================================================
function encodeDamageTypes(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		if vClause.dmgtype and vClause.dmgtype ~= "" then
			local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s)(%s)(%s)(%s)]", vClause.dmgtype, sDice, vClause.stat or "", vClause.statmult or 1, table.concat(vClause.reroll or {}, ","));
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function decodeDamageTypes(rRoll, bFinal)
	-- Process each type clause in the damage description (INITIAL ROLL)
	local nMainDieIndex = 0;
	local aRerollOutput = {};
	rRoll.clauses = {};
	for sDamageType, sDamageDice, sDamageAbility, sDamageAbilityMult, sDamageReroll in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)%(([^)]*)%)%(([^)]*)%)%(([^)]*)%)%]") do
		local rClause = {};
		rClause.dmgtype = StringManager.trim(sDamageType);
		rClause.stat = sDamageAbility;
		rClause.statmult = tonumber(sDamageAbilityMult) or 1;
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDamageDice);
		rClause.nTotal = rClause.modifier;
		local aReroll = {};
		for sReroll in sDamageReroll:gmatch("%d+") do
			table.insert(aReroll, tonumber(sReroll) or 0);
		end
		if #aReroll > 0 then
			rClause.reroll = aReroll;
		end
		for kDie,vDie in ipairs(rClause.dice) do
			nMainDieIndex = nMainDieIndex + 1;
			if rRoll.aDice[nMainDieIndex] then
				if bFinal and 
						rClause.reroll and rClause.reroll[kDie] and 
						rRoll.aDice[nMainDieIndex].result and 
						(math.abs(rRoll.aDice[nMainDieIndex].result) <= rClause.reroll[kDie]) then
					local nDieSides = tonumber(string.match(rRoll.aDice[nMainDieIndex].type, "[%-%+]?[a-z](%d+)")) or 0;
					if nDieSides > 0 then
						table.insert(aRerollOutput, "D" .. nMainDieIndex .. "=" .. rRoll.aDice[nMainDieIndex].result);
						local nSubtotal = math.random(nDieSides);
						if rRoll.aDice[nMainDieIndex].result < 0 then
							rRoll.aDice[nMainDieIndex].result = -nSubtotal;
						else
							rRoll.aDice[nMainDieIndex].result = nSubtotal;
						end
						rRoll.aDice[nMainDieIndex].value = nil;
					end
				end
				rClause.nTotal = rClause.nTotal + (rRoll.aDice[nMainDieIndex].result or 0);
			end
		end
		
		table.insert(rRoll.clauses, rClause);
	end
	if #aRerollOutput > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [REROLL " .. table.concat(aRerollOutput, ",") .. "]";
	end

	-- Process each type clause in the damage description (DRAG ROLL RESULT)
	local nClauses = #(rRoll.clauses);
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)]") do
		local sTotal = string.match(sDamageDice, "=(%d+)");
		if sTotal then
			local nTotal = tonumber(sTotal) or 0;
			
			local rClause = {};
			rClause.dmgtype = StringManager.trim(sDamageType);
			rClause.stat = "";
			rClause.dice = {};
			rClause.modifier = nTotal;
			rClause.nTotal = nTotal;

			table.insert(rRoll.clauses, rClause);
		end
	end
	
	-- Add untyped clause if no TYPE tag found
	if #(rRoll.clauses) == 0 then
		local rClause = {};
		rClause.dmgtype = "";
		rClause.stat = "";
		rClause.dice = {};
		rClause.modifier = rRoll.nMod;
		rClause.nTotal = rRoll.nMod;
		for _,vDie in ipairs(rRoll.aDice) do
			if type(vDie) == "table" then
				table.insert(rClause.dice, vDie.type);
				rClause.nTotal = rClause.nTotal + (vDie.value or vDie.result or 0);
			else
				table.insert(rClause.dice, vDie);
			end
		end

		table.insert(rRoll.clauses, rClause);
	end
	
	-- Handle drag results that are halved or doubled
	if #(rRoll.aDice) == 0 then
		local nResultTotal = 0;
		for i = nClauses + 1, #(rRoll.clauses) do
			nResultTotal = rRoll.clauses[i].nTotal;
		end
		if nResultTotal > 0 and nResultTotal ~= rRoll.nMod then
			if math.floor(nResultTotal / 2) == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = math.floor(vClause.modifier / 2);
					vClause.nTotal = math.floor(vClause.nTotal / 2);
				end
			elseif nResultTotal * 2 == rRoll.nMod then
				for _,vClause in ipairs(rRoll.clauses) do
					vClause.modifier = 2 * vClause.modifier;
					vClause.nTotal = 2 * vClause.nTotal;
				end
			end
		end
	end
	
	-- Remove damage type information from roll description
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE:[^]]*%]", "");
	
	if bFinal then
		local nFinalTotal = ActionsManager.total(rRoll);

		-- Handle minimum damage
		if nFinalTotal < 0 and rRoll.aDice and #rRoll.aDice > 0 then
			rRoll.sDesc = rRoll.sDesc .. " [MIN DAMAGE]";
			rRoll.nMod = rRoll.nMod - nFinalTotal;
			nFinalTotal = 0;
		end

		-- Capture any manual modifiers and adjust damage types accordingly
		-- NOTE: Positive values are added to first damage clause, Negative values reduce damage clauses until none remain
		local nClausesTotal = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nClausesTotal = nClausesTotal + vClause.nTotal;
		end
		if nFinalTotal ~= nClausesTotal then
			local nRemainder = nFinalTotal - nClausesTotal;
			if nRemainder > 0 then
				if #(rRoll.clauses) == 0 then
					table.insert(rRoll.clauses, { dmgtype = "", stat = "", dice = {}, modifier = nRemainder, nTotal = nRemainder})
				else
					rRoll.clauses[1].modifier = rRoll.clauses[1].modifier + nRemainder;
					rRoll.clauses[1].nTotal = rRoll.clauses[1].nTotal + nRemainder;
				end
			else
				for _,vClause in ipairs(rRoll.clauses) do
					if vClause.nTotal >= -nRemainder then
						vClause.modifier = vClause.modifier + nRemainder;
						vClause.nTotal = vClause.nTotal + nRemainder;
						break;
					else
						vClause.modifier = vClause.modifier - vClause.nTotal;
						nRemainder = nRemainder + vClause.nTotal;
						vClause.nTotal = 0;
					end
				end
			end
		end
		
		-- Collapse damage clauses into smallest set, then add to roll description as text
		local aDamage = ActionDamage.getDamageStrings(rRoll.clauses);
		for _, rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			local sDmgTypeOutput = rDamage.sType;
			if sDmgTypeOutput == "" then
				sDmgTypeOutput = "untyped";
			end
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s=%d)]", sDmgTypeOutput, sDice, rDamage.nTotal);
		end
	end
end

-- ===================================================================================================================
-- Collapse damage clauses by damage type (in the original order, if possible)
-- ===================================================================================================================
function getDamageStrings(clauses)
	local aOrderedTypes = {};
	local aDmgTypes = {};
	for _,vClause in ipairs(clauses) do
		local rDmgType = aDmgTypes[vClause.dmgtype];
		if not rDmgType then
			rDmgType = {};
			rDmgType.aDice = {};
			rDmgType.nMod = 0;
			rDmgType.nTotal = 0;
			rDmgType.sType = vClause.dmgtype;
			aDmgTypes[vClause.dmgtype] = rDmgType;
			table.insert(aOrderedTypes, rDmgType);
		end

		for _,vDie in ipairs(vClause.dice) do
			table.insert(rDmgType.aDice, vDie);
		end
		rDmgType.nMod = rDmgType.nMod + vClause.modifier;
		rDmgType.nTotal = rDmgType.nTotal + (vClause.nTotal or 0);
	end
	
	return aOrderedTypes;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);
	
	local aDamageTypes = {};
	for _,v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.dmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end
	
	return aDamageTypes;
end

-- ===================================================================================================================
-- DAMAGE APPLICATION
-- ===================================================================================================================
function checkReductionTypeHelper(rMatch, aDmgType)
	if not rMatch or (rMatch.mod ~= 0) then
		return false;
	end
	if #(rMatch.aNegatives) > 0 then
		local bMatchNegative = false;
		for _,vNeg in pairs(rMatch.aNegatives) do
			if StringManager.contains(aDmgType, vNeg) then
				bMatchNegative = true;
				break;
			end
		end
		return not bMatchNegative;
	end
	return true;
end

-- ===================================================================================================================
-- ===================================================================================================================
function checkReductionType(aReduction, aDmgType)
	for _,sDmgType in pairs(aDmgType) do
		if ActionDamage.checkReductionTypeHelper(aReduction[sDmgType], aDmgType) or ActionDamage.checkReductionTypeHelper(aReduction["all"], aDmgType) then
			return true;
		end
	end
	
	return false;
end

-- ===================================================================================================================
-- ===================================================================================================================
function checkNumericalReductionTypeHelper(rMatch, aDmgType, nLimit)
	if not rMatch or (rMatch.mod == 0) then
		return 0;
	end

	local bMatch = false;
	if #rMatch.aNegatives > 0 then
		local bMatchNegative = false;
		for _,vNeg in pairs(rMatch.aNegatives) do
			if StringManager.contains(aDmgType, vNeg) then
				bMatchNegative = true;
				break;
			end
		end
		if not bMatchNegative then
			bMatch = true;
		end
	else
		bMatch = true;
	end
	
	local nAdjust = 0;
	if bMatch then
		nAdjust = rMatch.mod - (rMatch.nApplied or 0);
		if nLimit then
			nAdjust = math.min(nAdjust, nLimit);
		end
		rMatch.nApplied = (rMatch.nApplied or 0) + nAdjust;
	end
	
	return nAdjust;
end

-- ===================================================================================================================
-- ===================================================================================================================
function checkNumericalReductionType(aReduction, aDmgType, nLimit)
	local nAdjust = 0;
	
	for _,sDmgType in pairs(aDmgType) do
		if nLimit then
			local nSpecificAdjust = ActionDamage.checkNumericalReductionTypeHelper(aReduction[sDmgType], aDmgType, nLimit);
			nAdjust = nAdjust + nSpecificAdjust;
			local nGlobalAdjust = ActionDamage.checkNumericalReductionTypeHelper(aReduction["all"], aDmgType, nLimit - nSpecificAdjust);
			nAdjust = nAdjust + nGlobalAdjust;
		else
			nAdjust = nAdjust + ActionDamage.checkNumericalReductionTypeHelper(aReduction[sDmgType], aDmgType);
			nAdjust = nAdjust + ActionDamage.checkNumericalReductionTypeHelper(aReduction["all"], aDmgType);
		end
	end
	
	return nAdjust;
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	local nDamageAdjust = 0;
	local bVulnerable = false;
	local bResist = false;
	
	-- Get damage adjustment effects
	local aVuln = ActorManager5E.getDamageVulnerabilities(rTarget, rSource);
	local aResist = ActorManager5E.getDamageResistances(rTarget, rSource);
	local aImmune = ActorManager5E.getDamageImmunities(rTarget, rSource);
	
	-- Handle immune all
	if aImmune["all"] then
		nDamageAdjust = 0 - nDamage;
		bResist = true;
		return nDamageAdjust, bVulnerable, bResist;
	end
	
	-- Iterate through damage type entries for vulnerability, resistance and immunity
	local nVulnApplied = 0;
	local bResistCarry = false;
	for k, v in pairs(rDamageOutput.aDamageTypes) do
		-- Get individual damage types for each damage clause
		local aSrcDmgClauseTypes = {};
		local aTemp = StringManager.split(k, ",", true);
		for _,vType in ipairs(aTemp) do
			if vType ~= "untyped" and vType ~= "" then
				table.insert(aSrcDmgClauseTypes, vType);
			end
		end
		
		-- Handle standard immunity, vulnerability and resistance
		local bLocalVulnerable = ActionDamage.checkReductionType(aVuln, aSrcDmgClauseTypes);
		local bLocalResist = ActionDamage.checkReductionType(aResist, aSrcDmgClauseTypes);
		local bLocalImmune = ActionDamage.checkReductionType(aImmune, aSrcDmgClauseTypes);
		
		-- Calculate adjustment
		-- Vulnerability = double
		-- Resistance = half
		-- Immunity = none
		local nLocalDamageAdjust = 0;
		if bLocalImmune then
			nLocalDamageAdjust = -v;
			bResist = true;
		else
			-- Handle numerical resistance
			local nLocalResist = ActionDamage.checkNumericalReductionType(aResist, aSrcDmgClauseTypes, v);
			if nLocalResist ~= 0 then
				nLocalDamageAdjust = nLocalDamageAdjust - nLocalResist;
				bResist = true;
			end
			-- Handle numerical vulnerability
			local nLocalVulnerable = ActionDamage.checkNumericalReductionType(aVuln, aSrcDmgClauseTypes);
			if nLocalVulnerable ~= 0 then
				nLocalDamageAdjust = nLocalDamageAdjust + nLocalVulnerable;
				bVulnerable = true;
			end
			-- Handle standard resistance
			if bLocalResist then
				local nResistOddCheck = (nLocalDamageAdjust + v) % 2;
				local nAdj = math.ceil((nLocalDamageAdjust + v) / 2);
				nLocalDamageAdjust = nLocalDamageAdjust - nAdj;
				if nResistOddCheck == 1 then
					if bResistCarry then
						nLocalDamageAdjust = nLocalDamageAdjust + 1;
						bResistCarry = false;
					else
						bResistCarry = true;
					end
				end
				bResist = true;
			end
			-- Handle standard vulnerability
			if bLocalVulnerable then
				nLocalDamageAdjust = nLocalDamageAdjust + (nLocalDamageAdjust + v);
				bVulnerable = true;
			end
		end
		
		-- Apply adjustment to this damage type clause
		nDamageAdjust = nDamageAdjust + nLocalDamageAdjust;
	end
	
	-- Handle damage and mishap threshold
	if (rTarget.sSubtargetPath or "") ~= "" then
		local nDT = DB.getValue(DB.getPath(rTarget.sSubtargetPath, "damagethreshold"), 0);
		if (nDT > 0) and (nDT > (nDamage + nDamageAdjust)) then
			nDamageAdjust = 0 - nDamage;
			bResist = true;
		end
	else
		local nDT = ActorManager5E.getDamageThreshold(rTarget);
		if (nDT > 0) and (nDT > (nDamage + nDamageAdjust)) then
			nDamageAdjust = 0 - nDamage;
			bResist = true;
		end
		local nMT = ActorManager5E.getMishapThreshold(rTarget);
		if (nMT > 0) and (nMT <= (nDamage + nDamageAdjust)) then
			table.insert(rDamageOutput.tNotifications, "[DAMAGE EXCEEDS MISHAP THRESHOLD]");
		end
	end

	-- Results
	return nDamageAdjust, bVulnerable, bResist;
end

-- ===================================================================================================================
-- ===================================================================================================================
function decodeDamageText(nDamage, sDamageDesc)
-- Step 14
	-- Debug.chat("FN: decodeDamageText in manager_action_damage")
	local rDamageOutput = {};

	rDamageOutput.sType = "damage";
	rDamageOutput.sTypeOutput = "Damage";
	rDamageOutput.sVal = string.format("%01d", nDamage);
	rDamageOutput.nVal = nDamage;

	-- Determine critical
	rDamageOutput.bCritical = string.match(sDamageDesc, "%[CRITICAL%]");

	-- Determine range
	rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";
	rDamageOutput.aDamageFilter = {};

	if rDamageOutput.sRange == "M" then
		table.insert(rDamageOutput.aDamageFilter, "melee");
	elseif rDamageOutput.sRange == "R" then
		table.insert(rDamageOutput.aDamageFilter, "ranged");
	end

	return rDamageOutput;
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyDamage(rActor, rTarget, rRoll)
-- Step 13
	-- Debug.chat("FN: applyDamage in manager_action_damage")
	-- ToDo: Adjust for Chronicle
	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);

	if not nodeTarget then
		return;
	end

	-- Get health fields
	local nTotalHP, nWounds, nInjuries, nTrauma, nAR;

	if sTargetNodeType == "pc" then
		nTotalHP = DB.getValue(nodeTarget, "hp.total", 0);
		nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
		nInjuries = DB.getValue(nodeTarget, "hp.injuries", 0);
		nTrauma = DB.getValue(nodeTarget, "hp.trauma", 0);
	elseif sTargetNodeType == "ct" then
	-- ToDo: Implement Max Trauma and Injuries for NPC
		nTotalHP = DB.getValue(nodeTarget, "hp.total", 0);
		nWounds = DB.getValue(nodeTarget, "hp.wounds", 0);
		nInjuries = DB.getValue(nodeTarget, "hp.injuries", 0);
		nTrauma = DB.getValue(nodeTarget, "hp.trauma", 0);
	-- elseif sTargetNodeType == "ct" and ActorManager.isRecordType(rTarget, "vehicle") then
		-- if (rRoll.sSubtargetPath or "") ~= "" then
			-- nTotalHP = DB.getValue(DB.getPath(rRoll.sSubtargetPath, "hp"), 0);
			-- nWounds = DB.getValue(DB.getPath(rRoll.sSubtargetPath, "wounds"), 0);
		-- else
			-- nTotalHP = DB.getValue(nodeTarget, "hptotal", 0);
			-- nWounds = DB.getValue(nodeTarget, "wounds", 0);
		-- end
	else
		return;
	end

	-- Get piercing value
	local nPiercing = CharWeaponManager.getPropertyValue(rActor.sWeaponQualities, "piercing")

	-- Set piercing to zero if NIL
	if not nPiercing then
		nPiercing = 0
	end

	-- Prepare for notifications
	local bRemoveTarget = false;

	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);

	-- Decode damage/heal description
	local rDamageOutput = ActionDamage.decodeDamageText(rRoll.nTotal, rRoll.sDesc);
	rDamageOutput.tNotifications = {};
	
	-- Damage
	-- Apply damage type adjustments
	-- Is this needed?
	rTarget.sSubtargetPath = rRoll.sSubtargetPath;
	-- local nDamageAdjust, bVulnerable, bResist = ActionDamage.getDamageAdjust(rActor, rTarget, rDamageOutput.nVal, rDamageOutput);
	local nAdjustedDamage = rDamageOutput.nVal

	-- Get Total Armor Rating
	nAR = DB.getValue(nodeTarget, "defenses.armor.total", 0)

	-- Apply Piercing
	if (nPiercing > 0) and (nAR > 0) then
		table.insert(rDamageOutput.tNotifications, "[ARMOR PIERCED BY " .. nPiercing .."]")
		nAR = nAR - nPiercing
		if nAR <0 then
			nAR = 0
		end
	end

	-- Apply armor damage reduction
	if nAdjustedDamage <= nAR then
		table.insert(rDamageOutput.tNotifications, "\n[ALL DEFLECTED BY ARMOR]")
		nAdjustedDamage = 0
	elseif nAR > 0 then
		table.insert(rDamageOutput.tNotifications, "\n[" .. nAR .. " DEFLECTED BY ARMOR]")
		nAdjustedDamage = nAdjustedDamage - nAR
	end

	-- Avoid negative damage
	if nAdjustedDamage < 0 then
		nAdjustedDamage = 0;
	end

	-- Apply remaining damage
	if nAdjustedDamage > 0 then
		nWounds = math.max(nWounds + nAdjustedDamage, 0);
	end

	-- Update the damage output variable to reflect adjustments
	rDamageOutput.nVal = nAdjustedDamage;
	rDamageOutput.sVal = string.format("%01d", nAdjustedDamage);

	-- Set health fields
	if sTargetNodeType == "pc" then
		DB.setValue(nodeTarget, "hp.wounds", "number", nWounds);
	elseif ActorManager.isRecordType(rTarget, "npc") then
		DB.setValue(nodeTarget, "hp.wounds", "number", nWounds);
	-- elseif ActorManager.isRecordType(rTarget, "vehicle") then
		-- if (rRoll.sSubtargetPath or "") ~= "" then
			-- DB.setValue(DB.getPath(rRoll.sSubtargetPath, "wounds"), "number", nWounds);
		-- else
			-- DB.setValue(nodeTarget, "wounds", "number", nWounds);
		-- end
	end

	-- If status changed, then...
	local sNewStatus = ActorHealthManager.getHealthStatus(rTarget);
	if sOriginalStatus ~= sNewStatus then
		-- Check for automatic effects
		if ActorHealthManager.isDyingOrDeadStatus(sOriginalStatus) and
				not ActorHealthManager.isDyingOrDeadStatus(sNewStatus) then
			if ActorManager.isRecordType(rTarget, "vehicle") then
				EffectManager.removeCondition(rTarget, "Incapacitated");
			else
				EffectManager.removeCondition(rTarget, "Stable");
				EffectManager.removeCondition(rTarget, "Unconscious");
				EffectManager.addCondition(rTarget, "Prone");
			end
		elseif not ActorHealthManager.isDyingOrDeadStatus(sOriginalStatus) and
				ActorHealthManager.isDyingOrDeadStatus(sNewStatus) then
			if ActorManager.isRecordType(rTarget, "vehicle") then
				EffectManager.addCondition(rTarget, "Incapacitated");
			else
				EffectManager.addCondition(rTarget, "Unconscious");
				EffectManager.addCondition(rTarget, "Prone");
			end
		end

		-- Check for status announcement
		local bShowStatus = false;
		if ActorManager.isFaction(rTarget, "friend") then
			bShowStatus = not OptionsManager.isOption("SHPC", "off");
		else
			bShowStatus = not OptionsManager.isOption("SHNPC", "off");
		end
		if bShowStatus then
			table.insert(rDamageOutput.tNotifications, "[" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]");
		end
	end

	-- Output results
	if not rRoll.sType then
		rRoll.sType = rDamageOutput.sType;
	end

	rRoll.sDamageText = rDamageOutput.sTypeOutput;
	rRoll.nTotal = rDamageOutput.nVal;
	rRoll.sResults = table.concat(rDamageOutput.tNotifications, " ");
	ActionDamage.messageDamage(rActor, rTarget, rRoll);

	-- Remove target after applying damage
	if bRemoveTarget and rActor and rTarget then
		TargetingManager.removeTarget(ActorManager.getCTNodeName(rActor), ActorManager.getCTNodeName(rTarget));
	end
end

-- ===================================================================================================================
-- Display damage message in chat
-- ===================================================================================================================
function messageDamage(rActor, rTarget, rRoll)
	-- Debug.chat("FN: messageDamage in manager_action_damage")
	-- Step 16
	if not rTarget then
		return;
	end
	
	local msgShort = { font = "msgfont" }
	local msgLong = { font = "msgfont" }

	-- Standard roll information
	msgShort.text = string.format("[%s", rRoll.sDamageText);
	msgLong.text = string.format("[%s", rRoll.sDamageText);
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end
	msgShort.text = string.format("%s]", msgShort.text);
	msgLong.text = string.format("%s]", msgLong.text);
	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s %s", msgShort.text, rRoll.sLabel);
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sLabel);
	end
	msgShort.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);
	msgLong.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);

	-- Targeting information
	msgShort.text = string.format("%s ->", msgShort.text);
	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		local sTargetName;
		if (rRoll.sSubtargetPath or "") ~= "" then
			sTargetName = string.format("%s (%s)", ActorManager.getDisplayName(rTarget), DB.getValue(DB.getPath(rRoll.sSubtargetPath, "name"), ""));
		else
			sTargetName = ActorManager.getDisplayName(rTarget);
		end
		msgShort.text = string.format("%s [to %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [to %s]", msgLong.text, sTargetName);
	end

	-- Extra roll information
	msgShort.icon = "roll_damage"
	msgLong.icon = "roll_damage"

	-- msgShort.text = sTotal .. "Damage inflicted"
	-- msgLong.text = sTotal .. " damage inflicted"

	if (rRoll.sResults or "") ~= "" then
		msgShort.txt = string.format("%s %s", msgLong.text, rRoll.sResults);
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sResults);
	end

	-- Add sTotal as number value via "diemodifier". This way the total damage will show up as a number in a white circle in chat
	msgShort.diemodifier = tonumber(sTotal)
	msgLong.diemodifier = tonumber(sTotal)

	ActionsManager.outputResult(rRoll.bSecret, rActor, rTarget, msgLong, msgShort);
end

-- ===================================================================================================================
-- TRACK DAMAGE STATE
-- ===================================================================================================================
-- Deliver damage message to Clients
-- ===================================================================================================================
local aDamageState = {};

-- ===================================================================================================================
-- ===================================================================================================================
function applyDamageState(rActor, rTarget, sAttack, sState)
	-- Debug.chat("FN: applyDamageState in manager_action_damage")
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMGSTATE;
	
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rActor);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rTarget);
	
	msgOOB.sAttack = sAttack;
	-- msgOOB.sState = sState;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- ===================================================================================================================
-- Catch damage message for delivery to Clients
-- ===================================================================================================================
function handleApplyDamageState(msgOOB)
	-- Debug.chat("FN: handleApplyDamageState in manager_action_damage")
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	if Session.IsHost then
		ActionDamage.setDamageState(rActor, rTarget, msgOOB.sAttack, msgOOB.sState);
	end
end

-- ===================================================================================================================
-- Set damage on Clients
-- ===================================================================================================================
function setDamageState(rActor, rTarget, sAttack, sState)
	-- Debug.chat("FN: setDamageState in manager_action_damage")
	if not Session.IsHost then
		ActionDamage.applyDamageState(rActor, rTarget, sAttack, sState);
		return;
	end
	
	local sSourceCT = ActorManager.getCTNodeName(rActor);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return;
	end
	
	if not aDamageState[sSourceCT] then
		aDamageState[sSourceCT] = {};
	end
	if not aDamageState[sSourceCT][sAttack] then
		aDamageState[sSourceCT][sAttack] = {};
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		aDamageState[sSourceCT][sAttack][sTargetCT] = {};
	end
	aDamageState[sSourceCT][sAttack][sTargetCT] = sState;
end

-- ===================================================================================================================
-- Get damage from Clients
-- ===================================================================================================================
function getDamageState(rActor, rTarget, sAttack)
	-- Debug.chat("FN: getDamageState in manager_action_damage")
	local sSourceCT = ActorManager.getCTNodeName(rActor);
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sSourceCT == "" or sTargetCT == "" then
		return "";
	end

	if not aDamageState[sSourceCT] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack] then
		return "";
	end
	if not aDamageState[sSourceCT][sAttack][sTargetCT] then
		return "";
	end
	
	local sState = aDamageState[sSourceCT][sAttack][sTargetCT];
	aDamageState[sSourceCT][sAttack][sTargetCT] = nil;

	return sState;
end