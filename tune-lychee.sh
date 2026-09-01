#!/bin/bash
# Kernel config tuning for lychee: Ryzen 5 9600X / RX 9070 / 30G / btrfs+nvme
# Desktop responsiveness + throughput. Security deliberately disregarded.
# strace/ptrace, seccomp, perf, kprobes/uprobes, BPF are all KEPT.
set -e
C="scripts/config ${CFGFILE:+--file $CFGFILE}"

# EXPERT only unhides prompts; it changes no values by itself.
$C -e EXPERT

# --- 1. CPU mitigations: compile out entirely (cmdline already has mitigations=off)
# Removes retpoline thunks, return thunks, SRSO 16-byte function padding, SLS.
$C -d CPU_MITIGATIONS

# --- 2. Hardening / LSM. SECURITY=n kills the whole LSM hook layer.
# NOTE: SECURITY_YAMA is what gates strace on non-child PIDs -> gone.
$C -d SECURITY
$C -d SECURITY_DMESG_RESTRICT
$C -d STACKPROTECTOR
$C -d FORTIFY_SOURCE
$C -d RANDOMIZE_KSTACK_OFFSET      # per-syscall RDTSC + stack shuffle
$C -d RANDOMIZE_BASE               # KASLR
$C -d MODULE_SIG                   # also cuts build time (no signing pass)
$C -d EXT4_FS_SECURITY             # meaningless with no LSM
# explicitly keep the things that actually matter to userspace:
$C -e SECCOMP -e SECCOMP_FILTER    # Chrome/VS Code/Steam/bwrap need this

# --- 3. Periodic/background work removal (latency)
$C -d SOFTLOCKUP_DETECTOR          # per-cpu watchdog hrtimer
$C -d DETECT_HUNG_TASK             # khungtaskd walks every task every 120s
$C -d WATCHDOG                     # hardware watchdog subsystem (+sp5100_tco)

# --- 4. Static full preemption (drops static_call indirection + cond_resched)
$C -d PREEMPT_DYNAMIC
$C -e PREEMPT

# --- 5. Hardware that does not exist on this machine
$C -d CFG80211                     # no wifi device at all (drops mac80211/mt76/mt7921)
$C -d WIRELESS
$C -d BT_INTEL                     # BT adapter is MediaTek
$C -d DRM_DISPLAY_DP_AUX_CEC
$C -d DRM_ACCEL                    # no NPU/accel device
$C -d DRM_LOAD_EDID_FIRMWARE
$C -d DRM_AMD_SECURE_DISPLAY       # HDCP secure display
$C -d UFS_FS                       # ancient BSD UFS
$C -d SENSORS_NCT6775              # board binds nct6683
$C -d SND_HDA_CODEC_HDMI_NVIDIA
$C -d SND_HDA_CODEC_HDMI_NVIDIA_MCP
$C -d SND_HDA_CODEC_HDMI_TEGRA
$C -d SND_HDA_CODEC_HDMI_INTEL
$C -d SND_HDA_CODEC_HDMI_SIMPLE
$C -d NET_SELFTESTS

# --- 6. Static bloat with no runtime benefit here
$C -d DYNAMIC_DEBUG                # ~1 descriptor per pr_debug callsite, permanently resident
$C -d SLUB_DEBUG                   # shrinks slab fast paths (loses /proc/slabinfo)
$C -d DEBUG_MEMORY_INIT
$C -d IKCONFIG                     # /proc/config.gz (config is in /boot anyway)
$C -d BOOT_CONFIG                  # no initramfs, so unusable
$C -d FANOTIFY_ACCESS_PERMISSIONS  # AV-style blocking hooks in path walk
$C -d USB_ANNOUNCE_NEW_DEVICES
