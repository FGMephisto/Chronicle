--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVEVS = "applysavevs";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionPower.OOB_MSGTYPE_APPLYSAVEVS, ActionPower.handleApplySaveVs);

	ActionsManager.registerTargetingHandler("cast", ActionCore.onTargeting);
	ActionsManager.registerResultHandler("cast", ActionPower.onPowerCast);

	ActionsManager.registerTargetingHandler("powersave", ActionCore.onTargeting);
	ActionsManager.registerModHandler("powersave", ActionPower.modCastSave);
	ActionsManager.registerResultHandler("powersave", ActionPower.onPowerSave);
end

--
--	CAST HANDLING
--

function handleApplySaveVs(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);

	local sSaveShort,_ = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.ability_stol[sSaveShort];
		if sSave then
			ActionSave.performVsRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, (tonumber(msgOOB.nRemoveOnMiss) == 1), msgOOB.sDesc);
		end
	end
end
function notifyApplySaveVs(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = ActionPower.OOB_MSGTYPE_APPLYSAVEVS;
	msgOOB.sUser = Session.UserName;

	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	msgOOB.nRemoveOnMiss = bRemoveOnMiss and 1 or 0;

	if not Session.IsHost and ActorManager.isPC(rTarget) and ActorManager.isOwner(rTarget) then
		ActionPower.handleApplySaveVs(msgOOB);
		return;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function getPowerCastRoll(_, rAction)
	local rRoll = {};
	rRoll.sType = "cast";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	rRoll.sDesc = ActionCore.encodeActionText(rAction, "action_cast_tag");

	return rRoll;
end

function onPowerCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "action_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end

	Comm.deliverChatMessage(rMessage);
end

--
--	POWER SAVE HANDLING (SAVE VS.)
--

function getSaveVsRoll(rActor, rAction)
	local rRoll = {
		sType = "powersave",
		sDesc = ActionCore.encodeActionText(rAction, "action_savevs_tag"),
		sSave = rAction.save,
		aDice = {},
		nMod = rAction.savemod or 0,
		bEffects = false,
		nEffectMod = 0,
		tNotifications = {},
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
function performSaveVsRoll(draginfo, rActor, rAction)
	local rRoll = ActionPower.getSaveVsRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modCastSave(_, _, rRoll)
	if (rRoll.sSave or "") == "dexterity" then
		if ModifierManager.getKey("DEF_SCOVER") then
			rRoll.sDesc = rRoll.sDesc .. " [COVER +5]";
		elseif ModifierManager.getKey("DEF_COVER") then
			rRoll.sDesc = rRoll.sDesc .. " [COVER +2]";
		end
	end
	return true;
end

function onPowerSave(rSource, rTarget, rRoll)
	if ActionPower.onCastSave(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
function onCastSave(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort,_ = rRoll.sDesc:match("%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.ability_stol[sSaveShort];
			if sSave then
				ActionPower.notifyApplySaveVs(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.bRemoveOnMiss);
				return true;
			end
		end
	end
	return false;
end
