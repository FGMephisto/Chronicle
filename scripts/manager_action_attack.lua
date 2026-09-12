--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionAttack.OOB_MSGTYPE_APPLYATK, ActionAttack.handleApplyAttack);
	OOBManager.registerOOBMsgHandler(ActionAttack.OOB_MSGTYPE_APPLYHRFC, ActionAttack.handleApplyHRFC);

	ActionsManager.registerTargetingHandler("attack", ActionCore.onTargeting);
	ActionsManager.registerModHandler("attack", ActionAttack.modAttack);
	ActionsManager.registerResultHandler("attack", ActionAttack.onAttack);
end

function notifyApplyAttack(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	rRoll.sResults = table.concat(rRoll.aMessages, "\r");

	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYATK;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionAttack.applyAttack(rSource, rTarget, rRoll);
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end
function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYHRFC;

	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetVsRoll(_, rActor, rAction)
	local rRoll = ActionAttack.getRoll(nil, rAction);

	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.actionDirect(nil, "attack", { rRoll }, { { rActor } });
end
function getRoll(rActor, rAction)
	local rRoll = ActionsManager2.setupD20RollBuild("attack", rActor);
	ActionAttack.setupRollBuild(rRoll, rActor, rAction);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end

function modAttack(rSource, rTarget, rRoll)
	ActionAttackCore.clearCritState(rSource);

	ActionsManager2.setupD20RollMod(rRoll);
	ActionAttack.setupRollMod(rRoll);
	ActionAttack.applyEffectsToRollMod(rRoll, rSource, rTarget);
	ActionsManager2.finalizeEffectsToD20RollMod(rRoll);
	ActionAttack.finalizeRollMod(rRoll);
	ActionsManager2.finalizeD20RollMod(rRoll);
	ActionsManager2.handleElvenAccuracyFeatMod(rRoll, rSource);
end

function onAttack(rSource, rTarget, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);
	ActionsManager2.handleElvenAccuracyFeatResolve(rRoll);

	ActionAttack.setupAttackResolve(rRoll, rSource, rTarget);

	GameManager.callEventFunctions("onAttackPreResolve", rSource, rTarget, rRoll);
	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");
	if not rTarget and (#(rRoll.aMessages) > 0) then
		rMessage.text = rMessage.text .. "\r" .. table.concat(rRoll.aMessages, "\r");
	end
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);

	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll);
	GameManager.callEventFunctions("onAttackPostResolve", rSource, rTarget, rRoll);
end
-- onPreAttackResolve(rSource, rTarget, rRoll)
function onPreAttackResolve()
	-- Do nothing; location to override
end
function onAttackResolve(rSource, rTarget, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);

	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll);
	end

	-- TRACK CRITICAL STATE
	if rRoll.sResult == "crit" then
		ActionAttackCore.setCritState(rSource, rTarget);
	end

	-- REMOVE TARGET ON MISS OPTION
	if rTarget then
		if StringManager.contains({ "crit", "hit", }, rRoll.sResult) then
			ActionsPerformManager.setActionResultState(rSource, rTarget, { sAuto = "hit", sDamageLabel = rRoll.sLabel, sDamageResult = "", });
		else
			if (rRoll.sDesc:match("%[HALF ON MISS%]") ~= nil) then
				ActionsPerformManager.setActionResultState(rSource, rTarget, { sAuto = "miss", sDamageLabel = rRoll.sLabel, sDamageResult = "half_miss", });
			else
				ActionsPerformManager.setActionResultState(rSource, rTarget, { sAuto = "miss", sDamageLabel = rRoll.sLabel, sDamageResult = "", });
				if rRoll.bRemoveOnMiss then
					TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
				end
			end
		end
	end
end
-- onPostAttackResolve(rSource, rTarget, rRoll)
function onPostAttackResolve(_, _, rRoll)
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rRoll.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		ActionAttack.notifyApplyHRFC("Fumble");
	end
	if rRoll.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		ActionAttack.notifyApplyHRFC("Critical Hit");
	end
end

function setupAttackResolve(rRoll, rSource, rTarget)
	ActionAttack.decodeAttackRoll(rRoll);
	ActionAttack.checkAttackDefense(rRoll, rSource, rTarget);
	ActionAttack.checkAttackResult(rRoll, rSource, rTarget);
end
function decodeAttackRoll(rRoll)
	ActionAttackCore.decodeRollData(rRoll);
	rRoll.aMessages = {};
end
function checkAttackDefense(rRoll, rSource, rTarget)
	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);
	if rRoll.nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end
	if rRoll.nDefEffectsBonus ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildDefEffectOutput(rRoll.nDefEffectsBonus));
	end
