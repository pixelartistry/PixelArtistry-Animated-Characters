"""Helper for Install-PixelArtistry-AI-Character.bat (runs in ComfyUI's python_embeded).

Commands:
  version   <ComfyUI dir>                       exit 0 if ComfyUI >= MIN_COMFY
  models    <ComfyUI dir> [--download]          list UltraTex GGUF models, exit code = missing count
  workflows <src dir> <dst dir> <blender.exe>   copy workflows, write the Blender path into them

Models are looked up the way ComfyUI does it (folder_paths + extra_model_paths.yaml),
so linked model folders count. Downloads resume from *.part files.
"""
import json, os, shutil, sys, urllib.request

MIN_COMFY = (0, 39, 2)  # version the workflows were tested on

# (category, file name, source, description)
HF = "https://huggingface.co/"
MODELS = [
    ("diffusion_models", "flux-2-klein-base-9b-Q4_0.gguf",
     HF + "unsloth/FLUX.2-klein-base-9B-GGUF/resolve/main/flux-2-klein-base-9b-Q4_0.gguf", "FLUX.2 Klein base 9B Q4_0 (5.3 GB)"),
    ("text_encoders", "Qwen3-8B-Q4_K_M.gguf",
     HF + "unsloth/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf", "Qwen3 8B Q4_K_M (5.0 GB)"),
    ("vae", "flux2-vae.safetensors",
     HF + "Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors", "FLUX.2 VAE"),
    ("background_removal", "birefnet.safetensors",
     HF + "Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors", "BiRefNet"),
    ("loras", "ultratex_flux2.safetensors", "modelscope:flux2/lora/dit_lora.safetensors", "UltraTex albedo LoRA"),
    ("loras", "ultratex_flux2_mr.safetensors", "modelscope:flux2_mr/lora/dit_lora.safetensors", "UltraTex metal-roughness LoRA"),
    ("ultratex", "ultratex_flux2_decoder.pt", "modelscope:flux2/decoder.pt", "UltraTex foreground decoder"),
]
MODELSCOPE_ID = "Yibo-Zhang/UltraTex"


def load_folder_paths(comfy):
    sys.path.insert(0, comfy)
    os.chdir(comfy)
    import folder_paths
    try:
        from utils.extra_config import load_extra_path_config
        for name in ("extra_model_paths.yaml",):
            p = os.path.join(comfy, name)
            if os.path.isfile(p):
                load_extra_path_config(p)
    except Exception as e:  # older layouts: default folders still work
        print(f"    [WARN] extra_model_paths.yaml not read: {e}")
    folder_paths.add_model_folder_path("ultratex", os.path.join(folder_paths.models_dir, "ultratex"))
    return folder_paths


def find(fp, category, name):
    try:
        if category == "ultratex":
            roots = fp.folder_names_and_paths["ultratex"][0]
            return next((os.path.join(r, name) for r in roots if os.path.isfile(os.path.join(r, name))), None)
        return fp.get_full_path(category, name)
    except Exception:
        return None


def http_download(url, target):
    part = target + ".part"
    have = os.path.getsize(part) if os.path.exists(part) else 0
    req = urllib.request.Request(url, headers={"Range": f"bytes={have}-"} if have else {})
    with urllib.request.urlopen(req) as r:
        total = int(r.headers.get("Content-Length", 0)) + have
        mode = "ab" if have and r.status == 206 else "wb"
        done = have if mode == "ab" else 0
        with open(part, mode) as f:
            while True:
                chunk = r.read(8 << 20)
                if not chunk:
                    break
                f.write(chunk)
                done += len(chunk)
                if total:
                    print(f"\r      {done / 1e9:5.2f} / {total / 1e9:5.2f} GB", end="", flush=True)
    print()
    os.replace(part, target)


