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
		"damagevulnerabilities", "damageresistances",
		"damageimmunities", "disablestandarddamageimmunities",
		"conditionimmunities", "disablestandardconditionimmunities",
	};
	WindowManager.callSafeControlsUpdate(self, tFields, bReadOnly);

	local bShowDmgImmune = not bReadOnly or (not damageimmunities.isEmpty() or not disablestandarddamageimmunities.isEmpty());
	damageimmunities.setVisible(bShowDmgImmune);
	disablestandarddamageimmunities.setVisible(bShowDmgImmune);
	damageimmunities_label.setVisible(bShowDmgImmune);

	if conditionimmunities then
		local bShowCondImmune = not bReadOnly or (not conditionimmunities.isEmpty() or not disablestandardconditionimmunities.isEmpty());
		conditionimmunities.setVisible(bShowCondImmune);
		disablestandardconditionimmunities.setVisible(bShowCondImmune);
		conditionimmunities_label.setVisible(bShowCondImmune);
	end

	local bShow = WindowManager.getAnyControlVisible(self, tFields);
	parentcontrol.setVisible(bShow);
end
