-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onInit()
	setColor(ColorManager.getButtonTextColor());
	if Session.IsHost then
		registerMenuItem(Interface.getString("ct_menu_initmenu"), "turn", 7);
		registerMenuItem(Interface.getString("ct_menu_initall"), "shuffle", 7, 8);
		registerMenuItem(Interface.getString("ct_menu_initnpc"), "mask", 7, 7);
		registerMenuItem(Interface.getString("ct_menu_initpc"), "portrait", 7, 6);
		registerMenuItem(Interface.getString("ct_menu_initclear"), "pointer_circle", 7, 4);

		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 8);
		-- registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 8, 8);
		-- registerMenuItem(Interface.getString("menu_restlong"), "pointer_circle", 8, 6);

		registerMenuItem(Interface.getString("ct_menu_itemdelete"), "delete", 3);
		registerMenuItem(Interface.getString("ct_menu_itemdeletenonfriendly"), "delete", 3, 1);
		registerMenuItem(Interface.getString("ct_menu_itemdeletefoe"), "delete", 3, 3);

		registerMenuItem(Interface.getString("ct_menu_effectdelete"), "hand", 5);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteall"), "pointer_circle", 5, 7);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteexpiring"), "pointer_cone", 5, 5);
	end
end

function onClickDown()
	return true;
end
function onClickRelease()
	Interface.openContextMenu();
	return true;
end

-- Adjusted
function onMenuSelection(selection, subselection)
	if Session.IsHost then
		if selection == 7 then
			if subselection == 4 then
				CombatManager.resetInit();
			elseif subselection == 8 then
				CombatManager2.rollInit();
			elseif subselection == 7 then
				CombatManager2.rollInit("npc");
			elseif subselection == 6 then
				CombatManager2.rollInit("pc");
			end
		end
		if selection == 8 then
			-- if subselection == 8 then
				ChatManager.Message(Interface.getString("message_restallshort"), true);
				CombatManager2.rest(false);
			-- elseif subselection == 6 then
				-- ChatManager.Message(Interface.getString("message_restalllong"), true);
				-- CombatManager2.rest(true);
			-- end
		end
		if selection == 5 then
			if subselection == 7 then
				CombatManager.resetCombatantEffects();
			elseif subselection == 5 then
				CombatManager2.clearExpiringEffects();
			end
		end
		if selection == 3 then
			if subselection == 1 then
				CombatManager.deleteNonFaction("friend");
			elseif subselection == 3 then
				CombatManager.deleteFaction("foe");
			end
		end
	end
end