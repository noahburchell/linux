# lychee kernel config

## 7.1.6

this isn't really anything special, it is pretty much the CachyOS kernel and has only minor (and very stupid) changes.
is this for you? it very well could be. the biggest change here is the .config, i have spent a while
stripping everything i can. this also has the side effect of a kernel that may not have a feature you
need, or may just not work at all.

this is built for *my* machine, on purpose. i haven't made any effort to keep it general.

### what's actually different (from standard, this is mostly cachy)

- BORE patches
- lazy preemption
- 1000 Hz tick
- built with clang, LTO
- a .config with everything i don't use ripped out
- no initramfs (fs and storage drivers as =y)
- cool qr code kernel panic
  
### what it assumes you have

- NVMe storage
- a btrfs root
- an AMD GPU
- an AMD CPU
- no bluetooth
- no wifi

if your hardware doesn't look like that list, this will most likely either not boot at all, or boot and
then refuse work with half your machine.

## building it

```sh
git clone --depth 1 --branch lychee-7.1.6 https://github.com/noahburchell/linux.git
cd linux
make LLVM=1 olddefconfig
make LLVM=1 -j$(nproc)
sudo make LLVM=1 modules_install
sudo make LLVM=1 install
```


if you install it and something doesnt work, feel free to shoot me an email at lychee@nburch.org and i may get back to you.
keep in mind the extent of the "fix" will be me letting you know what has to change in the config. do NOT submit an issue asking me to add support for your hardware.
