--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.update();
end

function onTypeChanged()
	self.update();
end
function onVersionChanged()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);

	WindowManager.callSafeControlUpdate(self, "sub_nonid", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_standard", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_type", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_pack", bReadOnly, bID);

	if bReadOnly then
		description.setVisible(bID and not description.isEmpty());
	else
		description.setVisible(bID);
	end
	description.setReadOnly(bReadOnly);
end

function onDrop(_, _, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end
