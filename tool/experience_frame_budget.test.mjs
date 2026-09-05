import test from "node:test";
import assert from "node:assert/strict";
import { evaluateExperience } from "./experience_frame_budget.mjs";

const trace = (
  frames = Array.from({ length: 200 }, () => ({
    buildMicros: 4000,
    rasterMicros: 5000,
  })),
) => ({
  experience: {
    mode: "profile",
    commit: "test-fixture-only",
    device: "synthetic test",
    fixture: "validator unit test, not a device result",
    refreshHz: 60,
    frames,
  },
});

test("valid timings pass without adding pipelined phase durations", () => {
  const result = evaluateExperience(
    trace(
      Array.from({ length: 200 }, () => ({
        buildMicros: 12000,
        rasterMicros: 12000,
      })),
    ),
  );
  assert.equal(result.passed, true);
  assert.equal(result.sampleCount, 200);
  assert.equal(result.buildP95Ms, 12);
  assert.equal(result.rasterP95Ms, 12);
});

test("over-budget frames fail even with a healthy average", () => {
  const input = trace();
  input.experience.frames.splice(
    0,
    3,
    ...Array.from({ length: 3 }, () => ({
      buildMicros: 25000,
      rasterMicros: 3000,
    })),
  );
  const result = evaluateExperience(input);
  assert.equal(result.overBudgetPercent, 1.5);
  assert.equal(result.passed, false);
});

test("raster regressions count independently from build regressions", () => {
  const input = trace();
  input.experience.frames.forEach((frame) => {
    frame.rasterMicros = 25000;
  });
  const result = evaluateExperience(input);
  assert.equal(result.overBudgetFrames, 200);
  assert.equal(result.passed, false);
});

test("a 120Hz display uses its own frame budget", () => {
  const input = trace(
    Array.from({ length: 200 }, () => ({
      buildMicros: 10000,
      rasterMicros: 1000,
    })),
  );
  input.experience.refreshHz = 120;
  assert.equal(evaluateExperience(input).passed, false);
});

test("debug traces never masquerade as performance evidence", () => {
  const input = trace();
  input.experience.mode = "debug";
  assert.throws(() => evaluateExperience(input), /Profile-mode/);
});

test("missing provenance is rejected", () => {
  for (const key of ["commit", "device", "fixture"]) {
    const input = trace();
    delete input.experience[key];
    assert.throws(() => evaluateExperience(input), /provenance/);
  }
});

test("empty or undersampled captures fail closed", () => {
  assert.throws(() => evaluateExperience(trace([])), /Insufficient/);
  assert.throws(
    () =>
      evaluateExperience(
        trace(Array(119).fill({ buildMicros: 1, rasterMicros: 1 })),
      ),
    /Insufficient/,
  );
});

test("invalid and missing frame values are rejected rather than discarded", () => {
  for (const value of [undefined, null, -1, NaN, Infinity, "4000"]) {
    const input = trace();
    input.experience.frames[0].buildMicros = value;
    assert.throws(() => evaluateExperience(input), /Invalid frame/);
  }
});

test("unknown display rate is rejected", () => {
  for (const value of [0, NaN, null, "60"]) {
    const input = trace();
    input.experience.refreshHz = value;
    assert.throws(() => evaluateExperience(input), /refresh rate/);
  }
});

test("sample-size and percentage options are validated", () => {
  assert.throws(
    () => evaluateExperience(trace(), { minFrames: 0 }),
    /120 frames/,
  );
  assert.throws(
    () => evaluateExperience(trace(), { maxOverBudgetPercent: -1 }),
    /percentage/,
  );
});
