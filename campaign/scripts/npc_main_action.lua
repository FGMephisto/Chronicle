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
	WindowManager.callSafeControlUpdate(self, "actions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "bonusactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "reactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "legendaryactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "lairactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "innatespells", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "spells", bReadOnly);
end
