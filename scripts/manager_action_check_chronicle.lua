-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	ActionsManager.registerModHandler("check", modRoll);
	ActionsManager.registerResultHandler("check", onRoll);
end

-- Adjusted
function performPartySheetRoll(draginfo, rActor, sCheck)
	local rRoll = getRoll(rActor, sCheck:lower());
	
	local nTargetDC = DB.getValue("partysheet.checkdc", 0);

	rRoll.nTarget = nTargetDC;
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performRoll(draginfo, rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = getRoll(rActor, sCheck, nTargetDC, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- Adjusted
function getRoll(rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.aDice = DiceRollManager.getActorDice({ }, rActor);
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

--
-- Adjusted
--
function modRoll(rSource, rTarget, rRoll)
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
	
	local bADV = false;
	local bDIS = false;
	-- if rRoll.sDesc:match(" %[ADV%]") then
		-- bADV = true;
		-- rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	-- end
	-- if rRoll.sDesc:match(" %[DIS%]") then
		-- bDIS = true;
		-- rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	-- end

	if rSource then
		local bEffects = false;

		-- Get ability used
		-- local sActionStat = nil;
		-- local sAbility = rRoll.sDesc:match("%[CHECK%] (%w+)");
		-- if not sAbility then
			-- local sSkill = rRoll.sDesc:match("%[SKILL%] (%w+)");
			-- if sSkill then
				-- sAbility = rRoll.sDesc:match("%[MOD:(%w+)%]");
				-- if sAbility then
					-- sAbility = DataCommon.ability_stol[sAbility];
				-- else
					-- for k, v in pairs(DataCommon.skilldata) do
						-- if k == sSkill then
							-- sAbility = v.stat;
						-- end
					-- end
				-- end
			-- end
		-- end
		-- if sAbility then
			-- sAbility = sAbility:lower();
		-- end

		-- Build filter
		local aCheckFilter = {};
		-- if sAbility then
			-- table.insert(aCheckFilter, sAbility);
		-- end

		-- Count effects
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		-- ToDo: Add possible Effects
		if EffectManager5E.hasEffectCondition(rSource, "ADVCHK") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVCHK", aCheckFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISCHK") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISCHK", aCheckFilter)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bDIS = true;
			bEffects = true;
		end
		-- if StringManager.contains({ "strength", "dexterity", "constitution" }, sAbility) then
			-- if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
				-- bEffects = true;
				-- bDIS = true;
			-- end
		-- end

		-- Get ability modifiers
		-- local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, sAbility);
		-- if nBonusEffects > 0 then
			-- bEffects = true;
			-- nAddMod = nAddMod + nBonusStat;
		-- end
		
		-- Get exhaustion modifiers
		-- local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		-- if nExhaustCount > 0 then
			-- bEffects = true;
			-- nAddMod = nAddMod - (2 * nExhaustMod);
		-- end
		
		-- Check Reliable state
		-- local bReliable = false;
		-- if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
			-- bEffects = true;
			-- bReliable = true;
		-- elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLECHK") then
			-- bEffects = true;
			-- bReliable = true;
		-- elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLECHK", aCheckFilter)) > 0 then
			-- bEffects = true;
			-- bReliable = true;
		-- end
		-- if bReliable then
			-- table.insert(aAddDesc, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
		-- end

		-- If effects happened, then add note
		-- ToDo: Does it work?
		if bEffects then
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
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

-- Adjusted
function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	-- Determine degrees of success
	rMessage, rRoll = ActionResult.DetermineSuccessTest(rMessage, rRoll)

	Comm.deliverChatMessage(rMessage);
end
