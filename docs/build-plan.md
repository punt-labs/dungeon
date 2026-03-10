# Dungeon — Development Build Plan

## Guiding Principles

1. **Test infrastructure before game code.** The test harness, CI pipeline,
   fakes, and fixture format are built first. No game logic is written until
   you can run `go test ./...` and see it pass or fail clearly.

2. **Thin end-to-end slices before depth.** Each milestone delivers a
   working, integrated path through the full architecture — even if most of
   that path is a stub. The next milestone adds meat to the bone. The system
   is never in a state where a full slice cannot be exercised.

3. **Headless first, display last.** The `headless` play mode (zero
   dependencies) is the CI workhorse and the first integration target. Lux
   and LLM integrations are layered on top of a proven engine core.

4. **Each milestone ends in green CI.** No milestone is done until tests pass,
   lint is clean, and the binary is runnable end-to-end. Partial work stays
   on a branch.

5. **Dependencies flow downward.** Engine knows nothing about interpreters.
   Interpreters know nothing about narrators. Narrators know nothing about
   renderers. When lower layers change, only lower-layer tests need to change.

---

## Module Dependency Map

```text
        ┌──────────────────────────────────────────────┐
        │             CLI / Commands                    │  dungeon solo
        │         (dungeon headless, dm, serve)         │  dungeon headless
        └───────────────┬──────────────────────────────┘  dungeon serve
                        │ wires together
        ┌───────────────▼──────────────────────────────┐
        │          Play Mode Composition                │
        │   CommandInterpreter + Narrator + Renderer    │
        └────┬───────────────┬─────────────────┬───────┘
             │               │                 │
   ┌─────────▼──────┐  ┌─────▼───────┐  ┌─────▼───────────┐
   │  Interpreters  │  │  Narrators  │  │   Renderers     │
   │  Rules / SLM   │  │  Template   │  │  CLI / Lux      │
   │  LLM           │  │  SLM / LLM  │  │                 │
   └─────────┬──────┘  └─────┬───────┘  └─────────────────┘
             │               │
        ┌────▼───────────────▼───────────────────────────┐
        │                 Engine                          │
        │  GameState · Character · Map · Combat           │
        │  Inventory · Leveling · Save/Load               │
        └─────────────────┬──────────────────────────────┘
                          │
        ┌─────────────────▼──────────────────────────────┐
        │           Data Contracts                        │
        │  Structs · Scenario YAML · Save JSON            │
        │  MCP tool signatures                            │
        └────────────────────────────────────────────────┘
```

Build order follows the graph: contracts → engine → interfaces → CLI
integration. Fakes for every external boundary are built alongside the
boundary they mock, not after.

---

## Milestone 0 — Foundation (Test Infrastructure Only)

**Goal:** `go test ./...` runs and produces a clear signal. No game logic
exists yet. Every subsequent milestone builds on this foundation.

**What gets built:**

- Go module scaffold: `go.mod`, directory layout, build tags
  (`unit`, `integration`, `e2e`, `acceptance`)
- CI workflow: `test.yml` running `go test -race ./...` and
  `go test -tags integration ./...`
- `internal/testutil/` package:
  - `FakeLLMInterpreter` — returns canned action from a fixture file
  - `FakeLLMNarrator` — returns fixture string
  - `FakeSLMServer` — `httptest.Server` serving canned ollama JSON
  - `FakeLuxServer` — records `show()`/`update()` calls; injects events
  - `ScriptRunner` — skeleton for running game scripts (no engine yet)
- `testdata/` layout: `scenarios/`, `saves/`, `scripts/`, `fixtures/`
- `testdata/scenarios/minimal.yaml` — two rooms, one enemy, one item
- Markdownlint in CI on all `*.md` files
- `go vet` and `staticcheck` in CI

**Done when:** `go test ./...` passes (trivially — no tests yet, but
infrastructure compiles). CI is green on an empty main branch.

**Why first:** Every milestone that follows assumes these tools exist. Writing
a test for a function that doesn't exist yet is the natural TDD starting
position. The fakes are the most reused code in the test suite — build them
before anything they mock.

