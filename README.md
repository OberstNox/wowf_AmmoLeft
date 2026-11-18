# Ammoleft Forever

Ammoleft Forever is a movable ammunition counter for Hunters in **World of Warcraft: Forever**. It shows the icon and total carried count of your selected arrows or bullets, including stacks spread across your bags. The counter stays visible in combat and when you run out.

## Installation

1. Download the ZIP from **Code → Download ZIP** and extract it.
2. Copy the inner `AmmoLeft` folder into `World of Warcraft\_forever_\Interface\AddOns`. You should end up with `AddOns\AmmoLeft\AmmoLeft.toc`.
3. Start WoW Forever and make sure **Ammoleft Forever** is enabled in the **AddOns** list. If the game was open while you copied the files, close it completely and start it again.

## Controls

- Hover over the ammunition icon to see the active item, its count, and compatible reserves grouped by item.
- Hold **Alt** and drag with the left mouse button to move the counter.
- Click the addon icon on the minimap to open settings, or drag it around the edge of the minimap to move it. Its position is saved per character.
- You can also open settings with `/ammoleft` or via **Options → AddOns → Ammoleft Forever**.
- Type `/ammoleft reset` to put the counter back in its default position.

## Settings

Choose normal, low, and critical count colors, adjust the warning thresholds, and change the counter size and background opacity. By default, the count turns yellow at **200** and red at **50**.

Open **Alerts** to configure Low and Critical separately. Choose a sound, duration, and optional counter pulse for each. Sound is off by default for new profiles. The Low sound plays when the Low pop-up is enabled, and Critical can play with or without its pop-up.

Set your own pop-up messages or leave the fields blank to use **Low ammo!** and **Critical ammo!**. Use `{count}` to insert the current ammo count, for example `Only {count} arrows left!`. Use **Preview Low** or **Preview Critical** to try an alert. Select **Move pop-up**, drag the preview, and click **Done moving** to set the shared position.

## Profiles

Choose **Use profile** to share settings across Hunters. **New profile** starts with a copy of your active settings. **Copy from** replaces the active profile's settings after you confirm. Changes to a shared profile apply to every character using it.

The counter, pop-up, and minimap positions belong to each character. Use **Copy positions** to bring them over from another character that has logged in with version 2.0 or later. Upgrading from 1.3.2 creates a separate profile from each character's current settings the first time they log in.

## Restock

**Manual** mode shows a quote at merchants selling your selected ammunition. **Restock** buys the number of rounds shown for the quoted price. The default target is 2,000 rounds. Purchases use whole vendor bundles, so the final count can be slightly above your target.

**Auto** mode requires a positive spending cap in copper per merchant visit. It purchases only when the full refill fits the cap, available stock, funds, and bag space. **Off** hides the merchant panel. If you fired your last round and the ammo slot cleared, the addon can restock the last ammunition it saw in this session if it still matches your ranged weapon.

## Versions and license

Developed by **OberstNox**. See the [changelog](CHANGELOG.md) for version history and the [MIT license](LICENSE) for reuse terms.
