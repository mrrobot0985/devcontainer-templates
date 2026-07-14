import { describe, expect, it } from "vitest";
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { postProcessDevcontainer } from "../src/postprocess.js";

function createFixture(
  tmp: string,
  content: Record<string, unknown>
): void {
  const dir = join(tmp, ".devcontainer");
  mkdirSync(dir, { recursive: true });
  writeFileSync(
    join(dir, "devcontainer.json"),
    JSON.stringify(content, null, "\t") + "\n"
  );
}

describe("postProcessDevcontainer", () => {
  it("removes --gpus=all when no GPU is present", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    createFixture(tmp, {
      name: "Test",
      image: "ubuntu",
      runArgs: ["--add-host=host.docker.internal:host-gateway", "--gpus=all"],
    });

    postProcessDevcontainer(tmp, { hasNvidiaGpu: false });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    );
    expect(result.runArgs).toEqual([
      "--add-host=host.docker.internal:host-gateway",
    ]);
  });

  it("removes empty runArgs entirely when no GPU is present", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    createFixture(tmp, {
      name: "Test",
      image: "ubuntu",
      runArgs: ["--gpus=all"],
    });

    postProcessDevcontainer(tmp, { hasNvidiaGpu: false });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    );
    expect(result.runArgs).toBeUndefined();
  });

  it("keeps --gpus=all when GPU is present", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    createFixture(tmp, {
      name: "Test",
      image: "ubuntu",
      runArgs: ["--gpus=all"],
    });

    postProcessDevcontainer(tmp, { hasNvidiaGpu: true });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    );
    expect(result.runArgs).toEqual(["--gpus=all"]);
  });

  it("enables nvidia-container-toolkit when GPU is present", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    createFixture(tmp, {
      name: "Test",
      image: "ubuntu",
      features: {
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0":
          {
            enable: false,
            defaultRuntime: false,
          },
      },
    });

    postProcessDevcontainer(tmp, { hasNvidiaGpu: true });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    );
    expect(
      result.features[
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0"
      ].enable
    ).toBe(true);
  });

  it("disables nvidia-container-toolkit when no GPU is present", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    createFixture(tmp, {
      name: "Test",
      image: "ubuntu",
      features: {
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0":
          {
            enable: true,
            defaultRuntime: true,
          },
      },
    });

    postProcessDevcontainer(tmp, { hasNvidiaGpu: false });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    );
    expect(
      result.features[
        "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0"
      ].enable
    ).toBe(false);
  });
});
