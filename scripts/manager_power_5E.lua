--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManager5E.getPowerActorNode,
		fnParse = PowerManager5E.parsePower,
		fnUsePower = PowerManager5E.usePower,
		fnUpdateDisplay = PowerManager5E.updatePowerDisplay,
	};
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);

	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManager5E.getActionButtonIcons,
		fnGetText = PowerManager5E.getActionText,
		fnGetTooltip = PowerManager5E.getActionTooltip,
		fnPerform = PowerManager5E.performAction,
	};
	PowerActionManagerCore.registerActionType("", tPowerActionHandlers);
	PowerActionManagerCore.registerActionType("cast", {});
	PowerActionManagerCore.registerActionType("attack", {});
	PowerActionManagerCore.registerActionType("powersave", {});
	PowerActionManagerCore.registerActionType("damage", {});
	PowerActionManagerCore.registerActionType("heal", {});
	PowerActionManagerCore.registerActionType("effect", {});
end

--
--	POWER HANDLING
--

function getPowerActorNode(node)
	return DB.getChild(node, "...");
end
function usePower(nodePower)
	local rActor = PowerManager5E.getPowerActorNode(nodePower);
	PowerManager5E.resetPower(rActor, nodePower);
	PowerManager5E.performPower(rActor, nodePower);
end
function parsePower(node)
	PowerManager.parsePCPower(node);
end
function updatePowerDisplay(w)
	if not w.header or not w.header.subwindow then
		return;
	end
	if not w.header.subwindow.group or not w.header.subwindow.actionsmini then
		return;
	end

	local bReadOnly = WindowManager.getWindowReadOnlyState(w);
	w.header.subwindow.group.setVisible(not bReadOnly);
	w.header.subwindow.actionsmini.setVisible(bReadOnly);
end

function onUsePowerHover(cUsePower, bOnControl)
	if not bOnControl then
		return;
	end
	local tTooltip = { Interface.getString("power_tooltip_use"), };

	local nodePower = cUsePower.window.getDatabaseNode();
	local nUpcast = PowerManager5E.getSpellUpcast(nodePower);
	if nUpcast > 0 then
		table.insert(tTooltip, string.format("%s: %+d", Interface.getString("power_tooltip_use_upcast"), nUpcast))
	end
	local tSelections = ActionsChoiceManager.getPowerChoiceSelectionsDisplayList(nodePower);
	if #tSelections > 0 then
		table.insert(tTooltip, string.format("%s:", Interface.getString("power_tooltip_use_choice")));
		for _,s in ipairs(tSelections) do
			table.insert(tTooltip, "    " .. s);
		end
	end

	cUsePower.setTooltipText(table.concat(tTooltip, "\r"));
end

function getSpellCantripBoost(rActor)
	local nCharLevel = ActorManager5E.getAbilityScore(rActor, "lvl");
	return math.max(math.floor((nCharLevel + 1) / 6), 0);
end

function getSpellUpcast(nodePower)
	if not nodePower then
		return 0;
	end
	return DB.getValue(nodePower, "upcast", 0);
end
function setSpellUpcast(nodePower, nUpcast)
	if not nodePower then
		return;
	end
	DB.setValue(nodePower, "upcast", "number", nUpcast);
end
function clearSpellUpcast(nodePower)
	if not nodePower then
		return;
	end
	DB.setValue(nodePower, "upcast", "number", 0);
end
function deleteSpellUpcast(nodePower)
	if not nodePower then
		return;
	end
	DB.deleteChild(nodePower, "upcast");
end

function getPowerTags(nodePower, sAutoKey)
	if not nodePower then
		return {};
	end

	local tPowerTags = {};

	local sSchool = StringManager.trim(DB.getValue(nodePower, "school", "")):lower():match("^%w+");
	if StringManager.contains(DataCommon.spellschools, sSchool) then
		table.insert(tPowerTags, sSchool);
	end

	for _, nodeAction in ipairs(DB.getChildList(nodePower, "actions")) do
		local sType = DB.getValue(nodeAction, "type", "");
		if StringManager.contains({ "damage", "effect", }, sType) and (((sAutoKey or "") == "") or (DB.getValue(nodeAction, "autokey", "") == sAutoKey)) then
			if sType == "damage" then
				for _,v in ipairs(UtilityManager.getNodeSortedChildren(nodeAction, "damagelist")) do
					local sDmgType = DB.getValue(v, "type", ""):lower();
					for _,s in ipairs(StringManager.splitByPattern(sDmgType, ",", true)) do
						if ActionCore.isDamageType(s) then
							table.insert(tPowerTags, s);
						end
					end
				end
			elseif sType == "effect" then
				local tEffectComps = EffectManager.parseEffect(EffectVarManager.getEffectVarFromNode(nodeAction, "sName", ""));
				for _,sComp in ipairs(tEffectComps) do
					local sLower = sComp:lower();
					if ActionCore.isCondition(sLower) then
						table.insert(tPowerTags, sLower);
					end
				end
			end
		end
	end

	return tPowerTags;
