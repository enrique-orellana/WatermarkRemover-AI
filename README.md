# WatermarkRemover-AI

**AI-Powered Watermark Removal Tool using Florence-2 and LaMA Models**

🇬🇧 English | 🇫🇷 Français | 🇨🇳 中文 | 🇯🇵 日本語 | 🇧🇷 Português | 🧠 Brainrot

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## Overview

`WatermarkRemover-AI` is a cutting-edge application that leverages AI models for precise watermark detection and seamless removal. Perfect for removing watermarks from AI-generated videos like Sora, Sora 2, Runway, and others.

It uses Florence-2 from Microsoft for watermark identification and LaMA for inpainting to fill in the removed regions naturally. The software features a modern GUI built with PyWebview for an accessible and intuitive experience.

## Fork Notes

This fork keeps the original app idea, but changes the runtime and installer so it is easier to run on modern GPUs and easier to trust.

- **AMD GPU support** - The original repo was mostly CUDA-oriented. This fork adds automatic backend selection for NVIDIA CUDA, AMD DirectML on Windows, and AMD ROCm on Linux so the app can use your GPU instead of falling back to CPU.
- **Safer startup path** - The Windows launcher now uses the local virtual environment, and the runtime avoids hardcoded `.cuda()` calls so device placement matches the selected backend.
- **Cleaner dependency stack** - Package versions are pinned to combinations that work with Florence-2, LaMA, and the GPU backends in this fork. This avoids the import crashes caused by newer incompatible wheels.
- **Trusted installation sources** - The setup scripts were simplified to use official package and model sources only, with no mirror/trusted-host shortcuts.
- **Less fragile inpainting load path** - LaMA is loaded directly instead of pulling the whole `iopaint` model manager, which avoids importing optional model code that is not needed for watermark removal.

## Screenshot

![App Screenshot](assets/screenshot-preview.png)

## Demo


https://github.com/user-attachments/assets/505be2a8-8eda-4def-90b6-5a4ceefee456


---

## Features

- **Smart Detection** - AI-powered watermark detection using Florence-2
- **Seamless Removal** - LaMA inpainting for natural-looking results
- **Video Support** - Process videos with two-pass detection and audio preservation
- **AI Video Ready** - Remove watermarks from Sora, Sora 2, Runway, and other AI-generated videos
- **Batch Processing** - Handle entire folders at once
- **Preview Mode** - Preview detected watermarks before processing
- **Fade In/Out Handling** - Extend masks for watermarks that fade in/out
- **GPU Acceleration** - NVIDIA CUDA, AMD ROCm on Linux, and AMD DirectML on Windows
- **Multi-Language UI** - Available in English, French, Chinese, Japanese, Portuguese, and more
- **Themes** - Multiple UI themes to choose from

---

## Installation

### Windows

The setup script downloads a portable Python environment automatically - no system Python required.

On NVIDIA GPUs, it installs the CUDA build of PyTorch. On AMD GPUs, it uses DirectML on Windows when available.

```powershell
git clone git@github.com:enrique-orellana/WatermarkRemover-AI.git
cd WatermarkRemover-AI
.\setup.ps1
```

After setup, double-click `run.bat` to launch the app.

### Linux / macOS

Requires Python 3.10+ installed on your system.

On Linux with an AMD GPU, the setup script installs the ROCm build of PyTorch for hardware acceleration. That is the recommended full-power path for an RX 9070 XT.

```bash
git clone git@github.com:enrique-orellana/WatermarkRemover-AI.git
cd WatermarkRemover-AI
chmod +x setup.sh
./setup.sh
```

After setup, run `./run.sh` to launch the app.

### Optional: FFmpeg

Install FFmpeg to preserve audio when processing videos:
- **Windows**: Download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH
- **Linux**: `sudo apt install ffmpeg`
- **macOS**: `brew install ffmpeg`

---

## Usage

### GUI Mode

1. Run the app (`run.bat` on Windows, `./run.sh` on macOS/Linux)
2. Select your preferred language and theme from the top-right corner
3. Select your mode (Single File or Batch)
4. Set input and output paths
5. Configure settings as needed
6. Hit **Start Processing**

Your settings are automatically saved and restored on next launch.

If auto-detection picks the wrong backend, set `WMR_DEVICE` to `auto`, `cpu`, `cuda`, `rocm`, or `directml` before launching.

### CLI Mode

```bash
# Basic usage
python remwm.py input.png output_folder/

# With options
python remwm.py ./images ./output --overwrite --max-bbox-percent=15 --force-format=PNG

# Process video with two-pass detection
python remwm.py video.mp4 ./output --detection-skip=3 --fade-in=0.5 --fade-out=0.5

# Preview mode (detect without processing)
python remwm.py input.png --preview
```

### CLI Options

| Option | Description |
|--------|-------------|
| `--overwrite` | Overwrite existing files |
| `--transparent` | Make watermark regions transparent (images only) |
| `--max-bbox-percent` | Max detection size as % of image (default: 10) |
| `--force-format` | Force output format (PNG, WEBP, JPG, MP4, AVI) |
| `--detection-prompt` | Custom detection prompt (default: "watermark") |
| `--detection-skip` | Detect every N frames for videos (1-10, default: 1) |
| `--fade-in` | Extend mask backwards by N seconds (for fade-in watermarks) |
| `--fade-out` | Extend mask forwards by N seconds (for fade-out watermarks) |
| `--preview` | Preview detected watermarks without processing |

---

## Video Processing

- **Supported formats:** MP4, AVI, MOV, MKV, FLV, WMV, WEBM
- **Audio preservation:** Requires FFmpeg installed
- **Two-pass mode:** Faster processing with `--detection-skip` > 1
- **Fade handling:** Use `--fade-in` / `--fade-out` for watermarks that appear/disappear gradually

---

## Tech Stack

- **Florence-2** - Microsoft's vision model for watermark detection
- **LaMA** - Large Mask Inpainting model
- **PyWebview** - Cross-platform webview wrapper
- **Alpine.js** - Lightweight JavaScript framework for UI
- **PyTorch** - Deep learning backend

---

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=D-Ogi/WatermarkRemover-AI&type=date&legend=top-left)](https://www.star-history.com/#D-Ogi/WatermarkRemover-AI&type=date&legend=top-left)


