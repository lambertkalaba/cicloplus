"""
Voila Photo - Mejora de imagenes con IA (estilo Remini)
Ejecutar con: python app.py
"""

import sys
import os
import cv2
import numpy as np
import multiprocessing as mp_process

from PyQt6.QtWidgets import (
    QApplication, QWidget, QLabel, QPushButton, QVBoxLayout,
    QHBoxLayout, QFileDialog, QComboBox, QMessageBox, QProgressBar, QSlider,
    QListWidget, QListWidgetItem, QTabWidget, QGridLayout, QScrollArea,
    QCheckBox, QRadioButton, QFrame, QDialog, QDialogButtonBox
)
from PyQt6.QtGui import QPixmap, QImage, QImageReader, QPainter, QPen, QColor, QAction
QImageReader.setAllocationLimit(0)

from PyQt6.QtCore import Qt, QThread, pyqtSignal, QRect, QTimer

import torch as torch_lib

IMAGE_EXTENSIONS = (".png", ".jpg", ".jpeg", ".bmp", ".webp")

# Evitar fragmentacion de VRAM
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"

# ---------------------------------------------------------------------------
# Modo de procesamiento global (se establece al arrancar)
# ---------------------------------------------------------------------------
MODO_GPU = True  # Por defecto GPU, se cambia en el dialogo inicial

# Paleta estilo Remini: fondo casi negro con tinte morado, acento en
# degradado violeta -> magenta para los elementos de accion principal.
REMINI_GRAD = "qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 #7C3AED, stop:1 #EC4899)"
REMINI_GRAD_HOVER = "qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 #8B5CF6, stop:1 #F472B6)"
REMINI_ACCENT = "#A855F7"

STYLE_SHEET = f"""
QWidget {{ background-color: #0c0c13; color: #f2f0f7; font-family: 'Segoe UI', sans-serif; font-size: 13px; }}
QPushButton {{ background-color: {REMINI_GRAD}; color: white; border: none; border-radius: 20px; padding: 11px 20px; font-weight: 700; }}
QPushButton:hover {{ background-color: {REMINI_GRAD_HOVER}; }}
QPushButton:disabled {{ background-color: #302e3a; color: #6f6c7d; }}
QPushButton#secondary {{ background-color: #1b1a23; color: #f2f0f7; border-radius: 16px; border: 1px solid #2c2a37; }}
QPushButton#secondary:hover {{ background-color: #26242f; border-color: #3d3a4a; }}
QPushButton#selectArrow {{ border-top-left-radius: 0px; border-bottom-left-radius: 0px; border-left: 1px solid #3a3a42; padding: 10px 8px; }}
QPushButton#selectMain {{ border-top-right-radius: 0px; border-bottom-right-radius: 0px; }}
QPushButton#modoGPU {{ background-color: #1c1730; color: #b794f6; border: 2px solid #4c2f8c; border-radius: 18px; padding: 16px; font-size: 14px; }}
QPushButton#modoGPU:hover {{ background-color: #241c3d; border-color: {REMINI_ACCENT}; }}
QPushButton#modoCPU {{ background-color: #17131f; color: #d8b4fe; border: 2px solid #3a2f52; border-radius: 18px; padding: 16px; font-size: 14px; }}
QPushButton#modoCPU:hover {{ background-color: #1e1829; border-color: #d8b4fe; }}
QPushButton#modoSeleccionado {{ border-width: 3px; }}
QPushButton#ctaPrimary {{ font-size: 15px; border-radius: 23px; padding: 12px 24px; }}
QComboBox {{ background-color: #19171f; border: 1px solid #322f3d; border-radius: 12px; padding: 6px 10px; }}
QComboBox QAbstractItemView {{ background-color: #19171f; selection-background-color: {REMINI_ACCENT}; }}
QSlider::groove:horizontal {{ height: 6px; background: #322f3d; border-radius: 3px; }}
QSlider::handle:horizontal {{ background: {REMINI_GRAD}; width: 18px; height: 18px; margin: -6px 0; border-radius: 9px; }}
QProgressBar {{ background-color: #19171f; border: none; border-radius: 4px; height: 8px; }}
QProgressBar::chunk {{ background-color: {REMINI_GRAD}; border-radius: 4px; }}
QListWidget {{ background-color: #19171f; border: 1px solid #322f3d; border-radius: 10px; }}
QTabWidget::pane {{ border: 1px solid #322f3d; border-radius: 12px; }}
QTabBar::tab {{ background-color: #19171f; padding: 9px 18px; border-radius: 14px; margin-right: 4px; color: #b3b0c0; font-weight: 600; }}
QTabBar::tab:selected {{ background-color: {REMINI_GRAD}; color: white; }}
QFrame#toolCard {{ background-color: #17151e; border: 1px solid #2a2836; border-radius: 16px; }}
QLabel#title {{ font-size: 23px; font-weight: 800; color: #ffffff; }}
QLabel#sectionTitle {{ font-size: 14px; font-weight: 700; color: #ffffff; }}
QLabel#sectionSubtitle {{ font-size: 11px; color: #928fa3; }}
QLabel#status {{ color: #928fa3; font-size: 12px; }}
QCheckBox {{ spacing: 8px; }}
QRadioButton::indicator {{ width: 16px; height: 16px; border-radius: 8px; border: 2px solid #f2f0f7; background-color: #19171f; }}
QRadioButton::indicator:checked {{ background-color: #ffffff; border: 2px solid {REMINI_ACCENT}; }}
"""

# ---------------------------------------------------------------------------
# Dialogo de seleccion de modo al arrancar
# ---------------------------------------------------------------------------
class DialogoModo(QDialog):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Voila Photo — Selecciona el modo")
        self.setMinimumWidth(520)
        self.setModal(True)
        self.modo_elegido = "gpu"

        # Detectar GPU
        gpu_disponible = torch_lib.cuda.is_available()
        gpu_nombre = torch_lib.cuda.get_device_name(0) if gpu_disponible else "No detectada"
        gpu_vram = ""
        if gpu_disponible:
            vram = torch_lib.cuda.get_device_properties(0).total_memory / 1024**3
            gpu_vram = f"{vram:.1f}GB VRAM"

        titulo = QLabel("⚡ Voila Photo")
        titulo.setObjectName("title")
        titulo.setAlignment(Qt.AlignmentFlag.AlignCenter)

        subtitulo = QLabel("Elige el modo de procesamiento según tu equipo")
        subtitulo.setObjectName("status")
        subtitulo.setAlignment(Qt.AlignmentFlag.AlignCenter)

        # Boton GPU
        gpu_info = f"{gpu_nombre}\n{gpu_vram}" if gpu_disponible else "No se detectó GPU NVIDIA"
        self.btn_gpu = QPushButton(f"⚡ Modo GPU — Rápido\n{gpu_info}\n\nTodos los efectos · Segundos por foto")
        self.btn_gpu.setObjectName("modoGPU")
        self.btn_gpu.setEnabled(gpu_disponible)
        self.btn_gpu.clicked.connect(lambda: self.elegir("gpu"))

        # Boton CPU
        self.btn_cpu = QPushButton("🖥️ Modo CPU — Compatible\nCualquier PC sin GPU\n\nEfectos ligeros · Más lento pero funciona en todos los equipos")
        self.btn_cpu.setObjectName("modoCPU")
        self.btn_cpu.clicked.connect(lambda: self.elegir("cpu"))

        if not gpu_disponible:
            aviso = QLabel("⚠️ No se detectó GPU NVIDIA. Solo disponible Modo CPU.")
            aviso.setStyleSheet("color: #e8a030; font-size: 12px;")
            aviso.setAlignment(Qt.AlignmentFlag.AlignCenter)
        else:
            aviso = QLabel(f"✅ GPU detectada: {gpu_nombre} ({gpu_vram})")
            aviso.setStyleSheet("color: #60ff9a; font-size: 12px;")
            aviso.setAlignment(Qt.AlignmentFlag.AlignCenter)

        comparativa = QLabel(
            "Modo GPU: Real-ESRGAN, GFPGAN, CodeFormer, todos los efectos\n"
            "Modo CPU: Mejora de nitidez, color, desenfoque — sin modelos pesados"
        )
        comparativa.setObjectName("sectionSubtitle")
        comparativa.setAlignment(Qt.AlignmentFlag.AlignCenter)
        comparativa.setWordWrap(True)

        layout = QVBoxLayout()
        layout.setSpacing(16)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.addWidget(titulo)
        layout.addWidget(subtitulo)
        layout.addWidget(aviso)
        layout.addWidget(self.btn_gpu)
        layout.addWidget(self.btn_cpu)
        layout.addWidget(comparativa)
        self.setLayout(layout)

        # Si no hay GPU, elegir CPU automáticamente
        if not gpu_disponible:
            self.modo_elegido = "cpu"

    def elegir(self, modo):
        self.modo_elegido = modo
        self.accept()