---

## Milestone 1 — Data Contracts

**Goal:** The data model compiles, parses, serialises, and has full unit test
coverage. No engine logic, no command processing, no rendering.

**What gets built:**

- `internal/model/` — all Go structs with zero methods:
  `GameState`, `Character`, `Stats`, `Equipment`, `Condition`,
  `DungeonMap`, `Room`, `Exit`, `Enemy`, `Item`, `LogEntry`
- `internal/scenario/` — YAML parser and validator:
  - Load and validate `minimal.yaml`
  - Typed errors for missing required fields, broken room references,
    unknown enemy templates, invalid dice notation
  - `dungeon validate <file>` CLI command (first runnable command)
- `internal/save/` — JSON save/load:
  - `Save(state GameState, path string) error`
  - `Load(path string) (GameState, error)`
  - Version field; unknown fields ignored (forward compat)
- `internal/dice/` — dice notation parser: `1d6`, `2d6+3`, `1d20-1`
- `testdata/scenarios/invalid/` — six broken scenario files for parser tests
- `testdata/saves/fighter-level-3.json` — known state fixture

**Tests written (unit):**
- Scenario parser: valid load, each invalid fixture, each error type
- Save round-trip: full `GameState` marshal/unmarshal deep-equal
- Save forward compat: unknown field survives round-trip
- Dice parser: all notation forms; boundary rolls; invalid → error

**Done when:** `go test ./internal/...` passes with ≥ 90% coverage on all
Milestone 1 packages. `dungeon validate testdata/scenarios/minimal.yaml`
prints "OK" and exits 0.

---

## Milestone 2 — Thin End-to-End Slice

**Goal:** A player can type `dungeon headless` and move between two rooms.
The full pipeline — interpreter → engine → narrator → renderer — exists and
is wired together, even though each layer is a thin stub. This is the most
important milestone; it validates the architecture before any real logic is
built.

**What gets built:**

- `internal/engine/` — movement only:
  - `move(direction)` → updates `CurrentRoom`, appends log entry, returns
    `MoveResult{NewRoom, Exits, Items, Enemies}`
  - `look()` → returns current room description
  - `new_game(scenario, character)` → initialises `GameState`
- `internal/interpreter/rules.go` — `RulesInterpreter`:
  - Recognises: `go <dir>`, `n/s/e/w`, `look`, `quit`
  - Returns `unknown` action for everything else (not an error)
- `internal/narrator/template.go` — `TemplateNarrator`:
  - Handles: `moved`, `looked`, `unknown_action`
  - One-sentence templates; no creativity required
- `internal/renderer/cli.go` — `CLIRenderer`:
  - Prints room name, exits list, narration text to stdout
  - Reads one line from stdin, returns it as `InputEvent`
- `cmd/dungeon/` — `headless` subcommand:
  - `dungeon headless --scenario <id>` starts a game loop
  - `dungeon headless --script <file>` runs a script non-interactively
- `testdata/scripts/minimal-run.yaml` — move north, move south, verify rooms

**Tests written:**

- Unit: `engine.move()` — open door, locked door (returns error), unknown
  direction, move updates fog-of-war list
- Unit: `RulesInterpreter` — full verb table (≥ 20 cases)
- Unit: `TemplateNarrator` — each event type produces non-empty string
- Integration (headless loop): `new_game → move(S) → look → move(N)`
  — wires all three interfaces; asserts `GameState` after each step
- E2E: `dungeon headless --script minimal-run.yaml` exits 0 and prints
  expected room names

**Done when:** `dungeon headless --script testdata/scripts/minimal-run.yaml`
passes. You can watch the full pipeline execute in one command. CI is green.

---

## Milestone 3 — Full Engine and Headless Mode

**Goal:** Deepen the engine to cover all game mechanics. `headless` is now a
complete, playable mode. The acceptance test suite runs for the first time.

**Sub-order within this milestone:**

