--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local nodeStat = getDatabaseNode();
	DB.addHandler(DB.getPath(nodeStat, "base"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeStat, "bonus"), "onUpdate", onDataChanged);

	self.onDataChanged()
end

function onClose()
	local nodeStat = getDatabaseNode();
	DB.removeHandler(DB.getPath(nodeStat, "base"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeStat, "bonus"), "onUpdate", onDataChanged);
end

function action(draginfo)
	local nodeStat = getDatabaseNode()

	local sCheck = nodeStat.getNodeName():lower();
	if DataCommon and DataCommon.ability_stol and DataCommon.ability_stol[sCheck:upper()] then
		sCheck = DataCommon.ability_stol[sCheck:upper()];
	elseif (sCheck or "") == "" then
		sCheck = DB.getValue(nodeStat, "name", ""):lower();
		if DataCommon and DataCommon.ability_stol and DataCommon.ability_stol[sCheck:upper()] then
			sCheck = DataCommon.ability_stol[sCheck:upper()];
		end
	end

	if (sCheck or "") == "" then
		return false;
	end

	local nodeChar = DB.getChild(nodeStat, "...")
	local rActor = ActorManager.resolveActor(nodeChar)
	ActionCheck.performRoll(draginfo, rActor, sCheck)

	return true
end

function onDataChanged()
	if ListManagerGroups and DataCommon and DataCommon.abilitygroups then
		ListManagerGroups.updateGroupID(self, DataCommon.abilitygroups);
	end
	self.updateScore();
end

function setFilter()
	local sKey = getDatabaseNode().getNodeName();
	local wContents = parentcontrol.window.parentcontrol.window;
	if wContents and wContents.stat_name_filter then
		local sCurrent = wContents.stat_name_filter.getValue();
		if sCurrent == sKey then
			wContents.stat_name_filter.setValue("");
		else
			wContents.stat_name_filter.setValue(sKey);
		end
	end
end

function updateScore()
	local nodeStat = getDatabaseNode();
	local nScore = base.getValue() + bonus.getValue()

	if DB.getValue(nodeStat, "score") ~= nScore then DB.setValue(nodeStat, "score", "number", nScore) end;
end