# ---------------------------------------------------------------------------
# CompareWidget
# ---------------------------------------------------------------------------
class CompareWidget(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(400, 300)
        self.pixmap_before = None
        self.pixmap_after = None
        self.split_ratio = 0.5
        self.setMouseTracking(True)
        self._dragging = False

    def set_images(self, pixmap_before, pixmap_after):
        self.pixmap_before = pixmap_before
        self.pixmap_after = pixmap_after
        self.split_ratio = 0.5
        self.update()

    def _scaled_rect(self, pixmap):
        widget_size = self.size()
        scaled = pixmap.scaled(widget_size, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        x = (widget_size.width() - scaled.width()) // 2
        y = (widget_size.height() - scaled.height()) // 2
        return QRect(x, y, scaled.width(), scaled.height()), scaled

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.fillRect(self.rect(), QColor("#0e0e11"))
        if not self.pixmap_after:
            painter.setPen(QColor("#6a6a7a"))
            painter.drawText(self.rect(), Qt.AlignmentFlag.AlignCenter, "Sin resultado todavia")
            return
        rect, scaled_after = self._scaled_rect(self.pixmap_after)
        painter.drawPixmap(rect, scaled_after)
        if self.pixmap_before:
            _, scaled_before = self._scaled_rect(self.pixmap_before)
            split_x = rect.x() + int(rect.width() * self.split_ratio)
            clip_rect = QRect(rect.x(), rect.y(), split_x - rect.x(), rect.height())
            painter.setClipRect(clip_rect)
            painter.drawPixmap(rect, scaled_before)
            painter.setClipping(False)
            pen = QPen(QColor("#A855F7"), 3)
            painter.setPen(pen)
            painter.drawLine(split_x, rect.y(), split_x, rect.y() + rect.height())
            painter.setPen(QColor("#ffffff"))
            painter.drawText(rect.x() + 10, rect.y() + 20, "ANTES")
            painter.drawText(rect.x() + rect.width() - 70, rect.y() + 20, "DESPUES")

    def mousePressEvent(self, event):
        if self.pixmap_after and self.pixmap_before:
            self._dragging = True
            self._update_split(event.position().x())

    def mouseMoveEvent(self, event):
        if self._dragging:
            self._update_split(event.position().x())

    def mouseReleaseEvent(self, event):
        self._dragging = False

    def _update_split(self, mouse_x):
        rect, _ = self._scaled_rect(self.pixmap_after)
        if rect.width() == 0:
            return
        ratio = (mouse_x - rect.x()) / rect.width()
        self.split_ratio = max(0.0, min(1.0, ratio))
        self.update()


# ---------------------------------------------------------------------------
# Motores de IA — GPU
# ---------------------------------------------------------------------------
def ensure_weight(filename, url):
    from basicsr.utils.download_util import load_file_from_url
    model_path = os.path.join("weights", filename)
    if not os.path.isfile(model_path):
        os.makedirs("weights", exist_ok=True)
        model_path = load_file_from_url(url=url, model_dir="weights", progress=True, file_name=filename)
    return model_path

def build_upsampler_general():
    from basicsr.archs.rrdbnet_arch import RRDBNet
    from realesrgan import RealESRGANer
    model = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=23, num_grow_ch=32, scale=4)
    model_path = ensure_weight("RealESRGAN_x4plus.pth", "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth")
    return RealESRGANer(scale=4, model_path=model_path, model=model, tile=400, tile_pad=10, pre_pad=0, half=True)

def _mask_worker(img_bgr, return_dict):
    from rembg import remove, new_session
    from PIL import Image
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(img_rgb)
    session = new_session("u2net")
    result = remove(pil_img, session=session, only_mask=True)
    mask = np.array(result)
    if mask.shape[:2] != img_bgr.shape[:2]:
        mask = cv2.resize(mask, (img_bgr.shape[1], img_bgr.shape[0]))
    return_dict["mask"] = mask

def get_foreground_mask(img_bgr):
    manager = mp_process.Manager()
    return_dict = manager.dict()
    process = mp_process.Process(target=_mask_worker, args=(img_bgr, return_dict))
    process.start()
    process.join(timeout=120)
    if process.is_alive():
        process.terminate()
        process.join()
        raise RuntimeError("La deteccion de fondo tardo demasiado.")
    if "mask" not in return_dict:
        raise RuntimeError("No se pudo calcular la mascara de fondo.")
    return return_dict["mask"]

# ---------------------------------------------------------------------------
# Motores de IA — CPU (ligeros, sin GPU)
# ---------------------------------------------------------------------------
def enhance_cpu_nitidez(img_bgr):
    """Mejora de nitidez usando OpenCV — sin GPU."""
    blurred = cv2.GaussianBlur(img_bgr, (0, 0), sigmaX=3)
    sharp = cv2.addWeighted(img_bgr, 2.0, blurred, -1.0, 0)
    return np.clip(sharp, 0, 255).astype(np.uint8)

def enhance_cpu_color(img_bgr):
    """Mejora de color automatica — sin GPU."""
    result = img_bgr.copy().astype(np.float32)
    for c in range(3):
        ch = result[:, :, c]
        low, high = np.percentile(ch, [1, 99])
        if high > low:
            ch = (ch - low) * (255.0 / (high - low))
        result[:, :, c] = np.clip(ch, 0, 255)
    return result.astype(np.uint8)

def enhance_cpu_cara(img_bgr):
    """Suavizado de piel basico — sin GPU."""
    smooth = cv2.bilateralFilter(img_bgr, d=9, sigmaColor=75, sigmaSpace=75)
    result = cv2.addWeighted(img_bgr, 0.4, smooth, 0.6, 0)
    return result

def get_mask_cpu(img_bgr):
    """Mascara de primer plano simple usando GrabCut — sin GPU."""
    h, w = img_bgr.shape[:2]
    mask = np.zeros((h, w), np.uint8)
    bgd_model = np.zeros((1, 65), np.float64)
    fgd_model = np.zeros((1, 65), np.float64)
    rect = (int(w*0.1), int(h*0.1), int(w*0.8), int(h*0.8))
    try:
        cv2.grabCut(img_bgr, mask, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
        mask2 = np.where((mask == 2) | (mask == 0), 0, 255).astype('uint8')
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
        mask2 = cv2.morphologyEx(mask2, cv2.MORPH_CLOSE, kernel)
        return mask2
    except:
        return np.ones((h, w), np.uint8) * 255

# ---------------------------------------------------------------------------
# Funciones comunes (GPU y CPU)
# ---------------------------------------------------------------------------
def auto_color_correct(img_bgr):
    result = img_bgr.copy().astype(np.float32)
    for c in range(3):
        channel = result[:, :, c]
        low, high = np.percentile(channel, [1, 99])
        if high > low:
            channel = (channel - low) * (255.0 / (high - low))
        result[:, :, c] = np.clip(channel, 0, 255)
    return result.astype(np.uint8)

def apply_color_preset(img_bgr, preset_name):
    if preset_name == "ninguno":
        return img_bgr
    img = auto_color_correct(img_bgr)
    img_f = img.astype(np.float32)
    if preset_name == "golden":
        img_f[:, :, 2] = np.clip(img_f[:, :, 2] * 1.12, 0, 255)
        img_f[:, :, 0] = np.clip(img_f[:, :, 0] * 0.92, 0, 255)
    elif preset_name == "balanced":
        img_f = (img_f - 128) * 1.08 + 128
    elif preset_name == "orange":
        img_f[:, :, 2] = np.clip(img_f[:, :, 2] * 1.18, 0, 255)
        img_f[:, :, 1] = np.clip(img_f[:, :, 1] * 1.05, 0, 255)
    elif preset_name == "silky":
        hsv = cv2.cvtColor(np.clip(img_f, 0, 255).astype(np.uint8), cv2.COLOR_BGR2HSV).astype(np.float32)
        hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 0.85, 0, 255)
        img_f = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR).astype(np.float32)
    elif preset_name == "muted":
        hsv = cv2.cvtColor(np.clip(img_f, 0, 255).astype(np.uint8), cv2.COLOR_BGR2HSV).astype(np.float32)
        hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 0.7, 0, 255)
        img_f = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR).astype(np.float32)
    elif preset_name == "teal":
        img_f[:, :, 0] = np.clip(img_f[:, :, 0] * 1.15, 0, 255)
        img_f[:, :, 1] = np.clip(img_f[:, :, 1] * 1.08, 0, 255)
        img_f[:, :, 2] = np.clip(img_f[:, :, 2] * 0.92, 0, 255)
    elif preset_name == "soft_warm":
        img_f[:, :, 2] = np.clip(img_f[:, :, 2] * 1.08, 0, 255)
        img_f = (img_f - 128) * 0.92 + 128
    return np.clip(img_f, 0, 255).astype(np.uint8)

def blur_background(img_bgr, mask, blur_amount=25):
    mask_norm = (mask.astype(np.float32) / 255.0)[:, :, np.newaxis]
    k = max(3, blur_amount | 1)
    blurred = cv2.GaussianBlur(img_bgr, (k, k), 0)
    result = img_bgr.astype(np.float32) * mask_norm + blurred.astype(np.float32) * (1 - mask_norm)
    return np.clip(result, 0, 255).astype(np.uint8)

