-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ToDo: Where has this moved?

local sortLocked = false

-- ===================================================================================================================
-- ===================================================================================================================
function setSortLock(isLocked)
	sortLocked = isLocked
end

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5)

	local node = getDatabaseNode()
	DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged)
	DB.addHandler(DB.getPath(node, "*.bulk"), "onUpdate", onBulkChanged)
	DB.addHandler(DB.getPath(node, "*.armor_penalty"), "onUpdate", onArmorChanged)
	DB.addHandler(DB.getPath(node, "*.armor_rating"), "onUpdate", onArmorChanged)	
	DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged)
end

-- ===================================================================================================================
-- ===================================================================================================================
function onClose()
	local node = getDatabaseNode()
	DB.removeHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onIDChanged)
	DB.removeHandler(DB.getPath(node, "*.bulk"), "onUpdate", onBulkChanged)
	DB.removeHandler(DB.getPath(node, "*.armor_penalty"), "onUpdate", onArmorChanged)
	DB.removeHandler(DB.getPath(node, "*.armor_rating"), "onUpdate", onArmorChanged)
	DB.removeHandler(DB.getPath(node, "*.carried"), "onUpdate", onCarriedChanged)
end

-- ===================================================================================================================
-- ===================================================================================================================
function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true)
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onIDChanged(nodeField)
	local nodeItem = DB.getChild(nodeField, "..")
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager.isArmor(nodeItem) then
		CharArmorManager.calcItemArmorClass(DB.getChild(nodeItem, "..."))
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onBulkChanged()
	if CharEncumbranceManager5E.updateBulk then
		CharEncumbranceManager5E.updateBulk(window.getDatabaseNode())
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onArmorChanged(nodeField)
	local nodeItem = DB.getChild(nodeField, "..")
	if (DB.getValue(nodeItem, "carried", 0) == 2) and ItemManager.isArmor(nodeItem) then
		CharArmorManager.calcItemArmorClass(DB.getChild(nodeItem, "..."))
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onCarriedChanged(nodeField)
	local nodeChar = DB.getChild(nodeField, "....")

	if nodeChar then
		local nodeItem = DB.getChild(nodeField, "..")

		local nCarried = nodeField.getValue()
		local sCarriedItem = StringManager.trim(ItemManager.getDisplayName(nodeItem)):lower()

		-- This syncs the "carried status" of items with the "carried status" of their container
		if sCarriedItem ~= "" then
			for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
				if vNode ~= nodeItem then
					local sLoc = StringManager.trim(DB.getValue(vNode, "location", "")):lower()
					if sLoc == sCarriedItem then
						DB.setValue(vNode, "carried", "number", nCarried)
					end
				end
			end
		end

		-- Run update for Armor		
		if ItemManager.isArmor(nodeItem) then
			CharArmorManager.calcItemArmorClass(nodeChar)
		end
	end

	-- Run update for Bulk
	onBulkChanged()
end

-- ===================================================================================================================
-- ===================================================================================================================
function onListChanged()
	-- Debug.chat("FN: onListChanged in char_invlist")
	update()
	updateContainers()
end

-- ===================================================================================================================
-- ===================================================================================================================
function update()
	local bEditMode = (window.inventorylist_iedit.getValue() == 1)
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode)
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function addEntry(bFocus)
	local w = createWindow()
	if w then
		if bFocus then
			w.name.setFocus()
		end
		w.count.setValue(1)
	end
	return w
end

-- ===================================================================================================================
-- ===================================================================================================================
function onSortCompare(w1, w2)
	if sortLocked then
		return false
	end
	return ItemManager.onInventorySortCompare(w1, w2)
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateContainers()
	ItemManager.onInventorySortUpdate(self)
end

-- ===================================================================================================================
-- ===================================================================================================================
function onDrop(x, y, draginfo)
	-- Debug.chat("FN: onDrop in char_invlist")
	return ItemManager.handleAnyDrop(window.getDatabaseNode(), draginfo)
end