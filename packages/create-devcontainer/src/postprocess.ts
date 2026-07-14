import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { HostCapabilities } from "./detect.js";

/**
 * Post-process the generated devcontainer.json to match host capabilities.
 *
 * - If no NVIDIA GPU is present, remove "--gpus=all" from runArgs.
 * - If NVIDIA GPU is present and nvidia-container-toolkit feature exists,
 *   set enable: true.
 * - If no NVIDIA GPU and nvidia-container-toolkit feature exists,
 *   ensure enable: false.
 */
export function postProcessDevcontainer(
  targetDir: string,
  caps: HostCapabilities
): void {
  const jsonPath = join(targetDir, ".devcontainer", "devcontainer.json");
  if (!existsSync(jsonPath)) {
    return;
  }

  const raw = readFileSync(jsonPath, "utf-8");
  let config: Record<string, unknown>;
  try {
    config = JSON.parse(raw);
  } catch {
    // Not valid JSON, leave untouched
    return;
  }

  // 1. Adjust runArgs: remove --gpus=all if no GPU
  if (!caps.hasNvidiaGpu && Array.isArray(config.runArgs)) {
    config.runArgs = (config.runArgs as string[]).filter(
      (arg) => arg !== "--gpus=all"
    );
    // Remove empty runArgs array to keep JSON clean
    if ((config.runArgs as string[]).length === 0) {
      delete config.runArgs;
    }
  }

  // 2. Adjust nvidia-container-toolkit feature if present
  if (
    config.features &&
    typeof config.features === "object"
  ) {
    const features = config.features as Record<
      string,
      Record<string, unknown>
    >;

    for (const [key, value] of Object.entries(features)) {
      if (key.includes("nvidia-container-toolkit")) {
        features[key] = {
          ...value,
          enable: caps.hasNvidiaGpu,
        };
      }
    }
  }

  writeFileSync(jsonPath, JSON.stringify(config, null, "\t") + "\n", "utf-8");
}
