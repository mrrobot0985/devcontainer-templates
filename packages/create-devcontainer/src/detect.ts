import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";

export interface HostCapabilities {
  hasNvidiaGpu: boolean;
}

/**
 * Detect host hardware capabilities relevant to devcontainer configuration.
 */
export function detectHostCapabilities(): HostCapabilities {
  return {
    hasNvidiaGpu: detectNvidiaGpu(),
  };
}

/**
 * Check if an NVIDIA GPU is present on the host.
 * Tries /dev/nvidia0 first (fast), then falls back to nvidia-smi.
 */
function detectNvidiaGpu(): boolean {
  if (existsSync("/dev/nvidia0")) {
    return true;
  }

  const result = spawnSync("nvidia-smi", ["--query-gpu=name", "--format=csv,noheader"], {
    stdio: "pipe",
    shell: false,
    encoding: "utf-8",
  });

  return result.status === 0 && typeof result.stdout === "string" && result.stdout.trim().length > 0;
}
