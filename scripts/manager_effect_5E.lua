--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	EffectManager.registerStandardDescriptorGroups();
	EffectManagerD20.registerStandardConditionals();

	GameManager.setFunction("onEffectPreAdd", EffectManager5E.onEffectPreAdd);

	GameManager.setFunction("onActorStartTurn", EffectManager5E.onActorStartTurn);
	GameManager.setFunction("onActorEndTurn", EffectManager5E.onActorEndTurn);
end

--
--	ACTION HANDLING
--

function onEffectPreAdd(rActor, rEffect)
	if not EffectManager.onEffectPreAddDefault(rActor, rEffect) then
		return false;
	end

	if not EffectManager5E.onEffectExhuastPreAdd(rActor, rEffect) then
		return false;
	end

	return true;
end
local _bIsConsolidating = false;
function onEffectExhuastPreAdd(rActor, rEffect)
	if _bIsConsolidating then
		return true;
	end
	_bIsConsolidating = true;

	local nAdd = 0;
	local tEffectComps = {};
	for _,sComp in ipairs(EffectManager.parseEffect(rEffect.sName)) do
		local tCompData = EffectManager.parseEffectCompSimple(sComp);
		if tCompData.type:lower() == "exhaustion" then
			nAdd = nAdd + tCompData.mod;
		elseif tCompData.original:lower() == "exhaustion" then
			nAdd = nAdd + 1;
		else
			table.insert(tEffectComps, sComp);
		end
	end

	if nAdd > 0 then
		ActorManager5E.setExhaustionLevel(rActor, ActorManager5E.getExhaustionLevel(rActor) + nAdd);
	end
	_bIsConsolidating = false;

	if #tEffectComps == 0 then
		return false;
	end
	rEffect.sName = EffectManager.rebuildParsedEffect(tEffectComps);
	return true;
end

--
--	EFFECT MANAGER OVERRIDES
--

function onActorStartTurn(rActor)
	EffectManager.applyTurnChangeEffect(rActor, "REGEN", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "TEMPO", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "DMGO", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "RCHG", EffectManager5E.applyRecharge);
	EffectManager.applyTurnChangeEffect(rActor, "SAVEO", EffectManager5E.applySave);
end
function onActorEndTurn(rActor)
	EffectManager.applyTurnChangeEffect(rActor, "REGENE", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "TEMPOE", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "DMGOE", ActionHealthD20.applyOngoingHealthAdjustment);
	EffectManager.applyTurnChangeEffect(rActor, "SAVEOE", EffectManager5E.applySave);
end
function applyRecharge(rActor, tCompData)
	ActionRecharge.performRoll(nil, rActor, tCompData.sRemainder, tCompData.mod, EffectManager.isGMEffect(ActorManager.getCreatureNode(rActor), tCompData.node), tCompData.node);
end
function applySave(rActor, tCompData)
	if not rActor or not tCompData then
		return;
	end
	if (tCompData.mod or 0) == 0 then
		return;
	end

	local sSave = tCompData.sRemainder:match("^%w+");
	if (sSave or "") == "" then
		return;
	end
	sSave = DataCommon.ability_stol[sSave:upper()] or sSave;
	if not StringManager.contains(DataCommon.abilities, sSave:lower()) then
		return;
	end

	local bMagic = false;
	if tCompData.sRemainder:match("%(M%)") then
		bMagic = true;
	end

	local tSaveDesc = {};
	local sLabel = EffectVarManager.getEffectVarFromNode(tCompData.node, "sName", "");
	local tComps = EffectManager.parseEffect(sLabel);
	table.insert(tSaveDesc, string.format("[EFFECT: %s]", tComps[1] or ""));
	if bMagic then
		table.insert(tSaveDesc, "[MAGIC]");
	end

	local rRoll = ActionSave.getRoll(rActor, sSave);
	rRoll.sEffectRecord = DB.getPath(tCompData.node);
	rRoll.nTarget = tCompData.mod;
	rRoll.sSaveDesc = table.concat(tSaveDesc, " ");
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

--
--	LEGACY - 2026-04
--

function parseEffectComp(s)
	return EffectManager.parseEffectCompSimple(s);
