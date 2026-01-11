--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onHealthChanged();
end

function onDrop(_, _, draginfo)
	if hp.getValue() > 0 then
		local sDragType = draginfo.getType();
		if sDragType == "attack" then
			draginfo.setMetaData("sSubtargetPath", DB.getPath(getDatabaseNode()));
		elseif sDragType == "damage" then
			draginfo.setMetaData("sSubtargetPath", DB.getPath(getDatabaseNode()));
		end
	end
end

function onHealthChanged()
	local nHP = math.max(hp.getValue(), 0);
	local nWounds = math.max(wounds.getValue(), 0);
	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	local sColor = ColorManager.getHealthColor(nPercentWounded, false);
	wounds.setColor(sColor);
	status.setColor(sColor);
end
function updateHealthDisplay(sOption)
	if hp.getValue() > 0 then
		if sOption == "detailed" then
			hp.setVisible(true);
			wounds.setVisible(true);
			status.setVisible(false);
		elseif sOption == "status" then
			hp.setVisible(false);
			wounds.setVisible(false);
			status.setVisible(true);
		else
			hp.setVisible(false);
			wounds.setVisible(false);
			status.setVisible(false);
		end
	else
		hp.setVisible(false);
		wounds.setVisible(false);
		status.setVisible(false);
	end
end