1. **Character and inventory** — `pick_up`, `drop`, `equip`, `use_item`,
   `examine`; weight limits; slot conflicts
2. **Combat engine** — initiative, `attack`, `defend`, `flee`, `end_combat`;
   all AI patterns; conditions
3. **Spells** — `cast_spell`; MP cost; Mage/Priest class gates
4. **Leveling** — XP thresholds per class; stat delta on level-up
5. **Save/load in-game** — `save_game`, `load_game` MCP tools wired
6. **RulesInterpreter expanded** — all verbs: `attack`, `pick up`, `equip`,
   `cast`, `rest`, `search`, `use`, `save`, `load`, `i`, `help`
7. **TemplateNarrator expanded** — all event types
8. **CLIRenderer expanded** — ASCII map, HP/MP bar, enemy list

**Tests written for each sub-step before the code:**
- Unit tests first; integration sequence tests second
- Combat sequence: `new_game → move → attack × N → end_combat → verify XP`
- Leveling: near-levelup fixture → one kill → assert level increased
- Save/load: mid-combat save → load → assert state identical
- All five acceptance scripts passing for the first time

**MCP schema contract introduced:**
- `cmd/dump-mcp-schema` generates `testdata/mcp-schema.json`
- CI diffs generated vs. committed; any unintentional API change fails build

**Done when:** All five acceptance scripts pass. Engine coverage ≥ 90%.
A real human can play a complete game via `dungeon headless`.

---

## Milestone 4 — Lux Thin Slice

**Goal:** `dungeon solo` starts, connects to Lux, and shows a minimal HUD.
A player can move rooms and see the narration log update in Lux. No SLM yet —
`solo` still uses `RulesInterpreter` as the interpreter in this milestone.

**What gets built:**

- `internal/renderer/lux.go` — `LuxRenderer` (thin):
  - `show()` on `new_game` and room transitions: displays room name and
    narration in a single Lux text panel
  - `update()` for log appends
  - `recv()` event loop for Lux button presses → `InputEvent`
- `cmd/dungeon/solo.go` — `dungeon solo` subcommand:
  - Wires `RulesInterpreter` + `TemplateNarrator` + `LuxRenderer`
  - Falls back to `CLIRenderer` if Lux is not running

**Tests written:**

- Unit: `LuxRenderer.Render()` calls `show()` on scene transition, not
  `update()` — verified against `FakeLuxServer` call log
- Unit: `LuxRenderer.Render()` calls `update()` for log appends —
  not a full `show()` (regression guard)
- Integration: `FakeLuxServer` receives correct element structure for
  a two-room navigation sequence
- Integration: `FakeLuxServer` injects a synthetic button press event;
  assert engine receives correct `InputEvent`

**Done when:** `dungeon solo --scenario minimal` connects to a running Lux
instance and displays room transitions. `FakeLuxServer` tests pass in CI
without Lux installed.

---

## Milestone 5 — Full Lux HUD

**Goal:** Deepen `LuxRenderer` to the full four-panel HUD. Navigation buttons,
HP/MP bars, fog-of-war map canvas, combat panel.

**Sub-order:**

1. Stats panel: HP/MP progress bars, class/level, XP
2. Map canvas: `draw` element, grid rooms, fog of war, player dot
3. Navigation buttons: N/S/E/W/Up/Down as Lux buttons wired to engine
4. Narration log: scrolling markdown panel
5. Combat panel: enemy HP bars, action buttons (Attack/Defend/Use/Flee)

**Tests written:** Each panel addition tested against `FakeLuxServer`. Button
press events from `FakeLuxServer` drive combat actions without any LLM.

**Done when:** Full HUD renders for a complete game session including combat.
`FakeLuxServer` integration tests cover all HUD update paths.

---

## Milestone 6 — SLM Thin Slice

**Goal:** `dungeon solo` uses a real SLM for command interpretation and
narration. The thin slice handles only movement commands; full verb coverage
comes next.

**What gets built:**

