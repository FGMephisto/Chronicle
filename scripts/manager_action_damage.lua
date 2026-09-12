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
end

--
--	ROLL HANDLING
--

function onDamagePostGetRoll(rActor, rAction, rRoll)
	ActionDamage.applyCritMetaToRoll(rActor, rAction, rRoll);
end
-- applyCritMetaToRoll(rActor, rAction, rRoll)
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

-- onHealPreResolve(rSource, rTarget, rRoll)
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

-- handleConcentrationOnDamage(rSource, rTarget, rRoll, tApplyData)
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
-- handleExhaustionOnHeal(rSource, rTarget, rRoll, tApplyData)
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

-- handleFortitudeTraitOnDamage(rSource, rTarget, rRoll, tApplyData)
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
