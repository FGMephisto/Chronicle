-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	super.onInit();
	OptionsManager.registerCallback("SHPC", updateHealthDisplay);
	OptionsManager.registerCallback("SHNPC", updateHealthDisplay);
	self.updateHealthDisplay();
end

-- ===================================================================================================================
-- ===================================================================================================================
function onClose()
	super.onClose();
	OptionsManager.unregisterCallback("SHPC", updateHealthDisplay);
	OptionsManager.unregisterCallback("SHNPC", updateHealthDisplay);
end

-- ===================================================================================================================
-- Modified
-- ===================================================================================================================
function updateHealthDisplay()
	local sOptSHPC = OptionsManager.getOption("SHPC");
	local sOptSHNPC = OptionsManager.getOption("SHNPC");
	local bShowDetail = (sOptSHPC == "detailed") or (sOptSHNPC == "detailed");
	local bShowStatus = ((sOptSHPC == "status") or (sOptSHNPC == "status")) and not bShowDetail;

	-- General
	label_wounds.setVisible(bShowDetail);
	label_trauma.setVisible(bShowDetail);
	label_injuries.setVisible(bShowDetail);
	label_fatigue.setVisible(bShowDetail);
	label_hp.setVisible(bShowDetail);

	label_status.setVisible(bShowStatus);

	for _,w in pairs(list.getWindows()) do
		w.updateHealthDisplay();
	end
end