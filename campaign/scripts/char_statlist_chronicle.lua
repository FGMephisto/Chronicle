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

	local validKeys = {};
	if DataCommon.abilities then
		for _, sAbility in ipairs(DataCommon.abilities) do
			validKeys[sAbility:lower()] = true;
		end
	end
	for k, _ in pairs(DataCommon.abilitydata) do
		validKeys[StringManager.simplify(k)] = true;
	end

	local entrymap = {};
	local duplicates = {};

	for _, w in pairs(getWindows()) do
		local node = w.getDatabaseNode();
		if node then
			local sName = (w.name and w.name.getValue()) or "";
			local sNodeName = DB.getName(node):lower();

			local sKey = "";
			if validKeys[sNodeName] then
				sKey = sNodeName;
			elseif sName ~= "" and DataCommon.ability_stol and DataCommon.ability_stol[sName:upper()] and validKeys[DataCommon.ability_stol[sName:upper()]] then
				sKey = DataCommon.ability_stol[sName:upper()];
			elseif sName ~= "" and validKeys[StringManager.simplify(sName)] then
				sKey = StringManager.simplify(sName);
			end

			if sKey ~= "" then
				if not entrymap[sKey] then
					entrymap[sKey] = w;
				else
					local prevW = entrymap[sKey];
					local prevNode = prevW.getDatabaseNode();
					if prevNode and DB.getName(prevNode):lower() ~= sKey and sNodeName == sKey then
						local nPrevBase = DB.getValue(prevNode, "base", DB.getValue(prevNode, "score", 0));
						local nPrevBonus = DB.getValue(prevNode, "bonus", 0);
						if DB.getValue(node, "base", 0) == 0 and nPrevBase ~= 0 then
							DB.setValue(node, "base", "number", nPrevBase);
						end
						if nPrevBonus ~= 0 and DB.getValue(node, "bonus", 0) == 0 then
							DB.setValue(node, "bonus", "number", nPrevBonus);
						end
						entrymap[sKey] = w;
						table.insert(duplicates, prevW);
					else
						if prevNode then
							local nWBase = DB.getValue(node, "base", DB.getValue(node, "score", 0));
							local nWBonus = DB.getValue(node, "bonus", 0);
							if DB.getValue(prevNode, "base", 0) == 0 and nWBase ~= 0 then
								DB.setValue(prevNode, "base", "number", nWBase);
							end
							if nWBonus ~= 0 and DB.getValue(prevNode, "bonus", 0) == 0 then
								DB.setValue(prevNode, "bonus", "number", nWBonus);
							end
						end
						table.insert(duplicates, w);
					end
				end
			else
				table.insert(duplicates, w);
			end
		end
	end

	-- Close duplicate / invalid windows from UI
	for _, w in ipairs(duplicates) do
		w.close();
	end

	-- Ensure each defined ability exists exactly once with shorthand label and canonical node name
	for k, t in pairs(DataCommon.abilitydata) do
		local sKey = StringManager.simplify(k);
		local w = entrymap[sKey];

		if not w then
			w = createWindowWithClass(sItemClass, "." .. sKey);
			if w then
				entrymap[sKey] = w;
			end
		elseif w.getDatabaseNode() and DB.getName(w.getDatabaseNode()):lower() ~= sKey then
			local oldNode = w.getDatabaseNode();
			local nBase = DB.getValue(oldNode, "base", DB.getValue(oldNode, "score", 0));
			local nBonus = DB.getValue(oldNode, "bonus", 0);

			w.close();

			w = createWindowWithClass(sItemClass, "." .. sKey);
			if w then
				entrymap[sKey] = w;
				DB.setValue(w.getDatabaseNode(), "base", "number", nBase);
				DB.setValue(w.getDatabaseNode(), "bonus", "number", nBonus);
				DB.setValue(w.getDatabaseNode(), "score", "number", nBase + nBonus);
			end
		end

		if w then
			if w.name then
				w.name.setValue(k);
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