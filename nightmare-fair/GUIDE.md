# 🎪 Nightmare Fair — Killer vs Survivors

An asymmetric horror game for Roblox, in the style of Dead by Daylight, set in a huge abandoned carnival at night.
**1 Killer vs up to 11 Survivors.** Survivors light Ritual Pumpkins to power the exit gates and escape. The Killer hunts them down and locks them in Crow Cages.

---

## 1. How a match plays

1. **Lobby** (25 s). Alone in a server? An **AI Ringmaster** hunts you, so nobody ever waits for players. Everyone waits in the carnival lobby. One player is picked as the **Killer**. Higher **Killer Chance** means better odds, and it goes up by 1 every round you're not the killer.
2. **The hunt** (7 min). Survivors spawn around the map. The killer spawns in the middle and is frozen for 10 seconds.
3. **Survivors** light **5 of the 7 Ritual Pumpkins**. Stand next to one, press E, and hit the **skill checks** (press Space when the needle is in the zone). A miss makes noise the killer can see.
4. **Killer hits:** Healthy → Injured (with a speed boost to get away) → **Downed**.
5. The killer **picks up** downed survivors and puts them in a **Crow Cage**. Teammates can **rescue** them. The first caging lasts 60 s, the second 40 s, and the third eliminates them.
6. Survivors **drop pallets** to block the killer. Dropping one on the killer **stuns** them and frees anyone they're carrying.
7. With 5 pumpkins lit, the **exit gates get power**. Hold E on a gate switch (8 s), run through, and escape. The fair collapses 2 minutes later.
8. **Eliminated survivors become Ghosts.** They can ring the 🔔 **Ghost Bells** around the map to reveal the killer's position to everyone for 6 s. Dead players keep playing, so they don't leave the server.

