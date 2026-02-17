---
title: "The UNIX Catacombs"
description: "Descend into a system gone wrong. Battle segfaults, navigate pipe mazes, and seek the legendary Root Shell."
author: claude-dungeon
starting_scene: entrance
---

# The UNIX Catacombs

## Scene: entrance

**Login Prompt**

A green phosphor terminal flickers in the darkness. The cursor blinks steadily.

```
  ┌──────────────────────────────────────┐
  │                                      │
  │   UNIX System V — Catacomb Edition   │
  │                                      │
  │   login: _                           │
  │                                      │
  └──────────────────────────────────────┘
```

You are a process, newly spawned, standing before the system's login gate. The cursor pulses, waiting. Beyond the terminal, corridors of memory stretch in every direction. A crumpled man page lies on the floor.

#### Action: login

- matches: ["login", "type", "enter", "log in", "guest", "type guest", "anonymous"]
- next_scene: home-directory
- narration: "You type 'guest' and press Enter. The terminal flickers — ACCESS GRANTED. The screen dissolves and you find yourself standing inside the filesystem."

#### Action: read-manpage

- matches: ["read", "look at paper", "man page", "examine", "read man page", "pick up paper"]
- set_flag: read_manpage
- narration: "The crumpled man page reads: `man survival(7)` — 'In the UNIX Catacombs, every process has a PID and a purpose. Find the Root Shell before the OOM Killer finds you. Pipes connect all things. stderr is your friend.' Cryptic, but noted."

#### Action: root-login

- matches: ["root", "su", "sudo", "login as root"]
- narration: "Permission denied. Nice try."

---

## Scene: home-directory

**/home/guest**

You stand in a sparse home directory. A single `.bashrc` file glows faintly on the floor. Three paths branch out: a well-worn path labeled `/tmp`, a narrow corridor marked `/var/log`, and a sealed door with `/etc/shadow` stenciled on it.

```
  ~/
  ├── .bashrc
  ├── /tmp ──────>
  ├── /var/log ──>
  └── /etc/shadow [LOCKED]
```

#### Action: read-bashrc

- matches: ["read bashrc", "cat bashrc", "examine bashrc", "look at bashrc", "source bashrc"]
- add_item: alias_shield
- narration: "You source the `.bashrc`. Among the aliases, you find one that pulses with power: `alias shield='deflect -a'`. The alias shield wraps around you like armor."

#### Action: go-tmp

- matches: ["go tmp", "cd tmp", "/tmp", "go to tmp", "take tmp path", "well-worn path"]
- next_scene: tmp-wasteland
- narration: "You follow the well-worn path toward /tmp..."

#### Action: go-var-log

- matches: ["go var", "cd var", "/var/log", "var log", "narrow corridor", "go to var"]
- next_scene: var-log
- narration: "You squeeze into the narrow /var/log corridor. Scrolling text lines the walls."

#### Action: try-etc-shadow

- matches: ["open door", "/etc/shadow", "etc shadow", "try door", "try shadow"]
- narration: "The door to /etc/shadow is sealed with permissions: `-rw------- root root`. You'll need root access to enter."

---

## Scene: tmp-wasteland

**/tmp Wasteland**

A chaotic landscape of abandoned temp files stretches before you. Half-finished downloads, orphaned sockets, and stale lock files litter the ground. In the distance, something moves — a Segfault Daemon shambles between the debris, corrupting everything it touches. A pipe (`|`) juts from the ground nearby.

```
  /tmp $  ls -la
  drwxrwxrwt  chaos  chaos   .
  -rw-------  ???    ???     core.dump
  srwx------  ???    ???     orphan.sock
  prw-r--r--  root   root   mystery.pipe
```

#### Action: fight-segfault

- matches: ["fight", "attack", "kill", "battle segfault", "fight daemon", "fight segfault"]
- next_scene: segfault-battle
- narration: "You approach the Segfault Daemon. It turns, memory addresses streaming from its eyes."

#### Action: examine-pipe

- matches: ["examine pipe", "look at pipe", "pipe", "check pipe", "inspect pipe", "mystery pipe"]
- set_flag: found_pipe
- add_item: pipe_connector
- narration: "The pipe is labeled `mystery.pipe`. You wrench it free — it could connect to anything. A pipe connector might be useful for redirecting... things."

#### Action: read-core-dump

