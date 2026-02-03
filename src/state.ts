import * as CANNON from "cannon-es";
import { TOWER, FIREBALL, ARROW, ARCANE, LIGHTNING, WAVE } from "./config.js";

export interface GameState {
  tower: TowerState;
  enemies: EnemyState[];
  projectiles: ProjectileState[];
  lightningArcs: LightningArc[];
  minions: MinionState[];
  wave: WaveState;
  time: number;
  deltaTime: number;
}

/**
 * Per-attack runtime state. fireRate + fireTimer live here so upgrades
 * can mutate them independently of the base config values.
 */
export interface AttackRuntimeState {
  fireRate: number;     // shots (or zaps) per second — mutable by upgrades
  fireTimer: number;    // countdown to next shot
  enabled: boolean;     // debug toggle
}

export interface TowerState {
  hp: number;
  maxHp: number;
  position: CANNON.Vec3;
  attacks: Record<AttackType, AttackRuntimeState>;
}

export interface EnemyState {
  id: number;
  body: CANNON.Body;
  hp: number;
  maxHp: number;
  speed: number;
  damage: number; // damage per second to tower
  alive: boolean;
  stunTimer: number; // seconds remaining of stun (0 = not stunned)
  // leg animation
  legPhase: number;
  meshGroup: null; // set by renderer
  type: "walker";
}

export type ProjectileType = "fireball" | "arrow" | "arcane";
export type AttackType = ProjectileType | "lightning" | "minions";

export type MinionAIState = "roaming" | "windup" | "bonk" | "cooldown" | "recovery";

export interface MinionState {
  id: number;
  body: CANNON.Body;
  aiState: MinionAIState;
  stateTimer: number;       // countdown for current AI state
  targetId: number | null;  // enemy being attacked
  legPhase: number;         // walk animation
  meshGroup: null;          // set by renderer
}

/** Visual-only lightning arc that fades out over time. */
export interface LightningArc {
  points: CANNON.Vec3[]; // chain of positions: tower -> enemy1 -> enemy2 -> ...
  age: number;
  maxAge: number;
}

export interface ProjectileState {
  id: number;
  body: CANNON.Body;
  alive: boolean;
  damage: number;
  knockback: number;
  age: number;
  maxAge: number;
  type: ProjectileType;
  splashRadius: number; // 0 = no splash
  splashForce: number;
  targetId: number | null; // homing target (arcane bolt)
}

export interface WaveState {
  number: number;
  enemiesRemaining: number;
  enemiesSpawned: number;
  enemiesTotal: number;
  spawnTimer: number;
  spawnInterval: number;
  reprieveTimer: number;
  inReprieve: boolean;
  kills: number;
}

let nextId = 1;

export function nextEntityId(): number {
  return nextId++;
}

export function createInitialState(): GameState {
  return {
    tower: {
      hp: TOWER.hp,
      maxHp: TOWER.maxHp,
      position: new CANNON.Vec3(0, 0, 0),
      attacks: {
        fireball:  { fireRate: FIREBALL.fireRate,  fireTimer: 0,   enabled: true },
        arrow:     { fireRate: ARROW.fireRate,     fireTimer: 0.3, enabled: true },
        arcane:    { fireRate: ARCANE.fireRate,     fireTimer: 0.6, enabled: true },
        lightning: { fireRate: LIGHTNING.fireRate,  fireTimer: 0.9, enabled: true },
        minions:   { fireRate: 0,                   fireTimer: 0,   enabled: true },
      },
    },
    enemies: [],
    projectiles: [],
    lightningArcs: [],
    minions: [],
    wave: {
      number: 1,
      enemiesRemaining: 0,
      enemiesSpawned: 0,
      enemiesTotal: WAVE.baseEnemies,
      spawnTimer: 0,
      spawnInterval: WAVE.spawnInterval,
      reprieveTimer: 0,
      inReprieve: false,
      kills: 0,
    },
    time: 0,
    deltaTime: 0,
  };
}
