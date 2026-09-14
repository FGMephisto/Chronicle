--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionInit.OOB_MSGTYPE_APPLYINIT, ActionInit.handleApplyInit);

	ActionsManager.registerModHandler("init", ActionInit.modRoll);
	ActionsManager.registerResultHandler("init", ActionInit.onResolve);
end

function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end

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

function getRoll(rActor, bSecretRoll)
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

	for _ = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6");
	end
	for _ = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6");
	end

	rRoll.sDesc = "[INITIATIVE] " .. rRoll.sAbility .. " (" .. rRoll.sSkill .. ")";
	return rRoll;
end

function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = ActionInit.getRoll(rActor, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, _, rRoll)
	rRoll.nTest = tonumber(rRoll.nTest) or 0;
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;
	rRoll.nAP = tonumber(rRoll.nAP) or 0;
	rRoll.nMod = tonumber(rRoll.nMod) or 0;

	ActionsManager2.encodeArmorMods(rRoll);
	ActionsManager2.encodeDesktopMods(rRoll);
	ActionsManager2.encodeHealthMods(rSource, rRoll);

	if rSource then
		local bEffects, aEffectDice, nEffectMod = ActionInit.getEffectAdjustments(rSource);
		if bEffects then
			for _, vDie in ipairs(aEffectDice) do
				if vDie:sub(1, 1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nEffectMod;

			local sMod = StringManager.convertDiceToString(aEffectDice, nEffectMod, true);
			local sEffects;
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end

	ActionResult.capDice(rRoll);
end

function onResolve(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rRoll = ActionResult.DropDice(rRoll);

	Comm.deliverChatMessage(rMessage);

	local nTotal = ActionsManager.total(rRoll);
	ActionInit.notifyApplyInit(rSource, nTotal);
end

--
-- CHRONICLE CUSTOM SYSTEMS
--

function getEffectAdjustments(rActor)
	if not rActor then
		return false, {}, 0;
	end

	local sActionStat = "agility";
	local bEffects = false;
	local aEffectDice = {};
	local nEffectMod = 0;

	local aInitDice, nInitMod, nInitCount = EffectManager5E.getEffectsBonus(rActor, { "INIT" });
	if nInitCount > 0 then
		bEffects = true;
		for _, vDie in ipairs(aInitDice) do
			table.insert(aEffectDice, vDie);
		end
		nEffectMod = nEffectMod + nInitMod;
	end

	local _, nAbilityEffects = ActorManager5E.getAbilityEffectsBonus(rActor, sActionStat);
	if nAbilityEffects > 0 then
		bEffects = true;
	end

	local aCheckFilter = { sActionStat };
	local aAbilityCheckDice, nAbilityCheckMod, nAbilityCheckCount = EffectManager5E.getEffectsBonus(rActor, { "CHECK" }, false, aCheckFilter);
	if (nAbilityCheckCount > 0) then
		bEffects = true;
		for _, vDie in ipairs(aAbilityCheckDice) do
			table.insert(aEffectDice, vDie);
		end
		nEffectMod = nEffectMod + nAbilityCheckMod;
	end

	local _, nExhaustCount = EffectManager5E.getEffectsBonus(rActor, { "EXHAUSTION" }, true);
	if nExhaustCount > 0 then
		bEffects = true;
	end

	return bEffects, aEffectDice, nEffectMod;
end