-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	super.onInit();
	onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	updateHealthDisplay();
end
function onActiveChanged()
	super.onActiveChanged();
	
	local sClass = link.getValue();
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	if (sRecordType == "vehicle") and name.isVisible() then
		sub_active.setValue("client_ct_section_active_vehicle", getDatabaseNode());
		sub_active.setVisible(true);
	else
		sub_active.setValue("", "");
		sub_active.setVisible(false);
	end
end
function onIDChanged()
	super.onIDChanged();
	
	self.onActiveChanged();
end
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode())
	local sColor = ActorHealthManager.getHealthColor(rActor);
	
	wounds.setColor(sColor);
	status.setColor(sColor);
end

-- Adjusted
function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end
	
	if sOption == "detailed" then
		hptotal.setVisible(true);
		fatigue.setVisible(true);
		injuries.setVisible(true);
		trauma.setVisible(true);
		wounds.setVisible(true);
		status.setVisible(false);
	elseif sOption == "status" then
		hptotal.setVisible(false);
		fatigue.setVisible(false);
		injuries.setVisible(false);
		trauma.setVisible(false);
		wounds.setVisible(false);
		status.setVisible(true);
	else
		hptotal.setVisible(false);
		fatigue.setVisible(false);
		injuries.setVisible(false);
		trauma.setVisible(false);
		wounds.setVisible(false);
		status.setVisible(false);
	end

	if sub_active and sub_active.subwindow then
		sub_active.subwindow.updateHealthDisplay(sOption);
	end
end