--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

local _rActionFallback = {};

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

	rRoll.bSecret = rRoll.bTower;
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
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.bWeapon = rAction.bWeapon;
	rRoll.sLabel = rAction.label;
	rRoll.sRange = rAction.range;
	rRoll.sType = "attack";
	rRoll.nTest = rAction.nStat or 0;
	rRoll.nBonus = rAction.nSkill or 0;
	rRoll.nPenalty = rAction.nPenalty or 0;
	rRoll.nDoS = 1;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nMod = rAction.nMod or 0;
	rRoll.nodeWeapon = rAction.nodeWeapon;
	rRoll.sWeaponNode = (rAction.nodeWeapon and DB.getPath(rAction.nodeWeapon)) or "";

	_rActionFallback = rAction;

	for _ = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6");
	end
	for _ = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6");
	end

	rRoll.sDesc = "[ATTACK";
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. (rAction.label or "");

	return rRoll;
end

function modAttack(rSource, rTarget, rRoll)
	ActionAttack.clearCritState(rSource);

	local aAddDesc = {};

	rRoll.nTest = tonumber(rRoll.nTest) or 0;
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;
	rRoll.nMod = tonumber(rRoll.nMod) or 0;

	local bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();
	if bOpportunity then
		table.insert(aAddDesc, "[OPPORTUNITY]");
	end

	ActionsManager2.encodeHealthMods(rSource, rRoll);
	ActionsManager2.encodeDesktopMods(rRoll);

	if rSource then
		ActionAttack.applyChronicleAttackModifiers(rSource, rTarget, rRoll, aAddDesc);
	end

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end

	ActionResult.capDice(rRoll);
end

function onAttack(rSource, rTarget, rRoll)
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rRoll = ActionResult.DropDice(rRoll);

	rRoll.aMessages = {};

	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);

	if (rRoll.nAtkEffectsBonus or 0) ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end

	if (rRoll.nDefEffectsBonus or 0) ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, string.format("[%s %+d]", Interface.getString("effects_def_tag"), rRoll.nDefEffectsBonus));
	end

	if rRoll.nDefenseVal then
		rMessage, rRoll = ActionResult.DetermineSuccessAttack(rMessage, rRoll);
	end

	local nodeWeapon = rRoll.nodeWeapon or ((rRoll.sWeaponNode or "") ~= "" and DB.findNode(rRoll.sWeaponNode)) or (_rActionFallback and _rActionFallback.nodeWeapon);
	if nodeWeapon then
		DB.setValue(nodeWeapon, "dmg_multiplier", "number", (rRoll.nDoS or 1) - 1);
	end

	if not rTarget and #(rRoll.aMessages) > 0 then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end

	GameManager.callEventFunctions("onAttackPreResolve", rSource, rTarget, rRoll);
	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
	GameManager.callEventFunctions("onAttackPostResolve", rSource, rTarget, rRoll);
end
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

function applyAttack(rSource, rTarget, rRoll)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };

	msgShort.text = "[Attack";
	msgLong.text = "[Attack";

	if rRoll.nOrder then
		msgShort.text = string.format("%s #%d", msgShort.text, rRoll.nOrder);
		msgLong.text = string.format("%s #%d", msgLong.text, rRoll.nOrder);
	end
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end

	msgShort.text = string.format("%s]", msgShort.text);
	msgLong.text = string.format("%s]", msgLong.text);

	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s %s", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s %s", msgLong.text, rRoll.sLabel or "");
	end
	msgLong.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);

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
-- CHRONICLE CUSTOM SYSTEMS
--

function applyChronicleAttackModifiers(rSource, rTarget, rRoll, aAddDesc)
	local aAttackFilter = {};
	local sAttackType = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]") or "M";
	if sAttackType == "M" then
		table.insert(aAttackFilter, "melee");
	elseif sAttackType == "R" then
		table.insert(aAttackFilter, "ranged");
	end

	if ModifierManager.getKey("ATT_AIM") then
		table.insert(aAddDesc, "[Aim +1B]");
		rRoll.nBonus = rRoll.nBonus + 1;
	end

	if ModifierManager.getKey("ATT_HIGHGROUND") and (sAttackType == "M") then
		table.insert(aAddDesc, "[HIGHGROUND +1B]");
		rRoll.nBonus = rRoll.nBonus + 1;
	end

	if ModifierManager.getKey("ATT_CAUTIOUS") then
		table.insert(aAddDesc, "[CAUTIOUS -1D, CoD +3]");
		rRoll.nPenalty = rRoll.nPenalty + 1;
	end

	if ModifierManager.getKey("ATT_RECKLESS") then
		table.insert(aAddDesc, "[RECKLESS +1D, CoD -5]");
		rRoll.nTest = rRoll.nTest + 1;
	end

	if ModifierManager.getKey("DEF_COVER") then
		table.insert(aAddDesc, "[COVER -5]");
		rRoll.nMod = rRoll.nMod - 5;
	end

	if ModifierManager.getKey("DEF_SCOVER") then
		table.insert(aAddDesc, "[COVER -10]");
		rRoll.nMod = rRoll.nMod - 10;
	end

	if ModifierManager.getKey("DEF_LOWLIGHT") then
		if sAttackType == "M" then
			table.insert(aAddDesc, "[SHADOWY -1D]");
			rRoll.nPenalty = rRoll.nPenalty + 1;
		elseif sAttackType == "R" then
			table.insert(aAddDesc, "[SHADOWY -2D]");
			rRoll.nPenalty = rRoll.nPenalty + 2;
		end
	end

	if ModifierManager.getKey("DEF_NOLIGHT") then
		if sAttackType == "M" then
			table.insert(aAddDesc, "[DARKNESS -2D]");
			rRoll.nPenalty = rRoll.nPenalty + 2;
		elseif sAttackType == "R" then
			table.insert(aAddDesc, "[DARKNESS -4D]");
			rRoll.nPenalty = rRoll.nPenalty + 4;
		end
	end

	if ModifierManager.getKey("DEF_SPRINT") then
		table.insert(aAddDesc, "[Moving Target -1D]");
		rRoll.nPenalty = rRoll.nPenalty + 1;
	end

	local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, { "ATK" }, false, aAttackFilter, rTarget);
	if (nEffectCount > 0) or (nAddMod ~= 0) or (#aAddDice > 0) then
		rRoll.nMod = rRoll.nMod + nAddMod;
		local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
		table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
	end

	local tCheckConditions = { "Blinded", "Encumbered", "Frightened", "Intoxicated", "Invisible", "Poisoned", "Prone", "Restrained", "Unconscious" };
	for _, sCond in ipairs(tCheckConditions) do
		if EffectManager5E.hasEffectCondition(rSource, sCond) or EffectManager.hasCondition(rSource, sCond) then
			table.insert(aAddDesc, string.format("[%s]", sCond:upper()));
		end
	end
end

function setCritState(rSource, rTarget)
	ActionAttackCore.setCritState(rSource, rTarget);
end
function clearCritState(rSource)
	ActionAttackCore.clearCritState(rSource);
end
function isCrit(rSource, rTarget)
	return ActionAttackCore.getCritState(rSource, rTarget);
end