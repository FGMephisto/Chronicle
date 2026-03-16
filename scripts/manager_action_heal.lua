--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	GameManager.setFunction("onHealPostModRoll", ActionHeal.onPostModRoll);
end

--
--	MOD ROLL
--

function onPostModRoll(rSource, rTarget, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);
end