def modelscope_download(file_path, target, cache):
    try:
        from modelscope.hub.file_download import model_file_download
    except ImportError:
        import subprocess
        subprocess.check_call([sys.executable, "-I", "-m", "pip", "install", "--quiet",
                               "--disable-pip-version-check", "--no-warn-script-location", "modelscope"])
        from modelscope.hub.file_download import model_file_download
    last = None
    for endpoint in (None, "https://www.modelscope.ai"):
        try:
            if endpoint:
                os.environ["MODELSCOPE_DOMAIN"] = endpoint
            p = model_file_download(model_id=MODELSCOPE_ID, file_path=file_path, cache_dir=cache)
            shutil.copyfile(p, target)  # rename: both LoRAs are called dit_lora.safetensors upstream
            return
        except Exception as e:
            last = e
    raise RuntimeError(last)


def cmd_version(comfy):
    ns = {}
    exec(open(os.path.join(comfy, "comfyui_version.py"), encoding="utf-8").read(), ns)
    v = tuple(int(x) for x in ns["__version__"].split(".")[:3])
    print(f"    ComfyUI {ns['__version__']} (tested: {'.'.join(map(str, MIN_COMFY))})")
    return 0 if v >= MIN_COMFY else 1


def cmd_models(comfy, download):
    fp = load_folder_paths(comfy)
    missing = 0
    for cat, name, src, desc in MODELS:
        path = find(fp, cat, name)
        if path:
            print(f"    [OK]      {name:34} {path}")
            continue
        if not download:
            print(f"    [MISSING] {name:34} {desc}")
            missing += 1
            continue
        folder = os.path.join(fp.models_dir, cat)
        os.makedirs(folder, exist_ok=True)
        target = os.path.join(folder, name)
        print(f"    [GET]     {name}  ({desc})")
        try:
            if src.startswith("modelscope:"):
                modelscope_download(src.split(":", 1)[1], target, os.path.join(fp.models_dir, ".modelscope_cache"))
            else:
                http_download(src, target)
            print(f"    [OK]      {target}")
        except Exception as e:
            print(f"    [FAIL]    {name}: {e}")
            missing += 1
    return missing


def cmd_workflows(src, dst, blender):
    os.makedirs(dst, exist_ok=True)
    blender = blender.replace("\\", "/")  # backslashes break the path inside JSON
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.endswith(".json"):
            continue
        g = json.load(open(os.path.join(src, f), encoding="utf-8"))
        for node in g.get("nodes", []):
            if node.get("type") == "PrimitiveString" and node.get("widgets_values") == ["blender"]:
                node["widgets_values"] = [blender]
        out = os.path.join(dst, f)
        if os.path.exists(out):
            shutil.copyfile(out, out + ".bak")
        json.dump(g, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"    [OK]      {f}")
        n += 1
    return 0 if n else 1


# triton-windows release line that matches each torch minor version (from triton-windows' README)
TRITON_FOR_TORCH = {(2, 7): "3.3", (2, 8): "3.4", (2, 9): "3.5", (2, 10): "3.6"}


