import * as THREE from "three";
import * as CANNON from "cannon-es";

export interface Enemy {
  id: number;
  mesh: THREE.Group;
  body: CANNON.Body;
  health: number;
  maxHealth: number;
  speed: number;
  damage: number;
  reward: number;
  type: EnemyType;
  healthBar: THREE.Sprite;
  alive: boolean;
  stunTimer: number;
  burnTimer: number;
  burnDamage: number;
  slowFactor: number;
  slowTimer: number;
}

export type EnemyType = "basic" | "fast" | "tank" | "flying" | "swarm" | "shielded" | "boss";

export interface EnemyConfig {
  health: number;
  speed: number;
  damage: number;
  reward: number;
  color: number;
  scale: number;
  meshBuilder: (config: EnemyConfig) => THREE.Group;
}

export type AttackType = "lightning" | "fireball" | "blizzard" | "laser" | "meteor" | "vortex";

export interface AttackConfig {
  name: string;
  type: AttackType;
  damage: number;
  cooldown: number;
  range: number;
  color: number;
  description: string;
  level: number;
}

export interface TowerState {
  level: number;
  health: number;
  maxHealth: number;
  attacks: AttackConfig[];
  activeAttackIndex: number;
  attackTimers: number[];
  gold: number;
  kills: number;
  wave: number;
  waveTimer: number;
  waveActive: boolean;
  enemiesRemaining: number;
  autoUpgrade: boolean;
}

export interface Projectile {
  mesh: THREE.Object3D;
  target: Enemy | null;
  position: THREE.Vector3;
  velocity: THREE.Vector3;
  damage: number;
  attackType: AttackType;
  lifetime: number;
  chainTargets?: Enemy[];
  aoeRadius?: number;
}

export interface ParticleSystem {
  points: THREE.Points;
  velocities: Float32Array;
  lifetimes: Float32Array;
  maxLifetimes: Float32Array;
  count: number;
  elapsed: number;
  duration: number;
}
