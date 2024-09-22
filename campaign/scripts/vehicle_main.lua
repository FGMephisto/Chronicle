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

	WindowManager.callSafeControlUpdate(self, "sub_standard", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_top", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_bottom", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_action", bReadOnly);
end

function onDrop(x, y, draginfo)
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return true;
	end
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "item" then
			local nodeSource = draginfo.getDatabaseNode();
			local sTypeLower = StringManager.simplify(DB.getValue(nodeSource, "type", ""));
			if StringManager.contains({ "vehiclecomponent", "vehiclecomponentupgrade", }, sTypeLower) then
				self.addComponent(nodeSource);
				return true;
			end
		end
	end
end
function addComponent(nodeSource)
	if not nodeSource then
		return;
	end

	local nodeComponents = DB.createChild(getDatabaseNode(), "components");
	local nodeEntry = DB.createChildAndCopy(nodeComponents, nodeSource);
	DB.setValue(nodeEntry, "locked", "number", 1);
	DB.setValue(nodeEntry, "shortcut", "windowreference", "item", DB.getPath(nodeEntry));
end
