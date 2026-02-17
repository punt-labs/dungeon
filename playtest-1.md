# Playtest 1 -- The UNIX Catacombs

**Date:** 2026-02-16 / 2026-02-17
**Script:** unix-catacombs
**Outcome:** In progress (stopped at /tmp Cleared, Turn 7)

---

## Turn 0: New Game

**Player:** `/dungeon new 2`

The game initializes with script #2, "The UNIX Catacombs."

**State created:**
- Scene: entrance
- HP: 100/100
- Inventory: (empty)
- Flags: (none)

---

## Turn 0: Entrance -- Login Prompt

```
─────────────────────────────────────────
Login Prompt              HP: [██████████] 100/100
─────────────────────────────────────────

  ┌──────────────────────────────────────┐
  │                                      │
  │   UNIX System V — Catacomb Edition   │
  │                                      │
  │   login: _                           │
  │                                      │
  └──────────────────────────────────────┘

A green phosphor terminal flickers in the darkness, its cursor
blinking with mechanical patience. You are a process, newly spawned,
standing before the system's login gate. Beyond the terminal,
corridors of memory stretch in every direction. A crumpled man page
lies on the floor near your feet.

What do you do?
  > Log in to the system
  > Read the crumpled man page
  > Try logging in as root
```

---

## Turn 1: Read the Man Page

**Player:** `/dungeon read the man page`

```
─────────────────────────────────────────
Login Prompt              HP: [██████████] 100/100
─────────────────────────────────────────
```

You pick up the crumpled man page and smooth it out. The faded dot-matrix print reads:

```
  man survival(7)

  In the UNIX Catacombs, every process has a PID
  and a purpose. Find the Root Shell before the
  OOM Killer finds you. Pipes connect all things.
  stderr is your friend.
```

Cryptic, but noted. The terminal still blinks before you, waiting for input. The corridors of memory stretch beyond.

What do you do?
  > Log in to the system
  > Try logging in as root

**State change:**
- Flag set: `read_manpage`

---

## Turn 2: Login

**Player:** `/dungeon login`

You type `guest` and press Enter. The terminal flickers --

```
  ACCESS GRANTED
```

The screen dissolves and reality shifts. You are no longer looking at a terminal. You are *inside* the filesystem.

```
─────────────────────────────────────────
/home/guest               HP: [██████████] 100/100
─────────────────────────────────────────

  ~/
  ├── .bashrc
  ├── /tmp ──────>
  ├── /var/log ──>
  └── /etc/shadow [LOCKED]
```

You stand in a sparse home directory. A single `.bashrc` file glows faintly on the floor, humming with stored configuration. Three paths branch out before you: a well-worn path to `/tmp`, a narrow corridor leading to `/var/log`, and a sealed door with `/etc/shadow` stenciled across it in root-only red.

What do you do?
  > Read the .bashrc file
  > Head to /tmp
  > Explore /var/log
  > Try the /etc/shadow door

**State change:**
- Scene: home-directory

---

## Turn 3: Read .bashrc

**Player:** `/dungeon read bashrc`

```
─────────────────────────────────────────
/home/guest               HP: [██████████] 100/100
─────────────────────────────────────────
```

You kneel down and `source .bashrc`. Lines of configuration scroll past your vision -- `PS1`, `PATH`, environment variables -- and then one alias pulses with power:

```
  alias shield='deflect -a'
```

The alias wraps around you like invisible armor, a shimmering layer of signal deflection. You feel protected against the worst the system might throw at you.

**Acquired: Alias Shield** -- deflects incoming signals.

The three paths still beckon before you.

What do you do?
  > Head to /tmp
  > Explore /var/log
  > Try the /etc/shadow door

  *Inventory: alias_shield*

**State change:**
- Item added: `alias_shield`

---

## Turn 4: Go to /tmp

**Player:** `/dungeon go to /tmp`

```
─────────────────────────────────────────
/tmp Wasteland            HP: [██████████] 100/100
─────────────────────────────────────────

  /tmp $  ls -la
  drwxrwxrwt  chaos  chaos   .
  -rw-------  ???    ???     core.dump
  srwx------  ???    ???     orphan.sock
  prw-r--r--  root   root   mystery.pipe
```

A chaotic landscape of abandoned temp files stretches before you. Half-finished downloads, orphaned sockets, and stale lock files litter the ground like digital debris. In the distance, something moves -- a Segfault Daemon shambles between the wreckage, corrupting everything it touches with wild pointer dereferences. A pipe juts from the ground nearby, labeled `mystery.pipe`.

What do you do?
  > Fight the Segfault Daemon
  > Examine the mystery pipe
  > Read the core dump
  > Go back to /home

  *Inventory: alias_shield*

**State change:**
- Scene: tmp-wasteland

---

## Turn 5: Examine the Pipe

**Player:** `/dungeon examine the pipe`

```
─────────────────────────────────────────
/tmp Wasteland            HP: [██████████] 100/100
─────────────────────────────────────────
```

You crouch beside the pipe jutting from the ground. It's labeled `mystery.pipe` -- a named UNIX pipe, owned by root. You grip it with both hands and wrench it free from the cracked earth. It hums faintly in your hands, one end open for input, the other for output. It could connect to anything -- redirect data streams, bypass junctions, maybe even reroute an entire maze.

