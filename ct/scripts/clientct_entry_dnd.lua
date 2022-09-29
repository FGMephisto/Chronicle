-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	updateHealthDisplay();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);

	if wounds then
		wounds.setColor(sColor);
	end
	if nonlethal then
		nonlethal.setColor(sColor);
	end
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	if sOption == "detailed" then
		if hp then
			hp.setVisible(true);
		end
		if hptemp then
			hptemp.setVisible(true);
		end
		if nonlethal then
			nonlethal.setVisible(true);
		end
		if wounds then
			wounds.setVisible(true);
		end

		status.setVisible(false);
	elseif sOption == "status" then
		if hp then
			hp.setVisible(false);
		end
		if hptemp then
			hptemp.setVisible(false);
		end
		if nonlethal then
			nonlethal.setVisible(false);
		end
		if wounds then
			wounds.setVisible(false);
		end

		status.setVisible(true);
	else
		if hp then
			hp.setVisible(false);
		end
		if hptemp then
			hptemp.setVisible(false);
		end
		if nonlethal then
			nonlethal.setVisible(false);
		end
		if wounds then
			wounds.setVisible(false);
		end

		status.setVisible(false);
	end
end
