-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DRAGTYPE_BASTIONORDER = "bastionorder";

function onInit()
	OptionsManager.registerCallback("HRBASTION", CharBastionManager.onOptionChanged);
end

function onOptionChanged()
	for _,w in ipairs(Interface.getWindows("charsheet")) do
		WindowManager.callInnerWindowFunction(w, "onBastionOptionChanged");
	end
end

function openBastionLog()
	Interface.openWindow("ps_bastion_log", "partysheet.bastionlog");
end

function advanceTurn()
	CharBastionManager.advanceBastionLog();
	CharBastionManager.advanceFacilityTurns();
end
function advanceBastionLog()
	local nodeLog = DB.createNode("partysheet.bastionlog");
	local nTurn = DB.getValue(nodeLog, "turn", 0);

	local tLogTurn = {};
	table.insert(tLogTurn, string.format("<h>BASTION TURN: %d</h>", nTurn));

	for _,nodePSChar in ipairs(DB.getChildList("partysheet.partyinformation")) do
		local _,sRecord = DB.getValue(nodePSChar, "link", "", "");
		if sRecord ~= "" then
			local nodeBastion = DB.findNode(DB.getPath(sRecord, "bastion"));
			if nodeBastion and (DB.getChildCount(nodeBastion, "sublocations") > 0) then
				local tLogPlayer = {};
				table.insert(tLogPlayer, string.format("<p><b>%s</b></p>", DB.getValue(nodePSChar, "name", "")));
				table.insert(tLogPlayer, "<list>");
				for _,nodeFacility in ipairs(DB.getChildList(nodeBastion, "sublocations")) do
					local sName = DB.getValue(nodeFacility, "name", "");
					local sOrder = DB.getValue(nodeFacility, "order", "");
					if sOrder == "" then
						table.insert(tLogPlayer, string.format("<li>%s - %s</li>", sName, Interface.getString("ps_label_bastion_facility_order_none")));
					else
						local nDuration = DB.getValue(nodeFacility, "duration", 0);
						table.insert(tLogPlayer, string.format("<li>%s - %s - %d TURNS LEFT</li>", sName, sOrder, math.max(nDuration - 1, 0)));
					end
				end
				table.insert(tLogPlayer, "</list>");
				table.insert(tLogTurn, table.concat(tLogPlayer));
			end
		end
	end

	DB.setValue(nodeLog, "turn", "number", nTurn + 1);
	DB.setValue(nodeLog, "text", "formattedtext", DB.getValue(nodeLog, "text", "") .. table.concat(tLogTurn));
end
function advanceFacilityTurns(nodeBastion)
	for _,nodePSChar in ipairs(DB.getChildList("partysheet.partyinformation")) do
		local _,sRecord = DB.getValue(nodePSChar, "link", "", "");
		if sRecord ~= "" then
			local nodeBastion = DB.findNode(DB.getPath(sRecord, "bastion"));
			if nodeBastion then
				for _,nodeFacility in ipairs(DB.getChildList(nodeBastion, "sublocations")) do
					local nNewDuration = math.max(DB.getValue(nodeFacility, "duration", 0) - 1, 0);
					if nNewDuration == 0 then
						CharBastionManager.clearFacilityOrder(nodeFacility);
					else
						DB.setValue(nodeFacility, "duration", "number", nNewDuration);
					end
				end
			end
		end
	end
end

function onOrderButtonDrag(draginfo, sOrderTag)
	if not draginfo or ((sOrderTag or "") == "") then
		return false;
	end

	local sOrder = Interface.getString("ps_label_bastion_facility_order_" .. sOrderTag);
	draginfo.setType(CharBastionManager.DRAGTYPE_BASTIONORDER);
	draginfo.setDescription(sOrder);
	draginfo.setStringData(sOrder);
	draginfo.setNumberData(1);
	return true;
end
function onPartyFacilityDrop(nodeFacility, draginfo)
	if draginfo.isType(CharBastionManager.DRAGTYPE_BASTIONORDER) then
		if not Session.IsHost and not DB.isOwner(nodeFacility) then
			return true;
		end

		local sOrder = draginfo.getDescription();
		local nDuration = draginfo.getNumberData();
		if DB.getValue(nodeFacility, "order", "") == sOrder then
			DB.setValue(nodeFacility, "duration", "number", DB.getValue(nodeFacility, "duration", 0) + nDuration);
		else
			DB.setValue(nodeFacility, "order", "string", sOrder);
			DB.setValue(nodeFacility, "duration", "number", nDuration);
		end
		return true;
	end
	return true;
end
function clearFacilityOrder(nodeFacility)
	if not nodeFacility then
		return;
	end
	DB.setValue(nodeFacility, "duration", "number", 0);
	DB.setValue(nodeFacility, "order", "string", "");
end

function clearBastionLog()
	local nodeLog = DB.findNode("partysheet.bastionlog");
	if not nodeLog then
		return;
	end
	DB.setValue(nodeLog, "text", "formattedtext", "");
end
function resetBastionTurns()
	local nodeLog = DB.findNode("partysheet.bastionlog");
	if not nodeLog then
		return;
	end
	DB.setValue(nodeLog, "turn", "number", 0);
end
