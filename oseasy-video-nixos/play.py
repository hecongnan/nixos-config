"""Start the laptop relay and mpv together; exit cleans up our relay."""
import argparse
import shutil
import subprocess
import sys
import threading

from laptop_proxy import RelayServer, RelayHandler, interface_address, probe_stream


def main():
    parser = argparse.ArgumentParser(description='一键连接学生机中继并播放课堂视频')
    parser.add_argument('--remote', default='10.115.3.82')
    parser.add_argument('--remote-port', type=int, default=17778)
    parser.add_argument('--interface', default='wlan0')
    parser.add_argument('--source', help='手动指定笔记本课堂网卡 IPv4')
    parser.add_argument('--port', type=int, default=17780)
    parser.add_argument('--check', action='store_true', help='只检查学生机 HTTP 服务，不打开播放器')
    args = parser.parse_args()
    try:
        source = args.source or interface_address(args.interface)
        print(f'课堂网卡：{args.interface} / {source}', flush=True)
        probe_stream(args.remote, args.remote_port, source)
    except OSError as error:
        print(f'无法连接学生机 {args.remote}:{args.remote_port}：{error}\n'
              '请检查课堂网络、学生机 IP 及中继脚本。', file=sys.stderr)
        return 1
    print('学生机 HTTP 视频服务正常；有画面还需教师正在广播。', flush=True)
    if args.check:
        return 0
    if not shutil.which('mpv'):
        print('未找到 mpv。', file=sys.stderr)
        return 1

    server = None
    try:
        server = RelayServer(('127.0.0.1', args.port), RelayHandler)
    except OSError as error:
        if error.errno != 98:
            print(f'本地端口启动失败：{error}', file=sys.stderr)
            return 1
        try:
            probe_stream('127.0.0.1', args.port)
        except OSError as error:
            print(f'端口 {args.port} 已被占用，且未提供可用视频：{error}\n'
                  '可使用 --port 17781 换一个端口。', file=sys.stderr)
            return 1
        print('使用已有的本地视频转发器。', flush=True)
    if server:
        server.source = source
        server.remote = args.remote
        server.remote_port = args.remote_port
        threading.Thread(target=server.serve_forever, daemon=True).start()
    player = None
    try:
        url = f'http://127.0.0.1:{args.port}/live.ts'
        print(f'播放地址：{url}', flush=True)
        player = subprocess.Popen(['mpv', '--no-config', '--ytdl=no', '--cache=no', url])
        return player.wait()
    except KeyboardInterrupt:
        return 130
    finally:
        if player and player.poll() is None:
            player.terminate()
            try:
                player.wait(timeout=3)
            except subprocess.TimeoutExpired:
                player.kill()
                player.wait()
        if server:
            server.shutdown()
            server.server_close()


if __name__ == '__main__':
    raise SystemExit(main())
