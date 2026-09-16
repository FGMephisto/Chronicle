--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	GameManager.setMultiKeyFunction("onActionPostGetRoll", "damage", ActionDamage.onDamagePostGetRoll);
	GameManager.setMultiKeyFunction("onActionPreResolve", "heal", ActionDamage.onHealPreResolve);

	GameManager.setMultiKeyFunction("onHealthApplyType", "recovery", ActionDamage.applyRecovery);
	GameManager.setFunction("onHealthPostApply", ActionDamage.onPostApply);

	GameManager.setOption("atktype", "5E");
	GameManager.setOption("critical", "5E");
	GameManager.setOption("deathsave", "5E");
	GameManager.setOption("dmgmishap", "5E");
	GameManager.setOption("dmgthreshold", "5E");
	GameManager.setOption("regeneration", "5E");
	GameManager.setOption("systemshock", "5E");

	ActionDamageD20.registerStandardDamageHealHandlers();
	ActionDamageD20.notifyApplyDamage = ActionDamage.notifyApplyDamage;
	OOBManager.registerOOBMsgHandler(ActionDamageD20.OOB_MSGTYPE_APPLYDMG, ActionDamage.handleApplyDamage);

	ActionsManager.registerResultHandler("damage", ActionDamage.onDamage);
	GameManager.setFunction("onDamageApplyResults", ActionDamage.applyDamageResultsChronicle);
	GameManager.setFunction("onHealthApplyGetHealth", ActionDamage.applyGetHealthChronicle);
	GameManager.setFunction("onHealthApplySetHealth", ActionDamage.applySetHealthChronicle);

	-- Record field mapping for Chronicle health structures
	GameManager.setRecordFieldMap("charsheet", "hptotal", "hptotal");
	GameManager.setRecordFieldMap("charsheet", "wounds", "wounds");
	GameManager.setRecordFieldMap("charsheet", "hptemp", "hptemp");
	GameManager.setRecordFieldMap("charsheet", "deathsavesuccess", "deathsavesuccess");
	GameManager.setRecordFieldMap("charsheet", "deathsavefail", "deathsavefail");
	GameManager.setRecordFieldMap("npc", "hptotal", "hp");
	GameManager.setRecordFieldMap("npc", "wounds", "wounds");
	GameManager.setRecordFieldMap("npc", "hptemp", "hptemp");
	GameManager.setRecordFieldMap("", "hptotal", "hptotal");
	GameManager.setRecordFieldMap("", "wounds", "wounds");
	GameManager.setRecordFieldMap("", "hptemp", "hptemp");

	-- Override combat overlay toast for Chronicle to display blank/untyped damage as "N damage"
	if OverlayCombatManager and OverlayCombatManager.helperDamageNotifyToast then
		OverlayCombatManager.helperDamageNotifyToast = ActionDamage.helperDamageNotifyToastChronicle;
	end
end

--
--	ROLL HANDLING
--

function onDamagePostGetRoll(rActor, rAction, rRoll)
	ActionDamage.applyCritMetaToRoll(rActor, rAction, rRoll);
	ActionDamage.applyChronicleRollData(rActor, rAction, rRoll);
end
function applyCritMetaToRoll(rActor, _, rRoll)
	if not rRoll or not rRoll.clauses or not rRoll.clauses[1] then
		return;
	end

	local nCritDice = 0;
	if rRoll.bWeapon and ActorManager.isPC(rActor) then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			if rRoll.sRange == "R" then
				nCritDice = DB.getValue(nodeActor, "weapon.critdicebonus.ranged", 0);
			else
				nCritDice = DB.getValue(nodeActor, "weapon.critdicebonus.melee", 0);
			end
		end
	end
	if nCritDice > 0 then
		rRoll.clauses[1].nExtraCritDice = nCritDice;
	end
end

function onHealPreResolve(rSource, _, rRoll)
	ActionsManager2.handleHealerFeat(rSource, rRoll);
