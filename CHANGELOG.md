# Revision history for distribution-nixpkgs

## 1.6.2

* Expect `MonadFailDesugaring` (or equivalent behavior) to be the default,
  requiring GHC >= 8.6.1.

## 1.6.1

* `Distribution.Nixpkgs.Meta`: support `aarch64-darwin`
  * Render `Platform AArch64 OSX` to `"aarch64-darwin"`
  * Add `Platform AArch64 OSX` to `allKnownPlatforms`

## 1.6.0

* `Distribution.Nixpkgs.PackageMap`
  * `readNixpkgPackageMap`: instead of a list of arguments to pass to
    `nix-env`, take path to nixpkgs and an optional nix expression
    to pass to it as arguments.
  * `readNixpkgPackageMap`: populate `PackageMap` with *all* attribute
    paths that point to derivations instead of just one per derivation.
    This fixes `resolve` not finding certain identifiers if there were
    two attributes pointing to the same derivation in nixpkgs. See also
    [#9](https://github.com/NixOS/distribution-nixpkgs/issues/9).
