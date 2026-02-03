import { GameState, AttackType } from "../state.js";

let hpBar: HTMLDivElement | null = null;
let hpText: HTMLSpanElement | null = null;
let waveText: HTMLSpanElement | null = null;
let killText: HTMLSpanElement | null = null;
let gameOverOverlay: HTMLDivElement | null = null;

const ATTACK_LABELS: Record<AttackType, { label: string; color: string }> = {
  fireball: { label: "Fireball", color: "#ff6600" },
  arrow: { label: "Arrow", color: "#c8a82e" },
  arcane: { label: "Arcane Bolt", color: "#8844ff" },
  lightning: { label: "Lightning", color: "#88ccff" },
  minions: { label: "Minions", color: "#33aa66" },
};

export function createHUD(state: GameState): void {
  const container = document.createElement("div");
  container.id = "hud";
  container.innerHTML = `
    <div style="
      position: fixed; top: 16px; left: 16px;
      font-family: 'Courier New', monospace;
      color: #eee; font-size: 14px;
      background: rgba(0,0,0,0.6);
      padding: 12px 16px;
      border-radius: 8px;
      min-width: 180px;
      pointer-events: none;
      user-select: none;
    ">
      <div style="margin-bottom: 8px;">
        <span style="color: #aaa;">HP</span>
        <div style="
          background: #333; border-radius: 4px;
          height: 16px; margin-top: 4px;
          overflow: hidden;
        ">
          <div id="hp-bar" style="
            background: linear-gradient(90deg, #e74c3c, #e67e22);
            height: 100%; width: 100%;
            border-radius: 4px;
            transition: width 0.2s;
          "></div>
        </div>
        <span id="hp-text" style="font-size: 12px; color: #ccc;">10 / 10</span>
      </div>
      <div><span style="color: #aaa;">Wave:</span> <span id="wave-text">1</span></div>
      <div><span style="color: #aaa;">Kills:</span> <span id="kill-text">0</span></div>
    </div>
  `;
  document.body.appendChild(container);

  hpBar = document.getElementById("hp-bar") as HTMLDivElement;
  hpText = document.getElementById("hp-text") as HTMLSpanElement;
  waveText = document.getElementById("wave-text") as HTMLSpanElement;
  killText = document.getElementById("kill-text") as HTMLSpanElement;

  // --- Debug toggle panel ---
  const togglePanel = document.createElement("div");
  togglePanel.style.cssText = `
    position: fixed; top: 16px; right: 16px;
    font-family: 'Courier New', monospace;
    color: #eee; font-size: 13px;
    background: rgba(0,0,0,0.6);
    padding: 12px 16px;
    border-radius: 8px;
    user-select: none;
  `;
  togglePanel.innerHTML = `<div style="color: #888; margin-bottom: 8px; font-size: 11px;">ATTACK TOGGLES</div>`;

  for (const [type, info] of Object.entries(ATTACK_LABELS) as [AttackType, { label: string; color: string }][]) {
    const row = document.createElement("label");
    row.style.cssText = `display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 3px 0;`;

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = state.tower.attacks[type].enabled;
    checkbox.style.cssText = `accent-color: ${info.color}; cursor: pointer;`;
    checkbox.addEventListener("change", () => {
      state.tower.attacks[type].enabled = checkbox.checked;
    });

    const label = document.createElement("span");
    label.textContent = info.label;
    label.style.color = info.color;

    row.appendChild(checkbox);
    row.appendChild(label);
    togglePanel.appendChild(row);
  }

  document.body.appendChild(togglePanel);
}

export function updateHUD(state: GameState): void {
  if (!hpBar || !hpText || !waveText || !killText) return;

  const hpPct = Math.max(0, (state.tower.hp / state.tower.maxHp) * 100);
  hpBar.style.width = `${hpPct}%`;
  hpText.textContent = `${Math.ceil(Math.max(0, state.tower.hp))} / ${state.tower.maxHp}`;
  waveText.textContent = state.wave.inReprieve
    ? `${state.wave.number} (next wave...)`
    : `${state.wave.number}`;
  killText.textContent = `${state.wave.kills}`;

  // Game over
  if (state.tower.hp <= 0 && !gameOverOverlay) {
    gameOverOverlay = document.createElement("div");
    gameOverOverlay.innerHTML = `
      <div style="
        position: fixed; inset: 0;
        display: flex; align-items: center; justify-content: center;
        background: rgba(0,0,0,0.7);
        font-family: 'Courier New', monospace;
        color: #e74c3c; font-size: 48px;
        pointer-events: none;
        flex-direction: column;
        gap: 16px;
      ">
        <div>TOWER DESTROYED</div>
        <div style="font-size: 20px; color: #ccc;">
          Wave ${state.wave.number} | ${state.wave.kills} kills
        </div>
        <div style="font-size: 16px; color: #888;">Refresh to restart</div>
      </div>
    `;
    document.body.appendChild(gameOverOverlay);
  }
}
