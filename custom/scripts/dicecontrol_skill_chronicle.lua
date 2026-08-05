--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	local nodeSkill = window.getDatabaseNode();
	if self.stat then
		self.stat[1] = DB.getValue(nodeSkill, "stat", "");
	end
	if self.skill then
		self.skill[1] = DB.getValue(nodeSkill, "name", "");
	end
	super.onInit();
end
