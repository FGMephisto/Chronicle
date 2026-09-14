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

	ActionsManager.registerResultHandler("damage", ActionDamage.onDamage);
	GameManager.setFunction("onDamageApplyResults", ActionDamage.applyDamageResultsChronicle);
	GameManager.setFunction("onHealthApplySetHealth", ActionDamage.applySetHealthChronicle);
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

	ActionDamageD20.onRoll(rSource, rTarget, rRoll);
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

function applySetHealthChronicle(rActor, rRoll, tApplyData)
	ActionHealthD20.applySetHealthDefault(rActor, rRoll, tApplyData);

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor and tApplyData and tApplyData.tHealth and tApplyData.tHealth["hp"] then
		DB.setValue(nodeActor, "hp.wounds", "number", tApplyData.tHealth["hp"].nWounds);
	end
end

-- Backward compatibility aliases
function performRoll(...)
	return ActionDamageD20.performRoll(...);
end
function getRoll(...)
	return ActionDamageD20.getRoll(...);
end
function notifyApplyDamage(...)
	return ActionDamageD20.notifyApplyDamage(...);
end
function applyDamage(...)
	return ActionHealthD20.applyDamage(...);
end