end

--
--	DAMAGE APPLICATION
--

function applyRecovery(rSource, rTarget, rRoll, tApplyData)
	-- Determine whether HD available
	local nClassHD = 0;
	local nClassHDMult = 0;
	local nClassHDUsed = 0;
	local sClassNode = rRoll.sDesc:match("%[NODE:([^]]+)%]");
	if sClassNode then
		local nodeClass = DB.findNode(sClassNode);
		if nodeClass then
			nClassHD = DB.getValue(nodeClass, "level", 0);
			nClassHDMult = #(DB.getValue(nodeClass, "hddie", {}));
			nClassHDUsed = DB.getValue(nodeClass, "hdused", 0);
		end
	end
	if (nClassHD * nClassHDMult) <= nClassHDUsed then
		rRoll.tResults = {};
		table.insert(tApplyData.tNotifications, "[INSUFFICIENT HIT DICE FOR THIS CLASS]");
		return;
	end

	ActionHealthD20.applyHeal(rSource, rTarget, rRoll, tApplyData);

	-- Decrement HD used
	if sClassNode then
		local nodeClass = DB.findNode(sClassNode);
		if nodeClass then
			DB.setValue(nodeClass, "hdused", "number", nClassHDUsed + 1);
		end
	end
end

function onPostApply(rSource, rTarget, rRoll, tApplyData)
	ActionHealthD20.onPostApplyDefault(rSource, rTarget, rRoll, tApplyData);

	if tApplyData.sType == "damage" then
		ActionDamage.onDamagePostApply(rSource, rTarget, rRoll, tApplyData);
	elseif tApplyData.sType == "heal" then
		ActionDamage.onHealPostApply(rSource, rTarget, rRoll, tApplyData);
	end
end
function onDamagePostApply(rSource, rTarget, rRoll, tApplyData)
	ActionDamage.handleConcentrationOnDamage(rSource, rTarget, rRoll, tApplyData);
	ActionDamage.handleFortitudeTraitOnDamage(rSource, rTarget, rRoll, tApplyData);
end
function onHealPostApply(rSource, rTarget, rRoll, tApplyData)
	ActionDamage.handleExhaustionOnHeal(rSource, rTarget, rRoll, tApplyData);
end

function handleConcentrationOnDamage(rSource, rTarget, _, tApplyData)
	-- Check for required concentration checks
	if (tApplyData.nConcentrationDamage or 0) <= 0 or not ActionSave.hasConcentrationEffects(rTarget) then
		return;
	end

	if ActorHealthManager.isDyingOrDeadStatus(tApplyData.tHealth.sNewStatus) then
		ActionSave.expireConcentrationEffects(rTarget);
	else
		local tData;
		if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_MAGE_SLAYER) then
			tData = { bDIS = true, sAddText = "[MAGE SLAYER]", };
		end
		local nTargetDC = math.max(math.floor(tApplyData.nConcentrationDamage / 2), 10);
		ActionSave.performConcentrationRoll(nil, rTarget, nTargetDC, tData);
	end
end
function handleExhaustionOnHeal(_, rTarget, _, tApplyData)
	if OptionsManager.isOption("HRHE", "off") then
		return;
	end
	if not ActorHealthManager.isDyingOrDeadStatus(tApplyData.tHealth.sOriginalStatus) or
			ActorHealthManager.isDyingOrDeadStatus(tApplyData.tHealth.sNewStatus) then
		return;
	end
	EffectManager.addEffectByText(rTarget, "EXHAUSTION: " .. OptionsManager.getOption("HRHE"));
end