- matches: ["read core", "examine core", "core dump", "cat core", "look at core"]
- set_flag: read_core
- narration: "The core dump is a mess of stack traces, but you spot a pattern: `0xDEAD → /dev/null → pipe_maze_entrance`. It's a map fragment — the pipe maze connects to /dev/null."

#### Action: go-back

- matches: ["go back", "cd ~", "return", "go home"]
- next_scene: home-directory
- narration: "You retreat to the relative safety of your home directory."

---

## Scene: segfault-battle

**Segfault Daemon**

The daemon lurches toward you, its form flickering between memory addresses. `SIGSEGV` pulses from its core. It reaches for you with corrupted pointers.

```
   ╔═══════════════════════════════╗
   ║  SEGFAULT DAEMON              ║
   ║  HP: [██████████] 100         ║
   ║  ATK: SIGSEGV (corrupts mem)  ║
   ╚═══════════════════════════════╝
```

#### Action: fight-with-shield

- matches: ["fight", "attack", "use shield", "deflect", "battle"]
- requires_item: alias_shield
- health_change: -15
- next_scene: tmp-cleared
- add_item: segfault_core
- set_flag: daemon_killed
- narration: "Your alias shield deflects the worst of the SIGSEGV signals. You land a `kill -9` on the daemon and it crashes, leaving behind its core — a pulsing fragment of raw process power."

#### Action: fight-without-shield

- matches: ["fight", "attack", "punch", "hit"]
- health_change: -40
- next_scene: tmp-cleared
- add_item: segfault_core
- set_flag: daemon_killed
- narration: "Without protection, the daemon's SIGSEGV hits hard — your memory scrambles and you nearly crash. But you manage to `kill -9` it. The daemon collapses, leaving its core."

#### Action: flee

- matches: ["run", "flee", "escape", "retreat"]
- health_change: -10
- next_scene: tmp-wasteland
- narration: "You dodge a corrupted pointer and flee. The daemon doesn't pursue — it returns to shambling among the temp files."

---

## Scene: tmp-cleared

**/tmp (Cleared)**

The wasteland is quieter now. Where the Segfault Daemon fell, a glowing portal has appeared — the entrance to the Pipe Maze. The path back to /home is clear.

#### Action: enter-maze

- matches: ["enter maze", "go in", "pipe maze", "portal", "enter portal", "enter"]
- next_scene: pipe-maze
- narration: "You step through the portal and the world dissolves into streams of data..."

#### Action: go-back

- matches: ["go back", "return", "go home", "cd ~"]
- next_scene: home-directory
- narration: "You head back to your home directory."

#### Action: use-potion

- matches: ["heal", "rest", "recover"]
- narration: "You rest among the cleared temp files. The system is quiet here now, but you don't recover — you'll need something stronger."

---

## Scene: var-log

**/var/log**

Walls of scrolling text surround you — system logs, auth logs, error messages cascading forever. Most are noise, but patterns emerge if you look carefully. A `grep` tool hangs on the wall in a glass case labeled "Break in case of emergency."

#### Action: grep

- matches: ["take grep", "grab grep", "use grep", "break glass", "get grep", "grep tool"]
- add_item: grep_tool
- narration: "You smash the glass and take the grep tool. With this, you can search for patterns anywhere in the catacombs."

#### Action: read-logs

- matches: ["read logs", "examine logs", "search logs", "look at logs", "read"]
- narration: "Most logs are routine — cron jobs, SSH attempts, daemon heartbeats. But one line stands out: `WARN: OOM Killer activated. Hunting PID > 1000. ETA: unknown.` Your PID is 31337. Time is not on your side."
- set_flag: oom_warning

#### Action: search-auth

- matches: ["auth log", "search auth", "grep auth", "check auth", "authentication"]
- requires_item: grep_tool
- set_flag: found_password_hint
- narration: "You grep through auth.log and find a failed login attempt: `root : incorrect password 'r00tsh3ll'`. Someone tried to log in as root. That password failed, but the attempt itself is interesting..."

#### Action: go-back

- matches: ["go back", "return", "cd ~", "go home"]
- next_scene: home-directory
- narration: "You leave the endless scroll of logs behind."

---

## Scene: pipe-maze

**The Pipe Maze**

You're inside a network of pipes — literal UNIX pipes connecting processes. Data streams flow in every direction, and wrong turns dump you to `/dev/null`. Three pipes branch before you:

```
  stdin ──┬──── pipe A ──> [rumbling sounds]
           ├──── pipe B ──> [silence]
           └──── pipe C ──> [faint light]
```

#### Action: pipe-a

