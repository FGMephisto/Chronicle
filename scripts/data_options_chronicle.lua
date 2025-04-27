-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	Options5E.registerOptions();
end

-- Adjusted
function registerOptions()
	OptionsManager.registerOptionData({
		sKey = "RMMT", bLocal = true,
		tCustom = { labelsres = "option_val_on|option_val_multi", values = "on|multi", baselabelres = "option_val_off", baseval = "off", default = "multi", },
	});

	OptionsManager.registerOptionData({
		sKey = "SHRR", sGroupRes = "option_header_game",
		tCustom = { labelsres = "option_val_on|option_val_friendly", values = "on|pc", baselabelres = "option_val_off", baseval = "off", default = "on", },
	});
	-- OptionsManager.registerOptionData({
		-- sKey = "GAVE", sGroupRes = "option_header_game",
		-- tCustom = { labelsres = "record_label_2024", values = "2024", baselabelres = "record_label_2014", baseval = "2014", default = "2024", },
	-- });

	OptionsManager.registerOptionData({
		sKey = "INIT", sGroupRes = "option_header_combat",
		tCustom = { labelsres = "option_val_on|option_val_group", values = "on|group", baselabelres = "option_val_off", baseval = "off", default = "group", },
	});
	OptionsManager.registerOptionData({
		sKey = "BARC", sGroupRes = "option_header_combat",
		tCustom = { labelsres = "option_val_tiered", values = "tiered", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "SHPC", sGroupRes = "option_header_combat",
		tCustom = { labelsres = "option_val_detailed|option_val_status", values = "detailed|status", baselabelres = "option_val_off", baseval = "off", default = "detailed", },
	});
	OptionsManager.registerOptionData({
		sKey = "SHNPC", sGroupRes = "option_header_combat",
		tCustom = { labelsres = "option_val_detailed|option_val_status", values = "detailed|status", baselabelres = "option_val_off", baseval = "off", default = "status", },
	});

	OptionsManager.registerOptionData({	sKey = "HRST", sGroupRes = "option_header_houserule", tCustom = { default = "on", }, });
	OptionsManager.registerOptionData({	sKey = "HRIR", sGroupRes = "option_header_houserule", });
	OptionsManager.registerOptionData({
		sKey = "NPCD", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_fixed", values = "fixed", baselabelres = "option_val_variable", baseval = "off", default = "off", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRNH", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_max|option_val_random", values = "max|random", baselabelres = "option_val_standard", baseval = "off", default = "off", },
	});
	OptionsManager.registerOptionData({	sKey = "HRMD", sGroupRes = "option_header_houserule", });
	OptionsManager.registerOptionData({
		sKey = "HRFC", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_fumbleandcrit|option_val_fumble|option_val_crit", values = "both|fumble|criticalhit", baselabelres = "option_val_off", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRAS", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_4|option_val_5|option_val_HRAS_prof|option_val_2", values = "4|5|prof|2", baselabelres = "option_val_3", baseval = "3", default = "3", },
	});
	-- OptionsManager.registerOptionData({
		-- sKey = "HREN", sGroupRes = "option_header_houserule",
		-- tCustom = { labelsres = "option_val_variant", values = "variant", baselabelres = "option_val_standard", baseval = "", default = "", },
	-- });
	OptionsManager.registerOptionData({
		sKey = "HRHV", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_HRHV_fast|option_val_HRHV_slow", values = "fast|slow", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRIS", sGroupRes = "option_header_houserule",
		tCustom = { labelsraw = "2|3|5", values = "2|3|5", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({	sKey = "HRBASTION", sGroupRes = "option_header_houserule", });
end
