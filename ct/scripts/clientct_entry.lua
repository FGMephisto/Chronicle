--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	self.updateHealthDisplay();
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

function updateHealthDisplay()
	local sOption;
	if friendfoe.getValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	local bShowDetail = (sOption == "detailed");
	local bShowStatus = (sOption == "status");

	hptotal.setVisible(bShowDetail);
	hptemp.setVisible(bShowDetail);
	wounds.setVisible(bShowDetail);
	status.setVisible(bShowStatus);

	local bShowHealthBase = not OptionsManager.isOption("SHPC", "off") or not OptionsManager.isOption("SHNPC", "off");
	healthbase.setVisible(bShowHealthBase);

	if sub_active and sub_active.subwindow then
		sub_active.subwindow.updateHealthDisplay(sOption);
	end
end
