from dataclasses import dataclass
import os
import subprocess
import sys

import torch

try:
    import torch_directml
except ImportError:
    torch_directml = None


@dataclass(frozen=True)
class RuntimeDevice:
    backend: str
    device: object
    label: str
    model_dtype: torch.dtype


def _get_windows_gpu_name():
    if sys.platform != "win32":
        return None

    try:
        query = (
            "Get-CimInstance Win32_VideoController | "
            "Where-Object { $_.Name -notmatch 'Microsoft Basic Display Adapter' } | "
            "Select-Object -First 1 -ExpandProperty Name"
        )
        result = subprocess.run(
            [
                "powershell",
                "-NoProfile",
                "-Command",
                query,
            ],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            gpu_name = result.stdout.strip()
            return gpu_name or None
    except Exception:
        pass

    return None


def _has_rocm():
    return torch.cuda.is_available() and getattr(torch.version, "hip", None) is not None


def _cuda_label():
    try:
        return torch.cuda.get_device_name(0)
    except Exception:
        return "GPU"


def _directml_device():
    if torch_directml is None:
        return None

    try:
        return torch_directml.device()
    except Exception:
        return None


def _device_from_backend(backend: str) -> RuntimeDevice:
    backend = backend.lower()

    if backend == "cpu":
        return RuntimeDevice("cpu", torch.device("cpu"), "CPU", torch.float32)

    if backend in {"cuda", "rocm"}:
        if not torch.cuda.is_available():
            raise RuntimeError("CUDA/ROCm backend requested, but no GPU backend is available.")
        resolved_backend = "rocm" if _has_rocm() else "cuda"
        return RuntimeDevice(
            resolved_backend,
            torch.device("cuda"),
            f"{resolved_backend.upper()} ({_cuda_label()})",
            torch.float16,
        )

    if backend == "directml":
        dml_device = _directml_device()
        if dml_device is None:
            raise RuntimeError("DirectML backend requested, but torch-directml is not available.")
        gpu_name = _get_windows_gpu_name() or "AMD GPU"
        return RuntimeDevice("directml", dml_device, f"DirectML ({gpu_name})", torch.float32)

    raise ValueError(f"Unknown backend: {backend}")


def select_runtime_device():
    """
    Pick the best backend available for the current platform.

    WMR_DEVICE can force one of: auto, cpu, cuda, rocm, directml.
    """
    requested = os.getenv("WMR_DEVICE", "auto").strip().lower()

    if requested != "auto":
        return _device_from_backend(requested)

    if torch.cuda.is_available():
        backend = "rocm" if _has_rocm() else "cuda"
        return _device_from_backend(backend)

    if sys.platform == "win32":
        dml_device = _directml_device()
        if dml_device is not None:
            gpu_name = _get_windows_gpu_name() or "AMD GPU"
            return RuntimeDevice("directml", dml_device, f"DirectML ({gpu_name})", torch.float32)

    return _device_from_backend("cpu")
