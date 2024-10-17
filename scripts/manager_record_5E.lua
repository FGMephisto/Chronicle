-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onTabletopInit()
	RecordManager.setRecordAddCallback("background", onNewBackground);
	RecordManager.setRecordAddCallback("class", onNewClass);
	RecordManager.setRecordAddCallback("class_specialization", onNewSubclass);
	RecordManager.setRecordAddCallback("feat", onNewFeat);
	RecordManager.setRecordAddCallback("item", onNewItem);
	RecordManager.setRecordAddCallback("itemtemplate", onNewItemTemplate);
	RecordManager.setRecordAddCallback("npc", onNewNPC);
	RecordManager.setRecordAddCallback("race", onNewSpecies);
	RecordManager.setRecordAddCallback("race_subrace", onNewAncestry);
	RecordManager.setRecordAddCallback("skill", onNewSkill);
	RecordManager.setRecordAddCallback("spell", onNewSpell);
	RecordManager.setRecordAddCallback("vehicle", onNewVehicle);
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
