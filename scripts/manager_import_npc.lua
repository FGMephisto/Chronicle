--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	ImportNPCManager.registerImportModes();
end

function registerImportModes()
	if OptionsManager.isOption("GAVE", "2024") then
		ImportUtilityManager.registerImportMode("npc", "2024", Interface.getString("import_mode_2024"), ImportNPCManager.import2024);
		ImportUtilityManager.registerImportMode("npc", "2024_dndb", Interface.getString("import_mode_dndb_2024"), ImportNPCManager.importDNDB2024);
		ImportUtilityManager.registerImportMode("npc", "2022", Interface.getString("import_mode_2022"), ImportNPCManager.import2022);
	else
		ImportUtilityManager.registerImportMode("npc", "2022", Interface.getString("import_mode_2022"), ImportNPCManager.import2022);
		ImportUtilityManager.registerImportMode("npc", "2024", Interface.getString("import_mode_2024"), ImportNPCManager.import2024);
		ImportUtilityManager.registerImportMode("npc", "2024_dndb", Interface.getString("import_mode_dndb_2024"), ImportNPCManager.importDNDB2024);
	end
end

function performImport(w)
	local tImportMode = ImportUtilityManager.getImportMode("npc", w.mode.getSelectedValue());
	if tImportMode then
		tImportMode.fn(w.statblock.getValue(), w.description.getValue());
	end
end

--
--	Built-in supported import modes
--

local _sStoredInitiativeBonus;
function import2024(sStats, sDesc)
	-- Track state information
	_sStoredInitiativeBonus = nil;
	local tImportState = ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name on Line 1
	ImportNPCManager.importHelperName(tImportState);

	-- Assume size/type/alignment on Line 2
	ImportNPCManager.importHelperSizeTypeAlignment(tImportState);

	-- Assume AC on Line 3, HP on Line 4, and Speed on Line 5
	ImportNPCManager.importHelperACHPSpeed2024(tImportState);

	-- Assume ability headers start on Line 6
	-- Line 6: MOD SAVE MOD SAVE MOD SAVE
	-- Line 7: Str X +M +S {tab} Dex X +M +S {tab} Con X +M +S
	-- Line 8: Int X +M +S {tab} Wis X +M +S {tab} Cha X +M +S
	ImportNPCManager.importHelperAbilities2024(tImportState);

	-- Assume the following optional fields in the following order:
	--		Saving throws
	--		Skills
	--		Damage Vulnerabilities,
	--		Damage Resistances
	--		Damage Immunities,
	--		Condition Immunities
	--		Senses
	--		Languages
	--		Challenge
	ImportNPCManager.importHelperOptionalFields2024(tImportState);

	-- Assume NPC actions appear next with the following headers: (Assume Traits until a header found)
	--		Traits, Actions, Bonus Actions, Reactions, Legendary Actions, Lair Actions
	ImportNPCManager.importHelperActions(tImportState);

	-- Update Description by adding the statblock text as well
	ImportNPCManager.finalizeDescription(tImportState);

	ImportNPCManager.importHelperVersion(tImportState, "2024");

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", tImportState.node);
end

function importDNDB2024(sStats, sDesc)
	-- Track state information
	local tImportState = ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name on Line 1
	ImportNPCManager.importHelperName(tImportState);

	-- Assume size/type/alignment on Line 2
	ImportNPCManager.importHelperSizeTypeAlignment(tImportState);

	-- Assume AC on Line 3, HP on Line 4, and Speed on Line 5
	ImportNPCManager.importHelperACHPSpeed2024(tImportState);

	-- Assume all abilities start on line 6 with a single line per
	-- ability and a header of Mod Save at the start and after CON
	ImportNPCManager.importHelperAbilitiesDNDB2024(tImportState);

	-- Assume the following optional fields in the following order:
	--		Saving throws
	--		Skills
	--		Damage Vulnerabilities,
	--		Damage Resistances
	--		Damage Immunities,
	--		Condition Immunities
	--		Senses
	--		Languages
	--		Challenge
	ImportNPCManager.importHelperOptionalFields2024(tImportState);

	-- Assume NPC actions appear next with the following headers: (Assume Traits until a header found)
	--		Traits, Actions, Bonus Actions, Reactions, Legendary Actions, Lair Actions
	ImportNPCManager.importHelperActions(tImportState);

	-- Update Description by adding the statblock text as well
	ImportNPCManager.finalizeDescription(tImportState);

	ImportNPCManager.importHelperVersion(tImportState,"2024");

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", tImportState.node);
end

function import2022(sStats, sDesc)
	-- Track state information
	local tImportState = ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name on Line 1
	ImportNPCManager.importHelperName(tImportState);

	-- Assume size/type/alignment on Line 2
	ImportNPCManager.importHelperSizeTypeAlignment(tImportState);

	-- Assume AC on Line 3, HP on Line 4, and Speed on Line 5
	ImportNPCManager.importHelperACHPSpeed2014(tImportState);

	-- Assume ability headers on Line 6, and ability scores/bonuses on Line 7
	ImportNPCManager.importHelperAbilities2014(tImportState);

	-- Assume the following optional fields in the following order:
	--		Saving throws
	--		Skills
	--		Damage Vulnerabilities,
	--		Damage Resistances
	--		Damage Immunities,
	--		Condition Immunities
	--		Senses
	--		Languages
	--		Challenge
	ImportNPCManager.importHelperOptionalFields2014(tImportState);

	-- Assume NPC actions appear next with the following headers: (Assume Traits until a header found)
	--		Traits, Actions, Bonus Actions, Reactions, Legendary Actions, Lair Actions
	ImportNPCManager.importHelperActions(tImportState);

	-- Update Description by adding the statblock text as well
	ImportNPCManager.finalizeDescription(tImportState);

	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", tImportState.node);
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName(tImportState)
	-- Name
	ImportNPCManager.nextImportLine(tImportState);
	DB.setValue(tImportState.node, "name", "string", tImportState.sActiveLine);
	ImportNPCManager.addStatOutput(tImportState, string.format("<h>%s</h>", tImportState.sActiveLine));

	-- Token
	ImportUtilityManager.setDefaultToken(tImportState.node);
