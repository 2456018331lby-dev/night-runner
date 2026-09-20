## RunOperationData — Single source of truth for run operation definitions
##
## This resource holds the complete catalog of run operations (Blitz Pursuit,
## Ghost Circuit, Overdrive Protocol), loaded by RunCatalog at runtime.
##
## Each operation dictionary contains:
## - Metadata: id, title, subtitle, mode_label, summary, brief, intel
## - Theme: colors for UI presentation
## - Unlock chain: unlocks array, locked_text
## - Layout: spawn_position, extraction_position, platforms, encounters, data_cores, boost_pads
## - Hazards: sweep walls, pulse beams, collapse zones with activation triggers
## - Events: timeline_events, core_events, completion_spawns
## - Narrative: objective texts, toasts, lane_signals
## - Phase setpiece: trigger condition, spawn wave, pressure text
## - Modifiers: base_modifiers, directive_pool
## - Objectives: secondary_objective, extraction_bonus
## - Cashout: tiers, events, loop, beacon (Overdrive only)
##
## All scene references (RUNNER_SCENE, SUPPRESSOR_SCENE, etc.) and constructors
## (Color(), Vector2()) are preserved as-is from the original OPERATIONS array.

class_name RunOperationData
extends Resource

@export var operations: Array[Dictionary] = []


## Returns a deep copy of the operations array for safe consumption
func get_operations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for operation in operations:
		result.append(operation.duplicate(true))
	return result
