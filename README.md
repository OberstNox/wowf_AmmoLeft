# AmmoLeft

AmmoLeft is a movable ammunition counter for Hunters in **World of Warcraft: Forever**. It shows the icon and total carried count of your selected arrows or bullets, including stacks spread across your bags. The counter stays visible in combat and when you run out.

## Installation

1. Download the ZIP from **Code → Download ZIP** and extract it.
2. Copy the inner `AmmoLeft` folder into `World of Warcraft\_forever_\Interface\AddOns`. You should end up with `AddOns\AmmoLeft\AmmoLeft.toc`.
3. Start WoW Forever and make sure **AmmoLeft** is enabled in the **AddOns** list. If the game was open while you copied the files, close it completely and start it again.

## Controls

- Hold **Alt** and drag with the left mouse button to move the counter.
- Click the AmmoLeft icon on the minimap to open settings, or drag it around the edge of the minimap to move it. Its position is saved per character.
- You can also open settings with `/ammoleft` or via **Options → AddOns → AmmoLeft**.
- Type `/ammoleft reset` to put the counter back in its default position.

## Settings

Choose normal, low, and critical count colors, adjust the warning thresholds, and change the counter size and background opacity. By default, the count turns yellow at **200** and red at **50**.

The warning sound is off by default. You can choose a soft click or a raid warning and preview it in settings. The selected sound plays on a Critical crossing and on a Low crossing when the Low pop-up is enabled.

Open **Pop-up alerts** in settings to enable Low and Critical alerts separately. Each appears for three seconds when your ammo drops to its threshold. Set your own messages or leave the fields blank to use **Low ammo!** and **Critical ammo!**. Use the preview buttons to check the text and sound. Select **Move pop-up**, drag the preview, and click **Done moving** to set the position for both alerts.

Settings and position are saved per character.

## Versions and license

Developed by **OberstNox**. See the [changelog](CHANGELOG.md) for version history and the [MIT license](LICENSE) for reuse terms.
