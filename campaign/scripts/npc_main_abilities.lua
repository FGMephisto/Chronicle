--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local tFields = {
		"strength", "dexterity", "constitution",
		"intelligence", "wisdom", "charisma",
	};
	WindowManager.callSafeControlsUpdate(self, tFields, bReadOnly);

	self.updateVehicleAbilities(bReadOnly);
end

function updateVehicleAbilities(bReadOnly)
	local sRecordType = RecordDataManager.getRecordTypeFromWindow(WindowManager.getTopWindow(self));
	if sRecordType ~= "vehicle" then
		return;
	end

	local bShow = not bReadOnly or
			((strength.getValue() ~= 10) or (constitution.getValue() ~= 10) or (dexterity.getValue() ~= 10) or
			(intelligence.getValue() ~= 0) or (wisdom.getValue() ~= 0) or (charisma.getValue() ~= 0));
	parentcontrol.setVisible(bShow);
end

-- 2024 only
function onAbilityChanged(sAbility)
	local n = self[sAbility].getValue();
	local nMod = math.floor((n - 10) / 2);
	self[sAbility .. "mod"].setValue(nMod);
	local nSave = nMod + self[sAbility .. "savemod"].getValue();
	self[sAbility .. "save"].setValue(nSave);
end
