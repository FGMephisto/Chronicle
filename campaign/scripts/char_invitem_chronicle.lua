-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onInit()
	self.addHandlers();
	-- self.onAttuneRelatedAttributeUpdate();
end
function onClose()
	self.removeHandlers();
end

-- Adjus
function addHandlers()
	local node = getDatabaseNode();
	DB.addHandler(node, "onDelete", self.onDelete);
	-- DB.addHandler(DB.getPath(node, "isidentified"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
	-- DB.addHandler(DB.getPath(node, "rarity"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
end

-- Adjus
function removeHandlers()
	local node = getDatabaseNode();
	DB.removeHandler(node, "onDelete", self.onDelete);
	-- DB.removeHandler(DB.getPath(node, "isidentified"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
	-- DB.removeHandler(DB.getPath(node, "rarity"), "onUpdate", self.onAttuneRelatedAttributeUpdate);
end

function onDelete(node)
	ItemManager.onCharRemoveEvent(node);
	self.removeHandlers();
end

-- Adjusted
function onAttuneRelatedAttributeUpdate(nodeAttribute)
	-- local bRequiresAttune = CharAttunementManager.doesItemAllowAttunement(getDatabaseNode());
	-- attune.setVisible(bRequiresAttune);
	-- attune_na.setVisible(not bRequiresAttune);
end