- matches: ["pipe a", "take a", "rumbling", "go a", "first pipe", "left pipe"]
- health_change: -20
- next_scene: pipe-maze
- narration: "You crawl through pipe A and emerge... back where you started, minus some HP. That pipe was a loop — stdout piped to stdin."

#### Action: pipe-b

- matches: ["pipe b", "take b", "silence", "go b", "second pipe", "middle pipe"]
- next_scene: dev-null
- narration: "Silence engulfs you. The pipe narrows, the data stream thins to nothing..."

#### Action: pipe-c

- matches: ["pipe c", "take c", "faint light", "go c", "third pipe", "right pipe"]
- next_scene: root-chamber
- narration: "You follow the faint light through pipe C. The data stream carries you forward..."

#### Action: use-connector

- matches: ["use pipe connector", "connect pipes", "redirect", "use connector"]
- requires_item: pipe_connector
- set_flag: pipe_redirected
- next_scene: root-chamber
- narration: "You use the pipe connector to redirect the data flow, bypassing the maze entirely. All pipes now lead to the light."

---

## Scene: dev-null

**/dev/null**

Void. Absolute nothing. Data enters and is destroyed. You feel yourself dissolving at the edges. There's nothing here — except a faint echo of a path back.

#### Action: escape

- matches: ["escape", "go back", "return", "leave", "resist", "fight", "hold on"]
- health_change: -25
- next_scene: pipe-maze
- narration: "You claw your way back against the null current. It costs you, but you make it back to the pipe junction."

#### Action: accept

- matches: ["accept", "give up", "let go", "surrender"]
- health_change: -100
- narration: "You let the void take you. Your process dissolves into nothing. `kill -9 31337`... silence."

---

## Scene: root-chamber

**The Root Chamber**

A vast chamber carved from pure silicon. In the center, on a pedestal of stacked man pages, rests the **Root Shell** — a glowing terminal prompt pulsing with `#` instead of `$`. The air hums with privilege escalation. But the chamber is guarded — the OOM Killer stands between you and the shell, a towering process reaper with `kill -9` crackling in its hands.

```
   ╔═══════════════════════════════╗
   ║       THE OOM KILLER          ║
   ║                               ║
   ║   "Out of memory. You must    ║
   ║    be terminated."            ║
   ║                               ║
   ║   HP: [██████████] HIGH       ║
   ╚═══════════════════════════════╝
```

#### Action: fight-oom

- matches: ["fight", "attack", "battle", "kill", "fight oom"]
- requires_item: segfault_core
- health_change: -30
- next_scene: root-shell
- narration: "You hurl the segfault core at the OOM Killer. It crashes, reboots, crashes again — a kernel panic cascades through its systems. While it thrashes, you dash past."

#### Action: fight-without-core

- matches: ["fight", "attack", "punch"]
- health_change: -60
- narration: "The OOM Killer is too powerful for a direct attack. `kill -9` hits you like a truck. You barely survive. You need something to crash its process first."

#### Action: use-password

- matches: ["password", "r00tsh3ll", "use password", "try password", "login", "su root", "sudo"]
- requires_flag: found_password_hint
- next_scene: root-shell
- narration: "You approach the terminal pedestal and type: `su root` — password: `r00tsh3ll`. The OOM Killer freezes. 'Authorized user detected. Standing down.' It dissolves into freed memory."

#### Action: use-grep

- matches: ["grep", "search", "analyze", "scan", "use grep"]
- requires_item: grep_tool
- set_flag: oom_weakness
- narration: "You grep the OOM Killer's process: `grep -r weakness /proc/oomkiller`. Result: 'Vulnerable to SIGSEGV core injection.' You need the segfault daemon's core to exploit this."

---

## Scene: root-shell

**The Root Shell**

The OOM Killer is gone. The Root Shell glows before you, the most powerful artifact in the UNIX Catacombs.

```
  ┌──────────────────────────────────────┐
  │                                      │
  │   root@catacombs:~#                  │
  │                                      │
  │   Welcome, superuser.                │
  │                                      │
  │   You now have root access.          │
  │   The system is yours.               │
  │                                      │
  └──────────────────────────────────────┘
```

#### Action: take-shell

- matches: ["take", "claim", "grab", "pick up", "use", "take shell", "root", "accept"]
- next_scene: victory
- narration: "You place your hands on the Root Shell. Power surges through you — every process, every file, every secret in the system bends to your will. `chmod 777 everything`. You are root. You have conquered the UNIX Catacombs."
