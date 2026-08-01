--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("check", ActionCheck.modRoll);
	ActionsManager.registerResultHandler("check", ActionCheck.onRoll);
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
	return true;
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
	table.insert(rRoll.tNotifications, ActionCore.encodeActionText({ label = sCheck, }, "action_check_tag"));

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
		rRoll.sAbility = ActionCore.decodeLabelText(rRoll.sDesc, "action_check_tag"):lower();
	elseif rRoll.sType == "init" then
		rRoll.sAbility = "dexterity";
	elseif rRoll.sType == "skill" then
		rRoll.sSkill = StringManager.simplify(ActionCore.decodeLabelText(rRoll.sDesc, "action_skill_tag"));
		if rRoll.sSkill ~= "" then
			local sAbility = rRoll.sDesc:match("%[MOD:(%w*)%]");
			if sAbility then
				rRoll.sAbility = DataCommon.ability_stol[sAbility] or "";
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
	ActionsManager2.applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget);
	ActionCheck.applyReliableEffectsToRollMod(rRoll, rSource, rTarget);
end
function applyStandardEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	-- Handle encumbrance penalty
	if StringManager.contains({ "strength", "dexterity", "constitution" }, rRoll.sAbility) then
		if CharEncumbranceManager5E.isHeavilyEncumbered(rSource) then
			rRoll.bDIS = true;
			table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("encumbrance_encumbered_heavy"):upper()));
		end
	end

	local tSrcEffData = { tFilter = rRoll.tCheckFilter, };

	-- Get roll effect modifiers
	ActionCore.applyModRollEffectBonusDiceMod(rSource, rRoll, "CHECK", tSrcEffData);

	-- Get condition modifiers
	if EffectManager.hasTextOrTag(rSource, "ADVCHK", tSrcEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end
	if EffectManager.hasTextOrTag(rSource, "DISCHK", tSrcEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasCondition(rSource, "Frightened") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasCondition(rSource, "Intoxicated") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasCondition(rSource, "Poisoned") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	end

	if rRoll.sType == "init" then
		ActionCore.applyModRollEffectBonusDiceMod(rSource, rRoll, "INIT");

		if EffectManager.hasText(rSource, "ADVINIT") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		elseif OptionsManager.isOption("GAVE", "2024") and EffectManager.hasCondition(rSource, "Invisible") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager.hasText(rSource, "DISINIT") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		elseif OptionsManager.isOption("GAVE", "2024") then
			if EffectManager.hasCondition(rSource, "Incapacitated") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			elseif EffectManager.hasCondition(rSource, "Paralyzed") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			elseif EffectManager.hasCondition(rSource, "Petrified") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			elseif EffectManager.hasCondition(rSource, "Stunned") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			elseif EffectManager.hasCondition(rSource, "Unconscious") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			elseif EffectManager.hasCondition(rSource, "Surprised") then
				rRoll.bEffects = true;
				rRoll.bDIS = true;
			end
		end
	elseif rRoll.sType == "skill" then
		local tSrcSkillEffData = { tFilter = rRoll.tSkillFilter, };

		ActionCore.applyModRollEffectBonusDiceMod(rSource, rRoll, "SKILL", tSrcSkillEffData);

		if EffectManager.hasTextOrTag(rSource, "ADVSKILL", tSrcSkillEffData) then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager.hasTextOrTag(rSource, "DISSKILL", tSrcSkillEffData) then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end
end
function applyReliableEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	if EffectManager.hasText(rSource, "RELIABLE") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif EffectManager.hasTextOrTag(rSource, "RELIABLECHK", { tFilter = rRoll.tCheckFilter, }) then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end

	if rRoll.sType == "init" then
		if EffectManager.hasText(rSource, "RELIABLEINIT") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		end
	elseif rRoll.sType == "skill" then
		if EffectManager.hasTextOrTag(rSource, "RELIABLESKILL", { tFilter = rRoll.tSkillFilter, }) then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		elseif rRoll.sDesc:match("%[PROF%]") or rRoll.sDesc:match("%[PROF x2%]") then
			if ActorManager5E.hasRollFeature(rSource, CharManager.FEATURE_RELIABLE_TALENT) then
				rRoll.bReliable = true;
			else
				local tSilverTongueSkills = {
					StringManager.simplify(Interface.getString("skill_value_deception")),
					StringManager.simplify(Interface.getString("skill_value_persuasion")),
				};
				if StringManager.contains(tSilverTongueSkills, rRoll.sSkill) and ActorManager5E.hasRollFeature(rSource, CharManager.FEATURE_SILVER_TONGUE) then
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