def enhance_background(img_bgr, mask, upsampler=None):
    mask_norm = (mask.astype(np.float32) / 255.0)[:, :, np.newaxis]
    blurred = cv2.GaussianBlur(img_bgr, (0, 0), sigmaX=4)
    sharpened = cv2.addWeighted(img_bgr, 3.5, blurred, -2.5, 0)
    sharpened = np.clip(sharpened, 0, 255).astype(np.float32)
    sharpened = (sharpened - 128) * 1.2 + 128
    sharpened = np.clip(sharpened, 0, 255).astype(np.uint8)
    result = img_bgr.astype(np.float32) * mask_norm + sharpened.astype(np.float32) * (1 - mask_norm)
    return np.clip(result, 0, 255).astype(np.uint8)

# ---------------------------------------------------------------------------
# Motores GPU (solo se importan si MODO_GPU=True)
# ---------------------------------------------------------------------------
def beautify_face_gpu(img_bgr, mask, strength=50):
    if strength <= 0:
        return img_bgr
    from gfpgan import GFPGANer
    gfpgan_model_path = ensure_weight("GFPGANv1.4.pth", "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth")
    restorer = GFPGANer(model_path=gfpgan_model_path, upscale=1, arch='clean', channel_multiplier=2, bg_upsampler=None)
    _, _, gfpgan_result = restorer.enhance(img_bgr, has_aligned=False, only_center_face=False, paste_back=True)
    if gfpgan_result.shape[:2] != img_bgr.shape[:2]:
        gfpgan_result = cv2.resize(gfpgan_result, (img_bgr.shape[1], img_bgr.shape[0]))
    mask_norm = (mask.astype(np.float32) / 255.0)[:, :, np.newaxis]
    blend_amount = strength / 100.0
    blended = img_bgr.astype(np.float32) * (1 - blend_amount) + gfpgan_result.astype(np.float32) * blend_amount
    result = blended * mask_norm + img_bgr.astype(np.float32) * (1 - mask_norm)
    return np.clip(result, 0, 255).astype(np.uint8)

def face_restore_gpu(img_bgr, scale=1):
    # Limitar tamaño para evitar OOM
    h, w = img_bgr.shape[:2]
    max_px = 1920
    if max(h, w) > max_px:
        factor = max_px / max(h, w)
        img_bgr = cv2.resize(img_bgr, (int(w * factor), int(h * factor)), interpolation=cv2.INTER_AREA)
    from gfpgan import GFPGANer
    bg_upsampler = build_upsampler_general()
    gfpgan_model_path = ensure_weight("GFPGANv1.4.pth", "https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth")
    restorer = GFPGANer(model_path=gfpgan_model_path, upscale=scale, arch='clean', channel_multiplier=2, bg_upsampler=bg_upsampler)
    _, _, output = restorer.enhance(img_bgr, has_aligned=False, only_center_face=False, paste_back=True)
    return output

def face_restore_codeformer(img_bgr, fidelity=0.5):
    # Limitar tamaño para evitar OOM (misma proteccion que face_restore_gpu)
    h, w = img_bgr.shape[:2]
    max_px = 1920
    if max(h, w) > max_px:
        factor = max_px / max(h, w)
        img_bgr = cv2.resize(img_bgr, (int(w * factor), int(h * factor)), interpolation=cv2.INTER_AREA)
    codeformer_path = r"C:\Users\Lambert 2\Desktop\voila\CodeFormer-master"
    if codeformer_path not in sys.path:
        sys.path.insert(0, codeformer_path)
    import torch
    from basicsr.utils import img2tensor, tensor2img
    from facelib.utils.face_restoration_helper import FaceRestoreHelper
    from basicsr.utils.registry import ARCH_REGISTRY
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    codeformer_model_path = r"C:\Users\Lambert 2\Desktop\voila\CodeFormer-master\weights\CodeFormer\codeformer.pth"
    net = ARCH_REGISTRY.get('CodeFormer')(dim_embd=512, codebook_size=1024, n_head=8, n_layers=9, connect_list=['32', '64', '128', '256']).to(device)
    checkpoint = torch.load(codeformer_model_path, map_location=device)
    net.load_state_dict(checkpoint['params_ema'])
    net.eval()
    face_helper = FaceRestoreHelper(upscale_factor=1, face_size=512, crop_ratio=(1, 1), det_model='retinaface_resnet50', save_ext='png', use_parse=True, device=device, model_rootpath=r"C:\Users\Lambert 2\Desktop\voila\CodeFormer-master\weights\facelib")
    face_helper.read_image(img_bgr)
    face_helper.get_face_landmarks_5()
    face_helper.align_warp_face()
    for cropped_face in face_helper.cropped_faces:
        cropped_face_t = img2tensor(cropped_face / 255., bgr2rgb=True, float32=True)
        cropped_face_t = cropped_face_t.unsqueeze(0).to(device)
        with torch.no_grad():
            output = net(cropped_face_t, w=fidelity, adain=True)[0]
            restored_face = tensor2img(output, rgb2bgr=True, min_max=(-1, 1))
        restored_face = restored_face.astype('uint8')
        face_helper.add_restored_face(restored_face)
    face_helper.get_inverse_affine(None)
    restored_img = face_helper.paste_faces_to_input_image()
    torch_lib.cuda.empty_cache()
    return restored_img

def general_enhance_gpu(img_bgr, scale=1):
    # Limitar tamaño de entrada para evitar OOM
    h, w = img_bgr.shape[:2]
    max_px = 1920
    if max(h, w) > max_px:
        factor = max_px / max(h, w)
        img_bgr = cv2.resize(img_bgr, (int(w * factor), int(h * factor)), interpolation=cv2.INTER_AREA)
    upsampler = build_upsampler_general()
    output, _ = upsampler.enhance(img_bgr, outscale=scale)
    return output

# ---------------------------------------------------------------------------
# Pipeline principal — elige GPU o CPU segun MODO_GPU
# ---------------------------------------------------------------------------
MAX_EFFECT_MEGAPIXELS = 16_000_000

def run_pipeline(img_bgr, options, progress_callback=None):
    global MODO_GPU
    img = img_bgr.copy()

    def report(msg):
        if progress_callback:
            progress_callback(msg)

    def free_gpu():
        import gc
        if MODO_GPU:
            torch_lib.cuda.empty_cache()
        gc.collect()

    if MODO_GPU:
        # --- PIPELINE GPU ---
        if options.get("general"):
            report("Aplicando mejora general (GPU)...")
            img = general_enhance_gpu(img, scale=1)
            free_gpu()

        if options.get("face"):
            motor = options.get("face_motor", "gfpgan")
            if motor == "codeformer":
                report("Restaurando rostros con CodeFormer (GPU)...")
                img = face_restore_codeformer(img, fidelity=options.get("face_fidelity", 0.5))
            else:
                report("Restaurando rostros con GFPGAN (GPU)...")
                img = face_restore_gpu(img, scale=1)
            free_gpu()

        needs_mask = options.get("beautify") or options.get("bg_enhance") or options.get("bg_blur")
        mask = None
        if needs_mask:
            report("Analizando sujeto y fondo (GPU)...")
            h, w = img.shape[:2]
            total_px = h * w
            if total_px > MAX_EFFECT_MEGAPIXELS:
                scale_factor = (MAX_EFFECT_MEGAPIXELS / total_px) ** 0.5
                small = cv2.resize(img, (max(1, int(w * scale_factor)), max(1, int(h * scale_factor))), interpolation=cv2.INTER_AREA)
                small_mask = get_foreground_mask(small)
                mask = cv2.resize(small_mask, (w, h), interpolation=cv2.INTER_LANCZOS4)
            else:
                mask = get_foreground_mask(img)

        if options.get("beautify"):
            report("Aplicando beautify (GPU)...")
            img = beautify_face_gpu(img, mask, strength=options.get("beautify_strength", 50))
            free_gpu()

        if options.get("bg_enhance"):
            report("Mejorando el fondo (GPU)...")
            img = enhance_background(img, mask)
            free_gpu()

        if options.get("bg_blur"):
            report("Desenfocando el fondo (GPU)...")
            img = blur_background(img, mask, blur_amount=options.get("bg_blur_amount", 25))
            free_gpu()

    else:
        # --- PIPELINE CPU ---
        if options.get("general"):
            report("Aplicando mejora de nitidez (CPU)...")
            img = enhance_cpu_nitidez(img)

        if options.get("face"):
            report("Suavizando piel (CPU)...")
            img = enhance_cpu_cara(img)

        needs_mask = options.get("bg_enhance") or options.get("bg_blur") or options.get("beautify")
        mask = None
        if needs_mask:
            report("Analizando sujeto y fondo (CPU)...")
            mask = get_mask_cpu(img)

        if options.get("beautify"):
            report("Aplicando suavizado (CPU)...")
            smooth = enhance_cpu_cara(img)
            mask_norm = (mask.astype(np.float32) / 255.0)[:, :, np.newaxis]
            img = (img.astype(np.float32) * (1 - mask_norm * 0.6) + smooth.astype(np.float32) * mask_norm * 0.6).astype(np.uint8)

        if options.get("bg_enhance"):
            report("Mejorando el fondo (CPU)...")
            img = enhance_background(img, mask)

        if options.get("bg_blur"):
            report("Desenfocando el fondo (CPU)...")
            img = blur_background(img, mask, blur_amount=options.get("bg_blur_amount", 25))

    if options.get("auto_color"):
        report("Aplicando color...")
        img = apply_color_preset(img, options.get("color_preset", "ninguno"))

    return img


