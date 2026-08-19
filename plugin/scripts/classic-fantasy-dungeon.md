---
title: "The Depths of Grimhold"
description: "A classic dungeon crawl beneath an ancient fortress. Goblins, traps, treasure, and a dragon await."
author: claude-dungeon
starting_scene: entrance
---

# The Depths of Grimhold

## Scene: entrance

**Torch-Lit Entrance**

You stand at the mouth of a crumbling stone passage. Torches flicker in iron sconces, casting dancing shadows across moss-covered walls. The air smells of damp earth and something faintly sulfurous. A weathered sign reads: *"Grimhold — Enter at your own peril."* The passage descends into darkness ahead. A rusty sword leans against the wall near the entrance.

```
          ___
         |   |
    _____|   |_____
   |               |
   |   ▓▓▓▓▓▓▓▓▓  |
   |   ▓       ▓  |
   |   ▓  YOU  ▓  |
   |   ▓       ▓  |
   |___▓_______▓__|
       ▓       ▓
       ▓▓▓▓▓▓▓▓▓
```

#### Action: take-sword

- matches: ["take sword", "grab sword", "pick up sword", "get sword", "take the rusty sword"]
- add_item: rusty_sword
- narration: You pick up the rusty sword. It's seen better days, but it has weight and an edge. Better than nothing.

#### Action: enter

- matches: ["go in", "enter", "descend", "walk in", "go forward", "proceed", "continue", "go deeper"]
- next_scene: corridor
- narration: You take a steadying breath and descend into the depths of Grimhold.

#### Action: examine-sign

- matches: ["read sign", "examine sign", "look at sign", "inspect"]
- narration: The sign is carved from dark wood. Below the warning, someone has scratched in smaller letters — *"Left is life, right is riches."* Helpful, if cryptic.
- set_flag: read_sign

---

## Scene: corridor

**Narrow Corridor**

The passage narrows. Your footsteps echo off close stone walls. Ahead, you hear faint chittering sounds — like small creatures arguing. The corridor opens into a wider chamber about thirty paces ahead. Along the wall, you notice a small iron lever partially hidden behind a loose stone.

#### Action: sneak

- matches: ["sneak", "creep", "move quietly", "stealth", "be quiet", "tiptoe"]
- next_scene: goblin-room-sneak
- narration: You press yourself against the cold wall and inch forward silently.

#### Action: charge

- matches: ["charge", "run in", "rush", "attack", "go loud", "sprint"]
- next_scene: goblin-room-loud
- narration: You let out a battle cry and charge forward!

#### Action: pull-lever

- matches: ["pull lever", "use lever", "flip lever", "pull the lever", "interact lever"]
- add_item: health_potion
- narration: The lever grinds and a small compartment opens in the wall, revealing a dusty glass vial filled with glowing red liquid. A health potion!

#### Action: go-back

- matches: ["go back", "retreat", "turn around", "return"]
- next_scene: entrance
- narration: You retreat to the entrance. The dungeon waits.

---

## Scene: goblin-room-sneak

**Goblin Warren (Undetected)**

You peer into a torchlit chamber. Three goblins sit around a rickety table, squabbling over a pile of coins. They haven't noticed you. A crude wooden door leads deeper into the dungeon on the far wall. A smaller passage branches off to the right, marked with scratch marks.

#### Action: sneak-past

- matches: ["sneak past", "slip by", "avoid", "go around", "stealth past", "continue sneaking"]
- next_scene: fork
- narration: You creep along the shadows and slip through the far door while the goblins argue. They never noticed a thing.

#### Action: ambush

- matches: ["attack", "ambush", "fight", "kill goblins", "strike", "surprise attack"]
- requires_item: rusty_sword
- next_scene: fork
- health_change: -10
- add_item: goblin_coins
- narration: You leap from the shadows! The goblins shriek. It's messy, but with surprise on your side, you dispatch them — though one catches your arm with its claws. You pocket their coins.

#### Action: ambush-no-weapon

- matches: ["attack", "fight", "punch", "hit them"]
- narration: You clench your fists... but charging three goblins unarmed seems unwise. If only you had a weapon.

#### Action: take-passage

- matches: ["go right", "take passage", "side passage", "small passage", "scratch marks"]
- next_scene: spider-nest
- narration: You squeeze into the narrow side passage, following the scratch marks into darkness.

