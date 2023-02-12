-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	ActionsManager.registerModHandler("check", modRoll);
	ActionsManager.registerResultHandler("check", onRoll);
end

-- ===================================================================================================================
-- ===================================================================================================================
function performPartySheetRoll(draginfo, rActor, sCheck)
	-- Debug.chat("FN: performPartySheetRoll in manager_action_check")
	local rRoll = getRoll(rActor, sCheck);

	local nTargetDC = DB.getValue("partysheet.checkdc", 0);

	rRoll.nTarget = nTargetDC;

	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- ===================================================================================================================
-- ===================================================================================================================
function performRoll(draginfo, rActor, sCheck, nTargetDC, bSecretRoll)
	-- Debug.chat("FN: performRoll in manager_action_check")
	local rRoll = getRoll(rActor, sCheck, nTargetDC, bSecretRoll);

	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function getRoll(rActor, sCheck, nTargetDC, bSecretRoll)
	-- Debug.chat("FN: getRoll in manager_action_check")
	-- Build rRoll
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bSecret = bSecretRoll or false;
	rRoll.sCheck = sCheck;
	rRoll.sAbility = Interface.getString(sCheck);
	rRoll.sType = "check";
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, sCheck);
	rRoll.nBonus = 0;
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;
	rRoll.nTarget = nTargetDC or 0;

	-- Add Test Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6")
	end

	-- Add Bonus Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6")
	end

	-- Concatenate strings
	rRoll.sDesc = rRoll.sAbility

	return rRoll;
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function modRoll(rSource, rTarget, rRoll)
	-- Debug.chat("FN: modRoll in manager_action_check")
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Correcting changes done in CorePRG
	rRoll.nTest = tonumber(rRoll.nTest)
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	rRoll.nAP = tonumber(rRoll.nAP)
	rRoll.nMod = tonumber(rRoll.nMod)

	-- Consider Armor Penalty
	ActionsManager2.encodeArmorMods(rRoll)

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll)
	
	-- Consider Health
	ActionsManager2.encodeHealthMods(rSource, rRoll)

	-- Consider Effects
	if rSource then
		local aCheckFilter = {}
		local bEffects = false;

		-- Add Ability to aCheckFilter
		if rRoll.sCheck then
			table.insert(aCheckFilter, rRoll.sCheck)
		end

		-- Get roll effect modifiers
		local nEffectCount

		-- ToDo: Adjust Effects Bonus to handle Test/Bonus/Penalty Dice
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter)

		-- Count effects
		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Get condition modifiers
		-- ToDo: Add possible Effects
		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bEffects = true;
		end

		if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bEffects = true;
		end

		-- If effects happened, then add note
		-- ToDo: Does it work?
		if bEffects then
			local sEffects = "";

			-- ToDo: Get what the function does
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);

			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end

	-- Build description string
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll)
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onRoll(rSource, rTarget, rRoll)
	-- Debug.chat("FN: onRoll in manager_action_check")
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	-- Determine degrees of success
	rMessage, rRoll = ActionResult.DetermineSuccessTest(rMessage, rRoll)

	Comm.deliverChatMessage(rMessage);
end
