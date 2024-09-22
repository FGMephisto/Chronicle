-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	WindowTabManager.registerTab("partysheet_host", { sName = "xp", sTabRes = "tab_xp", sClass = "ps_xp" });

	if Session.IsHost then
		DB.addHandler("charsheet.*.classes", "onChildUpdate", linkPCClasses);
	end
end

function linkPCClasses(nodeClass)
	if not nodeClass then
		return;
	end
	local nodeChar = DB.getParent(nodeClass);
	local nodePS = PartyManager.mapChartoPS(nodeChar);
	if not nodePS then
		return;
	end
	
	DB.setValue(nodePS, "classlevel", "string", CharManager.getClassSummary(nodeChar));
	
	local nHDUsed, nHDTotal = CharManager.getClassHDUsage(nodeChar);
	DB.setValue(nodePS, "hd", "number", nHDTotal);
	DB.setValue(nodePS, "hdused", "number", nHDUsed);
end
function linkPCFields(nodePS)
	local nodeChar = PartyManager.mapPStoChar(nodePS);
	
	PartyManager.linkRecordField(nodeChar, nodePS, "name", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "token", "token", "token");

	PartyManager.linkRecordField(nodeChar, nodePS, "race", "string");
	PartyManager.linkRecordField(nodeChar, nodePS, "exp", "number");
	PartyManager.linkRecordField(nodeChar, nodePS, "expneeded", "number");

	PartyManager.linkRecordField(nodeChar, nodePS, "hp.total", "number", "hptotal");
	PartyManager.linkRecordField(nodeChar, nodePS, "hp.wounds", "number", "wounds");
	
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.strength.score", "number", "strength");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.constitution.score", "number", "constitution");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.dexterity.score", "number", "dexterity");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.intelligence.score", "number", "intelligence");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.wisdom.score", "number", "wisdom");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.charisma.score", "number", "charisma");

	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.strength.bonus", "number", "strbonus");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.constitution.bonus", "number", "conbonus");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.dexterity.bonus", "number", "dexbonus");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.intelligence.bonus", "number", "intbonus");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.wisdom.bonus", "number", "wisbonus");
	PartyManager.linkRecordField(nodeChar, nodePS, "abilities.charisma.bonus", "number", "chabonus");

	PartyManager.linkRecordField(nodeChar, nodePS, "defenses.ac.total", "number", "ac");
	PartyManager.linkRecordField(nodeChar, nodePS, "defenses.special", "string", "specialdefense");
	PartyManager.linkRecordField(nodeChar, nodePS, "perception", "number");
	PartyManager.linkRecordField(nodeChar, nodePS, "senses", "string");
	
	if nodeChar then linkPCClasses(DB.getChild(nodeChar, "classes")); end
end
