-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onProfBonusDataChanged();
	self.update();
end

function onProfBonusDataChanged()
	profbonus.setValue(ActorManager5E.getAbilityScore(ActorManager.resolveActor(getDatabaseNode()), "prf"));
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	-- NOTE: savingthrows/conditionimmunities are 2014 specific
	local tFields = { 
		"savingthrows", "skills",
		"damagevulnerabilities", "damageresistances", 
		"damageimmunities", "conditionimmunities",
		"senses", "languages", "challengerating", "cr", "xp",
	};
	WindowManager.callSafeControlsUpdate(self, tFields, bReadOnly);
end
