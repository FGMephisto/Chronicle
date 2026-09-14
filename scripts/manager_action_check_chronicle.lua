-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("check", ActionCheck.modRoll);
	ActionsManager.registerResultHandler("check", ActionCheck.onRoll);
end

function getRoll(rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bSecret = bSecretRoll or false;
	rRoll.sCheck = sCheck or "";
	rRoll.sAbility = Interface.getString(sCheck);
	rRoll.sType = "check";
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, sCheck);
	rRoll.nBonus = 0;
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;
	rRoll.nTarget = tonumber(nTargetDC) or 0;

	for i = 1, (tonumber(rRoll.nTest) or 0) do
		table.insert(rRoll.aDice, { type = "d6" });
	end

	rRoll.sDesc = rRoll.sAbility;

	return rRoll;
end

function performRoll(draginfo, rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = ActionCheck.getRoll(rActor, sCheck, nTargetDC, bSecretRoll);

	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performPartySheetRoll(draginfo, rActor, sCheck)
	local rRoll = ActionCheck.getRoll(rActor, sCheck);

	local nTargetDC = DB.getValue("partysheet.checkdc", 0);
	rRoll.nTarget = nTargetDC;

	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	rRoll.nTest = tonumber(rRoll.nTest) or 0;
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;
	rRoll.nAP = tonumber(rRoll.nAP) or 0;
	rRoll.nMod = tonumber(rRoll.nMod) or 0;

	-- Consider Armor Penalty
	ActionsManager2.encodeArmorMods(rRoll);

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll);

	-- Consider Health
	ActionsManager2.encodeHealthMods(rSource, rRoll);

	-- Consider Effects
	if rSource then
		local aCheckFilter = {};
		local bEffects = false;

		if (rRoll.sCheck or "") ~= "" then
			table.insert(aCheckFilter, rRoll.sCheck);
		end

		local aEffectsDice, nEffectsMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter);
		if nEffectCount > 0 then
			bEffects = true;
			for _,v in ipairs(aEffectsDice) do
				table.insert(aAddDice, v);
			end
			nAddMod = nAddMod + nEffectsMod;
		end

		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bEffects = true;
		end

		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
		end
	end

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll);

	-- Determine degrees of success
	rMessage, rRoll = ActionResult.DetermineSuccessTest(rMessage, rRoll);

	Comm.deliverChatMessage(rMessage);
end
