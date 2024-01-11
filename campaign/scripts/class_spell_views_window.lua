-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.refresh();
end

function refresh()
	list.closeAll();

	local tClasses = ClassSpellListManager.getClassesWithSpellList();
	for _,sClassName in ipairs(tClasses) do
		if sClassName ~= "" then
			local w = list.createWindow();
			w.name.setValue(StringManager.titleCase(sClassName));
			w.link.setValue("class_spell_view", "class_spell_view." .. ClassSpellListManager.generateNameKey(sClassName));
		end
	end
end
