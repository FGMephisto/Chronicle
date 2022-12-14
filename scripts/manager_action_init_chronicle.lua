-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

OOB_MSGTYPE_APPLYINIT = "applyinit"

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit)

	ActionsManager.registerModHandler("init", modRoll)
	ActionsManager.registerResultHandler("init", onRoll)
	-- ActionsManager.registerResultHandler("init", onResolve)
end

-- ===================================================================================================================
-- Set Initiative result on CT
-- ===================================================================================================================
function handleApplyInit(msgOOB)
	-- Debug.chat("FN: handleApplyInit in manager_action_init")
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode)
	local nTotal = tonumber(msgOOB.nTotal) or 0

	DB.setValue(ActorManager.getCTNode(rActor), "initresult", "number", nTotal)
end

-- ===================================================================================================================
-- Communicate initiative roll to Clients
-- ===================================================================================================================
function notifyApplyInit(rActor, nTotal)
	-- Debug.chat("FN: notifyApplyInit in manager_action_init")
	if not rActor then
		return
	end

	local msgOOB = {}
	msgOOB.type = OOB_MSGTYPE_APPLYINIT

	msgOOB.nTotal = nTotal

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rActor)

	Comm.deliverOOBMessage(msgOOB, "")
end

-- ===================================================================================================================
-- ===================================================================================================================
function performRoll(draginfo, rActor, bSecretRoll, bHideMessage)
	-- Debug.chat("FN: performRoll in manager_action_init")
	local rRoll = getRoll(rActor, bSecretRoll, bHideMessage)
	
	ActionsManager.performAction(draginfo, rActor, rRoll)
end

-- ===================================================================================================================
-- ===================================================================================================================
function getRoll(rActor, bSecretRoll, bHideMessage)
	-- Debug.chat("FN: getRoll in manager_action_init")
	local rRoll = {}
	rRoll.aDice = {}
	rRoll.bSecret = bSecretRoll
	rRoll.bHideMessage = bHideMessage
	rRoll.sStat = "agility"
	rRoll.sAbility = "Agility"
	rRoll.sSkill = "Quickness"
	rRoll.sType = "init"
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat)
	rRoll.nBonus = ActorManager5E.getSkillRank(rActor, rRoll.sSkill)
	rRoll.nPenalty = 0
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor)
	rRoll.nMod = 0

	-- Add Test Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6")
	end

	-- Add Bonus Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6")
	end

	-- Concatenate strings	
	rRoll.sDesc = "[INITIATIVE] " .. rRoll.sAbility .. " (" .. rRoll.sSkill .. ")"

	return rRoll
end

-- ===================================================================================================================
-- ===================================================================================================================
function modRoll(rActor, rTarget, rRoll)
	-- Debug.chat("FN: modRoll in manager_action_init")
	local aAddDesc = {}
	local aAddDice = {}
	local nAddMod = 0
	local nAddTest = 0
	local nAddBonus = 0
	local nAddPenalty = 0

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
	ActionsManager2.encodeHealthMods(rActor, rRoll)

	-- ToDo: Handle Effects
	if rActor then
		local bEffects, aEffectDice, nEffectMod  = getEffectAdjustments(rActor)

		if bEffects then
			for _,vDie in ipairs(aEffectDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3))
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2))
				end
			end
			rRoll.nMod = rRoll.nMod + nEffectMod

			local sEffects = ""
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true)
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "] "
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "] "
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects
		end
	end

	-- Build effects description strings
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. table.concat(aAddDesc)
	end

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll)
end

-- ===================================================================================================================
-- Returns effect existence, effect dice, effect mod
-- ===================================================================================================================
function getEffectAdjustments(rActor)
	-- ToDo: Adjust to work with Chronicle
	-- Debug.chat("FN: getEffectAdjustments in manager_action_init")
	if not rActor then
		return false, {}, 0, false, false
	end
	
	-- Determine ability used - Only agility for this ruleset
	local sActionStat = "agility"
	
	-- Initialize
	local bEffects = false
	local aEffectDice = {}
	local nEffectMod = 0
	
	-- Determine general effect modifiers
	local aInitDice, nInitMod, nInitCount = EffectManager5E.getEffectsBonus(rActor, {"INIT"})
	if nInitCount > 0 then
		bEffects = true
		for _,vDie in ipairs(aInitDice) do
			table.insert(aEffectDice, vDie)
		end
		nEffectMod = nEffectMod + nInitMod
	end
	
	-- Get ability effect modifiers
	local nAbilityMod, nAbilityEffects = ActorManager5E.getAbilityEffectsBonus(rActor, sActionStat)
	if nAbilityEffects > 0 then
		bEffects = true
		nEffectMod = nEffectMod + nAbilityMod
	end
	
	-- Ability check modifiers
	local aCheckFilter = { sActionStat }
	local aAbilityCheckDice, nAbilityCheckMod, nAbilityCheckCount = EffectManager5E.getEffectsBonus(rActor, {"CHECK"}, false, aCheckFilter)
	if (nAbilityCheckCount > 0) then
		bEffects = true
		for _,vDie in ipairs(aAbilityCheckDice) do
			table.insert(aEffectDice, vDie)
		end
		nEffectMod = nEffectMod + nAbilityCheckMod
	end
	
	-- Get exhaustion modifiers
	local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rActor, {"EXHAUSTION"}, true)
	if nExhaustCount > 0 then
		bEffects = true
		if nExhaustMod >= 1 then
		end
	end
	
	return bEffects, aEffectDice, nEffectMod
end

-- ===================================================================================================================
-- ===================================================================================================================
function onRoll(rActor, rTarget, rRoll)
-- function onResolve(rActor, rTarget, rRoll)
	-- Debug.chat("FN: onRoll in manager_action_init")
	local rMessage = ActionsManager.createActionMessage(rActor, rRoll)

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	if not rRoll.bHideMessage then
		Comm.deliverChatMessage(rMessage)
	end

	notifyApplyInit(rActor, tonumber(rRoll.nTotal))
end