def save_image_formato(img, path, formato):
    if formato == "jpg_low":
        cv2.imwrite(path, img, [cv2.IMWRITE_JPEG_QUALITY, 60])
    elif formato == "jpg_mid":
        cv2.imwrite(path, img, [cv2.IMWRITE_JPEG_QUALITY, 80])
    elif formato == "jpg_high":
        cv2.imwrite(path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
    else:
        cv2.imwrite(path, img)

def dialogo_formato(parent):
    dialog = QDialog(parent)
    dialog.setWindowTitle("Elegir formato de descarga")
    layout = QVBoxLayout()
    opciones = [
        ("JPG - Reducida (menor peso)", "jpg_low"),
        ("JPG - Calidad media", "jpg_mid"),
        ("JPG - Alta calidad", "jpg_high"),
        ("PNG - Sin perdida", "png"),
        ("TIFF - Profesional (Photoshop/Lightroom)", "tiff"),
    ]
    radios = []
    for label, value in opciones:
        rb = QRadioButton(label)
        layout.addWidget(rb)
        radios.append((rb, value))
    radios[2][0].setChecked(True)
    buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel)
    buttons.accepted.connect(dialog.accept)
    buttons.rejected.connect(dialog.reject)
    layout.addWidget(buttons)
    dialog.setLayout(layout)
    if dialog.exec() != QDialog.DialogCode.Accepted:
        return None
    return next(v for rb, v in radios if rb.isChecked())

# ---------------------------------------------------------------------------
# ToolCard y PresetGallery
# ---------------------------------------------------------------------------
class ToolCard(QFrame):
    def __init__(self, title, subtitle, parent=None):
        super().__init__(parent)
        self.setObjectName("toolCard")
        self.checkbox = QCheckBox()
        self.checkbox.setChecked(False)
        title_label = QLabel(title)
        title_label.setObjectName("sectionTitle")
        subtitle_label = QLabel(subtitle)
        subtitle_label.setObjectName("sectionSubtitle")
        text_layout = QVBoxLayout()
        text_layout.setSpacing(0)
        text_layout.addWidget(title_label)
        text_layout.addWidget(subtitle_label)
        header_layout = QHBoxLayout()
        header_layout.addWidget(self.checkbox)
        header_layout.addLayout(text_layout)
        header_layout.addStretch()
        self.extra_layout = QVBoxLayout()
        self.main_layout = QVBoxLayout()
        self.main_layout.addLayout(header_layout)
        self.main_layout.addLayout(self.extra_layout)
        self.setLayout(self.main_layout)

    def add_extra_widget(self, widget):
        self.extra_layout.addWidget(widget)

    def is_checked(self):
        return self.checkbox.isChecked()


class PresetGallery(QFrame):
    def __init__(self, title, subtitle, presets, parent=None):
        super().__init__(parent)
        self.setObjectName("toolCard")
        self.presets = presets
        self.selected_index = 0
        self.buttons = []
        self.expanded = False

        title_label = QLabel(title)
        title_label.setObjectName("sectionTitle")
        subtitle_label = QLabel(subtitle)
        subtitle_label.setObjectName("sectionSubtitle")
        text_layout = QVBoxLayout()
        text_layout.setSpacing(0)
        text_layout.addWidget(title_label)
        text_layout.addWidget(subtitle_label)

        self.btn_toggle = QPushButton("\u25b8")
        self.btn_toggle.setObjectName("secondary")
        self.btn_toggle.setFixedWidth(36)
        self.btn_toggle.clicked.connect(self.toggle_expanded)

        header_layout = QHBoxLayout()
        header_layout.addLayout(text_layout)
        header_layout.addStretch()
        header_layout.addWidget(self.btn_toggle)

        self.gallery_widget = QWidget()
        grid = QGridLayout(self.gallery_widget)
        grid.setSpacing(8)
        columns = 3
        for i, (name, value, color) in enumerate(presets):
            btn = QPushButton(name)
            btn.setObjectName("presetButton")
            btn.setCheckable(True)
            btn.setMinimumHeight(50)
            btn.setStyleSheet(self._button_style(color, selected=(i == 0)))
            btn.clicked.connect(lambda checked, idx=i: self._select(idx))
            self.buttons.append(btn)
            row, col = divmod(i, columns)
            grid.addWidget(btn, row, col)
        self.buttons[0].setChecked(True)

        self.slider_extra = QSlider(Qt.Orientation.Horizontal)
        self.slider_extra.setRange(0, 100)
        self.slider_extra.setValue(0)
        self.extra_label = QLabel("Intensidad manual extra: 0")
        self.extra_label.setObjectName("sectionSubtitle")
        self.slider_extra.valueChanged.connect(lambda v: self.extra_label.setText(f"Intensidad manual extra: {v}"))
        first_value = presets[1][1] if len(presets) > 1 else 0
        self.has_numeric_values = isinstance(first_value, (int, float))

        self.gallery_widget.setVisible(False)

        layout = QVBoxLayout()
        layout.addLayout(header_layout)
        layout.addWidget(self.gallery_widget)
        if self.has_numeric_values:
            layout.addWidget(self.extra_label)
            layout.addWidget(self.slider_extra)
        self.setLayout(layout)

    def toggle_expanded(self):
        self.expanded = not self.expanded
        self.gallery_widget.setVisible(self.expanded)
        self.btn_toggle.setText("\u25be" if self.expanded else "\u25b8")

    def _button_style(self, color, selected):
        border = "3px solid #A855F7" if selected else "1px solid #34343c"
        return f"""QPushButton {{ background-color: {color}; border: {border}; border-radius: 12px; color: white; font-weight: 600; font-size: 11px; }}"""

    def _select(self, idx):
        self.selected_index = idx
        for i, btn in enumerate(self.buttons):
            _, _, color = self.presets[i]
            btn.setChecked(i == idx)
            btn.setStyleSheet(self._button_style(color, selected=(i == idx)))

    def get_value(self):
        base = self.presets[self.selected_index][1]
        if isinstance(base, (int, float)):
            extra = self.slider_extra.value()
            return min(100, base + extra)
        return base

    def is_active(self):
        return self.selected_index != 0


