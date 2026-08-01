--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("recovery", ActionRecovery.modRecovery);
	ActionsManager.registerResultHandler("recovery", ActionRecovery.onRecovery);
end

function performRoll(draginfo, rActor, nodeClass)
	local rRoll = {
		sType = "recovery",
		sDesc = "[RECOVERY]",
		aDice = {},
		nMod = 0,
		sClassNode = DB.getPath(nodeClass),
	};

	local aHDDice = DB.getValue(nodeClass, "hddie", {});
	if #aHDDice > 0 then
		table.insert(rRoll.aDice, aHDDice[1]);
	end

	local sAbility = "";
	local sAbility2 = "";
	if ActorManager.isPC(rActor) then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			sAbility = DB.getValue(nodeActor, "hp.hdstat", "");
			sAbility2 = DB.getValue(nodeActor, "hp.hdstat2", "");
			rRoll.nMod = DB.getValue(nodeActor, "hp.hdmod", 0);
		end
	end
	if sAbility == "" then
		sAbility = "constitution";
	end
	if sAbility ~= "constitution" then
		local sAbilityEffect = DataCommon.ability_ltos[sAbility];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end
	rRoll.nMod = rRoll.nMod + ActorManager5E.getAbilityBonus(rActor, sAbility);
	
	if sAbility2 ~= "" then
		local sAbilityEffect2 = DataCommon.ability_ltos[sAbility2];
		if sAbilityEffect2 then
			rRoll.sDesc = rRoll.sDesc .. " [MOD2:" .. sAbilityEffect2 .. "]";
			rRoll.nMod = rRoll.nMod + ActorManager5E.getAbilityBonus(rActor, sAbility2);
		end
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRecovery(rSource, rTarget, rRoll)
	ActionRecovery.applyModAbilityEffect(rSource, rTarget, rRoll);

	ActionHealD20.applyModHealEffects(rSource, rTarget, rRoll);

	ActionCore.applyModMaxEffects(rSource, rTarget, rRoll);
	ActionCore.applyModHalfEffects(rSource, rTarget, rRoll);
	ActionCore.applyModTabletopButtons(rSource, rTarget, rRoll);
end
function applyModAbilityEffect(rSource, rTarget, rRoll)
	if not rSource then
		return;
	end

	local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
	local sModStat2 = rRoll.sDesc:match("%[MOD2:(%w+)%]");

	local sActionStat = sModStat and DataCommon.ability_stol[sModStat] or "constitution";
	local sActionStat2 = sModStat2 and DataCommon.ability_stol[sModStat2];

	-- Determine ability modifiers
	local nBonusStat, nBonusEffects = ActorManagerD20.getAbilityEffectsBonus(rSource, sActionStat);
	if nBonusEffects > 0 then
		rRoll.bEffects = true;
		rRoll.nEffectMod = rRoll.nEffectMod + nBonusStat;
	end
	if sActionStat2 then
		local nBonusStat2, nBonusEffects2 = ActorManagerD20.getAbilityEffectsBonus(rSource, sActionStat2);
		if nBonusEffects2 > 0 then
			rRoll.bEffects = true;
			rRoll.nEffectMod = rRoll.nEffectMod + nBonusStat;
		end
	end
end

function onRecovery(rSource, _, rRoll)
	ActionCore.applyRollGeneralModifiers(rSource, rRoll);
	rRoll.nTotal = ActionsManager.total(rRoll);

	-- Get basic roll message and total
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Handle minimum damage
	if rRoll.nTotal < 0 and #(rRoll.aDice or {}) > 0 then
		rMessage.text = rMessage.text .. " [MIN RECOVERY]";
		rMessage.diemodifier = rMessage.diemodifier - rRoll.nTotal;
		rRoll.nTotal = 0;
	end
	if ActorManager5E.hasRollFeat2014(rSource, CharManager.FEAT_DURABLE) then
		local nDurableMin = math.max(ActorManager5E.getAbilityBonus(rSource, "constitution"), 1) * 2;
		if rRoll.nTotal < nDurableMin then
			rMessage.text = string.format("%s [DURABLE %+d]", rMessage.text, nDurableMin - rRoll.nTotal);
			rMessage.diemodifier = rMessage.diemodifier + (nDurableMin - rRoll.nTotal);
			rRoll.nMod = rRoll.nMod + (nDurableMin - rRoll.nTotal);
			rRoll.nTotal = nDurableMin; 
		else
			rMessage.text = rMessage.text .. " [DURABLE]";
		end
	end

	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);

	-- Apply recovery
	if rRoll.sClassNode then
		rMessage.text = rMessage.text .. " [NODE:" .. rRoll.sClassNode .. "]";
	end
	rRoll.sDesc = rMessage.text;
	ActionDamageD20.notifyApplyDamage(rSource, rSource, rRoll);
end