end

function importHelperVersion(tImportState, version)
	DB.setValue(tImportState.node, "version", "string", version);
end

-- Assumes size/type/alignment on next line; and of the form "<size> <type>, <alignment>"
function importHelperSizeTypeAlignment(tImportState)
	-- Example: Huge Fiend (Demon), Chaotic Evil
	ImportNPCManager.nextImportLine(tImportState);
	if (tImportState.sActiveLine or "") ~= "" then
		local sLine = tImportState.sActiveLine;
		local sAlignment = "";

		-- Find the last comma and split the string
		local sTypePart;
		local nLastComma = sLine:match(".*()%s*,%s*.*")
		if nLastComma then
			sAlignment = sLine:sub(nLastComma + 1)
			sTypePart = sLine:sub(1, nLastComma - 1)
		else
			-- No comma found, treat entire line as type and leave alignment empty
			sTypePart = sLine
		end

		-- Split size and type
		local tWords = StringManager.splitTokens(sTypePart);
		local sSize = tWords[1] or "";
		local sType = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "size", "string", sSize);
		DB.setValue(tImportState.node, "type", "string", sType);
		DB.setValue(tImportState.node, "alignment", "string", StringManager.trim(sAlignment));

		ImportNPCManager.addStatOutput(tImportState, string.format("<p><b><i>%s</i></b></p>", sLine));
	end
end

-- Assumes AC/HP/Speed on next 3 lines in the following formats:
-- 		"AC <ac> <actext>"
--		"HP <hp> <hd>"
--		"Speed <speed>"
function importHelperACHPSpeed2024(tImportState)
	local tMidOutput = {};

	-- Example: AC 12		Initiative +2 (12)
	ImportNPCManager.nextImportLine(tImportState); -- Line 3
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sAC = tWords[2] or "";
		local sACText = "";
		local sInitiativeBonus = "";
		local sInitiativeDefault = "";
		local isSummonAC = false;

		-- Check for different patterns in the AC line
		for i = 3, #tWords do
			if tWords[i]:lower() == "initiative" then
				sInitiativeBonus = tWords[i+1] or "";
				sInitiativeDefault = tWords[i+2] or "";
				-- Remove the parenthesis from the initiative default value
				sInitiativeDefault = sInitiativeDefault:gsub("[%(%)]", "");
				break;
			elseif tWords[i]:lower() == "per" and tWords[i+1] and tWords[i+1]:lower() == "spell" and tWords[i+2] and tWords[i+2]:lower() == "level" then
				-- Handling AC based on spell level
				isSummonAC = true;
				local baseAC = tonumber(tWords[2]);
				local modAC = tonumber(tWords[4]);
				DB.setValue(tImportState.node, "summon", "number", 1);
				DB.setValue(tImportState.node, "summon_ac_base", "number", baseAC);
				DB.setValue(tImportState.node, "summon_ac_mod", "number", modAC);
				table.insert(tMidOutput, string.format("<b>Armor Class</b> %d + 1 per spell level", baseAC));
				break;
			else
				sACText = sACText .. " " .. tWords[i];
			end
		end

		if not isSummonAC then
			sACText = StringManager.trim(sACText);

			DB.setValue(tImportState.node, "ac", "number", sAC);
			DB.setValue(tImportState.node, "actext", "string", sACText);
			-- Save the initiative value for later and write it out once we know the Dex modifier

			--DB.setValue(tImportState.node, "initiativebonus", "string", sInitiativeBonus);
			--DB.setValue(tImportState.node, "initiativedefault", "number", tonumber(sInitiativeDefault));
			_sStoredInitiativeBonus = sInitiativeBonus;
			table.insert(tMidOutput, string.format("<b>Armor Class</b> %s %s", sAC, sACText));
			if sInitiativeBonus ~= "" and sInitiativeDefault ~= "" then
				table.insert(tMidOutput, string.format("<b>Initiative</b> %s (%s)", sInitiativeBonus, sInitiativeDefault));
			end
		end
	end

	-- Example: HP 464 (32d12 + 256) or HP 5 + 10 per spell level (the steed has a number of Hit Dice [d10s] equal to the spell’s level)
	ImportNPCManager.nextImportLine(tImportState); -- Line 4
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sHP = tWords[2] or "";
		local sHD = table.concat(tWords, " ", 3) or "";

		-- Check for "per spell level" pattern in HP line
		if sHD:match("per spell level") then
			isSummonHP = true;
			local baseHP = tonumber(tWords[2]);
			local modHP = tonumber(tWords[4]);
			DB.setValue(tImportState.node, "summon", "number", 1);
			DB.setValue(tImportState.node, "summon_hp_base", "number", baseHP);
			DB.setValue(tImportState.node, "summon_hp_mod", "number", modHP);
			DB.setValue(tImportState.node, "summon_hp_mod_threshold", "number", 0);
			table.insert(tMidOutput, string.format("<b>Hit Points</b> %d + %d per spell level", baseHP, modHP));
		else
			DB.setValue(tImportState.node, "hp", "number", sHP);
			DB.setValue(tImportState.node, "hd", "string", sHD);
			table.insert(tMidOutput, string.format("<b>Hit Points</b> %s %s", sHP, sHD));
		end
	end

	-- Example: Speed 50 ft., swim 50 ft.
	ImportNPCManager.nextImportLine(tImportState); -- Line 5
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sSpeed = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "speed", "string", sSpeed);
		table.insert(tMidOutput, string.format("<b>Speed</b> %s", sSpeed));
	end

	if #tMidOutput > 0 then
		ImportNPCManager.addStatOutput(tImportState, string.format("<p>%s</p>", table.concat(tMidOutput, "&#13;")));
	end
