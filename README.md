# FFmpeg UHD 60 FPS Batch Converter (Windows, GPU NVENC)

This repository contains a Windows batch script that:

- Converts all videos in a folder to **4K UHD (3840×2160)**
- Converts frame rate to **60 FPS**
- Uses **FFmpeg** with **NVIDIA NVENC (GPU)** for fast, hardware-accelerated encoding
- Prompts for **input** and **output** folders
- Handles paths **with or without quotes**  
- Supports: `mp4`, `mkv`, `avi`, `mov`

---

## Features

- 🔹 Batch processing (all videos in a folder)
- 🔹 Upscaling to **4K UHD**
- 🔹 Motion interpolation to **60 FPS** using `minterpolate`
- 🔹 GPU-accelerated HEVC (`hevc_nvenc`)
- 🔹 High quality settings (higher bitrate, HQ tuning)
- 🔹 Simple interactive prompts for folders

---

## Requirements

- **Windows**
- **FFmpeg** with:
  - `hevc_nvenc` support (NVIDIA GPU with NVENC)
  - `minterpolate` filter (for motion interpolation)
- NVIDIA GPU with NVENC support

You can check if your FFmpeg has NVENC support by running:

```bash
ffmpeg -encoders | findstr nvenc
