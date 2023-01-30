-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tImportState = {};

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
	ImportNPCManager.initImportState(sStats, sDesc);

	-- Assume name on Line 1
	ImportNPCManager.importHelperName();

	-- Assume size/type/alignment on Line 2
	ImportNPCManager.importHelperSizeTypeAlignment();
	
	-- Assume AC on Line 3, HP on Line 4, and Speed on Line 5
	ImportNPCManager.importHelperACHPSpeed();

	-- Assume ability headers on Line 6, and ability scores/bonuses on Line 7
	ImportNPCManager.importHelperAbilities();
	
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
	ImportNPCManager.importHelperOptionalFields();
	
	-- Assume NPC actions appear next with the following headers: (Assume Traits until a header found)
	--		Traits, Actions, Bonus Actions, Reactions, Legendary Actions, Lair Actions
	ImportNPCManager.importHelperActions();

	-- Update Description by adding the statblock text as well
	ImportNPCManager.finalizeDescription();
	
	-- Open new record window and matching campaign list
	ImportUtilityManager.showRecord("npc", _tImportState.node);
end

--
--	Import section helper functions
--

-- Assumes name is on next line
function importHelperName()
	-- Name
	ImportNPCManager.nextImportLine();
	DB.setValue(_tImportState.node, "name", "string", _tImportState.sActiveLine);
	ImportNPCManager.addStatOutput(string.format("<h>%s</h>", _tImportState.sActiveLine));
	
	-- Token
	ImportUtilityManager.setDefaultToken(_tImportState.node);
end

-- Assumes size/type/alignment on next line; and of the form "<size> <type>, <alignment>"
function importHelperSizeTypeAlignment()
	-- Example: Huge Fiend (Demon), Chaotic Evil
	ImportNPCManager.nextImportLine();
	if (_tImportState.sActiveLine or "") ~= "" then
		local tSegments = StringManager.splitByPattern(_tImportState.sActiveLine, ",", true);
		local tWords = StringManager.splitTokens(tSegments[1] or "");
		local sSize = tWords[1] or "";
		local sType = table.concat(tWords, " ", 2) or "";
		local sAlignment = table.concat(tSegments, ",", 2) or "";

		DB.setValue(_tImportState.node, "size", "string", sSize);
		DB.setValue(_tImportState.node, "type", "string", sType);
		DB.setValue(_tImportState.node, "alignment", "string", StringManager.trim(sAlignment));

		ImportNPCManager.addStatOutput(string.format("<p><b><i>%s</i></b></p>", _tImportState.sActiveLine));
	end
end

