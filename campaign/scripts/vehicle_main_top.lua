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

	local tFields = { "ac", "actext", "hp", "damagethreshold", "mishapthreshold", "speed", };
	WindowManager.callSafeControlsUpdate(self, tFields, bReadOnly);

	local bShowAC = not bReadOnly or (ac.getValue() ~= 0) or (actext.getValue() ~= "");
	ac.setVisible(bShowAC);
	ac_label.setVisible(bShowAC);
	actext.setVisible(bShowAC);

	local bShowMishap = not bReadOnly or (mishapthreshold.getValue() ~= 0);
	mishapthreshold.setVisible(bShowMishap);
	mishapthreshold_label.setVisible(bShowMishap);
	local bShowDT = bShowMishap or not bReadOnly or (damagethreshold.getValue() ~= 0);
	damagethreshold.setVisible(bShowDT);
	damagethreshold_label.setVisible(bShowDT);

	parentcontrol.setVisible(WindowManager.getAnyControlVisible(self, tFields));
end
