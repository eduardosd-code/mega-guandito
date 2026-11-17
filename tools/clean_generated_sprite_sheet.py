from pathlib import Path
import sys

from PIL import Image


def clean(path: Path) -> None:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            brightness = (red + green + blue) / 3.0
            spread = max(red, green, blue) - min(red, green, blue)
            if brightness >= 242 and spread <= 5:
                alpha = 0
            elif brightness >= 225 and spread <= 8:
                alpha = min(alpha, int((242.0 - brightness) / 17.0 * 255.0))
            pixels[x, y] = (red, green, blue, alpha)
    image.save(path, optimize=True)


if __name__ == "__main__":
    for filename in sys.argv[1:]:
        clean(Path(filename))
