-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);

	for k,v in pairs(_tDataModuleSets) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end
end

-- ===================================================================================================================
-- Shown in Modifiers window
-- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
-- Adjusted
-- ===================================================================================================================
_tModifierWindowPresets =
{
	{
		sCategory = "attack",
		tPresets = 
		{
			"ATT_AIM",
			"ATT_HIGHGROUND",
			"ATT_CAUTIOUS",
			"ATT_RECKLESS",
			"DEF_COVER",
			"DEF_SCOVER",
			"DEF_LOWLIGHT",
			"DEF_NOLIGHT",
			"DEF_SPRINT",
		},
	},
	{ 
		sCategory = "damage",
		tPresets = { 
			-- "DMG_CRIT",
			-- "DMG_MAX",
			-- "",
			-- "DMG_HALF",
		}
	},
};
_tModifierExclusionSets =
{
	{ "ATT_CAUTIOUS", "ATT_RECKLESS" },
	{ "DEF_COVER", "DEF_SCOVER" },
	{ "DEF_LOWLIGHT", "DEF_NOLIGHT" },
};

-- ===================================================================================================================
-- Shown in Campaign Setup window
-- Adjusted
-- ===================================================================================================================
_tDataModuleSets = 
{
	["client"] =
	{
		{
			name = "Chronicle Data",
			modules =
			{
				{ name = "Chronicle Data", displayname = "Chronicle Data" },
			},
		},
	},
	["host"] =
	{
		{
			name = "Chronicle Data",
			modules =
			{
				{ name = "Chronicle Data", displayname = "Chronicle Data" },
			},
		},
	},
};