-- Assumes AC/HP/Speed on next 3 lines in the following formats:
-- 		"Armor Class <ac> <actext>"
--		"Hit Points <hp> <hd>"
--		"Speed <speed>"
function importHelperACHPSpeed()
	local tMidOutput = {};

	-- Example: Armor Class 22 (natural armor)
	ImportNPCManager.nextImportLine(); -- Line 3
	if (_tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sAC = tWords[3] or "";
		local sACText = table.concat(tWords, " ", 4) or "";

		DB.setValue(_tImportState.node, "ac", "number", sAC);
		DB.setValue(_tImportState.node, "actext", "string", sACText);
		table.insert(tMidOutput, string.format("<b>Armor Class</b> %s %s", sAC, sACText));
	end
	
	-- Example: Hit Points 464 (32d12 + 256)	
	ImportNPCManager.nextImportLine(); -- Line 4
	if (_tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sHP = tWords[3] or "";
		local sHD = table.concat(tWords, " ", 4) or "";

		DB.setValue(_tImportState.node, "hp", "number", sHP);
		DB.setValue(_tImportState.node, "hd", "string", sHD);	
		table.insert(tMidOutput, string.format("<b>Hit Points</b> %s %s", sHP, sHD));
	end
	
	-- Example: Speed 50 ft., swim 50 ft.
	ImportNPCManager.nextImportLine(); -- Line 5
	if (_tImportState.sActiveLine or "") ~= "" then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sSpeed = table.concat(tWords, " ", 2) or "";

		DB.setValue(_tImportState.node, "speed", "string", sSpeed);
		table.insert(tMidOutput, string.format("<b>Speed</b> %s", sSpeed));
	end

	if #tMidOutput > 0 then
		ImportNPCManager.addStatOutput(string.format("<p>%s</p>", table.concat(tMidOutput, "&#13;")));
	end
end

-- Assumes ability headers on next line, and ability scores/bonuses on following line
function importHelperAbilities()
	-- Check next line for ability list
	ImportNPCManager.nextImportLine(); -- Line 6

	-- Check for short ability list
	local sSTR, sDEX, sCON, sINT, sWIS, sCHA;
	local sSTRBonus, sDEXBonus, sCONBonus, sINTBonus, sWISBonus, sCHABonus;
	if StringManager.trim(_tImportState.sActiveLine or "") == "STR" then
		ImportNPCManager.nextImportLine(); -- Line 7
		local tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sSTR = tAbilityWords[1] or "";
		sSTRBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(2); -- Line 9
		tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sDEX = tAbilityWords[1] or "";
		sDEXBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(2); -- Line 11
		tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sCON = tAbilityWords[1] or "";
		sCONBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(2); -- Line 13
		tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sINT = tAbilityWords[1] or "";
		sINTBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(2); -- Line 15
		tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sWIS = tAbilityWords[1] or "";
		sWISBonus = (tAbilityWords[2] or ""):match("[+-]?%d+");

		ImportNPCManager.nextImportLine(2); -- Line 17
		tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);
		sCHA = tAbilityWords[1] or "";
		sCHABonus = (tAbilityWords[2] or ""):match("[+-]?%d+");
	else
		local tWords = StringManager.splitWords(_tImportState.sActiveLine);
		if #tWords == 6 and (tWords[1] == "STR") then
			ImportNPCManager.nextImportLine(); -- Line 7
			local tAbilityWords = StringManager.splitWords(_tImportState.sActiveLine);

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
		ImportNPCManager.nextImportLine(-1);
		return;
	end

	DB.setValue(_tImportState.node, "abilities.strength.score", "number", sSTR);
	DB.setValue(_tImportState.node, "abilities.dexterity.score", "number", sDEX);
	DB.setValue(_tImportState.node, "abilities.constitution.score", "number", sCON);
	DB.setValue(_tImportState.node, "abilities.wisdom.score", "number", sWIS);
	DB.setValue(_tImportState.node, "abilities.intelligence.score", "number", sINT);
	DB.setValue(_tImportState.node, "abilities.charisma.score", "number", sCHA);

	DB.setValue(_tImportState.node, "abilities.strength.bonus", "number", sSTRBonus);
	DB.setValue(_tImportState.node, "abilities.dexterity.bonus", "number", sDEXBonus);
	DB.setValue(_tImportState.node, "abilities.constitution.bonus", "number", sCONBonus);
	DB.setValue(_tImportState.node, "abilities.wisdom.bonus", "number", sWISBonus);
	DB.setValue(_tImportState.node, "abilities.intelligence.bonus", "number", sINTBonus);
	DB.setValue(_tImportState.node, "abilities.charisma.bonus", "number", sCHABonus);	
	
	ImportNPCManager.addStatOutput("<table>");
	ImportNPCManager.addStatOutput("<tr>");
	ImportNPCManager.addStatOutput("<td><b>STR</b></td>");
	ImportNPCManager.addStatOutput("<td><b>DEX</b></td>");
	ImportNPCManager.addStatOutput("<td><b>CON</b></td>");
	ImportNPCManager.addStatOutput("<td><b>INT</b></td>");
	ImportNPCManager.addStatOutput("<td><b>WIS</b></td>");
	ImportNPCManager.addStatOutput("<td><b>CHA</b></td>");
	ImportNPCManager.addStatOutput("</tr>");
	ImportNPCManager.addStatOutput("<tr>");
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sSTR or "", sSTRBonus or ""));
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sDEX or "", sDEXBonus or ""));
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sCON or "", sCONBonus or ""));
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sINT or "", sINTBonus or ""));
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sWIS or "", sWISBonus or ""));
	ImportNPCManager.addStatOutput(string.format("<td>%s (%s)</td>", sCHA or "", sCHABonus or ""));
	ImportNPCManager.addStatOutput("</tr>");
	ImportNPCManager.addStatOutput("</table>");
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
function importHelperOptionalFields()
	local tSpecialOutput = {};

	ImportNPCManager.nextImportLine(); -- Line 8
	local sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);

	-- Example: Saving Throws Dex +10, Con +16, Wis +11, Cha +15
	if sSimpleLine and sSimpleLine:match("^savingthrows") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sSavingThrows = table.concat(tWords, " ", 3) or "";

		DB.setValue(_tImportState.node, "savingthrows", "string", sSavingThrows);		   
		table.insert(tSpecialOutput, string.format("<b>Saving Throws</b> %s", sSavingThrows));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end
	
	-- Example: Skills Insight +11, Perception +19
	if sSimpleLine and sSimpleLine:match("^skills") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sSkills = table.concat(tWords, " ", 2) or "";

		DB.setValue(_tImportState.node, "skills", "string", sSkills);		   
		table.insert(tSpecialOutput, string.format("<b>Skills</b> %s", sSkills));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end	

	-- Example: Damage Vulnerabilities cold, fire, lightning
	if sSimpleLine and sSimpleLine:match("^damagevulnerabilities") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sDamageVulnerabilities = table.concat(tWords, " ", 3) or "";

		DB.setValue(_tImportState.node, "damagevulnerabilities", "string", sDamageVulnerabilities);
		table.insert(tSpecialOutput, string.format("<b>Damage Vulnerabilities</b> %s", sDamageVulnerabilities));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end	  
	
	-- Example: Damage Resistances cold, fire, lightning
	if sSimpleLine and sSimpleLine:match("^damageresistances") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sDamageResistances = table.concat(tWords, " ", 3) or "";

		DB.setValue(_tImportState.node, "damageresistances", "string", sDamageResistances);		   
		table.insert(tSpecialOutput, string.format("<b>Damage Resistances</b> %s", sDamageResistances));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end	  
	
	-- Example: Damage Immunities poison; bludgeoning, piercing, and slashing that is nonmagical
	if sSimpleLine and sSimpleLine:match("^damageimmunities") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sDamageImmunities = table.concat(tWords, " ", 3) or "";

		DB.setValue(_tImportState.node, "damageimmunities", "string", sDamageImmunities);		   
		table.insert(tSpecialOutput, string.format("<b>Damage Immunities</b> %s", sDamageImmunities));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end	  

	-- Example: Condition Immunities poison; bludgeoning, piercing, and slashing that is nonmagical
	if sSimpleLine and sSimpleLine:match("^conditionimmunities") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sConditionImmunities = table.concat(tWords, " ", 3) or "";

		DB.setValue(_tImportState.node, "conditionimmunities", "string", sConditionImmunities);		   
		table.insert(tSpecialOutput, string.format("<b>Condition Immunities</b> %s", sConditionImmunities));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end   

	-- Example: Senses truesight 120 ft., passive Perception 29
	if sSimpleLine and sSimpleLine:match("^senses") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sSenses = table.concat(tWords, " ", 2) or "";

		DB.setValue(_tImportState.node, "senses", "string", sSenses);		   
		table.insert(tSpecialOutput, string.format("<b>Senses</b> %s", sSenses));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end  
	
	-- Example: Languages all, telepathy 120 ft.
	if sSimpleLine and sSimpleLine:match("^languages") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sLanguages = table.concat(tWords, " ", 2) or "";

		DB.setValue(_tImportState.node, "languages", "string", sLanguages);		   
		table.insert(tSpecialOutput, string.format("<b>Languages</b> %s", sLanguages or ""));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end
	
	-- Example: Challenge 26 (90,000 XP) Proficiency Bonus +8
	if sSimpleLine and sSimpleLine:match("^challenge") then
		local tWords = StringManager.splitTokens(_tImportState.sActiveLine);
		local sCR = tWords[2] or "";
		local sXPText = (tWords[3] or ""):match("[%d,]+") or "";

		DB.setValue(_tImportState.node, "cr", "string", sCR);
		DB.setValue(_tImportState.node, "xp", "number", sXPText:gsub(",", "")); -- Remove all non-numeric characters (commas)
		table.insert(tSpecialOutput, string.format("<b>Challenge</b> %s (%s XP)", sCR, sXPText));

		ImportNPCManager.nextImportLine();
		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
	end
	
	ImportNPCManager.addStatOutput(string.format("<p>%s</p>", table.concat(tSpecialOutput, "&#13;")));
