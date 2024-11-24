-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

--
--
function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	
	-- Construct default skills
	self.constructDefaultSkills();
end

--
--
function addEntry(bFocus)
	local w = createWindow();

	w.setCustom(true);

	if bFocus and w then
		w.name.setFocus();
	end

	return w;
end

--
--
function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

--
-- Adjusted
-- Create default skill selection
--
function constructDefaultSkills()
	-- Debug.chat("FN: constructDefaultSkills in char_skilllist")
	-- Collect existing entries
	local entrymap = {};

	-- Create a list of all already existing skill list items
	for _,w in pairs(getWindows()) do
		-- Get skill names from all existing list items
		local sLabel = w.name.getValue();

		-- Check if the technical skill name matches a skill maintained in DataCommon.lua (i.e. is not custom skill)
		if DataCommon.skilldata[sLabel] then
			-- If the skill is not present on entrymap array, add the item windows instance with the skill as key
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				-- If the skill is present on entrymap array, add the item windows instance to the skill
				table.insert(entrymap[sLabel], w);
			end
		-- If the skill name does not match to a default skill, flag it as a custom skill
		else
			w.setCustom(true);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		-- Read entrymap table value
		local matches = entrymap[k];
		
		-- If no matching entrymap table entry is present, create an entry in the DB
		if not matches then
			local w = createWindow();

			if w then
				w.name.setValue(k);

				if t.stat then
					w.stat.setValue(t.stat);
				else
					-- w.stat.setStringValue("");
				end
				
				-- Add the item windows instance to the key
				matches = { w };

				-- Re-run the dicecontrol onInit to populate Ability and Skill values to the control required
				w.diceframe.onInit()
			end
		end

		-- Update properties if not a custom skill
		local bCustom = false;

		for _, match in pairs(matches) do
			match.setCustom(bCustom);

			-- Toggle visibility of Armor Widget
			if t.disarmorstealth then
				match.armorwidget.setVisible(true);
			end

			-- Disallow editing of Ability stat control and set a new frame
			match.stat.setReadOnly(true)
			match.stat.setFrame("fieldlight", 7, 5, 7, 5)

			-- Set as custom
			bCustom = true;
		end
	end
end

--
--
function addSkillReference(nodeSource)
	if not nodeSource then
		return;
	end
	
	local sName = StringManager.trim(DB.getValue(nodeSource, "name", ""));

	if sName == "" then
		return;
	end
	
	local wSkill = nil;

	for _,w in pairs(getWindows()) do
		if StringManager.trim(w.name.getValue()) == sName then
			wSkill = w;
			break;
		end
	end

	if not wSkill then
		wSkill = createWindow();
		
		wSkill.name.setValue(sName);
		if DataCommon.skilldata[sName] then
			wSkill.stat.setStringValue(DataCommon.skilldata[sName].stat);
			wSkill.setCustom(false);
		else
			wSkill.stat.setStringValue(DB.getValue(nodeSource, "stat", ""):lower());
			wSkill.setCustom(true);
		end
	end

	if wSkill then
		DB.setValue(wSkill.getDatabaseNode(), "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end