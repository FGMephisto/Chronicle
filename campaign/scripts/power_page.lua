--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local aGroups = {};
local aCharSlots = {};

function onInit()
	self.updatePowerGroups();

	local node = getDatabaseNode();

	DB.addHandler(DB.getPath(node, "level"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "abilities.*.score"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.stat"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkstat"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkprof"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.atkmod"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.savestat"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.saveprof"), "onUpdate", self.onAbilityChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.savemod"), "onUpdate", self.onAbilityChanged);

	DB.addHandler(DB.getPath(node, "powergroup"), "onChildAdded", self.onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup"), "onChildDeleted", self.onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", self.onGroupNameChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.castertype"), "onUpdate", self.onGroupTypeChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.prepared"), "onUpdate", self.onGroupTypeChanged);

	DB.addHandler(DB.getPath(node, "powergroup.*.uses"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.usesperiod"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots1"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots2"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots3"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots4"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots5"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots6"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots7"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots8"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.slots9"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powers.*.cast"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powers.*.prepared"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powermeta.*.max"), "onUpdate", self.onUsesChanged);
	DB.addHandler(DB.getPath(node, "powermeta.*.used"), "onUpdate", self.onUsesChanged);

	DB.addHandler(DB.getPath(node, "powers.*.group"), "onUpdate", self.onPowerGroupChanged);
	DB.addHandler(DB.getPath(node, "powers.*.level"), "onUpdate", self.onPowerGroupChanged);
end
function onClose()
	local node = getDatabaseNode();

	DB.removeHandler(DB.getPath(node, "level"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "abilities.*.score"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.stat"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkstat"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkprof"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.atkmod"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.savestat"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.saveprof"), "onUpdate", self.onAbilityChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.savemod"), "onUpdate", self.onAbilityChanged);

	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildAdded", self.onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildDeleted", self.onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", self.onGroupNameChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.castertype"), "onUpdate", self.onGroupTypeChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.prepared"), "onUpdate", self.onGroupTypeChanged);

	DB.removeHandler(DB.getPath(node, "powergroup.*.uses"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.usesperiod"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots1"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots2"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots3"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots4"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots5"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots6"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots7"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots8"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.slots9"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.cast"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.prepared"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powermeta.*.max"), "onUpdate", self.onUsesChanged);
	DB.removeHandler(DB.getPath(node, "powermeta.*.used"), "onUpdate", self.onUsesChanged);

	DB.removeHandler(DB.getPath(node, "powers.*.group"), "onUpdate", self.onPowerGroupChanged);
	DB.removeHandler(DB.getPath(node, "powers.*.level"), "onUpdate", self.onPowerGroupChanged);
end

function onDrop(_, _, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		draginfo.setSlot(2);
		local sGroup = draginfo.getStringData();
		draginfo.setSlot(1);
		return CharPowerManager.addPowerDB(getDatabaseNode(), sClass, sRecord, sGroup);
	end
end

function onModeChanged()
	self.rebuildGroups();
	self.updateUses();
end
function onLockModeChanged()
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			v.onDisplayChanged();
		end
	end
end
function onAbilityChanged()
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			if v.header.subwindow and v.header.subwindow.actionsmini then
				for _,v2 in pairs(v.header.subwindow.actionsmini.getWindows()) do
					v2.onDataChanged();
				end
			end
			if v.actions then
				for _,v2 in pairs(v.actions.getWindows()) do
					v2.onDataChanged();
				end
			end
		end
	end
end
function onUsesChanged()
	self.rebuildGroups();
	self.updateUses();
end
function onGroupListChanged()
	self.updatePowerGroups();
end
function onGroupTypeChanged()
	self.updatePowerGroups();
end
function onGroupNameChanged(nodeGroupName)
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);

	local nodeParent = DB.getParent(nodeGroupName);
	local sNode = DB.getPath(nodeParent);

	local nodeGroup = nil;
	local sOldValue = "";
	for sGroup, vGroup in pairs(aGroups) do
		if vGroup.nodename == sNode then
			nodeGroup = vGroup.node;
			sOldValue = sGroup;
			break;
		end
	end
	if not nodeGroup then
		CharPowerManager.resumePowerGroupUpdates(nodeChar);
		return;
	end

	local sNewValue = DB.getValue(nodeParent, "name", "");
	for _,v in pairs(powers.getWindows()) do
		if v.group.getValue() == sOldValue then
			v.group.setValue(sNewValue);
		end
	end

	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	self.updatePowerGroups();
end
function onPowerListChanged()
	self.updatePowerGroups();
end
function onPowerGroupChanged()
	self.updatePowerGroups();
end

function addPower()
	return powers.createWindow(nil, true);
end
function addGroupPower(sGroup, nLevel)
	local w = powers.createWindow(nil, true);
	w.level.setValue(nLevel);
	w.group.setValue(sGroup);
	return w;
end

function updatePowerGroups()
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);

	self.rebuildGroups();

	-- Determine all the groups accounted for by current powers
	local aPowerGroups = {};
	for _,nodePower in ipairs(DB.getChildList(getDatabaseNode(), "powers")) do
		local sGroup = DB.getValue(nodePower, "group", "");
		if sGroup ~= "" then
			aPowerGroups[sGroup] = true;
		end
	end

	-- Remove the groups that already exist
	for sGroup,_ in pairs(aGroups) do
		if aPowerGroups[sGroup] then
			aPowerGroups[sGroup] = nil;
		end
	end

	-- For the remaining power groups, that aren't named
	local sLowerSpellsLabel = Interface.getString("char_spell_powergroup_base"):lower();
	for k,_ in pairs(aPowerGroups) do
		if not aGroups[k] then
			local nodeGroups = DB.createChild(getDatabaseNode(), "powergroup");
			local nodeNewGroup = DB.createChild(nodeGroups);
			DB.setValue(nodeNewGroup, "name", "string", k);
			if sLowerSpellsLabel == k:lower() then
				DB.setValue(nodeNewGroup, "castertype", "string", "memorization");
			end
		end
	end

	self.rebuildGroups();

	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	self.updateHeaders();
	self.updateUses();
end
function updateHeaders()
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);

	-- Close all category headings
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			v.close();
		end
	end

	-- Create new category headings
	local aCategoryWindows = {};
	local aGroupShown = {};
	for _,nodePower in ipairs(DB.getChildList(getDatabaseNode(), "powers")) do
		local sCategory, sGroup, nLevel = self.getWindowSortByNode(nodePower);

		if not aCategoryWindows[sCategory] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderCategory(aGroups[sGroup], sGroup, nLevel);
			end
			aCategoryWindows[sCategory] = wh;
			aGroupShown[sGroup] = true;
		end
	end

	-- Create empty category headings
	for k,v in pairs(aGroups) do
		if not aGroupShown[k] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderCategory(v, k, nil, true);
			end
		end
	end

	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	powers.applySort();
end

function onPowerWindowAdded(w)
	self.updatePowerWindowUses(getDatabaseNode(), w);
end
function updatePowerWindowUses(nodeChar, w)
	local sMode = DB.getValue(nodeChar, "powermode", "");
	local bCombatMode = (sMode == "combat");
	local bShow = true;

	-- Get power information
	local sGroup = w.group.getValue();
	local nLevel = w.level.getValue();

	local nodePower = w.getDatabaseNode();
	local nCast = DB.getValue(nodePower, "cast", 0);
	local nPrepared = DB.getValue(nodePower, "prepared", 0);

	-- Get the power group, and whether it's a caster group
	local rGroup = aGroups[sGroup];
	local bCaster = (rGroup and rGroup.grouptype ~= "");

	-- Get group meta usage information
	local nAvailable = 0;
	local nTotalCast = 0;
	local nTotalPrepared = 0;
	if bCaster then
		if nLevel >= 1 and nLevel <= PowerManager.SPELL_LEVELS then
			nAvailable = aCharSlots[nLevel].nMax;
			nTotalCast = (aCharSlots[nLevel].nTotalCast or 0);
			nTotalPrepared = (aCharSlots[nLevel].nTotalPrepared or 0);
		end
	elseif rGroup then
		nAvailable = rGroup.nAvailable;
		nTotalCast = rGroup.nTotalCast;
		nTotalPrepared = rGroup.nTotalPrepared;
		sUsesPeriod = rGroup.sUsesPeriod;
	end

	-- SPELL CLASS
	if bCaster then
		if bCombatMode then
			if nLevel > 0 then
				if rGroup.nPrepared > 0 and nPrepared <= 0 then
					bShow = false;
				else
					local bValidSlot = false;
					for i = nLevel, PowerManager.SPELL_LEVELS do
						if (aCharSlots[i].nTotalCast or 0) < aCharSlots[i].nMax then
							bValidSlot = true;
							break;
						end
					end
					if not bValidSlot then
						bShow = false;
					end
				end
			else
				bShow = true;
			end
		else
			bShow = true;
		end

	-- ABILITY GROUP
	else
		if bCombatMode then
			if rGroup and (nTotalCast >= nAvailable) and (nAvailable > 0) then
				bShow = false;
			elseif (nCast >= nPrepared) and (nPrepared > 0) then
				bShow = false;
			end
		else
			bShow = true;
		end
	end
	w.setFilter(bShow);

	if bCaster then
		w.header.subwindow.prepared.setVisible(false);
		w.header.subwindow.usesperiod.setVisible(false);
		w.header.subwindow.counter.setVisible(false);
		if sMode == "preparation" then
			if nLevel == 0 then
				w.header.subwindow.preparedcheck.setVisible(false);
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.blank.setVisible(true);
			else
				if rGroup.nPrepared > 0 then
					w.header.subwindow.preparedcheck.setVisible(true);
					w.header.subwindow.blank.setVisible(false);
				else
					w.header.subwindow.preparedcheck.setVisible(false);
					w.header.subwindow.blank.setVisible(true);
				end
				w.header.subwindow.usepower.setVisible(false);
			end
		else
			w.header.subwindow.preparedcheck.setVisible(false);
			if (nLevel == 0) or (rGroup.nPrepared == 0) or (w.header.subwindow.preparedcheck.getValue() > 0) then
				w.header.subwindow.usepower.setVisible(true);
				w.header.subwindow.blank.setVisible(false);
			else
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.blank.setVisible(true);
			end
		end
	else
		w.header.subwindow.blank.setVisible(false);
		w.header.subwindow.preparedcheck.setVisible(false);
		if sMode == "preparation" then
			w.header.subwindow.prepared.setVisible(true);
			w.header.subwindow.usepower.setVisible(false);
			w.header.subwindow.counter.setVisible(false);
			if rGroup and (nAvailable > 0) then
				w.header.subwindow.usesperiod.setVisible(false);
			else
				w.header.subwindow.usesperiod.setVisible(true);
			end
		else
			w.header.subwindow.prepared.setVisible(false);
			w.header.subwindow.usesperiod.setVisible(false);
			if nAvailable > 0 then
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.counter.setVisible(true);
				if nPrepared > 0 then
					w.header.subwindow.counter.update(sMode, true, math.min(nAvailable, nPrepared), nTotalCast, nTotalPrepared);
				else
					w.header.subwindow.counter.update(sMode, true, nAvailable, nTotalCast, nTotalPrepared);
				end
			elseif nPrepared > 0 then
				w.header.subwindow.usepower.setVisible(false);
				w.header.subwindow.counter.setVisible(true);
				w.header.subwindow.counter.update(sMode, true, nPrepared, nCast, nPrepared);
			else
				w.header.subwindow.usepower.setVisible(true);
				w.header.subwindow.counter.setVisible(false);
			end
		end
	end

	return bShow;
end

function updateUses()
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerUsageUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerUsageUpdates(nodeChar);

	-- Prepare for lots of crunching
	local nodeChar = getDatabaseNode();
	local sMode = DB.getValue(nodeChar, "powermode", "");

	-- Add power counts, total cast and total prepared per group/slot
	for _,v in ipairs(DB.getChildList(nodeChar, "powers")) do
		local sGroup = DB.getValue(v, "group", "");
		local rGroup = aGroups[sGroup];
		if rGroup then
			local nCast = DB.getValue(v, "cast", 0);
			local nPrepared = DB.getValue(v, "prepared", 0);
			if rGroup.grouptype == "" then
				rGroup.nCount = (rGroup.nCount or 0) + 1;
				rGroup.nTotalCast = (rGroup.nTotalCast or 0) + nCast;
				rGroup.nTotalPrepared = (rGroup.nTotalPrepared or 0) + nPrepared;
			else
				local nLevel = DB.getValue(v, "level", 0);
				if nLevel >= 1 and nLevel <= PowerManager.SPELL_LEVELS then
					aCharSlots[nLevel].nCount = (aCharSlots[nLevel].nCount or 0) + 1;
					aCharSlots[nLevel].nTotalPrepared = (aCharSlots[nLevel].nTotalPrepared or 0) + math.min(nPrepared, 1);
				end
			end
		end
	end

	local aCasterGroupSpellsShown = {};

	-- Show/hide powers based on findings
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			if self.updatePowerWindowUses(nodeChar, v) then
				local sGroup = v.group.getValue();
				local rGroup = aGroups[sGroup];
				local bCaster = (rGroup and rGroup.grouptype ~= "");

				if bCaster then
					if not aCasterGroupSpellsShown[sGroup] then
						aCasterGroupSpellsShown[sGroup] = {};
					end
					local nLevel = v.level.getValue();
					aCasterGroupSpellsShown[sGroup][nLevel] = (aCasterGroupSpellsShown[sGroup][nLevel] or 0) + 1;
				elseif rGroup then
					rGroup.nShown = (rGroup.nShown or 0) + 1;
				end
			end
		end
	end

	-- Hide headers with no spells
	local bCombatMode = (sMode == "combat");
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			local sGroup = v.group.getValue();
			local rGroup = aGroups[sGroup];
			local bCaster = (rGroup and rGroup.grouptype ~= "");

			local bShow = true;

			if bCombatMode then
				if bCaster then
					local nLevel = v.level.getValue();
					if not aCasterGroupSpellsShown[sGroup] or (aCasterGroupSpellsShown[sGroup][nLevel] or 0) <= 0 then
						bShow = false;
					end
				elseif rGroup then
					bShow = ((rGroup.nShown or 0) > 0);
				end
			end

			v.setFilter(bShow);
		end
	end

	powers.applyFilter();

	CharPowerManager.resumePowerUsageUpdates(nodeChar);
end

--------------------------
-- POWER GROUP DISPLAY
--------------------------

function rebuildGroups()
	aGroups = {};
	aCharSlots = {};

	local nodeChar = getDatabaseNode();

	for _,v in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		local sGroup = DB.getValue(v, "name", "");
		local rGroup = {};
		rGroup.node = v;
		rGroup.nodename = DB.getPath(v);
		if sGroup == "" then
			rGroup.grouptype = "";
		else
			rGroup.grouptype = DB.getValue(v, "castertype", "");
		end

		if rGroup.grouptype == "memorization" then
			rGroup.nPrepared = DB.getValue(v, "prepared", 0);
		else
			rGroup.nAvailable = DB.getValue(v, "uses", 0);
		end

		rGroup.sUsesPeriod = DB.getValue(v, "usesperiod", "");

		aGroups[sGroup] = rGroup;
	end

	for i = 1, PowerManager.SPELL_LEVELS do
		aCharSlots[i] = {
			nMax = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0) + DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", 0),
			nTotalCast = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".used", 0) + DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".used", 0),
		};
	end