end

function importHelperActions()
	while _tImportState.sActiveLine do
 		sSimpleLine = StringManager.simplify(_tImportState.sActiveLine);
		
		-- Look for a section header
		if sSimpleLine:match("^traits$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("traits");

		elseif sSimpleLine:match("^bonusactions$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("bonusactions");
			ImportNPCManager.addStatOutput("<h>Bonus Actions</h>");
			
		elseif sSimpleLine:match("^actions$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("actions");
			ImportNPCManager.addStatOutput("<h>Actions</h>");
			
		elseif sSimpleLine:match("^reactions$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("reactions");
			ImportNPCManager.addStatOutput("<h>Reactions</h>");

		elseif sSimpleLine:match("^legendaryactions$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("legendaryactions");
			ImportNPCManager.addStatOutput("<h>Legendary Actions</h>");
			
		elseif sSimpleLine:match("^lairactions$") then
			ImportNPCManager.finalizeAction();
			ImportNPCManager.setActionMode("lairactions");
			ImportNPCManager.addStatOutput("<h>Lair Actions</h>");

		else
			-- NOTE: DAD 2022-04-13 John wants us to only allow a period and not a colon. This forces an 
			-- exact syntax but make sure that we don't inadvertantly change a : to a period because that 
			-- is the syntax used for stuff like 3/day: Spell1, Spell2

			-- Look for a feature heading. It should be proper cased and end in a period
			-- If it is multiple words, then each word should begin with a capitalization.
			local sHeading, sRemainder = _tImportState.sActiveLine:match("([^.!]+[.!])%s(.*)")
			if ImportNPCManager.isActionHeading(sHeading) then
				ImportNPCManager.finalizeAction();
				ImportNPCManager.setActionData(sHeading, sRemainder);
			else
				ImportNPCManager.appendActionDesc(_tImportState.sActiveLine);
			end
		end

		ImportNPCManager.nextImportLine();
	end

	-- Finalize all actions
	ImportNPCManager.finalizeAction();
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
	_tImportState = {};

	local sCleanStats = ImportUtilityManager.cleanUpText(sStatBlock);
	_tImportState.nLine = 0;
	_tImportState.tLines = ImportUtilityManager.parseFormattedTextToLines(sCleanStats);
	_tImportState.sActiveLine = "";

	_tImportState.sDescription = ImportUtilityManager.cleanUpText(sDesc);
	_tImportState.tStatOutput = {};

	_tImportState.sActionMode = "traits";
	_tImportState.sActionName = "";
	_tImportState.tActionDesc = {};

	local sRootMapping = LibraryData.getRootMapping("npc");
	_tImportState.node = DB.createChild(sRootMapping);
end

function nextImportLine(nAdvance)
	_tImportState.nLine = _tImportState.nLine + (nAdvance or 1);
	_tImportState.sActiveLine = _tImportState.tLines[_tImportState.nLine];
end

function addStatOutput(s)
	table.insert(_tImportState.tStatOutput, s);
end

function finalizeDescription()
	DB.setValue(_tImportState.node, "text", "formattedtext", _tImportState.sDescription .. table.concat(_tImportState.tStatOutput));
end

function setActionMode(s)
	_tImportState.sActionMode = s;
end

function setActionData(sName, sDesc)
	_tImportState.sActionName = sName;
	_tImportState.tActionDesc = {};
	if (sDesc or "") ~= "" then
		table.insert(_tImportState.tActionDesc, sDesc);
	end
end

function appendActionDesc(s)
	if (s or "") ~= "" then
		table.insert(_tImportState.tActionDesc, s);
	end
end

function finalizeAction()
	if (_tImportState.sActionName or "") ~= "" then
		local nodeGroup = DB.createChild(_tImportState.node, _tImportState.sActionMode);
		local node = DB.createChild(nodeGroup);
		if _tImportState.sActionName:match("%.$") then
			DB.setValue(node, "name", "string", _tImportState.sActionName:sub(1, -2));
		else
			DB.setValue(node, "name", "string", _tImportState.sActionName);
		end
		DB.setValue(node, "desc", "string", table.concat(_tImportState.tActionDesc, "\n"));
		local sOutputDesc = string.format("<p><b><i>%s</i></b> %s</p>", _tImportState.sActionName, table.concat(_tImportState.tActionDesc, "</p><p>"));
		ImportNPCManager.addStatOutput(sOutputDesc);

	elseif #(_tImportState.tActionDesc) > 0 then
		local sOutputDesc = string.format("<p>%s</p>", table.concat(_tImportState.tActionDesc, "</p><p>"));
		ImportNPCManager.addStatOutput(sOutputDesc);

	else
		return;
	end

	_tImportState.sActionName = "";
	_tImportState.tActionDesc = {};
end
