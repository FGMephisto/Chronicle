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

	WindowManager.callSafeControlUpdate(self, "traits", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "components", bReadOnly);
end
