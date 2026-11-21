import os

import numpy as np
from PIL import Image


def visualize_image(path: str) -> None:
    v: np.ndarray = np.array([int(x, 16) for x in open(path).read().split()])
    image: np.ndarray = v.reshape(320, 256)
    image: np.ndarray = (
        (image - image.min()) / (image.max() - image.min()) * 255
    ).astype("uint8")
    Image.fromarray(image).save(f"images/{os.path.splitext(os.path.basename(path))[0]}.png")


if __name__ == "__main__":
    visualize_image("images/image1.mem")
