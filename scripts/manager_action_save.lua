--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";
OOB_MSGTYPE_APPLYSS = "applyss";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYSAVE, ActionSave.handleApplySave);
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYCONC, ActionSave.handleApplyConc);
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYSS, ActionSave.handleApplySystemShock);

	ActionsManager.registerModHandler("save", ActionSave.modSave);
	ActionsManager.registerResultHandler("save", ActionSave.onSave);

	ActionsManager.registerModHandler("death", ActionSave.modSave);
	ActionsManager.registerResultHandler("death", ActionSave.onDeathRoll);
	ActionsManager.registerModHandler("death_auto", ActionSave.modSave);
	ActionsManager.registerResultHandler("death_auto", ActionSave.onDeathRoll);

	ActionsManager.registerModHandler("concentration", ActionSave.modSave);
	ActionsManager.registerResultHandler("concentration", ActionSave.onConcentrationRoll);

	ActionsManager.registerModHandler("systemshock", ActionSave.modSave);
	ActionsManager.registerResultHandler("systemshock", ActionSave.onSystemShockRoll);
	ActionsManager.registerResultHandler("systemshockresult", ActionSave.onSystemShockResultRoll);
end

function handleApplySave(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rOrigin = ActorManager.resolveActor(msgOOB.sTargetNode);

	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.bTower = (tonumber(msgOOB.nTower) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSave = msgOOB.sSave;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	rAction.sResult = msgOOB.sResult;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);

	ActionSave.applySave(rSource, rOrigin, rAction);
end
function notifyApplySave(rSource, rRoll)
	local msgOOB = {};
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYSAVE;

	msgOOB.nSecret = rRoll.bSecret and 1 or 0;
	msgOOB.nTower = rRoll.bTower and 1 or 0;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSave = rRoll.sSave;
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sResult = rRoll.sResult;
	msgOOB.nRemoveOnMiss = rRoll.bRemoveOnMiss and 1 or 0;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rRoll.sSource ~= "" then
		msgOOB.sTargetNode = rRoll.sSource;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function getRoll(rActor, sSave)
	local rRoll = ActionsManager2.setupD20RollBuild("save", rActor);
	ActionSave.setupRollBuild(rRoll, rActor, sSave);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, sSave)
	local rRoll = ActionSave.getRoll(rActor, sSave);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetRoll(draginfo, rActor, sSave)
	local rRoll = ActionSave.getRoll(rActor, sSave);

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
	local rRoll = ActionSave.getRoll(rActor, sSave);

	if bSecretRoll then
		rRoll.bSecret = true;
	end
	rRoll.nTarget = nTargetDC;
	local nTotal, nEffectCount = EffectManager5E.getEffectsBonus(rSource, "SAVEDC", true, {}, rActor, false)
	if nEffectCount > 0 then
		rRoll.nTarget = rRoll.nTarget + nTotal;
	end
	rRoll.bRemoveOnMiss = bRemoveOnMiss;
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
	if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modSave(rSource, rTarget, rRoll)
	ActionsManager2.setupD20RollMod(rRoll);
	ActionSave.setupRollMod(rRoll);
	ActionSave.applyEffectsToRollMod(rRoll, rSource, rTarget);
	ActionsManager2.finalizeEffectsToD20RollMod(rRoll);
	ActionSave.finalizeRollMod(rRoll);
	ActionsManager2.finalizeD20RollMod(rRoll);
end

