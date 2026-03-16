--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSAVE = "applysave";
OOB_MSGTYPE_APPLYCONC = "applyconc";
OOB_MSGTYPE_APPLYSS = "applyss";
OOB_MSGTYPE_FAILEDSAVEEFF = "failedsaveeff";

function onInit()
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYSAVE, ActionSave.handleApplySave);
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYCONC, ActionSave.handleApplyConc);
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_APPLYSS, ActionSave.handleApplySystemShock);
	OOBManager.registerOOBMsgHandler(ActionSave.OOB_MSGTYPE_FAILEDSAVEEFF, ActionSave.handleFailedEffectSave);

	ActionsManager.registerModHandler("save", ActionSave.modSave);
	ActionsManager.registerResultHandler("save", ActionSave.onSave);
	ActionsManager.registerModHandler("save_auto", ActionSave.modSave);
	ActionsManager.registerResultHandler("save_auto", ActionSave.onSave);

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

function notifyApplySave(rSource, rRoll)
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYSAVE;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rRoll.sSource ~= "" then
		msgOOB.sTargetNode = rRoll.sSource;
	end
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplySave(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rOrigin = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionSave.applySave(rSource, rOrigin, rRoll);
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
	local nTotal, nEffectCount = EffectManager.getBonusMod(rSource, "SAVEDC", { rTarget = rActor, });
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

	ActionSave.onPreSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onPostSaveResolve(rSource, rRoll, rMessage);
end
-- onPreSaveResolve(rSource, rRoll, rMessage)
function onPreSaveResolve()
	-- Do nothing; location to override
end
function onSaveResolve(rSource, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	if not bAutoFail and rRoll.nTarget then
		rRoll.nTotal = ActionsManager.total(rRoll);
		ActionSave.notifyApplySave(rSource, rRoll);
	end
end
-- onPostSaveResolve(rSource, rRoll, rMessage)
function onPostSaveResolve()
	-- Do nothing; location to override
end

function applySave(rSource, rOrigin, rRoll)
	local tApplyData = { sResultText = "Save", sResultIcon = "action_cast", tNotifications = {}, };

	local sAttack = ActionCore.decodeLabelText(rRoll.sSaveDesc, "action_savevs_tag");
	local bHalfMatch = ((rRoll.sSaveDesc or ""):match("%[HALF ON SAVE%]") ~= nil);
	rRoll.sResult = "";

	if rRoll.nTarget > 0 then
		tApplyData.nTargetDC = rRoll.nTarget;

		local bAvoidance = false;
		local bEvasion = false;
		if bHalfMatch then
			if ActorManager5E.hasRollFeature(rSource, "Avoidance") then
				bAvoidance = true;
				table.insert(tApplyData.tNotifications, "[AVOIDANCE]");
			elseif (rRoll.sSave == "dexterity") and ActorManager5E.hasRollFeature(rSource, "Evasion") then
				bEvasion = true;
				table.insert(tApplyData.tNotifications, "[EVASION]");
			end
		end

		if rRoll.nTotal >= rRoll.nTarget then
			rRoll.sResult = "success";
			table.insert(tApplyData.tNotifications, "[SUCCESS]");
			
			if rSource then
				if bAvoidance or bEvasion then
					rRoll.sResult = "none";
					rRoll.bRemoveOnMiss = false;
				elseif bHalfMatch then
					rRoll.sResult = "half_success";
					rRoll.bRemoveOnMiss = false;
				end
				
				if rOrigin and rRoll.bRemoveOnMiss then
					TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
				end

				if (rRoll.sEffectRecord or "") ~= "" then
					EffectManager.notifyExpire(rRoll.sEffectRecord, nil, true);
				end
			end
		else
			rRoll.sResult = "failure";
			table.insert(tApplyData.tNotifications, "[FAILURE]");

			if rSource then
				if bAvoidance or bEvasion then
					rRoll.sResult = "half_failure";
				end
			end

			if (rRoll.sEffectRecord or "") ~= "" then
				ActionSave.notifyFailedEffectSave(rSource, rRoll.sEffectRecord);
			end
		end
	end

	ActionCore.applyMessage(rSource, rOrigin, rRoll, tApplyData);
	
	if rSource and rOrigin then
		ActionDamageCore.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rRoll.sResult);
	end

	ActionSave.onPostSaveApply(rSource, rOrigin, rRoll);

	GameManager.callEventFunctions("onSavePostResolve", rSource, rOrigin, rAction);
end
-- onPostSaveApply(rSource, rOrigin, rRoll)
function onPostSaveApply()
	-- Do nothing; location to override
end

function notifyFailedEffectSave(rActor, sEffectRecord)
	local msgOOB = {
		type = OOB_MSGTYPE_FAILEDSAVEEFF,
		sActorNode = ActorManager.getCreatureNodeName(rActor),
		sEffectNode = sEffectRecord,
	};
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleFailedEffectSave(msgOOB)
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		return;
	end

	local rActor = ActorManager.resolveActor(msgOOB.sActorNode);
	EffectManager.handleEffectSaveFail(rActor, nodeEffect);
end

--
--	MOD ROLL HELPERS
--

function setupRollBuild(rRoll, rActor, sSave)
	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getSave(rActor, sSave);
	table.insert(rRoll.tNotifications, ActionCore.encodeActionText({ label = sSave, }, "action_save_tag"));
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
		rRoll.sSave = ActionCore.decodeLabelText(rRoll.sDesc, "action_save_tag"):lower();
		rRoll.sAbility = rRoll.sSave;

		-- Check cover for dexterity saves
		if rRoll.sSave == "dexterity" then
			rRoll.bCover = ModifierManager.getKey("DEF_COVER");
			rRoll.bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");
		end

		if rRoll.sSaveDesc:match("%[MAGIC%]") then
			table.insert(rRoll.tNotifications, "[VS MAGIC]");
			rRoll.bMagic = true;
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

	local bFrozen = EffectManager.hasText(rSource, "Paralyzed") or
			EffectManager.hasText(rSource, "Petrified") or
			EffectManager.hasText(rSource, "Stunned") or
			EffectManager.hasText(rSource, "Unconscious");
	local rSaveSource = nil;
	if rRoll.sSource then
		rSaveSource = ActorManager.resolveActor(rRoll.sSource);
	end
	local tSrcSaveEffData = { rTarget = rSaveSource, tFilter = rRoll.tSaveFilter, };
	local tTrgtEffData = { rTarget = rSource, tFilter = rRoll.tSaveFilter, };

	-- Get roll effect modifiers
	local tSaveDice, nSaveMod, nSaveEffect = EffectManager.getBonusDiceMod(rSource, "SAVE", tSrcSaveEffData);
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
	if EffectManager.hasTextOrTag(rSource, "ADVSAV", tSrcSaveEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	elseif EffectManager.hasTextOrTag(rSaveSource, "@ADVSAV", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end
	if EffectManager.hasTextOrTag(rSource, "DISSAV", tSrcSaveEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif EffectManager.hasTextOrTag(rSaveSource, "@DISSAV", tTrgtEffData) then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif ((rRoll.sAbility or "") == "dexterity") and EffectManager.hasText(rSource, "Restrained") then
		rRoll.bEffects = true;
		rRoll.bDIS = true;
	elseif StringManager.contains({ "strength", "dexterity", "constitution" }, rRoll.sAbility) then
		if EffectManager.hasText(rSource, "Encumbered") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end

	if ((rRoll.sAbility or "") == "dexterity") and EffectManager.hasText(rSource, "Dodge") and
			not (bFrozen or
				EffectManager.hasText(rSource, "Grappled") or
				EffectManager.hasText(rSource, "Restrained")) then
		rRoll.bEffects = true;
		rRoll.bADV = true;
	end

	if rRoll.sType == "concentration" then
		if EffectManager.hasText(rSource, "ADVCONC") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager.hasText(rSource, "DISCONC") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	elseif StringManager.contains({ "death", "death_auto", }, rRoll.sType) then
		if EffectManager.hasText(rSource, "ADVDEATH") then
			rRoll.bEffects = true;
			rRoll.bADV = true;
		end
		if EffectManager.hasText(rSource, "DISDEATH") then
			rRoll.bEffects = true;
			rRoll.bDIS = true;
		end
	end

	-- Handle Magic Resistance and Gnome Cunning effects/traits
	if rRoll.bMagic then
		if ActorManager5E.hasRollTrait(rSource, CharManager.TRAIT_MAGIC_RESISTANCE) then
			rRoll.bADV = true;
			table.insert(rRoll.tNotifications, "[MAGIC RESISTANCE]");
		elseif StringManager.contains({ "intelligence", "wisdom", "charisma" }, rRoll.sSave) and
					ActorManager5E.hasRollTrait(rSource, CharManager.TRAIT_GNOME_CUNNING) then
			rRoll.bADV = true;
			table.insert(rRoll.tNotifications, "[GNOME CUNNING]");
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
			if EffectManager.hasTextOrTag(rSource, "SCOVER", tSrcSaveEffData) then
				rRoll.bSuperiorCover = true;
			elseif not rRoll.bCover then
				if EffectManager.hasTextOrTag(rSource, "COVER", tSrcSaveEffData) then
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

	local nExhaustMod = EffectManager.getBonusMod(rSource, "EXHAUSTION");
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

	if EffectManager.hasText(rSource, "RELIABLE") then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	elseif EffectManager.hasTextOrTag(rSource, "RELIABLESAV", { tFilter = rRoll.tSaveFilter, }) then
		rRoll.bEffects = true;
		rRoll.bReliable = true;
	end

	if rRoll.sType == "concentration" then
		if EffectManager.hasText(rSource, "RELIABLECONC") then
			rRoll.bEffects = true;
			rRoll.bReliable = true;
		end
	elseif StringManager.contains({ "death", "death_auto", }, rRoll.sType) then
		if EffectManager.hasText(rSource, "RELIABLEDEATH") then
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

	ActionSave.onPreSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onSystemShockRollResolve(rSource, rRoll, rMessage);
	ActionSave.onPostSaveResolve(rSource, rRoll, rMessage);
end
function onSystemShockRollResolve(rSource, rRoll, rMessage)
	Comm.deliverChatMessage(rMessage);

	ActionSave.notifyApplySystemShock(rSource, rMessage.secret, rRoll);
end

function notifyApplySystemShock(rSource, bSecret, rRoll)
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYSS;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplySystemShock(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionSave.applySystemShockRoll(rSource, rRoll);
end
function applySystemShockRoll(rSource, rRoll)
	local tApplyData = { sResultText = "System Shock", sResultIcon = "action_cast", nValue = rRoll.nTotal, tNotifications = {}, };

	local bAutoFail = rRoll.sDesc:match("%[AUTOFAIL%]");
	local bSuccess = (not bAutoFail and (rRoll.nTotal >= 15));
	if bSuccess then
		rRoll.sResult = "success";
		table.insert(tApplyData.tNotifications, "[SUCCESS]");
	else
		rRoll.sResult = "failure";
		table.insert(tApplyData.tNotifications, "[FAILURE]");
	end

	ActionCore.applyMessage(rSource, nil, rRoll, tApplyData);

	-- On failed system shock check, roll for system shock
	if rRoll.sResult == "failure" then
		local rRoll = {
			sType = "systemshockresult",
			sDesc = "[SYSTEM SHOCK RESULT]",
			nMod = 0,
			bSecret = rRoll.bSecret,
		};
		rRoll.aDice = DiceRollManager.getActorDice({ "d10" }, rSource);
		ActionsManager.performAction(nil, rSource, rRoll);
	end

	ActionSave.onPostSystemShockApply(rSource, rRoll);

	rAction.sType = "save";
	rAction.sSaveType = "systemshock";
	GameManager.callEventFunctions("onSavePostResolve", rSource, nil, tNotifyData);
end
-- onPostSystemShockApply(rSource, rRoll)
function onPostSystemShockApply()
	-- Do nothing; location to override
end

function onSystemShockResultRoll(rSource, _, rRoll)
	ActionsManager2.setupD20RollResolve(rRoll, rSource);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	ActionSave.onPreSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onSystemShockResultRollResolve(rSource, rRoll, rMessage);
	ActionSave.onPostSaveResolve(rSource, rRoll, rMessage);
end
function onSystemShockResultRollResolve(rSource, rRoll, rMessage)
	local nodeActor = ActorManager.getCreatureNode(rSource);
	local nTotal = ActionsManager.total(rRoll);

	if (nTotal <= 1) then
		if ActorManager.isPC(rSource) then
			DB.setValue(nodeActor, "hp.wounds", "number", DB.getValue(nodeActor, "hp.total", 0));
		else
			DB.setValue(nodeActor, "wounds", "number", DB.getValue(nodeActor, "hptotal", 0));
		end
		EffectManager.removeCondition(rSource, "Stable");
		EffectManager.addCondition(rSource, "Unconscious");
		EffectManager.addCondition(rSource, "Prone");
		rMessage.text = rMessage.text .. " -> [DROPPED TO ZERO]";

	elseif ((nTotal == 2) or (nTotal == 3)) then
		if ActorManager.isPC(rSource) then
			DB.setValue(nodeActor, "hp.wounds", "number", DB.getValue(nodeActor, "hp.total", 0));
		else
			DB.setValue(nodeActor, "wounds", "number", DB.getValue(nodeActor, "hptotal", 0));
		end
		EffectManager.addCondition(rSource, "Stable");
		EffectManager.addCondition(rSource, "Unconscious");
		EffectManager.addCondition(rSource, "Prone");
		rMessage.text = rMessage.text .. " -> [DROPPED TO ZERO, BUT STABLE]";

	elseif ((nTotal == 4) or (nTotal == 5)) then
		local rEffect = { sName = "System Shock; Stunned", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			rEffect.nGMOnly = 1;
		end
		EffectManager.addEffectByTable(rSource, rEffect);
		rMessage.text = rMessage.text .. " -> [STUNNED]";

	elseif ((nTotal == 6) or (nTotal == 7)) then
		local rEffect = { sName = "System Shock; NOTE: No reactions; DISATK; DISCHK", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			rEffect.nGMOnly = 1;
		end
		EffectManager.addEffectByTable(rSource, rEffect);
		rMessage.text = rMessage.text .. " -> [NO REACTIONS, AND DISADVANTAGE]";

	else -- if (nTotal >= 8) then
		local rEffect = { sName = "System Shock; NOTE: No reactions", nDuration = 1 };
		if not ActorManager.isFaction(rSource, "friend") then
			rEffect.nGMOnly = 1;
		end
		EffectManager.addEffectByTable(rSource, rEffect);
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

	ActionSave.onPreSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onDeathRollResolve(rSource, rRoll, rMessage);
	ActionSave.onPostSaveResolve(rSource, rRoll, rMessage);

	rRoll.sType = "save";
	rRoll.sSaveType = "death";
	GameManager.callEventFunctions("onSavePostResolve", rSource, nil, rRoll);
end
function onDeathRollResolve(rSource, rRoll, rMessage)
	if ActorHealthManager.getWoundPercent(rSource) >= 1 then
		local nTotal = ActionsManager.total(rRoll);

		local bStatusCheck = true;
		local sOriginalStatus = ActorHealthManager.getHealthStatus(rSource);

		local nodeSource;
		if ActorManager.isPC(rSource) then
			nodeSource = ActorManager.getCreatureNode(rSource);
		else
			nodeSource = ActorManager.getCTNode(rSource);
		end
		if not nodeSource then
			return;
		end

		local sSuccessField, sFailField;
		if ActorManager.isPC(rSource) then
			sSuccessField = "hp.deathsavesuccess";
			sFailField = "hp.deathsavefail";
		else
			sSuccessField = "deathsavesuccess";
			sFailField = "deathsavefail";
		end

		local nFirstDie = 0;
		if #(rRoll.aDice) > 0 then
			nFirstDie = rRoll.aDice[1].result or 0;
		end
		if nFirstDie == 1 then
			rRoll.sResult = "critfailure";
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";

			if nodeSource then
				local nValue = DB.getValue(nodeSource, sFailField, 0);
				if nValue < 3 then
					nValue = math.min(nValue + 2, 3);
					DB.setValue(nodeSource, sFailField, "number", nValue);
				end
			end
		elseif nFirstDie == 20 then
			rRoll.sResult = "critsuccess";
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";

			local rCritHealRoll = {
				sType = "heal",
				bSecret = rRoll.bSecret,
				sDesc = string.format("[%s]", Interface.getString("action_heal_tag")),
				nTotal = 1,
			};
			ActionDamageD20.notifyApplyDamage(nil, rSource, rCritHealRoll);
			bStatusCheck = false;
		elseif nTotal >= 10 then
			rRoll.sResult = "success";
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
			rRoll.sResult = "failure";
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

	ActionSave.onPreSaveResolve(rSource, rRoll, rMessage);
	ActionSave.onConcentrationRollResolve(rSource, rRoll, rMessage);
	ActionSave.onPostSaveResolve(rSource, rRoll, rMessage);
end
function onConcentrationRollResolve(rSource, rRoll, rMessage)
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
					local sLabel = EffectVarManager.getEffectVarFromNode(nodeEffect, "sName", "");
					if sLabel:match("%([cC]%)") then
						table.insert(aEffects, { nodeCT = nodeCT, nodeEffect = nodeEffect });
					end
				end
			end
		end
	end

	return aEffects;
end

function notifyApplyConc(rSource, bSecret, rRoll)
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionSave.OOB_MSGTYPE_APPLYCONC;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	Comm.deliverOOBMessage(msgOOB, "");
end
function handleApplyConc(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionSave.applyConcentrationRoll(rSource, rRoll);
end
function applyConcentrationRoll(rSource, rRoll)
	local tApplyData = { sResultText = "Concentration", sResultIcon = "action_cast", tNotifications = {}, };

	if rRoll.nTarget > 0 then
		tApplyData.nTargetDC = rRoll.nTarget;

		if rRoll.nTotal >= rRoll.nTarget then
			msgLong.text = msgLong.text .. " [SUCCESS]";
		else
			msgLong.text = msgLong.text .. " [FAILURE]";
		end
	end
	
	ActionCore.applyMessage(rSource, nil, rRoll, tApplyData);

	if rRoll.nTotal >= rRoll.nTarget then
		rRoll.sResult = "success";
	else
		rRoll.sResult = "failure";
		-- On failed concentration check, remove all effects with the same source creature
		ActionSave.expireConcentrationEffects(rSource);
	end

	ActionSave.onPostConcentrationApply(rSource, rRoll);

	rAction.sType = "save";
	rAction.sSaveType = "concentration";
	GameManager.callEventFunctions("onSavePostResolve", rSource, nil, rAction);
end
function expireConcentrationEffects(rSource)
	local aSourceConcentrationEffects = ActionSave.getConcentrationEffects(rSource);
	for _,v in ipairs(aSourceConcentrationEffects) do
		EffectManager.expireEffect(v.nodeCT, v.nodeEffect, 0);
	end
end
-- onPostConcentrationApply(rSource, rRoll)
function onPostConcentrationApply()
	-- Do nothing; location to override
end