### Killers
| Killer | Power (Q) | How to unlock |
|---|---|---|
| 🎩 **The Ringmaster** | Bear traps: survivors who step in are stuck for 4 s and revealed | Free |
| 🔪 **The Butcher** | Charge: 1.2 s dash that injures whoever he slams into | 750 🎟️ |
| 👻 **The Phantom** | Vanish: 6 s of invisibility and extra speed (can't attack while hidden) | 2,500 🎟️ or a 399 R$ pass |

### Controls
| | Survivor | Killer |
|---|---|---|
| Move / jump | WASD / Space | WASD / Space |
| Interact | **E** (light pumpkin, drop pallet, heal, rescue, open gate) | **E** (pick up, cage, break pallet) |
| Skill check | **Space** or the HIT button | — |
| Attack | — | **Left click** / ATTACK button |
| Power | — | **Q** / POWER button |

Phones get on-screen buttons automatically.

---

## 2. The map (500 × 500 studs)

Built entirely from code, with no uploaded assets. About **3,900 parts and 110+ lights**, split into DBD-style zones:

| Zone | What's there |
|---|---|
| Center: **Midway** | Spinning carousel, 20 game booths (Ring Toss, Whack-a-Ghoul…), popcorn carts, string lights |
| North: **Wheel of Woe** | Giant spinning Ferris wheel, Bumper Scars arena |
| North-east: **Ride Graveyard** | Piles of wrecked cars, fallen teacups |
| North-west: **Corn Maze** | Tall corn rows with a hidden Ritual Pumpkin |
| East: **Big Top** | Huge striped circus tent you can run through, with a pumpkin in the ring |
| West: **Haunted Manor** | Multi-room house with a pumpkin inside, plus a graveyard with coffins |
| South-west: **Farm** | Red barn with a hay loft, tractor, scarecrows, pumpkin patch |
| South: **Main Entrance** | Entrance arch, ticket booths, the killer shack loop |
| South-east: **Lake** | Lake with dock and boat, water tower with a red beacon |

Plus **22 pallet loops**, L-wall loops, 9 Crow Cages, 4 Ghost Bells, 2 exit gates, and hundreds of hay bales, crates, barrels, pumpkin piles, scarecrows, tombstones, rocks and dead trees. A foggy forest surrounds the fence.

---

## 3. Everything players can buy

### 🎁 Bundles (developer products)
| Key | Contents | Price |
|---|---|---|
| `PackStarter` | Top Hat, Candy Corn Trail, 1,500 🎟️, +3 Killer Chance (one-time) | 49 R$ |
| `PackHalloween` | Pumpkin Head, Witch Hat, Hellfire Trail, 2,000 🎟️ | 199 R$ |
| `PackKiller` | Golden Ringmaster, Inferno Butcher, Toxic Trail, 1,000 🎟️, +10 Killer Chance | 249 R$ |
| `PackLegendary` | Crown, Halo, Bat Wings, Rainbow Trail, Void Phantom, 5,000 🎟️, +10 Killer Chance | 499 R$ |

### ⚡ Boosts (developer products)
| Key | What | Price |
|---|---|---|
| `KillerChance` | +5 Killer Chance (people *love* buying this) | 49 R$ |
| `SelfRescue` | Break Out of a Crow Cage (saved for later if you're not caged) | 35 R$ |
| `TicketsSmall` / `TicketsLarge` / `TicketsHuge` | 500 / 3,000 / 12,000 tickets | 25 / 99 / 299 R$ |

### ⭐ Game passes
| Key | What | Price |
|---|---|---|
| `Phantom` | Unlock The Phantom killer | 399 R$ |
| `DoubleTickets` | 2x tickets forever | 299 R$ |
| `VIP` | +25% tickets, +1 extra Killer Chance every round, gold [VIP] chat tag | 249 R$ |

### 🎭 Cosmetics (22 items)
- **10 hats & masks:** Cat Ears, Top Hat, Candle Hat, Devil Horns, Witch Hat, Skull Mask, Pumpkin Head, Bat Wings, Halo, Crown.
- **6 trails:** Candy Corn, Ghostly, Toxic, Blood, Hellfire, Rainbow.
- **6 killer skins:** Bloody/Golden Ringmaster, Toxic/Inferno Butcher, Crimson/Void Phantom.
- Some can be bought with tickets. The rarest only come from **bundles** or the **📦 Mystery Crate** (600 🎟️). The crate shows its odds in the shop (Common 55%, Rare 30%, Epic 12%, Legendary 3%), as Roblox requires for random items. Duplicates refund 250 🎟️.

**How the money loop works:** tickets come from playing (lighting pumpkins, rescues, stuns, escapes, kills). Players want killers, skins and crates, so they either grind or buy ticket packs and bundles. Killer Chance is the most-bought item in games like this because everyone wants to be the killer.

### Setting up the IDs
1. Creator Dashboard → your game → **Monetization** → create the **3 passes** and **9 developer products** above.
2. Paste each ID into `src/shared/Config.luau` (in Studio: *ReplicatedStorage → Shared → Config*), replacing every `Id = 0`.
3. Publish again.

---

## 4. Test and publish

1. Roblox Studio → **File → Open from File** → `NightmareFair.rbxlx`.
2. Press **Play** to try it alone: the **AI Ringmaster** hunts you. For the real killer-vs-survivors mode use **Test → Clients and Servers → 2 or 3 players → Start**; one of them becomes the killer.
3. **Game Settings**: Security → **Enable Studio Access to API Services** (for saving). Places → **Max Players 12**. Genre **Horror**. Fill in the age questionnaire.
4. **File → Publish to Roblox**, then set it to **Public**.

**Title for search:** `🎪 Nightmare Fair [KILLER vs SURVIVORS] 🎃 Halloween`
**Description:** *"1 KILLER vs 11 SURVIVORS in a haunted carnival! Light the Ritual Pumpkins, drop pallets, rescue friends from Crow Cages and ESCAPE, or become The Ringmaster, The Butcher or The Phantom and hunt them all. Ghosts ring bells to help! #horror #killer #survivors #halloween #dbd"*

---

## 5. Music and sounds (original, made for this game)

The `audio/` folder has 11 original sounds composed for Nightmare Fair (no copyrighted music):

| File | Used for |
|---|---|
| `lobby_music.ogg` | Lobby: a broken carnival music-box waltz |
| `ambience.ogg` | During a match: wind, low drone, distant metal creaks |
| `terror_heartbeat.ogg` | Survivors: heartbeat that grows and speeds up as the killer gets closer |
| `chase_music.ogg` | Chase music when the killer is right behind you |
| `sfx_skillcheck.ogg`, `sfx_great.ogg` | Skill check warning and GREAT |
| `sfx_pumpkin_lit.ogg`, `sfx_gate_alarm.ogg` | A pumpkin is lit / the exit gates get power |
| `sfx_hit.ogg`, `sfx_pallet.ogg`, `sfx_cage_scream.ogg` | Killer hit, pallet slam, Crow Cage scream (heard in 3D) |

**To turn them on:** Creator Hub → **Development Items → Audio → Import** each file, copy its ID, and paste it into `Config.Sounds` in `Config.luau`. Roblox may limit how many audio files you can upload per month; upload the first four (the music) first.

## 6. Real 3D killer looks

Killers can wear real 3D items from the Roblox Marketplace. Find a mask, coat or hat on roblox.com/catalog, copy the number from the web address, and paste it into `Config.KillerLooks` (for example `Face = "1234567"`). When a killer has items set, the built-in part mask is removed and only the weapon stays. The AI killer uses the Ringmaster's look.

## 7. Honest notes

- The game was checked with a linter and the map builder was run in a Roblox emulator (no crashes, 3,916 parts). It has **not** been playtested inside real Roblox yet, so test a few rounds with friends before advertising.
- It has **no sounds yet**. Add a heartbeat, chase music, a cage scream and pallet crashes from the Creator Store. Sound matters a lot in horror.
- Killers use your normal avatar plus a mask and weapon built from parts. For an even scarier look, add mesh costumes from the Creator Store later.
- Roblox's rules on paid random items change. Keep the crate odds visible and check the current policy before publishing.

### Code map
```
src/shared/   Config (balance, passes, products), Cosmetics (items, bundles, crate), Format, Remotes
src/server/   Main             entry point
              Props            40+ prop builders (rides, tents, booths, barn, cars, corn, cages, gates...)
              MapBuilder       lays out the 500x500 map, zones, loops and clutter
              Match            shared match state & helpers
              SurvivorService  health states, healing, carry, cages, rescue, ghosts, escape
              KillerService    costumes & skins, attacks, the 3 powers, pallets, stuns
              ObjectiveService pumpkins + skill checks, exit gates, ghost bells
              RoundService     lobby → killer pick → match → results
              CosmeticService  hats, trails, crates, bundles
              DataService      saving (retries, session lock, autosave)
              MonetizationService passes + products (safe receipts)
src/client/   Main, Controls (killer input), Effects (spinning rides, prompts, pings), HUD (all UI)
```
