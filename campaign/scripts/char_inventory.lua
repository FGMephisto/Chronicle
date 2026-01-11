--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals attunecalc.warning

function onInit()
	OptionsManager.registerCallback("HREN", self.onHRENOptionChanged);
	self.onHRENOptionChanged();

	self.updateAttunement();
end

function onClose()
	OptionsManager.unregisterCallback("HREN", self.onHRENOptionChanged);
end

function onHRENOptionChanged()
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
