-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("check", modRoll);
	ActionsManager.registerResultHandler("check", onRoll);
end

function getRoll(rActor, sCheck, nTargetDC, bSecret)
	local rRoll = ActionsManager2.setupD20RollBuild("check", rActor, bSecret);
	ActionCheck.setupRollBuild(rRoll, rActor, sCheck, nTargetDC);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = ActionCheck.getRoll(rActor, sCheck, nTargetDC, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetRoll(draginfo, rActor, sCheck)
	local rRoll = ActionCheck.getRoll(rActor, sCheck);
	
	rRoll.nTarget = DB.getValue("partysheet.checkdc", 0);
	if rRoll.nTarget == 0 then
		rRoll.nTarget = nil;
	end
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	ActionsManager2.setupD20RollMod(rRoll);
	ActionCheck.setupRollMod(rRoll);
	ActionCheck.applyEffectsToRollMod(rRoll, rSource, rTarget);
	ActionsManager2.finalizeEffectsToD20RollMod(rRoll);
	ActionCheck.finalizeRollMod(rRoll);
	ActionsManager2.finalizeD20RollMod(rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " [vs. DC " .. nTargetDC .. "]";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	Comm.deliverChatMessage(rMessage);

	if rRoll.sType == "init" then
		ActionInit.notifyApplyInit(rSource, ActionsManager.total(rRoll));
	end
end

--
--	MOD ROLL HELPERS
--

function setupRollBuild(rRoll, rActor, sCheck, nTargetDC)
	table.insert(rRoll.tNotifications, "[CHECK]");
	table.insert(rRoll.tNotifications, StringManager.capitalizeAll(sCheck));

	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getCheck(rActor, sCheck:lower());
	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end
	rRoll.nTarget = nTargetDC;
	
	return rRoll;
end

function setupRollMod(rRoll)
	ActionCheck.getAbilityRollMod(rRoll);

	rRoll.tCheckFilter = {};
	rRoll.tSkillFilter = {};
	if rRoll.sAbility then
		table.insert(rRoll.tCheckFilter, rRoll.sAbility);
		table.insert(rRoll.tSkillFilter, rRoll.sAbility);
	end
	if rRoll.sSkill then
		table.insert(rRoll.tSkillFilter, rRoll.sSkill);
	end
end
function getAbilityRollMod(rRoll)
	if rRoll.sType == "check" then
		rRoll.sAbility = rRoll.sDesc:match("%[CHECK%] (%w+)");
		if rRoll.sAbility then
			rRoll.sAbility = rRoll.sAbility:lower();
		end
	elseif rRoll.sType == "init" then
		rRoll.sAbility = "dexterity";
	elseif rRoll.sType == "skill" then
		rRoll.sSkill = StringManager.simplify(rRoll.sDesc:match("%[SKILL%] ([^%[]+)"));
		if rRoll.sSkill then
			local sAbility = StringManager.simplify(rRoll.sDesc:match("%[MOD:(%w+)%]"));
			if sAbility and DataCommon.ability_stol[sAbility] then
				rRoll.sAbility = DataCommon.ability_stol[sAbility];
			else
				for k, v in pairs(DataCommon.skilldata) do
					if StringManager.simplify(k) == rRoll.sSkill then
						rRoll.sAbility = v.stat;
					end
				end
			end
		end
	end
end
function applyEffectsToRollMod(rRoll, rSource, rTarget)
	ActionsManager2.applyAbilityEffectsToD20RollMod(rRoll, rSource, rTarget);
	ActionCheck.applyStandardEffectsToRollMod(rRoll, rSource, rTarget);
	ActionCheck.applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget);
	ActionCheck.applyReliableEffectsToRollMod(rRoll, rSource, rTarget);
end
function applyStandardEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	-- Get roll effect modifiers
	local tCheckDice, nCheckMod, nCheckEffect = EffectManager5E.getEffectsBonus(rSource, { "CHECK" }, false, rRoll.tCheckFilter);
	if (nCheckEffect > 0) then
		rRoll.bEffects = true;
		for _,vDie in ipairs(tCheckDice) do
			table.insert(rRoll.tEffectDice, vDie);
		end
		rRoll.nEffectMod = rRoll.nEffectMod + nCheckMod;
	end
	
	-- Get condition modifiers
	if EffectManager5E.hasEffectCondition(rSource, "ADVCHK") then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "ADVCHK", rRoll.tCheckFilter)) > 0 then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end
	if EffectManager5E.hasEffectCondition(rSource, "DISCHK") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "DISCHK", rRoll.tCheckFilter)) > 0 then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Frightened") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif StringManager.contains({ "strength", "dexterity", "constitution" }, rRoll.sAbility) then
		if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end

	if rRoll.sType == "init" then
		local tInitDice, nInitMod, nInitEffect = EffectManager5E.getEffectsBonus(rSource, {"INIT"}, false);
		if (nInitEffect > 0) then
			rRoll.bEffects = true;
			for _,vDie in ipairs(tInitDice) do
				table.insert(rRoll.tEffectDice, vDie);
			end
			rRoll.nEffectMod = rRoll.nEffectMod + nInitMod;
		end

		if EffectManager5E.hasEffectCondition(rSource, "ADVINIT") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		elseif OptionsManager.isOption("GAVE", "2024") and EffectManager5E.hasEffectCondition(rSource, "Invisible") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISINIT") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		elseif OptionsManager.isOption("GAVE", "2024") and EffectManager5E.hasEffectCondition(rSource, "Incapacitated") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	elseif rRoll.sType == "skill" then
		local tSkillDice, nSkillMod, nSkillEffect = EffectManager5E.getEffectsBonus(rSource, {"SKILL"}, false, rRoll.tSkillFilter);
		if (nSkillEffect > 0) then
			rRoll.bEffects = true;
			for _,vDie in ipairs(tSkillDice) do
				table.insert(rRoll.tEffectDice, vDie);
			end
			rRoll.nEffectMod = rRoll.nEffectMod + nSkillMod;
		end

		if EffectManager5E.hasEffectCondition(rSource, "ADVSKILL") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVSKILL", rRoll.tSkillFilter)) > 0 then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISSKILL") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISSKILL", rRoll.tSkillFilter)) > 0 then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end
