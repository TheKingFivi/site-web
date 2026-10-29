# 🚆 Frostline Checkpoint: anomaly inspection horror (1–4 players)

You work the night shift at a snowy border checkpoint. A night train is boarding and every passenger has to pass your desk.
Check their **passport, ticket, luggage, skeleton, temperature, fingerprints, eyes and brain**, then stamp **APPROVE** or **DENY**.
Some passengers are **not human**. Let one board and the power goes out at the end of your shift, and *it* comes back for you.

This is the same kind of game as "Airport Security (Anomaly)": an inspection job with rules that change every shift and monsters hidden among normal people.
All of the code, art, map and sounds here were made from scratch for this game.

---

## 1. How it plays

### The lobby (like your screenshots)
- Players spawn in the snowy plaza outside **Frostline Central**.
- Every player has a **"Shift N" badge** over their head showing their avatar headshot.
- **Step into one of the 4 glowing zones.** The first player in a zone gets the **CREATE PARTY** panel (party size 1–4, *Friends Only*, CREATE PARTY →).
  - The board above the zone shows `2/4 · STARTING IN 12`.
  - Other players walk in to join.
  - The countdown jumps to 3 seconds when the party is full.
- Lobby buttons: **REWARDS** (daily streak, 7 days), **INVITE** (Roblox invite friends), **SHOP**, **SKINS**, and a wobbling **LIMITED HALLOWEEN** button.
- Bottom left: 🍬 Candy and 💵 Cash with **+** buttons that open the shop.
- **Halloween Skins** stand on glowing orange pedestals: Plague Doctor, Pumpkin Conductor, Witch Medic, Inspector Dracul and Frost Wraith, all bought with Candy.
- **Officer Uniforms** stand on cyan pedestals: Night Watch, Arctic Patrol, Crimson Chief and Golden Inspector, all bought with Cash.
- Walk up to any pedestal and press E to open the skin shop.

### A shift
Each party gets its **own station**. Each player runs **their own lane** (Lane 1–4) at a desk in the checkpoint hall.

1. A passenger walks in from the street and puts their suitcase on the **X-ray belt**. The bag really rides through the tunnel.
2. They walk through the **body scanner arch**, stop and **raise their arms**, then step up to your counter and **hand over their passport**. They say a line in a speech bubble.
3. **[E] Take ID** from the tray. The passport and ticket open, with a live 3D **photo** of the passenger.
4. Inspect them with the tools on your desk:

