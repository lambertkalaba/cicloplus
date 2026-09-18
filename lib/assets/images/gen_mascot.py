from PIL import Image, ImageDraw
import math

# ---- Paleta CicloPlus (tema 'pink', desde app_theme.dart / kAppThemes) ----
PRIMARY = (214, 51, 108)        # 0xFFD6336C
PRIMARY_DARK = (166, 30, 77)    # 0xFFA61E4D
PRIMARY_LIGHT = (248, 215, 227) # 0xFFF8D7E3
BG_TINT = (255, 245, 247)       # 0xFFFFF5F7

CAT_ORANGE = (240, 152, 80)
CAT_ORANGE_DARK = (214, 122, 55)
CAT_CREAM = (255, 226, 189)
OUTLINE = (120, 70, 40)
PINK_NOSE = (232, 140, 150)
EYE_DARK = (60, 38, 30)
WHITE = (255, 255, 255)

SCALE = 4
FINAL = 800
SIZE = FINAL * SCALE

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
cx = SIZE // 2

def s(v):
    return v * SCALE

def soft_ellipse_shadow(draw, bbox, color, blur_layers=3):
    x0, y0, x1, y1 = bbox
    for i in range(blur_layers, 0, -1):
        alpha = int(28 / i)
        pad = i * s(6)
        draw.ellipse([x0 - pad, y0 - pad * 0.4, x1 + pad, y1 + pad * 0.4], fill=(60, 30, 20, alpha))

GRASS = (176, 214, 150)
GRASS_DARK = (150, 195, 122)
grass_top = s(600)
d.pieslice([-s(100), grass_top - s(220), SIZE + s(100), grass_top + s(420)], 0, 180, fill=GRASS)
d.rectangle([0, grass_top + s(60), SIZE, SIZE], fill=GRASS_DARK)
d.pieslice([-s(100), grass_top - s(220), SIZE + s(100), grass_top + s(420)], 0, 180, fill=GRASS)

soft_ellipse_shadow(d, [cx - s(230), s(690), cx + s(230), s(760)], OUTLINE, blur_layers=4)
d.ellipse([cx - s(190), s(700), cx + s(190), s(750)], fill=(90, 60, 40, 60))

def flower(draw, x, y, r, petal_color, center_color):
    petals = 5
    for i in range(petals):
        ang = (2 * math.pi / petals) * i - math.pi / 2
        px = x + math.cos(ang) * r * 0.9
        py = y + math.sin(ang) * r * 0.9
        draw.ellipse([px - r * 0.7, py - r * 0.7, px + r * 0.7, py + r * 0.7], fill=petal_color)
    draw.ellipse([x - r * 0.55, y - r * 0.55, x + r * 0.55, y + r * 0.55], fill=center_color)

flower_spots = [
    (s(80), s(660), s(26)),
    (s(170), s(720), s(20)),
    (s(60), s(760), s(16)),
    (s(700), s(660), s(24)),
    (s(630), s(730), s(18)),
    (s(740), s(770), s(16)),
    (s(30), s(690), s(14)),
    (s(760), s(700), s(14)),
]
for i, (fx, fy, fr) in enumerate(flower_spots):
    petal = PRIMARY_LIGHT if i % 2 == 0 else (255, 255, 255)
    center = PRIMARY if i % 2 == 0 else PRIMARY_DARK
    d.line([fx, fy + fr * 0.6, fx, fy + fr * 2.2], fill=GRASS_DARK, width=s(3))
    flower(d, fx, fy, fr, petal, center)

d.ellipse([cx - s(260), s(700), cx - s(210), s(730)], fill=GRASS_DARK)
d.ellipse([cx + s(210), s(705), cx + s(260), s(735)], fill=GRASS_DARK)

# ==================== GATO ====================
body_top = s(430)
body_bottom = s(720)
body_w = s(340)
body_cx = cx
d.ellipse([body_cx - body_w / 2, body_top, body_cx + body_w / 2, body_bottom],
          fill=CAT_ORANGE, outline=OUTLINE, width=s(6))

belly_w = s(190)
d.ellipse([body_cx - belly_w / 2, s(520), body_cx + belly_w / 2, s(720)], fill=CAT_CREAM)

paw_r = s(46)
d.ellipse([body_cx - s(110) - paw_r, s(660), body_cx - s(110) + paw_r, s(660) + paw_r * 1.3],
          fill=CAT_CREAM, outline=OUTLINE, width=s(5))
d.ellipse([body_cx + s(110) - paw_r, s(660), body_cx + s(110) + paw_r, s(660) + paw_r * 1.3],
          fill=CAT_CREAM, outline=OUTLINE, width=s(5))

tail_color = CAT_ORANGE
tail_pts = []
tail_cx, tail_cy = body_cx + s(190), s(640)
for t in range(0, 220, 4):
    ang = math.radians(t)
    r = s(120) - t * 0.35
    if r < 0:
        break
    x = tail_cx + math.cos(ang) * r
    y = tail_cy - math.sin(ang) * r * 0.9
    tail_pts.append((x, y))
