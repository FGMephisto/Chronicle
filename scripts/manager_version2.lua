--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local rsname = "5E";
local rsmajorversion = 8;

function onInit()
	if Session.IsHost then
		VersionManager2.updateCampaign();
	end

	DB.addEventHandler("onAuxCharLoad", VersionManager2.onCharImport);
	DB.addEventHandler("onImport", VersionManager2.onImport);
	Module.addEventHandler("onModuleLoad", VersionManager2.onModuleLoad);
end

function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	VersionManager2.updateChar(nodePC, aMajor[rsname]);
end

function onImport(node)
	local aPath = StringManager.split(DB.getPath(node), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		VersionManager2.updateChar(node, aMajor[rsname]);
	end
end

function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	VersionManager2.updateModule(sModule, aMajor[rsname]);
end

function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	if nVersion < rsmajorversion then
		if nVersion < 2 then
			VersionManager2.migrateChar2(nodePC);
		end
		if nVersion < 5 then
			VersionManager2.migrateChar5(nodePC);
		end
		if nVersion < 7 then
			VersionManager2.migrateChar7(nodePC);
		end
		if nVersion < 8 then
			VersionManager2.migrateChar8(nodePC);
		end
	end
end

function updateCampaign()
	local _, _, aMajor, _ = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end

	if major > 0 and major < rsmajorversion then
		ChatManager.SystemMessage("Migrating campaign database to latest data version.");
		DB.backup();

		if major < 2 then
			VersionManager2.convertCharacters2();
		end
		if major < 4 then
			VersionManager2.convertPSEnc4();
		end
		if major < 5 then
			VersionManager2.convertCharacters5();
		end
		if major < 6 then
			VersionManager2.convertEncounters6();
		end
		if major < 7 then
			VersionManager2.convertCharacters7();
		end
		if major < 8 then
			VersionManager2.convertCharacters8();
			VersionManager2.convertItems8();
		end
	end
end

function updateModule(sModule, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	if nVersion < rsmajorversion then
		local nodeRoot = DB.getRoot(sModule);

		if nVersion < 5 then
			VersionManager2.convertPregenCharacters5(nodeRoot);
		end
		if nVersion < 6 then
			if sModule == "DD MM Monster Manual" then
				Module.revert(sModule);
			end
		end
		if nVersion < 7 then
			VersionManager2.convertPregenCharacters7(nodeRoot);
		end
		if nVersion < 8 then
			VersionManager2.convertPregenCharacters8(nodeRoot);
			VersionManager2.convertItems8(nodeRoot);
		end
	end
end

function migrateItem8(nodeItem, nodeRoot)
	if DB.getValue(nodeItem, "istemplate", 0) ~= 1 then
		return;
	end
	local nodeTargetList;
	if nodeRoot then
		nodeTargetList = DB.createChild(nodeRoot, "itemtemplate");
	else
		nodeTargetList = DB.createNode("itemtemplate");
	end
	if not nodeTargetList then
		return;
	end
	local nodeItemTemplate = DB.createChild(nodeTargetList);
	if not nodeItemTemplate then
		return;
	end
	DB.copyNode(nodeItem, nodeItemTemplate);
	DB.deleteNode(nodeItem);
end

function convertItems8(nodeRoot)
	if nodeRoot then
		for _,nodeItem in ipairs(DB.getChildList(nodeRoot, "item")) do
			VersionManager2.migrateItem8(nodeItem, nodeRoot);
		end
		for _,nodeItem in ipairs(DB.getChildList(nodeRoot, "reference.equipmentdata")) do
			VersionManager2.migrateItem8(nodeItem, nodeRoot);
		end
	else
		for _,nodeItem in ipairs(DB.getChildList("item")) do
			VersionManager2.migrateItem8(nodeItem);
		end
	end
end

function migrateChar8(nodeChar)
	-- Migrate PC spells to specify "magic" save type in order to support Magic Resistance trait
	local aSpellGroups = {};
	for _,vGroup in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		local sPowerGroup = DB.getValue(vGroup, "name", "");
		if (sPowerGroup ~= "") and (DB.getValue(vGroup, "castertype", "") == "memorization") then
			aSpellGroups[sPowerGroup] = true;
		end
	end
	for _,nodePower in ipairs(DB.getChildList(nodeChar, "powers")) do
		local sGroup = DB.getValue(nodePower, "group", "");
		if aSpellGroups[sGroup] then
			for _,nodeAction in ipairs(DB.getChildList(nodePower, "actions")) do
				local sType = DB.getValue(nodeAction, "type", "");
				if sType == "cast" then
					DB.setValue(nodeAction, "savemagic", "number", 1);
				end
			end
		end
	end
end

function convertPregenCharacters8(nodeRoot)
	for _,nodeChar in ipairs(DB.getChildList(nodeRoot, "pregencharsheet")) do
		VersionManager2.migrateChar8(nodeChar);
	end
end

function convertCharacters8()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		VersionManager2.migrateChar8(nodeChar);
	end
end

function migrateChar7(nodeChar)
	-- Migrate warlock spell slots from standard spell slots
	-- NOTE: Don't do anything if multiclass with both pact magic and spellcasting
	local bPactMagicOnly = false;
	for _,nodeClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nCastLevelInvMult = DB.getValue(nodeClass, "casterlevelinvmult", 0);
		if nCastLevelInvMult > 0 then
			local nPactMagic = DB.getValue(nodeClass, "casterpactmagic", 0);
			if nPactMagic == 1 then
				bPactMagicOnly = true;
			else
				bPactMagicOnly = false;
				break;
			end
		end
	end
	if bPactMagicOnly then
		for i = 1, PowerManager.SPELL_LEVELS do
			local nSlotsMax = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0);
			local nSlotsUsed = DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".used", 0);
			DB.setValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", "number", nSlotsMax);
			DB.setValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".used", "number", nSlotsUsed);
			DB.setValue(nodeChar, "powermeta.spellslots" .. i .. ".max", "number", 0);
			DB.setValue(nodeChar, "powermeta.spellslots" .. i .. ".used", "number", 0);
		end
	end
