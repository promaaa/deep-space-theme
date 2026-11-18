"""Rebuild backgrounds/ and thumbnails/ from Dogan Ural's posts on X.

He posts each piece as tall strips (a carousel) and writes: "For the full 8K
version, just ask your @bot to stitch it together for you". This script does
that: it reads each post through the public fxtwitter API, downloads the strips
at full size, checks that every strip continues into the next one, joins them,
crops wider pieces to 2:1 around the centre, and writes a 5120x2560 WebP.

Run from the repository root:
  uv run --with pillow --with numpy python tools/wallpapers.py [--full DIR]
--full DIR also keeps each stitched original (8192x4096 or wider) as JPEG.
"""
import io, json, os, sys, urllib.request, numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None  # 16K panoramas are larger than Pillow's default limit
UA = {"User-Agent": "Mozilla/5.0"}

# (file name, post id, title). Order sets the cycling order in Omarchy.
WALLPAPERS = [
    ("01-rings", "2098815974858281039", "Rings"),
    ("02-orbit", "2115869155530535134", "Orbit"),
    ("03-walker", "2112987125901652467", "Walker"),
    ("04-spiral", "2119166987993538662", "Spiral"),
    ("05-vortex", "2102146429481316471", "Vortex"),
    ("06-do-you-have-time", "2121322050656907638", "Do you have time?"),
    ("07-tree", "2119819558055751846", "Tree"),
    ("08-other-worlds", "2116994324378349712", "One day, we'll call other worlds home"),
    ("09-are-you-there", "2120605852314816916", "Are you there?"),
    ("10-light-and-hope", "2115102152905408836", "I bring light, you bring hope"),
]
W, H = 5120, 2560


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
        return r.read()


def strips(post_id):
    post = json.loads(get(f"https://api.fxtwitter.com/doganuraldesign/status/{post_id}"))["tweet"]
    urls = [m["url"].split("?")[0] + "?name=orig" for m in post["media"]["all"] if m["type"] == "photo"]
    return [np.asarray(Image.open(io.BytesIO(get(u))).convert("RGB")) for u in urls]


def check_order(parts):
    """Each strip's right edge must match the next strip's left edge best."""
    k = np.ones(9) / 9
    edge = lambda col: np.convolve(col.mean(1).mean(1), k, "same")  # blur out JPEG block noise
    R = [edge(p[:, -3:].astype(np.float32)) for p in parts]
    L = [edge(p[:, :3].astype(np.float32)) for p in parts]
    for i in range(len(parts) - 1):
        cost = [np.abs(R[i] - L[j]).mean() if j != i else np.inf for j in range(len(parts))]
        assert int(np.argmin(cost)) == i + 1, f"strip {i} does not continue into strip {i + 1}"


def main():
    full = sys.argv[sys.argv.index("--full") + 1] if "--full" in sys.argv else None
    os.makedirs("backgrounds", exist_ok=True)
    os.makedirs("thumbnails", exist_ok=True)
    for name, post_id, title in WALLPAPERS:
        parts = strips(post_id)
        check_order(parts)
        img = Image.fromarray(np.hstack(parts))
        if full:
            os.makedirs(full, exist_ok=True)
            img.save(os.path.join(full, name + ".jpg"), quality=95, subsampling=0)
        w, h = img.size
        if w > 2 * h:  # ultra-wide: keep the 2:1 centre
            x = (w - 2 * h) // 2
            img = img.crop((x, 0, x + 2 * h, h))
        img = img.resize((W, H), Image.LANCZOS)
        img.save(f"backgrounds/{name}.webp", quality=88, method=6)
        img.resize((800, 400), Image.LANCZOS).save(f"thumbnails/{name}.jpg", quality=85)
        print(f"{name:22} {len(parts)} strips, {w}x{h} -> {W}x{H}  {title}")


if __name__ == "__main__":
    main()
