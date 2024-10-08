-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("check", modRoll);
	ActionsManager.registerResultHandler("check", onRoll);
end

function performPartySheetRoll(draginfo, rActor, sCheck)
	local rRoll = getRoll(rActor, sCheck);
	
	local nTargetDC = DB.getValue("partysheet.checkdc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performRoll(draginfo, rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = getRoll(rActor, sCheck, nTargetDC, bSecretRoll);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sCheck, nTargetDC, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "check";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getCheck(rActor, sCheck:lower());
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[CHECK]";
	rRoll.sDesc = rRoll.sDesc .. " " .. StringManager.capitalizeAll(sCheck);
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	rRoll.bSecret = bSecretRoll;

	rRoll.nTarget = nTargetDC;
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	if rSource then
		local bEffects = false;

		-- Get ability used
		local sActionStat = nil;
		local sAbility = rRoll.sDesc:match("%[CHECK%] (%w+)");
		if not sAbility then
			local sSkill = rRoll.sDesc:match("%[SKILL%] (%w+)");
			if sSkill then
				sAbility = rRoll.sDesc:match("%[MOD:(%w+)%]");
				if sAbility then
					sAbility = DataCommon.ability_stol[sAbility];
				else
					for k, v in pairs(DataCommon.skilldata) do
						if k == sSkill then
							sAbility = v.stat;
						end
					end
				end
			end
		end
		if sAbility then
			sAbility = sAbility:lower();
		end

		-- Build filter
		local aCheckFilter = {};
		if sAbility then
			table.insert(aCheckFilter, sAbility);
		end

		-- Get roll effect modifiers
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"CHECK"}, false, aCheckFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager5E.hasEffectCondition(rSource, "ADVCHK") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVCHK", aCheckFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISCHK") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISCHK", aCheckFilter)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bDIS = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bDIS = true;
			bEffects = true;
		end
		if StringManager.contains({ "strength", "dexterity", "constitution" }, sAbility) then
			if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
				bEffects = true;
				bDIS = true;
			end
		end

		-- Get ability modifiers
		local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, sAbility);
		if nBonusEffects > 0 then
			bEffects = true;
			nAddMod = nAddMod + nBonusStat;
		end
		
		-- Get exhaustion modifiers
		local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		local sOptionGAVE = OptionsManager.getOption("GAVE");
		local bIs2024 = (sOptionGAVE == "2024");
		if bIs2024 then
			if nExhaustMod > 0 then
				bEffects = true;
				nAddMod = nAddMod - (2 * nExhaustMod);
			end
		else
			if nExhaustMod > 0 then
				bEffects = true;
				bDIS = true;
			end		
		end
		
		-- Check Reliable state
		local bReliable = false;
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
			bEffects = true;
			bReliable = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLECHK") then
			bEffects = true;
			bReliable = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLECHK", aCheckFilter)) > 0 then
			bEffects = true;
			bReliable = true;
		end
		if bReliable then
			table.insert(aAddDesc, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
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
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
	
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);

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
end
