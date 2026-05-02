#!/usr/bin/env bash
set -e

echo ""
echo "  ============================================="
echo "     WatermarkRemover-AI Setup (Linux/macOS)"
echo "  ============================================="
echo ""

echo "  [OK] Using official package and model sources"
echo ""

# Detect OS
OS_TYPE="windows"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    echo "  [*] Detected Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    echo "  [*] Detected macOS"
else
    echo "  [*] Detected Windows/Other"
fi

GPU_BACKEND="cpu"
GPU_NAME="CPU"
if command -v nvidia-smi &> /dev/null; then
    GPU_BACKEND="cuda"
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1 2>/dev/null || echo "NVIDIA GPU")
elif [[ "$OS_TYPE" == "linux" ]] && command -v lspci &> /dev/null; then
    if lspci | grep -Eqi 'AMD|Advanced Micro Devices|Radeon'; then
        GPU_BACKEND="rocm"
        GPU_NAME="AMD Radeon GPU"
    fi
fi

echo "  [OK] Detected GPU backend: $GPU_BACKEND ($GPU_NAME)"
echo ""

# Check Python version
PYTHON_CMD=""
for cmd in python3.12 python3.11 python3.10 python3 python; do
    if command -v $cmd &> /dev/null; then
        version=$($cmd -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        major=$(echo $version | cut -d. -f1)
        minor=$(echo $version | cut -d. -f2)
        if [ "$major" -eq 3 ] && [ "$minor" -ge 10 ]; then
            PYTHON_CMD=$cmd
            echo "  [OK] Found $PYTHON_CMD (version $version)"
            break
        fi
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "  [X] Python 3.10+ is required but not found."
    echo "      Please install Python 3.10 or higher."
    exit 1
fi

# Create virtual environment
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "  [*] Creating virtual environment..."
    $PYTHON_CMD -m venv $VENV_DIR
    echo "  [OK] Virtual environment created"
else
    echo "  [OK] Virtual environment exists"
fi

# Activate venv
if [[ "$OS_TYPE" == "macos" || "$OS_TYPE" == "linux" ]]; then
    source $VENV_DIR/bin/activate
else
    source $VENV_DIR/Scripts/activate
fi

# Skip pip self-upgrade (can fail on some Windows Python installs)
echo "  [*] Skipping pip self-upgrade"

# Install PyTorch based on platform/backend
echo "  [*] Installing PyTorch..."
if [ "$OS_TYPE" == "macos" ]; then
    pip install "torch==2.9.0" "torchvision==0.24.0" --no-cache-dir -q
    echo "  [OK] PyTorch installed (macOS)"
elif [ "$GPU_BACKEND" == "cuda" ]; then
    pip install "torch==2.9.0" "torchvision==0.24.0" --index-url https://download.pytorch.org/whl/cu126 --no-cache-dir -q
    echo "  [OK] PyTorch installed (CUDA 12.6)"
elif [ "$GPU_BACKEND" == "rocm" ]; then
    pip install "torch==2.9.0" "torchvision==0.24.0" --index-url https://download.pytorch.org/whl/rocm6.4 --no-cache-dir -q
    echo "  [OK] PyTorch installed (ROCm 6.4)"
else
    pip install "torch==2.9.0" "torchvision==0.24.0" --index-url https://download.pytorch.org/whl/cpu --no-cache-dir -q
    echo "  [OK] PyTorch installed (CPU)"
fi

# Install other dependencies (without torch lines)
echo "  [*] Installing other dependencies..."
pip install "transformers>=4.50.0" "diffusers>=0.30.0" "numpy<2" --no-cache-dir -q
pip install "opencv-python-headless>=4.8.0,<4.12.0" "Pillow>=10.0.0" --no-cache-dir -q
pip install "pywebview>=4.0" --no-cache-dir -q
pip install loguru click tqdm psutil pyyaml --no-cache-dir -q

# Install iopaint separately (no deps to avoid conflicts)
echo "  [*] Installing iopaint..."
pip install iopaint --no-deps --no-cache-dir -q

# Install iopaint's required dependencies manually (subset needed for LaMA inpainting)
echo "  [*] Installing iopaint dependencies..."
pip install pydantic typer einops omegaconf easydict yacs --no-cache-dir -q
echo "  [OK] Dependencies installed"

# Download LaMA model directly from GitHub (avoids iopaint CLI dependency on fastapi)
echo "  [*] Downloading LaMA model (~196MB)..."
LAMA_DIR="$HOME/.cache/torch/hub/checkpoints"
LAMA_FILE="$LAMA_DIR/big-lama.pt"
if [ ! -f "$LAMA_FILE" ]; then
    mkdir -p "$LAMA_DIR"
    curl -L -o "$LAMA_FILE" "https://github.com/Sanster/models/releases/download/add_big_lama/big-lama.pt" || echo "  [!] LaMA download failed, will retry on first use"
    echo "  [OK] LaMA model downloaded"
else
    echo "  [OK] LaMA model already exists"
fi

# Download Florence-2 model
echo "  [*] Downloading Florence-2 model (~1.5GB)..."
python -c "from huggingface_hub import snapshot_download; snapshot_download('florence-community/Florence-2-large', local_dir_use_symlinks=False)" || echo "  [!] Florence-2 download failed, will retry on first use"

echo ""
echo "  ============================================="
echo "     Setup complete!"
echo "  ============================================="
echo ""
echo "  To run the app:"
echo "    source venv/bin/activate"
echo "    python remwmgui.py"
echo ""
echo "  Or for CLI:"
echo "    source venv/bin/activate"
echo "    python remwm.py input.png output/"
echo ""

# Ask to launch
read -p "  Launch now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  Starting WatermarkRemover-AI..."
    python remwmgui.py
fi
