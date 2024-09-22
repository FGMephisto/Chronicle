-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function onSummonChanged()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	WindowManager.callSafeControlUpdate(self, "summon", bReadOnly);

	local bHideSummon = (DB.getValue(nodeRecord, "summon", 0) == 0);

	WindowManager.callSafeControlUpdate(self, "summon_level", bReadOnly, bHideSummon);
	WindowManager.callSafeControlUpdate(self, "summon_attack", bReadOnly, bHideSummon);
	WindowManager.callSafeControlUpdate(self, "summon_dc", bReadOnly, bHideSummon);
	WindowManager.callSafeControlUpdate(self, "summon_mod", bReadOnly, bHideSummon);
	WindowManager.callSafeControlUpdate(self, "summon_pb", bReadOnly, bHideSummon);

	WindowManager.callSafeControlUpdate(self, "summon_ac_base", bReadOnly, bReadOnly or bHideSummon);
	local bShowACMod = summon_ac_base.isVisible();
	summon_ac_plus_label.setVisible(bShowACMod);
	summon_ac_mod.setReadOnly(bReadOnly);
	summon_ac_mod.setVisible(bShowACMod);
	summon_ac_mod_label.setVisible(bShowACMod);

	WindowManager.callSafeControlUpdate(self, "summon_hp_base", bReadOnly, bReadOnly or bHideSummon);
	local bShowHPMod = summon_hp_base.isVisible();
	summon_hp_plus_label.setVisible(bShowHPMod);
	summon_hp_mod.setReadOnly(bReadOnly);
	summon_hp_mod.setVisible(bShowHPMod);
	summon_hp_mod_label.setVisible(bShowHPMod);
	summon_hp_mod_threshold.setReadOnly(bReadOnly);
	summon_hp_mod_threshold.setVisible(bShowHPMod);
end
