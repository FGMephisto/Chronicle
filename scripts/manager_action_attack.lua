-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerResultHandler("attack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionAttack.applyAttack(rSource, rTarget, rRoll);
end
function notifyApplyAttack(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	rRoll.bSecret = rRoll.bTower;
	rRoll.sResults = table.concat(rRoll.aMessages, " ");
	
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYATK;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end
function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		bRemoveOnMiss = (#aTargeting > 1);
	end
	
	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = "true";
		end
	end

	return aTargeting;
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function getRoll(rActor, rAction)
	local rRoll = ActionsManager2.setupD20RollBuild("attack", rActor);
	ActionAttack.setupRollBuild(rRoll, rActor, rAction);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetVsRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
	
	ActionsManager.actionDirect(nil, "attack", { rRoll }, { { rActor } });
end

function modAttack(rSource, rTarget, rRoll)
	ActionAttack.clearCritState(rSource);
	
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

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");

	ActionAttack.setupAttackResolve(rRoll, rSource, rTarget);
	
	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end
	
	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
end
function onPreAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- Do nothing; location to override
end
function onAttackResolve(rSource, rTarget, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);
	
	if rTarget then
		ActionAttack.notifyApplyAttack(rSource, rTarget, rRoll);
	end
	
	-- TRACK CRITICAL STATE
	if rRoll.sResult == "crit" then
		ActionAttack.setCritState(rSource, rTarget);
	end
	
	-- REMOVE TARGET ON MISS OPTION
	if rTarget then
		if (rRoll.sResult == "miss" or rRoll.sResult == "fumble") then
			if rRoll.bRemoveOnMiss then
				TargetingManager.removeTarget(ActorManager.getCTNodeName(rSource), ActorManager.getCTNodeName(rTarget));
			end
		end
	end
end
function onPostAttackResolve(rSource, rTarget, rRoll, rMessage)
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
	ActionAttack.checkAttackResult(rRoll);
end
function decodeAttackRoll(rRoll)
	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	-- Rebuild detail fields if dragging from chat window
	if not rRoll.nOrder then
		rRoll.nOrder = tonumber(rRoll.sDesc:match("%[ATTACK.-#(%d+)")) or nil;
	end
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.-%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.-%]([^%[]+)"));
	end
end
function checkAttackDefense(rRoll, rSource, rTarget)
	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);
	if rRoll.nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end
	if rRoll.nDefEffectsBonus ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, string.format("[%s %+d]", Interface.getString("effects_def_tag"), rRoll.nDefEffectsBonus));
	end
end
function checkAttackResult(rRoll)
	local sCritThreshold = rRoll.sDesc:match("%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end
	
	rRoll.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rRoll.nFirstDie >= nCritThreshold then
		rRoll.bSpecial = true;
		rRoll.sResult = "crit";
		table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	elseif rRoll.nFirstDie == 1 then
		rRoll.sResult = "fumble";
		table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	elseif rRoll.nDefenseVal then
		if rRoll.nTotal >= rRoll.nDefenseVal then
			rRoll.sResult = "hit";
			table.insert(rRoll.aMessages, "[HIT]");
		else
			rRoll.sResult = "miss";
			table.insert(rRoll.aMessages, "[MISS]");
		end
	end
end

function applyAttack(rSource, rTarget, rRoll)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };
	
	-- Standard roll information
	msgShort.text = "Attack";
	msgLong.text = "Attack";
	if rRoll.nOrder then
		msgShort.text = string.format("%s #%d", msgShort.text, rRoll.nOrder);
		msgLong.text = string.format("%s #%d", msgLong.text, rRoll.nOrder);
	end
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end
	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sLabel or "");
	end
	msgLong.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);
	
	-- Targeting information
	msgShort.text = string.format("%s ->", msgShort.text);
	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		local sTargetName;
		if (rRoll.sSubtargetPath or "") ~= "" then
			sTargetName = string.format("%s (%s)", ActorManager.getDisplayName(rTarget), DB.getValue(DB.getPath(rRoll.sSubtargetPath, "name"), ""));
		else
			sTargetName = ActorManager.getDisplayName(rTarget);
		end
		msgShort.text = string.format("%s [at %s]", msgShort.text, sTargetName);
		msgLong.text = string.format("%s [at %s]", msgLong.text, sTargetName);
	end

	-- Extra roll information
	msgShort.icon = "roll_attack";
	if (rRoll.sResults or "") ~= "" then
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sResults);
		if rRoll.sResults:match("%[CRITICAL HIT%]") then
			msgLong.icon = "roll_attack_crit";
		elseif rRoll.sResults:match("HIT%]") then
			msgLong.icon = "roll_attack_hit";
		elseif rRoll.sResults:match("MISS%]") then
			msgLong.icon = "roll_attack_miss";
		else
			msgLong.icon = "roll_attack";
		end
	else
		msgLong.icon = "roll_attack";
	end
		
	ActionsManager.outputResult(rRoll.bSecret, rSource, rTarget, msgLong, msgShort);
end

--
--	MOD ROLL HELPERS
--