function handleFortitudeTraitOnDamage(_, rTarget, _, tApplyData)
	-- CHECK TO SEE IF DAMAGE PUSHED INTO DEATH STATUS
	if not tApplyData.tHealth or ActorHealthManager.isDyingOrDeadStatus(tApplyData.tHealth.sOriginalStatus) or
			not	ActorHealthManager.isDyingOrDeadStatus(tApplyData.tHealth.sNewStatus) then
		return;
	end

	-- CHECK TO SEE IF ACTOR HAS FORTITUDE TRAIT
	local tFortitudeData = ActionDamage.getFortitudeTraitData(rTarget);
	if not tFortitudeData then
		return;
	end

	-- CHECK TO SEE IF DAMAGE OVERCOMES FORTITUDE TRAIT
	local setActualDamageTypes = SetManager.new();
	for k,v in pairs(tApplyData.tDamageTypes or {}) do
		if v > 0 then
			SetManager.add(setActualDamageTypes, StringManager.split(k, ",", true));
		end
	end
	if SetManager.overlaps(setActualDamageTypes, tFortitudeData.tExceptions) then
		return;
	end

	-- ROLL CON SAVE TO APPLY FORTITUDE TRAIT
	local rRoll = ActionSave.getRoll(rTarget, "constitution");
	rRoll.sSubType = "fortitude";
	rRoll.sSaveTrait = tFortitudeData.sName;
	rRoll.sDesc = StringManager.append(rRoll.sDesc, string.format("(%s)", tFortitudeData.sName), "\r");
	rRoll.nTarget = 5 + (tApplyData.nValue or 0);
	ActionsManager.performAction(nil, rTarget, rRoll);
end
function getFortitudeTraitData(rActor)
	local sListPath;
	if ActorManager.isPC(rActor) then
		sListPath = "traitlist";
	elseif ActorManager.isRecordType(rActor, "npc") then
		sListPath = "traits";
	else
		return nil;
	end
	for _, nodeTrait in pairs(DB.getChildList(ActorManager.getCreatureNode(rActor), sListPath)) do
		local tData = ActionDamage.getFortitudeTraitDataHelper(rActor, nodeTrait);
		if tData then
			return tData;
		end
	end
end
function getFortitudeTraitDataHelper(rActor, nodeTrait)
	if not nodeTrait then
		return nil;
	end
	local sName = DB.getValue(nodeTrait, "name", "");
	local sNameLower = sName:lower();
	if not sNameLower:match("fortitude") then
		return nil;
	end

	local sTextLower;
	if ActorManager.isPC(rActor) then
		sTextLower = DB.getText(nodeTrait, "text", ""):lower();
	else
		sTextLower = DB.getText(nodeTrait, "desc", ""):lower();
	end
	if not (sTextLower:match("if%s+damage%s+reduces") and sTextLower:match("to%s+0%s+hit%s+points") and sTextLower:match("drops%s+to%s+1%s+hit%s+point%s+instead")) then
		return nil;
	end

	local tData = {
		sName = sName,
		tExceptions = { "critical", },
	};
	if sTextLower:match("unless%s+the%s+damage%s+is%s+radiant") then
		table.insert(tData.tExceptions, "radiant");
	end
	return tData;
end

--
-- CHRONICLE CUSTOM SYSTEMS
--

function applyChronicleRollData(rActor, rAction, rRoll)
	if not rRoll then
		return;
	end

	local nDoS = 1;
	if rAction then
		if rAction.nDoS then
			nDoS = tonumber(rAction.nDoS) or 1;
		elseif rAction.nodeWeapon then
			nDoS = (tonumber(DB.getValue(rAction.nodeWeapon, "dmg_multiplier", 0)) or 0) + 1;
		end
	end
	rRoll.nDoS = nDoS;
	if nDoS > 1 then
		rRoll.sDesc = string.format("%s [DOS: %d]", rRoll.sDesc or "", nDoS);
	end

	local sQualities = "";
	if rAction and rAction.nodeWeapon then
		sQualities = DB.getValue(rAction.nodeWeapon, "wpn_qualities", "");
	elseif rActor and rActor.sWeaponQualities then
		sQualities = rActor.sWeaponQualities;
	end
	if sQualities ~= "" then
		rRoll.sWeaponQualities = sQualities;
		rRoll.sDesc = string.format("%s [QUALITIES: %s]", rRoll.sDesc or "", sQualities);
	end
