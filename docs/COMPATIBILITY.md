# Node compatibility: Python, PyTorch, CUDA, GPU

**Status:** Checked on 15 October 2026 by reading what each node pack's binaries link against, and by loading them on Python 3.12.10 + torch 2.8.0+cu128 with an RTX 5080, where every part loads. Other combinations below are derived from the binaries, not from test runs.

The installer runs this check itself (`pa_helper.py compat`): it **loads** each
compiled part in the target Python instead of only comparing version numbers.

## Which parts are tied to which versions

| Part (used by workflow 05/05p) | Compiled? | Tied to | Evidence |
| --- | --- | --- | --- |
| **WTiVo watertight** (MostAadTech) | Yes, prebuilt `.pyd` | **Python 3.12 + torch 2.8 (C++ ABI) + CUDA 12.x** | Links `python312.dll`, `c10.dll`, `torch_cpu/cuda/python.dll`, `cudart64_12.dll`; README: "PyTorch 2.8.0 with CUDA 12.8" |
| · default build | | **RTX 50 only** (`sm_120`) | `cellocut_gpupr_fast.pyd` contains `sm_120` code only |
| · multi-GPU build (`.rar`) | | GTX 10 → RTX 50 (`sm_61` … `sm_120`) in `cppmodules`; `cellocut_gpupr_fast` lists only `sm_100/sm_120` | The Watertight installer unpacks it automatically on RTX 20/30/40. **Not tested on an older GPU here.** |
| **CuMesh** (Quad Reconstruct, CuMesh Decimate) | Yes, wheels from VisualBruno ComfyUI-Trellis2 | torch **2.7, 2.8 or 2.10** × Python **3.11 / 3.12** (Windows wheels shipped) | `wheels/Windows/Torch270, Torch280, Torch2100` |
| o_voxel (Mesh Encoder, workflow 03 only) | Yes, same wheels | same as CuMesh | same |
| **Triton** (UltraTex low-VRAM sparse attention) | Yes | must match torch: 2.7→3.3, **2.8→3.4**, 2.9→3.5, 2.10→3.6 (triton-windows) | Installed here: 3.4.0 with torch 2.8 |
| FastMerge native weld | Plain C++ DLL | **None** (only the VC++ runtime) | Links `VCRUNTIME140_1.dll` only, loaded via ctypes |
| LODTailor, Bake Forger, LODsmith | No (Python) | **None**: the heavy work runs in Blender (tested 5.2.2) | `bpy` is imported inside Blender's own Python |
| Quad Reconstruct, Memory Cleaner, Mesh Encoder | No (Python) | Only through CuMesh / o_voxel / pymeshlab | |
| UltraTex modular (MostAadTech), ComfyUI-GGUF | No (Python) | Only through Triton; `gguf`, `moderngl`, `xatlas` are ordinary wheels | |
| ComfyUI core Pixal3D / TRELLIS.2 nodes | Core | ComfyUI ≥ 0.34 (tested 0.39.2) | Native since Aug 2026 |

## What that means per install type

| Install | Python / torch / CUDA | Works? |
| --- | --- | --- |
| **ComfyUI-Easy-Install** (current) | 3.12 / 2.8.0 / cu128 | **Yes**: the tested setup |
| **ComfyUI Portable** with torch 2.8.0+cu128 | 3.12 / 2.8 / 12.8 | **Expected yes** (same layout and versions); needs Triton added, which the installer checks. Not tested on a fresh copy. |
| Portable / Easy-Install with **newer torch** (2.9, 2.10, cu129/cu130) | | **No for WTiVo** (C++ ABI); CuMesh only on 2.10; Triton must be swapped. Everything else is fine. |
| **ComfyUI Desktop** | its own `.venv`, torch managed by the app | **WTiVo only if its torch is exactly 2.8 + CUDA 12**; app updates can change torch and break it. The installer does not support the Desktop folder layout yet. Not tested. |

## The single bottleneck

Everything except **WTiVo** can be satisfied on several torch versions. WTiVo's
backend is compiled against the torch 2.8 C++ ABI and Python 3.12, so a
different torch minor version or Python means a different build from
MostAadTech. Options:

1. Keep **Python 3.12 + torch 2.8.0+cu128** (Easy-Install / Portable). This is the recommendation.
2. Ask MostAadTech for builds against newer torch, then add them to this table.
3. For a no-WTiVo fallback, bypass WTiVo (and its LODTailor trim) in workflow 05 or 05p.
   Pixal3D's raw mesh then goes straight to LODTailor A. It's untested and may
   leave holes, which matter less for a game character than for a print.
