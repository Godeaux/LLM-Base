import { TowerState, AttackConfig } from "./types.js";
import { getUpgradeCost, getAttackUpgradeCost } from "./tower.js";

type UpgradeCallback = (upgradeType: string, index?: number) => void;

let upgradeCallback: UpgradeCallback | null = null;
let lastRenderedState = "";

export function initUI(callback: UpgradeCallback): void {
  upgradeCallback = callback;
}

export function updateUI(state: TowerState): void {
  const stateKey = `${state.wave}-${state.kills}-${state.gold}-${state.level}-${state.health}-${state.attacks.map((a) => a.level).join(",")}`;
  if (stateKey === lastRenderedState) return;
  lastRenderedState = stateKey;

  const waveEl = document.getElementById("wave-num");
  const killEl = document.getElementById("kill-count");
  const goldEl = document.getElementById("gold-count");
  const levelEl = document.getElementById("tower-level");
  const healthFill = document.getElementById("tower-health-fill");
  const upgradesEl = document.getElementById("upgrades");

  if (waveEl) waveEl.textContent = String(state.wave);
  if (killEl) killEl.textContent = String(state.kills);
  if (goldEl) goldEl.textContent = String(state.gold);
  if (levelEl) levelEl.textContent = String(state.level);
  if (healthFill) {
    const pct = Math.max(0, (state.health / state.maxHealth) * 100);
    healthFill.style.width = `${pct}%`;
  }

  if (upgradesEl) {
    upgradesEl.innerHTML = "";

    // Tower upgrade button
    const towerCost = getUpgradeCost(state.level);
    const towerBtn = makeButton(
      `Tower Lv.${state.level + 1}`,
      `${towerCost}g`,
      state.gold >= towerCost,
      () => upgradeCallback?.("tower"),
    );
    upgradesEl.appendChild(towerBtn);

    // Attack upgrade buttons
    state.attacks.forEach((attack: AttackConfig, idx: number) => {
      const cost = getAttackUpgradeCost(attack.level);
      const btn = makeButton(
        `${attack.name} Lv.${attack.level + 1}`,
        `${cost}g`,
        state.gold >= cost,
        () => upgradeCallback?.("attack", idx),
      );
      upgradesEl.appendChild(btn);
    });
  }
}

function makeButton(
  name: string,
  cost: string,
  enabled: boolean,
  onClick: () => void,
): HTMLDivElement {
  const btn = document.createElement("div");
  btn.className = `upgrade-btn${enabled ? "" : " disabled"}`;
  btn.innerHTML = `<div class="name">${name}</div><div class="cost">${cost}</div>`;
  if (enabled) {
    btn.addEventListener("click", onClick);
  }
  return btn;
}

export function showWaveBanner(wave: number): void {
  const banner = document.getElementById("wave-banner");
  if (!banner) return;
  banner.textContent = `Wave ${wave}`;
  banner.classList.add("visible");
  setTimeout(() => banner.classList.remove("visible"), 2000);
}