end

function convertPregenCharacters7(nodeRoot)
	for _,nodeChar in ipairs(DB.getChildList(nodeRoot, "pregencharsheet")) do
		VersionManager2.migrateChar7(nodeChar);
	end
end

function convertCharacters7()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		VersionManager2.migrateChar7(nodeChar);
	end
end

function migrateEncounter6(nodeRecord)
	for _,nodeNPC in ipairs(DB.getChildList(nodeRecord, "npclist")) do
		local sClass, sRecord = DB.getValue(nodeNPC, "link", "", "");
		local sBadNPCID = sRecord:match ("npc%.(.*)@DD MM Monster Manual");
		if sBadNPCID then
			DB.setValue(nodeNPC, "link", "windowreference", sClass, "reference.npcdata." .. sBadNPCID .. "@DD MM Monster Manual");
		end
	end
end

function convertEncounters6()
	for _,nodeEnc in ipairs(DB.getChildList("battle")) do
		VersionManager2.migrateEncounter6(nodeEnc);
	end
end

function migrateChar5(nodeChar)
	-- Feature list can either be set up by source and level or by link, depending usually on whether they are pregens
	local aSpellCastFeatureBySource = {};
	local aSpellCastFeatureByPath = {};
	for _,nodeFeature in ipairs(DB.getChildList(nodeChar, "featurelist")) do
		local sFeature = DB.getValue(nodeFeature, "name", "");
		if sFeature:lower():sub(1, 12) == "spellcasting" then
			local sSource = DB.getValue(nodeFeature, "source", "");
			if sSource ~= "" then
				aSpellCastFeatureBySource[sSource] = DB.getValue(nodeFeature, "level", 1);
			else
				local sPath;
				_, sPath = DB.getValue(nodeFeature, "link", "", "");
				local sPathSansModule = StringManager.split(sPath, "@")[1];
				if sPathSansModule then
					local aSplit = StringManager.split(sPathSansModule, ".");
					if #aSplit == 5 then
						aSpellCastFeatureByPath[aSplit[1] .. "." .. aSplit[2] .. "." .. aSplit[3]] = tonumber(aSplit[5]:match("%d$")) or 1;
					end
				end
			end
		end
	end

	-- If spellcasting feature added with source and level, then match the class name
	for kClass, vSpellCastMult in pairs(aSpellCastFeatureBySource) do
		for _,nodeClass in ipairs(DB.getChildList(nodeChar, "classes")) do
			local sName = DB.getValue(nodeClass, "name", "");
			if kClass == sName then
				DB.setValue(nodeClass, "casterlevelinvmult", "number", vSpellCastMult);
			end
		end
	end

	-- If spellcasting feature added without source and level, then use link to match
	for kClassPath, vSpellCastMult in pairs(aSpellCastFeatureByPath) do
		for _,nodeClass in ipairs(DB.getChildList(nodeChar, "classes")) do
			local sPath;
			_, sPath = DB.getValue(nodeClass, "shortcut", "", "");
			local sPathSansModule = StringManager.split(sPath, "@")[1];
			if sPathSansModule == kClassPath then
				DB.setValue(nodeClass, "casterlevelinvmult", "number", vSpellCastMult);
			end
		end
	end
end

function convertPregenCharacters5(nodeRoot)
	for _,nodeChar in ipairs(DB.getChildList(nodeRoot, "pregencharsheet")) do
		VersionManager2.migrateChar5(nodeChar);
	end
end

