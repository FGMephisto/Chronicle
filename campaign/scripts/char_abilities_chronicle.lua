-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function collapse()
	feats_benefits_title.collapse()
	feats_drawbacks_title.collapse()
	languages_title.collapse()
end

-- ===================================================================================================================
-- ===================================================================================================================
function expand()
	feats_benefits_title.expand()
	feats_drawbacks_title.expand()
	languages_title.expand()
end

-- ===================================================================================================================
-- ===================================================================================================================
function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData()
		return CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord)
	end
end