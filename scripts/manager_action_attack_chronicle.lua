-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

rAction2 = {}

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerResultHandler("attack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local rRoll = UtilityManager.decodeRollFromOOB(msgOOB);
	ActionAttack.applyAttack(rSource, rTarget, rRoll);
end

-- Communicate attack roll to Clients
function notifyApplyAttack(rSource, rTarget, rRoll)
	if not rTarget then
		return;
	end

	rRoll.bSecret = rRoll.bTower;
	rRoll.sResults = table.concat(rRoll.aMessages, " ");
	
	local msgOOB = UtilityManager.encodeRollToOOB(rRoll);
	msgOOB.type = ActionAttack.OOB_MSGTYPE_APPLYATK;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

-- Handle "Fumble" & "Critica Hits" messaging. (HRFC = House Rules Fumble/Crit")
function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end

-- Communicate "Fumble" & "Critica Hits" to Clients
function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

-- Handle "Remove On Miss" setting in options
function onTargeting(rSource, aTargeting, rRolls)
	local bRemoveOnMiss = false;
	local sOptRMMT = OptionsManager.getOption("RMMT");
	if sOptRMMT == "on" then
		bRemoveOnMiss = true;
	elseif sOptRMMT == "multi" then
		bRemoveOnMiss = (#aTargeting > 1);
	end
	
	if bRemoveOnMiss then
		for _,vRoll in ipairs(rRolls) do
			vRoll.bRemoveOnMiss = "true";
		end
	end

	return aTargeting;
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function getRoll(rActor, rAction)
	local rRoll = ActionsManager2.setupD20RollBuild("attack", rActor);
	ActionAttack.setupRollBuild(rRoll, rActor, rAction);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetVsRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
	
	ActionsManager.actionDirect(nil, "attack", { rRoll }, { { rActor } });
end
function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionAttack.getRoll(rActor, rAction);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

-- Adjusted
function getRoll(rActor, rAction)
	local bADV = rAction.bADV or false;
	local bDIS = rAction.bDIS or false;
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "attack";
	rRoll.aDice = DiceRollManager.getActorDice({ }, rActor);
	rRoll.nMod = rAction.modifier or 0;
	rRoll.bWeapon = rAction.bWeapon;
	
	rRoll.sLabel = StringManager.capitalizeAll(rAction.label);
	rRoll.nOrder = rAction.order;
	rRoll.sRange = rAction.range;
	rRoll.nTest = rAction.nStat or 0;
	rRoll.nBonus = rAction.nSkill or 0;
	rRoll.nPenalty = rAction.nPenalty or 0;
	rRoll.nDoS = 1;
	rRoll.nAP = ActorManager5E.getArmorPenalty(rActor);
	rRoll.nodeWeapon = rAction.nodeWeapon;
	
	-- Save rAction as we need some of its data in function onAttack
	rAction2 = rAction
	
	-- Add Test and Bonus Die to Dice Array. This is necessary to have the proper number of die show up on drag.
	for i = 1, rRoll.nTest do
		table.insert(rRoll.aDice, "d6")
	end

	for i = 1, rRoll.nBonus do
		table.insert(rRoll.aDice, "d6")
	end

	-- Build the description label
	rRoll.sDesc = "[ATTACK";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. StringManager.capitalizeAll(rAction.label);
	
	local tAddText = {};

	-- Add crit range
	-- if rAction.nCritRange then
		-- table.insert(tAddText, "[CRIT " .. rAction.nCritRange .. "]");
	-- end
	
	-- Add ability modifiers
	-- if rAction.stat then
		-- local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		-- if sAbilityEffect then
			-- table.insert(tAddText, "[MOD:" .. sAbilityEffect .. "]");
		-- end

		-- Check for armor non-proficiency
		-- local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
		-- if nodeActor and (sNodeType == "pc") then
			-- if StringManager.contains({"strength", "dexterity"}, rAction.stat) then
				-- local nodePC = ActorManager.getCreatureNode(rActor);
				-- if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
					-- table.insert(tAddText, string.format("[%s]", Interface.getString("roll_msg_armor_nonprof")));
					-- bDIS = true;
				-- end
			-- end
		-- end
	-- end
	
	-- Add advantage/disadvantage tags
	-- if bADV then
		-- table.insert(tAddText, "[ADV]");
	-- end
	-- if bDIS then
		-- table.insert(tAddText, "[DIS]");
	-- end

	if #tAddText > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(tAddText, " ");
	end
	if #(rAction.tAddText or {}) > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(rAction.tAddText, " ");
	end

	return rRoll;
end

-- This function is used to modify the Roll record for Attack checks
function modAttack(rSource, rTarget, rRoll)
	ActionAttack.clearCritState(rSource);
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

	-- Correcting changes done in CorePRG
	rRoll.nTest = tonumber(rRoll.nTest)
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	rRoll.nMod = tonumber(rRoll.nMod)

	-- Check for opportunity attack
	local bOpportunity = ModifierManager.getKey("ATT_OPP") or Input.isShiftPressed();
	if bOpportunity then
		-- table.insert(aAddDesc, "[OPPORTUNITY]");
	end

	-- Check defense modifiers
	local bCover = ModifierManager.getKey("DEF_COVER");
	local bSuperiorCover = ModifierManager.getKey("DEF_SCOVER");
	if bSuperiorCover then
		table.insert(aAddDesc, "[COVER -5]");
	elseif bCover then
		table.insert(aAddDesc, "[COVER -2]");
	end
	
	-- Check advantage/disadvantage
	local bADV = false;
	local bDIS = false;
	-- if rRoll.sDesc:match(" %[ADV%]") then
		-- bADV = true;
		-- rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");		
	-- end
	-- if rRoll.sDesc:match(" %[DIS%]") then
		-- bDIS = true;
		-- rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	-- end

	local aAttackFilter = {};

	-- Consider Health
	ActionsManager2.encodeHealthMods(rSource, rRoll)

	-- Consider Desktop Modifications
	ActionsManager2.encodeDesktopMods(rRoll)

	-- Check applying Effects
	if rSource then
		-- Determine attack type
		local sAttackType = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
		if not sAttackType then
			sAttackType = "M";
		end

		-- Determine ability used
		-- local sActionStat = nil;
		-- local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
		-- if sModStat then
			-- sActionStat = DataCommon.ability_stol[sModStat];
		-- end
		
		-- Build attack filter
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		end

		-- Check for Weapon Grade
		-- local nodeWeapon = getDatabaseNode()
		-- local sWeaponGrade = DB.getValue(nodeWeapon, "wpn_grade", "")

		-- ToDo: Implement for Attack Roll
		-- if sWeaponGrade == "Poor" then
			-- nPenalty = nPenalty + 1
		-- elseif sWeaponGrade == "Superior" then
			-- nBonus = nBonus + 1
		-- elseif sWeaponGrade == "Extraordinary" then
			-- nBonus = nBonus + 1
		-- end

		-- Check if a two-handed weapon is used with one hand only and apply penalty dice accordingly
		-- ToDo: Implement for Attack Roll
		-- local sWeaponQualities = DB.getValue(nodeWeapon, "wpn_qualities", "")
		-- if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) == true and nWeaponHandling ~= 1 then
			-- nPenalty = nPenalty + 2
		-- end

		-- Check for modifiers
		-- Check for aim
		local bAim = ModifierManager.getKey("ATT_AIM")
		if bAim then
			table.insert(aAddDesc, "[Aim +1B]")
			rRoll.nBonus = rRoll.nBonus + 1
		end

		-- Check for higher ground
		local bHighground = ModifierManager.getKey("ATT_HIGHGROUND")
		if bHighground then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[HIGHGROUND +1B]")
				rRoll.nBonus = rRoll.nBonus + 1
			end
		end

		-- Check for cautious attack
		local bCautious = ModifierManager.getKey("ATT_CAUTIOUS")
		if bCautious then
			table.insert(aAddDesc, "[CAUTIOUS -1D, CoD +3]")
			rRoll.nPenalty = rRoll.nPenalty + 1
		end

		-- Check for reckless attack
		local bReckless = ModifierManager.getKey("ATT_RECKLESS")
		if bReckless then
			table.insert(aAddDesc, "[RECKLESS +1D, CoD -5]")
			rRoll.nTest = rRoll.nTest + 1
		end

		-- Check for cover
		local bCover = ModifierManager.getKey("DEF_COVER")
		if bCover then
			table.insert(aAddDesc, "[COVER -5]")
			nAddMod = nAddMod - 5
		end

		-- Check for superior cover
		local bSuperiorCover = ModifierManager.getKey("DEF_SCOVER")
		if bSuperiorCover then
			table.insert(aAddDesc, "[COVER -10]")
			nAddMod = nAddMod - 10
		end

		-- Check for shadowy light
		local bLowLight = ModifierManager.getKey("DEF_LOWLIGHT")
		if bLowLight then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[SHADOWY -1D]")
				rRoll.nPenalty = rRoll.nPenalty + 1
			elseif sAttackType == "R" then
				table.insert(aAddDesc, "[SHADOWY -2D]")
				rRoll.nPenalty = rRoll.nPenalty + 2
			end
		end

		-- Check for darkness
		local bNoLight = ModifierManager.getKey("DEF_NOLIGHT")
		if bNoLight then
			if sAttackType == "M" then
				table.insert(aAddDesc, "[DARKNESS -2D]")
				rRoll.nPenalty = rRoll.nPenalty + 2
			elseif sAttackType == "R" then
				table.insert(aAddDesc, "[DARKNESS -4D]")
				rRoll.nPenalty = rRoll.nPenalty + 4
			end
		end

		-- Check for sprinting target
		local bSprint = ModifierManager.getKey("DEF_SPRINT")
		if bSprint then
			table.insert(aAddDesc, "[Moving Target -1D]")
			rRoll.nPenalty = rRoll.nPenalty + 1
		end		

		-- Apply collected nAddMod to rRoll.nMod
		rRoll.nMod = rRoll.nMod + nAddMod

		-- Get attack effect modifiers
		-- ToDo: Implement
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter, rTarget);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		-- ToDo: List all conditions
		if EffectManager5E.hasEffect(rSource, "ADVATK", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVATK", aAttackFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Invisible") then
			bADV = true;
			bEffects = true;
		end

		if EffectManager5E.hasEffect(rSource, "DISATK", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISATK", aAttackFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Blinded") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Encumbered") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Frightened") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Intoxicated") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Poisoned") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager.hasCondition(rSource, "Prone") then
			bDIS = true;
			bEffects = true;
		elseif EffectManager5E.hasEffectCondition(rSource, "Restrained") then
			bDIS = true;
			bEffects = true;
		end

		local bFrozen = EffectManager5E.hasEffectCondition(rSource, "Paralyzed") or
				EffectManager5E.hasEffectCondition(rSource, "Petrified") or
				EffectManager5E.hasEffectCondition(rSource, "Stunned") or
				EffectManager5E.hasEffectCondition(rSource, "Unconscious");
		if bFrozen then
			bEffects = true;
		end

		-- Get ability modifiers
		-- local nBonusStat, nBonusEffects = ActorManager5E.getAbilityEffectsBonus(rSource, sActionStat);
		-- if nBonusEffects > 0 then
			-- bEffects = true;
			-- nAddMod = nAddMod + nBonusStat;
		-- end
		
		-- Get exhaustion modifiers
		-- local nExhaustMod, nExhaustCount = EffectManager5E.getEffectsBonus(rSource, {"EXHAUSTION"}, true);
		-- if nExhaustCount > 0 then
			-- bEffects = true;
			-- nAddMod = nAddMod - (2 * nExhaustMod);
		-- end
		
		-- Determine crit range
		-- local aCritRange = EffectManager5E.getEffectsByType(rSource, "CRIT", aAttackFilter, rTarget);
		-- if #aCritRange > 0 then
			-- local nCritThreshold = 20;
			-- for _,v in ipairs(aCritRange) do
				-- if v.mod > 1 and v.mod < nCritThreshold then
					-- bEffects = true;
					-- nCritThreshold = v.mod;
				-- end
			-- end
			-- if nCritThreshold < 20 then
				-- local sRollCritThreshold = rRoll.sDesc:match("%[CRIT (%d+)%]");
				-- local nRollCritThreshold = tonumber(sRollCritThreshold) or 20;
				-- if nCritThreshold < nRollCritThreshold then
					-- if rRoll.sDesc:match(" %[CRIT %d+%]") then
						-- rRoll.sDesc = rRoll.sDesc:gsub(" %[CRIT %d+%]", " [CRIT " .. nCritThreshold .. "]");
					-- else
						-- rRoll.sDesc = rRoll.sDesc ..  " [CRIT " .. nCritThreshold .. "]";
					-- end
				-- end
			-- end
		-- end

		-- Check Reliable state
		-- local bReliable = false;
		-- if EffectManager5E.hasEffectCondition(rSource, "RELIABLE") then
			-- bEffects = true;
			-- bReliable = true;
		-- elseif EffectManager5E.hasEffectCondition(rSource, "RELIABLEATK") then
			-- bEffects = true;
			-- bReliable = true;
		-- end
		-- if bReliable then
			-- table.insert(aAddDesc, string.format("[%s]", Interface.getString("roll_msg_feature_reliable")));
		-- end

		-- If effects, then add them
		if bEffects then
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
		end
	end

	-- if bSuperiorCover then
		-- nAddMod = nAddMod - 5;
	-- elseif bCover then
		-- nAddMod = nAddMod - 2;
	-- end
	
	-- local bDefADV, bDefDIS = ActorManager5E.getDefenseAdvantage(rSource, rTarget, aAttackFilter);
	-- if bDefADV then
		-- bADV = true;
	-- end
	-- if bDefDIS then
		-- bDIS = true;
	-- end

	-- Build description string
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	
	-- ActionsManager2.encodeDesktopMods(rRoll);
	-- for _,vDie in ipairs(aAddDice) do
		-- if vDie:sub(1,1) == "-" then
			-- table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		-- else
			-- table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		-- end
	-- end
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll)
	
	-- ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

