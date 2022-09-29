-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	-- Debug.chat("FN: onInit in manager_item2")
	ItemManager.isPack = isPack;

	ItemManager.isArmor = isArmor;
	ItemManager.isShield = isShield;
	ItemManager.isWeapon = isWeapon;

	ItemManager.registerCleanupTransferHandler(handleItemCleanupOnTransfer);

	-- Replacing CoreRPG function with new function
	ItemManager.getItemSourceType = getItemSourceTypeChronicle
end

-- ===================================================================================================================
-- ===================================================================================================================
function isPack(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	local bIsPack = false;
	if StringManager.startsWith(sTypeLower, "equipment pack") then
		bIsPack = true;
	elseif StringManager.startsWith(sSubtypeLower, "equipment pack") then
		bIsPack = true;
	end
	return bIsPack;
end

-- ===================================================================================================================
-- ===================================================================================================================
function isArmor(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	return (sTypeLower == "armor");
end

function isShield(nodeItem)
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
	return (sSubtypeLower == "shield");
end

-- ===================================================================================================================
-- ===================================================================================================================
function isWeapon(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if (sSubtypeLower == "weapon") and (sTypeLower ~= "vehicle component") and (sTypeLower ~= "vehicle component upgrade") then
		sSubtypeLower = sTypeLower;
		sTypeLower = "weapon";
	end

	local bIsWeapon = ((sTypeLower == "weapon") and (sSubtypeLower ~= "ammunition"));
	return bIsWeapon;
end

-- ===================================================================================================================
-- ===================================================================================================================
function handleItemCleanupOnTransfer(rSourceItem, rTempItem, rTargetItem)
	if rSourceItem.sClass ~= "item" then
		if rSourceItem.sClass == "reference_magicitem" then
			DB.setValue(rTempItem.node, "isidentified", "number", 0);
		else
			DB.setValue(rTempItem.node, "isidentified", "number", 1);
		end
	end
end

-- ===================================================================================================================
-- Custom
-- ===================================================================================================================
function getItemSourceTypeChronicle(vNode)
	-- Debug.chat("FN: getItemSourceTypeChronicle in manager_item3")
	local sNodePath = nil;

	if type(vNode) == "databasenode" then
		sNodePath = vNode.getPath();
	elseif type(vNode) == "string" then
		sNodePath = vNode;
	end

	if not sNodePath then
		return "";
	end

	for _, vMapping in ipairs(LibraryData.getMappings("charsheet")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "charsheet";
		end
		-- Added to allow drops for NPC
		if StringManager.startsWith(sNodePath, "npc") then
			return "charsheet";
		end
		-- Added to allow drops for Combat Tracker
		if StringManager.startsWith(sNodePath, "combattracker") then
			return "charsheet";
		end
	end

	for _, vMapping in ipairs(LibraryData.getMappings("item")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "item";
		end
	end

	for _, vMapping in ipairs(LibraryData.getMappings("treasureparcel")) do
		if StringManager.startsWith(sNodePath, vMapping) then
			return "treasureparcel";
		end
	end

	if StringManager.startsWith(sNodePath, "partysheet") then
		return "partysheet";
	end

	if StringManager.startsWith(sNodePath, "temp") then
		return "temp";
	end

	return "";
end