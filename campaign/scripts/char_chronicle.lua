-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 7)
	end

	-- local nodeChar = getDatabaseNode();
	-- CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

-- ===================================================================================================================
-- ===================================================================================================================
function onMenuSelection(selection, subselection)
	-- Debug.chat("FN: onMenuSelection in char")
	if selection == 7 then
		local nodeChar = getDatabaseNode();
		ChatManager.Message(Interface.getString("message_restshort"), true, ActorManager.resolveActor(nodeChar));
		CharManager.rest(nodeChar, false)
	end
end