end

-- Assumes AC/HP/Speed on next 3 lines in the following formats:
-- 		"Armor Class <ac> <actext>"
--		"Hit Points <hp> <hd>"
--		"Speed <speed>"
function importHelperACHPSpeed2014(tImportState)
	local tMidOutput = {};

	-- Example: Armor Class 22 (natural armor)
	ImportNPCManager.nextImportLine(tImportState); -- Line 3
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sAC = tWords[3] or "";
		local sACText = table.concat(tWords, " ", 4) or "";

		DB.setValue(tImportState.node, "ac", "number", sAC);
		DB.setValue(tImportState.node, "actext", "string", sACText);
		table.insert(tMidOutput, string.format("<b>Armor Class</b> %s %s", sAC, sACText));
	end

	-- Example: Hit Points 464 (32d12 + 256)
	ImportNPCManager.nextImportLine(tImportState); -- Line 4
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sHP = tWords[3] or "";
		local sHD = table.concat(tWords, " ", 4) or "";

		DB.setValue(tImportState.node, "hp", "number", sHP);
		DB.setValue(tImportState.node, "hd", "string", sHD);
		table.insert(tMidOutput, string.format("<b>Hit Points</b> %s %s", sHP, sHD));
	end

	-- Example: Speed 50 ft., swim 50 ft.
	ImportNPCManager.nextImportLine(tImportState); -- Line 5
	if (tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sSpeed = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "speed", "string", sSpeed);
		table.insert(tMidOutput, string.format("<b>Speed</b> %s", sSpeed));
	end

	if #tMidOutput > 0 then
		ImportNPCManager.addStatOutput(tImportState, string.format("<p>%s</p>", table.concat(tMidOutput, "&#13;")));
	end
end

	-- Assume ability headers start on Line 6
	-- Line 6: MOD SAVE MOD SAVE MOD SAVE
	-- Line 7: Str X +M +S {tab} Dex X +M +S {tab} Con X +M +S
	-- Line 8: Int X +M +S {tab} Wis X +M +S {tab} Cha X +M +S

