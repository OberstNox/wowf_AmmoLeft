# AmmoLeft

AmmoLeft is a movable ammunition counter for Hunters in **World of Warcraft: Forever**. It shows the icon and total carried count of your selected arrows or bullets, including stacks spread across your bags. The counter stays visible in combat and when you run out.

## Installation

1. Download the ZIP from **Code → Download ZIP** and extract it.
2. Copy the inner `AmmoLeft` folder into `World of Warcraft\_forever_\Interface\AddOns`. You should end up with `AddOns\AmmoLeft\AmmoLeft.toc`.
3. Start WoW Forever and make sure **AmmoLeft** is enabled in the **AddOns** list. If the game was open while you copied the files, close it completely and start it again.

## Controls

- Hold **Alt** and drag with the left mouse button to move the counter.
- Type `/ammoleft` or go to **Options → AddOns → AmmoLeft** to open settings.
- Type `/ammoleft reset` to put the counter back in its default position.

## Settings

Choose normal, low, and critical count colors, adjust the warning thresholds, and change the counter size and background opacity. By default, the count turns yellow at **200** and red at **50**.

The critical warning sound is off by default. You can choose a soft click or a raid warning and preview it in settings. When enabled, the sound plays once as the count crosses the critical threshold. It can play again after you replenish your ammo above that threshold.

Settings and position are saved per character.

## Versions and license

Developed by **OberstNox**. See the [changelog](CHANGELOG.md) for version history and the [MIT license](LICENSE) for reuse terms.
