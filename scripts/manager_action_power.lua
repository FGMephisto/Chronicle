--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVEVS = "applysavevs";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionPower.OOB_MSGTYPE_APPLYSAVEVS, ActionPower.handleApplySaveVs);

	ActionsManager.registerTargetingHandler("cast", ActionPower.onPowerTargeting);
	ActionsManager.registerTargetingHandler("powersave", ActionPower.onPowerTargeting);

	ActionsManager.registerModHandler("powersave", ActionPower.modCastSave);

	ActionsManager.registerResultHandler("cast", ActionPower.onPowerCast);
	ActionsManager.registerResultHandler("powersave", ActionPower.onPowerSave);
end

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

	if ActorManager.isPC(rTarget) then
		local nodeTarget = ActorManager.getCreatureNode(rTarget);
		if Session.IsHost then
			local sOwner = DB.getOwner(nodeTarget);
			if (sOwner or "") ~= "" then
				for _,vUser in ipairs(User.getActiveUsers()) do
					if vUser == sOwner then
						for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
							if DB.getName(nodeTarget) == vIdentity then
								Comm.deliverOOBMessage(msgOOB, sOwner);
								return;
							end
						end
					end
				end
			end
		else
			if DB.isOwner(nodeTarget) then
				ActionPower.handleApplySaveVs(msgOOB);
				return;
			end
		end
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function onPowerTargeting(_, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		local aTargets = {};
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aTargets, vTarget);
			end
		end
		bRemoveOnMiss = (#aTargets > 1);
	end

	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = true;
		end
	end

	return aTargeting;
end

function getPowerCastRoll(_, rAction)
	local rRoll = {};
	rRoll.sType = "cast";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	rRoll.sDesc = ActionCore.encodeActionText(rAction, "action_cast_tag");

	return rRoll;
end

function getSaveVsRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "powersave";
	rRoll.aDice = {};
	rRoll.nMod = rAction.savemod or 0;

	rRoll.sDesc = ActionCore.encodeActionText(rAction, "action_savevs_tag");

	rRoll.sSave = rAction.save;

	local tAddDesc = {};
	local bEffects = false;
	local nAddMod = 0;

	if DataCommon.ability_ltos[rAction.save] then
		local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rActor, rAction.savestat);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end

		local sDC = string.format("[%s DC %d]", DataCommon.ability_ltos[rAction.save], rRoll.nMod + nAddMod);
		table.insert(tAddDesc, sDC);
	end
	if rAction.magic then
		table.insert(tAddDesc, "[MAGIC]");
	end
	if rAction.onmissdamage == "half" then
		table.insert(tAddDesc, "[HALF ON SAVE]");
	end

	if bEffects then
		local sMod = StringManager.convertDiceToString(nil, nAddMod, true);
		table.insert(tAddDesc, EffectManager.buildEffectOutput(sMod));
	end

	if #tAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(tAddDesc, " ");
	end

	rRoll.nMod = rRoll.nMod + nAddMod;

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
end

function onPowerCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "roll_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end

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

function onPowerSave(rSource, rTarget, rRoll)
	if ActionPower.onCastSave(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
