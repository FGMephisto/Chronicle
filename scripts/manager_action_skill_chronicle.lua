-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	GameManager.setFunction("onActionSkillRoll", ActionSkill.performRoll);
	ActionsManager.registerModHandler("skill", ActionSkill.modRoll);
	ActionsManager.registerResultHandler("skill", ActionSkill.onRoll);
end

function getRoll(rActor, vSkill, nTargetDC, bSecretRoll)
	if type(vSkill) == "string" then
		return ActionSkill.getUnlistedRoll(rActor, vSkill, nTargetDC, bSecretRoll);
	end

	local nodeSkill = vSkill;
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.sStat = DB.getValue(nodeSkill, "stat", "");
	rRoll.sAbility = Interface.getString(rRoll.sStat);
	rRoll.sSkill = DB.getValue(nodeSkill, "name", "");
	rRoll.sType = "skill";
	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat);
	rRoll.nBonus = ActorManager5E.getSkillRank(rActor, rRoll.sSkill);
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;
	rRoll.nTarget = tonumber(nTargetDC) or 0;
	rRoll.bSecret = bSecretRoll or false;

	local nDiceTotal = (tonumber(rRoll.nTest) or 0) + (tonumber(rRoll.nBonus) or 0);
	for i = 1, nDiceTotal do
		table.insert(rRoll.aDice, {type = "d6"});
	end

	rRoll.sDesc = rRoll.sAbility .. " (" .. rRoll.sSkill .. ")";

	return rRoll;
end

function performRoll(draginfo, rActor, vSkill, nTargetDC, bSecretRoll)
	local rRoll = ActionSkill.getRoll(rActor, vSkill, nTargetDC, bSecretRoll);

	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performPartySheetRoll(draginfo, rActor, sSkill)
	if not ActorManager.isPC(rActor) then
		return;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	local rRoll = nil;
	for _,v in ipairs(DB.getChildList(nodeActor, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			rRoll = ActionSkill.getRoll(rActor, v);
			break;
		end
	end

	if not rRoll then
		rRoll = ActionSkill.getUnlistedRoll(rActor, sSkill);
	end

	if not rRoll then
		return;
	end

	local nTargetDC = DB.getValue("partysheet.skilldc", 0);
	rRoll.nTarget = nTargetDC;

	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	rRoll.nTest = tonumber(rRoll.nTest) or 0;
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;
	rRoll.nAP = tonumber(rRoll.nAP) or 0;
	rRoll.nMod = tonumber(rRoll.nMod) or 0;

	-- Consider Effects
	if rSource then
		local bEffects = false;

		local aCheckFilter = {};
		if (rRoll.sStat or "") ~= "" then
			table.insert(aCheckFilter, rRoll.sStat);
		end

		local aSkillFilter = {};
		if (rRoll.sSkill or "") ~= "" then
			table.insert(aSkillFilter, rRoll.sSkill:lower());
		end

		local aCheckDice, nCheckMod, nCheckCount = EffectManager5E.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter);
		if nCheckCount > 0 then
			bEffects = true;
			for _,v in ipairs(aCheckDice) do
				table.insert(aAddDice, v);
			end
			nAddMod = nAddMod + nCheckMod;
		end

		local aSkillAddDice, nSkillAddMod, nSkillEffectCount = EffectManager5E.getEffectsBonus(rSource, {"SKILL"}, false, aSkillFilter);
		if nSkillEffectCount > 0 then
			bEffects = true;
			for _,v in ipairs(aSkillAddDice) do
				table.insert(aAddDice, v);
			end
			nAddMod = nAddMod + nSkillAddMod;
		end

		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bEffects = true;
		end

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

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll);

	-- Consider Armor Penalty
	ActionsManager2.encodeArmorMods(rRoll);

	-- Consider Health
	ActionsManager2.encodeHealthMods(rSource, rRoll);

	-- Apply collected nAddMod to rRoll.nMod
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rRoll = ActionResult.DropDice(rRoll);
	rMessage, rRoll = ActionResult.DetermineSuccessTest(rMessage, rRoll);

	Comm.deliverChatMessage(rMessage);
end

--
-- CHRONICLE CUSTOM SYSTEMS
--

function getNPCRoll(rActor, sSkill, nSkill)
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bSecret = true;
	rRoll.sStat = "";
	rRoll.sAbility = "";
	rRoll.sSkill = StringManager.capitalize(sSkill or "");
	rRoll.sType = "skill";
	rRoll.nTest = 0;
	rRoll.nBonus = tonumber(nSkill) or 0;
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;
	rRoll.nTarget = 0;

	if DataCommon.skilldata[rRoll.sSkill] ~= nil then
		rRoll.sStat = DataCommon.skilldata[rRoll.sSkill].stat;
		rRoll.sAbility = Interface.getString(rRoll.sStat);
	end

	rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat);

	local nDiceTotal = (tonumber(rRoll.nTest) or 0) + (tonumber(rRoll.nBonus) or 0);
	for i = 1, nDiceTotal do
		table.insert(rRoll.aDice, {type = "d6"});
	end

	rRoll.sDesc = rRoll.sAbility .. " (" .. rRoll.sSkill .. ")";

	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	return rRoll;
end

function performNPCRoll(draginfo, rActor, sSkill, nSkill)
	local rRoll = ActionSkill.getNPCRoll(rActor, sSkill, nSkill);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getUnlistedRoll(rActor, sSkill, nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = {};
	rRoll.sStat = "";
	rRoll.sAbility = "";
	rRoll.sSkill = StringManager.capitalize(sSkill or "");
	rRoll.nTest = 0;
	rRoll.nBonus = 0;
	rRoll.nPenalty = 0;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = 0;
	rRoll.nTarget = tonumber(nTargetDC) or 0;
	rRoll.bSecret = bSecretRoll or false;

	if DataCommon.skilldata[rRoll.sSkill] then
		rRoll.sStat = DataCommon.skilldata[rRoll.sSkill].stat;
		rRoll.sAbility = Interface.getString(rRoll.sStat);
	elseif DataCommon.skilldata[sSkill] then
		rRoll.sStat = DataCommon.skilldata[sSkill].stat;
		rRoll.sAbility = Interface.getString(rRoll.sStat);
	end

	if (rRoll.sStat or "") ~= "" then
		rRoll.nTest = ActorManager5E.getAbilityScore(rActor, rRoll.sStat);
	end
	rRoll.nBonus = ActorManager5E.getSkillRank(rActor, rRoll.sSkill);
	if rRoll.nBonus < 0 then
		rRoll.nBonus = 0;
	end

	local nDiceTotal = (tonumber(rRoll.nTest) or 0) + (tonumber(rRoll.nBonus) or 0);
	for i = 1, nDiceTotal do
		table.insert(rRoll.aDice, {type = "d6"});
	end

	rRoll.sDesc = rRoll.sAbility .. " (" .. rRoll.sSkill .. ")";

	return rRoll;
end