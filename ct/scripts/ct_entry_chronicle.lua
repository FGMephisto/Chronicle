-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local _,sStatus,sColor = ActorHealthManager.getHealthInfo(rActor);

	wounds.setColor(sColor);
	status.setValue(sStatus);

	if not self.isPC() then
		idelete.setVisibility(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

-- ===================================================================================================================
-- This function links the CT values to the PC database values
-- Adjusted
-- ===================================================================================================================
function linkPCFields()
	super.linkPCFields();

	local nodeChar = link.getTargetDatabaseNode();

	if nodeChar then
		-- senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);

		hptotal.setLink(DB.createChild(nodeChar, "hp.total", "number"));
		wounds.setLink(DB.createChild(nodeChar, "hp.wounds", "number"))
		fatigue.setLink(DB.createChild(nodeChar, "hp.fatigue", "number"))
		injuries.setLink(DB.createChild(nodeChar, "hp.injuries", "number"))
		trauma.setLink(DB.createChild(nodeChar, "hp.trauma", "number"))

		size.setLink(DB.createChild(nodeChar, "size", "string"));

		agility.setLink(DB.createChild(nodeChar, "abilities.agility.score", "number"), true)
		animalhandling.setLink(DB.createChild(nodeChar, "abilities.animalhandling.score", "number"), true)
		athletics.setLink(DB.createChild(nodeChar, "abilities.athletics.score", "number"), true)
		awareness.setLink(DB.createChild(nodeChar, "abilities.awareness.score", "number"), true)
		cunning.setLink(DB.createChild(nodeChar, "abilities.cunning.score", "number"), true)
		endurance.setLink(DB.createChild(nodeChar, "abilities.endurance.score", "number"), true)
		fighting.setLink(DB.createChild(nodeChar, "abilities.fighting.score", "number"), true)
		marksmanship.setLink(DB.createChild(nodeChar, "abilities.marksmanship.score", "number"), true)
		warfare.setLink(DB.createChild(nodeChar, "abilities.warfare.score", "number"), true)
		will.setLink(DB.createChild(nodeChar, "abilities.will.score", "number"), true)

		cd.setLink(DB.createChild(nodeChar, "defenses.ac.total", "number"), true)
		armor.setLink(DB.createChild(nodeChar, "defenses.armor.total", "number"), true)
		move.setLink(DB.createChild(nodeChar, "speed.total", "number"), true)
		sprint.setLink(DB.createChild(nodeChar, "speed.sprint", "number"), true)
	end

	-- Set Link for Quickness, required for initiative roll
	-- "sSkill" must start with a capital letter, "sStat" must be all lower case
	local sSkill = "Quickness"
	local sStat = "agility"
	local node = getDatabaseNode()
	local nodeSkillList = DB.createChild(node, "skilllist")
	local nodeSkill = DB.createChild(nodeSkillList, sSkill:lower())

	DB.setValue(nodeSkill, "name", "string", sSkill)
	DB.setValue(nodeSkill, "stat", "string", sStat)
	
	-- Create Link to PC Skilllist items
	for _, v in pairs(DB.getChildren(nodeChar, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			init_skill_misc.setLink(DB.createChild(v, "misc", "number"), true)
		end
	end
end