def cmd_compat(comfy):
    """Check the compiled parts of the workflow against this Python / torch / CUDA / GPU.

    Exit code = number of blockers (components that cannot run here).
    """
    import importlib
    import platform
    blockers = 0
    py = sys.version_info[:2]
    print(f"    Python {platform.python_version()}")
    try:
        import torch
    except Exception as e:
        print(f"    [BLOCK] torch not importable: {e}")
        return 1
    tv = tuple(int(x) for x in torch.__version__.split("+")[0].split(".")[:2])
    cuda = torch.version.cuda or "none"
    cc = torch.cuda.get_device_capability() if torch.cuda.is_available() else None
    gpu = torch.cuda.get_device_name() if cc else "no CUDA GPU"
    print(f"    torch {torch.__version__} / CUDA {cuda} / {gpu}" + (f" (sm_{cc[0]}{cc[1]})" if cc else ""))
    print()

    def line(status, name, note):
        print(f"    [{status:5}] {name:30} {note}")

    # 1. WTiVo watertight backend: precompiled against CPython 3.12 + torch 2.8 C++ ABI + CUDA 12 runtime
    wt = os.path.join(comfy, "custom_nodes", "WTiVo-WatertightVoxel-ComfyuiNode", "build")
    if not os.path.isdir(wt):
        line("SKIP", "WTiVo watertight", "not installed yet (step 2 installs it)")
    elif py != (3, 12) or tv != (2, 8) or not cuda.startswith("12."):
        line("BLOCK", "WTiVo watertight", f"prebuilt for Python 3.12 + torch 2.8 + CUDA 12.x; this is Python {py[0]}.{py[1]} + torch {tv[0]}.{tv[1]} + CUDA {cuda}")
        blockers += 1
    else:
        sys.path.insert(0, wt)
        os.add_dll_directory(wt)
        try:
            for m in ("cellocut_vdb_watertight", "cppmodules", "cellocut_gpupr_fast"):
                importlib.import_module(m)
            build = "RTX 50 build" if cc and cc[0] >= 12 else "multi-GPU build (RTX 20/30/40)"
            line("OK", "WTiVo watertight", f"native modules load; GPU needs the {build}")
        except Exception as e:
            line("BLOCK", "WTiVo watertight", f"native modules do not load: {str(e)[:90]}")
            blockers += 1

    # 2. CuMesh / o_voxel (VisualBruno ComfyUI-Trellis2 wheels): Quad Reconstruct, CuMesh Decimate, Mesh Encoder
    for mod, users in (("cumesh", "Quad Reconstruct, CuMesh Decimate"), ("o_voxel", "Trellis2 Mesh Encoder (workflow 03 only)")):
        try:
            importlib.import_module(mod)
            line("OK", mod, users)
        except Exception as e:
            st = "WARN" if mod == "o_voxel" else "BLOCK"
            line(st, mod, f"not loadable ({str(e)[:60]}); wheels exist for torch 2.7/2.8/2.10 + Python 3.11/3.12 in VisualBruno ComfyUI-Trellis2")
            blockers += st == "BLOCK"

    # 3. Triton: UltraTex low-VRAM sparse attention, must match the torch version
    want = TRITON_FOR_TORCH.get(tv)
    try:
        import triton
        ok = want is None or triton.__version__.startswith(want)
        line("OK" if ok else "WARN", "triton", f"{triton.__version__}" + ("" if ok else f" - torch {tv[0]}.{tv[1]} expects triton-windows {want}.x"))
    except Exception:
        line("BLOCK", "triton", f"missing - UltraTex low-VRAM needs it" + (f" (pip install \"triton-windows<{want[0]}.{int(want[2:]) + 1}\")" if want else ""))
        blockers += 1

    # 4. Pure Python / version-independent parts
    for mod, users in (("gguf", "ComfyUI-GGUF loaders"), ("moderngl", "UltraTex rendering"), ("xatlas", "UltraTex UV fallback"), ("pymeshlab", "Quad Reconstruct")):
        try:
            importlib.import_module(mod)
            line("OK", mod, users)
        except Exception:
            line("WARN", mod, f"missing ({users}) - installed by the node requirements")
    line("OK", "FastMerge native DLL", "plain C++ DLL, independent of Python/torch/CUDA")
    line("OK", "LODTailor / Bake Forger", "run inside Blender, independent of torch (tested with Blender 5.2.2)")
    return blockers


if __name__ == "__main__":
    c = sys.argv[1]
    if c == "compat":
        sys.exit(min(cmd_compat(sys.argv[2]), 99))
    if c == "version":
        sys.exit(cmd_version(sys.argv[2]))
    if c == "models":
        sys.exit(min(cmd_models(sys.argv[2], "--download" in sys.argv), 99))
    if c == "workflows":
        sys.exit(cmd_workflows(sys.argv[2], sys.argv[3], sys.argv[4]))
    sys.exit(2)