function setupRollBuild(rRoll, rActor, rAction)
	rRoll.sLabel = StringManager.capitalizeAll(rAction.label);
	rRoll.nOrder = rAction.order;
	rRoll.sRange = rAction.range;
	rRoll.nMod = rAction.modifier or 0;
	rRoll.bWeapon = rAction.bWeapon;
	rRoll.bADV = rAction.bADV or false;
	rRoll.bDIS = rAction.bDIS or false;

	-- Build the description label
	local sAttackTag = "[ATTACK";
	if (rAction.order or 1) > 1 then
		sAttackTag = string.format("%s #%d", sAttackTag, rAction.order);
	end
	if rAction.range then
		sAttackTag = string.format("%s (%s)", sAttackTag, rAction.range);
	end
	sAttackTag = sAttackTag .. "]";
	table.insert(rRoll.tNotifications, sAttackTag);
	table.insert(rRoll.tNotifications, StringManager.capitalizeAll(rAction.label));
	
	-- Add crit range
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
		local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
		if nodeActor and (sNodeType == "pc") then
			if StringManager.contains({"strength", "dexterity"}, rAction.stat) then
				local nodePC = ActorManager.getCreatureNode(rActor);
				if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
					rRoll.bDIS = true;
					table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_armor_nonprof")));
				end
			end
		end
	end
	
	if #(rAction.tAddText or {}) > 0 then
		table.insert(rRoll.tNotifications, table.concat(rAction.tAddText, " "));
	end
end

function setupRollMod(rRoll)
	rRoll.sAttackType = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]") or "M";

	rRoll.sAbility = rRoll.sDesc:match("%[MOD:(%w+)%]");
	if rRoll.sAbility then
		rRoll.sAbility = DataCommon.ability_stol[rRoll.sAbility];
	end

	-- Check for opportunity attack
	rRoll.bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();
	if rRoll.bOpportunity then
		table.insert(rRoll.tNotifications, "[OPPORTUNITY]");
	end

	-- Check cover
	rRoll.bCover = ModifierManager.getKey("DEF_COVER");
	rRoll.bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");
	if rRoll.bSuperiorCover then
		table.insert(rRoll.tNotifications, "[COVER -5]");
	elseif rRoll.bCover then
		table.insert(rRoll.tNotifications, "[COVER -2]");
	end

	-- Build attack filter
	rRoll.tAttackFilter = {};
	if rRoll.sAttackType == "M" then
		table.insert(rRoll.tAttackFilter, "melee");
	elseif rRoll.sAttackType == "R" then
		table.insert(rRoll.tAttackFilter, "ranged");
	end
	if rRoll.bOpportunity then
		table.insert(rRoll.tAttackFilter, "opportunity");
	end
end
function applyEffectsToRollMod(rRoll, rSource, rTarget)
	ActionsManager2.applyAbilityEffectsToD20RollMod(rRoll, rSource, rTarget);
	ActionAttack.applyStandardEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyReliableEffectsToRollMod(rRoll, rSource, rTarget);
	ActionAttack.applyDefenderEffectsToRollMod(rRoll, rSource, rTarget);
end
function applyStandardEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	-- Get roll effect modifiers
	local tAttackDice, nAttackMod, nAttackEffect = EffectManager5E.getEffectsBonus(rSource, { "ATK" }, false, rRoll.tAttackFilter, rTarget);
	if (nAttackEffect > 0) then
		rRoll.bEffects = true;
		for _,vDie in ipairs(tAttackDice) do
			table.insert(rRoll.tEffectDice, vDie);
		end
		rRoll.nEffectMod = rRoll.nEffectMod + nAttackMod;
	end
	
	-- Get condition modifiers
	if EffectManager5E.hasEffectCondition(rSource, "ADVATK", rTarget) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "ADVATK", rRoll.tAttackFilter, rTarget)) > 0 then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Invisible") then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end
	if EffectManager5E.hasEffectCondition(rSource, "DISATK", rTarget) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "DISATK", rRoll.tAttackFilter, rTarget)) > 0 then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Blinded") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
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
	elseif EffectManager.hasCondition(rSource, "Prone") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "Restrained") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	end

	local bFrozen = EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
			EffectManager5E.hasEffectCondition(rSource, "Petrified") or
			EffectManager5E.hasEffectCondition(rSource, "Stunned") or
			EffectManager5E.hasEffectCondition(rSource, "Unconscious");
	if bFrozen then
		rRoll.bEffects = true;
	end

	-- Handle crit range effects
	local tCritRange = EffectManager5E.getEffectsByType(rSource, "CRIT", rRoll.tAttackFilter, rTarget);
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
					rRoll.sDesc = rRoll.sDesc:gsub(" %[CRIT %d+%]", " [CRIT " .. rRoll.nCritThreshold .. "]");
				else
					rRoll.sDesc = rRoll.sDesc ..  " [CRIT " .. rRoll.nCritThreshold .. "]";
				end
			end
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
		if nExhaustMod > 2 then
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
	elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLEATK") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLEATK", rRoll.tAttackFilter)) > 0 then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end
end
function applyDefenderEffectsToRollMod(rRoll, rSource, rTarget)
	-- Handle defender ADV/DIS
	local bDefADV, bDefDIS = ActorManager5E.getDefenseAdvantage(rSource, rTarget, rRoll.tAttackFilter);
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
	elseif rRoll.bCover then
		rRoll.nMod = rRoll.nMod - 2;
	end
	
	rRoll.bOpportunity = nil;
	rRoll.bCover = nil;
	rRoll.bSuperiorCover = nil;
	rRoll.tAttackFilter = nil;
end

--
--	CRIT STATE TRACKING
--

aCritState = {};
function setCritState(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end
	
	if not aCritState[sSourceCT] then
		aCritState[sSourceCT] = {};
	end
	table.insert(aCritState[sSourceCT], sTargetCT);
end
function clearCritState(rSource)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
	end
end
function isCrit(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end

	if not aCritState[sSourceCT] then
		return false;
	end
	
	for k,v in ipairs(aCritState[sSourceCT]) do
		if v == sTargetCT then
			table.remove(aCritState[sSourceCT], k);
			return true;
		end
	end
	
	return false;
end
