"""TCP relay that forces the student stream through the laptop's classroom NIC."""
import argparse
import fcntl
import select
import socket
import socketserver
import struct
import sys


def interface_address(interface):
    """Get the current Linux interface IPv4 without using the proxy route."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        result = fcntl.ioctl(probe.fileno(), 0x8915,
                            struct.pack('256s', interface.encode()[:15]))
    return socket.inet_ntoa(result[20:24])


def probe_stream(host, port, source=None, timeout=5):
    """Check HTTP headers without waiting for a classroom keyframe."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        if source:
            probe.bind((source, 0))
        probe.settimeout(timeout)
        probe.connect((host, port))
        probe.sendall((f'GET /live.ts HTTP/1.0\r\nHost: {host}:{port}\r\n\r\n').encode())
        headers = bytearray()
        while b'\r\n\r\n' not in headers:
            chunk = probe.recv(1)
            if not chunk:
                raise OSError('HTTP 服务未返回完整响应')
            headers.extend(chunk)
            if len(headers) > 16384:
                raise OSError('HTTP 响应头过大')
        status = bytes(headers).split(b'\r\n', 1)[0]
        if len(status.split()) < 2 or status.split()[1] != b'200':
            raise OSError(status.decode(errors='replace'))
        if b'content-type: video/mp2t' not in bytes(headers).lower():
            raise OSError('该端口未提供 MPEG-TS 视频流')


class RelayHandler(socketserver.BaseRequestHandler):
    def handle(self):
        response_started = False
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as upstream:
                upstream.bind((self.server.source, 0))
                upstream.settimeout(5)
                upstream.connect((self.server.remote, self.server.remote_port))
                upstream.settimeout(None)
                sockets = (self.request, upstream)
                while True:
                    readable, _, _ = select.select(sockets, (), (), 1)
                    for source in readable:
                        data = source.recv(64 * 1024)
                        if not data:
                            return
                        target = upstream if source is self.request else self.request
                        if source is upstream:
                            response_started = True
                        target.sendall(data)
        except OSError as error:
            print(f'转发连接失败：{error}', file=sys.stderr, flush=True)
            if not response_started:
                body = f'无法连接学生机中继：{error}\n'.encode()
                try:
                    self.request.sendall(b'HTTP/1.0 502 Bad Gateway\r\n'
                        b'Content-Type: text/plain; charset=utf-8\r\n'
                        + f'Content-Length: {len(body)}\r\nConnection: close\r\n\r\n'.encode()
                        + body)
                except OSError:
                    pass


class RelayServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    parser = argparse.ArgumentParser(description="Expose a remote student video stream as a local URL")
    parser.add_argument("--remote", default="10.115.3.82")
    parser.add_argument("--remote-port", type=int, default=17778)
    parser.add_argument("--source", help="Override classroom-facing IPv4")
    parser.add_argument("--interface", default="wlan0")
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=17780)
    args = parser.parse_args()
    if args.source is None:
        args.source = interface_address(args.interface)
    with RelayServer((args.bind, args.port), RelayHandler) as server:
        server.remote = args.remote
        server.remote_port = args.remote_port
        server.source = args.source
        print(f"http://127.0.0.1:{args.port}/live.ts", flush=True)
        print(f"Forwarding via {args.source} to {args.remote}:{args.remote_port}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    try:
        main()
    except OSError as error:
        print(f'转发器启动失败：{error}', file=sys.stderr)
        raise SystemExit(1)
