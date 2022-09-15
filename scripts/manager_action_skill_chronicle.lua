-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	ActionsManager.registerModHandler("skill", modRoll)
	ActionsManager.registerResultHandler("skill", onRoll)
end

-- ===================================================================================================================
-- ===================================================================================================================
function performNPCRoll(draginfo, rActor, sSkill, nSkill)
	-- Debug.chat("FN: performNPCRoll in manager_action_skill")
	-- Build rRoll
	local rRoll = {}
	rRoll.aDice = {}
	rRoll.bSecret = true
	rRoll.sStat = ""
	rRoll.sAbility = ""
	rRoll.sSkill = StringManager.capitalize(sSkill)
	rRoll.sType = "skill"
	rRoll.nTest = 0
	rRoll.nBonus = nSkill
	rRoll.nPenalty = 0
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor)
	rRoll.nMod = 0
	rRoll.nTarget = 0

	-- Try to get the linked Ability.
	if DataCommon.skilldata[rRoll.sSkill] ~= nil then
		rRoll.sStat = DataCommon.skilldata[rRoll.sSkill].stat
		rRoll.sAbility = Interface.getString(rRoll.sStat)
	end

	-- Get Ability score
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat)

	-- Add all Die to Dice Array. This is necessary to have the proper number of die show up on drag
	for i = 1, rRoll.nTest + rRoll.nBonus do
		table.insert(rRoll.aDice, "d6")
	end

	-- Concatenate strings	
	rRoll.sDesc = rRoll.sAbility .. " (" .. rRoll.sSkill .. ")"

	-- Roll hidden if host and CT is hidden
	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true
	end

	ActionsManager.performAction(draginfo, rActor, rRoll)
end

-- ===================================================================================================================
-- ===================================================================================================================
function performPartySheetRoll(draginfo, rActor, sSkill)
	-- Debug.chat("FN: performPartySheetRoll in manager_action_skill")
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)

	-- Exit gracefully if not a PC
	if sNodeType ~= "pc" then
		return
	end

	local rRoll = nil

	-- Get skill
	for _,v in pairs(DB.getChildren(nodeActor, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			rRoll = getRoll(rActor, v)
			break
		end
	end

	-- Get DC entered on Party Sheet
	local nTargetDC = DB.getValue("partysheet.skilldc", 0)
	rRoll.nTarget = nTargetDC

	-- Check if roll is secret
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true
		rRoll.bTower = true
	end

	ActionsManager.performAction(draginfo, rActor, rRoll)
end

-- ===================================================================================================================
-- ===================================================================================================================
function performRoll(draginfo, rActor, nodeSkill, nTargetDC, bSecretRoll)
	-- Debug.chat("FN: performRoll in manager_action_skill")
	local rRoll = getRoll(rActor, nodeSkill, nTargetDC, bSecretRoll)

	-- Roll hidden if host and CT is hidden
	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true
	end

	ActionsManager.performAction(draginfo, rActor, rRoll)
end

-- ===================================================================================================================
-- This function is used to build the inital rRoll record for Skill checks
-- ===================================================================================================================
 function getRoll(rActor, nodeSkill)
	-- Debug.chat("FN: getRoll in manager_action_skill")
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)

	-- Build rRoll
	local rRoll = {}
	rRoll.aDice = {}
	rRoll.sStat = DB.getValue(nodeSkill, "stat", "")
	rRoll.sAbility = Interface.getString(rRoll.sStat)
	rRoll.sSkill = 	DB.getValue(nodeSkill, "name", "")
	rRoll.sType = "skill"
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat)
	rRoll.nBonus = ActorManager5E.getSkillRank(rActor, rRoll.sSkill)
	rRoll.nPenalty = 0
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor)
	rRoll.nMod = 0
	rRoll.nTarget = 0

	-- Add all Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nTest + rRoll.nBonus  do
		table.insert(rRoll.aDice, "d6")
	end

	-- Concatenate strings	
	rRoll.sDesc = rRoll.sAbility .. " (" .. rRoll.sSkill .. ")"

	return rRoll
end

-- ===================================================================================================================
-- This function is used to modify the Roll record for Skill checks
-- ===================================================================================================================
function modRoll(rActor, rTarget, rRoll)
	-- Debug.chat("FN: modRoll in manager_action_skill")
	local aAddDesc = {}
	local aAddDice = {}
	local nAddMod = 0

	-- Correcting changes done in CorePRG
	rRoll.nTest = tonumber(rRoll.nTest)
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	rRoll.nAP = tonumber(rRoll.nAP)
	rRoll.nMod = tonumber(rRoll.nMod)

	-- Consider Effects
	if rActor then
		local bEffects = false

		-- Add Ability to aCheckFilter
		local aCheckFilter = {}
		if rRoll.sAbility then
			table.insert(aCheckFilter, rRoll.sStat)
		end

		-- Add Skill to aSkillFilter
		local aSkillFilter = {}
		if rRoll.sSkill then
			table.insert(aSkillFilter, rRoll.sSkill:lower())
		end

		-- Get roll effect modifiers
		local nEffectCount
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rActor, {"CHECK"}, false, aCheckFilter)

		-- Count effects
		if (nEffectCount > 0) then
			bEffects = true
		end

		-- ToDo: Build this
		local aSkillAddDice, nSkillAddMod, nSkillEffectCount = EffectManager5E.getEffectsBonus(rActor, {"SKILL"}, false, aSkillFilter)

		if (nSkillEffectCount > 0) then
			bEffects = true
			for _,v in ipairs(aSkillAddDice) do
				table.insert(aAddDice, v)
			end
			nAddMod = nAddMod + nSkillAddMod
		end
		
		-- Get condition modifiers
		-- Placeholder
		if EffectManager5E.hasEffectCondition(rActor, "Frightened") then
			bEffects = true
		end

		-- If effects happened, then add note
		-- ToDo: Make it work also with Abilities
		if bEffects then
			local sEffects = ""

			-- ToDo: Get what the function does
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true)

			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]"
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]"
			end
			table.insert(aAddDesc, sEffects)
		end
	end

	-- Build description string
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ")
	end

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll)

	-- Consider Armor Penalty
	ActionsManager2.encodeArmorMods(rRoll)

	-- Consider Health
	ActionsManager2.encodeHealthMods(rActor, rRoll)

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll)

	-- CoreRPG function "applyModifiers" checks if the registered handling function is handing over a dice expression (e.g. 5D6)
	-- If the handling function does not return "true", it removes the expression so we need to return "true" as we are handing over expressions
	-- return true
end

-- ===================================================================================================================
-- ===================================================================================================================
function onRoll(rActor, rTarget, rRoll)
	-- Debug.chat("FN: onRoll in manager_action_skill")
	local rMessage = ActionsManager.createActionMessage(rActor, rRoll)

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	-- Determine degrees of success
	rMessage, rRoll = ActionResult.DetermineSuccessTest(rMessage, rRoll)

	Comm.deliverChatMessage(rMessage)
end