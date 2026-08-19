---
title: "The Haunted Library of Ashworth"
description: "A cursed library where silence is survival. Solve puzzles, avoid the Ghost Librarian, and find the Forbidden Tome."
author: claude-dungeon
starting_scene: entrance
---

# The Haunted Library of Ashworth

> **Special Mechanic: Noise Level**
>
> This adventure tracks a `noise` flag (values: quiet, moderate, loud).
> Noise starts at "quiet." Certain actions increase noise. If noise reaches "loud,"
> the Ghost Librarian appears and the player must deal with her before continuing.
> The flag `noise` in game state tracks this: `quiet` → `moderate` → `loud`.

## Scene: entrance

**The Whispering Foyer**

Moonlight streams through cracked stained glass, casting colored shadows across dusty marble floors. The entrance to the Ashworth Library looms before you — its doors hanging open, whispering invitations in languages you almost understand. A bronze plaque reads: *"Silence is the price of knowledge."*

Inside, towering bookshelves form corridors that vanish into darkness. A reception desk stands just past the threshold, covered in cobwebs. A leather satchel hangs on a coat hook by the door.

```
     ___________
    /           \
   /  ASHWORTH   \
  /   LIBRARY     \
 /    est. 1847    \
|    ___________    |
|   |           |   |
|   |  SILENCE  |   |
|   |  PLEASE   |   |
|   |___________|   |
|                   |
|   [door]  [door]  |
|___________________|
```

#### Action: take-satchel

- matches: ["take satchel", "grab bag", "pick up satchel", "get satchel", "take bag", "leather satchel"]
- add_item: satchel
- narration: "You take the leather satchel. It's old but sturdy — good for carrying things."

#### Action: enter-quietly

- matches: ["enter quietly", "sneak in", "go in", "enter", "tiptoe", "walk in", "proceed"]
- next_scene: main-hall
- set_flag: noise=quiet
- narration: "You step carefully over the threshold, placing each foot softly on the marble. The whispers grow louder for a moment, then settle into the background hum of a place that hasn't been disturbed in decades."

#### Action: call-out

- matches: ["hello", "call out", "shout", "yell", "is anyone here", "announce"]
- next_scene: main-hall
- set_flag: noise=moderate
- narration: "Your voice echoes through the foyer and deep into the library. Books rustle on distant shelves. That... may have been a mistake. Somewhere in the depths, something stirs."

#### Action: read-plaque

- matches: ["read plaque", "examine plaque", "look at plaque", "inspect"]
- set_flag: read_plaque
- narration: "The plaque reads: *'The Ashworth Library — est. 1847. Silence is the price of knowledge. Those who disturb the peace shall answer to the Keeper.'* Below, someone has scratched: *'Card catalog knows all.'*"

---

## Scene: main-hall

**The Main Hall**

A cavernous reading room stretches before you. Chandeliers hang motionless overhead, their candles long extinguished. Three wings branch off the main hall:

- **East Wing**: The Card Catalog — rows of wooden drawers stretching into shadow
- **North Wing**: The Reading Room — tables stacked with open books, as if readers simply vanished mid-sentence
- **West Wing**: The Restricted Section — blocked by a velvet rope and a sign: *"AUTHORIZED PERSONNEL ONLY"*

A candelabra on the nearest table still has matches beside it.

#### Action: light-candles

- matches: ["light candles", "use matches", "light candelabra", "take matches", "light"]
- add_item: lit_candelabra
- set_flag: noise=moderate
- narration: "You strike a match — it sounds like a gunshot in the silence. The candelabra flickers to life, casting warm light that pushes back the shadows. But the match sound echoed. You notice the air feels... watchful."

#### Action: go-east

- matches: ["east", "go east", "card catalog", "east wing", "catalog"]
- next_scene: card-catalog
- narration: "You head east toward the Card Catalog. Wooden drawers line the walls from floor to ceiling."

#### Action: go-north

- matches: ["north", "go north", "reading room", "north wing", "tables"]
- next_scene: reading-room
- narration: "You walk north into the Reading Room, your footsteps muffled by worn carpet."

#### Action: go-west

- matches: ["west", "go west", "restricted", "west wing", "restricted section"]
- next_scene: restricted-entrance
- narration: "You approach the Restricted Section. The velvet rope sways slightly, though there's no breeze."

---

## Scene: card-catalog

**The Card Catalog**

Thousands of wooden drawers fill the east wing, each labeled with tiny brass plates. The organization system is... unusual. Instead of Dewey Decimal, the drawers are sorted by emotion, dream, and memory. A drawer labeled **"FORBIDDEN"** has been pulled slightly open. Another labeled **"ESCAPE"** glows faintly.

#### Action: open-forbidden

- matches: ["open forbidden", "forbidden drawer", "check forbidden", "pull forbidden", "look at forbidden"]
- add_item: catalog_card_forbidden
- narration: "Inside the FORBIDDEN drawer, a single card reads: *'The Forbidden Tome of Ashworth — Location: Restricted Section, Vault B. Key required. See: Ghost Librarian.'* The card hums faintly in your hand."