function onSave(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		ActionSave.notifyApplySave(rSource, rRoll);
	end
end

function applySave(rSource, rOrigin, rAction, _)
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
		local bAvoidance = false;
		local bEvasion = false;
		if bHalfMatch then
			if ActorManager5E.hasRollFeature(rSource, "Avoidance") then
				bAvoidance = true;
				msgLong.text = msgLong.text .. " [AVOIDANCE]";
			elseif (rAction.sSave == "dexterity") and ActorManager5E.hasRollFeature(rSource, "Evasion") then
				bEvasion = true;
				msgLong.text = msgLong.text .. " [EVASION]";
			end
		end

		if rAction.nTotal >= rAction.nTarget then
			msgLong.text = msgLong.text .. " [SUCCESS]";

			if rSource then
				if bAvoidance or bEvasion then
					rAction.sResult = "none";
					rAction.bRemoveOnMiss = false;
				elseif bHalfMatch then
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
				if bAvoidance or bEvasion then
					rAction.sResult = "half_failure";
				end
			end
		end
	end

	ActionsManager.outputResult(rAction.bTower, rSource, rOrigin, msgLong, msgShort);

	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end

--
--	MOD ROLL HELPERS
--

function setupRollBuild(rRoll, rActor, sSave)
	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getSave(rActor, sSave);
	table.insert(rRoll.tNotifications, "[SAVE]");
	table.insert(rRoll.tNotifications, StringManager.capitalizeAll(sSave));
	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end
end
function setupRollBuildSystemShock(rRoll, rActor)
	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	table.insert(rRoll.tNotifications, "[SYSTEM SHOCK]");
	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end

	rRoll.bSecret = not ActorManager.isFaction(rActor, "friend");
end
function setupRollBuildDeath(rRoll, _)
	table.insert(rRoll.tNotifications, "[DEATH]");
end
function setupRollBuildConcentration(rRoll, rActor, nTargetDC, tData)
	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	table.insert(rRoll.tNotifications, "[CONCENTRATION]");
	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end
	if tData then
		if tData.bADV then
			rRoll.bADV = true;
		end
		if tData.bDIS then
			rRoll.bDIS = true;
		end
		if (tData.sAddText or "") ~= "" then
			table.insert(rRoll.tNotifications, tData.sAddText);
		end
	end

	rRoll.nTarget = nTargetDC;
end

function setupRollMod(rRoll)
	if rRoll.sType == "save" then
		rRoll.sSave = rRoll.sDesc:match("%[SAVE%] (%w+)");
		if rRoll.sSave then
			rRoll.sSave = rRoll.sSave:lower();
		end
		rRoll.sAbility = rRoll.sSave;

		-- Check cover for dexterity saves
		if rRoll.sSave == "dexterity" then
			rRoll.bCover = ModifierManager.getKey("DEF_COVER");
			rRoll.bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");
		end
	elseif rRoll.sType == "concentration" then
		rRoll.sSave = "concentration";
		rRoll.sAbility = "constitution";
	elseif rRoll.sType == "systemshock" then
		rRoll.sSave = "systemshock";
		rRoll.sAbility = "constitution";
	elseif StringManager.contains({ "death", "death_auto", }, rRoll.sType) then
		rRoll.sSave = "death";
	end

	-- Build save filter
	rRoll.tSaveFilter = {};
	if rRoll.sSave then
		table.insert(rRoll.tSaveFilter, rRoll.sSave);
	end
end
function applyEffectsToRollMod(rRoll, rSource, rTarget)
	ActionsManager2.applyAbilityEffectsToD20RollMod(rRoll, rSource, rTarget);
	ActionSave.applyStandardEffectsToRollMod(rRoll, rSource, rTarget);
	ActionSave.applyExhaustionEffectsToRollMod(rRoll, rSource, rTarget);
	ActionSave.applyReliableEffectsToRollMod(rRoll, rSource, rTarget);
end
function applyStandardEffectsToRollMod(rRoll, rSource, rTarget)
	if not rSource then
		return;
	end

	local bFrozen = EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
			EffectManager5E.hasEffectCondition(rSource, "Petrified") or
			EffectManager5E.hasEffectCondition(rSource, "Stunned") or
			EffectManager5E.hasEffectCondition(rSource, "Unconscious");

	-- Get roll effect modifiers
	local rSaveSource = nil;
	if rRoll.sSource then
		rSaveSource = ActorManager.resolveActor(rRoll.sSource);
	end
	local tSaveDice, nSaveMod, nSaveEffect = EffectManager5E.getEffectsBonus(rSource, {"SAVE"}, false, rRoll.tSaveFilter, rSaveSource);
	if (nSaveEffect > 0) then
		rRoll.bEffects = true;
		for _,vDie in ipairs(tSaveDice) do
			table.insert(rRoll.tEffectDice, vDie);
		end
		rRoll.nEffectMod = rRoll.nEffectMod + nSaveMod;
	end

	-- Get condition modifiers
	if bFrozen and StringManager.contains({ "strength", "dexterity" }, rRoll.sAbility) then
		rRoll.bEffects = true;
		rRoll.bAutoFail = true;
	end
	if EffectManager5E.hasEffectCondition(rSource, "ADVSAV", rTarget) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "ADVSAV", rRoll.tSaveFilter, rTarget)) > 0 then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end
	if EffectManager5E.hasEffectCondition(rSource, "DISSAV", rTarget) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "DISSAV", rRoll.tSaveFilter, rTarget)) > 0 then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif ((rRoll.sAbility or "") == "dexterity") and EffectManager5E.hasEffectCondition(rSource, "Restrained") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif StringManager.contains({ "strength", "dexterity", "constitution" }, rRoll.sAbility) then
		if EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end

	if ((rRoll.sAbility or "") == "dexterity") and EffectManager5E.hasEffectCondition(rSource, "Dodge") and
			not (bFrozen or
				EffectManager5E.hasEffectCondition(rSource, "Grappled") or
				EffectManager5E.hasEffectCondition(rSource, "Restrained")) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end

	if rRoll.sType == "concentration" then
		if EffectManager5E.hasEffectCondition(rSource, "ADVCONC") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISCONC") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	elseif StringManager.contains({ "death", "death_auto", }, rRoll.sType) then
		if EffectManager5E.hasEffectCondition(rSource, "ADVDEATH") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISDEATH") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end

	-- Handle Magic Resistance and Gnome Cunning effects/traits
	if rRoll.sSaveDesc then
		if rRoll.sSaveDesc:match("%[MAGIC%]") then
			local bMagicResistance = false;
			if ActorManager5E.hasRollTrait(rSource, CharManager.TRAIT_MAGIC_RESISTANCE) then
				bMagicResistance = true;
			elseif StringManager.contains({ "intelligence", "wisdom", "charisma" }, rRoll.sSave) and
						ActorManager5E.hasRollTrait(rSource, CharManager.TRAIT_GNOME_CUNNING) then
				bMagicResistance = true;
			end
			if bMagicResistance then
				rRoll.bEffects = true;
				rRoll.bADV = true;
			end
		end
	end

	-- Handle Cover
	if ((rRoll.sAbility or "") == "dexterity") then
		if rRoll.sSaveDesc then
			if rRoll.sSaveDesc:match("%[COVER %+5%]") then
				rRoll.bSuperiorCover = true;
			end
			if rRoll.sSaveDesc:match("%[COVER %+2%]") then
				rRoll.bCover = true;
			end
		end
		if not rRoll.bSuperiorCover then
			local tCoverEffects = EffectManager5E.getEffectsByType(rSource, "SCOVER", rRoll.tSaveFilter, rSaveSource);
			if #tCoverEffects > 0 or EffectManager5E.hasEffect(rSource, "SCOVER", rSaveSource) then
				rRoll.bSuperiorCover = true;
			elseif not rRoll.bCover then
				tCoverEffects = EffectManager5E.getEffectsByType(rSource, "COVER", rRoll.tSaveFilter, rSaveSource);
				if #tCoverEffects > 0 or EffectManager5E.hasEffect(rSource, "COVER", rSaveSource) then
					rRoll.bCover = true;
				end
			end
		end
		if rRoll.bSuperiorCover then
			table.insert(rRoll.tNotifications, "[COVER +5]");
		elseif rRoll.bCover then
			table.insert(rRoll.tNotifications, "[COVER +2]");
		end
	end

	-- Handle War Caster feat
	if rRoll.sSave == "concentration" then
		if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_WAR_CASTER) then
			rRoll.bADV = true;
			table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_warcaster")));
		elseif ActorManager5E.hasFeature(rSource, CharManager.FEATURE_ELDRITCH_INVOCATION_ELDRITCH_MIND) then
			rRoll.bADV = true;
			table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_eldritchinvocationeldritchmind")));
		end
	end