-- Adjusted
function onAttack(rSource, rTarget, rRoll)
	-- ActionAttack.decodeAttackRoll(rRoll);
	-- ActionsManager2.decodeAdvantage(rRoll);
	
	-- Rebuild detail fields if dragging from chat window
	-- ToDo: Needed?
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.*%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.*%]([^%[]+)"));
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll)
	-- rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	-- Add message array to rRoll, this is required for DoS output
	-- rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aMessages = {};

	-- Determine Target Combat Defense and defense bonus effects
	rRoll.nDefenseVal, rRoll.nAtkEffectsBonus, rRoll.nDefEffectsBonus = ActorManager5E.getDefenseValue(rSource, rTarget, rRoll);
	if rRoll.nAtkEffectsBonus ~= 0 then
		rRoll.nTotal = rRoll.nTotal + rRoll.nAtkEffectsBonus;
		table.insert(rRoll.aMessages, EffectManager.buildEffectOutput(rRoll.nAtkEffectsBonus));
	end
	if rRoll.nDefEffectsBonus ~= 0 then
		rRoll.nDefenseVal = rRoll.nDefenseVal + rRoll.nDefEffectsBonus;
		table.insert(rRoll.aMessages, string.format("[%s %+d]", Interface.getString("effects_def_tag"), rRoll.nDefEffectsBonus));
	end
	
	-- local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	-- local nCritThreshold = tonumber(sCritThreshold) or 20;
	-- if nCritThreshold < 2 or nCritThreshold > 20 then
		-- nCritThreshold = 20;
	-- end
	
	-- rRoll.nFirstDie = 0;
	-- if #(rRoll.aDice) > 0 then
		-- rRoll.nFirstDie = rRoll.aDice[1].result or 0;
	-- end
	-- if rRoll.nFirstDie >= nCritThreshold then
		-- rRoll.bSpecial = true;
		-- rRoll.sResult = "crit";
		-- table.insert(rRoll.aMessages, "[CRITICAL HIT]");
	-- elseif rRoll.nFirstDie == 1 then
		-- rRoll.sResult = "fumble";
		-- table.insert(rRoll.aMessages, "[AUTOMATIC MISS]");
	-- elseif rRoll.nDefenseVal then
		-- if rRoll.nTotal >= rRoll.nDefenseVal then
			-- rRoll.sResult = "hit";
			-- table.insert(rRoll.aMessages, "[HIT]");
		-- else
			-- rRoll.sResult = "miss";
			-- table.insert(rRoll.aMessages, "[MISS]");
		-- end
	-- end

	-- Determine degrees of success
	if rRoll.nDefenseVal then
		rMessage, rRoll = ActionResult.DetermineSuccessAttack(rMessage, rRoll)
	end

	-- Save quality of attack for use in damage calculation
	DB.setValue(rAction2.nodeWeapon, "dmg_multiplier", "number", rRoll.nDoS - 1)

	-- Build chat message if no target was selected
	if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rRoll.aMessages, " ");
	end
	
	ActionAttack.onPreAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onAttackResolve(rSource, rTarget, rRoll, rMessage);
	ActionAttack.onPostAttackResolve(rSource, rTarget, rRoll, rMessage);