function importHelperAbilities2024(tImportState)
	-- Check next line for ability list
	ImportNPCManager.nextImportLine(tImportState); -- Line 6

	-- Check for short ability list
	local sSTR, sDEX, sCON, sINT, sWIS, sCHA;
	local sSTRBonus, sDEXBonus, sCONBonus, sINTBonus, sWISBonus, sCHABonus;
	local sSTRSave, sDEXSave, sCONSave, sINTSave, sWISSave, sCHASave;
	local sSTRSaveMod, sDEXSaveMod, sCONSaveMod, sINTSaveMod, sWISSaveMod, sCHASaveMod = "0", "0", "0", "0", "0", "0"

	-- Line 7: Str X +M +S {tab} Dex X +M +S {tab} Con X +M +S
	ImportNPCManager.nextImportLine(tImportState); -- Line 7
	local tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);

	if (StringManager.trim(tAbilityWords[1] or "")):lower() == "str" then
		sSTR = tAbilityWords[2] or "";
		sSTRBonus = (tAbilityWords[3] or ""):match("[+-]?%d+");
		sSTRSave = (tAbilityWords[4] or ""):match("[+-]?%d+");
		-- Calculate the difference and store it as a string
		if sSTRBonus and sSTRSave then
			sSTRSaveMod = tostring(tonumber(sSTRSave) - tonumber(sSTRBonus));
		end
	end
	if (StringManager.trim(tAbilityWords[5] or "")):lower() == "dex" then
		sDEX = tAbilityWords[6] or "";
		sDEXBonus = (tAbilityWords[7] or ""):match("[+-]?%d+");
		sDEXSave = (tAbilityWords[8] or ""):match("[+-]?%d+");
		if sDEXBonus and sDEXSave then
			sDEXSaveMod = tostring(tonumber(sDEXSave) - tonumber(sDEXBonus));
		end
	end
	if (StringManager.trim(tAbilityWords[9] or "")):lower() == "con" then
		sCON = tAbilityWords[10] or "";
		sCONBonus = (tAbilityWords[11] or ""):match("[+-]?%d+");
		sCONSave = (tAbilityWords[12] or ""):match("[+-]?%d+");
		if sCONBonus and sCONSave then
			sCONSaveMod = tostring(tonumber(sCONSave) - tonumber(sCONBonus));
		end
	end

	-- Line 8: Int X +M +S {tab} Wis X +M +S {tab} Cha X +M +S
	ImportNPCManager.nextImportLine(tImportState); -- Line 8
	tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);

	if (StringManager.trim(tAbilityWords[1] or "")):lower() == "int" then
		sINT = tAbilityWords[2] or "";
		sINTBonus = (tAbilityWords[3] or ""):match("[+-]?%d+");
		sINTSave = (tAbilityWords[4] or ""):match("[+-]?%d+");
		if sINTBonus and sINTSave then
			sINTSaveMod = tostring(tonumber(sINTSave) - tonumber(sINTBonus));
		end
	end
	if (StringManager.trim(tAbilityWords[5] or "")):lower() == "wis" then
		sWIS = tAbilityWords[6] or "";
		sWISBonus = (tAbilityWords[7] or ""):match("[+-]?%d+");
		sWISSave = (tAbilityWords[8] or ""):match("[+-]?%d+");
		if sWISBonus and sWISSave then
			sWISSaveMod = tostring(tonumber(sWISSave) - tonumber(sWISBonus));
		end
	end
	if (StringManager.trim(tAbilityWords[9] or "")):lower() == "cha" then
		sCHA = tAbilityWords[10] or "";
		sCHABonus = (tAbilityWords[11] or ""):match("[+-]?%d+");
		sCHASave = (tAbilityWords[12] or ""):match("[+-]?%d+");
		if sCHABonus and sCHASave then
			sCHASaveMod = tostring(tonumber(sCHASave) - tonumber(sCHABonus));
		end
	end

	if not sSTR then
		ImportNPCManager.nextImportLine(tImportState, -1);
		return;
	end

	DB.setValue(tImportState.node, "abilities.strength.score", "number", sSTR);
	DB.setValue(tImportState.node, "abilities.dexterity.score", "number", sDEX);
	DB.setValue(tImportState.node, "abilities.constitution.score", "number", sCON);
	DB.setValue(tImportState.node, "abilities.wisdom.score", "number", sWIS);
	DB.setValue(tImportState.node, "abilities.intelligence.score", "number", sINT);
	DB.setValue(tImportState.node, "abilities.charisma.score", "number", sCHA);

	DB.setValue(tImportState.node, "abilities.strength.bonus", "number", sSTRBonus);
	DB.setValue(tImportState.node, "abilities.dexterity.bonus", "number", sDEXBonus);
	DB.setValue(tImportState.node, "abilities.constitution.bonus", "number", sCONBonus);
	DB.setValue(tImportState.node, "abilities.wisdom.bonus", "number", sWISBonus);
	DB.setValue(tImportState.node, "abilities.intelligence.bonus", "number", sINTBonus);
	DB.setValue(tImportState.node, "abilities.charisma.bonus", "number", sCHABonus);

	DB.setValue(tImportState.node, "abilities.strength.savemodifier", "number", sSTRSaveMod);
	DB.setValue(tImportState.node, "abilities.dexterity.savemodifier", "number", sDEXSaveMod);
	DB.setValue(tImportState.node, "abilities.constitution.savemodifier", "number", sCONSaveMod);
	DB.setValue(tImportState.node, "abilities.wisdom.savemodifier", "number", sWISSaveMod);
	DB.setValue(tImportState.node, "abilities.intelligence.savemodifier", "number", sINTSaveMod);
	DB.setValue(tImportState.node, "abilities.charisma.savemodifier", "number", sCHASaveMod);

	if _sStoredInitiativeBonus and sDEXBonus then
		sInitiativeBonusMisc = tostring(tonumber(_sStoredInitiativeBonus) - tonumber(sDEXBonus));
		DB.setValue(tImportState.node, "initiative.misc", "number", 0);
	end

	ImportNPCManager.addStatOutput(tImportState, "<table>");
	ImportNPCManager.addStatOutput(tImportState, "<tr>");
	ImportNPCManager.addStatOutput(tImportState, "<td colspan='2'></td><td>MOD</td><td>SAVE</td>");
	ImportNPCManager.addStatOutput(tImportState, "<td colspan='2'></td><td>MOD</td><td>SAVE</td>");
	ImportNPCManager.addStatOutput(tImportState, "<td colspan='2'></td><td>MOD</td><td>SAVE</td>");
	ImportNPCManager.addStatOutput(tImportState, "</tr>");
	ImportNPCManager.addStatOutput(tImportState, "<tr>");
	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>STR</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sSTR or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sSTRBonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sSTRSave or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>DEX</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sDEX or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sDEXBonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sDEXSave or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>CON</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sCON or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sCONBonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sCONSave or ""));
	ImportNPCManager.addStatOutput(tImportState, "</tr>");
	ImportNPCManager.addStatOutput(tImportState, "<tr>");

	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>INT</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sINT or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sINTBonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sINTSave or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>WIS</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sWIS or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sWISBonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sWISSave or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>CHA</b></td>"));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td><b>%s</b></td>", sCHA or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sCHABonus or ""));
		ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s</td>", sCHASave or ""));
	ImportNPCManager.addStatOutput(tImportState, "</tr>");
	ImportNPCManager.addStatOutput(tImportState, "</table>");
end

	-- Assume ability headers start on Line 6
	-- Line  6: Mod Save
	-- Line  7: Str X +M +S
	-- Line  8: Dex X +M +S
	-- Line  9: Con X +M +S
	-- Line 10: Mod Save
	-- Line 11: Int X +M +S
	-- Line 12: Wis X +M +S
	-- Line 13: Cha X +M +S
