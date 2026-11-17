class_name MissionRank
extends RefCounted
# Zero-style mission score: 100 points max, split between clear time, damage
# taken, deaths and enemies destroyed. Pure logic so it can be unit-tested.

const PAR_TIME := 420.0
const TIME_LIMIT := 900.0

static func score(clear_time: float, damage_taken: int, deaths: int, kills: int, total_enemies: int) -> int:
	var time_part := 30.0 * clampf((TIME_LIMIT - clear_time) / (TIME_LIMIT - PAR_TIME), 0.0, 1.0)
	var damage_part := 30.0 * clampf(1.0 - damage_taken / 300.0, 0.0, 1.0)
	var death_part := maxf(0.0, 20.0 - deaths * 10.0)
	var kill_part := 20.0 * (float(kills) / maxf(1.0, total_enemies))
	return int(round(time_part + damage_part + death_part + kill_part))

static func rank(points: int) -> String:
	if points >= 95: return "S"
	if points >= 80: return "A"
	if points >= 60: return "B"
	if points >= 40: return "C"
	return "D"
