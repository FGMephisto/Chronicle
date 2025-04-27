-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ToDo: Where is this now?

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	self.update()
	
	-- Fill drop-down with values
	weapon_speciality.addItems(DataCommon.wpnskilldata)
end

-- ===================================================================================================================
-- ===================================================================================================================
function update(bReadOnly)
	weapon_speciality.setReadOnly(bReadOnly)
	weapon_training.setReadOnly(bReadOnly)
	weapon_dmg_ability.setReadOnly(bReadOnly)
	weapon_dmg_bonus.setReadOnly(bReadOnly)
	weapon_dmg_string.setReadOnly(bReadOnly)
	weapon_qualities.setReadOnly(bReadOnly)

	-- Update weapon damage string if ReadOnly
	if bReadOnly == true then
		local sWeaponDmgAbility = ""
		local sDmgBonus = 0
		local sWeaponDmg = ""
		
		-- Get ability and damage modifier from controls, there are no DB entires
		sWeaponDmgAbility = weapon_dmg_ability.getValue()
		sDmgBonus = weapon_dmg_bonus.getValue()

		-- Concatenate Ability and Damage Modifier
		if sDmgBonus == 0 then
			sWeaponDmg = sWeaponDmgAbility
		elseif sDmgBonus > 0 then
			sWeaponDmg = sWeaponDmgAbility .. " + " .. sDmgBonus
		elseif sDmgBonus < 0 then
			sWeaponDmg = sWeaponDmgAbility .. " - " .. sDmgBonus*-1
		end

		-- Store damage value for consumption by the Weapon Item Table
		weapon_dmg_string.setValue(sWeaponDmg)
	end

	-- Hide/show some controls based on bReadOnly. By default these objects only hide if empty which they are usually not.
	if bReadOnly == true then
		weapon_speciality_label.setVisible(false)
		weapon_speciality.setVisible(false)
		weapon_speciality_cbbutton.setVisible(false)
		weapon_dmg_ability_label.setVisible(false)
		weapon_dmg_ability.setVisible(false)
		weapon_dmg_ability_cbbutton.setVisible(false)
		weapon_dmg_bonus_label.setVisible(false)
		weapon_dmg_bonus.setVisible(false)
		weapon_dmg_string_label.setVisible(true)
		weapon_dmg_string.setVisible(true)
	else
		weapon_speciality_label.setVisible(true)
		weapon_speciality.setVisible(true)
		weapon_speciality_cbbutton.setVisible(true)
		weapon_dmg_ability_label.setVisible(true)
		weapon_dmg_ability.setVisible(true)
		weapon_dmg_ability_cbbutton.setVisible(true)
		weapon_dmg_bonus_label.setVisible(true)
		weapon_dmg_bonus.setVisible(true)
		weapon_dmg_string_label.setVisible(false)
		weapon_dmg_string.setVisible(false)
	end
end