# ---------------------------------------------------------------------------
# SidebarWidget
# ---------------------------------------------------------------------------
class SidebarWidget(QScrollArea):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWidgetResizable(True)
        self.setMaximumWidth(340)
        self.setMinimumWidth(300)

        self.card_general = ToolCard(
            "Mejora General",
            "Nitidez y detalle" + (" — Real-ESRGAN" if MODO_GPU else " — sin GPU")
        )
        self.card_face = ToolCard(
            "Mejora Facial",
            "Restauracion de rostros" + (" — GFPGAN / CodeFormer" if MODO_GPU else " — suavizado basico")
        )

        # Selector motor facial (solo GPU)
        self.combo_face_motor = QComboBox()
        self.combo_face_motor.addItem("GFPGAN (rapido)", "gfpgan")
        self.combo_face_motor.addItem("CodeFormer (mejor calidad)", "codeformer")

        self.slider_fidelity = QSlider(Qt.Orientation.Horizontal)
        self.slider_fidelity.setRange(0, 100)
        self.slider_fidelity.setValue(50)
        self.lbl_fidelity = QLabel("Fidelidad: 50 (equilibrio)")
        self.lbl_fidelity.setObjectName("sectionSubtitle")
        self.slider_fidelity.valueChanged.connect(self._update_fidelity_label)
        self.combo_face_motor.currentIndexChanged.connect(self._on_motor_changed)
        self.slider_fidelity.setVisible(False)
        self.lbl_fidelity.setVisible(False)

        face_options_widget = QWidget()
        face_options_layout = QVBoxLayout(face_options_widget)
        face_options_layout.setContentsMargins(4, 4, 4, 4)
        face_options_layout.addWidget(self.combo_face_motor)
        face_options_layout.addWidget(self.lbl_fidelity)
        face_options_layout.addWidget(self.slider_fidelity)
        face_options_widget.setVisible(False)

        self.btn_face_toggle = QPushButton("▸")
        self.btn_face_toggle.setObjectName("secondary")
        self.btn_face_toggle.setFixedWidth(36)
        self.btn_face_toggle.clicked.connect(lambda: self._toggle_face_options(face_options_widget))
        self.btn_face_toggle.setVisible(MODO_GPU)

        self.card_face.main_layout.itemAt(0).layout().addWidget(self.btn_face_toggle)
        self.card_face.extra_layout.addWidget(face_options_widget)
        self._face_options_expanded = False

        beautify_subtitle = "Suaviza la piel — IA" if MODO_GPU else "Suaviza la piel — basico"
        self.gallery_beautify = PresetGallery("Beautify", beautify_subtitle, presets=[
            ("Ninguno", 0, "#3a3a42"), ("Movie", 30, "#8e7cc3"), ("Glam", 80, "#c2185b"),
            ("Cute", 50, "#e57373"), ("Natural", 20, "#81c784"), ("Seda", 65, "#64b5f6"), ("Encanto", 45, "#ba68c8"),
        ])

        bg_subtitle = "Nitidez en el entorno" if MODO_GPU else "Nitidez en el fondo"
        self.card_bg_enhance = ToolCard("Mejora De Fondo", bg_subtitle)
        if not MODO_GPU:
            self.card_bg_enhance.setToolTip("Disponible en modo CPU con deteccion basica de fondo")

        self.gallery_bg_blur = PresetGallery("Desenfoque De Fondo", "Efecto retrato (bokeh)", presets=[
            ("Ninguno", 0, "#3a3a42"), ("Bajo", 15, "#4fc3f7"), ("Medio", 35, "#1e88e5"), ("Alto", 60, "#0d47a1"),
        ])

        self.gallery_color = PresetGallery("Auto Color", "Ajusta el perfil de colores", presets=[
            ("Ninguno", "ninguno", "#3a3a42"), ("Golden", "golden", "#d4a017"), ("Steady", "steady", "#90a4ae"),
            ("Balanced", "balanced", "#78909c"), ("Orange", "orange", "#e65100"), ("Silky", "silky", "#b0bec5"),
            ("Muted", "muted", "#78716c"), ("Teal", "teal", "#00796b"), ("Soft Warm", "soft_warm", "#bf8f5a"),
        ])

        # Indicador de modo
        # En modo CPU ocultar slider extra de beautify (no necesario)
        if not MODO_GPU:
            self.gallery_beautify.slider_extra.setVisible(False)
            self.gallery_beautify.extra_label.setVisible(False)

        if MODO_GPU:
            modo_text = "⚡ Modo GPU — Todos los efectos activos"
            modo_color = "#60b3ff"
            modo_bg = "background-color: #0a1a2e; border-radius: 8px;"
        else:
            modo_text = "🖥️ Modo CPU — Efectos compatibles activos"
            modo_color = "#60ff9a"
            modo_bg = "background-color: #0a2e1a; border-radius: 8px;"
        modo_label = QLabel(modo_text)
        modo_label.setStyleSheet(f"color: {modo_color}; font-size: 11px; font-weight: 600; padding: 6px; {modo_bg}")
        modo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        modo_label.setWordWrap(True)

        self.btn_apply = QPushButton("✨ Procesar")
        self.btn_apply.setObjectName("ctaPrimary")
        self.btn_apply.setMinimumHeight(46)
        self.btn_apply.setEnabled(False)

        self.progress = QProgressBar()
        self.progress.setVisible(False)
        self.progress.setRange(0, 0)

        self.status_label = QLabel("")
        self.status_label.setObjectName("status")

        sidebar_layout = QVBoxLayout()
        sidebar_title = QLabel("Barra De Herramientas De IA")
        sidebar_title.setObjectName("sectionTitle")
        sidebar_layout.addWidget(modo_label)
        sidebar_layout.addWidget(sidebar_title)
        sidebar_layout.addWidget(self.card_general)
        sidebar_layout.addWidget(self.card_face)
        sidebar_layout.addWidget(self.gallery_beautify)
        sidebar_layout.addWidget(self.card_bg_enhance)
        sidebar_layout.addWidget(self.gallery_bg_blur)
        sidebar_layout.addWidget(self.gallery_color)
        sidebar_layout.addWidget(self.btn_apply)
        sidebar_layout.addWidget(self.progress)
        sidebar_layout.addWidget(self.status_label)
        sidebar_layout.addStretch()

        container = QWidget()
        container.setLayout(sidebar_layout)
        self.setWidget(container)
        self.load_config()

    def _update_fidelity_label(self, v):
        if v < 30:
            desc = "max calidad"
        elif v > 70:
            desc = "max fidelidad"
        else:
            desc = "equilibrio"
        self.lbl_fidelity.setText(f"Fidelidad: {v} ({desc})")

    def _toggle_face_options(self, widget):
        self._face_options_expanded = not self._face_options_expanded
        widget.setVisible(self._face_options_expanded)
        self.btn_face_toggle.setText("▾" if self._face_options_expanded else "▸")

    def _on_motor_changed(self, idx):
        is_codeformer = self.combo_face_motor.currentData() == "codeformer"
        self.slider_fidelity.setVisible(is_codeformer)
        self.lbl_fidelity.setVisible(is_codeformer)

    def get_pipeline_options(self):
        return {
            "general": self.card_general.is_checked(),
            "general_scale": 1,
            "face": self.card_face.is_checked(),
            "face_motor": self.combo_face_motor.currentData(),
            "face_fidelity": self.slider_fidelity.value() / 100.0,
            "beautify": self.gallery_beautify.is_active(),
            "beautify_strength": self.gallery_beautify.get_value(),
            "bg_enhance": self.card_bg_enhance.is_checked(),
            "bg_blur": self.gallery_bg_blur.is_active(),
            "bg_blur_amount": self.gallery_bg_blur.get_value(),
            "auto_color": self.gallery_color.is_active(),
            "color_preset": self.gallery_color.get_value(),
        }

    def has_any_active(self):
        opts = self.get_pipeline_options()
        return any([opts["general"], opts["face"], opts["beautify"], opts["bg_enhance"], opts["bg_blur"], opts["auto_color"]])

    def set_busy(self, busy):
        self.btn_apply.setEnabled(not busy)
        self.progress.setVisible(busy)

    def save_config(self):
        import json
        config = self.get_pipeline_options()
        config["beautify_selected"] = self.gallery_beautify.selected_index
        config["beautify_extra"] = self.gallery_beautify.slider_extra.value()
        config["bg_blur_selected"] = self.gallery_bg_blur.selected_index
        config["color_selected"] = self.gallery_color.selected_index
        config["general_checked"] = self.card_general.is_checked()
        config["face_checked"] = self.card_face.is_checked()
        config["bg_enhance_checked"] = self.card_bg_enhance.is_checked()
        with open("voila_config.json", "w") as f:
            json.dump(config, f)
        self.status_label.setText("Configuracion guardada.")

    def load_config(self):
        import json
        if not os.path.isfile("voila_config.json"):
            return
        try:
            with open("voila_config.json", "r") as f:
                config = json.load(f)
            self.gallery_beautify._select(config.get("beautify_selected", 0))
            self.gallery_beautify.slider_extra.setValue(config.get("beautify_extra", 0))
            self.gallery_bg_blur._select(config.get("bg_blur_selected", 0))
            self.gallery_color._select(config.get("color_selected", 0))
            self.card_general.checkbox.setChecked(config.get("general_checked", False))
            self.card_face.checkbox.setChecked(config.get("face_checked", False))
            self.card_bg_enhance.checkbox.setChecked(config.get("bg_enhance_checked", False))
        except Exception:
            pass


