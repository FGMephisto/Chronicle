-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	self.update();
end

function update(bReadOnly, bID)
	local tFields = { "weapon_speciality", "weapon_training", "weapon_dmg_ability", "weapon_dmg_bonus", "weapon_qualities" };
	WindowManager.callSafeControlsUpdate(self, tFields, bReadOnly, not bID or bReadOnly);

	if bReadOnly == true then
		local sWeaponDmgAbility = weapon_dmg_ability.getValue();
		local sDmgBonus = weapon_dmg_bonus.getValue();
		local sWeaponDmg = "";

		if sDmgBonus == 0 then
			sWeaponDmg = sWeaponDmgAbility;
		elseif sDmgBonus > 0 then
			sWeaponDmg = sWeaponDmgAbility .. " + " .. sDmgBonus;
		elseif sDmgBonus < 0 then
			sWeaponDmg = sWeaponDmgAbility .. " - " .. (sDmgBonus * -1);
		end

		weapon_dmg_string.setValue(sWeaponDmg);
	end

	WindowManager.callSafeControlUpdate(self, "weapon_dmg_string", bReadOnly, not bID or not bReadOnly);

	parentcontrol.setVisible(WindowManager.getAnyControlVisible(self, { "weapon_speciality", "weapon_training", "weapon_dmg_ability", "weapon_dmg_bonus", "weapon_dmg_string", "weapon_qualities" }));
end