end
function applyExhaustionEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	local nExhaustMod,_ = EffectManager5E.getEffectsBonus(rSource, { "EXHAUSTION" }, true);
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
function applyReliableEffectsToRollMod(rRoll, rSource, _)
	if not rSource then
		return;
	end

	if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLESAV") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif #(EffectManager5E.getEffectsByType(rSource, "RELIABLESAV", rRoll.tSaveFilter)) > 0 then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end

	if rRoll.sType == "concentration" then
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLECONC") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		end
	elseif StringManager.contains({ "death", "death_auto", }, rRoll.sType) then
		if EffectManager5E.hasEffectCondition(rSource, "RELIABLEDEATH") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		end
	end
end
function finalizeRollMod(rRoll)
	if rRoll.bSuperiorCover then
		rRoll.nMod = rRoll.nMod + 5;
	elseif rRoll.bCover then
		rRoll.nMod = rRoll.nMod + 2;
	end
	if rRoll.sSaveDesc then
		local sEffectsTag = Interface.getString("effects_tag");
		local sDCEffect = rRoll.sSaveDesc:match("%[" .. sEffectsTag .. " ([+-]?%d+)%]")
		if sDCEffect then
			table.insert(rRoll.tNotifications, string.format("[DC %s %s]", sEffectsTag, sDCEffect));
		elseif rRoll.sSaveDesc:match("%[" .. sEffectsTag .. "%]") then
			table.insert(rRoll.tNotifications, string.format("[DC %s]", sEffectsTag));
		end
	end
	if rRoll.bAutoFail then
		table.insert(rRoll.tNotifications, "[AUTOFAIL]");
	end

	rRoll.bCover = nil;
	rRoll.bSuperiorCover = nil;
	rRoll.tSaveFilter = nil;
	rRoll.bAutoFail = nil;
