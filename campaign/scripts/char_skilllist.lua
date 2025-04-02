--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bInitialized = false;

function onInit()
	self.constructDefaultSkills();
	_bInitialized = true;
end

function onChildWindowCreated(w)
	if _bInitialized then
		w.setCustom(true);
	end
end

-- Create default skill selection
function constructDefaultSkills()
	-- Collect existing entries
	local entrymap = {};

	for _,w in pairs(getWindows()) do
		local sLabel = w.name.getValue();

		if DataCommon.skilldata[sLabel] then
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				table.insert(entrymap[sLabel], w);
			end
		else
			w.setCustom(true);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		local matches = entrymap[k];

		if not matches then
			local w = createWindow();
			if w then
				w.name.setValue(k);
				if t.stat then
					w.stat.setStringValue(t.stat);
				else
					w.stat.setStringValue("");
				end
				matches = { w };
			end
		end

		-- Update properties
		local bCustom = false;
		for _, match in pairs(matches) do
			match.setCustom(bCustom);
			if t.disarmorstealth then
				match.armorwidget.setVisible(true);
			end
			bCustom = true;
		end
	end
end

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
