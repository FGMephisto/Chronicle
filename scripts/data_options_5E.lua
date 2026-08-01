--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	Options5E.registerOptions();
end

function registerOptions()
	-- Per User
	OptionsManager.registerStandardOption("RMMT");

	-- Game
	OptionsManager.registerStandardOption("SHRR");
	OptionsManager.registerOptionData({
		sKey = "GAVE", sGroupRes = "option_header_game",
		tCustom = { labelsres = "record_label_2024", values = "2024", baselabelres = "record_label_2014", baseval = "2014", default = "2024", },
	});

	-- Combat
	OptionsManager.registerStandardOption("INIT");
	OptionsManager.registerStandardOption("BARC");
	OptionsManager.registerStandardOption("SHPC");
	OptionsManager.registerStandardOption("SHNPC");

	-- House Rules
	OptionsManager.registerStandardOption("HRFC");
	OptionsManager.registerStandardOption("HRIR");

	OptionsManager.registerStandardOption("HRST");
	OptionsManager.registerOptionData({
		sKey = "NPCD", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_fixed", values = "fixed", baselabelres = "option_val_variable", baseval = "off", default = "off", },
	});
	OptionsManager.registerStandardOption("HRNH");
	OptionsManager.registerOptionData({	sKey = "HRMD", sGroupRes = "option_header_houserule", });

	OptionsManager.registerOptionData({
		sKey = "HREX", sGroupRes = "option_header_houserule",
		tCustom = { labelsraw = "-1|-2|-3", values = "-1|-2|-3", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRHE", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_1|option_val_2|option_val_3|option_val_4|option_val_5", values = "1|2|3|4|5", baselabelres = "option_val_off", baseval = "off", default = "off", },
	});
	OptionsManager.registerOptionData({	sKey = "HRSE", sGroupRes = "option_header_houserule", });

	OptionsManager.registerOptionData({	sKey = "HRBASTION", sGroupRes = "option_header_houserule", });

	OptionsManager.registerOptionData({
		sKey = "HRAS", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_4|option_val_5|option_val_HRAS_prof|option_val_2", values = "4|5|prof|2", baselabelres = "option_val_3", baseval = "3", default = "3", },
	});
	OptionsManager.registerOptionData({
		sKey = "HREN", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_standard|option_val_variant", values = "standard|variant", baselabelres = "option_val_off", baseval = "off", default = "standard", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRFL", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_HRFL_passive|option_val_all", values = "passive|all", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRHV", sGroupRes = "option_header_houserule",
		tCustom = { labelsres = "option_val_HRHV_fast|option_val_HRHV_slow", values = "fast|slow", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
	OptionsManager.registerOptionData({
		sKey = "HRIS", sGroupRes = "option_header_houserule",
		tCustom = { labelsraw = "2|3|5", values = "2|3|5", baselabelres = "option_val_standard", baseval = "", default = "", },
	});
end
