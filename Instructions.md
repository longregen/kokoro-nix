Please fix this repository's flake.nix file. I want to be able to run the "kokoro" package, but many of the things it depends on are not bundled by nixpkgs. Please run `nix develop`, check the errors, fix the flake file, and try again.

Most of the complications to run "kokoro" was that these packages are not in nixpkgs:
- cn2an
- espeakng-loader
- mishkal-hebrew
- mojimoji
- phonemizer-fork
- pyopenjtalk
- pypinyin-dict
- spacy-curated-transformers
- underthesea

Please run `nix develop` and check the error, fix the flake, and try to see if it works. Since the shell script runs python with an import of kokoro, successful run of the command should indicate it works.