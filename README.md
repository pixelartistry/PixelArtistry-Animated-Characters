# PixelArtistry Animated Characters – one image to a game-ready, animatable 3D character

Free & local ComfyUI workflows that turn **one image** into a **game-ready low-poly character with great textures**, ready to be rigged and animated (for example in [ActionForge](https://actionforge.app)) and played in your game engine. Includes a one-click installer for ComfyUI-Easy-Install and ComfyUI Portable.

```
Image ──► Pixal3D / TRELLIS.2 ──► WTiVo watertight ──► LODTailor 12k low-poly ──► Bake Forger normal map
                                                                                         │
                     final GLB ◄── Apply Materials ◄── UltraTex colour + metal/rough ◄──┘
```

## The workflows

| Workflow | For | Output |
|---|---|---|
| **PixelArtistry_05_Image_to_LowPoly_Character_UltraTex** | Characters: 12k triangles, 2K maps | `output/3d/PixelArtistry_char_final_*.glb` |
| **PixelArtistry_05p_Image_to_LowPoly_Prop_UltraTex** | Props and weapons: 2k triangles, hard-surface bake | `output/3d/PixelArtistry_sword_final_*.glb` |

Both run in one click: Pixal3D (or TRELLIS.2, one switch) builds the shape (their own texture stage is switched off, since UltraTex textures the mesh), MostAadTech's **WTiVo** makes it watertight, **LODTailor** rebuilds it as a low-poly game mesh, **Bake Forger** bakes the high-poly detail into a normal map, and **UltraTex** (MostAadTech's low-VRAM GGUF version) paints the colour and metal/roughness again straight from your image, on the same UVs. **Apply Materials** merges everything into one GLB.

## Requirements

- Windows, NVIDIA GPU (tested on an RTX 5080, 16 GB VRAM)
- [ComfyUI-Easy-Install](https://github.com/Tavris1/ComfyUI-Easy-Install) or ComfyUI Portable with **Python 3.12 + PyTorch 2.8 + CUDA 12** (tested: ComfyUI 0.39.2, torch 2.8.0+cu128)
- [Blender](https://www.blender.org) for LODTailor and Bake Forger – a clean portable install without add-ons works best (tested: 5.2.2)
- About 26 GB of disk for the models (Pixal3D and TRELLIS.2 both included), plus **a few GB free for UltraTex's scratch folder** (see Settings)

The watertight node (WTiVo) ships prebuilt for Python 3.12 + PyTorch 2.8 + CUDA 12, so other PyTorch versions will not run it. Details: [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Install

### a) Recommended: the installer

1. On this page: **Code → Download ZIP**.
2. Unzip it into `ComfyUI-Easy-Install\Add-Ons\` (or next to `python_embeded` in a portable install).
3. Close ComfyUI.
4. Double-click `Install-PixelArtistry-Animated-Characters.bat`.

What it does:

| Step | |
|---|---|
| 1 | Finds your install, checks that ComfyUI is closed, its version, and Python / PyTorch / CUDA (asks before continuing if they're not 3.12 / 2.8 / 12.x) |
| 2 | Runs the [PixelArtistry Watertight-Meshes installer](https://github.com/pixelartistry/PixelArtistry-Watertight-Meshes): MostAadTech's 3D nodes and the Pixal3D / TRELLIS.2 models (asks before downloading) |
| 3 | Installs MostAadTech's **UltraTex low-VRAM nodes** and **ComfyUI-GGUF**, pinned to the tested versions |
| 4 | Installs the Python packages, then **loads every compiled part once** (WTiVo, CuMesh, Triton …) to prove it runs on your setup |
| 5 | Checks the UltraTex models the way ComfyUI does (linked folders and `extra_model_paths.yaml` count) and asks before downloading the missing ones – **no Hugging Face token needed** |
| 6 | Finds Blender (or asks for the path) |
| 7 | Puts both workflows into the **PixelArtistry** folder of the workflow sidebar, with your Blender path filled in |

Safe to run again: existing files are kept, downloads resume, and an existing workflow is backed up as `.bak` before it is replaced. To try the newest node versions instead of the tested ones: open `cmd`, run `set PA_LATEST=1`, and start the installer from that window.

### b) Manual install

**1. Nodes** – clone into `ComfyUI\custom_nodes` and check out the tested commit:

| Node pack | Commit |
|---|---|
| [Mstafa-awad/WTiVo-WatertightVoxel-ComfyuiNode](https://github.com/Mstafa-awad/WTiVo-WatertightVoxel-ComfyuiNode) | `fb9e9ea` |
| [Mstafa-awad/ComfyUI-Mesh-Quad-Reconstruct](https://github.com/Mstafa-awad/ComfyUI-Mesh-Quad-Reconstruct) | `74048b3` |
| [Mstafa-awad/ComfyUI-Memory-Cleaner](https://github.com/Mstafa-awad/ComfyUI-Memory-Cleaner) | `3357282` |
| [Mstafa-awad/LODTailor-The-Mesh-Trimmer-ComfyuiNode](https://github.com/Mstafa-awad/LODTailor-The-Mesh-Trimmer-ComfyuiNode) | `3d25b7d` |
| [Mstafa-awad/LODTailor-Bake-Forger](https://github.com/Mstafa-awad/LODTailor-Bake-Forger) | `f13589c` |
| [Mstafa-awad/WTiVo-FastMergeByDistance](https://github.com/Mstafa-awad/WTiVo-FastMergeByDistance) | `5392949` |
| [Mstafa-awad/UltraTex-ComfyUI-nodes](https://github.com/Mstafa-awad/UltraTex-ComfyUI-nodes) → folder `comfyui_ultratex_modular` | `8d434a2` (v2.0.0) |
| [city96/ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) | `4dfc025` |
| [visualbruno/ComfyUI-Trellis2](https://github.com/visualbruno/ComfyUI-Trellis2) – provides the CuMesh wheels for Quad Reconstruct | `1459741` |

Then install each pack's `requirements.txt` with `python_embeded\python.exe -m pip install -r …`, plus `gguf>=0.13` for the UltraTex nodes. WTiVo on an RTX 20/30/40 card needs its multi-GPU build: unpack `build\ForNonBlackwellgpu(rtx50 and below).rar` into the node folder (the Watertight-Meshes installer does this for you).

**2. Models**

| File | Folder | Source |
|---|---|---|
| `pixal3d_int8_convrot.safetensors` | `diffusion_models` | [Comfy-Org/Pixal3D](https://huggingface.co/Comfy-Org/Pixal3D/resolve/main/diffusion_models/pixal3d_int8_convrot.safetensors) |
| `trellis_2_int8_convrot.safetensors` | `diffusion_models` | [Comfy-Org/TRELLIS.2](https://huggingface.co/Comfy-Org/TRELLIS.2/resolve/main/diffusion_models/trellis_2_int8_convrot.safetensors) |
| `trellis_2_shape_vae_bf16.safetensors` | `vae` | [Comfy-Org/Pixal3D](https://huggingface.co/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_shape_vae_bf16.safetensors) |
| `trellis_2_texture_vae_bf16.safetensors` | `vae` | [Comfy-Org/Pixal3D](https://huggingface.co/Comfy-Org/Pixal3D/resolve/main/vae/trellis_2_texture_vae_bf16.safetensors) |
| `dino_v3_L_naf_fp32.safetensors` | `clip_vision` | [Comfy-Org/Pixal3D](https://huggingface.co/Comfy-Org/Pixal3D/resolve/main/clip_vision/dino_v3_L_naf_fp32.safetensors) |
| `moge_2_vitl_normal_fp16.safetensors` | `geometry_estimation` | [Comfy-Org/MoGe](https://huggingface.co/Comfy-Org/MoGe/resolve/main/geometry_estimation/moge_2_vitl_normal_fp16.safetensors) |
| `birefnet.safetensors` | `background_removal` | [Comfy-Org/BiRefNet](https://huggingface.co/Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors) |
| `flux-2-klein-base-9b-Q4_0.gguf` | `diffusion_models` (or `unet`) | [unsloth/FLUX.2-klein-base-9B-GGUF](https://huggingface.co/unsloth/FLUX.2-klein-base-9B-GGUF/resolve/main/flux-2-klein-base-9b-Q4_0.gguf) |
| `Qwen3-8B-Q4_K_M.gguf` | `text_encoders` | [unsloth/Qwen3-8B-GGUF](https://huggingface.co/unsloth/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf) |
| `flux2-vae.safetensors` | `vae` | [Comfy-Org/flux2-dev](https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors) |
| `ultratex_flux2.safetensors` | `loras` | [ModelScope Yibo-Zhang/UltraTex](https://www.modelscope.ai/models/Yibo-Zhang/UltraTex): `flux2/lora/dit_lora.safetensors` → **rename** |
| `ultratex_flux2_mr.safetensors` | `loras` | ModelScope Yibo-Zhang/UltraTex: `flux2_mr/lora/dit_lora.safetensors` → **rename** |
| `ultratex_flux2_decoder.pt` | `ultratex` (create it) | ModelScope Yibo-Zhang/UltraTex: `flux2/decoder.pt` → **rename** |

Both LoRAs are called `dit_lora.safetensors` on ModelScope – rename each one right after downloading, or the second overwrites the first.

**3. Workflows** – copy the two JSONs from `workflows` into `ComfyUI\user\default\workflows\PixelArtistry`, and set the **Blender path** node once (use forward slashes, e.g. `D:/Blender/blender.exe`).

## How to use

1. Open **Workflows → PixelArtistry → PixelArtistry_05_Image_to_LowPoly_Character_UltraTex**.
2. Set the **UltraTex scratch folder** node (`spill_directory`) to a drive with free space.
3. Load your image in **Load Image**: the full character, straight front view, **T-pose**, **empty hands**, plain background. Fitted clothing animates best – big shoulder armour stretches when the arms move.
4. Choose Pixal3D (`false`, default) or TRELLIS.2 (`true`) with **Boolean (Switch to Trellis2)**.
5. Press **Run**. The final GLB lands in `ComfyUI/output/3d/`.

**Next steps used in the video:** load the GLB into ActionForge as **+ Unrigged model**, place the joint dots, play the free CC0 animations by Quaternius and export them with the character. A weapon from workflow 05p goes into the character's hand in Blender as a **separate object** and is tagged as **prop** in ActionForge, so it stays rigid in the hand.

## Settings

| Setting | Character (05) | Prop (05p) | Notes |
|---|---|---|---|
| LODTailor A `target_tris` | **12,000** | **2,000** | 8–15k for rigged characters, 500–2,000 for props |
| LODTailor `relative_voxel_size` | 0.0015 | 0.0015 | keeps thin parts such as blades |
| Bake Forger maps | 2048 | 2048 | |
| Bake Forger `tight_cage_extrusion_factor` | 0.0019 | 0.019 | characters vs hard-surface; raise it if white patches appear |
| UltraTex steps | 4 | 4 | fast; 25 for final quality – mostly worth it on the metal/rough pass |
| UltraTex views | 12 colour (guided extra angles), 6 metal/rough | same | 1024 view resolution. UltraTex v2 also offers **10** (6 canonical + 4 guided diagonals, all real views) |
| UltraTex UVs | `keep_existing` | same | keeps the UltraTex maps aligned with the baked normal map |
| UltraTex bake (v2) | Fast Surface Texture Baker, 2048, `surface_fill`, `fast_detail` | same | replaces the v0.2 bake node |
| UltraTex camera (v2) | `native_mesh_fit`, 0 % margin, 0 px padding | same | 0/0 gave better results than the v2 defaults (2 % / 8 px) |
| TRELLIS / Pixal3D texture stage | off (muted) | off (muted) | UltraTex paints colour and metal/rough anyway; Bake Forger bakes the normal map only. Saves ~2 min and ~100 MB per run |
| Structure seed | 56, fixed | 56, fixed | change it for a different generation |
| UltraTex scratch folder | blank → `output/.ultratex_cache` | same | **point it to a drive with space** |

## My measured results

RTX 5080 16 GB, ComfyUI 0.39.2, Pixal3D, UltraTex 4 steps:

- **Character (05):** 572 s for the full run (UltraTex v2, texture stage off) → 11,976 triangles, colour + metal/rough from UltraTex, normal map from Bake Forger. The earlier version with the texture stage on took 705 s.
- **Prop (05p), a sword:** 463 s → 2,000 triangles.

## Troubleshooting

| You see | Fix |
|---|---|
| `OSError: [Errno 28] No space left on device` in an UltraTex node | UltraTex writes several GB of scratch files per run and never deletes them. Point the **UltraTex scratch folder** node to a drive with space, and empty that folder now and then. |
| `UltraTex spill budget reached` | Raise `disk_budget_gb` in the UltraTex scratch folder node (default 16) or free that drive. |
| The installer says WTiVo will not load | WTiVo needs Python 3.12 + PyTorch 2.8 + CUDA 12 – see [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md). |
| LODTailor / Bake Forger: `WinError 2` | The Blender path is wrong or uses single backslashes – use forward slashes. |
| Holes or floating bits in the result | Run again with another structure seed, or switch between Pixal3D and TRELLIS.2. |
| The weapon bends with the wrist in ActionForge | Keep it a separate object in Blender and tag that piece as **prop** in ActionForge. |

## Credits

- **MostAadTech** – WTiVo, Quad Reconstruct, Memory Cleaner, LODTailor, Bake Forger, Fast Merge and the low-VRAM UltraTex nodes. He built the heavy lifting of this pipeline – please support him: [YouTube](https://www.youtube.com/@MostAadTech) · [Patreon](https://www.patreon.com/cw/MostafaAwad/membership) · [GitHub](https://github.com/Mstafa-awad)
- [visualbruno](https://github.com/visualbruno) – ComfyUI-Trellis2 (CuMesh) and ComfyUI-UltraTex
- [city96](https://github.com/city96/ComfyUI-GGUF) – ComfyUI-GGUF
- Comfy-Org – native Pixal3D / TRELLIS.2 nodes and the official template this builds on (MIT)
- TRELLIS.2 (Microsoft Research, MIT) · Pixal3D (Tencent ARC, MIT)
- UltraTex (SIGGRAPH Asia 2026): [yiboz2001.github.io/UltraTex](https://yiboz2001.github.io/UltraTex/) · weights on [ModelScope](https://www.modelscope.ai/models/Yibo-Zhang/UltraTex)
- FLUX.2 Klein base 9B by Black Forest Labs · GGUFs by [unsloth](https://huggingface.co/unsloth)
- Animation step: [ActionForge](https://actionforge.app) by CGstuff, CC0 animations by [Quaternius](https://quaternius.com)

**PixelArtistry**

- YouTube: [youtube.com/@PixelArtistry_](https://www.youtube.com/@PixelArtistry_)
- FutureFrames newsletter: [go.pixel-artistry.com/newsletter](https://go.pixel-artistry.com/newsletter)
- X: [x.com/philippsieben](https://x.com/philippsieben)

## License

> [!IMPORTANT]
> - **My files in this repo** (installer, helper script, workflow layouts and notes): [MIT](LICENSE).
> - **Node packs** keep their own licenses (see each repository).
> - **FLUX.2 Klein base 9B** (and its GGUF versions), used by UltraTex, is under the **FLUX Non-Commercial License v2.1** by Black Forest Labs. Your textures are yours – BFL claims no ownership of outputs – but **running the model** is licensed for non-commercial use. For client or production work, check [bfl.ai/licensing](https://bfl.ai/licensing) first. This is not legal advice.