end
function rebuildParsedEffectComp(tCompData)
	return EffectManager.rebuildParsedEffectCompSimple(tCompData);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly)
	local tData = {
		rTarget = rTarget,
		bTargetedOnly = bTargetedOnly,
	};
	return EffectManager.hasText(rActor, sEffect, tData);
end
function hasEffectCondition(rActor, sEffect, rTarget, bTargetedOnly)
	local tData = {
		rTarget = rTarget,
		bTargetedOnly = bTargetedOnly,
	};
	return EffectManager.hasText(rActor, sEffect, tData);
end
function getEffectsByType(rActor, sEffectTag, tFilter, rTarget, bTargetedOnly)
	local tData = {
		rTarget = rTarget,
		bTargetedOnly = bTargetedOnly,
		tFilter = tFilter,
	};
	return EffectManager.getCompsDataByTag(rActor, sEffectTag, tData);
end
function getEffectsBonusByType(rActor, sEffectTag, bAddEmptyBonus, tFilter, rTarget, bTargetedOnly)
	if type(sEffectTag) == "table" then
		sEffectTag = sEffectTag[1];
	end
	local tData = {
		rTarget = rTarget,
		bTargetedOnly = bTargetedOnly,
		tFilter = tFilter,
		bNoStack = not bAddEmptyBonus,
	};
	return EffectManager.getBonusData(rActor, sEffectTag, tData);
end
function getEffectsBonus(rActor, sEffectTag, bModOnly, tFilter, rTarget, bTargetedOnly)
	if type(sEffectTag) == "table" then
		sEffectTag = sEffectTag[1];
	end
	local tData = {
		rTarget = rTarget,
		bTargetedOnly = bTargetedOnly,
		tFilter = tFilter,
	};
	if bModOnly then
		return EffectManager.getBonusMod(rActor, sEffectTag, tData);
	end
	return EffectManager.getBonusDiceMod(rActor, sEffectTag, tData);
end
function removeEffectByType(rActor, sEffectTag)
	return EffectManager.removeEffectsByTag(rActor, sEffectTag);
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	local bReturn = true;

	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, DB.getPath(nodeEffect));

	for _,v in ipairs(aConditions) do
		local sLower = v:lower();
		if sLower == "healthy" then
			local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
			if nPercentWounded > 0 then
				bReturn = false;
				break;
			end
		elseif sLower == "bloodied" then
			local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
			if nPercentWounded < .5 then
				bReturn = false;
				break;
			end
		elseif sLower == "wounded" then
			local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
			if nPercentWounded == 0 then
				bReturn = false;
				break;
			end
		elseif ActionCore.isCondition(sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
				break;
			end
		else
			local sAlignCheck = sLower:match("^align%s*%(([^)]+)%)$");
			local sSizeCheck = sLower:match("^size%s*%(([^)]+)%)$");
			local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
			local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
			if sAlignCheck then
				if not ActorCommonManager.isCreatureAlignmentDnD(rActor, sAlignCheck) then
					bReturn = false;
					break;
				end
			elseif sSizeCheck then
				if not ActorCommonManager.isCreatureSizeDnD(rActor, sSizeCheck) then
					bReturn = false;
					break;
				end
			elseif sTypeCheck then
				if not ActorCommonManager.isCreatureTypeDnD(rActor, sTypeCheck) then
					bReturn = false;
					break;
				end
			elseif sCustomCheck then
				if not checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
					bReturn = false;
					break;
				end
			end
		end
	end

	table.remove(aIgnore);

	return bReturn;
end
function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end

	for _,v in ipairs(ActorEffectManager.getCombatantEffectNodes(rActor)) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 and not StringManager.contains(aIgnore, DB.getPath(v)) then
			-- Parse each effect label
			local sLabel = EffectVarManager.getEffectVarFromNode(v, "sName", "");
			local aEffectComps = EffectManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			for _,sEffectComp in ipairs(aEffectComps) do
				local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);

				-- CHECK CONDITIONALS
				if rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end

				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif rEffectComp.original:lower() == sEffect then
					if EffectManager.isTargetedEffect(v) then
						if EffectManager.isEffectTarget(v, rTarget) then
							return true;
						end
					else
						return true;
					end
				end
			end
		end
	end

	return false;
end
