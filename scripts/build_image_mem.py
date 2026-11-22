from PIL import Image


def build_image_mem(src_path: str, dest_path: str, w: int = 256, h: int = 320) -> None:
    image: Image.Image = Image.open(src_path).convert("L").resize((w, h))
    with open(dest_path, "w") as f:
        for y in range(h):
            for x in range(w):
                v: int = image.getpixel((x, y)) << 6  # 8-bit gray -> 14-bit
                f.write(f"{v:04X}\n")


if __name__ == "__main__":
    build_image_mem("ohmygod.jpg", "image1.mem")
