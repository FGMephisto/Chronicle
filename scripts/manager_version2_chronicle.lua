--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local rsname = "Chronicle";
local rsmajorversion = 10;

function onInit()
	Debug.console("VersionManager2.onInit - Session.IsHost:", Session.IsHost);
	if Session.IsHost then
		VersionManager2.updateCampaign();
	end

	DB.addEventHandler("onAuxCharLoad", VersionManager2.onCharImport);
	DB.addEventHandler("onImport", VersionManager2.onImport);
	Module.addEventHandler("onModuleLoad", VersionManager2.onModuleLoad);
end

function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	Debug.console("VersionManager2.onCharImport - import aMajor:", aMajor);
	VersionManager2.updateChar(nodePC, aMajor and (aMajor[rsname] or aMajor["5E"] or aMajor[""]));
end

function onImport(node)
	local aPath = StringManager.split(DB.getPath(node), ".");
	if #aPath == 2 and (aPath[1] == "charsheet" or aPath[1] == "npc") then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		Debug.console("VersionManager2.onImport - node:", DB.getPath(node), "import aMajor:", aMajor);
		VersionManager2.updateChar(node, aMajor and (aMajor[rsname] or aMajor["5E"] or aMajor[""]));
	end
end

function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	Debug.console("VersionManager2.onModuleLoad - module:", sModule, "aMajor:", aMajor);
	VersionManager2.updateModule(sModule, aMajor and (aMajor[rsname] or aMajor["5E"] or aMajor[""]));
end

function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	Debug.console("VersionManager2.updateChar - node:", DB.getPath(nodePC), "nVersion:", nVersion, "target:", rsmajorversion);
	if nVersion < rsmajorversion then
		if nVersion < 10 then
			VersionManager2.migrateChar10(nodePC);
		end
	end
end

function updateCampaign()
	local _, nRulesetVersion, aMajor, _ = DB.getRulesetVersion();
	local major = (aMajor and (aMajor[rsname] or aMajor["5E"] or aMajor[""])) or nRulesetVersion;
	Debug.console("VersionManager2.updateCampaign - major:", major, "rsmajorversion:", rsmajorversion, "aMajor:", aMajor, "nRulesetVersion:", nRulesetVersion);
	if not major then
		Debug.console("VersionManager2.updateCampaign - no major version found, skipping.");
		return;
	end

	if major > 0 and major < rsmajorversion then
		Debug.console("VersionManager2.updateCampaign: starting migration from v" .. tostring(major) .. " to v" .. tostring(rsmajorversion));
		ChatManager.SystemMessage("Migrating campaign database to latest data version.");
		DB.backup();

		if major < 10 then
			VersionManager2.convertCharacters10();
			VersionManager2.convertNPCs10();
		end
		Debug.console("VersionManager2.updateCampaign: migration completed successfully.");
	else
		Debug.console("VersionManager2.updateCampaign: no migration needed (major=" .. tostring(major) .. " >= target=" .. tostring(rsmajorversion) .. ")");
	end
end

function updateModule(sModule, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	Debug.console("VersionManager2.updateModule - module:", sModule, "nVersion:", nVersion);
	if nVersion > 0 and nVersion < rsmajorversion then
		local nodeRoot = DB.getRoot(sModule);

		if nVersion < 10 then
			VersionManager2.convertPregenCharacters10(nodeRoot);
			VersionManager2.convertNPCs10(nodeRoot);
		end
	end
end

function convertPregenCharacters10(nodeRoot)
	local tList = DB.getChildList(nodeRoot, "pregencharsheet");
	Debug.console("VersionManager2.convertPregenCharacters10 - count:", #tList);
	for _, nodeChar in ipairs(tList) do
		VersionManager2.migrateChar10(nodeChar);
	end
end

function convertCharacters10()
	local tList = DB.getChildList("charsheet");
	Debug.console("VersionManager2.convertCharacters10 - count:", #tList);
	for _, nodeChar in ipairs(tList) do
		VersionManager2.migrateChar10(nodeChar);
	end
end

function convertNPCs10(nodeRoot)
	local tList;
	if nodeRoot then
		tList = DB.getChildList(nodeRoot, "npc");
	else
		tList = DB.getChildList("npc");
	end
	Debug.console("VersionManager2.convertNPCs10 - count:", #tList);
	for _, nodeNPC in ipairs(tList) do
		VersionManager2.migrateChar10(nodeNPC);
	end
end

-- Migration v10: Abilities score -> base + bonus model
function migrateChar10(nodeChar)
	if not nodeChar then
		return;
	end

	local sName = DB.getValue(nodeChar, "name", "");
	local sPath = DB.getPath(nodeChar);
	Debug.console("VersionManager2.migrateChar10 - record:", sPath, "(" .. sName .. ")");

	for _, nodeAbility in ipairs(DB.getChildList(nodeChar, "abilities")) do
		local nScore = DB.getValue(nodeAbility, "score", 0);
		Debug.console("  " .. DB.getName(nodeAbility) .. ": score=" .. tostring(nScore) .. " -> base=" .. tostring(nScore) .. ", bonus=0");
		DB.setValue(nodeAbility, "base", "number", nScore);
		DB.setValue(nodeAbility, "bonus", "number", 0);
	end
end
