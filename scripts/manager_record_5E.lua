--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	RecordManager.setRecordAddCallback("background", RecordManager5E.onNewBackground);
	RecordManager.setRecordAddCallback("class", RecordManager5E.onNewClass);
	RecordManager.setRecordAddCallback("class_specialization", RecordManager5E.onNewSubclass);
	RecordManager.setRecordAddCallback("feat", RecordManager5E.onNewFeat);
	RecordManager.setRecordAddCallback("item", RecordManager5E.onNewItem);
	RecordManager.setRecordAddCallback("itemtemplate", RecordManager5E.onNewItemTemplate);
	RecordManager.setRecordAddCallback("npc", RecordManager5E.onNewNPC);
	RecordManager.setRecordAddCallback("race", RecordManager5E.onNewSpecies);
	RecordManager.setRecordAddCallback("race_subrace", RecordManager5E.onNewAncestry);
	RecordManager.setRecordAddCallback("skill", RecordManager5E.onNewSkill);
	RecordManager.setRecordAddCallback("spell", RecordManager5E.onNewSpell);
	RecordManager.setRecordAddCallback("vehicle", RecordManager5E.onNewVehicle);
end

function onNewBackground(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewClass(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSubclass(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewFeat(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewItem(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewItemTemplate(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewNPC(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSpecies(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewAncestry(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSkill(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSpell(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewVehicle(nodeRecord)
	if OptionsManager.isOption("GAVE", "2024") then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
