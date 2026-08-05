--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local nodeSkill = window.getDatabaseNode();
	if nodeSkill then
		DB.addHandler(DB.getPath(nodeSkill, "misc"), "onUpdate", self.onDataChanged);
		DB.addHandler(DB.getPath(nodeSkill, "name"), "onUpdate", self.onDataChanged);
	end

	self.onDataChanged();
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end

	local nodeSkill = window.getDatabaseNode();
	if nodeSkill then
		DB.removeHandler(DB.getPath(nodeSkill, "misc"), "onUpdate", self.onDataChanged);
		DB.removeHandler(DB.getPath(nodeSkill, "name"), "onUpdate", self.onDataChanged);
	end
end

function onDataChanged()
	if super and super.onDataChanged then
		super.onDataChanged();
	end

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	local sSkill = DB.getValue(nodeSkill, "name", "");
	local nRank = ActorManager5E.getSkillRank(rActor, sSkill);

	self.setValue(nRank or 0);
end
