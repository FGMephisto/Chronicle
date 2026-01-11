--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("heal", ActionHeal.modHeal);
	ActionsManager.registerResultHandler("heal", ActionHeal.onHeal);
end

function getRoll(_, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	-- Build description
	rRoll.sDesc = ActionHealCore.encodeActionText(rAction);

	-- Save the heal clauses in the roll structure
	rRoll.clauses = rAction.clauses;

	-- Add heal type to roll data
	if rAction.subtype == "temp" then
		rRoll.healtype = "temp";
	else
		rRoll.healtype = "health";
	end

	-- Add the dice and modifiers, and encode ability scores used
	for _,vClause in pairs(rRoll.clauses) do
		DiceRollManager.addHealDice(rRoll.aDice, vClause.dice, { healtype = rRoll.healtype });
		rRoll.nMod = rRoll.nMod + vClause.modifier;
		local sAbility = DataCommon.ability_ltos[vClause.stat];
		if sAbility then
			rRoll.sDesc = rRoll.sDesc .. string.format(" [MOD: %s (%s)]", sAbility, vClause.statmult or 1);
		end
	end

	-- Encode the damage types
	ActionHeal.encodeHealClauses(rRoll);

	-- Handle temporary hit points
	if rAction.subtype == "temp" then
		rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
	end

	-- Handle self-targeting
	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end

	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionHeal.getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modHeal(rSource, _, rRoll)
	ActionHeal.decodeHealClauses(rRoll);
	CombatManager2.addRightClickDiceToClauses(rRoll);

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Track how many heal clauses before effects applied
	local nPreEffectClauses = #(rRoll.clauses);

	if rSource then
		local bEffects = false;

		-- Apply general heal modifiers
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"HEAL"});
		if (nEffectCount > 0) then
			bEffects = true;
		end

		-- Apply ability modifiers
		for sAbility, sAbilityMult in rRoll.sDesc:gmatch("%[MOD: (%w+) %((%w+)%)%]") do
			local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, DataCommon.ability_stol[sAbility]);
			if nBonusEffects > 0 then
				bEffects = true;
				local nMult = tonumber(sAbilityMult) or 1;
				if nBonusStat > 0 and nMult ~= 1 then
					nBonusStat = math.floor(nMult * nBonusStat);
				end
				nAddMod = nAddMod + nBonusStat;
			end
		end

		-- If effects happened, then add note
		if bEffects then
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
		end
	end

	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
	DiceRollManager.addHealDice(rRoll.aDice, aAddDice, { iconcolor = "FF00FF", healtype = rRoll.healtype });
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Handle fixed damage option
	if not ActorManager.isPC(rSource) and OptionsManager.isOption("NPCD", "fixed") then
		local aFixedClauses = {};
		local aFixedDice = {};
		local nFixedPositiveCount = 0;
		local nFixedNegativeCount = 0;
		local nFixedMod = 0;

		for kClause,vClause in ipairs(rRoll.clauses) do
			if kClause <= nPreEffectClauses then
				local nClauseFixedMod = 0;
				for _,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						nFixedNegativeCount = nFixedNegativeCount + 1;
						nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
						if nFixedNegativeCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod - 1;
						end
					else
						nFixedPositiveCount = nFixedPositiveCount + 1;
						nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
						if nFixedPositiveCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod + 1;
						end
					end
					vClause.dice = {};
					vClause.modifier = vClause.modifier + nClauseFixedMod;
				end
				nFixedMod = nFixedMod + nClauseFixedMod;
			else
				for _,vDie in ipairs(vClause.dice) do
					table.insert(aFixedDice, vDie);
				end
			end

			table.insert(aFixedClauses, vClause);
		end

		rRoll.clauses = aFixedClauses;
		rRoll.aDice = aFixedDice;
		rRoll.nMod = rRoll.nMod + nFixedMod;
	end
end

function onHeal(rSource, rTarget, rRoll)
	ActionsManager2.handleHealerFeat(rSource, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");
	Comm.deliverChatMessage(rMessage);

	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.sDesc = rMessage.text;
	ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll);
end

--
-- UTILITY FUNCTIONS
--

function encodeHealClauses(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
		rRoll.sDesc = rRoll.sDesc .. string.format(" [CLAUSE: (%s) (%s) (%s)]", sDice, vClause.stat or "", vClause.statmult or 1);
	end
end

function decodeHealClauses(rRoll)
	-- Process each type clause in the damage description
	rRoll.clauses = {};
	for sDice, sStat, sStatMult in rRoll.sDesc:gmatch("%[CLAUSE: %(([^)]*)%) %(([^)]*)%) %(([^)]*)%)]") do
		local rClause = {};
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDice);
		rClause.stat = sStat;
		rClause.statmult = tonumber(sStatMult) or 1;

		table.insert(rRoll.clauses, rClause);
	end

	-- Remove heal clause information from roll description
	rRoll.sDesc = rRoll.sDesc:gsub(" %[CLAUSE:[^]]*%]", "");
end