end
function applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, { "EXHAUSTION" }, true);
	if OptionsManager.isOption("GAVE", "2024") then
		if nExhaustMod > 0 then
			rRoll.bEffects = true;
			rRoll.nEffectMod = rRoll.nEffectMod - (2 * nExhaustMod);
		end
	else
		if nExhaustMod > 0 then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end		
	end
end
function applyReliableEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLECHK") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLECHK", rRoll.tCheckFilter)) > 0 then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end

	if rRoll.sType == "init" then
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLEINIT") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		end
	elseif rRoll.sType == "skill" then
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLESKILL") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLESKILL", rRoll.tSkillFilter)) > 0 then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		elseif ActorManager.isPC(rSource) and rRoll.sDesc:match("%[PROF%]") or rRoll.sDesc:match("%[PROF x2%]") then
			local nodeActor = ActorManager.getCreatureNode(rSource);
			if CharManager.hasFeature(nodeActor, CharManager.FEATURE_RELIABLE_TALENT) then
				rRoll.bReliable = true;
			else
				local tSilverTongueSkills = {
					StringManager.simplify(Interface.getString("skill_value_deception")),
					StringManager.simplify(Interface.getString("skill_value_persuasion")),
				};
				if StringManager.contains(tSilverTongueSkills, rRoll.sSkill) and CharManager.hasFeature(nodeActor, CharManager.FEATURE_SILVER_TONGUE) then
					rRoll.bReliable = true;
				end
			end
		end
	end
end
function finalizeRollMod(rRoll)
	rRoll.tCheckFilter = nil;
	rRoll.tSkillFilter = nil;
end
