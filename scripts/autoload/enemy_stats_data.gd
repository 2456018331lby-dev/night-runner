class_name EnemyStatsData
extends Resource

## 敌人数值资源：每个 kind 一张 Dictionary 表，字段 snake_case。
##
## 这是敌人平衡数值的单一事实来源（数据本体），由 EnemyStats autoload 加载。
## 在 Inspector 里直接编辑对应 .tres，或改 data/enemy_stats.tres 文本。
## 字段含义与各 enemy 脚本里的调参常量一一对应；max_hp / points_award 为 int，其余为 float。
## 纯演出常量（AFTERIMAGE_*、PLATFORM_* 布局）不进这里，仍留在各 enemy 脚本。

@export var runner: Dictionary = {}
@export var suppressor: Dictionary = {}
@export var bastion: Dictionary = {}
@export var phantom: Dictionary = {}
@export var stalker: Dictionary = {}
@export var bolt: Dictionary = {}


## 取某 kind 的表；未知 kind 返回空 Dictionary。
func get_kind_stats(kind: String) -> Dictionary:
	var value: Variant = get(kind)
	return (value as Dictionary) if value is Dictionary else {}


## 收录的 kind 列表。
func get_kinds() -> Array:
	return ["runner", "suppressor", "bastion", "phantom", "stalker", "bolt"]
