-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

rAction2 = {}

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerResultHandler("attack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);

	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionAttack.applyAttack(rSource, rTarget, rRoll);
end

function notifyApplyAttack(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	rRoll.bSecret = rRoll.bTower;
	rRoll.sResults = table.concat(rRoll.aMessages, " ");
	
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYATK;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		bRemoveOnMiss = (#aTargeting > 1);
	end
	
	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = "true";
		end
	end

	return aTargeting;
end

function performPartySheetVsRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
	
	ActionsManager.actionDirect(nil, "attack", { rRoll }, { { rActor } });
end

function performRoll(draginfo, rActor, rAction) -- Adjusted
	local rRoll = ActionAttack.getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction) -- Adjusted
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bWeapon = rAction.bWeapon;
	rRoll.sLabel = rAction.label;
	rRoll.sRange = rAction.range;
	rRoll.sType = "attack";
	rRoll.nTest = rAction.nStat or 0;
	rRoll.nBonus = rAction.nSkill or 0;
	rRoll.nPenalty = rAction.nPenalty or 0;
	rRoll.nDoS = 1;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = rAction.nMod or 0;
	rRoll.nodeWeapon = rAction.nodeWeapon;
	
	-- Save rAction as we need some of its data in function onAttack
	rAction2 = rAction
	
	-- Add Test Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6")
	end

	-- Add Bonus Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6")
	end

	-- Build the description label
	rRoll.sDesc = "[ATTACK"

	-- Add Attack range type
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
	end

	-- Add weapon name
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label

	return rRoll;
end

-- ===================================================================================================================
-- This function is used to modify the Roll record for Attack checks
-- ===================================================================================================================
function modAttack(rSource, rTarget, rRoll)
	-- Clear Critical
	ActionAttack.clearCritState(rSource);

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Correcting changes done in CorePRG
	rRoll.nTest = tonumber(rRoll.nTest)
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	rRoll.nMod = tonumber(rRoll.nMod)

	-- Check for opportunity attack
	local bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();

	if bOpportunity then
		table.insert(aAddDesc, "[OPPORTUNITY]");
	end

	-- Consider Health
	ActionsManager2.encodeHealthMods(rSource, rRoll)

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll)

	-- Check applying Effects
	if rSource then
		local aAttackFilter = {}
		local bEffects = false

		-- Determine attack type
		local sAttackType = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
		if not sAttackType then
			sAttackType = "M";
		end

		-- Build attack filter
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end

		-- Check for Weapon Grade
		-- local nodeWeapon = getDatabaseNode()
		-- local sWeaponGrade = DB.getValue(nodeWeapon, "wpn_grade", "")

		-- ToDo: Implement for Attack Roll
		-- if sWeaponGrade == "Poor" then
			-- nPenalty = nPenalty + 1
		-- elseif sWeaponGrade == "Superior" then
			-- nBonus = nBonus + 1
		-- elseif sWeaponGrade == "Extraordinary" then
			-- nBonus = nBonus + 1
		-- end

		-- Check if a two-handed weapon is used with one hand only and apply penalty dice accordingly
		-- ToDo: Implement for Attack Roll
		-- local sWeaponQualities = DB.getValue(nodeWeapon, "wpn_qualities", "")
		-- if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) == true and nWeaponHandling ~= 1 then
			-- nPenalty = nPenalty + 2
		-- end

		-- Check for modifiers
		-- Check for aim
		local bAim = ModifierManager.getKey("ATT_AIM")
		if bAim then
			table.insert(aAddDesc, "[Aim +1B]")
			rRoll.nBonus = rRoll.nBonus + 1
		end

		-- Check for higher ground
		local bHighground = ModifierManager.getKey("ATT_HIGHGROUND")
		if bHighground then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[HIGHGROUND +1B]")
				rRoll.nBonus = rRoll.nBonus + 1
			end
		end

		-- Check for cautious attack
		local bCautious = ModifierManager.getKey("ATT_CAUTIOUS")
		if bCautious then
			table.insert(aAddDesc, "[CAUTIOUS -1D, CoD +3]")
			rRoll.nPenalty = rRoll.nPenalty + 1
		end

		-- Check for reckless attack
		local bReckless = ModifierManager.getKey("ATT_RECKLESS")
		if bReckless then
			table.insert(aAddDesc, "[RECKLESS +1D, CoD -5]")
			rRoll.nTest = rRoll.nTest + 1
		end

		-- Check for cover
		local bCover = ModifierManager.getKey("DEF_COVER")
		if bCover then
			table.insert(aAddDesc, "[COVER -5]")
			nAddMod = nAddMod - 5
		end

		-- Check for superior cover
		local bSuperiorCover = ModifierManager.getKey("DEF_SCOVER")
		if bSuperiorCover then
			table.insert(aAddDesc, "[COVER -10]")
			nAddMod = nAddMod - 10
		end

		-- Check for shadowy light
		local bLowLight = ModifierManager.getKey("DEF_LOWLIGHT")
		if bLowLight then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[SHADOWY -1D]")
				rRoll.nPenalty = rRoll.nPenalty + 1
			elseif sAttackType == "R" then
				table.insert(aAddDesc, "[SHADOWY -2D]")
				rRoll.nPenalty = rRoll.nPenalty + 2
			end
		end

		-- Check for darkness
		local bNoLight = ModifierManager.getKey("DEF_NOLIGHT")
		if bNoLight then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[DARKNESS -2D]")
				rRoll.nPenalty = rRoll.nPenalty + 2
			elseif sAttackType == "R" then
				table.insert(aAddDesc, "[DARKNESS -4D]")
				rRoll.nPenalty = rRoll.nPenalty + 4
			end
		end

		-- Check for sprinting target
		local bSprint = ModifierManager.getKey("DEF_SPRINT")
		if bSprint then
			table.insert(aAddDesc, "[Moving Target -1D]")
			rRoll.nPenalty = rRoll.nPenalty + 1
		end		

		-- Apply collected nAddMod to rRoll.nMod
		rRoll.nMod = rRoll.nMod + nAddMod

		-- Get attack effect modifiers
		-- ToDo: Implement
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter, rTarget);

		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Get condition modifiers
		-- ToDo: List all conditions
		if EffectManager5E.hasEffectCondition(rSource, "Blinded") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Invisible") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bEffects = true;
		end
		if EffectManager.hasCondition(rSource, "Prone") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Restrained") then
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Unconscious") then
			bEffects = true;
		end

		-- If effects, then add them
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

	-- Build description string
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll)
end