end
function onPreAttackResolve(rSource, rTarget, rRoll, rMessage)
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
function onPostAttackResolve(rSource, rTarget, rRoll, rMessage)
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rRoll.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		ActionAttack.notifyApplyHRFC("Fumble");
	end
	if rRoll.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		ActionAttack.notifyApplyHRFC("Critical Hit");
	end
end

function decodeAttackRoll(rRoll)
	-- Rebuild detail fields if dragging from chat window
	if not rRoll.nOrder then
		rRoll.nOrder = tonumber(rRoll.sDesc:match("%[ATTACK.-#(%d+)")) or nil;
	end
	if not rRoll.sRange then
		rRoll.sRange = rRoll.sDesc:match("%[ATTACK.-%((%w+)%)%]");
	end
	if not rRoll.sLabel then
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match("%[ATTACK.-%]([^%[]+)"));
	end
end

function applyAttack(rSource, rTarget, rRoll)
	local msgShort = { font = "msgfont" };
	local msgLong = { font = "msgfont" };
	
	-- Standard roll information
	msgShort.text = "Attack";
	msgLong.text = "Attack";
	if rRoll.nOrder then
		msgShort.text = string.format("%s #%d", msgShort.text, rRoll.nOrder);
		msgLong.text = string.format("%s #%d", msgLong.text, rRoll.nOrder);
	end
	if (rRoll.sRange or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sRange);
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sRange);
	end
	if (rRoll.sLabel or "") ~= "" then
		msgShort.text = string.format("%s (%s)", msgShort.text, rRoll.sLabel or "");
		msgLong.text = string.format("%s (%s)", msgLong.text, rRoll.sLabel or "");
	end
	msgLong.text = string.format("%s [%d]", msgLong.text, rRoll.nTotal or 0);
	
	-- Targeting information
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

	-- Extra roll information
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
--	CRIT STATE TRACKING
--

aCritState = {};
function setCritState(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end
	
	if not aCritState[sSourceCT] then
		aCritState[sSourceCT] = {};
	end
	table.insert(aCritState[sSourceCT], sTargetCT);
end
function clearCritState(rSource)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT ~= "" then
		aCritState[sSourceCT] = nil;
	end
end
function isCrit(rSource, rTarget)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	local sTargetCT = "";
	if rTarget then
		sTargetCT = ActorManager.getCTNodeName(rTarget);
	end

	if not aCritState[sSourceCT] then
		return false;
	end
	
	for k,v in ipairs(aCritState[sSourceCT]) do
		if v == sTargetCT then
			table.remove(aCritState[sSourceCT], k);
			return true;
		end
	end
	
	return false;
end