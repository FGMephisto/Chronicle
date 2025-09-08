--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionInit.OOB_MSGTYPE_APPLYINIT, ActionInit.handleApplyInit);

	ActionsManager.registerModHandler("init", ActionInit.modRoll);
	ActionsManager.registerResultHandler("init", ActionInit.onResolve);
end

-- Set Initiative result on CT
function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end

-- Communicate initiative roll to Clients
function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end

	local msgOOB = {};
	msgOOB.type = ActionInit.OOB_MSGTYPE_APPLYINIT;

	msgOOB.nTotal = nTotal;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

--
--	ROLL BUILD/MOD/RESOLVE
--

-- Adjusted
function getRoll(rActor, bSecret)
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bSecret = bSecretRoll;
	rRoll.sStat = "agility";
	rRoll.sAbility = "Agility";
	rRoll.sSkill = "Quickness";
	rRoll.sType = "init";
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat);
	rRoll.nBonus = ActorManager5E.getSkillRank(rActor, rRoll.sSkill);
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;

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

	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = ActionInit.getRoll(rActor, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- Adjusted
function modRoll(rSource, rTarget, rRoll)
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
	if rSource then
		local bEffects, aEffectDice, nEffectMod = getEffectAdjustments(rSource);
		if bEffects then
			for _,vDie in ipairs(aEffectDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nEffectMod;

			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
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

-- Adjusted - Returns effect existence, effect dice, effect mod
function getEffectAdjustments(rActor)
	-- Debug.chat("FN getEffectAdjustments in manager_action_init")
	-- ToDo: Adjust to work with Chronicle
	if not rActor then
		return false, {}, 0, false, false;
	end
	
	-- Determine ability used - Only agility for this ruleset
	local sActionStat = "agility";
	
	-- Initialize
	local bEffects = false;
	local aEffectDice = {};
	local nEffectMod = 0;
	
	-- Determine general effect modifiers
	local aInitDice, nInitMod, nInitCount = EffectManager5E.getEffectsBonus(rActor, {"INIT"});
	if nInitCount > 0 then
		bEffects = true;
		for _,vDie in ipairs(aInitDice) do
			table.insert(aEffectDice, vDie);
		end
		nEffectMod = nEffectMod + nInitMod;
	end
	
	-- Get ability effect modifiers
	local nAbilityMod, nAbilityEffects = ActorManager5E.getAbilityEffectsBonus(rActor, sActionStat);
	if nAbilityEffects > 0 then
		bEffects = true;
	end
	
	-- Ability check modifiers
	local aCheckFilter = { sActionStat };
	local aAbilityCheckDice, nAbilityCheckMod, nAbilityCheckCount = EffectManager5E.getEffectsBonus(rActor, {"CHECK"}, false, aCheckFilter);
	if (nAbilityCheckCount > 0) then
		bEffects = true;
		for _,vDie in ipairs(aAbilityCheckDice) do
			table.insert(aEffectDice, vDie);
		end
		nEffectMod = nEffectMod + nAbilityCheckMod;
	end
	
	-- Get exhaustion modifiers
	local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rActor, {"EXHAUSTION"}, true);
	if nExhaustCount > 0 then
		bEffects = true;
		if nExhaustMod >= 1 then
		end
	end
	
	return bEffects, aEffectDice, nEffectMod;
end

function onResolve(rSource, rTarget, rRoll)
	-- Debug.chat("FN onResolve in manager_action_init")
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	Comm.deliverChatMessage(rMessage);
	
	local nTotal = ActionsManager.total(rRoll);
	notifyApplyInit(rSource, nTotal);
end

--
--	ROLL BUILDING HELPERS
--

function setupRollBuild(rRoll, rActor)
	table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("action_init_tag")));

	-- Determine the modifier and ability to use for this roll
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		if ActorManager.isPC(rActor) then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);

			-- Check for armor non-proficiency
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				rRoll.bDIS = true;
				table.insert(rRoll.tNotifications, Interface.getString("roll_msg_armor_nonprof"));
			end
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
end

--
--	OTHER
--

-- Used in combat manager script to get initiative adjustments for automatic initiative
-- Returns effect existence, effect dice, effect mod, effect advantage, effect disadvantage
function getEffectAdjustments(rActor)
	local rRoll = {
		sType = "init",
		bEffects = false,
		tEffectDice = {},
		nEffectMod = 0,
		tCheckFilter = { "dexterity" },
	};
	ActionCheck.applyEffectsToRollMod(rRoll, rActor);
	return rRoll.bEffects, rRoll.tEffectDice, rRoll.nEffectMod, rRoll.bADV, rRoll.bDIS;
end