--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("skill", ActionSkill.modRoll);
	ActionsManager.registerResultHandler("skill", ActionSkill.onRoll);
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function getRoll(rActor, nodeSkill)
	local rRoll = ActionsManager2.setupD20RollBuild("skill", rActor);
	ActionSkill.setupRollBuildFromNodePC(rRoll, rActor, nodeSkill);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, nodeSkill, nTargetDC, bSecretRoll)
	local rRoll = ActionSkill.getRoll(rActor, nodeSkill, nTargetDC, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end
function performPartySheetRoll(draginfo, rActor, sSkill)
	if not ActorManager.isPC(rActor) then
		return;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	local rRoll = nil;
	for _,v in ipairs(DB.getChildList(nodeActor, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			rRoll = ActionSkill.getRoll(rActor, v);
			break;
		end
	end
	if not rRoll then
		rRoll = ActionSkill.getUnlistedRoll(rActor, sSkill);
	end

	local nTargetDC = DB.getValue("partysheet.skilldc", 0);
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
function getUnlistedRoll(rActor, sSkill)
	local rRoll = ActionsManager2.setupD20RollBuild("skill", rActor);
	ActionSkill.setupRollBuildFromNamePC(rRoll, rActor, sSkill);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end

function getNPCRoll(rActor, sSkill, nSkill)
	local rRoll = ActionsManager2.setupD20RollBuild("skill", rActor);
	ActionSkill.setupRollBuildFromNameNPC(rRoll, rActor, sSkill, nSkill);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performNPCRoll(draginfo, rActor, sSkill, nSkill)
	local rRoll = ActionSkill.getNPCRoll(rActor, sSkill, nSkill);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	ActionCheck.modRoll(rSource, rTarget, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	ActionCheck.onRoll(rSource, rTarget, rRoll);
end

--
--	ROLL BUILDING HELPERS
--

function setupRollBuildFromNodePC(rRoll, rActor, nodeSkill)
	local sSkill = DB.getValue(nodeSkill, "name", "");
	local sAbility = DB.getValue(nodeSkill, "stat", "");

	local sAddText;
	rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getCheck(rActor, sAbility:lower(), sSkill);
	rRoll.nMod = rRoll.nMod + DB.getValue(nodeSkill, "misc", 0);

	table.insert(rRoll.tNotifications, ActionCore.encodeActionText({ label = sSkill, }, "action_skill_tag"));

	if DataCommon.skilldata[sSkill] then
		if sAbility ~= (DataCommon.skilldata[sSkill].stat or "") then
			table.insert(rRoll.tNotifications, string.format("[MOD:%s]", DataCommon.ability_ltos[sAbility] or ""));
		end
	else
		if sAbility ~= "" then
			table.insert(rRoll.tNotifications, string.format("[MOD:%s]", DataCommon.ability_ltos[sAbility]));
		end
	end

	local nodeChar = DB.getChild(nodeSkill, "...");
	local nProf = DB.getValue(nodeSkill, "prof", 0);
	if nProf == 1 then
		rRoll.nMod = rRoll.nMod + DB.getValue(nodeChar, "profbonus", 2);
		table.insert(rRoll.tNotifications, "[PROF]");
	elseif nProf == 2 then
		rRoll.nMod = rRoll.nMod + (2 * DB.getValue(nodeChar, "profbonus", 2));
		table.insert(rRoll.tNotifications, "[PROF x2]");
	elseif nProf == 3 then
		rRoll.nMod = rRoll.nMod + math.floor(DB.getValue(nodeChar, "profbonus", 2) / 2);
		table.insert(rRoll.tNotifications, "[PROF x1/2]");
	elseif ActorManager5E.hasRollFeature(rActor, CharManager.FEATURE_JACK_OF_ALL_TRADES) then
		rRoll.nMod = rRoll.nMod + math.floor(DB.getValue(nodeChar, "profbonus", 2) / 2);
		table.insert(rRoll.tNotifications, "[PROF x1/2]");
		table.insert(rRoll.tNotifications, string.format("[%s]", Interface.getString("roll_msg_feature_jackofalltrades")));
	end

	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end
end
function setupRollBuildFromNamePC(rRoll, rActor, sSkill)
	local sAddText;
	if DataCommon.skilldata[sSkill] then
		rRoll.sAbility = DataCommon.skilldata[sSkill].stat;
	end
	if rRoll.sAbility then
		rRoll.nMod, rRoll.bADV, rRoll.bDIS, sAddText = ActorManager5E.getCheck(rActor, rRoll.sAbility, sSkill);
	end

	table.insert(rRoll.tNotifications, ActionCore.encodeActionText({ label = sSkill, }, "action_skill_tag"));

	if (sAddText or "") ~= "" then
		table.insert(rRoll.tNotifications, sAddText);
	end
	if (rRoll.nMod or 0) ~= 0 then
		table.insert(rRoll.tNotifications, string.format(" [%+d]", rRoll.nMod));
	end
end
function setupRollBuildFromNameNPC(rRoll, _, sSkill, nSkill)
	table.insert(rRoll.tNotifications, ActionCore.encodeActionText({ label = sSkill, }, "action_skill_tag"));
	rRoll.nMod = nSkill;
end