function importHelperAbilitiesDNDB2024(tImportState)
    -- First line is "Mod Save" header, skip this
    ImportNPCManager.nextImportLine(tImportState);

    -- Initialize variables for ability scores, bonuses, and saves
    local sSTR, sDEX, sCON, sINT, sWIS, sCHA;
    local sSTRBonus, sDEXBonus, sCONBonus, sINTBonus, sWISBonus, sCHABonus;
    local sSTRSave, sDEXSave, sCONSave, sINTSave, sWISSave, sCHASave;

    -- Parsing abilities for STR, DEX, and CON (first set of abilities)
    for i = 1, 3 do
        ImportNPCManager.nextImportLine(tImportState); -- Process each ability line (STR, DEX, CON)
        local tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);

        -- STR
        if i == 1 then
            sSTR = tAbilityWords[2] or "";
            sSTRBonus = tAbilityWords[3] or "";
            sSTRSave = tAbilityWords[4] or "";
        -- DEX
        elseif i == 2 then
            sDEX = tAbilityWords[2] or "";
            sDEXBonus = tAbilityWords[3] or "";
            sDEXSave = tAbilityWords[4] or "";
        -- CON
        elseif i == 3 then
            sCON = tAbilityWords[2] or "";
            sCONBonus = tAbilityWords[3] or "";
            sCONSave = tAbilityWords[4] or "";
        end
    end

    -- Second line for "Mod Save" header, skip this
    ImportNPCManager.nextImportLine(tImportState);

    -- Parsing abilities for INT, WIS, and CHA (second set of abilities)
    for i = 1, 3 do
        ImportNPCManager.nextImportLine(tImportState); -- Process each ability line (INT, WIS, CHA)
        local tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);

        -- INT
        if i == 1 then
            sINT = tAbilityWords[2] or "";
            sINTBonus = tAbilityWords[3] or "";
            sINTSave = tAbilityWords[4] or "";
        -- WIS
        elseif i == 2 then
            sWIS = tAbilityWords[2] or "";
            sWISBonus = tAbilityWords[3] or "";
            sWISSave = tAbilityWords[4] or "";
        -- CHA
        elseif i == 3 then
            sCHA = tAbilityWords[2] or "";
            sCHABonus = tAbilityWords[3] or "";
            sCHASave = tAbilityWords[4] or "";
        end
    end

	local sSTRSaveMod, sDEXSaveMod, sCONSaveMod, sINTSaveMod, sWISSaveMod, sCHASaveMod = "0", "0", "0", "0", "0", "0"
	if sSTRBonus and sSTRSave then
		sSTRSaveMod = tostring(tonumber(sSTRSave) - tonumber(sSTRBonus));
	end
	if sDEXBonus and sDEXSave then
		sDEXSaveMod = tostring(tonumber(sDEXSave) - tonumber(sDEXBonus));
	end
	if sCONBonus and sCONSave then
		sCONSaveMod = tostring(tonumber(sCONSave) - tonumber(sCONBonus));
	end
	if sINTBonus and sINTSave then
		sINTSaveMod = tostring(tonumber(sINTSave) - tonumber(sINTBonus));
	end
	if sWISBonus and sWISSave then
		sWISSaveMod = tostring(tonumber(sWISSave) - tonumber(sWISBonus));
	end
	if sCHABonus and sCHASave then
		sCHASaveMod = tostring(tonumber(sCHASave) - tonumber(sCHABonus));
	end

    -- Set the values in the DB for abilities, modifiers, and saves
    DB.setValue(tImportState.node, "abilities.strength.score", "number", sSTR);
    DB.setValue(tImportState.node, "abilities.dexterity.score", "number", sDEX);
    DB.setValue(tImportState.node, "abilities.constitution.score", "number", sCON);
    DB.setValue(tImportState.node, "abilities.intelligence.score", "number", sINT);
    DB.setValue(tImportState.node, "abilities.wisdom.score", "number", sWIS);
    DB.setValue(tImportState.node, "abilities.charisma.score", "number", sCHA);

    DB.setValue(tImportState.node, "abilities.strength.bonus", "number", sSTRBonus);
    DB.setValue(tImportState.node, "abilities.dexterity.bonus", "number", sDEXBonus);
    DB.setValue(tImportState.node, "abilities.constitution.bonus", "number", sCONBonus);
    DB.setValue(tImportState.node, "abilities.intelligence.bonus", "number", sINTBonus);
    DB.setValue(tImportState.node, "abilities.wisdom.bonus", "number", sWISBonus);
    DB.setValue(tImportState.node, "abilities.charisma.bonus", "number", sCHABonus);

    DB.setValue(tImportState.node, "abilities.strength.savemodifier", "number", sSTRSaveMod);
    DB.setValue(tImportState.node, "abilities.dexterity.savemodifier", "number", sDEXSaveMod);
    DB.setValue(tImportState.node, "abilities.constitution.savemodifier", "number", sCONSaveMod);
    DB.setValue(tImportState.node, "abilities.intelligence.savemodifier", "number", sINTSaveMod);
    DB.setValue(tImportState.node, "abilities.wisdom.savemodifier", "number", sWISSaveMod);
    DB.setValue(tImportState.node, "abilities.charisma.savemodifier", "number", sCHASaveMod);
end