end

function onDamage(rSource, rTarget, rRoll)
	local nDoS = rRoll.nDoS or (rRoll.sDesc and tonumber(rRoll.sDesc:match("%[DOS: (%d+)%]"))) or 1;
	if nDoS > 1 then
		rRoll.nTotal = ActionsManager.total(rRoll) * nDoS;
		if rRoll.clauses then
			for _, tClause in ipairs(rRoll.clauses) do
				tClause.modifier = (tClause.modifier or 0) * nDoS;
			end
		end
	else
		rRoll.nTotal = ActionsManager.total(rRoll);
	end

	-- Remove redundant [TYPE: damage] or [TYPE: untyped] display in Chronicle chat
	if rRoll.sDesc then
		rRoll.sDesc = rRoll.sDesc:gsub("%s?%[TYPE: damage[^]]*%]", ""):gsub("%s?%[TYPE: untyped[^]]*%]", "");
	end

	ActionDamageD20.onRoll(rSource, rTarget, rRoll);
end

function helperDamageNotifyToastChronicle(rSource, tActions)
	local tToastText = {};

	local sToastIcon = nil;
	local sToastIconColor = nil;
	local tDamageTotal = {};
	local tTargets = {};
	for _, tAction in ipairs(tActions or {}) do
		if tAction.tData and ActionsManager.getShowResult(rSource, tAction.rTarget) then
			if tAction.rTarget then
				table.insert(tTargets, ActorManager.getDisplayName(tAction.rTarget));
			end

			for sKey, tResult in pairs(tAction.tData.tResults or {}) do
				if (sToastIcon or "") == "" then
					sToastIcon = tResult.sIcon;
					sToastIconColor = tResult.sColor;
				elseif sToastIcon ~= tResult.sIcon then
					sToastIcon = ActionDamageCore.getDamageTypeIcon("");
					sToastIconColor = ActionDamageCore.getDamageTypeColor("");
				end

				tDamageTotal[sKey] = (tDamageTotal[sKey] or 0) + (tResult.nTotal or 0);
			end
		end
	end
	if not next(tDamageTotal) then
		return;
	end
	local tDamageTypeText = {};
	for sKey, nDamage in pairs(tDamageTotal) do
		if nDamage > 0 then
			local sTypeText = (sKey ~= "" and sKey ~= "untyped") and sKey or "damage";
			table.insert(tDamageTypeText, string.format("<font color=%s>%d %s</font>", ActionDamageCore.getDamageTypeColor(sKey), nDamage, sTypeText));
		end
	end
	if #tDamageTypeText == 0 then
		table.insert(tDamageTypeText, Interface.getString("combat_toast_text_damage_none"));
	end

	if rSource then
		local sDamage = string.format(Interface.getString("combat_toast_text_damage"), ActorManager.getDisplayName(rSource), table.concat(tDamageTypeText, ", "));
		table.insert(tToastText, sDamage);
	else
		table.insert(tToastText, table.concat(tDamageTypeText, ", "));
	end

	if #tTargets > 0 then
		local sResultText = string.format("<font name=\"toast-bold\">%s:</font> %s", Interface.getString("combat_result_damage"), table.concat(tTargets, ", "));
		table.insert(tToastText, sResultText);
	end

	local tOverlayData = {
		sOption = "TOAST_COMBAT",
		sToastType = "failure",
		sIcon = sToastIcon or ActionDamageCore.getDamageTypeIcon(""),
		sIconColor = sToastIconColor or ActionDamageCore.getDamageTypeColor(""),
		sTitle = Interface.getString("combat_toast_title_damage"),
		sText = table.concat(tToastText, "\r"),
	};
	OverlayManager.showToastMessage(tOverlayData);