---

## Scene: goblin-room-loud

**Goblin Warren (Alerted!)**

You burst into a torchlit chamber to find three goblins whirling to face you, crude weapons raised! They screech and attack!

#### Action: fight

- matches: ["fight", "attack", "swing", "defend", "battle", "slash", "hit them"]
- requires_item: rusty_sword
- next_scene: fork
- health_change: -25
- add_item: goblin_coins
- narration: Steel meets crude iron. The goblins fight viciously — one stabs your leg before you cut it down. You finish the last two, bloodied but standing. A pile of coins glitters on their table.

#### Action: fight-unarmed

- matches: ["punch", "kick", "fight bare"]
- next_scene: fork
- health_change: -45
- narration: You throw yourself into the fray with nothing but your fists. It's brutal. You manage to beat them, but you're battered and bleeding badly.

#### Action: flee

- matches: ["run", "flee", "escape", "retreat", "run away"]
- next_scene: corridor
- health_change: -15
- narration: You turn and bolt as a goblin dagger catches your shoulder. You escape back to the corridor, heart pounding.

---

## Scene: spider-nest

**Spider's Nest**

The passage opens into a low cavern draped in thick webs. In the center, a large spider the size of a dog crouches over something glinting — a silver key on a chain. The spider's many eyes track your movement.

```
    /\\  .-"""-.  /\\
   //\\\\/  ,,,  \\//\\\\
   |/  \\ (o.o) //  \\|
    \\   \\ \\=// /   //
     '---\\ ))) /---'
          \\///
```

#### Action: fight-spider

- matches: ["fight", "attack", "kill spider", "swing at spider", "slay"]
- requires_item: rusty_sword
- health_change: -15
- add_item: silver_key
- narration: You slash through the webs and drive the spider back. It hisses and bites your arm before you land a killing blow. You pry the silver key from its nest.

#### Action: distract

- matches: ["throw", "distract", "toss coins", "lure", "bait"]
- requires_item: goblin_coins
- remove_item: goblin_coins
- add_item: silver_key
- narration: You toss the goblin coins into the far corner. The spider skitters after the glinting metal, and you snatch the silver key from its nest.

#### Action: retreat

- matches: ["go back", "leave", "retreat", "run"]
- next_scene: goblin-room-sneak
- narration: You back away from the spider slowly. It watches you go.

---

## Scene: fork

**The Forking Path**

The corridor splits in two. The left passage slopes gently upward, and you can feel a faint breeze — perhaps an exit? The right passage descends steeply, and the sulfurous smell grows stronger. Scratch marks on the right wall read: *"DRAAK."* The walls here have carved alcoves, one of which holds a dusty health potion.

#### Action: take-potion

- matches: ["take potion", "grab potion", "get potion", "pick up potion", "health potion"]
- add_item: health_potion
- narration: You pocket the health potion. It glows faintly through the glass.

#### Action: go-left

- matches: ["go left", "take left", "left path", "follow breeze", "exit", "upward"]
- next_scene: treasure-room
- narration: You follow the breeze leftward and upward.

#### Action: go-right

- matches: ["go right", "take right", "right path", "go down", "descend", "toward smell", "draak"]
- next_scene: dragon-approach
- narration: You steel yourself and descend toward the sulfurous heat.

#### Action: use-potion

- matches: ["drink potion", "use potion", "heal", "drink health potion"]
- requires_item: health_potion
- remove_item: health_potion
- health_change: 40
- narration: You uncork the potion and drink. Warmth floods through you and your wounds begin to close.

---

## Scene: treasure-room

**Treasure Chamber**

A small chamber glitters with gold and gems piled carelessly around a stone pedestal. On the pedestal sits an ornate golden chalice. But the chamber has a heavy iron door on the far side — locked with a silver keyhole. Through the bars of the door, you can see daylight.

#### Action: take-chalice

- matches: ["take chalice", "grab chalice", "pick up chalice", "get chalice", "take gold", "take treasure"]
- add_item: golden_chalice
- narration: You lift the golden chalice. It's heavier than it looks, warm to the touch.

#### Action: unlock-door

