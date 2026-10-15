{ pkgs, diskoScript }:
pkgs.testers.runNixOSTest {
  name = "aurora-preserve-existing-partitions";
  nodes.machine = { ... }: {
    virtualisation.emptyDiskImages = [ 2048 ];
    environment.systemPackages = [ pkgs.gptfdisk pkgs.dosfstools pkgs.btrfs-progs ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("sgdisk --clear /dev/vdb")
    for number in range(1, 9):
        machine.succeed(f"sgdisk -n {number}:0:+8M /dev/vdb")
    machine.succeed("sgdisk -n 9:0:+488M -t 9:ef00 -u 9:82583d67-296c-4c37-a6b6-976a4cbbe812 -n 10:0:0 -u 10:f63cafe7-af68-48d7-a02e-c021f166bbf0 /dev/vdb")
    machine.succeed("udevadm settle")
    for number in range(1, 9):
        machine.succeed(f"echo preserved-partition-{number} | dd of=/dev/vdb{number} conv=notrunc status=none")
    preserved_before = [machine.succeed(f"sha256sum /dev/vdb{number}") for number in range(1, 9)]
    table_before = machine.succeed("sfdisk --dump /dev/vdb")
    machine.succeed("mkfs.vfat -i 546455C8 /dev/vdb9")
    machine.succeed("mkfs.btrfs -f -U 12860093-9471-4933-b960-acc7f8a23823 /dev/vdb10")
    # Incorrect selection must fail before changing either approved partition.
    machine.fail("bash ${../scripts/prepare-arch-partitions.sh} /dev/vdb /dev/vdb1 /dev/vdb10")
    machine.succeed("bash ${../scripts/prepare-arch-partitions.sh} /dev/vdb /dev/vdb9 /dev/vdb10")
    machine.succeed("${diskoScript}")
    machine.succeed("test $(findmnt -no FSTYPE /mnt) = btrfs && test $(findmnt -no FSTYPE /mnt/boot) = vfat")
    machine.succeed("test $(blkid -p -s VERSION -o value /dev/vdb9) = FAT32")
    assert machine.succeed("sfdisk --dump /dev/vdb") == table_before
    assert [machine.succeed(f"sha256sum /dev/vdb{number}") for number in range(1, 9)] == preserved_before
    machine.succeed("echo retained > /mnt/home/rebuild-check")
    machine.succeed("${diskoScript}")
    machine.succeed("grep -q retained /mnt/home/rebuild-check")
  '';
}