end

function applyDamageResultsChronicle(rSource, rTarget, rRoll, tApplyData)
	tApplyData.nConcentrationDamage = tApplyData.nAdjustedDamage;

	ActionHealthD20.applyDamageResultsTemp(rSource, rTarget, rRoll, tApplyData);
	ActionHealthD20.applyDamageResultsNonlethal(rSource, rTarget, rRoll, tApplyData);

	if (tApplyData.nAdjustedDamage or 0) <= 0 then
		return;
	end

	local nArmorDR, nPiercing = ActionDamage.getArmorReductionChronicle(rTarget, rSource, rRoll);
	if nPiercing > 0 and nArmorDR > 0 then
		table.insert(tApplyData.tNotifications, string.format("[ARMOR PIERCED BY %d]", nPiercing));
	end
	if nArmorDR > 0 then
		local nDeflected = math.min(tApplyData.nAdjustedDamage, nArmorDR);
		tApplyData.nAdjustedDamage = math.max(0, tApplyData.nAdjustedDamage - nDeflected);
		if tApplyData.nAdjustedDamage == 0 then
			table.insert(tApplyData.tNotifications, "[ALL DEFLECTED BY ARMOR]");
		else
			table.insert(tApplyData.tNotifications, string.format("[%d DEFLECTED BY ARMOR]", nDeflected));
		end
	end

	if (tApplyData.nAdjustedDamage or 0) <= 0 then
		return;
	end

	ActionHealthD20.applyDamageResultsNormal(rSource, rTarget, rRoll, tApplyData);
	ActionHealthD20.applyDamageResultsDeathSave(rSource, rTarget, rRoll, tApplyData);
	ActionHealthD20.applyDamageResultsSystemShock(rSource, rTarget, rRoll, tApplyData);
end

function getArmorReductionChronicle(rTarget, rSource, rRoll)
	if not rTarget then
		return 0, 0;
	end

	local nodeTarget = ActorManager.getCreatureNode(rTarget);
	if not nodeTarget then
		return 0, 0;
	end

	local nAR = DB.getValue(nodeTarget, "defenses.armor.total", 0);
	if nAR <= 0 then
		local nodeCT = ActorManager.getCTNode(rTarget);
		if nodeCT and nodeCT ~= nodeTarget then
			nAR = DB.getValue(nodeCT, "armor", 0);
		end
	end

	local sQualities = "";
	if rRoll and rRoll.sWeaponQualities and rRoll.sWeaponQualities ~= "" then
		sQualities = rRoll.sWeaponQualities;
	elseif rRoll and rRoll.sDesc then
		sQualities = rRoll.sDesc:match("%[QUALITIES: ([^%]]+)%]") or "";
	elseif rSource and rSource.sWeaponQualities and rSource.sWeaponQualities ~= "" then
		sQualities = rSource.sWeaponQualities;
	end

	local nPiercing = 0;
	if sQualities ~= "" and CharWeaponManager and CharWeaponManager.getPropertyValue then
		nPiercing = CharWeaponManager.getPropertyValue(sQualities, "piercing") or 0;
	end

	local nEffectiveAR = nAR;
	if (nPiercing > 0) and (nEffectiveAR > 0) then
		nEffectiveAR = math.max(0, nEffectiveAR - nPiercing);
	end

	return nEffectiveAR, nPiercing;
end

