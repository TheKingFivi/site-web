# 🎃 Survive The Hollow — Halloween horror survival

A co-op horror survival game for Roblox, built for the Halloween season.

**The pitch:** 1–12 players huddle around a dying bonfire in a foggy haunted village. A pumpkin-headed scarecrow, **The Hollow**, hunts anyone who leaves the light. Gather logs, keep the fire burning, and survive **5 nights**. Night 5 is a **Blood Moon** with *two* of them.

---

## 1. What makes it different

| Feature | Why players love it (and stay longer) |
|---|---|
| 🔥 **Light is life** | The monster can't enter the bonfire's light, but the fire shrinks every second. Someone *has* to go into the dark for logs. This creates tension without anyone having to explain it. |
| 🔦 **Your lantern is your weapon** | Shine your lantern on The Hollow for about a second and it flees. The battery drains, and it recharges by the fire. |
| 🎃 **Trick-or-treat doors** | Knock on any house: candy, batteries or a log... or a **TRICK** that sends The Hollow straight at you with a jumpscare. Very clip-friendly. |
| 🆘 **Down, not dead** | Getting caught knocks you down. Teammates hold E to revive you before you bleed out (30 s). |
| 🩸 **Blood Moon finale** | Night 5 turns everything red and spawns two monsters. Players come back to beat it. |
| 👻 **Haunt a Player** (paid) | Pay to send The Hollow after a friend for 20 seconds. Troll purchases like this sell well and spread through videos. |
| ☀️ **Daylight** (paid, whole server) | 30 seconds of sunlight: the monster hides and everyone loots safely, with a server shout-out for the buyer. |
| 📡 Danger vignette + radar | The screen edges pulse red as it gets close. The Radar pass shows its exact direction. |

**Progression:** candy is earned from pickups, surviving nights, reviving teammates, delivering logs and scaring the monster. It buys permanent upgrades (lantern range, battery size, stamina), so players have a reason to come back.

---

## 2. Play it in Roblox Studio

1. Open **Roblox Studio** → **File → Open from File** → `SurviveTheHollow.rbxlx`.
2. Press **▶ Play**. After a 20-second intermission, night falls.
3. To test with friends: **Test** tab → **Clients and Servers** → 2–3 players → **Start**.

### Controls
| Key | Action |
|---|---|
| WASD / Space | Move / jump |
| **Shift** (hold) | Sprint (uses stamina) |
| **F** | Lantern on/off. It points where your camera looks. |
| **E** (hold) | Knock on doors, revive teammates |
| Phone | On-screen **RUN** and **LIGHT** buttons appear automatically |

### How to survive
1. Stay inside the **orange glowing circle**. The Hollow can't get you there.
2. Touch **logs** (brown, glowing) and carry them back to the fire. That grows the safe circle.
3. When The Hollow comes at you, **turn your camera toward it and turn your lantern on**. Hold the light on it until it runs away.
4. If a teammate goes down, **hold E** on them to revive them.
5. Survive until the timer runs out. 5 nights = you escape and get a big candy reward.

---

## 3. Publish it (before Halloween!)

1. **File → Publish to Roblox** → create a new experience.
2. **Game Settings**:
   - **Security → Enable Studio Access to API Services: ON** (needed for saving).
   - **Places → Max players: 12**.
   - Turn on Phone, Tablet and Console.
3. **Name and description matter for search.** Use the words people type in October:
   - Title idea: **`🎃 Survive The Hollow [HALLOWEEN] Horror`**
   - Description: *"Survive 5 nights in a haunted village! Keep the bonfire burning, scare off The Hollow with your lantern, trick-or-treat at haunted houses, and survive the BLOOD MOON. Play with friends! #halloween #horror #survival #scary #nights"*
   - Genre: **Horror**. Make sure the age guidelines questionnaire is filled in.
