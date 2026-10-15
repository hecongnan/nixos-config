"""Select a Linux classroom interface, then start only the video receiver."""
import argparse
import sys

from laptop_proxy import interface_address
from oseasy_helper.cli import ipv4, main as video_main, port


def main(argv=None):
    parser = argparse.ArgumentParser(description="NixOS student video relay")
    parser.add_argument("--teacher", type=ipv4, required=True)
    parser.add_argument("--interface", default="eth0")
    parser.add_argument("--local", type=ipv4)
    parser.add_argument("--udp-port", type=port, default=7778)
    parser.add_argument("--http-host", type=ipv4, default="0.0.0.0")
    parser.add_argument("--http-port", type=port, default=17778)
    args = parser.parse_args(argv)
    try:
        local = args.local or interface_address(args.interface)
    except OSError as error:
        print(f"无法读取课堂网卡 {args.interface} 的 IPv4：{error}", file=sys.stderr)
        return 1
    print(f"课堂网卡：{args.interface} / {local}", flush=True)
    return video_main([
        "video", "--teacher", args.teacher, "--local", local,
        "--udp-port", str(args.udp_port), "--http-host", args.http_host,
        "--http-port", str(args.http_port), "--player", "none",
    ])


if __name__ == "__main__":
    raise SystemExit(main())