-- Assumes ability headers on next line, and ability scores/bonuses on following line
function importHelperAbilities2014(tImportState)
	-- Check next line for ability list
	ImportNPCManager.nextImportLine(tImportState); -- Line 6

	-- Check for short ability list
	local sSTR, sDEX, sCON, sINT, sWIS, sCHA;
	local sSTRBonus, sDEXBonus, sCONBonus, sINTBonus, sWISBonus, sCHABonus;
	if StringManager.trim(tImportState.sActiveLine or "") == "STR" then
		ImportNPCManager.nextImportLine(tImportState); -- Line 7
		local tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sSTR = tAbilityWords[1] or "";
		sSTRBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(tImportState, 2); -- Line 9
		tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sDEX = tAbilityWords[1] or "";
		sDEXBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(tImportState, 2); -- Line 11
		tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sCON = tAbilityWords[1] or "";
		sCONBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(tImportState, 2); -- Line 13
		tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sINT = tAbilityWords[1] or "";
		sINTBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(tImportState, 2); -- Line 15
		tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sWIS = tAbilityWords[1] or "";
		sWISBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(tImportState, 2); -- Line 17
		tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);
		sCHA = tAbilityWords[1] or "";
		sCHABonus = (tAbilityWords[2] or ""):match("[+-]?%d+");
	else
		local tWords = StringManager.splitWords(tImportState.sActiveLine);
		if #tWords == 6 and (tWords[1] == "STR") then
			ImportNPCManager.nextImportLine(tImportState); -- Line 7
			local tAbilityWords = StringManager.splitWords(tImportState.sActiveLine);

			sSTR = tAbilityWords[1] or "";
			sSTRBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");
			sDEX = tAbilityWords[3] or "";
			sDEXBonus = (tAbilityWords[4] or ""):match("[+-]?%d+");
			sCON = tAbilityWords[5] or "";
			sCONBonus = (tAbilityWords[6] or ""):match("[+-]?%d+");
			sINT = tAbilityWords[7] or "";
			sINTBonus = (tAbilityWords[8] or ""):match("[+-]?%d+");
			sWIS = tAbilityWords[9] or "";
			sWISBonus = (tAbilityWords[10] or ""):match("[+-]?%d+");
			sCHA = tAbilityWords[11] or "";
			sCHABonus = (tAbilityWords[12] or ""):match("[+-]?%d+");
		end
	end
	if not sSTR then
		ImportNPCManager.nextImportLine(tImportState, -1);
		return;
	end

	DB.setValue(tImportState.node, "abilities.strength.score", "number", sSTR);
	DB.setValue(tImportState.node, "abilities.dexterity.score", "number", sDEX);
	DB.setValue(tImportState.node, "abilities.constitution.score", "number", sCON);
	DB.setValue(tImportState.node, "abilities.wisdom.score", "number", sWIS);
	DB.setValue(tImportState.node, "abilities.intelligence.score", "number", sINT);
	DB.setValue(tImportState.node, "abilities.charisma.score", "number", sCHA);

	DB.setValue(tImportState.node, "abilities.strength.bonus", "number", sSTRBonus);
	DB.setValue(tImportState.node, "abilities.dexterity.bonus", "number", sDEXBonus);
	DB.setValue(tImportState.node, "abilities.constitution.bonus", "number", sCONBonus);
	DB.setValue(tImportState.node, "abilities.wisdom.bonus", "number", sWISBonus);
	DB.setValue(tImportState.node, "abilities.intelligence.bonus", "number", sINTBonus);
	DB.setValue(tImportState.node, "abilities.charisma.bonus", "number", sCHABonus);

	ImportNPCManager.addStatOutput(tImportState, "<table>");
	ImportNPCManager.addStatOutput(tImportState, "<tr>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>STR</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>DEX</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>CON</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>INT</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>WIS</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "<td><b>CHA</b></td>");
	ImportNPCManager.addStatOutput(tImportState, "</tr>");
	ImportNPCManager.addStatOutput(tImportState, "<tr>");
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sSTR or "", sSTRBonus or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sDEX or "", sDEXBonus or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sCON or "", sCONBonus or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sINT or "", sINTBonus or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sWIS or "", sWISBonus or ""));
	ImportNPCManager.addStatOutput(tImportState, string.format("<td>%s (%s)</td>", sCHA or "", sCHABonus or ""));
	ImportNPCManager.addStatOutput(tImportState, "</tr>");
	ImportNPCManager.addStatOutput(tImportState, "</table>");
end

-- Read in additional stat block data elements that may or may not be present.
-- Repeat until you don't find any more pattern matches.
function importHelperOptionalFields2024(tImportState)
	local tSpecialOutput = {};
	local keywordPatterns = {
		["savingthrows"] = "Saving Throws",
		["skills"] = "Skills",
		["damagevulnerabilities"] = "Damage Vulnerabilities",
		["damageresistances"] = "Damage Resistances",
		["damageimmunities"] = "Damage Immunities",
		["conditionimmunities"] = "Condition Immunities",
		["immunities"] = "Immunities",
		["resistances"] = "Resistances",
		["vulnerabilities"] = "Vulnerabilities",
		["gear"] = "Gear",
		["senses"] = "Senses",
		["languages"] = "Languages",
		["cr"] = "CR",
		["proficiencybonus"] = "Proficiency Bonus"
	};

	while true do
		ImportNPCManager.nextImportLine(tImportState);
		local sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
		if not sSimpleLine then break end

		local matched = false
		for pattern, label in pairs(keywordPatterns) do
			if sSimpleLine:match("^" .. pattern) then
				local tWords = StringManager.splitTokens(tImportState.sActiveLine);
				local valueStartIndex = 2;
				local sValue = table.concat(tWords, " ", valueStartIndex) or "";

				if pattern == "cr" then
					local sCR = tWords[2] or "";
					local sXPText = tImportState.sActiveLine:match("%(XP ([%d,]+)") or "";
					local sPB = tImportState.sActiveLine:match("PB ([+%d]+)") or "";
					DB.setValue(tImportState.node, "cr", "string", sCR);
					DB.setValue(tImportState.node, "xp", "number", sXPText:gsub(",", "")); -- Remove all non-numeric characters (commas)
					table.insert(tSpecialOutput, string.format("<b>%s</b> %s (XP %s; PB %s)", label, sCR, sXPText, sPB));
				elseif pattern == "vulnerabilities" then
					-- Account for when they leave off the word "damage"
					DB.setValue(tImportState.node, "damagevulnerabilities", "string", sValue);
					table.insert(tSpecialOutput, string.format("<b>%s</b> %s", label, sValue));
				elseif pattern == "resistances" then
					-- Account for when they leave off the word "damage"
					DB.setValue(tImportState.node, "damageresistances", "string", sValue);
					table.insert(tSpecialOutput, string.format("<b>%s</b> %s", label, sValue));
				elseif pattern == "immunities" then
					-- Account for when they leave off the word "damage"
					DB.setValue(tImportState.node, "damageimmunities", "string", sValue);
					table.insert(tSpecialOutput, string.format("<b>%s</b> %s", label, sValue));
				else
					DB.setValue(tImportState.node, pattern, "string", sValue);
					table.insert(tSpecialOutput, string.format("<b>%s</b> %s", label, sValue));
				end

				matched = true
				break
			end
		end

		if not matched then
			-- return back to the calling function and return the most recently read line back into the parser queue
			ImportNPCManager.nextImportLine(tImportState, 0);
			ImportNPCManager.addStatOutput(tImportState, string.format("<p>%s</p>", table.concat(tSpecialOutput, "&#13;")));
			return;
		end
	end
