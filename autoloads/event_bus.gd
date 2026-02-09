extends Node
## Global signal hub for decoupled communication between systems.

# --- Mode-agnostic signals ---
signal currency_earned(amount: int, mode: String)
signal upgrade_purchased(upgrade_id: String, mode: String)
signal mode_changed(mode_name: String)

# --- Cascade signals ---
signal ball_collected(position: Vector2, score: int)
signal ball_stuck(ball: Node)

# --- Tumble signals ---
signal tower_collapsed(max_height: float)
signal block_placed(height: float)

# --- Orbit signals ---
signal bodies_merged(position: Vector2, new_mass: float)
signal orbit_stabilized(body_count: int)
signal prestige_triggered
