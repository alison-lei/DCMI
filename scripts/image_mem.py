from PIL import Image

W, H = 256, 320
img = Image.open("ohmygod.jpg").convert("L").resize((W, H))
with open("image1.mem", "w") as f:
    for y in range(H):
        for x in range(W):
            v = img.getpixel((x, y)) << 6   # 8-bit gray -> 14-bit
            f.write(f"{v:04X}\n")