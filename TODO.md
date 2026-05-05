# TODO

## Drop temporary 7.0 overrides in `occ-laptop/configuration.nix`

Both added 2026-05-04 alongside the 6.19 → 7.0 kernel move. Independent — drop each as its gating PR lands.

- [ ] **`zfsTo7`** — drop once OpenZFS [PR #18462](https://github.com/openzfs/zfs/pull/18462) (zfs-2.4.2 patchset) tags as `zfs-2.4.2` AND nixpkgs bumps `pkgs/os-specific/linux/zfs/unstable.nix` past 2.4.1 with `kernelMaxSupportedMajorMinor = "7.0"`. Then delete the `zfsTo7` let-binding, the `zfs_unstable` line in the `boot.kernelPackages.extend`, and `boot.zfs.package` (default resumes working).
- [ ] **`virtualbox728`** — drop once nixpkgs [PR #512148](https://github.com/NixOS/nixpkgs/pull/512148) (`virtualbox: 7.2.6 -> 7.2.8`) merges into nixos-unstable. Then delete the `virtualbox728` let-binding, the `virtualbox` line in the `boot.kernelPackages.extend`, and the entire `nixpkgs.overlays` block.
