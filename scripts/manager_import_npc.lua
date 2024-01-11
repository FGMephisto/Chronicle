-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onTabletopInit()
	local sLabel = Interface.getString("import_npc_mode_2022");
	ImportUtilityManager.registerImportMode("npc", "2022", sLabel, ImportNPCManager.import2022);
end

function performImport(w)
	local sMode = w.mode.getSelectedValue();
	local tImportMode = ImportUtilityManager.getImportMode("npc", sMode);
	if tImportMode then
		local sStats = w.statblock.getValue();
		local sDesc = w.description.getValue();
		tImportMode.fn(sStats, sDesc);
	end
end

--
--	Built-in supported import modes
--

function import2022(sStats, sDesc)
	-- Track state information
	local tImportState = ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name on Line 1
	ImportNPCManager.importHelperName(tImportState);

	-- Assume size/type/alignment on Line 2
	ImportNPCManager.importHelperSizeTypeAlignment(tImportState);
	
	-- Assume AC on Line 3, HP on Line 4, and Speed on Line 5
	ImportNPCManager.importHelperACHPSpeed(tImportState);

	-- Assume ability headers on Line 6, and ability scores/bonuses on Line 7
	ImportNPCManager.importHelperAbilities(tImportState);
	
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
	ImportNPCManager.importHelperOptionalFields(tImportState);
	
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

-- Assumes size/type/alignment on next line; and of the form "<size> <type>, <alignment>"
function importHelperSizeTypeAlignment(tImportState)
	-- Example: Huge Fiend (Demon), Chaotic Evil
	ImportNPCManager.nextImportLine(tImportState);
	if (tImportState.sActiveLine or "") ~= "" then
		local tSegments = StringManager.splitByPattern(tImportState.sActiveLine, ",", true);
		local tWords = StringManager.splitTokens(tSegments[1] or "");
		local sSize = tWords[1] or "";
		local sType = table.concat(tWords, " ", 2) or "";
		local sAlignment = table.concat(tSegments, ",", 2) or "";

		DB.setValue(tImportState.node, "size", "string", sSize);
		DB.setValue(tImportState.node, "type", "string", sType);
		DB.setValue(tImportState.node, "alignment", "string", StringManager.trim(sAlignment));

		ImportNPCManager.addStatOutput(tImportState, string.format("<p><b><i>%s</i></b></p>", tImportState.sActiveLine));
	end
end

-- Assumes AC/HP/Speed on next 3 lines in the following formats:
-- 		"Armor Class <ac> <actext>"
--		"Hit Points <hp> <hd>"
--		"Speed <speed>"
function importHelperACHPSpeed(tImportState)
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

-- Assumes ability headers on next line, and ability scores/bonuses on following line
function importHelperAbilities(tImportState)
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
function importHelperOptionalFields(tImportState)
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
		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
	end
	
	ImportNPCManager.addStatOutput(tImportState, string.format("<p>%s</p>", table.concat(tSpecialOutput, "&#13;")));
end

function importHelperActions(tImportState)
	while tImportState.sActiveLine do
 		sSimpleLine = StringManager.simplify(tImportState.sActiveLine);
		
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
			-- NOTE: DAD 2022-04-13 John wants us to only allow a period and not a colon. This forces an 
			-- exact syntax but make sure that we don't inadvertantly change a : to a period because that 
			-- is the syntax used for stuff like 3/day: Spell1, Spell2

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
	tImportState.sActiveLine = tImportState.tLines[tImportState.nLine];
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
		DB.setValue(node, "desc", "string", table.concat(tImportState.tActionDesc, "\n"));
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
