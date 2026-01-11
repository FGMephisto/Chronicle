--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.updateLinkRecord();
	self.populateBastionView();
end
function onClose()
	self.removeHandlers();
end

function addHandlers()
	local sRecord = self.getLinkRecord();
	if sRecord ~= "" then
		DB.addHandler(DB.getPath(sRecord, "bastion"), "onAdd", self.onBastionAdded);
		DB.addHandler(DB.getPath(sRecord, "bastion"), "onDelete", self.onBastionDeleted);
	end
end
function removeHandlers()
	local sRecord = self.getLinkRecord();
	if sRecord ~= "" then
		DB.removeHandler(DB.getPath(sRecord, "bastion"), "onAdd", self.onBastionAdded);
		DB.removeHandler(DB.getPath(sRecord, "bastion"), "onDelete", self.onBastionDeleted);
	end
end

local _sRecord = "";
function getLinkRecord()
	return _sRecord;
end
function updateLinkRecord()
	self.removeHandlers();
	_, _sRecord = link.getValue();
	self.addHandlers();
end
function onLinkChanged()
	self.updateLinkRecord();
	portrait.update();
	self.populateBastionView();
end

function onBastionAdded()
	self.populateBastionView();
end
function onBastionDeleted()
	self.populateBastionView();
end

function populateBastionView()
	local nodeBastion;
	local sRecord = self.getLinkRecord();
	if sRecord ~= "" then
		local sBastionPath = DB.getPath(sRecord, "bastion");
		nodeBastion = DB.findNode(sBastionPath);
	end
	if nodeBastion then
		sub_bastion.setValue("ps_bastion_entry_contents", nodeBastion);
	else
		sub_bastion.setValue("", "");
	end
end
