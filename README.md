# Classic Profession CDs

Free, open-source World of Warcraft **Classic Era** add-on that tracks **alchemy transmute**, **mooncloth**, and **salt shaker** cooldowns across every character on your account.

## Blizzard policy

This add-on is written to follow the [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534):

1. **Free of charge** — no paywalled features
2. **Fully visible source** — plain Lua, no obfuscation
3. **Low impact** — local SavedVariables only; no chat spam or realm load
4. **No advertisements**
5. **No in-game donation prompts**
6. **T-rated content**
7. **ToU / EULA** — uses only official add-on APIs (no bots or client mods)
8. Blizzard may disable any API at any time

## What it tracks

| Profession | Craft | Spell ID |
|------------|--------|----------|
| Alchemy | Transmute: Arcanite | 17187 |
| Alchemy | Transmute: Iron to Gold | 11479 |
| Alchemy | Transmute: Mithril to Truesilver | 11480 |
| Alchemy | Elemental essence transmutes | 17559–17566 |
| Tailoring | Mooncloth | 18560 |
| Leatherworking | Salt Shaker | 19566 (item 15846) |

## Install

1. Copy the `ClassicProfessionCDs` folder into:
   ```
   World of Warcraft/_classic_era_/Interface/AddOns/
   ```
2. Restart the client or `/reload`.
3. Enable **Classic Profession CDs** on the character select AddOns screen (load out-of-date if needed).

## Usage

| Command | Action |
|---------|--------|
| `/cpcd` | Toggle the overview window |
| `/cpcd reset` | Reset window position |
| `/cpcd wipe` | Clear all saved cooldown data |
| `/cpcd help` | Show commands |

Log into each crafting alt once so the add-on can record known recipes and active cooldowns. Data is stored account-wide in SavedVariables.

Every tracked cooldown is listed for each character. Recipes that character does not know show as **Not learned**; known ones show **Ready** or time remaining.

## How it works

- Reads profession spell cooldowns via `GetSpellCooldown` while you are logged in.
- Stores an absolute “ready at” time using `GetServerTime()`.
- Shows every character’s status in one window so you can plan crafts without swapping first.

Cooldown times only update for the character you are currently playing. Visit each alt periodically (or after crafting) to refresh.

## Repository status

This GitHub repository is **private** while the add-on is in development. Before public distribution (CurseForge, Wago, etc.), make the repo public so the source stays freely viewable per [Blizzard’s UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534).

## License

MIT — see [LICENSE](LICENSE).