function convertCharacters5()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		VersionManager2.migrateChar5(nodeChar);
	end
end

function convertPSEnc4()
	for _,vEnc in ipairs(DB.getChildList("partysheet.encounters")) do
		DB.setValue(vEnc, "exp", "number", DB.getValue(vEnc, "xp", "number"));
	end
end

function migrateChar2(nodeChar)
	for _,nodeAbility in ipairs(DB.getChildList(nodeChar, "abilitylist")) do
		local nodeFeatureList = DB.createChild(nodeChar, "featurelist");
		local nodeNewFeature = DB.createChild(nodeFeatureList);
		DB.copyNode(nodeAbility, nodeNewFeature);
	end
	DB.deleteChild(nodeChar, "abilitylist");

	for _,nodeWeapon in ipairs(DB.getChildList(nodeChar, "weaponlist")) do
		if not DB.getChild(nodeWeapon, "damagelist") then
			local nodeDmgList = DB.createChild(nodeWeapon, "damagelist");
			if nodeDmgList then
				local nodeDmg = DB.createChild(nodeDmgList);
				if nodeDmg then
					DB.setValue(nodeDmg, "dice", "dice", DB.getValue(nodeWeapon, "damagedice", {}));
					DB.setValue(nodeDmg, "stat", "string", DB.getValue(nodeWeapon, "damagestat", ""));
					DB.setValue(nodeDmg, "bonus", "number", DB.getValue(nodeWeapon, "damagebonus", 0));
					DB.setValue(nodeDmg, "type", "string", DB.getValue(nodeWeapon, "damagetype", ""));

					DB.deleteChild(nodeWeapon, "damagedice");
					DB.deleteChild(nodeWeapon, "damagestat");
					DB.deleteChild(nodeWeapon, "damagebonus");
					DB.deleteChild(nodeWeapon, "damagetype");
				end
			end
		end
	end

	for _,nodePower in ipairs(DB.getChildList(nodeChar, "powers")) do
		for _,nodeAction in ipairs(DB.getChildList(nodePower, "actions")) do
			local sType = DB.getValue(nodeAction, "type", "");
			if sType == "damage" then
				if not DB.getChild(nodeAction, "damagelist") then
					local nodeDmgList = DB.createChild(nodeAction, "damagelist");
					if nodeDmgList then
						local nodeDmg = DB.createChild(nodeDmgList);
						if nodeDmg then
							local sDmgType = DB.getValue(nodeAction, "dmgtype", "");

							DB.setValue(nodeDmg, "dice", "dice", DB.getValue(nodeAction, "dmgdice", {}));
							DB.setValue(nodeDmg, "stat", "string", DB.getValue(nodeAction, "dmgstat", ""));
							DB.setValue(nodeDmg, "bonus", "number", DB.getValue(nodeAction, "dmgmod", 0));
							DB.setValue(nodeDmg, "type", "string", sDmgType);

							local sDmgStat2 = DB.getValue(nodeAction, "dmgstat2", "");
							if sDmgStat2 ~= "" then
								local nodeDmg2 = DB.createChild(nodeDmgList);
								DB.setValue(nodeDmg2, "stat", "string", sDmgStat2);
								DB.setValue(nodeDmg2, "type", "string", sDmgType);
							end

							DB.deleteChild(nodeAction, "dmgdice");
							DB.deleteChild(nodeAction, "dmgstat");
							DB.deleteChild(nodeAction, "dmgstat2");
							DB.deleteChild(nodeAction, "dmgmod");
							DB.deleteChild(nodeAction, "dmgtype");
						end
					end
				end
			elseif sType == "heal" then
				if not DB.getChild(nodeAction, "heallist") then
					local nodeDmgList = DB.createChild(nodeAction, "heallist");
					if nodeDmgList then
						local nodeHeal = DB.createChild(nodeDmgList);
						if nodeHeal then
							DB.setValue(nodeHeal, "dice", "dice", DB.getValue(nodeAction, "hdice", {}));
							DB.setValue(nodeHeal, "stat", "string", DB.getValue(nodeAction, "hstat", ""));
							DB.setValue(nodeHeal, "bonus", "number", DB.getValue(nodeAction, "hmod", 0));

							local sStat2 = DB.getValue(nodeAction, "hstat2", "");
							if sStat2 ~= "" then
								local nodeHeal2 = DB.createChild(nodeDmgList);
								DB.setValue(nodeHeal2, "stat", "string", sStat2);
							end

							DB.deleteChild(nodeAction, "hdice");
							DB.deleteChild(nodeAction, "hstat");
							DB.deleteChild(nodeAction, "hstat2");
							DB.deleteChild(nodeAction, "hmod");
						end
					end
				end
			end
		end
	end
end

function convertCharacters2()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		VersionManager2.migrateChar2(nodeChar);
	end
end
