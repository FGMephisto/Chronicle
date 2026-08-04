--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Adjustable class names
local sItemClass

function onInit()
	sItemClass = self.class[1];

	self.constructDefaultAbilities();
	self.onDataChanged();
end

-- Create default ability selection
function constructDefaultAbilities()
	if not DataCommon or not DataCommon.abilitydata then return end

	local entrymap = {};
	local duplicates = {};

	for _, w in pairs(getWindows()) do
		local node = w.getDatabaseNode();
		if node then
			local sName = (w.name and w.name.getValue()) or "";
			local sNodeName = node.getNodeName();

			local sKey = "";
			if sName ~= "" and DataCommon.ability_stol and DataCommon.ability_stol[sName:upper()] then
				sKey = DataCommon.ability_stol[sName:upper()];
			elseif sName ~= "" then
				sKey = StringManager.simplify(sName);
			else
				sKey = StringManager.simplify(sNodeName);
			end

			if sKey ~= "" then
				if not entrymap[sKey] then
					entrymap[sKey] = w;
				else
					table.insert(duplicates, w);
				end
			end
		end
	end

	-- Remove duplicate windows/nodes from DB
	for _, w in ipairs(duplicates) do
		local node = w.getDatabaseNode();
		w.close();
		if node then
			node.delete();
		end
	end

	-- Ensure each defined ability exists exactly once with shorthand label
	for k, t in pairs(DataCommon.abilitydata) do
		local sKey = StringManager.simplify(k);
		local w = entrymap[sKey];

		if not w then
			w = createWindowWithClass(sItemClass, "." .. sKey);
			if w then
				entrymap[sKey] = w;
			end
		end

		if w then
			if w.name then
				local sShort = (DataCommon.ability_ltos and DataCommon.ability_ltos[sKey]) or k;
				w.name.setValue(sShort);
			end
			if w.group then
				w.group.setValue(t.group);
			end
			if w.groupid then
				w.groupid.setValue(t.groupid);
			end
		end
	end
end

function onDataChanged()
	self.applySort();
end