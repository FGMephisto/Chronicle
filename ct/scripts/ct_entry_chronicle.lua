--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
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

	if self.isPC() then
		local sClass, sRecord = link.getValue();
		local w = Interface.findWindow(sClass, sRecord);
		if w then
			WindowManager.callInnerWindowFunction(w.main, "onHealthChanged");
		end
	else
		idelete.setVisible(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end

end

function linkPCFields()
	super.linkPCFields();

	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		-- senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);

		local nodeHPTotal = DB.getChild(nodeChar, "hptotal");
		if not nodeHPTotal and DB.getChild(nodeChar, "hp.total") then
			nodeHPTotal = DB.getChild(nodeChar, "hp.total");
		else
			nodeHPTotal = DB.createChild(nodeChar, "hptotal", "number");
		end
		hptotal.setLink(nodeHPTotal);

		local nodeWounds = DB.getChild(nodeChar, "wounds");
		if not nodeWounds and DB.getChild(nodeChar, "hp.wounds") then
			nodeWounds = DB.getChild(nodeChar, "hp.wounds");
		else
			nodeWounds = DB.createChild(nodeChar, "wounds", "number");
		end
		wounds.setLink(nodeWounds);

		local nodeFatigue = DB.getChild(nodeChar, "fatigue");
		if not nodeFatigue and DB.getChild(nodeChar, "hp.fatigue") then
			nodeFatigue = DB.getChild(nodeChar, "hp.fatigue");
		else
			nodeFatigue = DB.createChild(nodeChar, "fatigue", "number");
		end
		fatigue.setLink(nodeFatigue);

		local nodeInjuries = DB.getChild(nodeChar, "injuries");
		if not nodeInjuries and DB.getChild(nodeChar, "hp.injuries") then
			nodeInjuries = DB.getChild(nodeChar, "hp.injuries");
		else
			nodeInjuries = DB.createChild(nodeChar, "injuries", "number");
		end
		injuries.setLink(nodeInjuries);

		local nodeTrauma = DB.getChild(nodeChar, "trauma");
		if not nodeTrauma and DB.getChild(nodeChar, "hp.trauma") then
			nodeTrauma = DB.getChild(nodeChar, "hp.trauma");
		else
			nodeTrauma = DB.createChild(nodeChar, "trauma", "number");
		end
		trauma.setLink(nodeTrauma);

		type.setLink(DB.createChild(nodeChar, "race", "string"));
		size.setLink(DB.createChild(nodeChar, "size", "string"));
		-- alignment.setLink(DB.createChild(nodeChar, "alignment", "string"));

		agility.setLink(DB.createChild(nodeChar, "abilities.agility.score", "number"), true);
		animalhandling.setLink(DB.createChild(nodeChar, "abilities.animalhandling.score", "number"), true);
		athletics.setLink(DB.createChild(nodeChar, "abilities.athletics.score", "number"), true);
		awareness.setLink(DB.createChild(nodeChar, "abilities.awareness.score", "number"), true);
		cunning.setLink(DB.createChild(nodeChar, "abilities.cunning.score", "number"), true);
		endurance.setLink(DB.createChild(nodeChar, "abilities.endurance.score", "number"), true);
		fighting.setLink(DB.createChild(nodeChar, "abilities.fighting.score", "number"), true);
		marksmanship.setLink(DB.createChild(nodeChar, "abilities.marksmanship.score", "number"), true);
		warfare.setLink(DB.createChild(nodeChar, "abilities.warfare.score", "number"), true);
		will.setLink(DB.createChild(nodeChar, "abilities.will.score", "number"), true);

		cd.setLink(DB.createChild(nodeChar, "defenses.ac.total", "number"), true);
		armor.setLink(DB.createChild(nodeChar, "defenses.armor.total", "number"), true);
		move.setLink(DB.createChild(nodeChar, "speed.total", "number"), true);
		sprint.setLink(DB.createChild(nodeChar, "speed.sprint", "number"), true);

		-- Set Link for Quickness, required for initiative roll
		local sSkill = "Quickness";
		local sStat = "agility";
		local node = getDatabaseNode();
		local nodeSkillList = DB.createChild(node, "skilllist");
		local nodeSkill = DB.createChild(nodeSkillList, sSkill:lower());

		DB.setValue(nodeSkill, "name", "string", sSkill);
		DB.setValue(nodeSkill, "stat", "string", sStat);
		
		-- Create Link to PC Skilllist items
		for _, v in pairs(DB.getChildren(nodeChar, "skilllist")) do
			if DB.getValue(v, "name", ""):lower() == sSkill:lower() then
				init_skill_misc.setLink(DB.createChild(v, "misc", "number"), true);
				break;
			end
		end
	end
end