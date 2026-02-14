# ElasticBalls2D Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Julia package that simulates exact event-driven 2D elastic collisions among many balls and visualizes motion with Makie.

**Architecture:** Implement core types and deterministic event scheduling first, then analytic collision math, then simulation loop, then visualization layer. Keep queue correctness via per-ball version invalidation and verify behavior through TDD invariants.

**Tech Stack:** Julia 1.12, `DataStructures.jl`, `StaticArrays.jl`, `CairoMakie.jl`, `Test`

---

### Task 1: Package scaffold

**Files:**
- Create: `Project.toml`
- Create: `src/ElasticBalls2D.jl`
- Create: `test/runtests.jl`

**Step 1: Write failing test**
- Add `test/runtests.jl` checks that package loads and exports expected API symbols.

**Step 2: Run test to verify it fails**
- Run: `julia --project=. -e 'using Pkg; Pkg.test()'`
- Expected: fail due to missing types/functions.

**Step 3: Write minimal implementation**
- Add module and placeholder exports.

**Step 4: Run test to verify it passes**
- Run package tests.

### Task 2: Exact collision math

**Files:**
- Modify: `src/ElasticBalls2D.jl`
- Modify: `test/runtests.jl`

**Step 1: Write failing tests**
- Wall collision time tests for both axes and directions.
- Ball-ball collision time tests for hit/miss/separating cases.

**Step 2: Run tests to fail**
- Run targeted tests.

**Step 3: Implement minimal math**
- Add analytic solvers with tolerances.

**Step 4: Run tests to pass**
- Re-run targeted tests.

### Task 3: Event engine and invariants

**Files:**
- Modify: `src/ElasticBalls2D.jl`
- Modify: `test/runtests.jl`

**Step 1: Write failing tests**
- Two-ball head-on elastic collision conserves kinetic energy.
- Wall reflection flips one component.
- Stale events get invalidated.

**Step 2: Run tests to fail**
- Run full suite.

**Step 3: Implement minimal engine**
- Add `World`, `Event`, queue scheduling, `step_event!`, `simulate`.

**Step 4: Run tests to pass**
- Run full suite.

### Task 4: Visualization API

**Files:**
- Modify: `src/ElasticBalls2D.jl`
- Modify: `test/runtests.jl`

**Step 1: Write failing tests**
- `animate` returns a figure object.
- Recording path writes output file.

**Step 2: Run tests to fail**
- Run visualization tests.

**Step 3: Implement minimal visualization**
- Add Makie-based animation over simulated frames.

**Step 4: Run tests to pass**
- Run all tests.

### Task 5: Final verification

**Files:**
- Modify: `README.md`

**Step 1: Add concise usage docs**
- Include setup, simulation, and animation examples.

**Step 2: Verification before completion**
- Run: `julia --project=. -e 'using Pkg; Pkg.test()'`
- Run: `julia --project=. -e 'using ElasticBalls2D'`
- Confirm no failures.