function applyGetHealthChronicle(rActor, rRoll, tApplyData)
	local nodeCT = ActorManager.getCTNode(rActor);
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeCT and not nodeActor then
		return;
	end

	local tHealth = { ["hp"] = {}, };
	if GameManager.hasOption("deathsave") then
		tHealth["deathsave"] = {};
	end
	if GameManager.hasOption("healsurge") then
		tHealth["healsurge"] = {};
	end

	local nTotal = 0;
	local nWounds = 0;
	local nTemp = 0;

	if nodeCT then
		nTotal = DB.getValue(nodeCT, "hptotal", 0);
		if nTotal == 0 then
			nTotal = DB.getValue(nodeCT, "hp.total", 0);
		end
		nWounds = DB.getValue(nodeCT, "wounds", 0);
		if nWounds == 0 then
			nWounds = DB.getValue(nodeCT, "hp.wounds", 0);
		end
		nTemp = DB.getValue(nodeCT, "hptemp", 0);
		if nTemp == 0 then
			nTemp = DB.getValue(nodeCT, "hp.temporary", 0);
		end
	elseif ActorManager.isPC(rActor) and nodeActor then
		nTotal = DB.getValue(nodeActor, "hptotal", 0);
		if nTotal == 0 then
			nTotal = DB.getValue(nodeActor, "hp.total", 0);
		end
		nWounds = DB.getValue(nodeActor, "wounds", 0);
		if nWounds == 0 then
			nWounds = DB.getValue(nodeActor, "hp.wounds", 0);
		end
		nTemp = DB.getValue(nodeActor, "hptemp", 0);
		if nTemp == 0 then
			nTemp = DB.getValue(nodeActor, "hp.temporary", 0);
		end
	elseif nodeActor then
		nTotal = DB.getValue(nodeActor, "hptotal", 0);
		if nTotal == 0 then
			nTotal = DB.getValue(nodeActor, "hp", 0);
		end
		if nTotal == 0 then
			nTotal = DB.getValue(nodeActor, "hp.total", 0);
		end
		nWounds = DB.getValue(nodeActor, "wounds", 0);
		if nWounds == 0 then
			nWounds = DB.getValue(nodeActor, "hp.wounds", 0);
		end
	end

	-- Fallback if total was 0 but creature record has it or calculate from Endurance
	if nTotal == 0 and nodeActor then
		nTotal = DB.getValue(nodeActor, "hptotal", 0);
		if nTotal == 0 then
			nTotal = DB.getValue(nodeActor, "hp", 0);
		end
		if nTotal == 0 then
			nTotal = DB.getValue(nodeActor, "hp.total", 0);
		end
		if nTotal == 0 then
			local nEndurance = DB.getValue(nodeActor, "abilities.endurance.score", 0);
			if nEndurance > 0 then
				nTotal = nEndurance * 3;
			end
		end
	end

	tHealth["hp"].nTotal = nTotal;
	tHealth["hp"].nTemp = nTemp;
	tHealth["hp"].nWounds = nWounds;

	if GameManager.hasOption("deathsave") then
		local nSuccess = 0;
		local nFail = 0;
		if nodeCT then
			nSuccess = DB.getValue(nodeCT, "deathsavesuccess", 0);
			if nSuccess == 0 then
				nSuccess = DB.getValue(nodeCT, "hp.deathsavesuccess", 0);
			end
			nFail = DB.getValue(nodeCT, "deathsavefail", 0);
			if nFail == 0 then
				nFail = DB.getValue(nodeCT, "hp.deathsavefail", 0);
			end
		elseif nodeActor then
			nSuccess = DB.getValue(nodeActor, "deathsavesuccess", 0);
			if nSuccess == 0 then
				nSuccess = DB.getValue(nodeActor, "hp.deathsavesuccess", 0);
			end
			nFail = DB.getValue(nodeActor, "deathsavefail", 0);
			if nFail == 0 then
				nFail = DB.getValue(nodeActor, "hp.deathsavefail", 0);
			end
		end
		tHealth["deathsave"].nSuccess = nSuccess;
		tHealth["deathsave"].nFail = nFail;
	end

	tHealth.sOriginalStatus = ActorHealthManager.getHealthStatus(rActor);
	tApplyData.tHealth = tHealth;
end