if len(tail_pts) > 2:
    d.line(tail_pts, fill=tail_color, width=s(48), joint="curve")
    d.ellipse([tail_pts[0][0] - s(24), tail_pts[0][1] - s(24), tail_pts[0][0] + s(24), tail_pts[0][1] + s(24)], fill=tail_color)
    d.ellipse([tail_pts[-1][0] - s(20), tail_pts[-1][1] - s(20), tail_pts[-1][0] + s(20), tail_pts[-1][1] + s(20)], fill=CAT_CREAM)

head_r = s(230)
head_cy = s(320)
d.ellipse([body_cx - head_r, head_cy - head_r, body_cx + head_r, head_cy + head_r],
          fill=CAT_ORANGE, outline=OUTLINE, width=s(6))

def rounded_triangle(draw, apex, base_l, base_r, color, outline, width):
    draw.polygon([apex, base_l, base_r], fill=color, outline=outline, width=width)
    r = s(18)
    for p in (apex, base_l, base_r):
        draw.ellipse([p[0]-r, p[1]-r, p[0]+r, p[1]+r], fill=color)

ear_r = head_r
rounded_triangle(
    d,
    (body_cx - s(150), head_cy - ear_r - s(40)),
    (body_cx - s(230), head_cy - s(20)),
    (body_cx - s(70), head_cy - s(60)),
    CAT_ORANGE, OUTLINE, s(6),
)
rounded_triangle(
    d,
    (body_cx + s(150), head_cy - ear_r - s(40)),
    (body_cx + s(230), head_cy - s(20)),
    (body_cx + s(70), head_cy - s(60)),
    CAT_ORANGE, OUTLINE, s(6),
)
rounded_triangle(
    d,
    (body_cx - s(150), head_cy - ear_r + s(10)),
    (body_cx - s(200), head_cy - s(40)),
    (body_cx - s(100), head_cy - s(65)),
    PINK_NOSE, None, 0,
)
rounded_triangle(
    d,
    (body_cx + s(150), head_cy - ear_r + s(10)),
    (body_cx + s(200), head_cy - s(40)),
    (body_cx + s(100), head_cy - s(65)),
    PINK_NOSE, None, 0,
)

muzzle_w = s(190)
d.ellipse([body_cx - muzzle_w / 2, head_cy + s(30), body_cx + muzzle_w / 2, head_cy + s(170)], fill=CAT_CREAM)

for i, off in enumerate([-s(60), 0, s(60)]):
    d.line([body_cx + off, head_cy - head_r + s(30), body_cx + off * 0.6, head_cy - s(40)],
           fill=CAT_ORANGE_DARK, width=s(10))

eye_y = head_cy - s(10)
eye_dx = s(85)
eye_w, eye_h = s(58), s(70)
for sign in (-1, 1):
    ex = body_cx + sign * eye_dx
    d.ellipse([ex - eye_w/2, eye_y - eye_h/2, ex + eye_w/2, eye_y + eye_h/2], fill=WHITE, outline=OUTLINE, width=s(5))
    d.ellipse([ex - eye_w/2 + s(8), eye_y - eye_h/2 + s(14), ex + eye_w/2 - s(8), eye_y + eye_h/2 - s(6)], fill=EYE_DARK)
    d.ellipse([ex - s(6), eye_y - eye_h/2 + s(18), ex + s(14), eye_y - eye_h/2 + s(38)], fill=WHITE)

nose_w = s(30)
d.polygon([
    (body_cx - nose_w/2, head_cy + s(60)),
    (body_cx + nose_w/2, head_cy + s(60)),
    (body_cx, head_cy + s(85)),
], fill=PINK_NOSE, outline=OUTLINE, width=s(4))

mouth_y = head_cy + s(85)
d.arc([body_cx - s(50), mouth_y - s(20), body_cx, mouth_y + s(30)], start=20, end=160, fill=OUTLINE, width=s(6))
d.arc([body_cx, mouth_y - s(20), body_cx + s(50), mouth_y + s(30)], start=20, end=160, fill=OUTLINE, width=s(6))

cheek_r = s(28)
d.ellipse([body_cx - s(150), head_cy + s(50), body_cx - s(150) + cheek_r*2, head_cy + s(50) + cheek_r*1.6], fill=(255, 190, 190, 140))
d.ellipse([body_cx + s(150) - cheek_r*2, head_cy + s(50), body_cx + s(150), head_cy + s(50) + cheek_r*1.6], fill=(255, 190, 190, 140))

whisker_y = head_cy + s(70)
for dy in (-s(20), 0, s(20)):
    d.line([body_cx - s(120), whisker_y + dy, body_cx - s(220), whisker_y + dy - s(10)], fill=OUTLINE, width=s(4))
    d.line([body_cx + s(120), whisker_y + dy, body_cx + s(220), whisker_y + dy - s(10)], fill=OUTLINE, width=s(4))

highlight = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
hd = ImageDraw.Draw(highlight)
hd.ellipse([body_cx - s(140), head_cy - s(160), body_cx + s(20), head_cy - s(20)], fill=(255, 255, 255, 45))
img = Image.alpha_composite(img, highlight)

final_img = img.resize((FINAL, FINAL), Image.LANCZOS)
final_img.save("/sessions/vibrant-cool-maxwell/mnt/dev/cicloplus_app/lib/assets/images/mascot_cat.png")
print("mascot saved", final_img.size)