end

-- Assume the following optional fields in the following order:
--		Saving throws, Skills,
--		Damage Vulnerabilities, Damage Resistances, Damage Immunities, Condition Immunities,
--		Senses, Languages, Challenge
function importHelperOptionalFields2014(tImportState)
	local tSpecialOutput = {};

	ImportNPCManager.nextImportLine(tImportState); -- Line 8
	local sSimpleLine = StringManager.simplify(tImportState.sActiveLine);

	-- Example: Saving Throws Dex +10, Con +16, Wis +11, Cha +15
	if sSimpleLine and sSimpleLine:match("^savingthrows") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sSavingThrows = table.concat(tWords, " ", 3) or "";

		DB.setValue(tImportState.node, "savingthrows", "string", sSavingThrows);
		table.insert(tSpecialOutput, string.format("<b>Saving Throws</b> %s", sSavingThrows));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Skills Insight +11, Perception +19
	if sSimpleLine and sSimpleLine:match("^skills") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sSkills = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "skills", "string", sSkills);
		table.insert(tSpecialOutput, string.format("<b>Skills</b> %s", sSkills));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Damage Vulnerabilities cold, fire, lightning
	if sSimpleLine and sSimpleLine:match("^damagevulnerabilities") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sDamageVulnerabilities = table.concat(tWords, " ", 3) or "";

		DB.setValue(tImportState.node, "damagevulnerabilities", "string", sDamageVulnerabilities);
		table.insert(tSpecialOutput, string.format("<b>Damage Vulnerabilities</b> %s", sDamageVulnerabilities));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Damage Resistances cold, fire, lightning
	if sSimpleLine and sSimpleLine:match("^damageresistances") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sDamageResistances = table.concat(tWords, " ", 3) or "";

		DB.setValue(tImportState.node, "damageresistances", "string", sDamageResistances);
		table.insert(tSpecialOutput, string.format("<b>Damage Resistances</b> %s", sDamageResistances));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Damage Immunities poison; bludgeoning, piercing, and slashing that is nonmagical
	if sSimpleLine and sSimpleLine:match("^damageimmunities") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sDamageImmunities = table.concat(tWords, " ", 3) or "";

		DB.setValue(tImportState.node, "damageimmunities", "string", sDamageImmunities);
		table.insert(tSpecialOutput, string.format("<b>Damage Immunities</b> %s", sDamageImmunities));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Condition Immunities poison; bludgeoning, piercing, and slashing that is nonmagical
	if sSimpleLine and sSimpleLine:match("^conditionimmunities") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sConditionImmunities = table.concat(tWords, " ", 3) or "";

		DB.setValue(tImportState.node, "conditionimmunities", "string", sConditionImmunities);
		table.insert(tSpecialOutput, string.format("<b>Condition Immunities</b> %s", sConditionImmunities));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Senses truesight 120 ft., passive Perception 29
	if sSimpleLine and sSimpleLine:match("^senses") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sSenses = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "senses", "string", sSenses);
		table.insert(tSpecialOutput, string.format("<b>Senses</b> %s", sSenses));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Languages all, telepathy 120 ft.
	if sSimpleLine and sSimpleLine:match("^languages") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sLanguages = table.concat(tWords, " ", 2) or "";

		DB.setValue(tImportState.node, "languages", "string", sLanguages);
		table.insert(tSpecialOutput, string.format("<b>Languages</b> %s", sLanguages or ""));

		ImportNPCManager.nextImportLine(tImportState);
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end

	-- Example: Challenge 26 (90,000 XP) Proficiency Bonus +8
	if sSimpleLine and sSimpleLine:match("^challenge") then
		local tWords = StringManager.splitTokens(tImportState.sActiveLine);
		local sCR = tWords[2] or "";
		local sXPText = (tWords[3] or ""):match("[%d,]+") or "";

		DB.setValue(tImportState.node, "cr", "string", sCR);
		DB.setValue(tImportState.node, "xp", "number", sXPText:gsub(",", "")); -- Remove all non-numeric characters (commas)
		table.insert(tSpecialOutput, string.format("<b>Challenge</b> %s (%s XP)", sCR, sXPText));

		ImportNPCManager.nextImportLine(tImportState);
	end

	ImportNPCManager.addStatOutput(tImportState, string.format("<p>%s</p>", table.concat(tSpecialOutput, "&#13;")));
end

