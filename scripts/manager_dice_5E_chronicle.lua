--
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tActorDiceSystemRules = {};
local _tActorSystemDefaults = {};
local _tActorTypeDefaults = {
	["beast"] = {
		{ diceskin = 269 },
		{ diceskin = 95 },
	},
	["undead"] = {
		{ diceskin = 260 },
		{ diceskin = 101 },
	},
};

function onInit()
	DiceRollManager.registerActorSupportDnD();
	DiceManager5E.registerActorTypeDefaults();
	DiceManager5E.registerActorSystemDefaults();
	DiceManager5E.registerActorSystemRules();

	DiceManager5E.registerActions();
end

function registerActions()
	DiceRollManager.registerDamageTypeMode("critical");

	DiceRollManager.registerDamageKey();
	-- DiceRollManager.registerDamageTypeKey("acid", "life");
	DiceRollManager.registerDamageTypeKey("cold", "frost");
	DiceRollManager.registerDamageTypeKey("fire", "fire");
	-- DiceRollManager.registerDamageTypeKey("force", "arcane");
	-- DiceRollManager.registerDamageTypeKey("lightning", "lightning");
	-- DiceRollManager.registerDamageTypeKey("necrotic", "shadow");
	DiceRollManager.registerDamageTypeKey("poison", "life");
	-- DiceRollManager.registerDamageTypeKey("psychic", "shadow");
	-- DiceRollManager.registerDamageTypeKey("radiant", "light");
	-- DiceRollManager.registerDamageTypeKey("thunder", "storm");

	DiceRollManager.registerDamageTypeKey("bludgeoning");
	DiceRollManager.registerDamageTypeKey("piercing");
	DiceRollManager.registerDamageTypeKey("slashing");

	-- DiceRollManager.registerDamageTypeKey("adamantine");
	-- DiceRollManager.registerDamageTypeKey("cold-forged iron");
	-- DiceRollManager.registerDamageTypeKey("silver");

	-- DiceRollManager.registerDamageTypeKey("magic");

	DiceRollManager.registerHealKey();
	DiceRollManager.registerHealTypeKey("health", "light");
	-- DiceRollManager.registerHealTypeKey("temp", "water");
end

function registerActorTypeDefaults()
	for k,v in pairs(_tActorTypeDefaults) do
		DiceRollManager.setDiceSkinDefaults(k, v);
	end
end
function registerActorSystemDefaults()
	for k,v in pairs(_tActorSystemDefaults) do
		DiceRollManager.setDiceSkinDefaults(k, v);
	end
end
function registerActorSystemRules()
	for k,v in pairs(_tActorDiceSystemRules) do
		DiceRollManager.setActorSystem(k, v);
	end
end