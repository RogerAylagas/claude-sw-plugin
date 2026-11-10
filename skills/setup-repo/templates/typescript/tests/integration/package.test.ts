// Integration smoke test. Placeholder: replace with tests that cross real boundaries.
import { readFile } from "node:fs/promises";

import { describe, expect, it } from "vitest";

describe("package metadata", () => {
  it("is readable from disk", async () => {
    const raw = await readFile(
      new URL("../../package.json", import.meta.url),
      "utf8",
    );
    const pkg = JSON.parse(raw) as { name: string };
    expect(pkg.name).toBe("{{PROJECT_NAME}}");
  });
});
