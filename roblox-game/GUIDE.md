# 🌙 Moonlight Critter Heist — complete guide

A ready-to-publish Roblox game in the "buy it on the conveyor, steal it from other bases" genre (the genre of *Steal a Brainrot*, one of the highest-earning Roblox games of 2025), with its **own twist** so it isn't a copy.

---

## 1. What the game is

**Core loop (easy to understand in 10 seconds — that's what makes these games go viral):**

1. Every player gets their own **base** (8 per server).
2. Cute **critters** walk down **Critter Road** in the middle of the map. Walk up and **buy** one before it leaves.
3. Critters sit on pedestals in your base and **earn cash every second**. Step on the green **💰 COLLECT** pad to collect.
4. Buy better critters → earn faster → buy even better critters.
5. **Steal** critters from other players' bases (hold **E**), then **run back to your base** before the owner tags you.
6. Defend your base with the **🔒 LOCK** button (45 s, 90 s cooldown).
7. **Rebirth** to reset with permanent bonuses (+50% income and +1 slot each time).

**What makes it unique:**

| Feature | Why it matters |
|---|---|
| 🌙 **Moon Raids** (every 8 min, 2 min long) | Night falls, **all base locks turn off**, glowing *Moonlit* critters (x3) and **Secret critters that only exist during raids** appear. Players stay online waiting for the next raid → longer sessions → more money. |
| 🧬 **Mutations**: Gold x2, Diamond x5, Moonlit x3, Rainbow x10 | Every critter can be a rare jackpot. Mutated critters cost less than they earn, so they feel like a steal. |
| 🍀 **Server Luck** (paid, for the WHOLE server) | One player pays and everyone gets 3x luck, with a server-wide shout-out. Social purchases sell very well. |
| 🛡️ **Raid Shield** (paid) | The only protection that works during a Moon Raid. Cheap impulse buy at the exact moment players are scared of losing things. |
| 👥 **Friend Boost** | +10% income for every friend in the same server (max +50%). Players invite friends, which is free advertising for you. |
| 😴 Offline earnings, 🎁 7-day daily streak | Players have a reason to come back every day (retention is what the Roblox algorithm rewards). |
| Sell critters (F) | Frees slots, keeps the economy moving. |

20 critters in 7 rarities: Common → Uncommon → Rare → Epic → Legendary → Mythic → **Secret**.

---

## 2. Open it in Roblox Studio (5 minutes)

### Easiest way: open the ready-made file
1. Install **Roblox Studio** (free): https://create.roblox.com
2. Double-click `MoonlightCritterHeist.rbxlx` (in this folder), or open it from *File → Open from File*.
3. Press **Play** ▶. The map, bases, conveyor and UI all build themselves from code.
4. To test with several players: *Test* tab → *Clients and Servers* → 2 or 3 players → *Start*. Try stealing!

### Pro way: live-sync code with Rojo (recommended if you keep editing)
1. Install Rojo: https://rojo.space/docs/v7/getting-started/installation/ (plus the Studio plugin).
2. In this folder run `rojo serve`, then click *Connect* in the Rojo plugin in Studio.
3. Edit the `.luau` files in `src/` with VS Code and changes appear in Studio instantly.
4. Rebuild the file anytime with `rojo build -o MoonlightCritterHeist.rbxlx`.

---

## 3. Publish the game

1. In Studio: *File → Publish to Roblox* → create a new experience. Name idea: **"Steal a Critter 🌙 Moon Raid"**. Use searchable words people already type into Roblox search.
2. *Home → Game Settings*:
   - **Security → Enable Studio Access to API Services = ON** (needed for saving).
   - **Places → Max players = 8** (one base per player; the code supports 8).
   - Genre: *Adventure* or *Simulator*; devices: enable Phone, Tablet and Console.
3. On https://create.roblox.com/dashboard/creations open your game → *Configure*:
   - Set it to **Public**.
   - Upload an **icon** (512×512) and **3+ thumbnails** (1920×1080). A big glowing critter + "STEAL!" text + bright colors gets clicks. Thumbnails and icon matter more than anything else for getting players.

---

## 4. Turn on monetization (this is how you earn Robux)

Creator Dashboard → your game → **Monetization**.

### a) Create the Game Passes (one-time purchases)
*Monetization → Passes → Create a Pass*. Create these 5, put each one **on sale**, and copy each **Pass ID**:

| Key in Config | Name | Suggested price |
|---|---|---|
| `DoubleCash` | 💸 2x Cash | 299 R$ |
| `VIP` | 👑 VIP | 199 R$ |
| `ExtraSlots` | 🧱 +4 Base Slots | 149 R$ |
| `AutoCollect` | 🤖 Auto Collect | 129 R$ |
| `FastThief` | 🥷 Fast Thief | 99 R$ |

### b) Create the Developer Products (can be bought again and again)
*Monetization → Developer Products → Create*. Copy each **Product ID**:

| Key in Config | Name | Suggested price |
|---|---|---|
| `CashSmall` | 💰 Cash Pouch | 25 R$ |
| `CashMedium` | 💰 Cash Sack | 99 R$ |
| `CashLarge` | 💰 Cash Vault | 349 R$ |
| `ServerLuck` | 🍀 Server Luck x3 | 149 R$ |
| `RaidShield` | 🛡️ Raid Shield | 49 R$ |
| `MythicEgg` | 🥚 Mythic Egg | 399 R$ |

### c) Paste the IDs
Open `src/shared/Config.luau` (or *ReplicatedStorage → Shared → Config* in Studio) and replace each `Id = 0` with your real ID. Also update `Price =` if you changed the price; it's only used for the label in the shop.
Then **publish again** (*File → Publish to Roblox*).

> Until an ID is set, the shop button for that item just shows "isn't set up yet". Nothing breaks.

### d) Free extra income
- **Premium Payouts**: you are paid automatically when Roblox Premium members play your game. Nothing to set up.
- **Rewarded video ads / Immersive Ads**: if your account is eligible, enable them under *Monetization → Ads*.

---

## 5. Getting players (the hard part)

A game earns nothing without players. What actually works:

1. **Thumbnails and icon.** Make 3–5 versions and test them (the dashboard has *Thumbnail personalization / A-B testing*).
2. **Ads**: *Creator Dashboard → Ads Manager*. Start small (for example 1,000–5,000 Robux) and watch the **click-through rate** and **average playtime**. If people leave in under 3 minutes, improve the game before spending more.
3. **TikTok / YouTube Shorts / Instagram Reels**, exactly like the videos you watched: post 1–3 clips per day of funny steals, Rainbow Secret critters and Moon Raid chaos. One viral clip can bring thousands of players.
4. **Update every week** (new critter, new mutation, new event) and put "UPDATE 🌙" in the game title. Roblox's algorithm likes games that update often and keep players for a long time.
5. Make a **Roblox group** and a **Discord** for update announcements and to bring players back.

---

## 6. How much money can this make? (honest numbers)

- Roblox keeps about 30% of every sale; you receive **~70% of the Robux**.
- **DevEx** (converting Robux to real money) pays roughly **$0.0035–$0.0038 per earned Robux**, so **100,000 Robux ≈ $350–$380**. Roblox changes the rate and eligibility rules (minimum earned Robux, age, verified account, tax forms), so check the official page before you count on it: https://create.roblox.com/docs/production/monetization/developer-exchange
- Rough idea: a game averaging **500 players online at once** with decent monetization can earn **$3,000–$10,000+ per month**. Top games in this genre earn millions. **Most new games get very few players**, so treat the first version as a launch, then improve it based on the numbers (retention, playtime, conversion) in the Creator Dashboard Analytics.

Nobody can guarantee income. The games that win are the ones whose creators keep **posting clips, buying a few ads, and updating every week**.

---

## 7. Where to tweak things

Everything is in `src/shared/Config.luau` and `src/shared/Critters.luau`:

| Want to… | Change |
|---|---|
| Make raids more/less frequent | `Config.MoonRaid.Interval` / `Duration` |
| Make the game easier/harder | `StartingCash`, critter `Price`/`Income`, `Rebirth.BaseCost` |
| Make rare critters rarer | `Weight` in `Critters.Rarities` |
| Add a new critter | Add a line to `Critters.List` (Id, Rarity, Price, Income, Size, Color, Accent) |
| Test passes in Studio | `Config.StudioGrantAllPasses = true` (set it back to `false` before publishing!) |

### Code map
```
src/shared/   Config, Critters (data + rolls), Format, Remotes
src/server/   Main (entry point)
              DataService        saving with retries, session locks, autosave
              MapBuilder         builds the map, road, lamps, 8 bases
              CritterFactory     builds critter models + name tags
              PlotService        bases, pedestals, income, collect, sell, lock, shield
              ConveyorService    Critter Road spawning and buying
              StealService       stealing, carrying, catching thieves
              EventService       Moon Raid day/night cycle
              MonetizationService game passes + developer products (safe receipts)
              ProgressionService rebirth, daily streak, offline earnings, friend boost
src/client/   Main (prompts, rainbow effect, VIP chat tag), HUD (all UI)
```

### Next upgrades that would make it look and earn even better
- Replace the part-built critters with **real meshes** (Toolbox or a 3D artist), keeping the same names in `Critters.luau`.
- Add **sounds** (buy, steal, raid siren) from the Creator Store.
- Add a **global leaderboard** (OrderedDataStore) for most steals and richest player.
- Add **limited-time critters** for holidays to drive spending spikes.