end
function checkAttackResult(rRoll, rSource, rTarget)
	local sCritThreshold = rRoll.sDesc:match("%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end

	if not rRoll.bOutOfRange then
		rRoll.nFirstDie = (rRoll.aDice[1] and rRoll.aDice[1].result) or 0;
		if rRoll.nFirstDie >= nCritThreshold then
			rRoll.sResult = "crit";
		elseif rRoll.nFirstDie == 1 then
			rRoll.sResult = "fumble";
		elseif rRoll.nDefenseVal then
			if rRoll.nTotal >= rRoll.nDefenseVal then
				rRoll.sResult = "hit";
			else
				rRoll.sResult = "miss";
			end
		end
	end

	if rRoll.sResult == "hit" then
		if EffectManager.hasCondition(rTarget, "Paralyzed") or EffectManager.hasCondition(rTarget, "Unconscious") then
			if ActorManager.isInRange(rSource, rTarget, 5) then
				table.insert(rRoll.aMessages, "[CONVERTED TO CRIT]");
				rRoll.sResult = "crit";
			end
		end
	end

	if rRoll.sResult == "crit" then
		table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	elseif rRoll.sResult == "fumble" then
		table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	elseif rRoll.sResult == "hit" then
		table.insert(rRoll.aMessages, "[HIT]");
	elseif rRoll.sResult == "miss" then
		table.insert(rRoll.aMessages, "[MISS]");
	end
end

function applyAttack(rSource, rTarget, rRoll)
	local tApplyData = { sResultText = "Attack", sResultIcon = "action_attack", tNotifications = {}, };

	if (rRoll.sResults or "") ~= "" then
		table.insert(tApplyData.tNotifications, rRoll.sResults);
	end

	if rRoll.bOutOfRange then
		tApplyData.sResultIconLong = "action_error";
		table.insert(tApplyData.tNotifications, "[OUT OF RANGE]");
	elseif rRoll.sResult == "crit" then
		tApplyData.sResultIconLong = "action_attack_crit";
	elseif rRoll.sResult == "fumble" then
		tApplyData.sResultIconLong = "action_attack_miss";
	elseif rRoll.sResult == "hit" then
		tApplyData.sResultIconLong = "action_attack_hit";
	elseif rRoll.sResult == "miss" then
		tApplyData.sResultIconLong = "action_attack_miss";
	end

	ActionCore.applyMessage(rSource, rTarget, rRoll, tApplyData);
end

--
--	MOD ROLL HELPERS
--

function setupRollBuild(rRoll, rActor, rAction)
	rRoll.sLabel = StringManager.capitalizeAll(rAction.label);
	rRoll.nOrder = rAction.order;
	rRoll.nMod = rAction.modifier or 0;
	rRoll.sRange = rAction.range;
	rRoll.bWeapon = rAction.bWeapon;
	rRoll.bSpell = rAction.bSpell;
	rRoll.bADV = rAction.bADV or false;
	rRoll.bDIS = rAction.bDIS or false;
	rRoll.tActionTags = rAction.tActionTags;
	rRoll.nRange = rAction.nRange;
	rRoll.nRangeLong = rAction.nRangeLong;

	-- Build the description label
	table.insert(rRoll.tNotifications, ActionAttackCore.encodeActionText(rAction));

	-- Add crit range
	if ((rAction.nCritRange or 20) > 18) and ActorManager5E.hasRollFeature(rActor, CharManager.FEATURE_SUPERIOR_CRITICAL) then
		rAction.nCritRange = 18;
		table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_superior_critical")));
	elseif ((rAction.nCritRange or 20) > 19) and ActorManager5E.hasRollFeature(rActor, CharManager.FEATURE_IMPROVED_CRITICAL) then
		rAction.nCritRange = 19;
		table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_improved_critical")));
	end
	if rAction.nCritRange then
		table.insert(rRoll.tNotifications, string.format("[CRIT %d]", rAction.nCritRange));
	end

	-- Add ability modifiers
	if rAction.stat then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		if sAbilityEffect then
			table.insert(rRoll.tNotifications, string.format("[MOD:%s]", sAbilityEffect));
		end

		-- Check for armor non-proficiency
		if ActorManager.isPC(rActor) then
			if StringManager.contains({"strength", "dexterity"}, rAction.stat) then
				local nodeActor = ActorManager.getCreatureNode(rActor);
				if nodeActor and (DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0) then
					rRoll.bDIS = true;
					table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_armor_nonprof")));
				end
			end
		end
	end

	if ((rAction.save or "") == "") and ((rAction.onmissdamage or "") == "half") then
		table.insert(rRoll.tNotifications, "[HALF ON MISS]");
	end
end

function setupRollMod(rRoll)
	ActionAttackCore.decodeRollData(rRoll);

	rRoll.sAbility = rRoll.sDesc:match("%[MOD:(%w*)%]");
	if rRoll.sAbility then
		rRoll.sAbility = DataCommon.ability_stol[rRoll.sAbility] or "";
	end

	-- Check for opportunity attack
	rRoll.bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();
	if rRoll.bOpportunity then
		table.insert(rRoll.tNotifications, "[OPPORTUNITY]");
	end

	-- Check cover
	rRoll.bCover = ModifierManager.getKey("DEF_COVER");
	rRoll.bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");

	-- Build attack filter
	rRoll.tAttackFilter = ActionCore.buildEffectFilter(rRoll);
end
function applyEffectsToRollMod(rRoll, rSource, rTarget)
	ActionsManager2.applyAbilityEffectsToD20RollMod(rRoll, rSource, rTarget);
	ActionAttack.applyStandardEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyRangeToRollMod(rRoll, rSource, rTarget);
	ActionsManager2.applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyReliableEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyDefenderEffectsToRollMod(rRoll, rSource, rTarget);
end
function applyStandardEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	-- Handle encumbrance penalty
	if CharEncumbranceManager5E.isHeavilyEncumbered(rSource) then
		rRoll.bDIS = true;
		rRoll.sDesc = StringManager.append(rRoll.sDesc, string.format("[%s]", Interface.getString("encumbrance_encumbered_heavy"):upper()), "\r");
	end

	local tSrcEffData = { rTarget = rTarget, tFilter = rRoll.tAttackFilter, tActionTags = rRoll.tActionTags, };
	local tTrgtEffData = { rTarget = rSource, tFilter = rRoll.tAttackFilter, tActionTags = rRoll.tActionTags, };
	local bInvisible = EffectManager.hasCondition(rSource, "Invisible") and not EffectManager.hasCondition(rSource, "NOINVISIBLE");

	-- Get roll effect modifiers
	ActionCore.applyModRollEffectBonusDiceMod(rSource, rRoll, "ATK", tSrcEffData);
	ActionCore.applyModRollEffectBonusDiceMod(rTarget, rRoll, "@ATK", tTrgtEffData);

	-- Get condition modifiers
	if EffectManager.hasTextOrTag(rSource, "ADVATK", tSrcEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif EffectManager.hasTextOrTag(rTarget, "@ADVATK", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif EffectManager.hasTextOrTag(rTarget, "GRANTADVATK", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif bInvisible then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end

	if EffectManager.hasTextOrTag(rSource, "DISATK", tSrcEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasTextOrTag(rTarget, "@DISATK", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasTextOrTag(rTarget, "GRANTDISATK", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasCondition(rSource, "Blinded") then
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
	elseif EffectManager.hasCondition(rSource, "Prone") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasCondition(rSource, "Restrained") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	end

	local bFrozen = EffectManager.hasCondition(rSource, "Paralyzed") or
			EffectManager.hasCondition(rSource, "Petrified") or
			EffectManager.hasCondition(rSource, "Stunned") or
			EffectManager.hasCondition(rSource, "Unconscious");
	if bFrozen then
		rRoll.bEffects = true;
	end

	if EffectManager.hasTextOrTag(rSource, "SCOVER", tSrcEffData) then
		rRoll.bSuperiorCover = true;
	elseif EffectManager.hasTextOrTag(rSource, "COVER", tSrcEffData) then
		rRoll.bCover = true;
	end

	-- Handle crit range effects
	local tCritRange = EffectManager.getCompsDataByTag(rSource, "CRIT", tSrcEffData);
	if #tCritRange > 0 then
		rRoll.nCritThreshold = 20;
		for _,v in ipairs(tCritRange) do
			if v.mod > 1 and v.mod < rRoll.nCritThreshold then
				rRoll.bEffects = true;
				rRoll.nCritThreshold = v.mod;
			end
		end
		if rRoll.nCritThreshold < 20 then
			local sRollCritThreshold = rRoll.sDesc:match("%[CRIT (%d+)%]");
			local nRollCritThreshold = tonumber(sRollCritThreshold) or 20;
			if rRoll.nCritThreshold < nRollCritThreshold then
				if rRoll.sDesc:match(" %[CRIT %d+%]") then
					rRoll.sDesc = rRoll.sDesc:gsub(" %[CRIT %d+%]", string.format("[CRIT %d]", rRoll.nCritThreshold));
				else
					table.insert(rRoll.tNotifications, string.format("[CRIT %d]", rRoll.nCritThreshold));
				end
			end
		end
	end
end
function applyRangeToRollMod(rRoll, rSource, rTarget)
	-- Handle prone condition range
	if EffectManager.hasCondition(rTarget, "Prone") then
		if ActorManager.isInRange(rSource, rTarget, 5) then
			rRoll.bADV = true;
		else
			rRoll.bDIS = true;
		end
	end

	-- Handle ranged attack specific modifications
	if rRoll.sRange == "R" then
		-- Check if ranged attack in melee
		if not bInvisible and EffectQueryManager.onRangeCheck(rSource, "5,enemy,!incapacitated") then
			local bApply = true;
			if rRoll.bWeapon then
				bApply = not ActorManager5E.hasRollFeat2024(rSource, CharManager.FEAT_SHARPSHOOTER) and
						not ActorManager5E.hasRollFeat2014(rSource, CharManager.FEAT_CROSSBOW_EXPORT);
			elseif rRoll.bSpell then
				bApply = not ActorManager5E.hasRollFeat2024(rSource, CharManager.FEAT_SPELL_SNIPER) and
						not ActorManager5E.hasRollFeat2014(rSource, CharManager.FEAT_CROSSBOW_EXPORT);
			end
			if bApply then
				rRoll.bDIS = true;
				table.insert(rRoll.tNotifications, "[RANGED ATTACK NEXT TO ENEMY]");
			end
		end

		-- Check cover bypass
		if rRoll.bSuperiorCover or rRoll.bCover then
			if rRoll.bSpell then
				if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_SPELL_SNIPER) then
					rRoll.bSuperiorCover = false;
					rRoll.bCover = false;
					table.insert(rRoll.tNotifications, "[COVER BYPASSED]");
				end
			elseif rRoll.bWeapon then
				if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_SHARPSHOOTER) then
					rRoll.bSuperiorCover = false;
					rRoll.bCover = false;
					table.insert(rRoll.tNotifications, "[COVER BYPASSED]");
				end
			end
		end

		-- Apply range modifiers
		if rRoll.bSpell then
			if ActorManager5E.hasRollFeat2024(rSource, CharManager.FEAT_SPELL_SNIPER) then
				if (rRoll.nRange or 0) >= 10 then
					rRoll.nRange = rRoll.nRange + 60;
				end
			elseif ActorManager5E.hasRollFeat2014(rSource, CharManager.FEAT_SPELL_SNIPER) then
				if (rRoll.nRange or 0) > 0 then
					rRoll.nRange = rRoll.nRange * 2;
				end
			end
		elseif rRoll.bWeapon then
			if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_SHARPSHOOTER) then
				if ((rRoll.nRange or 0) > 0) and ((rRoll.nRangeLong or 0) > rRoll.nRange) then
					rRoll.nRange = rRoll.nRangeLong;
				end
			end
		end
		if (rRoll.nRangeLong or 0) <= (rRoll.nRange or 0) then
			rRoll.nRangeLong = rRoll.nRange;
		end
		local nTokenRange = ActorManager.getDistanceBetween(rSource, rTarget);
		if nTokenRange then
			if nTokenRange > (rRoll.nRangeLong or 0) then
				rRoll.bOutOfRange = true;
				table.insert(rRoll.tNotifications, "[OUT OF RANGE]");
			elseif nTokenRange > (rRoll.nRange or 0) then
				rRoll.bDIS = true;
				table.insert(rRoll.tNotifications, "[LONG RANGE]");
			end
		end
	end
end
function applyReliableEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	if EffectManager.hasText(rSource, "RELIABLE", { tActionTags = rRoll.tActionTags, }) then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif EffectManager.hasTextOrTag(rSource, "RELIABLEATK", { tFilter = rRoll.tAttackFilter, tActionTags = rRoll.tActionTags, }) then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end
end
function applyDefenderEffectsToRollMod(rRoll, rSource, rTarget)
	-- Handle defender ADV/DIS
	local bDefADV, bDefDIS = ActorManager5E.getDefenseAdvantage(rSource, rTarget, rRoll);
	if bDefADV then
		rRoll.bADV = true;
	end
	if bDefDIS then
		rRoll.bDIS = true;
	end
end
function finalizeRollMod(rRoll)
	if rRoll.bSuperiorCover then
		rRoll.nMod = rRoll.nMod - 5;
		table.insert(rRoll.tNotifications, "[COVER -5]");
	elseif rRoll.bCover then
		rRoll.nMod = rRoll.nMod - 2;
		table.insert(rRoll.tNotifications, "[COVER -2]");
	end

	rRoll.bOpportunity = nil;
	rRoll.bCover = nil;
	rRoll.bSuperiorCover = nil;
	rRoll.tAttackFilter = nil;
end