end

--
-- System shock saving throw
--

function getSystemShockRoll(rActor)
	local rRoll = ActionsManager2.setupD20RollBuild("systemshock", rActor);
	ActionSave.setupRollBuildSystemShock(rRoll, rActor);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performSystemShockRoll(draginfo, rActor)
	local rRoll = ActionSave.getSystemShockRoll(rActor);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onSystemShockRoll(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	ActionSave.notifyApplySystemShock(rSource, rMessage.secret, rRoll);
end

function notifyApplySystemShock(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYSS;

	msgOOB.nSecret = bSecret and 1 or 0;
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

	ActionSave.applySystemShockRoll(rSource, rAction);
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
		rRoll.aDice = DiceRollManager.getActorDice({ "d10" }, rSource);
		ActionsManager.performAction(nil, rSource, rRoll);
	end
end

function onSystemShockResultRoll(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

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

function getDeathRoll(rActor, bAuto)
	local rRoll = ActionsManager2.setupD20RollBuild(bAuto and "death_auto" or "death", rActor);
	ActionSave.setupRollBuildDeath(rRoll, rActor);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performDeathRoll(draginfo, rActor, bAuto)
	local rRoll = ActionSave.getDeathRoll(rActor, bAuto);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onDeathRoll(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

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
			local bShowStatus;
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

function getConcentrationRoll(rActor, nTargetDC, tData)
	local rRoll = ActionsManager2.setupD20RollBuild("concentration", rActor);
	ActionSave.setupRollBuildConcentration(rRoll, rActor, nTargetDC, tData);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performConcentrationRoll(draginfo, rActor, nTargetDC, tData)
	local rRoll = ActionSave.getConcentrationRoll(rActor, nTargetDC, tData);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onConcentrationRoll(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	if Session.IsHost and ActorManager.isPC(rSource) then
		rMessage.secret = nil;
	end
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		ActionSave.notifyApplyConc(rSource, rMessage.secret, rRoll);
	end
end

function hasConcentrationEffects(rSource)
	return #(ActionSave.getConcentrationEffects(rSource)) > 0;
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

	ActionSave.applyConcentrationRoll(rSource, rAction);
end
function notifyApplyConc(rSource, bSecret, rRoll)
	local msgOOB = {};
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYCONC;

	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = rRoll.bSecret and 1 or 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.nTarget = rRoll.nTarget;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
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
		bSecret = false;
	end
	ActionsManager.outputResult(bSecret, rSource, nil, msgLong, msgShort);

	-- On failed concentration check, remove all effects with the same source creature
	if rAction.nTotal < rAction.nTarget then
		ActionSave.expireConcentrationEffects(rSource);
	end
end
function expireConcentrationEffects(rSource)
	local aSourceConcentrationEffects = ActionSave.getConcentrationEffects(rSource);
	for _,v in ipairs(aSourceConcentrationEffects) do
		EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
	end
end