#### Action: open-escape

- matches: ["open escape", "escape drawer", "check escape", "look at escape", "glowing drawer"]
- set_flag: knows_exit
- narration: "The ESCAPE drawer contains a floor plan of the library. There's a hidden exit behind the Restricted Section — through a service corridor marked 'Emergency Egress.' You memorize the route."

#### Action: search-drawers

- matches: ["search", "browse", "look around", "examine drawers", "open others", "explore"]
- set_flag: noise=moderate
- narration: "You rummage through drawers — MEMORY contains faded photographs, SORROW holds tear-stained letters, LAUGHTER is empty. The drawers rattle as you search. The sound carries."

#### Action: go-back

- matches: ["go back", "return", "main hall", "leave"]
- next_scene: main-hall
- narration: "You return to the main hall."

---

## Scene: reading-room

**The Reading Room**

Long oak tables fill the room, each covered with open books, half-written notes, and cold cups of tea. It looks like an entire reading room full of scholars vanished in an instant. One book lies open to a page about **binding rituals**. A scholar's journal sits at the nearest seat.

#### Action: read-binding

- matches: ["read book", "binding ritual", "open book", "read binding", "look at book"]
- set_flag: knows_binding
- add_item: binding_knowledge
- narration: "The book describes how the Ghost Librarian was bound to the library by a ritual involving three things: *silence, the Forbidden Tome, and speaking her name — Eleanor.* Knowing her name gives you power."

#### Action: read-journal

- matches: ["read journal", "journal", "scholar's journal", "examine journal"]
- set_flag: scholar_warning
- narration: "The last entry reads: *'Day 47. The Librarian grows more aggressive. She can hear a pin drop from three wings away. Jenkins tried to run — she caught him in the stacks. Must stay silent. Must find the Tome. Must end the curse.'* The entry ends mid-sentence."

#### Action: take-tea

- matches: ["drink tea", "take tea", "sip tea", "cup of tea"]
- narration: "The tea is ice cold and tastes of decades. Unpleasant, but oddly grounding."

#### Action: go-back

- matches: ["go back", "return", "main hall", "leave"]
- next_scene: main-hall
- narration: "You carefully leave the reading room, stepping over scattered papers."

---

## Scene: restricted-entrance

**Restricted Section Entrance**

The velvet rope blocks the entrance to the west wing. Beyond it, the shelves are caged in iron, the books chained to their places. A brass sign reads: *"Entry by permission of the Head Librarian only."*

The rope has a clasp — you could undo it, but it looks rigged with a small bell.

#### Action: undo-clasp-carefully

- matches: ["undo clasp", "carefully", "remove rope", "sneak past", "undo carefully", "open carefully"]
- next_scene: restricted-section
- narration: "You hold the bell still with one hand and undo the clasp with the other. The rope drops silently. You slip through."

#### Action: undo-clasp

- matches: ["go in", "enter", "push past", "open", "just go", "step over", "duck under"]
- set_flag: noise=loud
- next_scene: ghost-encounter
- narration: "You push past the rope and the bell jingles — a bright, clear sound that echoes through the entire library. The temperature plummets. *She's coming.*"

#### Action: go-back

- matches: ["go back", "return", "leave", "main hall"]
- next_scene: main-hall
- narration: "You leave the restricted section entrance."

---

## Scene: ghost-encounter

**The Ghost Librarian**

The air freezes. Books fly from shelves. A spectral figure materializes before you — the Ghost Librarian, her eyes burning with cold fury. She was beautiful once. Now she is terrifying. Her whisper cuts like ice:

*"SILENCE in the library."*

She reaches for you with translucent hands.

```
        .  *  .
     *  /|\ /|\  *
       / | X | \
      *  |/ \|  *
         /   \
        /  ?  \
       / SHHHH \
      /__________\
          |  |
          |  |
```

#### Action: speak-name

- matches: ["Eleanor", "say her name", "speak name", "say Eleanor", "name"]
- requires_flag: knows_binding
- next_scene: ghost-calmed
- narration: "You speak clearly: *'Eleanor.'* The ghost freezes. The fury drains from her face, replaced by shock, then sorrow. 'You... know my name?' she whispers."

#### Action: fight

- matches: ["fight", "attack", "hit", "punch", "swing"]
- health_change: -35
- narration: "Your hand passes through her and the cold burns like fire. She shrieks — the sound rattles every window in the library. You cannot fight a ghost."

#### Action: run

- matches: ["run", "flee", "escape", "hide"]
- health_change: -20
- next_scene: main-hall
- set_flag: noise=quiet
- narration: "You sprint back to the main hall as books hurl themselves at you. One catches your shoulder hard. The ghost doesn't follow past the restricted section entrance — but she's watching."

#### Action: be-silent

- matches: ["be quiet", "silence", "stop", "freeze", "shh", "stay still", "don't move"]
- next_scene: restricted-section
- health_change: -10
- set_flag: noise=quiet
- narration: "You freeze and hold your breath. The ghost studies you for an agonizing moment, then slowly fades. *'One warning,'* she hisses. The temperature rises. You're in the restricted section now — but she'll be less forgiving next time."

