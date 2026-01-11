--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ItemManager.isPack = ItemManager2.isPack;

	ItemManager.isArmor = ItemManager2.isArmor;
	ItemManager.isShield = ItemManager2.isShield;
	ItemManager.isWeapon = ItemManager2.isWeapon;

	ItemManager.registerCleanupTransferHandler(ItemManager2.handleItemCleanupOnTransfer);
end

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

function isArmor(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	return (sTypeLower == "armor");
end

function isShield(nodeItem)
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
	return (sSubtypeLower == "shield");
end

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

function handleItemCleanupOnTransfer(rSourceItem, rTempItem, _)
	if rSourceItem.sClass ~= "item" then
		if rSourceItem.sClass == "reference_magicitem" then
			DB.setValue(rTempItem.node, "isidentified", "number", 0);
		else
			DB.setValue(rTempItem.node, "isidentified", "number", 1);
		end
	end
end
