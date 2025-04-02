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

	if not self.isPC() then
		idelete.setVisible(ActorHealthManager.isDyingOrDeadStatus(sStatus));
	end
end

function linkPCFields()
	super.linkPCFields();

	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		senses.setLink(DB.createChild(nodeChar, "senses", "string"), true);

		hptotal.setLink(DB.createChild(nodeChar, "hp.total", "number"));
		hptemp.setLink(DB.createChild(nodeChar, "hp.temporary", "number"));
		wounds.setLink(DB.createChild(nodeChar, "hp.wounds", "number"));
		deathsavesuccess.setLink(DB.createChild(nodeChar, "hp.deathsavesuccess", "number"));
		deathsavefail.setLink(DB.createChild(nodeChar, "hp.deathsavefail", "number"));

		type.setLink(DB.createChild(nodeChar, "race", "string"));
		size.setLink(DB.createChild(nodeChar, "size", "string"));
		alignment.setLink(DB.createChild(nodeChar, "alignment", "string"));

		strength.setLink(DB.createChild(nodeChar, "abilities.strength.score", "number"), true);
		dexterity.setLink(DB.createChild(nodeChar, "abilities.dexterity.score", "number"), true);
		constitution.setLink(DB.createChild(nodeChar, "abilities.constitution.score", "number"), true);
		intelligence.setLink(DB.createChild(nodeChar, "abilities.intelligence.score", "number"), true);
		wisdom.setLink(DB.createChild(nodeChar, "abilities.wisdom.score", "number"), true);
		charisma.setLink(DB.createChild(nodeChar, "abilities.charisma.score", "number"), true);

		init.setLink(DB.createChild(nodeChar, "initiative.total", "number"), true);
		ac.setLink(DB.createChild(nodeChar, "defenses.ac.total", "number"), true);
		speed.setLink(DB.createChild(nodeChar, "speed.total", "number"), true);
	end
end
