"""스토어 스크린샷 합성 스크립트 - 코랄 그라디언트 + 캡션"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# Paths
RAW_DIR = "/Users/di-nomad/civil-servant-community/screenshots/raw"
OUT_DIR = "/Users/di-nomad/civil-servant-community/screenshots/store"
os.makedirs(OUT_DIR, exist_ok=True)

# Target: 6.7" App Store (1290 x 2796)
CANVAS_W, CANVAS_H = 1290, 2796

# Colors
CORAL_TOP = (232, 131, 107)      # #E8836B
CORAL_BOTTOM = (212, 96, 74)     # #D4604A
PEACH_LIGHT = (255, 248, 245)    # #FFF8F5
WHITE = (255, 255, 255)
TEXT_DARK = (45, 45, 45)          # #2D2D2D
TEXT_SUB = (150, 130, 125)

# Screenshot config
SCREENSHOTS = [
    ("01_home_feed.png", "우리 지자체\n이야기가 모이는 곳", "내 지자체 피드에서 동료들의 이야기를 만나보세요"),
    ("02_hot.png", "전국 공무원이\n주목하는 인기글", "전국 HOT 게시판에서 화제의 글을 확인하세요"),
    ("03_post_detail.png", "솔직한 이야기,\n익명이니까요", "자유롭게 소통하고 댓글로 공감해보세요"),
    ("04_write.png", "자유롭게\n의견을 나눠요", "태그를 골라 글을 작성하고 이미지도 첨부하세요"),
    ("05_explore.png", "243개 지자체\n한눈에 탐색", "전국 지자체를 검색하고 다른 지역 소식을 살펴보세요"),
    ("06_profile.png", "내 활동을\n한눈에 관리", "작성한 글, 댓글, 북마크를 한곳에서 확인하세요"),
]

# Status bar crop (iPhone 17 Pro: ~130px top for dynamic island + status bar)
STATUS_BAR_HEIGHT = 175
HOME_INDICATOR_HEIGHT = 34


def create_gradient(width, height, color_top, color_bottom):
    """Create vertical gradient image"""
    img = Image.new("RGB", (width, height))
    for y in range(height):
        ratio = y / height
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        for x in range(width):
            img.putpixel((x, y), (r, g, b))
    return img


def create_gradient_fast(width, height, color_top, color_bottom):
    """Create vertical gradient image (fast version)"""
    import numpy as np
    arr = np.zeros((height, width, 3), dtype=np.uint8)
    for y in range(height):
        ratio = y / height
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        arr[y, :] = [r, g, b]
    return Image.fromarray(arr)


def round_corners(img, radius):
    """Add rounded corners with transparency"""
    w, h = img.size
    rounded = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (w, h)], radius=radius, fill=255)
    rounded.paste(img.convert("RGBA"), (0, 0))
    rounded.putalpha(mask)
    return rounded


def add_shadow(img, offset=10, blur_radius=20, opacity=80):
    """Add drop shadow behind image"""
    w, h = img.size
    shadow_canvas = Image.new("RGBA", (w + blur_radius * 2 + offset, h + blur_radius * 2 + offset), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, opacity))
    # Use the alpha from original as shadow shape
    if img.mode == "RGBA":
        shadow.putalpha(img.split()[3].point(lambda x: min(x, opacity)))
    shadow_canvas.paste(shadow, (blur_radius + offset, blur_radius + offset))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(blur_radius))
    shadow_canvas.paste(img, (blur_radius, blur_radius), img)
    return shadow_canvas, blur_radius


def load_font(size):
    """Load system font"""
    font_paths = [
        "/System/Library/Fonts/AppleSDGothicNeo.ttc",
        "/System/Library/Fonts/Supplemental/AppleGothic.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def load_font_bold(size):
    """Load bold system font"""
    font_paths = [
        "/System/Library/Fonts/AppleSDGothicNeo.ttc",  # index 0 is usually regular, try bold
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                # Try different font indices for bold
                for idx in [8, 6, 4, 2, 0]:
                    try:
                        f = ImageFont.truetype(path, size, index=idx)
                        return f
                    except Exception:
                        continue
            except Exception:
                continue
    return ImageFont.load_default()


# Create screenshots
try:
    create_bg = create_gradient_fast
    import numpy as np
except ImportError:
    create_bg = create_gradient

for filename, title, subtitle in SCREENSHOTS:
    raw_path = os.path.join(RAW_DIR, filename)
    if not os.path.exists(raw_path):
        print(f"  SKIP: {filename} not found")
        continue

    print(f"  Processing: {filename}...")

    # 1. Load and crop raw screenshot
    raw = Image.open(raw_path)
    raw_w, raw_h = raw.size

    # Crop status bar and home indicator
    cropped = raw.crop((0, STATUS_BAR_HEIGHT, raw_w, raw_h - HOME_INDICATOR_HEIGHT))
    crop_w, crop_h = cropped.size

    # 2. Scale screenshot to fit canvas with padding
    # Target: screenshot takes ~75% of canvas width, positioned lower
    target_w = int(CANVAS_W * 0.82)
    scale = target_w / crop_w
    target_h = int(crop_h * scale)
    cropped_resized = cropped.resize((target_w, target_h), Image.LANCZOS)

    # 3. Round corners
    corner_radius = 36
    rounded_screenshot = round_corners(cropped_resized, corner_radius)

    # 4. Add shadow
    shadowed, shadow_pad = add_shadow(rounded_screenshot, offset=8, blur_radius=25, opacity=60)

    # 5. Create gradient background
    canvas = create_bg(CANVAS_W, CANVAS_H, CORAL_TOP, CORAL_BOTTOM).convert("RGBA")

    # 6. Add title text
    font_title = load_font_bold(82)
    font_sub = load_font(38)

    draw = ImageDraw.Draw(canvas)

    # Title position
    title_y = 180
    for line in title.split("\n"):
        bbox = draw.textbbox((0, 0), line, font=font_title)
        tw = bbox[2] - bbox[0]
        tx = (CANVAS_W - tw) // 2
        draw.text((tx, title_y), line, fill=WHITE, font=font_title)
        title_y += bbox[3] - bbox[1] + 16

    # Subtitle
    subtitle_y = title_y + 20
    bbox = draw.textbbox((0, 0), subtitle, font=font_sub)
    sw = bbox[2] - bbox[0]
    sx = (CANVAS_W - sw) // 2
    draw.text((sx, subtitle_y), subtitle, fill=(255, 255, 255, 200), font=font_sub)

    # 7. Place screenshot (centered, below text)
    screenshot_y = subtitle_y + 100
    screenshot_x = (CANVAS_W - shadowed.width) // 2

    # Make sure screenshot doesn't overflow bottom too much (it's OK to clip a bit)
    canvas.paste(shadowed, (screenshot_x, screenshot_y), shadowed)

    # 8. Save
    out_path = os.path.join(OUT_DIR, filename)
    canvas_rgb = Image.new("RGB", canvas.size, (0, 0, 0))
    canvas_rgb.paste(canvas, mask=canvas.split()[3] if canvas.mode == "RGBA" else None)
    canvas_rgb.save(out_path, "PNG", quality=95)
    print(f"    -> {out_path} ({CANVAS_W}x{CANVAS_H})")

print("\n=== 완료! ===")
print(f"저장 위치: {OUT_DIR}")
