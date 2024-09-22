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
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewClass(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSubclass(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewFeat(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewItem(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewItemTemplate(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewNPC(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSpecies(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewAncestry(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSkill(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewSpell(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
function onNewVehicle(nodeRecord)
	local sOptionGAVE = OptionsManager.getOption("GAVE");
	local bIs2024 = (sOptionGAVE == "2024");
	if bIs2024 then
		DB.setValue(nodeRecord, "version", "string", "2024");
	end
end
