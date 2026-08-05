--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	if nodeChar then
		DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", self.onDataChanged);
	end
	if nodeSkill then
		DB.addHandler(DB.getPath(nodeSkill, "stat"), "onUpdate", self.onDataChanged);
	end

	self.onDataChanged();
end

function onClose()
	if super and super.onClose then
		super.onClose();
	end

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	if nodeChar then
		DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", self.onDataChanged);
	end
	if nodeSkill then
		DB.removeHandler(DB.getPath(nodeSkill, "stat"), "onUpdate", self.onDataChanged);
	end
end

function onDataChanged()
	if super and super.onDataChanged then
		super.onDataChanged();
	end

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	local sStat = DB.getValue(nodeSkill, "stat", "");
	local nScore = ActorManager5E.getAbilityScore(rActor, sStat);

	self.setValue(nScore);
end
