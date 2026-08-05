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

	local sCheck = DB.getName(nodeStat):lower();
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
	local nodeStat = getDatabaseNode();
	local sKey = DB.getName(nodeStat);
	if (sKey or "") == "" then
		sKey = DB.getValue(nodeStat, "name", "");
	end
	local wContents = nil;
	if windowlist and windowlist.window and windowlist.window.parentcontrol then
		wContents = windowlist.window.parentcontrol.window;
	end
	if wContents and wContents.filter then
		wContents.filter.setValue("");
	end
	if wContents and wContents.content_skills and wContents.content_skills.subwindow then
		local wSkillsMain = wContents.content_skills.subwindow;
		if wSkillsMain and wSkillsMain.filter_ability then
			local sCurrent = wSkillsMain.filter_ability.getValue();
			if sCurrent == sKey then
				wSkillsMain.filter_ability.setValue("");
			else
				wSkillsMain.filter_ability.setValue(sKey);
			end
		end
	end
end

function updateScore()
	local nodeStat = getDatabaseNode();
	local nScore = base.getValue() + bonus.getValue()

	if DB.getValue(nodeStat, "score") ~= nScore then DB.setValue(nodeStat, "score", "number", nScore) end;
end