# ---------------------------------------------------------------------------
# SingleTab
# ---------------------------------------------------------------------------
class SingleTab(QWidget):
    def __init__(self, sidebar):
        super().__init__()
        self.sidebar = sidebar
        self.input_path = None
        self.original_img_bgr = None
        self.result_img_bgr = None
        self.undo_stack = []
        self.redo_stack = []

        self.compare = CompareWidget()

        self.btn_select = QPushButton("Seleccionar imagen")
        self.btn_select.setObjectName("secondary")
        self.btn_select.clicked.connect(self.select_image)

        self.btn_undo = QPushButton("Deshacer")
        self.btn_undo.setObjectName("secondary")
        self.btn_undo.clicked.connect(self.undo)
        self.btn_undo.setEnabled(False)
        self.btn_undo.setShortcut("Ctrl+Z")

        self.btn_redo = QPushButton("Rehacer")
        self.btn_redo.setObjectName("secondary")
        self.btn_redo.clicked.connect(self.redo)
        self.btn_redo.setEnabled(False)
        self.btn_redo.setShortcut("Ctrl+Y")

        self.btn_save = QPushButton("Descargar")
        self.btn_save.clicked.connect(self.save_result)
        self.btn_save.setEnabled(False)

        self.btn_save_config = QPushButton("Guardar configuracion")
        self.btn_save_config.setObjectName("secondary")
        self.btn_save_config.clicked.connect(self.sidebar.save_config)

        top_buttons = QHBoxLayout()
        top_buttons.addWidget(self.btn_select)
        top_buttons.addWidget(self.btn_undo)
        top_buttons.addWidget(self.btn_redo)
        top_buttons.addStretch()
        top_buttons.addWidget(self.btn_save_config)
        top_buttons.addWidget(self.btn_save)

        center_layout = QVBoxLayout()
        center_layout.addLayout(top_buttons)
        center_layout.addWidget(self.compare, stretch=1)

        main_layout = QHBoxLayout()
        main_layout.addLayout(center_layout, stretch=3)
        main_layout.addWidget(self.sidebar, stretch=1)
        self.setLayout(main_layout)

        self.sidebar.btn_apply.clicked.connect(self.apply_pipeline)

    def _bgr_to_pixmap(self, img_bgr):
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        h, w, ch = img_rgb.shape
        qimg = QImage(img_rgb.data, w, h, ch * w, QImage.Format.Format_RGB888)
        return QPixmap.fromImage(qimg.copy())

    def select_image(self):
        path, _ = QFileDialog.getOpenFileName(self, "Selecciona una imagen", "", "Imagenes (*.png *.jpg *.jpeg *.bmp *.webp)")
        if path:
            self.load_image_path(path)

    def load_image_path(self, path):
        self.input_path = path
        self.original_img_bgr = cv2.imread(path, cv2.IMREAD_COLOR)
        if self.original_img_bgr is None:
            QMessageBox.critical(self, "Error", f"No se pudo abrir la imagen:\n{path}")
            return
        self.result_img_bgr = None
        self.undo_stack = []
        self.redo_stack = []
        pixmap = self._bgr_to_pixmap(self.original_img_bgr)
        self.compare.set_images(pixmap, pixmap)
        self.sidebar.btn_apply.setEnabled(True)
        self.btn_save.setEnabled(False)
        self.btn_undo.setEnabled(False)
        self.btn_redo.setEnabled(False)
        self.sidebar.status_label.setText("")

    def apply_pipeline(self):
        if self.original_img_bgr is None:
            return
        if not self.sidebar.has_any_active():
            QMessageBox.information(self, "Nada seleccionado", "Activa al menos una herramienta antes de aplicar.")
            return
        options = self.sidebar.get_pipeline_options()
        self.sidebar.set_busy(True)
        self.btn_select.setEnabled(False)
        self.sidebar.status_label.setText("Procesando...")
        QApplication.processEvents()
        try:
            result = run_pipeline(self.original_img_bgr, options, progress_callback=lambda m: (self.sidebar.status_label.setText(m), QApplication.processEvents()))
            self._on_done(result)
        except Exception as e:
            self._on_error(str(e))

    def _on_done(self, result_img):
        self.sidebar.set_busy(False)
        self.btn_select.setEnabled(True)
        self.sidebar.status_label.setText("Listo.")
        previous = self.result_img_bgr if self.result_img_bgr is not None else self.original_img_bgr
        self.undo_stack.append(previous.copy())
        self.redo_stack = []
        self.btn_undo.setEnabled(True)
        self.btn_redo.setEnabled(False)
        self.result_img_bgr = result_img
        self.btn_save.setEnabled(True)
        self.compare.set_images(self._bgr_to_pixmap(self.original_img_bgr), self._bgr_to_pixmap(result_img))

    def _on_error(self, message):
        self.sidebar.set_busy(False)
        self.btn_select.setEnabled(True)
        self.sidebar.status_label.setText("Error.")
        QMessageBox.critical(self, "Error", f"Ocurrio un error:\n{message}")

    def undo(self):
        if not self.undo_stack:
            return
        current = self.result_img_bgr if self.result_img_bgr is not None else self.original_img_bgr
        self.redo_stack.append(current.copy())
        self.result_img_bgr = self.undo_stack.pop()
        self.compare.set_images(self._bgr_to_pixmap(self.original_img_bgr), self._bgr_to_pixmap(self.result_img_bgr))
        self.btn_redo.setEnabled(True)
        self.btn_undo.setEnabled(len(self.undo_stack) > 0)
        self.btn_save.setEnabled(True)
        self.sidebar.status_label.setText("Cambio deshecho.")

    def redo(self):
        if not self.redo_stack:
            return
        current = self.result_img_bgr if self.result_img_bgr is not None else self.original_img_bgr
        self.undo_stack.append(current.copy())
        self.result_img_bgr = self.redo_stack.pop()
        self.compare.set_images(self._bgr_to_pixmap(self.original_img_bgr), self._bgr_to_pixmap(self.result_img_bgr))
        self.btn_undo.setEnabled(True)
        self.btn_redo.setEnabled(len(self.redo_stack) > 0)
        self.btn_save.setEnabled(True)
        self.sidebar.status_label.setText("Cambio rehecho.")

    def save_result(self):
        if self.result_img_bgr is None:
            return
        formato = dialogo_formato(self)
        if not formato:
            return
        ext_map = {"jpg_low": ".jpg", "jpg_mid": ".jpg", "jpg_high": ".jpg", "png": ".png", "tiff": ".tiff"}
        filter_map = {"jpg_low": "JPEG (*.jpg)", "jpg_mid": "JPEG (*.jpg)", "jpg_high": "JPEG (*.jpg)", "png": "PNG (*.png)", "tiff": "TIFF (*.tiff)"}
        path, _ = QFileDialog.getSaveFileName(self, "Guardar imagen", "resultado" + ext_map[formato], filter_map[formato])
        if not path:
            return
        save_image_formato(self.result_img_bgr, path, formato)
        QMessageBox.information(self, "Guardado", f"Imagen guardada en:\n{path}")


# ---------------------------------------------------------------------------
# BatchPipelineThread
# ---------------------------------------------------------------------------
class BatchPipelineThread(QThread):
    progress_update = pyqtSignal(int, int, str)
    item_done = pyqtSignal(int, str)
    item_error = pyqtSignal(int, str)
    finished_all = pyqtSignal()
    paused_at = pyqtSignal(int)

    def __init__(self, input_paths, output_dir, options, formato="jpg_low", start_index=0):
        super().__init__()
        self.input_paths = input_paths
        self.output_dir = output_dir
        self.options = options
        self.formato = formato
        self.start_index = start_index
        self._stop_requested = False

    def stop(self):
        self._stop_requested = True

    def run(self):
        ext_map = {"jpg_low": ".jpg", "jpg_mid": ".jpg", "jpg_high": ".jpg", "png": ".png", "tiff": ".tiff"}
        total = len(self.input_paths)
        os.makedirs(self.output_dir, exist_ok=True)
        for i, input_path in enumerate(self.input_paths):
            if self._stop_requested:
                self.paused_at.emit(self.start_index + i)
                return
            filename = os.path.basename(input_path)
            self.progress_update.emit(self.start_index + i + 1, self.start_index + total, filename)
            try:
                img = cv2.imread(input_path, cv2.IMREAD_COLOR)
                if img is None:
                    raise ValueError("No se pudo leer la imagen")
                output = run_pipeline(img, self.options)
                base_name = os.path.splitext(filename)[0]
                out_path = os.path.join(self.output_dir, f"{base_name}_mejorada{ext_map[self.formato]}")
                save_image_formato(output, out_path, self.formato)
                self.item_done.emit(self.start_index + i, out_path)
            except Exception as e:
                self.item_error.emit(self.start_index + i, str(e))
        self.finished_all.emit()


