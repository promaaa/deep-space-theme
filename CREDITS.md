# Credits

## Wallpapers

All ten wallpapers are by **Dogan Ural**
([@doganuraldesign](https://x.com/doganuraldesign),
[doganural.com](https://doganural.com)). The rights stay with him. The MIT
license of this repository does not cover them.

He posts each piece on 𝕏 as a carousel of tall strips, 2048×4096 each, and
writes: "For the full 8K version, just ask your @bot to stitch it together for
you, as the file is too large to share on 𝕏"
([post](https://x.com/doganuraldesign/status/2119408920980500622)).

[`tools/wallpapers.py`](tools/wallpapers.py) does that. For each post it
downloads the strips at full size and checks that each strip's right edge
continues best into the next strip's left edge. It then joins them, keeps the
2:1 centre of wider pieces, and writes a 5120×2560 WebP and an 800×400
thumbnail. Nothing else is changed.

| File | Title | Posted | Strips | Original size |
| --- | --- | --- | --- | --- |
| `01-rings` | untitled | [12 Sep 2026](https://x.com/doganuraldesign/status/2098815974858281039) | 4 | 8192×4096 |
| `02-orbit` | untitled | [29 Oct 2026](https://x.com/doganuraldesign/status/2115869155530535134) | 4 | 8192×4096 |
| `03-walker` | untitled | [21 Oct 2026](https://x.com/doganuraldesign/status/2112987125901652467) | 4 | 8192×4096 |
| `04-spiral` | untitled | [7 Nov 2026](https://x.com/doganuraldesign/status/2119166987993538662) | 4 | 8192×4096 |
| `05-vortex` | untitled | [21 Sep 2026](https://x.com/doganuraldesign/status/2102146429481316471) | 4 | 8192×4096 |
| `06-do-you-have-time` | "Do you have time?" | [13 Nov 2026](https://x.com/doganuraldesign/status/2121322050656907638) | 8 | 16384×4096 |
| `07-tree` | untitled | [9 Nov 2026](https://x.com/doganuraldesign/status/2119819558055751846) | 4 | 8192×4096 |
| `08-other-worlds` | "One day, we'll call other worlds home" | [1 Nov 2026](https://x.com/doganuraldesign/status/2116994324378349712) | 4 | 8192×4096 |
| `09-are-you-there` | "Are you there?" | [11 Nov 2026](https://x.com/doganuraldesign/status/2120605852314816916) | 4 | 8192×4096 |
| `10-light-and-hope` | "I bring light, you bring hope" | [27 Oct 2026](https://x.com/doganuraldesign/status/2115102152905408836) | 4 | 8192×4096 |

Titles in quotes are the artist's own. "Rings", "Orbit", "Walker", "Spiral",
"Vortex" and "Tree" in the README are only names for the untitled pieces.

## Palette

The palette is by Marc Duboc ([@promaaa](https://github.com/promaaa)). The hue
of each colour was measured in OKLCH from `01-rings`. Lightness and saturation
were then set so every colour reads on the background.
[`tools/palettes.py`](tools/palettes.py) writes `colors.toml` and stops if text
falls below 11:1, comments below 4.5:1 or any colour below 5.5:1. Green is the
one colour the picture does not have. It is a mint, added so green still means
"OK" in diffs and test output.

## Boot logo

`unlock.png` is the Omarchy logo from the stock themes, recoloured to the
accent blue.
