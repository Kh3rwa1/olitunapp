import { readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const percentile = (values, fraction) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(fraction * sorted.length) - 1];
};

/** Evaluate real profile-mode engine samples, not a debug stopwatch. */
export function evaluateExperience(
  report,
  { minFrames = 120, maxOverBudgetPercent = 1 } = {},
) {
  const data = report?.experience;
  if (!Number.isInteger(minFrames) || minFrames < 120) {
    throw new Error("At least 120 frames are required.");
  }
  if (
    !Number.isFinite(maxOverBudgetPercent) ||
    maxOverBudgetPercent < 0 ||
    maxOverBudgetPercent > 100
  ) {
    throw new Error("Invalid over-budget percentage.");
  }
  if (data?.mode !== "profile") throw new Error("Profile-mode trace required.");
  for (const name of ["commit", "device", "fixture"]) {
    if (typeof data[name] !== "string" || !data[name].trim()) {
      throw new Error(`Missing trace provenance: ${name}.`);
    }
  }
  if (
    !Number.isFinite(data.refreshHz) ||
    data.refreshHz < 1 ||
    data.refreshHz > 1000
  ) {
    throw new Error("A valid measured display refresh rate is required.");
  }
  if (!Array.isArray(data.frames) || data.frames.length < minFrames) {
    throw new Error(`Insufficient engine samples: need ${minFrames} frames.`);
  }
  const build = [];
  const raster = [];
  for (const frame of data.frames) {
    for (const key of ["buildMicros", "rasterMicros"]) {
      if (!Number.isFinite(frame?.[key]) || frame[key] < 0) {
        throw new Error(`Invalid frame timing: ${key}.`);
      }
    }
    build.push(frame.buildMicros / 1000);
    raster.push(frame.rasterMicros / 1000);
  }
  const budgetMs = 1000 / data.refreshHz;
  // Build and raster are pipelined; do not add their durations together.
  const overBudgetFrames = build.filter(
    (value, index) => value > budgetMs || raster[index] > budgetMs,
  ).length;
  const overBudgetPercent = (100 * overBudgetFrames) / build.length;
  const buildP95Ms = percentile(build, 0.95);
  const rasterP95Ms = percentile(raster, 0.95);
  return {
    commit: data.commit,
    device: data.device,
    fixture: data.fixture,
    refreshHz: data.refreshHz,
    sampleCount: build.length,
    budgetMs,
    buildP95Ms,
    rasterP95Ms,
    overBudgetFrames,
    overBudgetPercent,
    maxOverBudgetPercent,
    passed:
      buildP95Ms <= budgetMs &&
      rasterP95Ms <= budgetMs &&
      overBudgetPercent <= maxOverBudgetPercent,
    caveat:
      "Engine phase-budget proxy; not measured display jank, startup, network latency, or whole-app certification.",
  };
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  try {
    const [input, output] = process.argv.slice(2);
    if (!input || !output)
      throw new Error(
        "Usage: node tool/experience_frame_budget.mjs <integration_response_data.json> <summary.json>",
      );
    const result = evaluateExperience(JSON.parse(readFileSync(input, "utf8")));
    writeFileSync(output, JSON.stringify(result, null, 2) + "\n");
    console.log(JSON.stringify(result, null, 2));
    process.exitCode = result.passed ? 0 : 1;
  } catch (error) {
    console.error(`Experience evaluation failed: ${error.message}`);
    process.exitCode = 2;
  }
}
