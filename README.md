# Kokoro TTS Nix Flake

A Nix flake for setting up and testing the Kokoro text-to-speech system in a hermetic environment.

## Overview

This repository provides a Nix flake configuration for the Kokoro text-to-speech system, which is a neural text-to-speech engine. The flake sets up a complete development environment with all necessary dependencies and provides a test script to verify functionality.

## Features

- Complete Nix flake configuration for Kokoro TTS
- CUDA support for hardware acceleration
- Hermetic environment (no downloads required during runtime)
- Includes patches for compatibility with Nix
- Test script to verify functionality

## Requirements

- Nix package manager with flakes enabled
- CUDA-compatible GPU (optional, for hardware acceleration)

## Usage

### Development Shell

To enter a development shell with all dependencies:

```bash
nix develop
```

This will set up an environment with all required dependencies, including:
- Python 3.12 with necessary packages
- CUDA toolkit (if using GPU acceleration)
- Espeak-ng for text processing
- All required TTS models

### Running the Test

The flake includes a test to verify Kokoro functionality:

```bash
nix flake check
```

This will run the `kokoro-test.py` script, which generates a "hello world" audio file.

You can also run the test script directly from the development shell:

```bash
python kokoro-test.py
```

## Project Structure

- `flake.nix` - Main Nix flake configuration
- `flake.lock` - Lock file for Nix flake dependencies
- `kokoro-test.py` - Test script for Kokoro TTS
- `misaki-espeak-fix.patch` - Patch for Misaki library to fix eSpeak integration
- `mecab-remove-deprecated.patch` - Patch for MeCab to remove deprecated code

## Patches

### misaki-espeak-fix.patch

Fixes an issue with the Misaki library's eSpeak integration by changing how the data path is set.

### mecab-remove-deprecated.patch

Removes deprecated `register` keywords from MeCab source code to ensure compatibility with modern compilers.

## Models

The flake automatically downloads and sets up the required models:
- Kokoro TTS model from Hugging Face (hexgrad/Kokoro-82M)
- Voice model (af_heart.pt)

## License

This project is distributed under the terms of the Apache License 2.0.

## Acknowledgments

- [Kokoro TTS](https://github.com/hexgrad/kokoro) - Neural text-to-speech engine
- [Misaki](https://github.com/hexgrad/misaki) - Text processing for TTS
- [NixOS](https://nixos.org/) - The purely functional package manager
