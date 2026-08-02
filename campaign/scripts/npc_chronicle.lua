-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onIDChanged();
end

function onMenuSelection(selection)
	-- if selection == 7 then
		-- CampaignDataManager2.updateNPCSpells(getDatabaseNode());
	-- end
end

function onLockChanged()
	StateChanged();
end

function StateChanged()
	if header and header.subwindow then
		if header.subwindow.update then
			header.subwindow.update();
		end
		if header.subwindow.npc_header_contents and header.subwindow.npc_header_contents.subwindow then
			if header.subwindow.npc_header_contents.subwindow.update then
				header.subwindow.npc_header_contents.subwindow.update();
			end
		end
	end
end

function onIDChanged()
	if Session.IsHost then
		if header and header.subwindow and header.subwindow.npc_header_contents and header.subwindow.npc_header_contents.subwindow then
			if header.subwindow.npc_header_contents.subwindow.update then
				header.subwindow.npc_header_contents.subwindow.update();
			end
		end
	else
		local bID = LibraryData.getIDState("npc", getDatabaseNode(), true);
		if tabs then
			if tabs.setVisibility then
				tabs.setVisibility(bID);
			elseif tabs.setVisible then
				tabs.setVisible(bID);
			end
		end
	end
end