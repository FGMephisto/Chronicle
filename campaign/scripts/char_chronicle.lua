-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 7);
	end
end

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function onMenuSelection(selection, subselection)
	-- Debug.chat("FN: onMenuSelection in char")
	if selection == 7 then
		local nodeChar = getDatabaseNode();
		ChatManager.Message(Interface.getString("message_restshort"), true, ActorManager.resolveActor(nodeChar));
		CharManager.rest(nodeChar, false);
	end
end

-- ===================================================================================================================
-- Disabled
-- ===================================================================================================================
function updateAttunement()
	-- if inventory.subwindow then
		-- if inventory.subwindow.contents.subwindow then
			-- inventory.subwindow.contents.subwindow.updateAttunement();
		-- end
	-- end
end