| Tool | Key | Unlocks | What it reveals |
|---|---|---|---|
| Passport & Ticket | E (tray) | Shift 1 | Expired passport, name typos, wrong destination or night, **photo doesn't match** (black eyes, wrong hair, too-wide smile) |
| Rulebook | R | Shift 1 | Tonight's rules (they change every shift) |
| X-Ray | X | Shift 2 | Forbidden items (the list changes), **jars of teeth, ice that never melts, a beating heart...** |
| Body Scan | B | Shift 3 | Missing skeletons, extra ribs, arms that are far too long |
| CCTV | C | Shift 4 | The camera shows what it **really** looks like |
| Thermal | T | Shift 5 | Fever (deny) or **2–11 °C body temperature** (not human) |
| **Interrogation room** | Q (red phone) | Shift 6 | Sends the suspect to *Interrogation Room N* in the west wing. Follow the ⬇ ROOM marker. |
| Lie detector | E (in room) | Shift 6 | Ask 3 questions. The polygraph spikes on lies, and some of them only repeat your question back... |
| Fingerprints | T (in room) | Shift 7 | The scanned print must match the print pattern in the passport (or there's no print at all) |
| Eye Exam | Y (in room) | Shift 8 | Shine a light: human pupils shrink. No pupils, slits or glowing eyes mean NOT human. |
| Brain Scan | B (in room) | Shift 9 | A human brain shows two independently active halves. Flat, mirrored or static means NOT human. |

5. Stamp **APPROVE (F)** or **DENY (G)** at your desk, in the interrogation room, or with the on-screen buttons.
6. Approved passengers walk out to the **train on Platform 3**. Denied ones walk back out into the snow.

- **Mistakes:**
  - Wrongly denying an honest traveller, or approving a rule-breaker, is a **strike**.
  - 3 strikes and **you're fired** (the Second Chance pass gives 4).
  - Each mistake raises your **CRASH OUT** meter. At 100% your screen drains of color and blurs, and you hear whispers. Drink coffee in the break room to calm down.
- **Approving a monster:** you get no warning, just whispers. When all lanes are done:
  - **⚠ POWER FAILURE.** The lights die, the red emergency lights come on and the chase music starts.
  - The things you approved climb out of the train (one per anomaly, up to 3).
  - They hunt you with pathfinding AI. Your heartbeat gets louder and faster the closer they are.
- **Surviving:**
  - **Hide in lockers**, found in the break room, storage, the fuse room and the corridor.
  - **Tase** the monster to stun it (you can also tase your coworkers 😈).
  - Restore the **3 breakers**: A in the fuse room, B in storage, C in the hall by the platform door. Each is a 3-second hold.
  - Get caught and you get a **jumpscare**, then wake up in the break room.
  - If everyone is down at once, or the 2-minute timer runs out, **the station is lost**.
- **Results:** a shift report shows every passenger, what they really were, the pay you earned, and Candy. Pass the shift to unlock the next one.

### The station map
- **Main hall:** 4 inspection lanes. Each has a counter with a glass partition, an ID tray, a service bell, stamps, monitors, a CCTV wall screen, an X-ray conveyor, a scanner arch, queue ropes and a lane sign showing `LANE 2 · 04 CHECK-INS LEFT`.
- Around the hall: waiting seats, a departure board ("NIGHT TRAIN 03:00 → ???"), posters ("THEY LOOK LIKE US"), Halloween garlands and pumpkins, a vending machine and plants.
- **Staff corridor and back rooms:**
  - **Break room:** coffee machine, time clock, sofa, TV, fridge, lockers.
  - **Storage:** shelves of boxes, lockers, breaker B.
  - **Fuse room:** panels, pipes, breaker A.
- **Interrogation wing:** 4 rooms, each with a one-way mirror, a hanging lamp, a metal table, the suspect's chair with a **brain-scanner helmet**, a polygraph, a fingerprint reader, an eye-exam lamp, a neuro-scan wall screen and stamps.
- **Platform 3:** a 3-carriage night train with lit windows, a canopy, lamps, rails, falling snow and a pine forest.

---

## 2. Making money

### Game passes (create these in the Creator Dashboard)
| Key | What | Price |
|---|---|---|
| `AnomalyRadar` | 📡 3 times per shift, tells you which tool will expose the passenger | 299 R$ |
| `DoublePay` | 💰 2x pay forever | 249 R$ |
| `ExtraStrike` | 🛡️ One extra mistake allowed every shift | 199 R$ |
| `VIP` | 👑 +25% pay and Candy, gold name, **double daily rewards** | 249 R$ |

### Developer products
| Key | What | Price |
|---|---|---|
| `Hint` | 🔍 "Is this passenger human?" (saved for later if no passenger) | 15 R$ |
| `Revive` | ⚡ Get up instantly when knocked out (saved and auto-used if bought early) | 25 R$ |
| `PowerSurge` | 🔋 Instantly restore a breaker during a blackout | 49 R$ |
| `CandySmall` / `CandyLarge` | 🍬 300 / 1,500 Candy (Halloween skins) | 49 / 199 R$ |
| `CashSmall` / `CashLarge` | 💵 $500 / $3,000 | 25 / 99 R$ |

**Why people pay:**
- The game gets hard fast and the monsters are scary, so Hints, Revives and the Radar sell during the panic.
- Halloween skins are *limited* and cost Candy, which the Candy packs speed up.
- The **daily streak** brings players back every day.

### Setting up the IDs
1. Creator Dashboard → your experience → **Monetization** → create the 4 passes and 7 products above.
2. Open `src/shared/Config.luau` (in Studio: *ReplicatedStorage → Shared → Config*) and replace every `Id = 0` with the real number.
3. Publish again. Until an ID is filled in, its shop button says "not set up yet".

---

## 3. Sounds (original, made for this game)

`audio/` has 22 sound files, all synthesized from scratch (no copyrighted material):

| File | Used for |
|---|---|
| `MonsterScreech.ogg` | The shriek when a monster climbs out of the train (3D) |
| `MonsterGrowl.ogg`, `MonsterBreath.ogg`, `MonsterSteps.ogg` | Loop on the monster in 3D: growl, rattling breath and heavy steps with claws clicking on tile. You hear it coming from inside your locker. |
| `Jumpscare.ogg` | Boom, shriek and metal scrape when you're caught |
| `Heartbeat.ogg` | Gets louder and faster the closer a monster is |
| `ChaseMusic.ogg` | Blackout music: pounding drums and dissonant strings |
| `Whispers.ogg` | When you approve something wrong, or your CRASH OUT meter is high |
| `Ambience.ogg` | Fluorescent hum, wind, distant creaks and train rumble |
| `LobbyMusic.ogg` | A lullaby music box that slowly goes out of tune |
| `Coffee.ogg` | Pour, slurp, "ahh" |
| `PowerDown.ogg`, `Breaker.ogg` | Lights dying / breaker clunk |
| `Taser.ogg`, `Locker.ogg`, `TrainHorn.ogg`, `Stamp.ogg`, `Correct.ogg`, `Buzzer.ogg`, `Bell.ogg`, `Paper.ogg`, `Scanner.ogg` | Station effects |

**To turn them on:**
1. Creator Hub → **Development Items → Audio → Import** each file.
2. Copy each file's ID into `Config.Sounds` (each file name matches a key).

Roblox limits audio uploads per month, so upload these first: MonsterScreech, Jumpscare, ChaseMusic, Heartbeat, Ambience, LobbyMusic.

**Want even more realistic sounds?** The Creator Store (Toolbox → Audio) has thousands of free, licensed horror sounds made by Roblox and verified creators. Search "screech", "monster growl" or "jumpscare", copy an ID and paste it into the same `Config.Sounds` slot. Never upload sounds you don't own.

---

## 4. Animations and real 3D characters

- Passengers and monsters are **real R15 Roblox characters**:
  - Built with HumanoidDescription.
  - Walk and idle animations play through the Animator.
  - Poses (arms up in the scanner, handing over the passport, placing the bag) are made by moving their shoulder joints.
- **Custom animations:**
  1. Make them in Studio's **Animation Editor** or **Moon Animator**, which runs on your PC.
  2. Publish them.
  3. Paste the IDs into `Config.Animations`: PassengerWalk, PassengerIdle, PassengerHandOver, PassengerPlaceBag, PassengerScanPose, MonsterRun, MonsterIdle and MonsterAttack.
  4. The game uses them automatically.
- **Real clothes and hair:** paste Marketplace catalog IDs into `Config.PassengerLooks` (Hair, Shirts, Pants, Faces). Every passenger then picks randomly from your lists.

---

## 5. Test and publish

1. Roblox Studio → **File → Open from File** → `FrostlineCheckpoint.rbxlx`.
2. Press **Play**, walk into a glowing zone, choose party size **1** and CREATE PARTY.
   - To test co-op: **Test → Clients and Servers → 2 players**.
   - Want to try later shifts quickly? Set `Config.StudioGrantAllPasses = true` to test the passes.
3. **Game Settings**:
   - Security → **Enable Studio Access to API Services** (for saving).
   - Places → **Max Players 24** (up to 4 parties of 4 plus people in the lobby).
   - Genre **Horror**. Fill in the questionnaire.
4. **File → Publish to Roblox**, then set it to **Public**.
5. Upload `marketing/icon.png` as the icon and `marketing/thumb1-3.png` as thumbnails.

**Title:** `🚆 Frostline Checkpoint [ANOMALY] 🎃`
**Description:** *"Work the night shift at a frozen border checkpoint. Check passports, X-ray luggage, scan skeletons, watch the cameras and interrogate suspects with a lie detector, fingerprints, eye exams and brain scans. Deny anyone suspicious, but don't send away the innocent! Some passengers are NOT human... and if one gets on the train, the lights go out. Play solo or with up to 4 friends. Hide in lockers. Tase the monsters. Tase your coworkers. 🎃 Limited Halloween skins!"*

---

## 6. Honest notes

- **What was checked:**
  - Linted (0 warnings).
  - The lobby and station builders were run in a Roblox emulator: 1,290 lobby parts and about 1,700 per station, no errors.
  - Every passenger walking route was collision-checked against the map.
  - The passenger generator was run 27,000 times: every anomaly is catchable with the tools you have that shift, and the right answer is always consistent.
- **Not yet tested in real Roblox:** the code hasn't been play-tested there. Test a few shifts alone and with a friend before advertising, and send me any red errors from the Output window.
- **Animations:** the characters use Roblox's default walk, idle and run animations plus joint poses. For cinematic animations, make them in the Animation Editor or Moon Animator (both run on your computer) and paste the IDs into Config.
- **Copying:** this is the same *type* of game as Airport Security (Anomaly), but with its own setting, art, code and sounds. Don't copy their name, logo or images.

### Code map
```
src/shared/  Config (balance, passes, products, skins, sounds, animations), Passengers (generator + rules + judge),
             Format, Remotes
src/server/  Main               entry point, lighting, remotes
             LobbyBuilder       snowy plaza, party pads, skin pedestals, shop, daily board
             StationBuilder     4-lane checkpoint, back rooms, interrogation wing, platform + train
             Build              part helpers
             NPC                R15 passengers/monsters, animations, poses, suitcases, speech
             SkinLook           part-built officer skins (also on lobby mannequins)
             PartyService       zones → create party → countdown → own station
             Run                a shift: passengers, tools, interrogation, verdicts, strikes, blackout, monster AI, taser, pay
             PlayerService      "Shift N" badges, lockers, skins, daily rewards
             DataService        saving (session lock, retries, autosave)
             MonetizationService passes + products (safe receipts), hint, radar
src/client/  Main, HUD (all screens), Inspect (tool panels), Effects (prompts, bubbles, blackout, jumpscare...), Audio, UI
audio/       22 original .ogg sounds
marketing/   icon + 3 thumbnails
```