- matches: ["unlock door", "use key", "use silver key", "open door", "escape"]
- requires_item: silver_key
- next_scene: victory
- narration: The silver key slides into the lock and turns with a satisfying click. The iron door swings open and daylight floods in. You step out onto a hillside, blinking in the sun, treasure in hand. You've escaped Grimhold!

#### Action: try-door

- matches: ["try door", "open door", "push door", "check door"]
- narration: The door is locked solid. A silver keyhole glints in the iron. You'll need a key.

#### Action: go-back

- matches: ["go back", "return", "leave"]
- next_scene: fork
- narration: You return to the forking path.

---

## Scene: dragon-approach

**Dragon's Antechamber**

The heat is intense. The passage widens into a vast cavern. Through a stone archway ahead, you can see the glow of something massive — a sleeping dragon, coiled atop a mountain of gold. Its breath comes in slow, smoky rumbles. A single exit tunnel leads past the dragon's hoard to daylight beyond.

```
                 __        _
               _/  \    _(\(o
              /     \  /  _  ^^^o
             /   !   \/  ! '!!!v'
            !  !  \ _' ( \__)
            !  !   '\   \/
             \  \/   \   |
              \  \    \  |
               \  !    \ !
                \  \    !|
                 ~\  \  !|
                   \  \ !;
                    ~\ \;|
                      ~ \!
```

#### Action: sneak-past-dragon

- matches: ["sneak", "sneak past", "creep", "stealth", "be quiet", "tiptoe"]
- next_scene: dragon-sneak
- narration: You press yourself low and begin to creep along the cavern wall...

#### Action: fight-dragon

- matches: ["fight", "attack", "charge", "fight dragon", "slay dragon"]
- requires_item: rusty_sword
- next_scene: dragon-fight
- narration: You raise your rusty sword and charge the dragon with a battle cry!

#### Action: go-back

- matches: ["go back", "retreat", "return", "leave"]
- next_scene: fork
- narration: Wisdom over valor. You retreat from the heat.

#### Action: use-potion

- matches: ["drink potion", "use potion", "heal"]
- requires_item: health_potion
- remove_item: health_potion
- health_change: 40
- narration: You drink the health potion, steeling yourself for what lies ahead.

---

## Scene: dragon-sneak

**Sneaking Past the Dragon**

You creep along the cavern wall, barely breathing. The dragon's massive flank rises and falls. Gold coins shift under your feet with tiny clinks. The exit tunnel is close — twenty paces, ten, five...

#### Action: keep-going

- matches: ["keep going", "continue", "press on", "keep sneaking", "almost there"]
- next_scene: victory
- health_change: 0
- narration: You reach the tunnel and slip through into blinding daylight. Behind you, the dragon snores on. You've escaped Grimhold — alive and perhaps wiser, if not richer.

#### Action: grab-gold

- matches: ["take gold", "grab gold", "grab treasure", "steal", "pocket gold", "take some gold"]
- next_scene: dragon-fight
- health_change: -30
- add_item: dragon_gold
- narration: You can't resist. You grab a fistful of gold — and a coin avalanche cascades down the pile. The dragon's eyes snap open, blazing with fury. A jet of flame scorches your side!

---

## Scene: dragon-fight

**The Dragon Awakens!**

The dragon rears up, filling the cavern. Its jaws open and heat shimmers in its throat. This is a fight you probably can't win — but the exit is right there.

#### Action: fight

- matches: ["fight", "attack", "slash", "swing", "stand and fight"]
- requires_item: rusty_sword
- health_change: -60
- next_scene: victory
- narration: You swing desperately as the dragon lunges. Your rusty sword finds the soft spot beneath its jaw — the beast screams and recoils. You sprint for the exit as flame erupts behind you. You're badly burned, but alive. You tumble out into daylight.

#### Action: run

- matches: ["run", "flee", "escape", "sprint", "dash for exit"]
- health_change: -35
- next_scene: victory
- narration: You don't hesitate — you bolt for the exit tunnel as dragonfire erupts behind you. The heat is searing. You dive through the exit and roll down the hillside, singed but alive. Grimhold is behind you.

#### Action: use-potion

- matches: ["drink potion", "use potion", "heal"]
- requires_item: health_potion
- remove_item: health_potion
- health_change: 40
- narration: You gulp down the health potion mid-battle as the dragon circles.
