--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.addHandlers();
	self.onAttuneRelatedAttributeUpdate();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end
function onClose()
	self.removeHandlers();
end

function onLockModeChanged(bReadOnly)
	local tFields = { "name", "nonid_name", "weight", "idelete", };
	WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);
	-- local tFields = { "count", "location", "carried", attune", };
	-- WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);
end

function addHandlers()
	local node = getDatabaseNode();
	DB.addHandler(node, "onDelete", self.onDelete);
	DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
	DB.addHandler(DB.getPath(node, "rarity"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
end
function removeHandlers()
	local node = getDatabaseNode();
	DB.removeHandler(node, "onDelete", self.onDelete);
	DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
	DB.removeHandler(DB.getPath(node, "rarity"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
end

function onDelete(node)
	ItemManager.onCharRemoveEvent(node);
	self.removeHandlers();
end
function onAttuneRelatedAttributeUpdate()
	local bRequiresAttune = CharAttunementManager.doesItemAllowAttunement(getDatabaseNode());
	attune.setVisible(bRequiresAttune);
	attune_na.setVisible(not bRequiresAttune);
end
