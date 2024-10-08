-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";
OOB_MSGTYPE_APPLYSS = "applyss";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSAVE, handleApplySave);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCONC, handleApplyConc);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSS, handleApplySystemShock);

	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerResultHandler("save", onSave);

	ActionsManager.registerModHandler("death", modSave);
	ActionsManager.registerResultHandler("death", onDeathRoll);
	ActionsManager.registerModHandler("death_auto", modSave);
	ActionsManager.registerResultHandler("death_auto", onDeathRoll);

	ActionsManager.registerModHandler("concentration", modSave);
	ActionsManager.registerResultHandler("concentration", onConcentrationRoll);

	ActionsManager.registerModHandler("systemshock", modSave);
	ActionsManager.registerResultHandler("systemshock", onSystemShockRoll);
	ActionsManager.registerResultHandler("systemshockresult", onSystemShockResultRoll);
end

function handleApplySave(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rOrigin = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	rAction.sResult = msgOOB.sResult;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
	
	applySave(rSource, rOrigin, rAction);
end
function notifyApplySave(rSource, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVE;
	
	if rRoll.bTower then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sResult = rRoll.sResult;
	if rRoll.bRemoveOnMiss then
		msgOOB.nRemoveOnMiss = 1;
	end

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rRoll.sSource ~= "" then
		msgOOB.sTargetNode = rRoll.sSource;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function performPartySheetRoll(draginfo, rActor, sSave)
	local rRoll = getRoll(rActor, sSave);
	
	local nTargetDC = DB.getValue("partysheet.savedc", 0);
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
function performVsRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
	local rRoll = getRoll(rActor, sSave);
	
	if bSecretRoll then
		rRoll.bSecret = true;
	end
	rRoll.nTarget = nTargetDC;
	local nTotal, nEffectCount = EffectManager5E.getEffectsBonus(rSource, "SAVEDC", true, {}, rActor, false)
	if nEffectCount > 0 then
		rRoll.nTarget = rRoll.nTarget + nTotal;
	end
	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performRoll(draginfo, rActor, sSave)
	local rRoll = getRoll(rActor, sSave);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function getRoll(rActor, sSave)
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, sSave);
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[SAVE] " .. StringManager.capitalizeAll(sSave);
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	
	return rRoll;
end

function modSave(rSource, rTarget, rRoll)
	local bAutoFail = false;

	local sSave = nil;
	if rRoll.sDesc:match("%[DEATH%]") then
		sSave = "death";
	elseif rRoll.sDesc:match("%[CONCENTRATION%]") then
		sSave = "concentration";
	elseif rRoll.sDesc:match("%[SYSTEM SHOCK%]") then
		sSave = "systemshock";
	else
		sSave = rRoll.sDesc:match("%[SAVE%] (%w+)");
		if sSave then
			sSave = sSave:lower();
		end
	end

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

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	local nCover = 0;
	if sSave == "dexterity" then
		if rRoll.sSaveDesc then
			nCover = tonumber(rRoll.sSaveDesc:match("%[COVER %-(%d)%]")) or 0;
		else
			if ModifierManager.getKey("DEF_SCOVER") then
				nCover = 5;
			elseif ModifierManager.getKey("DEF_COVER") then
				nCover = 2;
			end
		end
	end
	
	if rSource then
		local nodeActor = ActorManager.getCreatureNode(rSource);
		local bEffects = false;

		-- Build filter
		local aSaveFilter = {};
		if sSave then
			table.insert(aSaveFilter, sSave);
		end

		-- Get effect modifiers
		local rSaveSource = nil;
		if rRoll.sSource then
			rSaveSource = ActorManager.resolveActor(rRoll.sSource);
		end
		local aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter, rSaveSource);
		if nEffectCount > 0 then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if EffectManager5E.hasEffect(rSource, "ADVSAV", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVSAV", aSaveFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "ADVDEATH") then
			bADV = true;
			bEffects = true;
		elseif sSave == "concentration" and EffectManager5E.hasEffect(rSource, "ADVCONC") then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffect(rSource, "DISSAV", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISSAV", aSaveFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		elseif sSave == "dexterity" and EffectManager5E.hasEffectCondition(rSource, "Restrained") then
			bDIS = true;
			bEffects = true;
		elseif sSave == "death" and EffectManager5E.hasEffect(rSource, "DISDEATH") then
			bDIS = true;
			bEffects = true;
		elseif sSave == "concentration" and EffectManager5E.hasEffect(rSource, "DISCONC") then
			bDIS = true;
			bEffects = true;
		end
		if sSave == "dexterity" then
			if nCover < 5 then
				if EffectManager5E.hasEffect(rSource, "SCOVER", rTarget) then
					nCover = 5;
					bEffects = true;
				elseif nCover < 2 then
					if EffectManager5E.hasEffect(rSource, "COVER", rTarget) then
						nCover = 2;
						bEffects = true;
					end
				end
			end
		end
		local bFrozen = EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
				EffectManager5E.hasEffectCondition(rSource, "Petrified") or
				EffectManager5E.hasEffectCondition(rSource, "Stunned") or
				EffectManager5E.hasEffectCondition(rSource, "Unconscious");
		if bFrozen and StringManager.contains({ "strength", "dexterity" }, sSave) then
			bAutoFail = true;
			bEffects = true;
		end
		if StringManager.contains({ "strength", "dexterity", "constitution", "concentration", "systemshock" }, sSave) then
			if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
				bEffects = true;
				bDIS = true;
			end
		end
		if sSave == "dexterity" and EffectManager5E.hasEffectCondition(rSource, "Dodge") and 
				not (bFrozen or 
					EffectManager5E.hasEffectCondition(rSource, "Grappled") or
					EffectManager5E.hasEffectCondition(rSource, "Restrained")) then
			bEffects = true;
			bADV = true;
		end
		if rRoll.sSaveDesc then
			if rRoll.sSaveDesc:match("%[MAGIC%]") then
				local bMagicResistance = false;
				if EffectManager5E.hasEffectCondition(rSource, "Magic Resistance") then
					bMagicResistance = true;
				elseif StringManager.contains({ "intelligence", "wisdom", "charisma" }, sSave) then
					if EffectManager5E.hasEffectCondition(rSource, "Gnome Cunning") then
						bMagicResistance = true;
					else
						if ActorManager.isPC(rSource) and CharManager.hasTrait(nodeActor, CharManager.TRAIT_GNOME_CUNNING) then
							bMagicResistance = true;
						end
					end
				end
				if bMagicResistance then
					bEffects = true;
					bADV = true;
				end
			end
		end

		-- Get ability modifiers
		local sSaveAbility = nil;
		if sSave == "concentration" or sSave == "systemshock" then
			sSaveAbility = "constitution";
		elseif sSave ~= "death" then
			sSaveAbility = sSave;
		end
		if sSaveAbility then
			local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, sSaveAbility);
			if nBonusEffects > 0 then
				bEffects = true;
				nAddMod = nAddMod + nBonusStat;
			end
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
			if nExhaustMod > 2 then
				bEffects = true;
				bDIS = true;
			end		
		end

		-- Handle War Caster feat
		if sSave == "concentration" and ActorManager.isPC(rSource) then
			if CharManager.hasFeat(nodeActor, CharManager.FEAT_WAR_CASTER) then
				bADV = true;
				rRoll.sDesc = rRoll.sDesc .. string.format("[%s]", Interface.getString("roll_msg_feature_warcaster"));
			elseif CharManager.hasFeature(nodeActor, CharManager.FEATURE_ELDRITCH_INVOCATION_ELDRITCH_MIND) then
				bADV = true;
				rRoll.sDesc = rRoll.sDesc .. string.format("[%s]", Interface.getString("roll_msg_feature_eldritchinvocationeldritchmind"));
			end
		end
		
		-- Check Reliable state
		local bReliable = false;
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
			bEffects = true;
			bReliable = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLESAV") then
			bEffects = true;
			bReliable = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLESAV", aSaveFilter)) > 0 then
			bEffects = true;
			bReliable = true;
		elseif (sSave == "concentration") and EffectManager5E.hasEffectCondition(rSource, "RELIABLECONC") then
			bEffects = true;
			bReliable = true;
		elseif (sSave == "death") and EffectManager5E.hasEffectCondition(rSource, "RELIABLEDEATH") then
			bEffects = true;
			bReliable = true;
		end
		if bReliable then
			table.insert(aAddDesc, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
		end

		-- If effects apply, then add note
		if bEffects then
			for _, vDie in ipairs(aAddDice) do
				if vDie:sub(1,1) == "-" then
					table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
				else
					table.insert(rRoll.aDice, "p" .. vDie:sub(2));
				end
			end
			rRoll.nMod = rRoll.nMod + nAddMod;
			
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, EffectManager.buildEffectOutput(sMod));
		end
	end
	
	if rRoll.sSaveDesc then
		local sEffectsTag = Interface.getString("effects_tag");
		local sDCEffect = rRoll.sSaveDesc:match("%[" .. sEffectsTag .. " ([+-]?%d+)%]")
		if sDCEffect then
			local sDC = string.format(" [DC %s %s]", sEffectsTag, sDCEffect);
			rRoll.sDesc = rRoll.sDesc .. sDC;
		elseif rRoll.sSaveDesc:match("%[" .. sEffectsTag .. "%]") then
			local sDC = string.format(" [DC %s]", sEffectsTag);
			rRoll.sDesc = rRoll.sDesc .. sDC;
		end
	end

	if nCover > 0 then
		rRoll.nMod = rRoll.nMod + nCover;
		rRoll.sDesc = rRoll.sDesc .. string.format(" [COVER +%d]", nCover);
	end
	
	ActionsManager2.encodeDesktopMods(rRoll);
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
	
	if bAutoFail then
		rRoll.sDesc = rRoll.sDesc .. " [AUTOFAIL]";
	end
end
function onSave(rSource, rTarget, rRoll)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		notifyApplySave(rSource, rRoll);
	end
end

function applySave(rSource, rOrigin, rAction, sUser)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Save";
	msgLong.text = "Save [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	if rOrigin then
		msgShort.text = msgShort.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
		msgLong.text = msgLong.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local sAttack = "";
	local bHalfMatch = false;
	if rAction.sSaveDesc then
		sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
		bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
	end
	rAction.sResult = "";
	
	if rAction.nTarget > 0 then
		if rAction.nTotal >= rAction.nTarget then
			msgLong.text = msgLong.text .. " [SUCCESS]";
			
			if rSource then
				local bHalfDamage = bHalfMatch;
				local bAvoidDamage = false;
				if bHalfDamage then
					if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
						bAvoidDamage = true;
						msgLong.text = msgLong.text .. " [AVOIDANCE]";
					else
						local bEvasion = EffectManager5E.hasEffectCondition(rSource, "Evasion");
						if not bEvasion and ActorManager.isPC(rSource) then
							local nodeActor = ActorManager.getCreatureNode(rActor);
							if CharManager.hasFeature(nodeActor, CharManager.FEATURE_EVASION) then
								bEvasion = true;
							end
						end
						if bEvasion then
							local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
							if sSave then
								sSave = sSave:lower();
							end
							if sSave == "dexterity" then
								bAvoidDamage = true;
								msgLong.text = msgLong.text .. " [EVASION]";
							end
						end
					end
				end
				
				if bAvoidDamage then
					rAction.sResult = "none";
					rAction.bRemoveOnMiss = false;
				elseif bHalfDamage then
					rAction.sResult = "half_success";
					rAction.bRemoveOnMiss = false;
				end
				
				if rOrigin and rAction.bRemoveOnMiss then
					TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
				end
			end
		else
			msgLong.text = msgLong.text .. " [FAILURE]";

			if rSource then
				local bHalfDamage = false;
				if bHalfMatch then
					if EffectManager5E.hasEffectCondition(rSource, "Avoidance") then
						bHalfDamage = true;
						msgLong.text = msgLong.text .. " [AVOIDANCE]";
					elseif EffectManager5E.hasEffectCondition(rSource, "Evasion") then
						local sSave = rAction.sDesc:match("%[SAVE%] (%w+)");
						if sSave then
							sSave = sSave:lower();
						end
						if sSave == "dexterity" then
							bHalfDamage = true;
							msgLong.text = msgLong.text .. " [EVASION]";
						end
					end
				end
				
				if bHalfDamage then
					rAction.sResult = "half_failure";
				end
			end
		end
	end
	
	ActionsManager.outputResult(rAction.bSecret, rSource, rOrigin, msgLong, msgShort);
	
	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end

--
-- System shock saving throw
--

function performSystemShockRoll(draginfo, rActor)
	local rRoll = { };
	rRoll.sType = "systemshock";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[SYSTEM SHOCK]";
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	
	rRoll.bSecret = not ActorManager.isFaction(rActor, "friend");
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onSystemShockRoll(rSource, rTarget, rRoll)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	notifyApplySystemShock(rSource, rMessage.secret, rRoll);
end

function notifyApplySystemShock(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSS;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.nTarget = rRoll.nTarget;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplySystemShock(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	
	applySystemShockRoll(rSource, rAction);
end
function applySystemShockRoll(rSource, rAction)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "System Shock";
	msgLong.text = "System Shock [" .. rAction.nTotal ..  "]";
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local bAutoFail = rAction.sDesc:match("%[AUTOFAIL%]");
	local bSuccess = (not bAutoFail and (rAction.nTotal >= 15));
	if bSuccess then
		msgLong.text = msgLong.text .. " [SUCCESS]";
	else
		msgLong.text = msgLong.text .. " [FAILURE]";
	end
	
	ActionsManager.outputResult(rAction.bSecret, rSource, nil, msgLong, msgShort);
	
	-- On failed system shock check, roll for system shock
	if not bSuccess then
		local rRoll = { 
			sType = "systemshockresult",
			sDesc = "[SYSTEM SHOCK RESULT]",
			nMod = 0,
			bSecret = rAction.bSecret,
		};
		rRoll.aDice = DiceRollManager.getActorDice({ "d10" }, rActor);
		ActionsManager.performAction(nil, rSource, rRoll);
	end
end

function onSystemShockResultRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rSource);
	if not nodeActor then
		return;
	end
	local nodeCT = ActorManager.getCTNode(rSource)
	local nTotal = ActionsManager.total(rRoll);
	
	if (nTotal <= 1) then
		if sNodeType == "pc" then
			DB.setValue(nodeActor, "hp.wounds", "number", DB.getValue(nodeActor, "hp.total", 0));
		else
			DB.setValue(nodeActor, "wounds", "number", DB.getValue(nodeActor, "hptotal", 0));
		end
		EffectManager.removeCondition(rSource, "Stable");
		EffectManager.addCondition(rSource, "Unconscious");
		EffectManager.addCondition(rSource, "Prone");
		rMessage.text = rMessage.text .. " -> [DROPPED TO ZERO]";
		
	elseif ((nTotal == 2) or (nTotal == 3)) then
		if sNodeType == "pc" then
			DB.setValue(nodeActor, "hp.wounds", "number", DB.getValue(nodeActor, "hp.total", 0));
		else
			DB.setValue(nodeActor, "wounds", "number", DB.getValue(nodeActor, "hptotal", 0));
		end
		EffectManager.addCondition(rSource, "Stable");
		EffectManager.addCondition(rSource, "Unconscious");
		EffectManager.addCondition(rSource, "Prone");
		rMessage.text = rMessage.text .. " -> [DROPPED TO ZERO, BUT STABLE]";
		
	elseif ((nTotal == 4) or (nTotal == 5)) then
		local aEffect = { sName = "System shock; Stunned", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			aEffect.nGMOnly = 1;
		end
		EffectManager.addEffect("", "", nodeCT, aEffect, true);
		rMessage.text = rMessage.text .. " -> [STUNNED]";
		
	elseif ((nTotal == 6) or (nTotal == 7)) then
		local aEffect = { sName = "System shock; NOTE: No reactions; DISATK; DISCHK", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			aEffect.nGMOnly = 1;
		end
		EffectManager.addEffect("", "", nodeCT, aEffect, true);
		rMessage.text = rMessage.text .. " -> [NO REACTIONS, AND DISADVANTAGE]";
		
	else -- if (nTotal >= 8) then
		local aEffect = { sName = "System shock; NOTE: No reactions", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			aEffect.nGMOnly = 1;
		end
		EffectManager.addEffect("", "", nodeCT, aEffect, true);
		rMessage.text = rMessage.text .. " -> [NO REACTIONS]";
	end
	
	Comm.deliverChatMessage(rMessage);
end

--
--  Death saving throw
--

function performDeathRoll(draginfo, rActor, bAuto)
	local rRoll = { };
	if bAuto then
		rRoll.sType = "death_auto";
	else
		rRoll.sType = "death";
	end
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[DEATH]";
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onDeathRoll(rSource, rTarget, rRoll)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if ActorHealthManager.getWoundPercent(rSource) >= 1 then
		local nTotal = ActionsManager.total(rRoll);
		
		local bStatusCheck = true;
		local sOriginalStatus = ActorHealthManager.getHealthStatus(rSource);
		
		local sSuccessField, sFailField;
		local sSourceNodeType, nodeSource = ActorManager.getTypeAndNode(rSource);
		if not nodeSource then
			return;
		end
		if sSourceNodeType == "pc" then
			sSuccessField = "hp.deathsavesuccess";
			sFailField = "hp.deathsavefail";
		elseif sSourceNodeType == "ct" then
			sSuccessField = "deathsavesuccess";
			sFailField = "deathsavefail";
		else
			return;
		end

		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		if nFirstDie == 1 then
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
			
			if nodeSource then
				local nValue = DB.getValue(nodeSource, sFailField, 0);
				if nValue < 3 then
					nValue = math.min(nValue + 2, 3);
					DB.setValue(nodeSource, sFailField, "number", nValue);
				end
			end
		elseif nFirstDie == 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
			
			ActionDamage.applyDamage(nil, rSource, { bSecret = rRoll.bSecret, sType = "heal", sDesc = "[HEAL]", nTotal = 1 });
			bStatusCheck = false;
		elseif nTotal >= 10 then
			rMessage.text = rMessage.text .. " [SUCCESS]";

			if nodeSource then
				local nValue = DB.getValue(nodeSource, sSuccessField, 0);
				if nValue < 3 then
					nValue = nValue + 1;
					DB.setValue(nodeSource, sSuccessField, "number", nValue);
				end
				if nValue >= 3 then
					EffectManager.addCondition(rSource, "Stable");
				end
			end
		else
			rMessage.text = rMessage.text .. " [FAILURE]";

			if nodeSource then
				local nValue = DB.getValue(nodeSource, sFailField, 0);
				if nValue < 3 then
					DB.setValue(nodeSource, sFailField, "number", nValue + 1);
				end
			end
		end
		
		if bStatusCheck then
			local bShowStatus = false;
			if ActorManager.isFaction(rSource, "friend") then
				bShowStatus = not OptionsManager.isOption("SHPC", "off");
			else
				bShowStatus = not OptionsManager.isOption("SHNPC", "off");
			end
			if bShowStatus then
				local sNewStatus = ActorHealthManager.getHealthStatus(rSource);
				if sOriginalStatus ~= sNewStatus then
					rMessage.text = rMessage.text .. string.format("[%s: %s]", Interface.getString("combat_tag_status"), sNewStatus);
				end
			end
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end

--
--  Concentration saving throw
--

function hasConcentrationEffects(rSource)
	return #(getConcentrationEffects(rSource)) > 0;
end
function getConcentrationEffects(rSource)
	local aEffects = {};
	
	local nodeCTSource = ActorManager.getCTNode(rSource);
	if nodeCTSource then
		local sCTNodeSource = DB.getPath(nodeCTSource);
		for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
			local sCTNode = DB.getPath(nodeCT);
			for _,nodeEffect in ipairs(DB.getChildList(nodeCT, "effects")) do
				local bSourceMatch = false;
				local sEffectCTSource = DB.getValue(nodeEffect, "source_name", "");
				if sEffectCTSource == sCTNodeSource then
					bSourceMatch = true;
				elseif (sCTNode == sCTNodeSource) and (sEffectCTSource == "") then
					bSourceMatch = true;
				end
				if bSourceMatch then
					if DB.getValue(nodeEffect, "label", ""):match("%([cC]%)") then
						table.insert(aEffects, { nodeCT = nodeCT, nodeEffect = nodeEffect });
					end
				end
			end
		end
	end
	
	return aEffects;
end

function handleApplyConc(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	
	applyConcentrationRoll(rSource, rAction);
end
function notifyApplyConc(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYCONC;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.nTarget = rRoll.nTarget;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

function performConcentrationRoll(draginfo, rActor, nTargetDC, tData)
	local rRoll = { };
	rRoll.sType = "concentration";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	rRoll.nMod = nMod;
	
	rRoll.sDesc = "[CONCENTRATION]";
	if (sAddText or "") ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if (tData.sAddText or "") ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. tData.sAddText;
	end
	if bADV and (not tData or not tData.bDIS) then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS or (not bADV and tData and tData.bDIS) then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	rRoll.nTarget = nTargetDC;
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onConcentrationRoll(rSource, rTarget, rRoll)
	ActionsManager2.handleLuckTrait(rSource, rRoll);
	ActionsManager2.decodeAdvantage(rRoll);
	ActionsManager2.handleReliable(rSource, rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	if Session.IsHost and ActorManager.isPC(rSource) then
		rMessage.secret = nil;
	end
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		notifyApplyConc(rSource, rMessage.secret, rRoll);
	end
end

function applyConcentrationRoll(rSource, rAction)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Concentration";
	msgLong.text = "Concentration [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	if rAction.nTotal >= rAction.nTarget then
		msgLong.text = msgLong.text .. " [SUCCESS]";
	else
		msgLong.text = msgLong.text .. " [FAILURE]";
	end
	
	local bSecret = rAction.bSecret;
	if Session.IsHost and ActorManager.isPC(rSource) then
		bSecret = nil;
	end
	ActionsManager.outputResult(bSecret, rSource, nil, msgLong, msgShort);
	
	-- On failed concentration check, remove all effects with the same source creature
	if rAction.nTotal < rAction.nTarget then
		expireConcentrationEffects(rSource);
	end
end
function expireConcentrationEffects(rSource)
	local aSourceConcentrationEffects = getConcentrationEffects(rSource);
	for _,v in ipairs(aSourceConcentrationEffects) do
		EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
	end
end