function applySetHealthChronicle(rActor, rRoll, tApplyData)
	if not rActor or not tApplyData or not tApplyData.tHealth or not tApplyData.tHealth["hp"] then
		return;
	end

	local nWounds = tApplyData.tHealth["hp"].nWounds or 0;
	local nTemp = tApplyData.tHealth["hp"].nTemp or 0;

	-- Death saves handling
	if GameManager.hasOption("deathsave") and tApplyData.tHealth["deathsave"] then
		if nWounds < (tApplyData.tHealth["hp"].nTotal or 0) then
			tApplyData.tHealth["deathsave"].nSuccess = 0;
			tApplyData.tHealth["deathsave"].nFail = 0;
		else
			tApplyData.tHealth["deathsave"].nSuccess = math.min(tApplyData.tHealth["deathsave"].nSuccess or 0, 3);
			tApplyData.tHealth["deathsave"].nFail = math.min(tApplyData.tHealth["deathsave"].nFail or 0, 3);
		end
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	local nodeActor = ActorManager.getCreatureNode(rActor);

	-- If on the combat tracker, update the CT entry directly (dual-write hp.wounds and wounds)
	if nodeCT then
		DB.setValue(nodeCT, "hp.wounds", "number", nWounds);
		DB.setValue(nodeCT, "wounds", "number", nWounds);
		DB.setValue(nodeCT, "hp.temporary", "number", nTemp);
		DB.setValue(nodeCT, "hptemp", "number", nTemp);
		if GameManager.hasOption("deathsave") and tApplyData.tHealth["deathsave"] then
			DB.setValue(nodeCT, "deathsavesuccess", "number", tApplyData.tHealth["deathsave"].nSuccess);
			DB.setValue(nodeCT, "hp.deathsavesuccess", "number", tApplyData.tHealth["deathsave"].nSuccess);
			DB.setValue(nodeCT, "deathsavefail", "number", tApplyData.tHealth["deathsave"].nFail);
			DB.setValue(nodeCT, "hp.deathsavefail", "number", tApplyData.tHealth["deathsave"].nFail);
		end
	end

	-- For PCs, also sync to character sheet (or if not in CT)
	if ActorManager.isPC(rActor) and nodeActor then
		DB.setValue(nodeActor, "wounds", "number", nWounds);
		DB.setValue(nodeActor, "hp.wounds", "number", nWounds);
		DB.setValue(nodeActor, "hptemp", "number", nTemp);
		DB.setValue(nodeActor, "hp.temporary", "number", nTemp);
		if GameManager.hasOption("deathsave") and tApplyData.tHealth["deathsave"] then
			DB.setValue(nodeActor, "deathsavesuccess", "number", tApplyData.tHealth["deathsave"].nSuccess);
			DB.setValue(nodeActor, "hp.deathsavesuccess", "number", tApplyData.tHealth["deathsave"].nSuccess);
			DB.setValue(nodeActor, "deathsavefail", "number", tApplyData.tHealth["deathsave"].nFail);
			DB.setValue(nodeActor, "hp.deathsavefail", "number", tApplyData.tHealth["deathsave"].nFail);
		end
	elseif not nodeCT and nodeActor then
		DB.setValue(nodeActor, "wounds", "number", nWounds);
		DB.setValue(nodeActor, "hp.wounds", "number", nWounds);
	end
end

function notifyApplyDamage(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionDamageD20.OOB_MSGTYPE_APPLYDMG;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	local sCTNode = ActorManager.getCTNodeName(rTarget);
	if sCTNode ~= "" then
		msgOOB.sTargetNode = sCTNode;
	else
		msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	end
	msgOOB.nTargetOrder = rTarget.nOrder;
	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end

	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionHealthD20.applyDamage(rSource, rTarget, rRoll);
end

-- Backward compatibility aliases
function performRoll(...)
	return ActionDamageD20.performRoll(...);
end
function getRoll(...)
	return ActionDamageD20.getRoll(...);
end
function applyDamage(...)
	return ActionHealthD20.applyDamage(...);
end
