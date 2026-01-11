--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.rebuildSlots();
	DB.addHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", self.rebuildSlots);
	self.onModeChanged();
end
function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "powermeta.*.max"), "onUpdate", self.rebuildSlots);
end

function onModeChanged()
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end
function onLockModeChanged(bReadOnly)
	if not bReadOnly then
		parentcontrol.setVisible(false);
		return;
	end

	local nodeChar = getDatabaseNode();

	local bSpellSlotsVisible = false;
	for i = 1, PowerManager.SPELL_LEVELS do
		if DB.getValue(nodeChar, "powermeta.spellslots" .. i .. ".max", 0) > 0 then
			bSpellSlotsVisible = true;
			break;
		end
	end
	local bPactMagicSlotsVisible = false;
	for i = 1, PowerManager.SPELL_LEVELS do
		if DB.getValue(nodeChar, "powermeta.pactmagicslots" .. i .. ".max", 0) > 0 then
			bPactMagicSlotsVisible = true;
			break;
		end
	end

	spellslots.setVisible(bSpellSlotsVisible);
	spellslots_label.setVisible(bSpellSlotsVisible and bPactMagicSlotsVisible);
	pactmagicslots.setVisible(bPactMagicSlotsVisible);
	pactmagicslots_label.setVisible(bPactMagicSlotsVisible);

	parentcontrol.setVisible(bSpellSlotsVisible or bPactMagicSlotsVisible);
end

-- NOTE: We can not delete windows here;
-- 		because the counters in each window also have database node handlers
--		that will trigger either before or after
--		and can will generate errors when control no longer exists.
function rebuildListSlots(ctrlList, sPrefix)
	if not ctrlList or ((sPrefix or "") == "") then
		return;
	end

	local tWindows = ctrlList.getWindows();

	local nodeChar = getDatabaseNode();
	for i = 1, PowerManager.SPELL_LEVELS do
		if DB.getValue(nodeChar, "powermeta." .. sPrefix .. i .. ".max", 0) > 0 then
			local sLabel = self.getOrdinalLabel(i);
			local bExists = false;
			for _,wChild in ipairs(tWindows) do
				if wChild.label.getValue() == sLabel then
					bExists = true;
				end
			end
			if not bExists then
				local w = ctrlList.createWindow();
				w.label.setValue(sLabel);
				w.counter.setMaxNode(DB.getPath(nodeChar, "powermeta." .. sPrefix .. i .. ".max"));
				w.counter.setCurrNode(DB.getPath(nodeChar, "powermeta." .. sPrefix .. i .. ".used"));
			end
		end
	end

	ctrlList.applyFilter();
	ctrlList.applySort();
end

function getOrdinalLabel(n)
	if n <= 0 then
		return tostring(n) or "";
	end
	if n == 1 then
		return "1st";
	elseif n == 2 then
		return "2nd";
	elseif n == 3 then
		return "3rd";
	end
	return (tostring(n) or "") .. "th";
end

function rebuildSlots()
	self.rebuildListSlots(spellslots, "spellslots");
	self.rebuildListSlots(pactmagicslots, "pactmagicslots");
end