function onAttack(rSource, rTarget, rRoll) -- Adjusted
	-- Rebuild detail fields if dragging from chat window
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll)

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	-- Add message array to rRoll, this is required for DoS output
	rRoll.aMessages = {};

	-- Determine Target Combat Defense and defense bonus effects
	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);

	if rRoll.nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end

	if rRoll.nDefEffectsBonus ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, string.format("[%s %+d]", Interface.getString("effects_def_tag"), rRoll.nDefEffectsBonus));
	end

	-- Determine degrees of success
	if rRoll.nDefenseVal then
		rMessage, rRoll = ActionResult.DetermineSuccessAttack(rMessage, rRoll)
	end

	-- Save quality of attack for use in damage calculation
	DB.setValue(rAction2.nodeWeapon, "dmg_multiplier", "number", rRoll.nDoS - 1)

	-- Build chat message if no target was selected
	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end

	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
end

function onPreAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- Do nothing; location to override
end

function onAttackResolve(rSource, rTarget, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);
	
	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll);
	end
	
	-- TRACK CRITICAL STATE
	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end
	
	-- REMOVE TARGET ON MISS OPTION
	if rTarget then
		if (rRoll.sResult == "miss" or rRoll.sResult == "fumble") then
			if rRoll.bRemoveOnMiss then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onPostAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- Debug.chat("FN: onPostAttackResolve in manager_action_attack")
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rRoll.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		ActionAttack.notifyApplyHRFC("Fumble");
	end
	if rRoll.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		ActionAttack.notifyApplyHRFC("Critical Hit");
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function applyAttack(rSource, rTarget, rRoll)
	-- Debug.chat("FN: applyAttack in manager_action_attack")
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };
	
	-- Standard roll information
	msgShort.text = "[Attack";
	msgLong.text = "[Attack";

	if rRoll.nOrder then
		msgShort.text = string.format("%s #%d", msgShort.text, rRoll.nOrder);
		msgLong.text = string.format("%s #%d", msgLong.text, rRoll.nOrder);
	end
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end

	msgShort.text = string.format("%s]", msgShort.text);
	msgLong.text = string.format("%s]", msgLong.text);

	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s %s", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sLabel or "");
	end
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
		msgShort.text = string.format("%s [at %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [at %s]", msgLong.text, sTargetName);
	end

	-- Extra roll information
	msgShort.icon = "roll_attack";
	if (rRoll.sResults or "") ~= "" then
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sResults);
		if rRoll.sResults:match("%[CRITICAL HIT%]") then
			msgLong.icon = "roll_attack_crit";
		elseif rRoll.sResults:match("HIT%]") then
			msgLong.icon = "roll_attack_hit";
		elseif rRoll.sResults:match("MISS%]") then
			msgLong.icon = "roll_attack_miss";
		else
			msgLong.icon = "roll_attack";
		end
	else
		msgLong.icon = "roll_attack";
	end

	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

--
--	CRIT STATE TRACKING
--

aCritState = {};

-- ===================================================================================================================
-- ===================================================================================================================
function setCritState(rSource, rTarget)
	-- Debug.chat("FN: setCritState in manager_action_attack")
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end
	
	if not aCritState[sSourceCT] then
		aCritState[sSourceCT] = {};
	end
	table.insert(aCritState[sSourceCT], sTargetCT);
end

-- ===================================================================================================================
-- ===================================================================================================================
function clearCritState(rSource)
	-- Debug.chat("FN: clearCritState in manager_action_attack")
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function isCrit(rSource, rTarget)
	-- Debug.chat("FN: isCrit in manager_action_attack")
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end

	if not aCritState[sSourceCT] then
		return false;
	end
	
	for k,v in ipairs(aCritState[sSourceCT]) do
		if v == sTargetCT then
			table.remove(aCritState[sSourceCT], k);
			return true;
		end
	end
	
	return false;
end