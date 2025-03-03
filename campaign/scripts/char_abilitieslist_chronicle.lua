-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

tAbilitiesGroups = {};

-- Adjusted
function onInit()
	-- registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);

	-- Construct default attributes
	self.constructDefaultAbilities();
	self.constructHeader();
	self.setAbilityGroups();
	self.setSortingControls();
	self.applySort();
end

-- Adjusted
function addEntry(bFocus)
	local w = createWindow();

	-- Set to use no custom skills
	w.name.setEnabled(false);
	w.name.setLine(false);

	if bFocus and w then
		w.name.setFocus();
	end

	-- Construct headers, set sorting controls and sort
	self.constructHeader();
	self.setAbilityGroups();
	self.setSortingControls();
	self.applySort();
	
	return w;
end

-- Adjusted
function onMenuSelection(item)
	-- if item == 5 then
		-- addEntry(true);
	-- end
end

-- Create default ability selection
-- Adjusted
function constructDefaultAbilities()
	-- Collect existing entries
	local entrymap = {};
	for _,w in pairs(getWindows()) do
		-- Get ability name
		local sLabel = w.name.getValue();
Debug.chat("sLabel", sLabel)

		-- Check if the ability name matches a ability maintained in DataCommon.lua (i.e. is not a custom ability)
		if DataCommon.abilitydata[sLabel] then
			-- If the ability is not present on entrymap array, add the item windows instance and its values with the ability as key
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				-- If the ability is present on entrymap array, add the item windows instance and its values to the ability
				table.insert(entrymap[sLabel], w);
			end
		end

		-- Set to use no custom skills and set correct target value of score field
		w.name.setEnabled(false);
		w.name.setLine(false);
		w.score.target[1] = StringManager.simplify(sLabel)
Debug.chat("StringManager.simplify(sLabel)", StringManager.simplify(sLabel))
	end

	-- Set properties and create missing entries for all known abilitys
	for k, t in pairs(DataCommon.abilitydata) do
		-- Check if a match exists in entrymap
		local matches = entrymap[k];
		
		-- If no matching entrymap table entry is present, create an entry in the list
		if not matches then
			local w = createWindowWithClass("char_ability_item", "." .. k:lower())
			
			if w then
				w.name.setValue(k);
				w.name.setEnabled(false);
				w.name.setLine(false);
				w.group.setValue(StringManager.capitalize(t.group));
				w.score.target[1] = StringManager.simplify(sLabel)
Debug.chat("StringManager.simplify(sLabel)", StringManager.simplify(sLabel))
				
				-- Add the item windows instance to the key
				matches = { w };
			end
		end
	end
end

-- Adjusted
function addAbilityReference(nodeSource)
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
		wSkill.name.setEnabled(false);
		wSkill.name.setLine(false);
		wSkill.group.setValue(StringManager.trim(DB.getValue(nodeSource, "group", "")));
		
		-- if DataCommon.skilldata[sName] then
			-- wSkill.stat.setStringValue(DataCommon.skilldata[sName].stat);
			-- wSkill.setCustom(false);
		-- else
			-- wSkill.stat.setStringValue(DB.getValue(nodeSource, "stat", ""):lower());
			-- wSkill.setCustom(true);
		-- end
	end

	if wSkill then
		DB.setValue(wSkill.getDatabaseNode(), "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

-- Added
function constructHeader()
	local wHeader = nil

	-- Avoid duplicate headers
	self.destroyHeaders()

	tAbilitiesGroups = constructDefaultAbilityGroups()

    -- Create Header items
    for k, t in pairs(tAbilitiesGroups) do
		if t.group ~= "" then
			wHeader = createWindowWithClass("char_ability_header")
			wHeader.group.setValue(StringManager.capitalizeAll(t.group));
			wHeader.groupid.setValue(t.groupid-1);
			wHeader.name_label.setValue(t.group:upper() .. " " .. Interface.getString("char_label_abilitiess"));
		end
	end
end

-- Added
function destroyHeaders()
	for _,w in pairs(getWindows()) do
		local sClass = w.getClass()
		if sClass == "char_ability_header" then w.close() end
	end
end

-- Added
function constructDefaultAbilityGroups()
	local EntryMap = {};
	local tGroupList = {}

	for _,w in pairs(getWindows()) do
		local sGroup = w.group.getValue():lower();
		
        -- Ensure the group isn't already present before adding it
        if not EntryMap[sGroup] then
            EntryMap[sGroup] = true
        end
	end

    -- Find the highest groupid in DataCommon.abilitiesgroups
    local nMaxGroupID = 0
    for _, t in pairs(DataCommon.abilitygroups) do
        if tonumber(t.groupid) > nMaxGroupID then
            nMaxGroupID = tonumber(t.groupid)
        end
    end
	
    -- Iterate over EntryMap
    for k, _ in pairs(EntryMap) do
        local match = false

        -- Check if the group key exists in DataCommon.abilitiesgroups
        for v, t in pairs(DataCommon.abilitygroups) do
            if v == k then
                table.insert(tGroupList, { group = k, groupid = t.groupid })
                match = true
                break
            end
        end

        -- If no match is found, assign a new groupid
        if not match then
			nMaxGroupID = nMaxGroupID + 2
            table.insert(tGroupList, { group = k, groupid = nMaxGroupID })
        end
    end
	
	return tGroupList
end

-- Added
function setAbilityGroups()
	for _,w in pairs(getWindows()) do
		local sGroup = w.group.getValue():lower()
		local sClass = w.getClass()
		
		for k,t in pairs(tAbilitiesGroups) do

			if t.group == sGroup then
				if sClass == "char_ability_header" then
					sGroupID = t.groupid -1
				else
					sGroupID = t.groupid
				end
			end
		end

		w.groupid.setValue(sGroupID)
	end
end

-- Added
-- Set sorting and filtering controls
function setSortingControls()
	for _,w in pairs(getWindows()) do
		w.name_sorting.setValue(w.groupid.getValue() .. w.name.getValue());
	end
end