end
function getPowerTagsFromActions(tActions)
	local tPowerTags = {};
	for _,tActionData in ipairs(tActions or {}) do
		if tActionData.type == "damage" then
			for _,tClause in ipairs(tActionData.clauses) do
				for _,s in ipairs(StringManager.splitByPattern(tClause.dmgtype, ",", true)) do
					if ActionCore.isDamageType(s) then
						table.insert(tPowerTags, s);
					end
				end
			end
		elseif tActionData.type == "effect" then
			for _,sComp in ipairs(EffectManager.parseEffect(tActionData.sName)) do
				local sLower = sComp:lower();
				if ActionCore.isCondition(sLower) then
					table.insert(tPowerTags, sLower);
				end
			end
		end
	end
	return tPowerTags;
end

function doesPowerActionRequireTargets(nodeAction)
	if not nodeAction then
		return false;
	end

	local sActionType = DB.getValue(nodeAction, "type", "");
	if sActionType == "attack" then
		if (DB.getValue(nodeAction, "atktype", "") ~= "") then
			return true;
		end
	elseif sActionType == "powersave" then
		if (DB.getValue(nodeAction, "savetype", "") ~= "") then
			return true;
		end
	elseif sActionType == "damage" then
		return true;
	elseif sActionType == "heal" then
		if DB.getValue(nodeAction, "healtargeting", "") ~= "self" then
			return true;
		end
	elseif sActionType == "effect" then
		if DB.getValue(nodeAction, "targeting", "") ~= "self" then
			return true;
		end
	end
	return false;
end
function notifySpellCastNoTargets(rActor, nodePower)
	local sName = DB.getValue(nodePower, "name", "");
	local s = string.format(Interface.getString("message_actor_cast_notargets"), sName);
	ChatManager.sendMessage(s, { rActor = rActor, sIcon = "action_warning", });
end
function notifySpellCastNoSlots(rActor, nodePower)
	local sName = DB.getValue(nodePower, "name", "");
	local nLevel = DB.getValue(nodePower, "level", 0);
	local s = string.format(Interface.getString("message_actor_cast_noslots"), sName, StringManager.convertNumberToOrdinal(nLevel));
	ChatManager.sendMessage(s, { rActor = rActor, sIcon = "action_warning", });
end

-- resetPower(rActor, nodePower)
function resetPower(_, nodePower)
	if not nodePower then
		return;
	end
	PowerManager5E.clearSpellUpcast(nodePower);
	ActionsChoiceManager.deletePowerChoiceSelections(nodePower);
end
function performPower(rActor, nodePower)
	if not nodePower then
		return;
	end
	local tPowerData = PowerManager5E.buildPerformPowerData(rActor, nodePower, "default", true);
	if tPowerData then
		PowerManager5E.performPowerInternal(rActor, tPowerData);
	else
		PowerManagerCore.performDefaultPowerUse(nodePower);
	end
end
function performPowerAction(nodeAction)
	if not nodeAction then
		return;
	end
	local nodePower = DB.getChild(nodeAction, "...");
	local rActor = PowerManagerCore.getPowerActor(nodePower);
	local sAutoKey = DB.getValue(nodeAction, "autokey", "");
	if sAutoKey == "" then
		local tData = { rActor = rActor, };
		local rAction = PowerManager.getPowerAction(nodeAction, tData);
		if rAction then
			PowerManager.evalAction(rActor, nodePower, rAction);
			PowerManager.performAction(nil, rActor, rAction, nodePower);
		end
		return;
	end
	local tPowerData = PowerManager5E.buildPerformPowerData(rActor, nodePower, sAutoKey);
	PowerManager5E.handlePerformPowerDataSolo(rActor, nodeAction, tPowerData);
	PowerManager5E.performPowerInternal(rActor, tPowerData);
