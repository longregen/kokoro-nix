{
  description = "Audio service environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
              
              # espeakng-loader package
              espeakng-loader = prev.python312Packages.buildPythonPackage {
                pname = "espeakng-loader";
                version = "0.1.0";
                format = "pyproject";
                
                src = prev.fetchFromGitHub {
                  owner = "thewh1teagle";
                  repo = "espeakng-loader";
                  rev = "main";
                  hash = "sha256-YlqlC5/x54y2nz2o4InCXOy802VE2VEDl7SRr3sBcTk=";
                };
                
                nativeBuildInputs = with prev.python312Packages; [
                  setuptools
                  wheel
                  pip
                  hatchling
                ] ++ [ prev.tree ];
                
                propagatedBuildInputs = [  prev.espeak-ng ];
                
                # Debug the file structure and then patch the package
                postPatch = ''
                  substituteInPlace src/espeakng_loader/__init__.py \
                    --replace 'libespeak-ng.so' '${prev.espeak-ng}/lib/libespeak-ng.so' \
                    --replace 'libespeak-ng.so.1' '${prev.espeak-ng}/lib/libespeak-ng.so.1' \
                    --replace 'libespeak-ng' '${prev.espeak-ng}/lib/libespeak-ng'
                '';
                
                doCheck = false;
                
                meta = {
                  description = "Python loader for espeak-ng";
                  homepage = "https://github.com/thewh1teagle/espeakng-loader";
                };
              };
              
              # cn2an package
              cn2an = prev.python312Packages.buildPythonPackage {
                pname = "cn2an";
                version = "0.5.23";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/py3/c/cn2an/cn2an-0.5.23-py3-none-any.whl";
                  hash = "sha256:1gqw3wj6jmwki10c6fc1i05lzykykgv53aydih1mqxkn6v2v76mi";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Convert Chinese numerals and Arabic numerals";
                  homepage = "https://github.com/Ailln/cn2an";
                };
              };
              
              # mishkal-hebrew package
              mishkal-hebrew = prev.python312Packages.buildPythonPackage {
                pname = "mishkal-hebrew";
                version = "0.3.5";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/d6/b6/eaf92c7f1aa9b37aac4ace213aba289baeade73ab0bfafd052a2e84da7ce/mishkal_hebrew-0.3.5-py3-none-any.whl";
                  hash = "sha256:1jb573xqv38wdknv6ykmrhips1ahysflsbj258r87nknzkqrr4jq";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Hebrew diacritization library";
                  homepage = "https://github.com/NLPH/mishkal-hebrew";
                };
              };
              
              # mojimoji package
              mojimoji = prev.python312Packages.buildPythonPackage {
                pname = "mojimoji";
                version = "0.0.13";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/cd/4e/0d7f019386bc4feb8096b5e8150d2e2dadd377be178d950654830541b5a3/mojimoji-0.0.13-cp310-cp310-macosx_10_9_x86_64.whl";
                  hash = "sha256:132vjixcbri25pish9qf9snpj8cm9ihllp9nxwz5gb5qgvnmzqyl";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Fast converter between Japanese hankaku and zenkaku characters";
                  homepage = "https://github.com/studio-ousia/mojimoji";
                };
              };
              
              # phonemizer-fork package
              phonemizer-fork = prev.python312Packages.buildPythonPackage {
                pname = "phonemizer-fork";
                version = "3.3.2";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/64/f1/0dcce21b0ae16a82df4b6583f8f3ad8e55b35f7e98b6bf536a4dd225fa08/phonemizer_fork-3.3.2-py3-none-any.whl";
                  hash = "sha256:0x2b4r4i65k29dyw8n6f8scqrrsz4qrc1x78v8jkhfqqyiv5qc4p";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Simple text to phonemes converter for multiple languages";
                  homepage = "https://github.com/bootphon/phonemizer";
                };
              };
              
              # pyopenjtalk package
              # pyopenjtalk = let
              #   dic-dirname = "open_jtalk_dic_utf_8-1.11";
              #   dic-src = prev.fetchzip {
              #     url = "https://github.com/r9y9/open_jtalk/releases/download/v1.11.1/${dic-dirname}.tar.gz";
              #     hash = "sha256-+6cHKujNEzmJbpN9Uan6kZKsPdwxRRzT3ZazDnCNi3s=";
              #   };
              # in prev.python312Packages.buildPythonPackage {
              #   pname = "pyopenjtalk";
              #   version = "0-unstable-2023-09-08";
              #   format = "pyproject";
              #   
              #   src = prev.fetchFromGitHub {
              #     owner = "r9y9";
              #     repo = "pyopenjtalk";
              #     rev = "v0.3.0";
              #     hash = "sha256-Yd+Uc9/Ixq8/Hs9/uxLWyFfPnHH/QgRPxUB+Hl+Wd+Y=";
              #     fetchSubmodules = true;
              #   };
              #   
              #   postPatch = ''
              #     substituteInPlace pyproject.toml \
              #         --replace-fail 'setuptools<v60.0' 'setuptools'
              #   '';
              #   
              #   nativeBuildInputs = with prev.python312Packages; [
              #     setuptools
              #     wheel
              #     cython
              #     numpy
              #   ] ++ [ 
              #     prev.cmake 
              #     prev.pkg-config
              #   ];
              #   
              #   propagatedBuildInputs = with prev.python312Packages; [
              #     numpy
              #     six
              #     tqdm
              #   ];
              #   
              #   dontUseCmakeConfigure = true;
              #   
              #   # Skip tests
              #   doCheck = false;
              #   
              #   postInstall = ''
              #     ln -s ${dic-src} $out/${prev.python312Packages.python.sitePackages}/pyopenjtalk/${dic-dirname}
              #   '';
              #   
              #   meta = {
              #     description = "Python wrapper for OpenJTalk";
              #     homepage = "https://github.com/r9y9/pyopenjtalk";
              #     license = prev.lib.licenses.mit;
              #   };
              # };
              
              # pypinyin-dict package
              pypinyin-dict = prev.python312Packages.buildPythonPackage {
                pname = "pypinyin-dict";
                version = "0.9.0";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/41/8f/add772a61256a9ac91d95bf5ec3dffc1de97c8e5da53d40655044b2e1509/pypinyin_dict-0.9.0-py2.py3-none-any.whl";
                  hash = "sha256:0yh6jy0fi62p4zfmair2kvd3fa6pijz7fcakcyw09mw7mx0bxkqh";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Pinyin dictionaries for pypinyin";
                  homepage = "https://github.com/mozillazg/pypinyin-dict";
                };
              };
              
              # spacy-curated-transformers package
              spacy-curated-transformers = prev.python312Packages.buildPythonPackage {
                pname = "spacy-curated-transformers";
                version = "2.1.2";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/65/4a/9c2b5d676f820e2d3672d8532def8a193e8cb9530824ce16b232b707c1a0/spacy_curated_transformers-2.1.2-py2.py3-none-any.whl";
                  hash = "sha256:069my5q5nlw6hlrk5agqirxki6272mgjj4c9242a8ajdapb2dmfl";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Curated transformer models for spaCy";
                  homepage = "https://github.com/explosion/spacy-curated-transformers";
                };
              };
              
              # underthesea package
              underthesea = prev.python312Packages.buildPythonPackage {
                pname = "underthesea";
                version = "6.8.4";
                format = "wheel";
                src = prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/23/17/8c9b8faa546fc0b1d2c2d95bc3539422946c3614f14db91272b219307c9f/underthesea-6.8.4-py3-none-any.whl";
                  hash = "sha256:1iz9kvkxhixw3ja54rrbh1aav7ykgi6x7gz2pqmll3ijk5zkihfx";
                };
                propagatedBuildInputs = [ ];
                doCheck = false;
                meta = {
                  description = "Vietnamese NLP Toolkit";
                  homepage = "https://github.com/undertheseanlp/underthesea";
                };
              };
              
              # Main misaki package
              misaki = prev.python312Packages.buildPythonPackage {
                pname = "misaki";
                version = "0.9.4";
                format = "pyproject";
                src = prev.python312Packages.fetchPypi {
                  pname = "misaki";
                  version = "0.9.4";
                  hash = "sha256-OWD6Pm3heakO6OYoRGpKT2uMcwtuNBCZnPOWGJ9NnEA=";
                };
                patches = [
                  ./misaki-espeak-fix.patch
                ];
                nativeBuildInputs = with prev.python312Packages; [
                  setuptools
                  wheel
                  hatchling
                ];
                propagatedBuildInputs = with prev.python312Packages; [
                  # Common dependencies
                  addict
                  regex
                  numpy
                  torch-bin
                  spacy
                  num2words
                  # English support
                  nltk
                  # Japanese support (optional)
                  fugashi
                  jaconv
                  # Chinese support (optional)
                  jieba
                  pypinyin
                  # Add espeakng-loader
                  espeakng-loader
                ];
                doCheck = false;
              };
              
              # Main kokoro package
              kokoro = prev.python312Packages.buildPythonPackage {
                pname = "kokoro";
                version = "0.9.4";
                format = "pyproject";
                src = prev.python312Packages.fetchPypi {
                  pname = "kokoro";
                  version = "0.9.4";
                  hash = "sha256-+/YzJieX+M9G/awzFc+creZ9yLdiwP7M8zSJJ3L7msQ=";
                };
                nativeBuildInputs = with prev.python312Packages; [
                  setuptools
                  wheel
                  hatchling
                ];
                propagatedBuildInputs = with prev.python312Packages; [
                  misaki
                  torch-bin
                  soundfile
                  phonemizer
                  phonemizer-fork
                  munch
                  numpy
                  transformers
                  huggingface-hub
                  loguru
                  # Additional dependencies
                  cn2an
                  mishkal-hebrew
                  mojimoji
                  # pyopenjtalk
                  pypinyin-dict
                  spacy-curated-transformers
                  underthesea
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
        depGenerator = ps: with ps; [
          aiohttp
          ctranslate2
          torch-bin
          torchvision-bin
          faster-whisper
          munch
          nltk
          numpy
          phonemizer
          requests
          scipy
          soundfile
          transformers
          websockets
          misaki
          kokoro
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
