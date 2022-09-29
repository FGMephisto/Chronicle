-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System.
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
	if label_hp then
		label_hp.setVisible(bShowDetail);
	end

	if label_temp then
		label_temp.setVisible(bShowDetail);
	end

	if label_wounds then
		label_wounds.setVisible(bShowDetail);
	end

	-- Chronicle
	if abel_injuriess then
		label_injuries.setVisible(bShowDetail);
	end

	if label_fatigues then
		label_fatigue.setVisible(bShowDetail);
	end

	if label_trauma then
		label_trauma.setVisible(bShowDetail);
	end

	label_status.setVisible(not bShowDetail);

	for _,w in pairs(list.getWindows()) do
		w.updateHealthDisplay();
	end
end