end

function buildPerformPowerData(rActor, nodePower, sAutoKey, bNewCast)
	local tPowerData = {
		nodePower = nodePower,
		nPowerLevel = DB.getValue(nodePower, "level", 0),
		bRitual = (DB.getValue(nodePower, "ritual", 0) == 1),
		bNewCast = bNewCast,
		sAutoKey = sAutoKey or "",
		tPowerTags = PowerManager5E.getPowerTags(nodePower, sAutoKey)
	};
	PowerManager5E.buildPerformPowerDataActions(rActor, tPowerData);
	if bNewCast and (#(tPowerData.tActionQueue) == 0) then
		return nil;
	end
	PowerManager5E.buildPerformPowerDataTargeting(rActor, tPowerData);
	PowerManager5E.buildPerformPowerSlotData(rActor, tPowerData);
	return tPowerData;
end
-- buildPerformPowerDataActions(rActor, tPowerData)
function buildPerformPowerDataActions(_, tPowerData)
	if not tPowerData then
		return;
	end

	tPowerData.tActionQueue = {};

	local nodeCast = PowerManager.getFirstActionOfType(tPowerData.nodePower, "cast", tPowerData.sAutoKey);
	if nodeCast then
		table.insert(tPowerData.tActionQueue, { sType = "cast", node = nodeCast, bPower = true, tActionTags = tPowerData.tPowerTags, sTargeting = "none", });
		tPowerData.tCastTargeting = {
			sTargeting = DB.getValue(nodeCast, "targeting", ""),
			nTargetingVal = DB.getValue(nodeCast, "targetingval", 0),
			nTargetingVal2 = DB.getValue(nodeCast, "targetingval2", 0),
			sTargetScaleStat = DB.getValue(nodeCast, "targetscalestat", ""),
			nTargetScaleMult = DB.getValue(nodeCast, "targetscalemult", 0),
		};
	end
	local nodeFirstCast = PowerManager.getFirstActionOfType(tPowerData.nodePower, "cast", "default");
	if nodeFirstCast then
		tPowerData.bAllowUpcast = (DB.getValue(nodeFirstCast, "allowupcast", 0) == 1);
		if not tPowerData.tCastTargeting or (tPowerData.tCastTargeting.sTargeting == "") then
			tPowerData.tCastTargeting = {
				sTargeting = DB.getValue(nodeFirstCast, "targeting", ""),
				nTargetingVal = DB.getValue(nodeFirstCast, "targetingval", 0),
				nTargetingVal2 = DB.getValue(nodeFirstCast, "targetingval2", 0),
				sTargetScaleStat = DB.getValue(nodeFirstCast, "targetscalestat", ""),
				nTargetScaleMult = DB.getValue(nodeFirstCast, "targetscalemult", 0),
			};
		end
	end

	local tActionNodes = WindowManager.getSortedNodesByOrder(tPowerData.nodePower, "actions");

	-- First, perform self actions
	for _, nodeAction in ipairs(tActionNodes) do
		local sActionAutoKey = DB.getValue(nodeAction, "autokey", "");
		if (sActionAutoKey == (tPowerData.sAutoKey or "")) then
			local sActionType = DB.getValue(nodeAction, "type", "");
			if StringManager.contains({ "heal", "effect", }, sActionType) then
				if ((sActionType == "heal") and (DB.getValue(nodeAction, "healtargeting", "") == "self")) or
						((sActionType == "effect") and (DB.getValue(nodeAction, "targeting", "") == "self")) then
					local tActionQueueEntry = {
						sType = sActionType,
						node = nodeAction,
						bPower = true,
						sAuto = DB.getValue(nodeAction, "auto", ""),
						tActionTags = tPowerData.tPowerTags,
						sTargeting = "self",
					};
					table.insert(tPowerData.tActionQueue, tActionQueueEntry);
				end
			end
		end
	end
	-- Then, perform targeted actions
	local sAutoResult = nil;
	for _, nodeAction in ipairs(tActionNodes) do
		local sActionAutoKey = DB.getValue(nodeAction, "autokey", "");
		if (sActionAutoKey == (tPowerData.sAutoKey or "")) then
			local sActionType = DB.getValue(nodeAction, "type", "");
			if (sActionType ~= "cast") and PowerActionManagerCore.isActionType(sActionType) then
				if ((sActionType == "heal") and (DB.getValue(nodeAction, "healtargeting", "") == "self")) or
						((sActionType == "effect") and (DB.getValue(nodeAction, "targeting", "") == "self")) then
					-- ALREADY HANDLED SELF ACTIONS
				else
					local tActionQueueEntry = {
						sType = sActionType,
						node = nodeAction,
						bPower = true,
						sAuto = DB.getValue(nodeAction, "auto", ""),
						sOpposed = GameManager.getActionProperty(sActionType, "sOpposed"),
						tActionTags = tPowerData.tPowerTags,
					};
					if tActionQueueEntry.sAuto == "" then
						tActionQueueEntry.sAuto = sAutoResult;
					end
					if sActionType == "damage" then
						tActionQueueEntry.sTargeting = ((tPowerData.tCastTargeting and tPowerData.tCastTargeting.sTargeting or "") == "multihit") and "each" or "";
					elseif sActionType == "effect" then
						tActionQueueEntry.sTargeting = DB.getValue(nodeAction, "targeting", "");
					end

					table.insert(tPowerData.tActionQueue, tActionQueueEntry);
				end
			end

			if sActionType == "cast" then
				sAutoResult = nil;
			elseif sActionType == "attack" then
				sAutoResult = (DB.getValue(nodeAction, "onmissdamage", "") == "half") and "" or "hit";
			elseif sActionType == "powersave" then
				sAutoResult = (DB.getValue(nodeAction, "onmissdamage", "") == "half") and "" or "failure";
			end
		end
	end
end
function buildPerformPowerDataTargeting(rActor, tPowerData)
	if not tPowerData then
		return;
	end

	tPowerData.tTargets = TargetingManager.getFullTargets(rActor);

	tPowerData.bRequireTargets = false;
	for _,tActionQueueEntry in ipairs(tPowerData.tActionQueue) do
		if PowerManager5E.doesPowerActionRequireTargets(tActionQueueEntry.node) then
			tPowerData.bRequireTargets = true;
		end
	end
end
function buildPerformPowerSlotData(rActor, tPowerData)
	if not rActor or not tPowerData or not tPowerData.bNewCast then
		return;
	end
	if tPowerData.nPowerLevel <= 0 then
		return;
	end
	local rPowerGroup = PowerManager.getPowerGroupRecord(rActor, tPowerData.nodePower);
	if not rPowerGroup or ((rPowerGroup.sCasterType or "") ~= "memorization") then
		return;
	end

	local tSlotData = {
		tSlotsAvail = {},
		tPactSlotsAvail = {},
		nActiveCount = 0,
		tActiveLevels = {},
		bPactOnly = true,
		tCharLevels = {},
	};
	local nodeActor = ActorManager.getCreatureNode(rActor);
	for i = 1, PowerManager.SPELL_LEVELS do
		local nSlotsMax = DB.getValue(nodeActor, "powermeta.spellslots" .. i .. ".max", 0);
		local nSlotsUsed = DB.getValue(nodeActor, "powermeta.spellslots" .. i .. ".used", 0);
		tSlotData.tSlotsAvail[i] = math.max(nSlotsMax - nSlotsUsed, 0);
		if nSlotsMax > 0 then
			tSlotData.bPactOnly = false;
		end
		local nPactSlotsMax = DB.getValue(nodeActor, "powermeta.pactmagicslots" .. i .. ".max", 0);
		local nPactSlotsUsed = DB.getValue(nodeActor, "powermeta.pactmagicslots" .. i .. ".used", 0);
		tSlotData.tPactSlotsAvail[i] = math.max(nPactSlotsMax - nPactSlotsUsed, 0);
		tSlotData.tCharLevels[i] = ((nSlotsMax > 0) or (nPactSlotsMax > 0));
	end

	for i = 1, PowerManager.SPELL_LEVELS do
		if i >= tPowerData.nPowerLevel then
			local bAvailableSlots = (tSlotData.tSlotsAvail[i] > 0) or (tSlotData.tPactSlotsAvail[i] > 0);
			tSlotData.tActiveLevels[i] = bAvailableSlots;
			if bAvailableSlots then
				tSlotData.nActiveCount = tSlotData.nActiveCount + 1;
				if not tSlotData.nFirstActiveLevel then
					tSlotData.nFirstActiveLevel = i;
				end
			end
		else
			tSlotData.tActiveLevels[i] = false;
		end
	end
	tPowerData.tSlotData = tSlotData;
end
-- handlePerformPowerDataSolo(rActor, nodeAction, tPowerData)
function handlePerformPowerDataSolo(_, nodeAction, tPowerData)
	if not tPowerData or not nodeAction then
		return;
	end
	if DB.getValue(nodeAction, "type", "") == "cast" then
		return;
	end

	tPowerData.nodeSoloAction = nodeAction;
	tPowerData.bRequireTargets = PowerManager5E.doesPowerActionRequireTargets(nodeAction);
end

function performPowerInternal(rActor, tPowerData)
	if not tPowerData then
		return;
	end

	-- Targeting Check
	if not PowerManager5E.handleTargetSelection(rActor, tPowerData) then
		return;
	end

	-- Spell Slot Select
	if not PowerManager5E.handleSpellSlotSelection(rActor, tPowerData) then
		return;
	end

	-- Spell Choices
	if not PowerManager5E.handlePowerChoices(rActor, tPowerData) then
		return;
	end

	-- Spell Slot Use
	if not PowerManager5E.handleSpellSlotUsage(rActor, tPowerData) then
		return;
	end

	-- Finalize any behaviors based on selections
	PowerManager5E.performPowerFinalize(rActor, tPowerData);

	-- Concentration Handling
	PowerManager5E.handlePowerConcOverride(rActor, tPowerData);

	-- Power Action
	if tPowerData.nodeSoloAction then
		for _,tActionQueueEntry in ipairs(tPowerData.tActionQueue) do
			if tPowerData.nodeSoloAction == tActionQueueEntry.node then
				tActionQueueEntry.sAuto = "";
				ActionsPerformManager.performActionQueue(rActor, tPowerData.tTargets, { tActionQueueEntry });
				return;
			end
		end
	else
		ActionsPerformManager.performActionQueue(rActor, tPowerData.tTargets, tPowerData.tActionQueue);
	end
end

-- TODO - Build targeting UI to select targets, if no targets
--			(requires visibility check API)
--			(requires spell data for # targets, or shape (any targets), ...)
function handleTargetSelection(rActor, tPowerData)
	if not tPowerData then
		return true;
	end

	if tPowerData.bRequireTargets and (#(tPowerData.tTargets) == 0) then
		PowerManager5E.notifySpellCastNoTargets(rActor, tPowerData.nodePower);
		return false;
	end

	return true;
end

function handleSpellSlotSelection(rActor, tPowerData)
	if not tPowerData or tPowerData.bSlotSelected or not tPowerData.bNewCast or not tPowerData.tSlotData then
		return true;
	end

	-- Check for valid spell slots available
	if tPowerData.tSlotData.nActiveCount <= 0 then
		PowerManager5E.notifySpellCastNoSlots(rActor, tPowerData.nodePower);
		return false;
	end

	-- If not ritual, then attempt to auto-select spell slot
	if not tPowerData.bRitual then
		-- If base level available, and it is the only spell level available (or Shift is pressed); then cast at the base level
		if (not tPowerData.bAllowUpcast or (tPowerData.tSlotData.nActiveCount == 1) or Input.isShiftPressed()) and ((tPowerData.tSlotData.nFirstActiveLevel or 0) == tPowerData.nPowerLevel) then
			tPowerData.bSlotSelected = true;
			return true;
		-- If pact magic slots only, automatically cast at the power level of the first
		elseif tPowerData.tSlotData.bPactOnly then
			PowerManager5E.setSpellUpcast(tPowerData.nodePower, math.max((tPowerData.tSlotData.nFirstActiveLevel or 0) - tPowerData.nPowerLevel, 0));
			tPowerData.bSlotSelected = true;
			return true;
		end
	end

	-- Otherwise, open spell slots selection dialog
	PowerManager5E.queryPowerSelection(rActor, "power_upcast", tPowerData);
	return false;
end
function handleSpellSlotManualSelection(rActor, tPowerData, nSlot)
	if not rActor or not tPowerData or (type(tPowerData.nodePower) ~= "databasenode") then
		return;
	end

	if nSlot < 0 then
		PowerManager5E.setSpellUpcast(tPowerData.nodePower, -1);
	else
		PowerManager5E.setSpellUpcast(tPowerData.nodePower, math.max(nSlot - tPowerData.nPowerLevel, 0));
	end
	tPowerData.bSlotSelected = true;
	PowerManager5E.performPowerInternal(rActor, tPowerData);
end

function handlePowerChoices(rActor, tPowerData)
	if not tPowerData or tPowerData.bChoicesSelected then
		return true;
	end

	tPowerData.tChoices = ActionsChoiceManager.getPowerChoices(tPowerData.nodePower, tPowerData.sAutoKey);
	if #(tPowerData.tChoices) <= 0 then
		tPowerData.bChoicesSelected = true;
		return true;
	end

	tPowerData.tChoiceSelections = ActionsChoiceManager.getPowerChoiceSelections(tPowerData.nodePower, tPowerData.sAutoKey);
	if not tPowerData.bNewCast then
		if (#(tPowerData.tChoiceSelections) >= #(tPowerData.tChoices)) then
			for _,tSelections in ipairs(tPowerData.tChoiceSelections) do
				if tSelections.sTag == "__autokey" then
					local sNewAutoKey = tSelections[1] or "";
					if sNewAutoKey ~= tPowerData.sAutoKey then
						tPowerData.sAutoKey = sNewAutoKey;
						PowerManager5E.buildPerformPowerDataActions(rActor, tPowerData);
						PowerManager5E.performPowerInternal(rActor, tPowerData);
						return false;
					end
				end
			end

			tPowerData.bChoicesSelected = true;
			return true;
		end
	end

	PowerManager5E.queryPowerSelection(rActor, "power_choice", tPowerData);
	return false;
end
function handlePowerChoiceSelectionsComplete(rActor, tPowerData)
	if not rActor or not tPowerData or (type(tPowerData.nodePower) ~= "databasenode") then
		return;
	end

	ActionsChoiceManager.setPowerChoiceSelections(tPowerData.nodePower, tPowerData.tChoiceSelections);

	for _,tSelections in ipairs(tPowerData.tChoiceSelections) do
		if tSelections.sTag == "__autokey" then
			local sNewAutoKey = tSelections[1] or "";
			if sNewAutoKey ~= tPowerData.sAutoKey then
				tPowerData.sAutoKey = sNewAutoKey;
				PowerManager5E.buildPerformPowerDataActions(rActor, tPowerData);
				PowerManager5E.performPowerInternal(rActor, tPowerData);
				return;
			end
		end
	end

	-- Continue processing
	tPowerData.bChoicesSelected	= true;
	PowerManager5E.performPowerInternal(rActor, tPowerData);
end

function handleSpellSlotUsage(rActor, tPowerData)
	if not tPowerData or not tPowerData.bNewCast or not tPowerData.tSlotData then
		return true;
	end
	if not tPowerData or not tPowerData.tSlotData then
		return true;
	end
	if tPowerData.nPowerLevel <= 0 then
		return true;
	end

	-- Consume a spell slot (unless upcast is -1, which indicates ritual)
	local nUpcast = PowerManager5E.getSpellUpcast(tPowerData.nodePower);
	if nUpcast < 0 then
		return true;
	end
	if PowerManager5E.consumeSpellSlot(rActor, tPowerData.nPowerLevel + nUpcast) then
		return true;
	end

	PowerManager5E.notifySpellCastNoSlots(rActor, tPowerData.nodePower);
	return false;
end
function consumeSpellSlot(rActor, n)
	if ((n or 0) < 1) or ((n or 0) > PowerManager.SPELL_LEVELS) then
		return false;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);

	local nSlotsMax = DB.getValue(nodeActor, "powermeta.spellslots" .. n .. ".max", 0);
	local nSlotsUsed = DB.getValue(nodeActor, "powermeta.spellslots" .. n .. ".used", 0);
	if (nSlotsMax > 0) and (nSlotsUsed < nSlotsMax) then
		DB.setValue(nodeActor, "powermeta.spellslots" .. n .. ".used", "number", nSlotsUsed + 1);
		return true;
	end

	local nPactSlotsMax = DB.getValue(nodeActor, "powermeta.pactmagicslots" .. n .. ".max", 0);
	local nPactSlotsUsed = DB.getValue(nodeActor, "powermeta.pactmagicslots" .. n .. ".used", 0);
	if (nPactSlotsMax > 0) and (nPactSlotsUsed < nPactSlotsMax) then
		DB.setValue(nodeActor, "powermeta.pactmagicslots" .. n .. ".used", "number", nPactSlotsUsed + 1);
		return true;
	end

	return false;
end

function performPowerFinalize(rActor, tPowerData)
	if not tPowerData then
		return;
	end

	-- Handle multi-instance targeting
	if not tPowerData.nodeSoloAction and ((tPowerData.tCastTargeting and tPowerData.tCastTargeting.sTargeting or "") == "multihit") then
		tPowerData.nMultiHit = math.max(tPowerData.tCastTargeting.nTargetingVal, 1);
		if tPowerData.tCastTargeting.sTargetScaleStat == "cantrip" then
			tPowerData.nMultiHit = tPowerData.nMultiHit + (PowerManager5E.getSpellCantripBoost(rActor) * math.max(tPowerData.tCastTargeting.nTargetScaleMult, 1));
		elseif tPowerData.tCastTargeting.sTargetScaleStat == "upcast" then
			tPowerData.nMultiHit = tPowerData.nMultiHit + (PowerManager5E.getSpellUpcast(tPowerData.nodePower) * math.max(tPowerData.tCastTargeting.nTargetScaleMult, 1));
		end

		if #(tPowerData.tTargets) > 0 then
			local tNewTargets = {};
			for _ = 1, math.floor(tPowerData.nMultiHit / #(tPowerData.tTargets)) do
				for _,rTarget in ipairs(tPowerData.tTargets) do
					table.insert(tNewTargets, rTarget);
				end
			end
			for i = 1, (tPowerData.nMultiHit % #(tPowerData.tTargets)) do
				table.insert(tNewTargets, tPowerData.tTargets[i]);
			end
			tPowerData.tTargets = tNewTargets;
		end
	end
end

function handlePowerConcOverride(rActor, tPowerData)
	if not tPowerData or not tPowerData.bNewCast then
		return;
	end

	-- Check if power requires concentration
	if not PowerManager5E.hasPowerConc(tPowerData.nodePower) then
		return;
	end

	-- Check if actor is concentrating on any effects
	local tEffects = ActionSave.getConcentrationEffects(rActor);
	if #tEffects <= 0 then
		return;
	end

	ChatManager.sendMessage(Interface.getString("message_actor_cast_dropconc"), { rActor = rActor, sIcon = "action_info", });
	ActionSave.expireConcentrationEffects(rActor);
end
function hasPowerConc(nodePower)
	if not nodePower then
		return false;
	end
	if StringManager.trim(DB.getValue(nodePower, "duration", "")):lower():match("^concentration") then
		return true;
	end
	for _,nodeAction in pairs(DB.getChildren(nodePower, "actions")) do
		if DB.getValue(nodeAction, "type", "") == "effect" then
			if DB.getValue(nodeAction, "label", ""):match("%([cC]%)") then
				return true;
			end
		end
	end
	return false;
end

function queryPowerSelection(rActor, sClass, ...)
	if ActorManager.isPC(rActor) then
		local w = Interface.findWindow("charsheet", ActorManager.getCreatureNodeName(rActor));
		if w and (w.tabs.getActiveTabName() == "actions") then
			w.actions.subwindow.sub_query.setValue("", "");
			w.actions.subwindow.sub_query.setValue(sClass .. "_content", "");
			w.actions.subwindow.sub_query.subwindow.setData(rActor, ...);
			return;
		end
	end

	local w = Interface.openWindow(sClass, "");
	w.setData(rActor, ...);
end

--
--	ACTION HANDLING
--

function getActionButtonIcons(_, tData)
	if tData.sType == "cast" then
		return "button_roll", "button_roll_down";
	elseif tData.sType == "attack" then
		return "button_action_attack", "button_action_attack_down";
	elseif tData.sType == "powersave" then
		return "button_action_save", "button_action_save_down";
	elseif tData.sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif tData.sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif tData.sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(nodeAction, tData)
	return PowerManager.getActionText(nodeAction, tData);
end
function getActionTooltip(nodeAction, tData)
	return PowerManager.getActionTooltip(nodeAction, tData);
end
function performAction(nodeAction, tData)
	PowerManager.performPCPowerAction(tData.draginfo, nodeAction, tData and tData.sSubRoll);
end
