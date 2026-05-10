class_name RunCatalog
extends RefCounted

const RUNNER_SCENE := preload("res://scenes/actors/enemy_runner.tscn")
const SUPPRESSOR_SCENE := preload("res://scenes/actors/enemy_suppressor.tscn")

const OPERATIONS := [
	{
		"id": "blitz_pursuit",
		"title": "Blitz Pursuit",
		"subtitle": "High-speed assault extraction",
		"mode_label": "Chase / Combo Route",
		"summary": "A neon sprint built around boost chains, collapsing lanes and aggressive combo play.",
		"brief": "Kick the alarmed convoy off-balance, grab the cores and punch through the extraction corridor before the kill-team closes the grid.",
		"intel": "Best for players who want velocity, aggression and constant forward pressure.",
		"theme": {
			"primary": Color("46d2ff"),
			"secondary": Color("ff7e43"),
			"backdrop": Color("08111f"),
			"moon": Color("ffd166"),
		},
		"unlocks": ["ghost_circuit"],
		"locked_text": "Available from the start.",
		"spawn_position": Vector2(148, 590),
		"extraction_position": Vector2(2244, 118),
		"platforms": [
			{"position": Vector2(920, 666), "size": Vector2(2300, 64), "color": Color("18233a")},
			{"position": Vector2(630, 426), "size": Vector2(300, 30), "color": Color("20314d")},
			{"position": Vector2(1060, 344), "size": Vector2(300, 30), "color": Color("1c2b46")},
			{"position": Vector2(1458, 252), "size": Vector2(286, 30), "color": Color("1c2a44")},
			{"position": Vector2(1782, 162), "size": Vector2(254, 30), "color": Color("20314d")},
			{"position": Vector2(2066, 198), "size": Vector2(270, 30), "color": Color("1f2f4a")},
			{"position": Vector2(2250, 132), "size": Vector2(180, 30), "color": Color("233654")},
		],
		"encounters": [
			{"scene": RUNNER_SCENE, "position": Vector2(520, 348)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(874, 184)},
			{"scene": RUNNER_SCENE, "position": Vector2(1180, 214)},
			{"scene": RUNNER_SCENE, "position": Vector2(1380, 214)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1700, 88)},
			{"scene": RUNNER_SCENE, "position": Vector2(1870, 124)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(2108, 126)},
		],
		"data_cores": [
			Vector2(690, 364),
			Vector2(1120, 276),
			Vector2(1502, 180),
			Vector2(1800, 92),
			Vector2(2100, 124),
		],
		"boost_pads": [
			{"position": Vector2(494, 618), "boost_velocity": Vector2(420.0, -520.0)},
			{"position": Vector2(1126, 294), "boost_velocity": Vector2(350.0, -480.0)},
			{"position": Vector2(1714, 112), "boost_velocity": Vector2(310.0, -390.0)},
			{"position": Vector2(1966, 148), "boost_velocity": Vector2(290.0, -360.0)},
		],
		"timeline_events": [
			{
				"time": 16.0,
				"toast": "Rear pursuit drones are burning into your lane.",
				"spawn": [
					{"scene": RUNNER_SCENE, "position": Vector2(936, 350)},
					{"scene": SUPPRESSOR_SCENE, "position": Vector2(1510, 188)},
				],
			},
		],
		"core_events": [
			{
				"count": 2,
				"toast": "Momentum spike. The convoy is splitting its shield line.",
				"spawn": [
					{"scene": RUNNER_SCENE, "position": Vector2(1640, 124)},
				],
			},
		],
		"completion_spawns": [
			{"scene": RUNNER_SCENE, "position": Vector2(868, 364)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1512, 188)},
			{"scene": RUNNER_SCENE, "position": Vector2(1880, 124)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(2208, 126)},
		],
		"objective_intro": "Blitz through the convoy rooftops, secure all 5 data cores and break out alive.",
		"objective_complete": "Extraction corridor is live. Run the gauntlet or keep farming the clean-up team.",
		"intro_toast": "Route is hot. Chain boost pads to stay ahead of the response time.",
		"block_toast": "Extraction lane is still sealed. You need every core.",
		"completion_toast": "Alarm trip confirmed. The convoy is dumping reinforcements into the lane.",
		"base_modifiers": {
			"health_bonus": 0,
			"speed_multiplier": 1.06,
			"dash_multiplier": 1.08,
			"jump_multiplier": 1.0,
			"boost_multiplier": 1.08,
			"score_multiplier": 1.0,
			"combo_window_multiplier": 1.1,
			"finish_bonus_multiplier": 1.0,
			"silent_bonus": 0,
		},
		"directive_pool": [
			{
				"id": "surge_injection",
				"name": "Surge Injection",
				"summary": "Overclocks movement and rewards relentless pace.",
				"modifiers": {
					"speed_multiplier": 1.12,
					"dash_multiplier": 1.14,
					"score_multiplier": 1.05,
				},
			},
			{
				"id": "knife_party",
				"name": "Knife Party",
				"summary": "Longer combo window and stronger melee launches.",
				"modifiers": {
					"combo_window_multiplier": 1.25,
					"attack_force_multiplier": 1.12,
				},
			},
			{
				"id": "redline_thrusters",
				"name": "Redline Thrusters",
				"summary": "Boost pads hit harder, but the score clock pushes faster.",
				"modifiers": {
					"boost_multiplier": 1.2,
					"finish_bonus_multiplier": 0.94,
				},
			},
		],
		"secondary_objective": {
			"id": "shock_exit",
			"name": "Shock Exit",
			"type": "time_limit",
			"description": "Extract within 00:45 to cash the pursuit bonus.",
			"target_time": 45.0,
			"reward_score": 320,
		},
		"extraction_bonus": {
			"label": "Pursuit Bonus",
			"base_bounty": 70,
			"step_bounty": 25,
		},
	},
	{
		"id": "ghost_circuit",
		"title": "Ghost Circuit",
		"subtitle": "Low-profile relay theft",
		"mode_label": "Stealth Pressure Route",
		"summary": "A denser vertical route where suppressors control angles and perfect execution pays a silent bonus.",
		"brief": "Slip through a live relay garden, pull the black-box cores and leave before the sniper lattice triangulates your route.",
		"intel": "Built around route reading, suppressor angles and reward for low-damage clears.",
		"theme": {
			"primary": Color("9ef6d2"),
			"secondary": Color("7aa8ff"),
			"backdrop": Color("08161a"),
			"moon": Color("9fe7ff"),
		},
		"unlocks": ["overdrive_protocol"],
		"locked_text": "Clear Blitz Pursuit to unlock.",
		"spawn_position": Vector2(140, 596),
		"extraction_position": Vector2(2246, 88),
		"platforms": [
			{"position": Vector2(930, 666), "size": Vector2(2280, 64), "color": Color("15252c")},
			{"position": Vector2(500, 516), "size": Vector2(240, 30), "color": Color("1d3640")},
			{"position": Vector2(778, 412), "size": Vector2(210, 28), "color": Color("244653")},
			{"position": Vector2(1062, 324), "size": Vector2(248, 28), "color": Color("203947")},
			{"position": Vector2(1362, 244), "size": Vector2(216, 28), "color": Color("1b3140")},
			{"position": Vector2(1640, 168), "size": Vector2(210, 28), "color": Color("1f3745")},
			{"position": Vector2(1944, 116), "size": Vector2(220, 28), "color": Color("244653")},
			{"position": Vector2(2238, 100), "size": Vector2(150, 28), "color": Color("284b5d")},
		],
		"encounters": [
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(520, 458)},
			{"scene": RUNNER_SCENE, "position": Vector2(786, 366)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1098, 282)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1416, 204)},
			{"scene": RUNNER_SCENE, "position": Vector2(1680, 124)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1996, 74)},
		],
		"data_cores": [
			Vector2(506, 470),
			Vector2(800, 366),
			Vector2(1086, 278),
			Vector2(1670, 122),
			Vector2(1990, 72),
		],
		"boost_pads": [
			{"position": Vector2(356, 626), "boost_velocity": Vector2(300.0, -420.0)},
			{"position": Vector2(928, 374), "boost_velocity": Vector2(260.0, -340.0)},
			{"position": Vector2(1728, 126), "boost_velocity": Vector2(220.0, -260.0)},
		],
		"timeline_events": [
			{
				"time": 18.0,
				"toast": "Relay mirrors are pivoting. Expect new suppressor sight-lines.",
				"spawn": [
					{"scene": SUPPRESSOR_SCENE, "position": Vector2(1500, 202)},
				],
			},
		],
		"core_events": [
			{
				"count": 1,
				"toast": "First vault cracked. The relay net is waking up.",
				"spawn": [
					{"scene": RUNNER_SCENE, "position": Vector2(948, 280)},
				],
			},
			{
				"count": 3,
				"toast": "You are no longer invisible. Exit routes are now contested.",
				"spawn": [
					{"scene": SUPPRESSOR_SCENE, "position": Vector2(1860, 76)},
				],
			},
		],
		"completion_spawns": [
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1210, 282)},
			{"scene": RUNNER_SCENE, "position": Vector2(1764, 126)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(2130, 74)},
		],
		"objective_intro": "Pick apart the relay garden, stay clean and exfil with every black-box core.",
		"objective_complete": "Your ghost window is closing. Slip out now or risk a full sniper lock.",
		"intro_toast": "This route is quieter and meaner. Read the suppressor angles before you leap.",
		"block_toast": "The relay still has black boxes online. Clear the route first.",
		"completion_toast": "Relay net compromised. The circuit is broadcasting your position.",
		"base_modifiers": {
			"health_bonus": -1,
			"speed_multiplier": 0.98,
			"dash_multiplier": 1.0,
			"jump_multiplier": 1.02,
			"boost_multiplier": 0.92,
			"score_multiplier": 1.08,
			"combo_window_multiplier": 0.96,
			"finish_bonus_multiplier": 1.06,
			"silent_bonus": 260,
		},
		"directive_pool": [
			{
				"id": "ghost_ink",
				"name": "Ghost Ink",
				"summary": "Rewards no-hit clears with a larger silent bonus.",
				"modifiers": {
					"silent_bonus": 220,
					"score_multiplier": 1.04,
				},
			},
			{
				"id": "thin_wire",
				"name": "Thin Wire",
				"summary": "Higher jump control, but you enter the mission at reduced health.",
				"modifiers": {
					"jump_multiplier": 1.08,
					"health_bonus": -1,
					"score_multiplier": 1.1,
				},
			},
			{
				"id": "blank_signal",
				"name": "Blank Signal",
				"summary": "Suppressor pressure rises, but finish bonus climbs with it.",
				"modifiers": {
					"finish_bonus_multiplier": 1.18,
				},
			},
		],
		"secondary_objective": {
			"id": "ghost_clause",
			"name": "Ghost Clause",
			"type": "no_hit",
			"description": "Extract without taking damage to secure the silent bonus.",
			"reward_score": 420,
		},
		"extraction_bonus": {
			"label": "Relay Harvest",
			"base_bounty": 90,
			"step_bounty": 35,
		},
	},
	{
		"id": "overdrive_protocol",
		"title": "Overdrive Protocol",
		"subtitle": "Adaptive hunter operation",
		"mode_label": "Rogue Pursuit Route",
		"summary": "A mixed route with a random combat directive every run, pushing repeatability and creative routing.",
		"brief": "Take a black-budget kill switch through a reconfiguring rooftop sector, adapt to the directive draw and decide whether to cash out or overstay for score.",
		"intel": "This is the replayable mode: mixed enemy lanes, more route branches and a stronger run modifier system.",
		"theme": {
			"primary": Color("ff5f6d"),
			"secondary": Color("ffc371"),
			"backdrop": Color("140b17"),
			"moon": Color("ffb86c"),
		},
		"unlocks": [],
		"locked_text": "Clear Ghost Circuit to unlock.",
		"spawn_position": Vector2(144, 590),
		"extraction_position": Vector2(2330, 118),
		"platforms": [
			{"position": Vector2(970, 666), "size": Vector2(2360, 64), "color": Color("231b2f")},
			{"position": Vector2(612, 468), "size": Vector2(220, 30), "color": Color("302441")},
			{"position": Vector2(872, 380), "size": Vector2(240, 28), "color": Color("352949")},
			{"position": Vector2(1178, 294), "size": Vector2(236, 28), "color": Color("2b213a")},
			{"position": Vector2(1460, 214), "size": Vector2(230, 28), "color": Color("332745")},
			{"position": Vector2(1718, 300), "size": Vector2(188, 26), "color": Color("3b2d50")},
			{"position": Vector2(1912, 196), "size": Vector2(210, 28), "color": Color("332745")},
			{"position": Vector2(2186, 132), "size": Vector2(240, 28), "color": Color("3f3156")},
		],
		"encounters": [
			{"scene": RUNNER_SCENE, "position": Vector2(500, 410)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(852, 334)},
			{"scene": RUNNER_SCENE, "position": Vector2(1190, 250)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1460, 170)},
			{"scene": RUNNER_SCENE, "position": Vector2(1736, 254)},
			{"scene": RUNNER_SCENE, "position": Vector2(1914, 152)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(2204, 90)},
		],
		"data_cores": [
			Vector2(620, 420),
			Vector2(904, 336),
			Vector2(1200, 248),
			Vector2(1740, 254),
			Vector2(2188, 90),
		],
		"boost_pads": [
			{"position": Vector2(396, 626), "boost_velocity": Vector2(320.0, -430.0)},
			{"position": Vector2(982, 348), "boost_velocity": Vector2(290.0, -360.0)},
			{"position": Vector2(1564, 182), "boost_velocity": Vector2(250.0, -320.0)},
			{"position": Vector2(2000, 154), "boost_velocity": Vector2(240.0, -300.0)},
		],
		"timeline_events": [
			{
				"time": 14.0,
				"toast": "Adaptive hunters have a live trace. The sector is rebalancing against you.",
				"spawn": [
					{"scene": RUNNER_SCENE, "position": Vector2(1328, 250)},
					{"scene": SUPPRESSOR_SCENE, "position": Vector2(1828, 152)},
				],
			},
			{
				"time": 28.0,
				"toast": "Overdrive spike. Any greed from here on is a deliberate choice.",
				"spawn": [
					{"scene": RUNNER_SCENE, "position": Vector2(2104, 92)},
				],
			},
		],
		"core_events": [
			{
				"count": 2,
				"toast": "The protocol is changing shape. Expect a mixed wave ahead.",
				"spawn": [
					{"scene": SUPPRESSOR_SCENE, "position": Vector2(1580, 170)},
				],
			},
		],
		"completion_spawns": [
			{"scene": RUNNER_SCENE, "position": Vector2(992, 338)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(1638, 170)},
			{"scene": RUNNER_SCENE, "position": Vector2(1960, 150)},
			{"scene": SUPPRESSOR_SCENE, "position": Vector2(2268, 90)},
		],
		"objective_intro": "Survive the adaptive sector, seize every kill-switch core and decide how greedy you want to be.",
		"objective_complete": "Exit point is unlocked. Cash out now or stay in the overdrive pocket for score.",
		"intro_toast": "This mode draws a fresh directive every run. Build your route around it immediately.",
		"block_toast": "Kill-switch matrix incomplete. Finish the sweep before you run.",
		"completion_toast": "Protocol breach confirmed. The sector is now fully hostile.",
		"base_modifiers": {
			"health_bonus": 0,
			"speed_multiplier": 1.0,
			"dash_multiplier": 1.04,
			"jump_multiplier": 1.0,
			"boost_multiplier": 1.0,
			"score_multiplier": 1.12,
			"combo_window_multiplier": 1.0,
			"finish_bonus_multiplier": 1.12,
			"silent_bonus": 0,
		},
		"directive_pool": [
			{
				"id": "glass_reactor",
				"name": "Glass Reactor",
				"summary": "Higher score multiplier, lower max health.",
				"modifiers": {
					"health_bonus": -1,
					"score_multiplier": 1.18,
				},
			},
			{
				"id": "warpath",
				"name": "Warpath",
				"summary": "Stronger attacks and longer combo windows reward aggression.",
				"modifiers": {
					"attack_force_multiplier": 1.16,
					"combo_window_multiplier": 1.18,
				},
			},
			{
				"id": "phantom_step",
				"name": "Phantom Step",
				"summary": "Faster movement and cleaner landings tighten the route.",
				"modifiers": {
					"speed_multiplier": 1.1,
					"jump_multiplier": 1.06,
				},
			},
			{
				"id": "panic_dividend",
				"name": "Panic Dividend",
				"summary": "Extraction bonus surges if you survive the late game.",
				"modifiers": {
					"finish_bonus_multiplier": 1.22,
				},
			},
		],
		"secondary_objective": {
			"id": "dividend_hunter",
			"name": "Dividend Hunter",
			"type": "score_threshold",
			"description": "Reach 2600 score before extraction to trigger the dividend payout.",
			"target_score": 2600,
			"reward_score": 460,
		},
		"extraction_bonus": {
			"label": "Dividend Chain",
			"base_bounty": 110,
			"step_bounty": 45,
		},
	},
]


static func get_operations() -> Array[Dictionary]:
	var operations: Array[Dictionary] = []
	for operation in OPERATIONS:
		operations.append(operation.duplicate(true))
	return operations


static func get_operation(operation_id: String) -> Dictionary:
	for operation in OPERATIONS:
		if String(operation.get("id", "")) == operation_id:
			return operation.duplicate(true)
	return {}


static func get_first_operation_id() -> String:
	if OPERATIONS.is_empty():
		return ""
	return String(OPERATIONS[0].get("id", ""))
