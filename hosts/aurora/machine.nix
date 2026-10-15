{ ... }:
{
  my.machine = {
    username = "aurora";
    hostName = "aurora";
    # Set only after target hardware, disk and boot layout have been checked.
    installationReady = true;
    diskLayout = "existing-partitions";
    diskDevice = "/dev/disk/by-id/nvme-FORESEE_XP1000F512G_NFE476Q023944";
    efiDevice = "/dev/disk/by-partuuid/82583d67-296c-4c37-a6b6-976a4cbbe812";
    rootDevice = "/dev/disk/by-partuuid/f63cafe7-af68-48d7-a02e-c021f166bbf0";
  };
}
