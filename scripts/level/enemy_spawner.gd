class_name EnemySpawner
extends Node2D
const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
@export var role := SectorEnemy.Role.SCRAPPER
func spawn() -> SectorEnemy:
	var enemy := ENEMY.instantiate() as SectorEnemy; get_parent().add_child(enemy); enemy.global_position = global_position; enemy.role = role; return enemy
