-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onInit()
	-- OptionsManager.registerCallback("HREN", onHRENOptionChanged);
	-- onHRENOptionChanged();

	-- updateAttunement();
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onClose()
	-- OptionsManager.unregisterCallback("HREN", onHRENOptionChanged);
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onHRENOptionChanged()
	-- local sOptionHREN = OptionsManager.getOption("HREN");
	-- local bShowVariant = (sOptionHREN == "variant");
	-- encumbrancebase_label.setVisible(bShowVariant);
	-- encumbrancebase.setVisible(bShowVariant);
	-- encumbranceheavy_label.setVisible(bShowVariant);
	-- encumbranceheavy.setVisible(bShowVariant);
end

-- ===================================================================================================================
-- ===================================================================================================================
function onDrop(x, y, draginfo)
	return ItemManager.handleAnyDrop(getDatabaseNode(), draginfo);
	
	-- local sDragType = draginfo.getType()
	-- local nodeCreature = getDatabaseNode()

	-- if ActorManager.isPC(nodeCreature) then
		-- return ItemManager.handleAnyDrop(nodeCreature, draginfo);
	-- elseif sDragType == "shortcut" then
		-- local sClass, sRecord = draginfo.getShortcutData()
		-- if LibraryData.isRecordDisplayClass("item", sClass) then
			-- local bTransferAll = false
			-- local sTargetList = "inventorylist"

			-- return ItemManager.handleItem(nodeCreature, sTargetList, sClass, sRecord, bTransferAll)
		-- end
	-- end
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function updateAttunement()
	-- local nodeChar = getDatabaseNode();
	-- local nUsed = CharAttunementManager.getUsedSlots(nodeChar);
	-- local nAllowed = CharAttunementManager.getTotalSlots(nodeChar);
	-- local sUsage = string.format("%d / %d", nUsed, nAllowed);
	
	-- attunecalc.setValue(sUsage);
	-- if nUsed > nAllowed then
		-- attunecalc.setColor(attunecalc.warning[1])
	-- else
		-- attunecalc.setColor(nil);
	-- end
end