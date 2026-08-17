-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals attunecalc.warning

function onInit()
	do return; end -- Disabled -> exit
	OptionsManager.registerCallback("HREN", onHRENOptionChanged);
	onHRENOptionChanged();

	updateAttunement();
end

function onClose()
	do return; end -- Disabled -> exit
	OptionsManager.unregisterCallback("HREN", onHRENOptionChanged);
end

function onHRENOptionChanged()
	do return; end -- Disabled -> exit
	local sOptionHREN = OptionsManager.getOption("HREN");
	local bShowVariant = (sOptionHREN == "variant");
	encumbrancebase_label.setVisible(bShowVariant);
	encumbrancebase.setVisible(bShowVariant);
	encumbranceheavy_label.setVisible(bShowVariant);
	encumbranceheavy.setVisible(bShowVariant);
end

function onDrop(_, _, draginfo)
	return ItemManager.handleAnyDrop(getDatabaseNode(), draginfo);
end

function updateAttunement()
	do return; end -- Disabled -> exit
	local nodeChar = getDatabaseNode();
	local nUsed = CharAttunementManager.getUsedSlots(nodeChar);
	local nAllowed = CharAttunementManager.getTotalSlots(nodeChar);
	local sUsage = string.format("%d / %d", nUsed, nAllowed);

	attunecalc.setValue(sUsage);
	if nUsed > nAllowed then
		attunecalc.setColor(attunecalc.warning[1])
	else
		attunecalc.setColor(nil);
	end
end