# ---------------------------------------------------------------------------
# BatchTab
# ---------------------------------------------------------------------------
class BatchTab(QWidget):
    def __init__(self, sidebar, single_tab):
        super().__init__()
        self.sidebar = sidebar
        self.single_tab = single_tab
        self.input_paths = []
        self.paths_to_process = []
        self.output_dir = None
        self.thread = None
        self._paused_at = 0
        self._is_paused = False

        self.btn_select_folder = QPushButton("Seleccionar imagenes (max 30)")
        self.btn_select_folder.setObjectName("secondary")
        self.btn_select_folder.clicked.connect(self.select_images)

        self.btn_select_mode = QPushButton("Seleccion")
        self.btn_select_mode.setObjectName("selectMain")
        self.btn_select_mode.setCheckable(True)
        self.btn_select_mode.clicked.connect(self.toggle_select_mode)
        self.btn_select_mode.setEnabled(False)

        self.btn_select_arrow = QPushButton("▼")
        self.btn_select_arrow.setObjectName("selectArrow")
        self.btn_select_arrow.setFixedWidth(36)
        self.btn_select_arrow.setEnabled(False)
        self.btn_select_arrow.clicked.connect(self.show_select_menu)

        self.btn_remove = QPushButton("Eliminar")
        self.btn_remove.setObjectName("secondary")
        self.btn_remove.clicked.connect(self.remove_selected)
        self.btn_remove.setEnabled(False)

        self.btn_process_all = QPushButton("✨ Procesar")
        self.btn_process_all.setObjectName("ctaPrimary")
        self.btn_process_all.setMinimumHeight(46)
        self.btn_process_all.clicked.connect(self.process_all)
        self.btn_process_all.setEnabled(False)

        self.btn_open_output = QPushButton("Descargar")
        self.btn_open_output.setObjectName("secondary")
        self.btn_open_output.clicked.connect(self.open_output_folder)
        self.btn_open_output.setEnabled(False)

        self.thumb_size = 120
        self.thumb_container = QWidget()
        self.thumb_grid = QGridLayout(self.thumb_container)
        self.thumb_grid.setSpacing(4)
        self.thumb_scroll = QScrollArea()
        self.thumb_scroll.setWidgetResizable(True)
        self.thumb_scroll.setWidget(self.thumb_container)
        self.thumb_scroll.wheelEvent = self._wheel_zoom
        self.thumb_scroll.resizeEvent = self._on_scroll_resize
        self._resize_timer = QTimer()
        self._resize_timer.setSingleShot(True)
        self._resize_timer.timeout.connect(self._rebuild_thumbs)
        self._last_scroll_width = 0
        self.thumb_items = []
        self.fullscreen_widget = None

        self.btn_view = QPushButton("Vista ▼")
        self.btn_view.setObjectName("secondary")
        self.btn_view.clicked.connect(self.show_view_menu)

        info_label = QLabel("Selecciona imagenes, configura herramientas y pulsa 'Procesar'.")
        info_label.setObjectName("status")

        self.progress = QProgressBar()
        self.progress.setVisible(False)

        self.btn_pause = QPushButton("⏸ Pausar")
        self.btn_pause.setObjectName("secondary")
        self.btn_pause.setVisible(False)
        self.btn_pause.clicked.connect(self.toggle_pause)

        self.status_label = QLabel("Selecciona imagenes para empezar.")
        self.status_label.setObjectName("status")

        ajustes_title = QLabel("Ajustes de salida")
        ajustes_title.setObjectName("sectionTitle")

        self.combo_formato = QComboBox()
        self.combo_formato.addItem("JPG - Reducida (menor peso)", "jpg_low")
        self.combo_formato.addItem("JPG - Calidad media", "jpg_mid")
        self.combo_formato.addItem("JPG - Alta calidad", "jpg_high")
        self.combo_formato.addItem("PNG - Sin perdida", "png")
        self.combo_formato.addItem("TIFF - Profesional", "tiff")
        self.combo_formato.setCurrentIndex(0)

        self.lbl_output_dir = QLabel("Carpeta: (misma que las fotos)")
        self.lbl_output_dir.setObjectName("status")
        self.lbl_output_dir.setWordWrap(True)

        self.btn_choose_dir = QPushButton("Cambiar carpeta de destino")
        self.btn_choose_dir.setObjectName("secondary")
        self.btn_choose_dir.clicked.connect(self.choose_output_dir)

        select_layout = QHBoxLayout()
        select_layout.setSpacing(0)
        select_layout.addWidget(self.btn_select_mode)
        select_layout.addWidget(self.btn_select_arrow)

        self.btn_save_config_batch = QPushButton("Guardar configuracion")
        self.btn_save_config_batch.setObjectName("secondary")
        self.btn_save_config_batch.clicked.connect(self.sidebar.save_config)

        top_layout = QHBoxLayout()
        top_layout.addWidget(self.btn_select_folder)
        top_layout.addLayout(select_layout)
        top_layout.addWidget(self.btn_remove)
        top_layout.addWidget(self.btn_view)
        top_layout.addStretch()
        top_layout.addWidget(self.btn_save_config_batch)
        top_layout.addWidget(self.btn_open_output)

        ajustes_layout = QVBoxLayout()
        ajustes_layout.addWidget(ajustes_title)
        ajustes_layout.addWidget(self.combo_formato)
        ajustes_layout.addWidget(self.lbl_output_dir)
        ajustes_layout.addWidget(self.btn_choose_dir)

        left_layout = QVBoxLayout()
        left_layout.addLayout(top_layout)
        left_layout.addWidget(info_label)
        left_layout.addWidget(self.thumb_scroll, stretch=1)
        left_layout.addLayout(ajustes_layout)
        left_layout.addWidget(self.progress)
        left_layout.addWidget(self.btn_pause)
        left_layout.addWidget(self.status_label)

        main_layout = QHBoxLayout()
        main_layout.addLayout(left_layout, stretch=3)
        main_layout.addWidget(self.sidebar, stretch=1)
        self.setLayout(main_layout)

        try:
            self.sidebar.btn_apply.clicked.disconnect()
        except Exception:
            pass
        self.sidebar.btn_apply.clicked.connect(self.process_all)
        self.sidebar.btn_apply.setEnabled(True)

    def choose_output_dir(self):
        folder = QFileDialog.getExistingDirectory(self, "Selecciona carpeta de destino")
        if folder:
            self.output_dir = folder
            self.lbl_output_dir.setText(f"Carpeta: {folder}")

    def select_images(self):
        paths, _ = QFileDialog.getOpenFileNames(self, "Selecciona imagenes (max 30)", "", "Imagenes (*.png *.jpg *.jpeg *.bmp *.webp)")
        if not paths:
            return
        if len(paths) > 30:
            QMessageBox.warning(self, "Limite alcanzado", f"Has seleccionado {len(paths)} imagenes.\nEl maximo permitido es 30.")
            return
        self.input_paths = list(paths)
        self._clear_thumbs()
        for full_path in self.input_paths:
            self._add_thumb(full_path)
        self.btn_select_mode.setEnabled(True)
        self.btn_select_mode.setChecked(False)
        self.output_dir = os.path.join(os.path.dirname(self.input_paths[0]), "mejoradas")
        self.lbl_output_dir.setText(f"Carpeta: {self.output_dir}")
        self.status_label.setText(f"{len(self.input_paths)} imagenes seleccionadas.")
        self.btn_process_all.setEnabled(True)
        self.btn_remove.setEnabled(True)
        self.btn_open_output.setEnabled(False)

    def _clear_thumbs(self):
        while self.thumb_grid.count():
            item = self.thumb_grid.takeAt(0)
            if item.widget():
                item.widget().deleteLater()
        self.thumb_items = []

    def _add_thumb(self, full_path):
        filename = os.path.basename(full_path)
        size = self.thumb_size
        columns = max(1, (self.thumb_scroll.viewport().width() or 600) // (size + 12))

        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setSpacing(2)
        layout.setContentsMargins(2, 2, 2, 2)

        cb = QCheckBox()
        cb.setVisible(False)
        layout.addWidget(cb)

        thumb_label = QLabel()
        thumb_label.setFixedSize(size, size)
        thumb_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        thumb_label.setStyleSheet("border: 1px solid #2c2c34; border-radius: 6px; background-color: #1c1c22;")

        img = cv2.imread(full_path, cv2.IMREAD_COLOR)
        if img is not None:
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            h, w, ch = img_rgb.shape
            qimg = QImage(img_rgb.data, w, h, ch * w, QImage.Format.Format_RGB888)
            pixmap = QPixmap.fromImage(qimg.copy())
            thumb_label.setPixmap(pixmap.scaled(size, size, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))

        thumb_label.mouseDoubleClickEvent = lambda e, p=full_path: self._open_fullscreen(p)
        layout.addWidget(thumb_label)

        name_label = QLabel(filename)
        name_label.setWordWrap(True)
        name_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        name_label.setMaximumWidth(size + 8)
        name_label.setObjectName("status")
        layout.addWidget(name_label)

        idx = len(self.thumb_items)
        row, col = divmod(idx, columns)
        self.thumb_grid.addWidget(container, row, col)
        self.thumb_items.append((full_path, cb, name_label, container))

    def toggle_select_mode(self, checked):
        for _, cb, _, _ in self.thumb_items:
            cb.setVisible(checked)
            if not checked:
                cb.setChecked(False)
        self.btn_remove.setEnabled(checked)
        self.btn_select_arrow.setEnabled(checked)

    def show_select_menu(self):
        from PyQt6.QtWidgets import QMenu
        menu = QMenu(self)
        action_all = QAction("Todo", self)
        action_none = QAction("Nada", self)
        action_all.triggered.connect(self.select_all)
        action_none.triggered.connect(self.select_none)
        menu.addAction(action_all)
        menu.addAction(action_none)
        menu.exec(self.btn_select_arrow.mapToGlobal(self.btn_select_arrow.rect().bottomLeft()))

    def select_all(self):
        for _, cb, _, _ in self.thumb_items:
            if cb.isVisible():
                cb.setChecked(True)

    def select_none(self):
        for _, cb, _, _ in self.thumb_items:
            if cb.isVisible():
                cb.setChecked(False)

    def _on_scroll_resize(self, event):
        QScrollArea.resizeEvent(self.thumb_scroll, event)
        new_width = self.thumb_scroll.viewport().width()
        if abs(new_width - self._last_scroll_width) > 30 and self.thumb_items:
            self._resize_timer.start(300)

    def _rebuild_thumbs(self):
        if not self.thumb_items:
            return
        new_width = self.thumb_scroll.viewport().width()
        self._last_scroll_width = new_width
        paths = [p for p, _, _, _ in self.thumb_items]
        self._clear_thumbs()
        for path in paths:
            self._add_thumb(path)

    def show_view_menu(self):
        from PyQt6.QtWidgets import QMenu
        menu = QMenu(self)
        action_small = QAction("Iconos medianos", self)
        action_large = QAction("Iconos grandes", self)
        action_detail = QAction("Detalles", self)
        action_small.triggered.connect(lambda: self._set_thumb_size(120))
        action_large.triggered.connect(lambda: self._set_thumb_size(200))
        action_detail.triggered.connect(lambda: self._set_thumb_size(48))
        menu.addAction(action_small)
        menu.addAction(action_large)
        menu.addAction(action_detail)
        menu.exec(self.btn_view.mapToGlobal(self.btn_view.rect().bottomLeft()))

    def _set_thumb_size(self, size):
        self.thumb_size = size
        paths = [p for p, _, _, _ in self.thumb_items]
        self._clear_thumbs()
        for path in paths:
            self._add_thumb(path)

    def _wheel_zoom(self, event):
        mods = event.modifiers()
        if mods & Qt.KeyboardModifier.ControlModifier:
            delta = event.angleDelta().y()
            new_size = min(300, self.thumb_size + 20) if delta > 0 else max(48, self.thumb_size - 20)
            if new_size != self.thumb_size:
                self._set_thumb_size(new_size)
        else:
            QScrollArea.wheelEvent(self.thumb_scroll, event)

    def _open_fullscreen(self, full_path):
        if self.fullscreen_widget is not None:
            self.fullscreen_widget.close()
            self.fullscreen_widget = None
            return
        img = cv2.imread(full_path, cv2.IMREAD_COLOR)
        if img is None:
            return
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        h, w, ch = img_rgb.shape
        qimg = QImage(img_rgb.data, w, h, ch * w, QImage.Format.Format_RGB888)
        pixmap = QPixmap.fromImage(qimg.copy())
        viewer = QWidget(self)
        viewer.setStyleSheet("background-color: #000000;")
        viewer.setGeometry(self.rect())
        label = QLabel(viewer)
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        label.setGeometry(viewer.rect())
        label.setPixmap(pixmap.scaled(viewer.width(), viewer.height(), Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))
        close_btn = QPushButton("✕ Cerrar", viewer)
        close_btn.setObjectName("secondary")
        close_btn.move(10, 10)
        close_btn.clicked.connect(lambda: (viewer.close(), setattr(self, 'fullscreen_widget', None)))
        viewer.show()
        self.fullscreen_widget = viewer

    def remove_selected(self):
        checked_indices = [i for i, (_, cb, _, _) in enumerate(self.thumb_items) if cb.isChecked()]
        if checked_indices:
            for i in sorted(checked_indices, reverse=True):
                self.input_paths.pop(i)
        elif self.thumb_items:
            self.input_paths.pop()
        self._clear_thumbs()
        for full_path in self.input_paths:
            self._add_thumb(full_path)
        if not self.input_paths:
            self.btn_process_all.setEnabled(False)
            self.btn_remove.setEnabled(False)
            self.status_label.setText("No hay imagenes seleccionadas.")
        else:
            self.status_label.setText(f"{len(self.input_paths)} imagenes seleccionadas.")

    def _start_thread(self, paths, start_index=0):
        formato = self.combo_formato.currentData()
        options = self.sidebar.get_pipeline_options()
        self.progress.setRange(0, len(self.paths_to_process))
        self.thread = BatchPipelineThread(paths, self.output_dir, options, formato, start_index)
        self.thread.progress_update.connect(self.on_progress)
        self.thread.item_done.connect(self.on_item_done)
        self.thread.item_error.connect(self.on_item_error)
        self.thread.finished_all.connect(self.on_finished_all)
        self.thread.paused_at.connect(self.on_paused_at)
        self.thread.start()

    def process_all(self):
        if self._is_paused:
            self._is_paused = False
            self.btn_pause.setText("⏸ Pausar")
            self.status_label.setText("Procesando...")
            remaining = self.paths_to_process[self._paused_at:]
            self._start_thread(remaining, self._paused_at)
            return

        if not self.input_paths:
            return
        if not self.sidebar.has_any_active():
            QMessageBox.information(self, "Nada seleccionado", "Activa al menos una herramienta en la barra lateral.")
            return

        select_mode_active = self.btn_select_mode.isChecked()
        checked = [path for path, cb, _, _ in self.thumb_items if cb.isChecked()]
        self.paths_to_process = checked if (select_mode_active and checked) else self.input_paths

        self.btn_process_all.setEnabled(False)
        self.sidebar.btn_apply.setEnabled(False)
        self.btn_select_folder.setEnabled(False)
        self.progress.setVisible(True)
        self.progress.setRange(0, len(self.paths_to_process))
        self.progress.setValue(0)
        self.btn_pause.setVisible(True)
        self.btn_pause.setText("⏸ Pausar")
        self._is_paused = False
        self._paused_at = 0
        self._start_thread(self.paths_to_process, 0)

    def toggle_pause(self):
        if self._is_paused:
            self._is_paused = False
            self.btn_pause.setText("⏸ Pausar")
            self.status_label.setText("Procesando...")
            remaining = self.paths_to_process[self._paused_at:]
            if remaining:
                self._start_thread(remaining, self._paused_at)
        else:
            self._is_paused = True
            self.btn_pause.setText("▶ Continuar")
            self.status_label.setText("Pausando... terminara la foto actual y se detendra.")
            if self.thread and self.thread.isRunning():
                self.thread.stop()

    def on_paused_at(self, index):
        self._paused_at = index
        self.status_label.setText(f"Pausado en foto {index + 1}. Pulsa Continuar para seguir.")

    def on_progress(self, current, total, filename):
        self.progress.setValue(current - 1)
        self.status_label.setText(f"Procesando {current}/{total}: {filename}")

    def on_item_done(self, index, out_path):
        if index < len(self.thumb_items):
            _, _, name_label, container = self.thumb_items[index]
            filename = os.path.basename(self.input_paths[index]) if index < len(self.input_paths) else ""
            name_label.setText(f"✓ {filename}")
            container.setStyleSheet("background-color: #1a2e1a; border-radius: 8px;")
        self.progress.setValue(index + 1)

    def on_item_error(self, index, message):
        if index < len(self.thumb_items):
            _, _, name_label, container = self.thumb_items[index]
            filename = os.path.basename(self.input_paths[index]) if index < len(self.input_paths) else ""
            name_label.setText(f"✗ {filename}")
            container.setStyleSheet("background-color: #2e1a1a; border-radius: 8px;")
        self.progress.setValue(index + 1)

    def on_finished_all(self):
        if self._is_paused:
            return
        self.btn_process_all.setEnabled(True)
        self.sidebar.btn_apply.setEnabled(True)
        self.btn_select_folder.setEnabled(True)
        self.btn_open_output.setEnabled(True)
        self.btn_pause.setVisible(False)
        self.status_label.setText(f"Completado. Resultados en: {self.output_dir}")

    def open_output_folder(self):
        if self.output_dir and os.path.isdir(self.output_dir):
            os.startfile(self.output_dir)


# ---------------------------------------------------------------------------
# MainWindow
# ---------------------------------------------------------------------------
class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(f"Voila Photo — {'Modo GPU ⚡' if MODO_GPU else 'Modo CPU 🖥️'}")
        self.setMinimumSize(1100, 720)
        self.setAcceptDrops(True)

        title = QLabel("Voila Photo")
        title.setObjectName("title")

        modo_badge = QLabel(f"{'⚡ GPU' if MODO_GPU else '🖥️ CPU'}")
        modo_badge.setStyleSheet(f"color: {'#60b3ff' if MODO_GPU else '#60ff9a'}; font-weight: 700; font-size: 13px;")

        title_layout = QHBoxLayout()
        title_layout.addWidget(title)
        title_layout.addWidget(modo_badge)
        title_layout.addStretch()

        self.sidebar_single = SidebarWidget()
        self.sidebar_batch = SidebarWidget()

        self.tabs = QTabWidget()
        self.single_tab = SingleTab(self.sidebar_single)
        self.batch_tab = BatchTab(self.sidebar_batch, self.single_tab)
        self.tabs.addTab(self.single_tab, "Imagen individual")
        self.tabs.addTab(self.batch_tab, "Procesar por lotes")

        main_layout = QVBoxLayout()
        main_layout.addLayout(title_layout)
        main_layout.addWidget(self.tabs, stretch=1)
        self.setLayout(main_layout)

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            urls = event.mimeData().urls()
            if any(url.toLocalFile().lower().endswith(IMAGE_EXTENSIONS) for url in urls):
                event.acceptProposedAction()

    def dropEvent(self, event):
        urls = event.mimeData().urls()
        for url in urls:
            path = url.toLocalFile()
            if path.lower().endswith(IMAGE_EXTENSIONS):
                self.tabs.setCurrentWidget(self.single_tab)
                self.single_tab.load_image_path(path)
                break


if __name__ == "__main__":
    mp_process.freeze_support()
    app = QApplication(sys.argv)
    app.setStyleSheet(STYLE_SHEET)

    # Mostrar dialogo de seleccion de modo
    dialogo = DialogoModo()
    if not dialogo.exec():
        sys.exit(0)

    # Establecer modo global
    MODO_GPU = dialogo.modo_elegido == "gpu"

    window = MainWindow()
    window.show()
    sys.exit(app.exec())