**Acquired: Pipe Connector** -- can redirect data flows between processes.

The Segfault Daemon still shambles in the distance. The core dump lies untouched nearby.

What do you do?
  > Fight the Segfault Daemon
  > Read the core dump
  > Go back to /home

  *Inventory: alias_shield, pipe_connector*

**State change:**
- Item added: `pipe_connector`
- Flag set: `found_pipe`

---

## Turn 6: Fight the Segfault Daemon

**Player:** `/dungeon fight the segfault daemon`

```
─────────────────────────────────────────
Segfault Daemon           HP: [██████████] 100/100
─────────────────────────────────────────

   ╔═══════════════════════════════════╗
   ║  SEGFAULT DAEMON                  ║
   ║  HP: [██████████] 100             ║
   ║  ATK: SIGSEGV (corrupts memory)  ║
   ╚═══════════════════════════════════╝
```

You approach the daemon and it turns to face you. Memory addresses stream from its hollow eyes like tears of corrupted data. `SIGSEGV` pulses from its core in waves, and the air around it shimmers with dangling pointers. It reaches for you with hands made of null dereferences.

This thing will corrupt your memory if you're not careful.

What do you do?
  > Fight it (your alias shield should help deflect its signals)
  > Run for it

  *Inventory: alias_shield, pipe_connector*

**State change:**
- Scene: segfault-battle

---

## Turn 6 (continued): Use Pipe Connector (Failed)

**Player:** `/dungeon use pipe_connector`

```
─────────────────────────────────────────
Segfault Daemon           HP: [██████████] 100/100
─────────────────────────────────────────
```

You hold up the pipe connector, trying to redirect the daemon's data stream -- but there's nothing to pipe *to* here. The connector whines uselessly, its open ends finding no compatible process to latch onto. The Segfault Daemon doesn't even flinch. It reaches closer, null pointers crackling.

The pipe connector is meant for redirecting data flows, not fighting daemons. You'll need a more direct approach.

What do you do?
  > Fight it (your alias shield should deflect its signals)
  > Run for it

  *Inventory: alias_shield, pipe_connector*

**State change:** (none -- action did not match any valid scene action)

---

## Turn 7: Attack with Shield

**Player:** `/dungeon attack with my shield`

```
─────────────────────────────────────────
/tmp (Cleared)            HP: [█████████░] 85/100
─────────────────────────────────────────
```

Your alias shield flares to life -- `deflect -a` -- absorbing the brunt of the daemon's SIGSEGV barrage. Corrupted signals scatter off you like sparks. You close the distance and execute `kill -9` point blank. The daemon's eyes go wide, its process table empties, and it collapses into a heap of freed memory.

Where it fell, a pulsing fragment remains -- the **Segfault Core**, raw process power condensed into a throwable shard. You pocket it. Beyond the daemon's corpse, a glowing portal has appeared -- the entrance to the Pipe Maze.

**Acquired: Segfault Core** -- a fragment of pure SIGSEGV energy.
**HP: -15** (shield absorbed most of the damage)

What do you do?
  > Enter the Pipe Maze portal
  > Go back to /home

  *Inventory: alias_shield, pipe_connector, segfault_core*

**State change:**
- HP: 100 -> 85
- Scene: tmp-cleared
- Item added: `segfault_core`
- Flag set: `daemon_killed`

---

## Session End

The playtest ended here. The player had not yet entered the Pipe Maze, visited /var/log, or reached the Root Chamber.

### Final State

| Field     | Value                                    |
|-----------|------------------------------------------|
| Scene     | tmp-cleared                              |
| Turn      | 7                                        |
| HP        | 85 / 100                                 |
| Inventory | alias_shield, pipe_connector, segfault_core |
| Flags     | read_manpage, found_pipe, daemon_killed  |

### Path Taken

```
entrance
  └─ (read man page)
  └─ (login) ─> home-directory
                  └─ (read bashrc) ─> got alias_shield
                  └─ (go to /tmp) ─> tmp-wasteland
                                       └─ (examine pipe) ─> got pipe_connector
                                       └─ (fight daemon) ─> segfault-battle
                                                              └─ (use pipe -- FAILED)
                                                              └─ (attack with shield) ─> tmp-cleared
```

### Scenes Not Visited

- /var/log (grep tool, auth log password hint)
- /etc/shadow (locked, requires root)
- Pipe Maze
- /dev/null
- Root Chamber
- Root Shell / Victory

### Notes

- The player skipped /var/log entirely, which means they did not pick up the grep tool or find the password hint (`r00tsh3ll`). This closes off the password-based bypass of the OOM Killer in the Root Chamber.
- The player tried to use the pipe_connector in battle, which was correctly rejected -- it has no matching action in the segfault-battle scene.
- The player collected all items available on the /tmp path (alias_shield from home, pipe_connector and segfault_core from /tmp).
- With the segfault_core, the player can defeat the OOM Killer in the Root Chamber (at a cost of -30 HP, bringing them to 55 HP).
- The pipe_connector can be used to skip the Pipe Maze entirely, going straight to the Root Chamber.
