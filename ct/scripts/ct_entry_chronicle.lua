-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	-- Show active section, if combatant is active
	self.onActiveChanged()

	-- Acquire token reference, if any
	self.linkToken()
	
	-- Set up the PC links
	self.onLinkChanged()
	self.onFactionChanged()
	self.onHealthChanged()
	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6)
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7)
end

-- ===================================================================================================================
-- ===================================================================================================================
function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		self.delete()
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	if self.isPC() then
		self.linkPCFields()
		name.setLine(false)
	end
	self.onIDChanged()
end

-- ===================================================================================================================
-- ===================================================================================================================
function onIDChanged()
	local nodeRecord = getDatabaseNode()
	local sClass = link.getValue()
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass)
	local bID = LibraryData.getIDState(sRecordType, nodeRecord, true)
	
	name.setVisible(bID)
	nonid_name.setVisible(not bID)

	isidentified.setVisible(LibraryData.getIDMode(sRecordType))
end

-- ===================================================================================================================
-- ===================================================================================================================
function onFactionChanged()
	-- Update the entry frame
	self.updateDisplay()

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		tokenvis.setVisible(false)
	else
		tokenvis.setVisible(true)
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode())
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor)

	wounds.setColor(sColor)
	status.setValue(sStatus)

	if not self.isPC() then
		idelete.setVisibility(ActorHealthManager.isDyingOrDeadStatus(sStatus))
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode())
	windowlist.onVisibilityToggle()
end

-- ===================================================================================================================
-- ===================================================================================================================
function onActiveChanged()
	self.onSectionChanged("active")
end

-- ===================================================================================================================
-- ===================================================================================================================
function updateDisplay()
	local sFaction = friendfoe.getStringValue()

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("sheetlabel")
		nonid_name.setFont("sheetlabel")
		
		active_spacer_top.setVisible(true)
		active_spacer_bottom.setVisible(true)
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active")
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active")
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active")
		else
			setFrame("ctentrybox_active")
		end
	else
		name.setFont("sheettext")
		nonid_name.setFont("sheettext")
		
		active_spacer_top.setVisible(false)
		active_spacer_bottom.setVisible(false)
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend")
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral")
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe")
		else
			setFrame("ctentrybox")
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue())
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance)
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function delete()
	local node = getDatabaseNode()
	if not node then
		close()
		return
	end

	-- Clear any effects first, so that saves aren't triggered when initiative advanced
	DB.deleteChildren(node, "effects")

	-- Move to the next actor, if this CT entry is active
	if self.isActive() then
		CombatManager.nextActor()
	end

	-- Delete the database node and close the window
	local cList = windowlist
	node.delete()

	-- Update list information
	cList.onVisibilityToggle()
end

-- ===================================================================================================================
-- This function links the CT values to the PC database values
-- Modified
-- ===================================================================================================================
function linkPCFields()
	-- Debug.chat("FN: linkPCFields")
	local nodeChar = link.getTargetDatabaseNode()
	local node = getDatabaseNode()
	local nodeSkillList = DB.createChild(node, "skilllist")

	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true)

		fatigue.setLink(nodeChar.createChild("hp.fatigue", "number"))
		hptotal.setLink(nodeChar.createChild("hp.total", "number"))
		injuries.setLink(nodeChar.createChild("hp.injuries", "number"))
		trauma.setLink(nodeChar.createChild("hp.trauma", "number"))
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"))

		size.setLink(nodeChar.createChild("size", "string"))

		agility.setLink(nodeChar.createChild("abilities.agility.score", "number"), true)
		animalhandling.setLink(nodeChar.createChild("abilities.animalhandling.score", "number"), true)
		athletics.setLink(nodeChar.createChild("abilities.athletics.score", "number"), true)
		awareness.setLink(nodeChar.createChild("abilities.awareness.score", "number"), true)
		cunning.setLink(nodeChar.createChild("abilities.cunning.score", "number"), true)
		endurance.setLink(nodeChar.createChild("abilities.endurance.score", "number"), true)
		fighting.setLink(nodeChar.createChild("abilities.fighting.score", "number"), true)
		marksmanship.setLink(nodeChar.createChild("abilities.marksmanship.score", "number"), true)
		warfare.setLink(nodeChar.createChild("abilities.warfare.score", "number"), true)
		will.setLink(nodeChar.createChild("abilities.will.score", "number"), true)

		cd.setLink(nodeChar.createChild("defenses.ac.total", "number"), true)
		armor.setLink(nodeChar.createChild("defenses.armor.total", "number"), true)
		move.setLink(nodeChar.createChild("speed.total", "number"), true)
		sprint.setLink(nodeChar.createChild("speed.sprint", "number"), true)
	end

	-- Set Link for Quickness, required for initiative roll
	-- "sSkill" must start with a capital letter, "sStat" must be all lower case
	local sSkill = "Quickness"
	local sStat = "agility"
	local nodeSkill = DB.createChild(nodeSkillList, sSkill:lower())

	DB.setValue(nodeSkill, "name", "string", sSkill)
	DB.setValue(nodeSkill, "stat", "string", sStat)
	
	-- Create Link to PC Skilllist item
	for _, v in pairs(DB.getChildren(nodeChar, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			-- init_skill_misc.setLink(v.createChild("misc", "number"), true)
		end
	end
end

-- ===================================================================================================================
--	HELPERS
-- ===================================================================================================================
function isRecordType(s)
	local sClass = link.getValue()
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass)
	return (sRecordType == s)
end

-- ===================================================================================================================
-- ===================================================================================================================
function isPC()
	return self.isRecordType("charsheet")
end

-- ===================================================================================================================
-- ===================================================================================================================
function isActive()
	return (active.getValue() == 1)
end

-- ===================================================================================================================
--	SECTION HANDLING
-- ===================================================================================================================
function getSectionToggle(sKey)
	local bResult = false
	local sButtonName = "button_section_" .. sKey
	local cButton = self[sButtonName]

	if cButton then
		bResult = (cButton.getValue() == 1)
		if (sKey == "active") and self.isActive() and not self.isPC() then
			bResult = true
		end
	end

	return bResult
end

-- ===================================================================================================================
-- ===================================================================================================================
function onSectionChanged(sKey)
	local sSectionName = "sub_" .. sKey

	local cSection = self[sSectionName]
	if cSection then
		local bShow = self.getSectionToggle(sKey)

		if bShow then
			local sSectionClass = "ct_section_" .. sKey
			if sKey == "active" then
				if self.isRecordType("npc") then
					sSectionClass = sSectionClass .. "_npc"
				elseif self.isRecordType("vehicle") then
					sSectionClass = sSectionClass .. "_vehicle"
				end
			elseif sKey == "defense" then
				if self.isRecordType("npc") then
					sSectionClass = sSectionClass .. "_npc"
				elseif self.isRecordType("vehicle") then
					sSectionClass = sSectionClass .. "_vehicle"
				end
			end
			cSection.setValue(sSectionClass, getDatabaseNode())
		else
			cSection.setValue("", "")
		end
		cSection.setVisible(bShow)
	end

	local sSummaryName = "summary_" .. sKey
	local cSummary = self[sSummaryName]
	if cSummary then
		cSummary.onToggle()
	end
end