- `internal/interpreter/slm.go` — `SLMInterpreter` (thin):
  - Calls ollama `/api/generate` with compact system prompt
  - Parses JSON action response
  - Timeout → fallback to `RulesInterpreter`
  - Non-200 or malformed JSON → fallback
- `internal/narrator/slm.go` — `SLMNarrator` (thin):
  - Calls ollama with room seed + moved event
  - Returns model prose verbatim
- `testdata/fixtures/ollama-*.json` — canned responses for all test cases

**Tests written (all using `FakeSLMServer`, never real ollama):**

- Happy path: JSON action parsed correctly
- Timeout: fallback triggered, game continues
- Malformed JSON: fallback triggered, game continues
- Non-200: fallback triggered, game continues
- Narrator: prose from canned response passed through to renderer

**Done when:** `dungeon solo` with a running ollama instance uses SLM for
movement narration. All SLM tests pass in CI without ollama installed.

---

## Milestone 7 — Full SLM (Solo Mode Complete)

**Goal:** `SLMInterpreter` and `SLMNarrator` cover all game actions. `solo`
mode is fully playable with SLM as a first-class experience.

- Expand `SLMInterpreter` system prompt and action schema to all verbs
- Expand `SLMNarrator` templates to all event types: combat, items, leveling
- Model eval harness: `cmd/eval-slm` runs the full verb table through a real
  ollama model and scores classification accuracy (not CI — run manually)
- `dungeon solo` declared feature-complete

---

## Milestone 8 — Daemon Thin Slice

**Goal:** `dungeon serve` starts and handles a single MCP client connection.
The full daemon topology (Section 4.2 of architecture spec) is exercised for
the first time, even though session routing is not yet implemented.

**What gets built:**

- `cmd/dungeon/serve.go` — `dungeon serve` subcommand:
  - Starts daemon, listens on Unix socket
  - Accepts one MCP client connection
  - Dispatches all MCP tools to embedded engine
  - Responds with same JSON as embedded mode
- Auto-start: if socket is not present, `dungeon dm` starts the daemon

**Tests written:**

- Integration (in-process): spawn daemon, connect one fake MCP client,
  call `new_game` + `move` + `save_game`, verify JSON responses
- E2E: spawn `dungeon serve` subprocess, connect minimal MCP client over
  stdio, call each tool once, assert valid JSON, no stderr

**Done when:** MCP wire smoke tests pass. Daemon can handle a complete game
session from a single client.

---

## Milestone 9 — DM Thin Slice

**Goal:** `dungeon dm` works. A Claude Code session can connect via MCP,
start a game, and receive narration from the LLM. The thin slice covers only
movement and basic narration.

**What gets built:**

- `internal/interpreter/llm.go` — `LLMInterpreter` (thin):
  - Makes MCP callback to Claude with player input + room context
  - Returns structured action JSON
- `internal/narrator/llm.go` — `LLMNarrator` (thin):
  - Calls Claude with event result + adventure context
  - Returns narration string
- `skills/dungeon/SKILL.md` — rewritten for DM role:
  - Narration instructions, not game rules
  - Handles room descriptions, item examine responses
- `cmd/dungeon/dm.go` — `dungeon dm` subcommand

**Tests written (using `FakeLLMInterpreter` and `FakeLLMNarrator`):**

- Integration: full DM mode pipeline with fakes — engine transitions are
  identical to headless, only Interpreter and Narrator differ
- The LLM is never called in tests; the fakes assert correct
  prompt structure is assembled

**Done when:** `dungeon dm` invoked by `/dungeon` skill starts a playable
game with Claude narrating room descriptions. E2E: daemon + one DM session +
movement + narration all working together.

---

## Milestone 10 — Daemon Session Routing

**Goal:** The daemon supports multiple concurrent sessions, DM-privileged
tool routing, and `tools/list_changed` push. This is the pre-requisite for
multi-player and is also required for production-quality DM mode.

**What gets built:**

- Session identity injection (from mcp-proxy, or via `--session-id` flag
  until mcp-proxy ships)
- DM vs. player tool privilege gating
- `tools/list_changed` push after any player action
- Session isolation: game A state cannot bleed into game B

