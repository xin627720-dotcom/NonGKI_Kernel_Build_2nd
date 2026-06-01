#!/bin/bash
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18
# 20251120

KSU_FOLDER=("drivers/kernelsu" "KernelSU" "KernelSU-Next")

KSU_CLEAN_FILES=("fs/exec.c" "fs/read_write.c" "fs/open.c" "fs/stat.c" "fs/devpts/inode.c" "fs/namei.c" "drivers/input/input.c" "drivers/tty/pty.c" "security/selinux/hooks.c" "kernel/reboot.c" "kernel/sys.c")

SUSFS_CLEAN_FILES=("security/selinux/avc.c" "kernel/kallsyms.c" "kernel/sys.c" "kernel/reboot.c" "fs/dcache.c" "fs/statfs.c" "fs/namespace.c" "fs/proc_namespace.c" "fs/stat.c" "fs/namei.c" "fs/readdir.c" "fs/exec.c" "fs/proc/task_mmu.c" "fs/proc/base.c" "fs/proc/fd.c" "fs/proc/cmdline.c" "fs/overlayfs/super.c" "fs/overlayfs/overlayfs.h" "fs/overlayfs/inode.c" "fs/overlayfs/inode.c" "fs/notify/fdinfo.c" "fs/devpts/inode.c" "include/linux/sched.h" "include/linux/mount.h")

SUSFS_REMAIN_CLEAN_FILES=("fs/susfs.c" "fs/sus_su.c" "include/linux/susfs.h" "include/linux/susfs_def.h")

# Removal of KernelSU

for file in "${KSU_FOLDER[@]}"; do
    rm -rf "${file}"

    if [ -f "${file}" ] || [ -d "${file}" ]; then
        echo "[-] Could not remove ${file}."
    else
        echo "[+] Cleaned for ${file}."
    fi
done

# Removal of KernelSU Hook

for file in "${KSU_CLEAN_FILES[@]}"; do
    sed -i '/#ifdef CONFIG_KSU\b/,/#endif/d' "${file}"

    if grep -q "#ifdef CONFIG_KSU\b" "${file}"; then
        echo "[-] Could not remove KernelSU hook from ${file}."
    else
        echo "[+] Cleaned KernelSU Hook for ${file}."
    fi
done

# Removal of SuSFS (use unifdef: correctly strips #ifdef/#ifndef/#else/#endif for SUSFS symbols)
command -v unifdef >/dev/null 2>&1 || sudo apt-get install -y unifdef >/dev/null 2>&1

SUSFS_UNDEF="-U CONFIG_KSU_SUSFS -U CONFIG_KSU_SUSFS_SUS_PATH -U CONFIG_KSU_SUSFS_SUS_MOUNT -U CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT -U CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT -U CONFIG_KSU_SUSFS_SUS_KSTAT -U CONFIG_KSU_SUSFS_SUS_OVERLAYFS -U CONFIG_KSU_SUSFS_TRY_UMOUNT -U CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT -U CONFIG_KSU_SUSFS_SPOOF_UNAME -U CONFIG_KSU_SUSFS_ENABLE_LOG -U CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS -U CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG -U CONFIG_KSU_SUSFS_OPEN_REDIRECT -U CONFIG_KSU_SUSFS_SUS_SU -U CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT -U CONFIG_KSU_SUSFS_SUS_PATH_LOOP -U CONFIG_KSU_SUSFS_SUS_MAPS"

for file in "${SUSFS_CLEAN_FILES[@]}"; do
    [ -f "${file}" ] || continue
    unifdef ${SUSFS_UNDEF} "${file}" > "${file}.ud"
    rc=$?
    if [ ${rc} -le 1 ]; then
        mv "${file}.ud" "${file}"
        echo "[+] unifdef-cleaned SuSFS for ${file} (rc=${rc})."
    else
        rm -f "${file}.ud"
        echo "[-] unifdef error (rc=${rc}) on ${file}; left unchanged."
    fi
    if grep -q "CONFIG_KSU_SUSFS" "${file}"; then
        echo "[-] residual CONFIG_KSU_SUSFS in ${file}:"; grep -n "CONFIG_KSU_SUSFS" "${file}" | head
    fi
done

for file in "${SUSFS_REMAIN_CLEAN_FILES[@]}"; do
    rm -f "${file}"

    if [ -f "${file}" ]; then
        echo "[-] Could not remove file ${file}."
    else
        echo "[+] Removed file ${file}."
    fi
done

if grep -q "CONFIG_KSU_SUSFS" "fs/Makefile"; then
    sed -i '/CONFIG_KSU_SUSFS/d' fs/Makefile
    if grep -q "CONFIG_KSU_SUSFS" "fs/Makefile"; then
        echo "[-] Could not remove code from fs/Makefile."
    else
        echo "[+] Removed code for fs/Makefile."
    fi
else
    echo "[-] Have no CONFIG_KSU_SUSFS in fs/Makefile"
fi
