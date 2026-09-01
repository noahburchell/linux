#!/bin/bash
# Move to CachyOS 7.2.1 carrying the tuned config forward. Run as root.
set -euo pipefail
OLD=/usr/src/linux-7.1.6-cachyos0
NEW=/usr/src/linux-7.2.1-cachyos0
TAG=cachyos-7.2.1-1

[[ -f $OLD/.config ]] || { echo "no tuned config at $OLD/.config"; exit 1; }
[[ -e $NEW ]] && { echo "$NEW already exists, refusing"; exit 1; }

cd /usr/src
echo ">>> downloading $TAG (~265 MB)"
curl -fL --progress-bar -o $TAG.tar.gz \
  "https://github.com/CachyOS/linux/releases/download/$TAG/$TAG.tar.gz"

echo ">>> extracting"
tar xf $TAG.tar.gz
mv "$TAG" "$NEW"
rm -f $TAG.tar.gz

echo ">>> carrying tuned config forward"
cp "$OLD/.config" "$NEW/.config"
cp "$OLD/tune-lychee.sh" "$NEW/tune-lychee.sh"
cd "$NEW"
make olddefconfig LLVM=1          # resolve 7.1 -> 7.2 option drift
bash tune-lychee.sh               # re-assert tuning on any options 7.2 re-introduced
make olddefconfig LLVM=1

echo ">>> verifying the settings that matter survived the version bump"
fail=0
for chk in CPU_MITIGATIONS=n SECURITY=n STACKPROTECTOR=n FORTIFY_SOURCE=n \
           RANDOMIZE_BASE=n RANDOMIZE_KSTACK_OFFSET=n MODULE_SIG=n \
           SLUB_DEBUG=n DYNAMIC_DEBUG=n PREEMPT_DYNAMIC=n \
           PREEMPT=y SCHED_BORE=y SECCOMP=y HZ_1000=y NO_HZ_IDLE=y \
           BTRFS_FS=y BLK_DEV_NVME=y DRM_AMDGPU=m LTO_CLANG_THIN=y \
           X86_NATIVE_CPU=y CC_OPTIMIZE_FOR_PERFORMANCE_O3=y; do
  o=${chk%=*}; want=${chk#*=}; got=$(scripts/config -s "$o")
  if [[ "$got" != "$want" ]]; then printf '  MISMATCH %-34s want=%s got=%s\n' "$o" "$want" "$got"; fail=1; fi
done
[[ $fail -eq 0 ]] && echo "  all checks passed"

eselect kernel set linux-7.2.1-cachyos0
echo
echo ">>> tree ready at $NEW"
echo ">>> next:  cd $NEW && make LLVM=1 -j12"
