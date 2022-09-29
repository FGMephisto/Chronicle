-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	super.onInit()
	self.onHealthChanged()

	-- Show active section, if combatant is active
	-- self.onActiveChanged()

	-- Acquire token reference, if any
	-- self.linkToken()
	
	-- Set up the PC links
	-- self.onLinkChanged()
	-- self.onFactionChanged()
	-- self.onHealthChanged()
	
	-- Register the deletion menu item for the host
	-- registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6)
	-- registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7)
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
	
	-- Create Link to PC Skilllist items
	for _, v in pairs(DB.getChildren(nodeChar, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			-- init_skill_misc.setLink(v.createChild("misc", "number"), true)
		end
	end
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