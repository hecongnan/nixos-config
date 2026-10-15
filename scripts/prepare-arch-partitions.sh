#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo 'Usage: prepare-arch-partitions.sh DISK EFI_PARTITION ROOT_PARTITION' >&2
  exit 2
fi
disk=$(readlink -f "$1")
efi=$(readlink -f "$2")
root_partition=$(readlink -f "$3")
test "$(id -u)" = 0
test "$(lsblk -dno TYPE "$disk")" = disk
test "$efi" != "$disk"
test "$root_partition" != "$disk"
test "$efi" != "$root_partition"

check_partition() {
  local target=$1 number=$2 expected_guid=$3 expected_fs_uuid=$4
  test "$(lsblk -dno TYPE "$target")" = part
  test "$(lsblk -dno PKNAME "$target")" = "$(basename "$disk")"
  test "$(cat "/sys/class/block/$(basename "$target")/partition")" = "$number"
  test "$(lsblk -dno PARTUUID "$target")" = "$expected_guid"
  test "$(blkid -c /dev/null -s UUID -o value "$target")" = "$expected_fs_uuid"
  if findmnt -rn -S "$target" >/dev/null; then
    echo "Refusing to wipe a mounted partition: $target" >&2
    exit 1
  fi
}

# Validate BOTH targets before changing either. Refuse any disk/partition drift
# and any filesystem other than the original, explicitly approved Arch install.
check_partition "$efi" 9 82583d67-296c-4c37-a6b6-976a4cbbe812 5464-55C8
check_partition "$root_partition" 10 f63cafe7-af68-48d7-a02e-c021f166bbf0 12860093-9471-4933-b960-acc7f8a23823
printf 'Clearing approved Arch filesystem signatures only: %s %s\n' "$efi" "$root_partition"
wipefs --all --force -- "$efi" "$root_partition"
