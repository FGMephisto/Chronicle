-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Not used any more

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	onSummaryChanged()
	update()
end

-- ===================================================================================================================
-- ===================================================================================================================
function onSummaryChanged()
	local sSize = size.getValue()
	local sType = type.getValue()
	
	local aText = {}
	if sSize ~= "" then
		table.insert(aText, sSize)
	end
	if sType ~= "" then
		table.insert(aText, sType)
	end
	local sText = table.concat(aText, " ")

	summary_label.setValue(sText)
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false
	end

	return self[sControl].update(bReadOnly, bForceHide)
end

-- ===================================================================================================================
-- ===================================================================================================================
function update()
	local nodeRecord = getDatabaseNode()
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord)
	local bID = LibraryData.getIDState("npc", nodeRecord)

	local bSection1 = false
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true end
	else
		updateControl("nonid_name", bReadOnly, true)
	end
	divider.setVisible(bSection1)

	updateControl("size", bReadOnly, bReadOnly)
	updateControl("type", bReadOnly, bReadOnly)
	summary_label.setVisible(bReadOnly)

	ac.setReadOnly(bReadOnly)
	hp.setReadOnly(bReadOnly)
	speed.setReadOnly(bReadOnly)
	
	updateControl("agility", bReadOnly)
	updateControl("animalhandling", bReadOnly)
	updateControl("athletics", bReadOnly)
	updateControl("awareness", bReadOnly)
	updateControl("cunning", bReadOnly)
	updateControl("deception", bReadOnly)
	updateControl("endurance", bReadOnly)
	updateControl("fighting", bReadOnly)
	updateControl("healing", bReadOnly)
	updateControl("language", bReadOnly)
	updateControl("knowledge", bReadOnly)
	updateControl("marksmanship", bReadOnly)
	updateControl("persuasion", bReadOnly)
	updateControl("status", bReadOnly)
	updateControl("stealth", bReadOnly)
	updateControl("survival", bReadOnly)
	updateControl("thievery", bReadOnly)
	updateControl("warfare", bReadOnly)
	updateControl("will", bReadOnly)


	updateControl("skills", bReadOnly)
	updateControl("senses", bReadOnly)
	updateControl("languages", bReadOnly)
	updateControl("qualities", bReadOnly)
	
	-- if bReadOnly then
		-- header_actions.setVisible(bShow)
	-- else
		-- header_actions.setVisible(true)
	-- end
end