end

function getWindowSortByNode(node)
	local sGroup = DB.getValue(node, "group", "");
	local nLevel = DB.getValue(node, "level", 0);

	local sCategory = sGroup;
	if aGroups[sGroup] and aGroups[sGroup].grouptype ~= "" then
		sCategory = sCategory .. nLevel;
	else
		nLevel = 0;
	end

	return sCategory, sGroup, nLevel;
end
function getWindowSort(w)
	local sGroup = w.group.getValue();
	local nLevel = w.level.getValue();

	local sCategory = sGroup;
	if aGroups[sGroup] and aGroups[sGroup].grouptype ~= "" then
		sCategory = sCategory .. nLevel;
	end

	return sCategory;
end
function onSortCompare(w1, w2)
	local vCategory1 = self.getWindowSort(w1);
	local vCategory2 = self.getWindowSort(w2);
	if vCategory1 ~= vCategory2 then
		return vCategory1 > vCategory2;
	end

	local bIsHeader1 = (w1.getClass() == "power_group_header");
	local bIsHeader2 = (w2.getClass() == "power_group_header");
	if bIsHeader1 then
		return false;
	elseif bIsHeader2 then
		return true;
	end

	local sValue1 = DB.getValue(w1.getDatabaseNode(), "name", ""):lower();
	local sValue2 = DB.getValue(w2.getDatabaseNode(), "name", ""):lower();
	if sValue1 ~= sValue2 then
		return sValue1 > sValue2;
	end
end
