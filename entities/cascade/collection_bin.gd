class_name CollectionBin
extends Area2D
## Collects balls at the bottom of the machine and awards currency.

@export var score_multiplier: float = 1.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2


func _on_body_entered(body: Node) -> void:
	if body is CascadeBall:
		var ball := body as CascadeBall
		var score: int = roundi(score_multiplier)
		if ball.data:
			score = roundi(ball.data.score_multiplier * score_multiplier)
		EventBus.ball_collected.emit(ball.global_position, score)
		EventBus.currency_earned.emit(score, "cascade")
		VisualJuice.float_text(get_parent(), "+" + str(score), ball.global_position)
		var pool := _find_pool()
		if pool:
			pool.release(ball)


func _find_pool() -> ObjectPool:
	var spawner: Node = get_tree().get_first_node_in_group("ball_spawner")
	if spawner and spawner.has_method("get_pool"):
		return spawner.get_pool() as ObjectPool
	return null