**Tests written:**

- Two in-process fake clients; DM identity vs. player identity
- DM-only tool called from player → typed error response
- Player action → `tools/list_changed` received by DM client only
- Two concurrent game sessions; mutation in session A does not affect B

---

## Milestone 11 — Full DM Mode

**Goal:** DM mode is fully featured. Rich narration, lore on examine,
DM-generated scenario creation.

- `LLMInterpreter` and `LLMNarrator` cover all game actions
- `/dungeon:create` skill command: DM generates scenario YAML interactively
- DM can generate encounter backstories and puzzle hints on demand
- `dungeon dm` declared feature-complete

---

## Milestone 12 — Rich World

**Goal:** Multiple bundled scenarios; advanced mechanics.

- Shops (buy/sell, gold economy)
- Traps (DEX save on room entry)
- Cursed items (equip without knowing; `identify` spell to reveal)
- Multiple bundled scenarios (minimum three)
- Permadeath mode configurable per scenario

---

## Milestone 13 — Biff Multi-player

**Goal:** Party play. Each Biff participant controls one character.

- `GameState.Party` promoted from single-element to real party
- `move`/`attack`/`flee`/`defend` `character_id` routing active
- Turn tokens via Biff `/write`
- Shared save state across sessions
- DM narrates for the full party

---

## Build Order Summary

```text
M0  Foundation      Test infra, CI, fakes, no game code
M1  Data Contracts  Structs, YAML parser, save/load, testdata
M2  Thin E2E Slice  Move pipeline: interpreter → engine → narrator → renderer
                    ← FIRST FULL ARCHITECTURE VALIDATION →
M3  Full Headless   All engine mechanics; full headless mode; acceptance tests
M4  Lux Thin Slice  LuxRenderer stub; dungeon solo shows minimal HUD
M5  Full Lux HUD    Four-panel HUD; nav buttons; combat panel
M6  SLM Thin Slice  SLMInterpreter + SLMNarrator for movement; fallback tested
M7  Full SLM        All verbs; solo mode complete
M8  Daemon Slice    dungeon serve; single-session; MCP wire tests
M9  DM Thin Slice   LLM in the loop; dungeon dm; SKILL.md rewrite
                    ← FIRST FULL DM MODE VALIDATION →
M10 Daemon Routing  Multi-session; privilege gating; push notifications
M11 Full DM Mode    Rich narration; scenario creation
M12 Rich World      Shops, traps, multiple scenarios
M13 Biff            Multi-player party
```

The two critical integration gates are **M2** (architecture validated end-to-end
before any real mechanics) and **M9** (LLM in the loop before the engine is
heavily invested in). If either of these gates reveals a design flaw, the cost
of correction is low.

---

## What Parallel Work Is Safe

Some work can proceed in parallel once its dependencies are met:

| Can run in parallel | After |
|---|---|
| `FakeLuxServer` + `LuxRenderer` | M2 (interfaces defined) |
| `FakeSLMServer` + SLM interpreters | M2 (interfaces defined) |
| Additional scenario YAML files | M1 (parser exists) |
| Additional acceptance scripts | M3 (engine complete) |
| SKILL.md DM role draft | M3 (game mechanics stable) |
| Daemon shell | M3 (engine complete) |
| `LLMInterpreter`/`LLMNarrator` stubs | M2 (interfaces defined) |

---

## Red Lines

These constraints must hold throughout development:

- **`go test ./...` is always green on `main`.** All failing tests live on
  branches. No exceptions.
- **No game logic in the LLM prompt.** If a rule can be stated in Go, it must
  be. The LLM prompt grows only with narrative and creative guidance.
- **No network in unit tests.** Any test that dials a real socket is an
  integration test and must be tagged accordingly.
- **No real ollama or Lux in CI.** Every external dependency has a fake. If a
  test requires the real thing, it is a manual playtest, not CI.
- **Save files are always loadable by the current binary.** Migration tests
  run on every format change. Old saves never silently corrupt.