function importHelperActions(tImportState)
	while tImportState.sActiveLine do
		local sSimpleLine = StringManager.simplify(tImportState.sActiveLine);

		-- Look for a section header
		if sSimpleLine:match("^traits$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "traits");

		elseif sSimpleLine:match("^bonusactions$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "bonusactions");
			ImportNPCManager.addStatOutput(tImportState, "<h>Bonus Actions</h>");

		elseif sSimpleLine:match("^actions$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "actions");
			ImportNPCManager.addStatOutput(tImportState, "<h>Actions</h>");

		elseif sSimpleLine:match("^reactions$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "reactions");
			ImportNPCManager.addStatOutput(tImportState, "<h>Reactions</h>");

		elseif sSimpleLine:match("^legendaryactions$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "legendaryactions");
			ImportNPCManager.addStatOutput(tImportState, "<h>Legendary Actions</h>");

		elseif sSimpleLine:match("^lairactions$") then
			ImportNPCManager.finalizeAction(tImportState);
			ImportNPCManager.setActionMode(tImportState, "lairactions");
			ImportNPCManager.addStatOutput(tImportState, "<h>Lair Actions</h>");

		else
			-- Look for a feature heading. It should be proper cased and end in a period
			-- If it is multiple words, then each word should begin with a capitalization.
			local sHeading, sRemainder = tImportState.sActiveLine:match("([^.!]+[.!])%s(.*)")
			if ImportNPCManager.isActionHeading(sHeading) then
				ImportNPCManager.finalizeAction(tImportState);
				ImportNPCManager.setActionData(tImportState, sHeading, sRemainder);
			else
				ImportNPCManager.appendActionDesc(tImportState, tImportState.sActiveLine);
			end
		end

		ImportNPCManager.nextImportLine(tImportState);
	end

	-- Finalize all actions
	ImportNPCManager.finalizeAction(tImportState);
end

--
--	Import state identification and tracking
--

function isActionHeading(s)
	if not s then
		return false;
	end

	local sHeading = s;

	sHeading = sHeading:gsub(" of ", " Of ");
	sHeading = sHeading:gsub(" with ", " With ");
	sHeading = sHeading:gsub(" and ", " And ");
	sHeading = sHeading:gsub(" the ", " The ");
	sHeading = sHeading:gsub(" to ", " To ");
	sHeading = sHeading:gsub(" in ", " In ");
	sHeading = sHeading:gsub(" on ", " On ");
	sHeading = sHeading:gsub(" a ", " A ");
	sHeading = sHeading:gsub(" an ", " An ");
	sHeading = sHeading:gsub(" from ", " From ");
	sHeading = sHeading:gsub(" after ", " After ");
	sHeading = sHeading:gsub(" before ", " Before ");
	-- handle possessive titles
	sHeading = sHeading:gsub("\'s ", "'S ");

	if sHeading == StringManager.capitalizeAll(sHeading) then
		return true;
	elseif s:match("Recharges after") then
		return true;
	end
	return false;
end

function initImportState(sStatBlock, sDesc)
	local tImportState = {};

	local sCleanStats = ImportUtilityManager.cleanUpText(sStatBlock);
	tImportState.nLine = 0;
	tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanStats);
	tImportState.sActiveLine = "";

	tImportState.sDescription = ImportUtilityManager.cleanUpText(sDesc);
	tImportState.tStatOutput = {};

	tImportState.sActionMode = "traits";
	tImportState.sActionName = "";
	tImportState.tActionDesc = {};

	local sRootMapping = LibraryData.getRootMapping("npc");
	tImportState.node = DB.createChild(sRootMapping);

	return tImportState;
end

function nextImportLine(tImportState, nAdvance)
	tImportState.nLine = tImportState.nLine + (nAdvance or 1);
	if tImportState.nLine <= #tImportState.tLines then
		tImportState.sActiveLine = tImportState.tLines[tImportState.nLine];
		return true;
	else
		tImportState.sActiveLine = nil;
		return false;
	end
end

function addStatOutput(tImportState, s)
	table.insert(tImportState.tStatOutput, s);
end

function finalizeDescription(tImportState)
	DB.setValue(tImportState.node, "text", "formattedtext", tImportState.sDescription .. table.concat(tImportState.tStatOutput));
end

function setActionMode(tImportState, s)
	tImportState.sActionMode = s;
end

function setActionData(tImportState, sName, sDesc)
	tImportState.sActionName = sName;
	tImportState.tActionDesc = {};
	if (sDesc or "") ~= "" then
		table.insert(tImportState.tActionDesc, sDesc);
	end
end

function appendActionDesc(tImportState, s)
	if (s or "") ~= "" then
		table.insert(tImportState.tActionDesc, s);
	end
end

function finalizeAction(tImportState)
	if (tImportState.sActionName or "") ~= "" then
		local nodeGroup = DB.createChild(tImportState.node, tImportState.sActionMode);
		local node = DB.createChild(nodeGroup);
		if tImportState.sActionName:match("%.$") then
			DB.setValue(node, "name", "string", tImportState.sActionName:sub(1, -2));
		else
			DB.setValue(node, "name", "string", tImportState.sActionName);
		end
		-- DAD. Use the new macros John built into the 2024 ruleset for summoned creatures
		local sActionDesc = table.concat(tImportState.tActionDesc, "\n");

		-- Perform replacements
		sActionDesc = sActionDesc:gsub("DC equals your spell save DC", "DC {$SpellDC}");
		sActionDesc = sActionDesc:gsub("Bonus equals your spell attack modifier", "+{$SpellAttack}");
		sActionDesc = sActionDesc:gsub("plus the spell’s level", "plus +{$SpellLevel}");
		sActionDesc = sActionDesc:gsub("%+ your spellcasting ability modifier", "+ {$SpellAttack}");

		-- Write the modified description to the database
		DB.setValue(node, "desc", "string", sActionDesc);

		local sOutputDesc = string.format("<p><b><i>%s</i></b> %s</p>", tImportState.sActionName, table.concat(tImportState.tActionDesc, "</p><p>"));
		ImportNPCManager.addStatOutput(tImportState, sOutputDesc);

	elseif #(tImportState.tActionDesc) > 0 then
		local sOutputDesc = string.format("<p>%s</p>", table.concat(tImportState.tActionDesc, "</p><p>"));
		ImportNPCManager.addStatOutput(tImportState, sOutputDesc);

	else
		return;
	end

	tImportState.sActionName = "";
	tImportState.tActionDesc = {};
end
