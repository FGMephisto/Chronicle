-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	DesktopManager.setSidebarDockCategoryIconColor("A3A29D");
	DesktopManager.setSidebarDockCategoryTextColor("A3A29D");
	DesktopManager.setSidebarDockIconColor("332A25");
	DesktopManager.setSidebarDockTextColor("332A25");

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
-- ===================================================================================================================
_tDataModuleSets = 
{
	["client"] =
	{
		{
			name = "Chronicle Ruleset Data",
			modules =
			{
				{ name = "Chronicle Ruleset Data", displayname = "Chronicle Ruleset Data" },
			},
		},
	},
	["host"] =
	{
		{
			name = "Chronicle Ruleset Data",
			modules =
			{
				{ name = "Chronicle Ruleset Data", displayname = "Chronicle Ruleset Data" },
			},
		},
	},
};