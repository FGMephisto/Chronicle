--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals _tDataModuleSets _tModifierExclusionSets _tModifierWindowPresets

function onInit()
	CampaignSetupManager.addAutoLoadRules(_tAutoLoadRules);
	CampaignSetupManager.addModuleSetsByMode(_tDataModuleSets);

	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);
end

_tAutoLoadRules = {
	{ key = "PHB", load = { "WOTC50PHB", }, playerload = { "WOTC50PHB", }, },
	{ key = "PHB", load = { "WOTC5EPHB", }, playerload = { "WOTC5EPHB", }, },
	{ key = "PHB", load = { "DNDSRD521PLAYER", }, playerload = { "DNDSRD521PLAYER", }, },
	{ key = "DMG", load = { "WOTC50DMG", "WOTC50DMGBastions", }, },
	{ key = "DMG", load = { "WOTC5EDMG", }, },
	{ key = "DMG", load = { "DNDSRD521MAGICITEMS", }, },
	{ key = "MM", load = { "WOTC50MM", }, },
	{ key = "MM", load = { "WOTC5EMM", }, },
	{ key = "MM", load = { "DNDSRD521BESTIARY", }, },
	{ load = { "DD Bigby Presents Glory of the Giants", "DD Bigby Presents Glory of the Giants - Players", }, playerload = { "DD Bigby Presents Glory of the Giants - Players", }, },
	{ load = { "DD The Book of Many Things", "DD The Book of Many Things - Players", }, playerload = { "DD The Book of Many Things - Players", }, },
	{ load = { "WOTC50EFOTADM", "WOTC50EFOTAPG", }, playerload = { "WOTC50EFOTAPG", }, },
	--{ load = { "DD Eberron Rising From the Last War - DM", "DD Eberron Rising From the Last War - Players", }, playerload = { "DD Eberron Rising From the Last War - Players", }, },
	{ load = { "Fizban's Treasury of Dragon", "DD Fizban's Treasury of Dragons Players", }, playerload = { "DD Fizban's Treasury of Dragons Players", }, },
	{ load = { "WOTC50FRAIF", }, },
	{ load = { "WOTC50FRHOF", }, playerload = { "WOTC50FRHOF", }, },
	{ load = { "WOTC50SSHOTBDM", "WOTC50SSHOTBP", }, playerload = { "WOTC50SSHOTBP", }, }, 
	{ load = { "DD Monsters of the Multiverse", "DD Monsters of the Multiverse Players", }, playerload = { "DD Monsters of the Multiverse Players", }, },
	{ load = { "DD Mordenkainen's Tome of Foes", "DD Mordenkainen's Tome of Foes Players", }, playerload = { "DD Mordenkainen's Tome of Foes Players", }, },
	--{ load = { "DD Sword Coast Adventurer's Guide - Campaign Guide", "DD Sword Coast Adventurer's Guide - Player's Guide", }, playerload = { "DD Sword Coast Adventurer's Guide - Player's Guide", }, },
	{ load = { "DD Tashas Cauldron of Everything", "DD Tashas Cauldron of Everything - Players", }, playerload = { "DD Tashas Cauldron of Everything - Players", }, },
	{ load = { "The Tortle Package", "The Tortle Package - Player", }, playerload = { "The Tortle Package - Player", }, },
	{ load = { "DD Volos Guide to Monsters", "Volos Guide to Monsters Players", }, playerload = { "Volos Guide to Monsters Players", }, },
	{ load = { "DD Xanathar's Guide to Everything", "DD Xanathar's Guide to Everything Players", }, playerload = { "DD Xanathar's Guide to Everything Players", }, },
};
_tDataModuleSets =
{
	["client"] =
	{
		{
			name = "2024 - Free Rules",
			modules =
			{
				{ name = "DND2024FREERULES", displayname = "D&D Free Rules" },
			},
		},
		{
			name = "2024 - Core Rules",
			modules =
			{
				{ name = "WOTC50PHB", storeid = "WOTC50PHB", displayname = "D&D Player's Handbook" },
				{ name = "WOTC50DMGBastions", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide - Player" },
			},
		},
		{
			name = "2014 - SRD",
			modules =
			{
				{ name = "DD5E SRD Data", displayname = "D&D SRD Data" },
			},
		},
		{
			name = "2014 - Basic Rules",
			modules =
			{
				{ name = "DD Basic Rules - Player", displayname = "D&D Basic Rules - Player" },
			},
		},
		{
			name = "2014 - Core Rules",
			modules =
			{
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE", displayname = "D&D Player's Handbook (Legacy)" },
			},
		},
		{
			name = "All Rules",
			modules =
			{
				{ name = "WOTC50PHB", storeid = "WOTC50PHB", displayname = "D&D Player's Handbook" },
				{ name = "WOTC50DMGBastions", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide - Player" },
				{ name = "DD Curse of Strahd Players", storeid = "WOTC5ECOS", displayname = "D&D Curse of Strahd - Player" },
				{ name = "DD Eberron Rising From the Last War - Players", storeid = "WOTC5EERFTLW", displayname = "D&D Eberron Rising From the Last War - Player" },
				{ name = "DD Elemental Evil Players Companion", storeid = "WOTC5EEEPC", displayname = "D&D Elemental Evil Player's Companion" },
				{ name = "DD Monsters of the Multiverse Players", storeid = "WOTC5EMPMOTM", displayname = "D&D Mordenkainen Presents Monsters of the Multiverse - Player" },
				{ name = "DD Mordenkainen's Tome of Foes Players", storeid = "WOTC5EMTOF", displayname = "D&D Mordenkainen's Tome of Foes - Player" },
				{ name = "Spelljammer Astral Adventurer's Guide - Players", storeid = "WOTC5ESPJAIS5E", displayname = "D&D Spelljammer Astral Adventurer's Guide - Player" },
				{ name = "DD Sword Coast Adventurer's Guide - Player's Guide", storeid = "WOTC5ESCAG", displayname = "D&D Sword Coast Adventurer's Guide - Player"  },
				{ name = "DD Tashas Cauldron of Everything - Players", storeid = "WOTC5ETCE", displayname = "D&D Tasha's Cauldron of Everything - Player" },
				{ name = "DD The Book of Many Things - Players", storeid = "WOTC5ETBOMT", displayname = "D&D The Book of Many Things - Players" },
				{ name = "DD Tomb of Annihilation - Players", storeid = "WOTC5ETOA", displayname = "D&D Tomb of Annihilation - Player" },
				{ name = "Volos Guide to Monsters Players", storeid = "WOTC5EVGM", displayname = "D&D Volo's Guide to Monsters - Player" },
				{ name = "D&D Wayfinder's Guide to Eberron", storeid = "WOTC5EWGTE" },
				{ name = "Van Riichten's Guide to Ravenloft - Players", storeid = "WOTC5EVRGTR", displayname = "D&D Van Richten's Guide to Ravenloft - Player" },
				{ name = "DD Xanathar's Guide to Everything Players", storeid = "WOTC5EXGTE", displayname = "D&D Xanathar's Guide to Everything - Player" },
			},
		},
	},
	["host"] =
	{
		{
			name = "2024 - Free Rules",
			modules =
			{
				{ name = "DND2024FREERULES", displayname = "D&D Free Rules" },
			},
		},
		{
			name = "2024 - Core Rules",
			modules =
			{
				{ name = "WOTC50PHB", storeid = "WOTC50PHB", displayname = "D&D Player's Handbook" },
				{ name = "WOTC50DMG", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide" },
				{ name = "WOTC50DMGBastions", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide - Player" },
				{ name = "WOTC50MM", storeid = "WOTC50MM", displayname = "D&D Monster Manual" },
			},
		},
		{
			name = "2014 - SRD",
			modules =
			{
				{ name = "DD5E SRD Bestiary", displayname = "D&D SRD Bestiary" },
				{ name = "DD5E SRD Data", displayname = "D&D SRD Data" },
				{ name = "DD5E SRD Magic Items", displayname = "D&D SRD Magic Items" },
			},
		},
		{
			name = "2014 - Basic Rules",
			modules =
			{
				{ name = "DD Basic Rules - DM", displayname = "D&D Basic Rules" },
				{ name = "DD Basic Rules - Player", displayname = "D&D Basic Rules - Player" },
			},
		},
		{
			name = "2014 - Core Rules",
			modules =
			{
				{ name = "DD Dungeon Masters Guide", storeid = "WOTC5EDMG", displayname = "D&D Dungeon Master's Guide (Legacy)" },
				{ name = "DD Dungeon Masters Guide - Players", storeid = "WOTC5EDMG", displayname = "D&D Dungeon Master's Guide - Player (Legacy)" },
				{ name = "DD MM Monster Manual", storeid = "WOTC5EMMDELUXE", displayname = "D&D Monster Manual" },
				{ name = "DD PHB Deluxe", storeid = "WOTC5EPHBDELUXE", displayname = "D&D Player's Handbook (Legacy)" },
			},
		},
		{
			name = "All Rules",
			modules =
			{
				{ name = "WOTC50PHB", storeid = "WOTC50PHB", displayname = "D&D Player's Handbook" },
				{ name = "WOTC50DMG", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide" },
				{ name = "WOTC50DMGBastions", storeid = "WOTC50DMG", displayname = "D&D Dungeon Master's Guide - Player" },
				{ name = "WOTC50MM", storeid = "WOTC50MM", displayname = "D&D Monster Manual" },
				{ name = "DD Curse of Strahd Players", storeid = "WOTC5ECOS", displayname = "D&D Curse of Strahd - Player" },
				{ name = "DD Eberron Rising From the Last War - DM", storeid = "WOTC5EERFTLW", displayname = "D&D Eberron Rising From the Last War"},
				{ name = "DD Eberron Rising From the Last War - Players", storeid = "WOTC5EERFTLW", displayname = "D&D Eberron Rising From the Last War - Player" },
				{ name = "DD Elemental Evil Players Companion", storeid = "WOTC5EEEPC", displayname = "D&D Elemental Evil Player's Companion" },
				{ name = "DD Monsters of the Multiverse", storeid = "WOTC5EMPMOTM", displayname = "D&D Mordenkainen Presents Monsters of the Multiverse" },
				{ name = "DD Monsters of the Multiverse Players", storeid = "WOTC5EMPMOTM", displayname = "D&D Mordenkainen Presents Monsters of the Multiverse - Player" },
				{ name = "DD Mordenkainen's Tome of Foes", storeid = "WOTC5EMTOF", displayname = "D&D Mordenkainen's Tome of Foes" },
				{ name = "DD Mordenkainen's Tome of Foes Players", storeid = "WOTC5EMTOF", displayname = "D&D Mordenkainen's Tome of Foes - Player" },
				{ name = "DD Spelljammer Astral Adventure Guide DM", storeid = "WOTC5ESPJAIS5E", displayname = "D&D Spelljammer Astral Adventurer's Guide" },
				{ name = "Spelljammer Astral Adventurer's Guide - Players", storeid = "WOTC5ESPJAIS5E", displayname = "D&D Spelljammer Astral Adventurer's Guide - Player" },
				{ name = "DD Sword Coast Adventurer's Guide - Campaign Guide", storeid = "WOTC5ESCAG", displayname = "D&D Sword Coast Adventurer's Guide" },
				{ name = "DD Sword Coast Adventurer's Guide - Player's Guide", storeid = "WOTC5ESCAG", displayname = "D&D Sword Coast Adventurer's Guide - Player"  },
				{ name = "DD Tashas Cauldron of Everything", storeid = "WOTC5ETCE", displayname = "D&D Tasha's Cauldron of Everything" },
				{ name = "DD Tashas Cauldron of Everything - Players", storeid = "WOTC5ETCE", displayname = "D&D Tasha's Cauldron of Everything - Player" },
				{ name = "DD The Book of Many Things", storeid = "WOTC5ETBOMT", displayname = "D&D The Book of Many Things" },
				{ name = "DD The Book of Many Things - Players", storeid = "WOTC5ETBOMT", displayname = "D&D The Book of Many Things - Players" },
				{ name = "DD Tomb of Annihilation - Players", storeid = "WOTC5ETOA", displayname = "D&D Tomb of Annihilation - Player" },
				{ name = "DD Volos Guide to Monsters", storeid = "WOTC5EVGM", displayname = "D&D Volo's Guide to Monsters" },
				{ name = "Volos Guide to Monsters Players", storeid = "WOTC5EVGM", displayname = "D&D Volo's Guide to Monsters - Player" },
				{ name = "Van Richten's Guide to Ravenloft", storeid = "WOTC5EVRGTR", displayname = "D&D Van Richten's Guide to Ravenloft" },
				{ name = "Van Riichten's Guide to Ravenloft - Players", storeid = "WOTC5EVRGTR", displayname = "D&D Van Richten's Guide to Ravenloft - Player" },
				{ name = "D&D Wayfinder's Guide to Eberron", storeid = "WOTC5EWGTE" },
				{ name = "DD Xanathar's Guide to Everything", storeid = "WOTC5EXGTE", displayname = "D&D Xanathar's Guide to Everything" },
				{ name = "DD Xanathar's Guide to Everything Players", storeid = "WOTC5EXGTE", displayname = "D&D Xanathar's Guide to Everything - Player" },
			},
		},
	},
};

-- Shown in Modifiers window
-- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
_tModifierWindowPresets =
{
	{
		sCategory = "attack",
		tPresets =
		{
			"ATT_OPP",
			"DEF_COVER",
			"",
			"DEF_SCOVER",
		},
	},
	{
		sCategory = "damage",
		tPresets = {
			"DMG_CRIT",
			"DMG_MAX",
			"",
			"DMG_HALF",
		}
	},
};
_tModifierExclusionSets =
{
	{ "DEF_COVER", "DEF_SCOVER" },
};