4. **Icon and thumbnails**: the pumpkin-head monster's glowing face up close in the dark, with big text like **"SURVIVE 5 NIGHTS"** or **"DON'T LEAVE THE LIGHT"**. Upload 3–5 and use thumbnail A/B testing.

---

## 4. Turn on monetization

Creator Dashboard → your game → **Monetization**.

### Game passes (copy each Pass ID)
| Key in Config | Name | Suggested price |
|---|---|---|
| `InfiniteBattery` | 🔦 Infinite Battery | 249 R$ |
| `SecondWind` | 💖 Second Wind | 199 R$ |
| `DoubleCandy` | 🍬 2x Candy | 299 R$ |
| `MonsterRadar` | 📡 Monster Radar | 149 R$ |
| `VIP` | 👑 VIP | 199 R$ |

### Developer products (copy each Product ID)
| Key in Config | Name | Suggested price |
|---|---|---|
| `SelfRevive` | 💖 Revive | 25 R$ |
| `BonfireRefill` | 🔥 Refill Bonfire | 19 R$ |
| `ServerDaylight` | ☀️ Daylight | 99 R$ |
| `HauntPlayer` | 👻 Haunt a Player | 49 R$ |
| `CandySmall` | 🍬 Candy Bag | 25 R$ |
| `CandyLarge` | 🍬 Candy Bucket | 99 R$ |
| `CandyHuge` | 🍬 Candy Cauldron | 299 R$ |

Paste the IDs into `src/shared/Config.luau` (in Studio: *ReplicatedStorage → Shared → Config*), replacing each `Id = 0`. Then publish again.

**Why these sell:** the Revive button appears on the "YOU'RE DOWN" screen at the most emotional moment. Daylight and Bonfire Refill are bought to save the whole team, and everyone sees the buyer's name. Haunt is a social troll. If someone buys a Revive when they don't need it, it's saved as a token, so they never waste Robux.

---

## 5. Getting players (Halloween is the window)

- **Publish as early as possible.** Halloween searches peak in the last 2 weeks of October.
- Post short clips every day: jumpscares, "TRICK!" moments, Blood Moon escapes, someone getting haunted by a friend. Use #roblox #robloxhorror #halloween.
- Run a small **Ads Manager** campaign with your best thumbnail and watch the **average playtime**. If it's under ~5 minutes, improve the first night before spending more.
- After Halloween, the game still works as an all-year horror game. Rename the event and keep updating.

---

## 6. Tweaking

Everything is in `src/shared/Config.luau`:

| Want to… | Change |
|---|---|
| Make it scarier/harder | `Monster.BaseSpeed`, `Monster.SpeedPerNight`, `Bonfire.DrainPerSec` |
| Make it easier | `Bonfire.LogFuel`, `Flashlight.BaseBattery`, `Monster.StunNeeded` (lower = faster scare) |
| Shorter/longer nights | `NightLength` |
| More candy/logs on the map | `Pickups` |
| Test passes in Studio | `StudioGrantAllPasses = true` (set back to `false` before publishing!) |

### Code map
```
src/shared/   Config, Format, Remotes
src/server/   Main                entry point
              DataService         saving (retries, session lock, autosave)
              MapBuilder, World   haunted village, bonfire fuel and safe zone
              MonsterService      The Hollow: pathfinding hunt, light stun, catching players
              PlayerService       lantern & battery, downed/revive/death, upgrades
              PickupService       candy, batteries, logs, trick-or-treat doors
              RoundService        intermission → 5 nights → escape / game over, lighting moods
              MonetizationService passes + products (safe receipt handling)
src/client/   Main, Controls (sprint, lantern, mobile buttons), HUD (all UI, jumpscares, radar)
```

### Easy upgrades for later
- Add **sounds** from the Creator Store: heartbeat when close, a scream on jumpscare, crackling fire, wind. Sound is the biggest single boost to horror.
- Swap the part-built monster for a **mesh** from the Creator Store, keeping the model name "The Hollow".
- Add more monsters for later updates (a Witch on night 3, Ghosts that turn off lanterns).
