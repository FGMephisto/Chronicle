-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onHealthChanged();
end

function onDrop(x, y, draginfo)
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

	local sStatus;
	if nPercentWounded >= 1 then
		sStatus = ActorHealthManager.STATUS_DESTROYED;
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentWounded);
	end
	status.setValue(sStatus);
end
