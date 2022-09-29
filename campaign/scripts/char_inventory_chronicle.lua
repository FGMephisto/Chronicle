-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onDrop(x, y, draginfo)
	-- Debug.chat("FN: onDrop in char_inventory")
	local sDragType = draginfo.getType()
	local nodeCreature = getDatabaseNode()

	if ActorManager.isPC(nodeCreature) then
		return ItemManager.handleAnyDrop(nodeCreature, draginfo)
	elseif sDragType == "shortcut" then
		local sClass, sRecord = draginfo.getShortcutData()
		if LibraryData.isRecordDisplayClass("item", sClass) then
			local bTransferAll = false
			local sTargetList = "inventorylist"

			return ItemManager.handleItem(nodeCreature, sTargetList, sClass, sRecord, bTransferAll)
		end
	end
end