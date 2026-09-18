from PIL import Image, ImageDraw

# Paleta CicloPlus (tema 'pink')
PRIMARY_LIGHT = (248, 215, 227)  # 0xFFF8D7E3 - fondo circular
SILHOUETTE = (196, 140, 160)     # tono más oscuro derivado de primaryLight, cálido neutro

SCALE = 4
FINAL = 400
SIZE = FINAL * SCALE

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Fondo circular
d.ellipse([0, 0, SIZE, SIZE], fill=PRIMARY_LIGHT)

cx = SIZE // 2

def s(v):
    return v * SCALE

# Silueta: cabeza (círculo) + hombros (media elipse) recortada al círculo de fondo
# Cabeza
head_r = s(72)
head_cy = s(148)
d.ellipse([cx - head_r, head_cy - head_r, cx + head_r, head_cy + head_r], fill=SILHOUETTE)

# Hombros (elipse grande, la parte inferior queda cortada por el borde del avatar circular al recortar después)
shoulder_w = s(230)
shoulder_top = s(230)
d.ellipse([cx - shoulder_w/2, shoulder_top, cx + shoulder_w/2, shoulder_top + s(260)], fill=SILHOUETTE)

# Recorte final al círculo (por si algo sobresale del borde)
mask = Image.new("L", (SIZE, SIZE), 0)
md = ImageDraw.Draw(mask)
md.ellipse([0, 0, SIZE, SIZE], fill=255)
out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
out.paste(img, (0, 0), mask)

final_img = out.resize((FINAL, FINAL), Image.LANCZOS)
final_img.save("/sessions/vibrant-cool-maxwell/mnt/dev/cicloplus_app/lib/assets/images/avatar_placeholder.png")
print("avatar saved", final_img.size)
