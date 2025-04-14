{
  description = "Audio service environment";

  # Add NVIDIA cache configuration
  nixConfig = {
    extra-substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlay = final: prev: {
          ctranslate2 = prev.ctranslate2.override {
            stdenv = prev.gcc11Stdenv;
            withCUDA = true;
            withCuDNN = true;
            cudaPackages = prev.cudaPackages;
          };
          python312Packages =
            prev.python312Packages
            // rec {
              faster-whisper = prev.python312Packages.faster-whisper.overrideAttrs {
                ctranslate2-cpp = final.ctranslate2;
              };
              clldutils = prev.python312Packages.clldutils.overrideAttrs (oldAttrs: {
                meta = oldAttrs.meta // {broken = false;};
              });
              
              # Main misaki package
              misaki = prev.python312Packages.buildPythonPackage {
                pname = "misaki";
                version = "0.9.4";
                format = "setuptools";
                src = prev.python312Packages.fetchPypi {
                  pname = "misaki";
                  version = "0.9.4";
                  sha256 = "90e2eeb169786c014c429e5058d2ea6bcd02d651f2a24450ba6c9ffc0f8da15a";
                };
                propagatedBuildInputs = with prev.python312Packages; [
                  # Common dependencies
                  numpy
                  torch
                  spacy
                  num2words
                  regex
                  # English support
                  nltk
                  # Japanese support (optional)
                  fugashi
                  jaconv
                  # Chinese support (optional)
                  jieba
                  pypinyin
                ];
                doCheck = false;
              };
              
              # Main kokoro package
              kokoro = prev.python312Packages.buildPythonPackage {
                pname = "kokoro";
                version = "0.9.4";
                format = "setuptools";
                src = prev.python312Packages.fetchPypi {
                  pname = "kokoro";
                  version = "0.9.4";
                  sha256 = "sha256-+/YzJieX+M9G/awzFc+creZ9yLdiwP7M8zSJJ3L7msQ=";
                };
                propagatedBuildInputs = with prev.python312Packages; [
                  misaki
                  torch
                  soundfile
                  phonemizer
                  munch
                  numpy
                  transformers
                ];
                doCheck = false;
              };
            };
        };
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
          overlays = [overlay];
        };
        depGenerator = ps: let
          torch = ps.torch-bin;
          torchvision = ps.torchvision-bin;
        in [
          ps.aiohttp
          ps.ctranslate2
          torch
          torchvision
          ps.faster-whisper
          ps.munch
          ps.nltk
          ps.numpy
          ps.phonemizer
          ps.requests
          ps.scipy
          ps.soundfile
          ps.transformers
          ps.websockets
          ps.misaki # Add misaki as a dependency
          ps.kokoro # Keep kokoro as a dependency
        ];
        deps = with pkgs;
          [
            stdenv.cc.cc.lib
            cudatoolkit
            linuxPackages.nvidia_x11
            gcc11
            ctranslate2
            espeak-ng # Add espeak-ng for fallback in misaki
          ]
          ++ (depGenerator pkgs.python312Packages);
      in {
        devShells.default = pkgs.mkShell {
          name = "cuda-env-shell";
          packages = deps;
          buildInputs = with pkgs; [
            ctranslate2
            libsndfile
            ffmpeg
          ];
          shellHook = with pkgs; ''
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${stdenv.cc.cc.lib}/lib"
            export NIX_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
            export CUDA_PATH=${cudatoolkit}
            export EXTRA_LDFLAGS="-L/lib -L${linuxPackages.nvidia_x11}/lib"
            export EXTRA_CCFLAGS="-I/usr/include"
            export CC="${gcc11}/bin/gcc"

            # This is the key that shows everything works
            python -c "from misaki import en; from kokoro import KModel, KPipeline"
          '';
        };
      }
    );
}
