--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVEVS = "applysavevs";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionPowerSave.OOB_MSGTYPE_APPLYSAVEVS, ActionPowerSave.handleApplyPowerSave);

	ActionsManager.registerTargetingHandler("powersave", ActionCore.onTargeting);
	ActionsManager.registerModHandler("powersave", ActionPowerSave.modPowerSave);
	ActionsManager.registerResultHandler("powersave", ActionPowerSave.onPowerSave);
end

--
--	POWER SAVE HANDLING (SAVE VS.)
--

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionPowerSave.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function getRoll(rActor, rAction)
	local rRoll = {
		sType = "powersave",
		sDesc = ActionCore.encodeActionText(rAction, "action_savevs_tag"),
		sSave = rAction.save,
		aDice = {},
		nMod = rAction.savemod or 0,
		bEffects = false,
		nEffectMod = 0,
		tNotifications = {},
		tActionTags = rAction.tActionTags,
	};

	if OptionsManager.isOption("HRSE", "on") then
		ActionsManager2.applyExhaustionEffectsToRollMod(rRoll, rActor);
	end
	if DataCommon.ability_ltos[rAction.save] then
		local nBonusStat, nBonusEffects = ActorManagerD20.getAbilityEffectsBonus(rActor, rAction.savestat);
		if nBonusEffects > 0 then
			rRoll.bEffects = true;
			rRoll.nEffectMod = rRoll.nEffectMod + nBonusStat;
		end
	end
	rRoll.nMod = rRoll.nMod + rRoll.nEffectMod;

	if DataCommon.ability_ltos[rAction.save] then
		local sDC = string.format("[%s DC %d]", DataCommon.ability_ltos[rAction.save], rRoll.nMod);
		table.insert(rRoll.tNotifications, sDC);
	end
	if rAction.magic then
		table.insert(rRoll.tNotifications, "[MAGIC]");
	end
	if rAction.onmissdamage == "half" then
		table.insert(rRoll.tNotifications, "[HALF ON SAVE]");
	end
	if rRoll.bEffects then
		local sMod = StringManager.convertDiceToString(nil, rRoll.nEffectMod, true);
		table.insert(rRoll.tNotifications, EffectManager.buildEffectOutput(sMod));
	end
	if #(rRoll.tNotifications) > 0 then
		rRoll.sDesc = rRoll.sDesc .. "\r" .. table.concat(rRoll.tNotifications, "\r");
	end

	rRoll.bEffects = nil;
	rRoll.nEffectMod = nil;
	rRoll.tNotifications = nil;

	if Session.IsHost and (OptionsManager.isOption("REVL", "off") or CombatManager.isCTHidden(ActorManager.getCTNode(rActor))) then
		rRoll.bSecret = true;
	end

	return rRoll;
end

function modPowerSave(_, _, rRoll)
	if (rRoll.sSave or "") == "dexterity" then
		if ModifierManager.getKey("DEF_SCOVER") then
			rRoll.sDesc = StringManager.appendLine(rRoll.sDesc, "[COVER +5]");
		elseif ModifierManager.getKey("DEF_COVER") then
			rRoll.sDesc = StringManager.appendLine(rRoll.sDesc, "[COVER +2]");
		end
	end
	return true;
end

function onPowerSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort,_ = rRoll.sDesc:match("%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.ability_stol[sSaveShort];
			if sSave then
				ActionPowerSave.notifyApplyPowerSave(rSource, rTarget, rRoll);
				return;
			end
		end
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

--
--	CAST HANDLING
--

function notifyApplyPowerSave(rSource, rTarget, rRoll)
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionPowerSave.OOB_MSGTYPE_APPLYSAVEVS;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplyPowerSave(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rSaveVsRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionPowerSave.performOpposedRoll(rSource, rTarget, rSaveVsRoll);
end

function performOpposedRoll(rSource, rTarget, rSaveVsRoll)
	if not rSaveVsRoll then
		return;
	end
	local sSave = rSaveVsRoll.sSave;
	local nTarget = rSaveVsRoll.nTarget;
	if not sSave or not nTarget then
		local sSaveShort, sSaveDC = (rSaveVsRoll.sDesc or ""):match("%[(%w+) DC (%d+)%]");
		sSave = DataCommon.ability_stol[sSaveShort or ""];
		if not sSave then
			return;
		end
		nTarget = tonumber(sSaveDC) or 0;
	end

	local rRoll = ActionSave.getRoll(rTarget, sSave);
	rRoll.bVsSave = true;
	rRoll.sSaveDesc = rSaveVsRoll.sDesc;
	rRoll.bSecret = rSaveVsRoll.bSecret;
	rRoll.nTarget = nTarget;
	rRoll.bRemoveOnMiss = rSaveVsRoll.bRemoveOnMiss;
	rRoll.sEffectRecord = rSaveVsRoll.sEffectRecord;
	rRoll.tActionTags = rSaveVsRoll.tActionTags;

	local nTotal, nEffectCount = EffectManager.getBonusMod(rSource, "SAVEDC", { rTarget = rTarget, tActionTags = rRoll.tActionTags });
	if nEffectCount > 0 then
		rRoll.sDesc = StringManager.appendLine(rRoll.sDesc, EffectManager.buildEffectOutput(nTotal));
		rRoll.nTarget = rRoll.nTarget + nTotal;
	end

	-- Legacy (2026-08)
	rRoll.sSource = ActorManager.getCTNodeName(rSource);

	ActionsManager.actionDirect(rTarget, rRoll.sType, { rRoll }, { { rSource } });
end