---

## Scene: ghost-calmed

**Eleanor**

The ghost hovers before you, no longer threatening. Tears of light stream down her spectral face.

*"I was the Head Librarian. I bound myself to protect the Forbidden Tome... but the ritual trapped me. I've been alone so long I forgot my own name."*

She extends a translucent hand. A ghostly key materializes.

*"Take this. Find the Tome in Vault B. Read the unbinding passage. Set us both free."*

#### Action: take-key

- matches: ["take key", "accept", "take it", "grab key", "accept key"]
- add_item: vault_key
- next_scene: restricted-section
- narration: "The ghost key becomes solid in your hand — ice cold but real. Eleanor smiles sadly and fades to a faint shimmer. You're in the restricted section."

#### Action: refuse

- matches: ["refuse", "no", "decline", "leave"]
- next_scene: main-hall
- narration: "Eleanor's face falls. She fades away without another word. The library grows colder."

---

## Scene: restricted-section

**The Restricted Section**

Iron-caged bookshelves line the walls, their contents chained in place. The books here pulse with energy — you can feel it through the floor. At the far end, a heavy iron door is marked **"VAULT B"**. The lock is ornate and old.

A service corridor branches off to the left — the emergency egress from the floor plan.

#### Action: open-vault

- matches: ["open vault", "use key", "unlock vault", "vault b", "unlock door", "open door"]
- requires_item: vault_key
- next_scene: vault
- narration: "The vault key slides into the ornate lock. The tumblers fall with a sound like distant bells. The iron door swings open."

#### Action: try-vault

- matches: ["try door", "open door", "push door", "check door"]
- narration: "The vault door is locked with an ornate mechanism. You'll need the right key."

#### Action: service-corridor

- matches: ["service corridor", "emergency exit", "egress", "escape", "leave library", "go left"]
- requires_flag: knows_exit
- next_scene: victory
- narration: "You slip into the service corridor and follow the route from the floor plan. A rusted door opens onto the moonlit grounds outside. You've escaped the library... but the curse remains. Eleanor is still trapped inside."

#### Action: go-back

- matches: ["go back", "return", "leave"]
- next_scene: main-hall
- narration: "You return to the main hall."

---

## Scene: vault

**Vault B**

A circular stone room. In the center, on a reading stand carved from a single piece of obsidian, lies **The Forbidden Tome of Ashworth**. It's bound in dark leather and clasped with silver. The air here is thick with power. Faint whispers emanate from the book itself.

The book's clasp has an inscription: *"To unbind the keeper, read the final passage aloud."*

#### Action: open-tome

- matches: ["open book", "open tome", "read", "unclasp", "open it", "read tome", "read book"]
- next_scene: final-choice
- narration: "You unclasp the silver binding. The book falls open to the final page. The text glows."

#### Action: take-tome

- matches: ["take book", "take tome", "steal", "grab", "pick up"]
- set_flag: noise=loud
- health_change: -25
- narration: "You try to lift the Tome from its stand. It shrieks — a sound like tearing metal. The vault shakes. The book is bound to the stand. It must be read here."

#### Action: go-back

- matches: ["go back", "leave", "return"]
- next_scene: restricted-section
- narration: "You step back from the vault, leaving the Tome on its stand."

---

## Scene: final-choice

**The Unbinding**

The Forbidden Tome's final page glows with golden text. You can feel the words pulling at reality. Eleanor shimmers into existence beside you, hope and fear warring on her spectral face.

The text reads: *"Speak these words to break the binding: 'By name I release you. Eleanor, you are free.'"*

Eleanor whispers: *"Please."*

#### Action: read-aloud

- matches: ["read aloud", "speak", "say the words", "read passage", "unbind", "free her", "Eleanor you are free", "release"]
- requires_flag: knows_binding
- next_scene: victory
- narration: "You read aloud: *'By name I release you. Eleanor, you are free.'* The Tome blazes with golden light. Eleanor gasps — color floods her spectral form for a single, radiant moment. 'Thank you,' she breathes, and dissolves into warm light that fills the library. The curse is broken. The whispers fall silent. The library is just a library again. You step outside into the dawn, the Forbidden Tome in your hands — no longer forbidden, no longer dangerous. Just a book."

#### Action: refuse

- matches: ["refuse", "don't read", "no", "keep power", "close book"]
- next_scene: dark-ending
- narration: "You close the Tome. Eleanor stares at you in disbelief as her form begins to fade. *'No... please...'* But you've made your choice."

---

## Scene: dark-ending

**The New Keeper**

Eleanor screams. The vault seals. The Tome's clasp snaps shut around your wrist, binding you to the reading stand. You feel the library's power flow into you — knowledge of every book, every word, every secret.

But you can't leave. You can never leave.

The library has a new keeper.

*Your health drains as the binding takes hold...*

- health_change: -100
- narration: "GAME OVER — You are now bound to the library for eternity. The curse continues."
