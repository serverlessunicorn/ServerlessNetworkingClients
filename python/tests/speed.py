import socket
from sys import argv
import time
from udt4py import UDTSocket, UDTException


if __name__ == "__main__":
    SIZE = 15 * 1000 * 1000
    msg = bytearray(SIZE)
    sock_type = argv[1][0:3]
    argv[1] = argv[1][6:]
    HOST, PORT = argv[1].split(':')
    addr = (HOST, int(PORT))
    N = int(argv[2])
    if sock_type == "udt":
        sock = UDTSocket()
        sock.UDP_SNDBUF = 512 * 1024
        sock.UDP_RCVBUF = 2 * 1024 * 1024
        sock.UDT_SNDBUF = (15 * 1000 + 1000) * 1000
        sock.UDT_RCVBUF = (15 * 1000 + 1000) * 1000
    elif sock_type == "tcp":
        sock = socket.socket()
    else:
        raise Exception("Socket type \"%s\" is not supported" % sock_type)
    if argv[1].startswith("0.0.0.0"):
        sock.bind(addr)
        sock.listen(1)
        peer, _ = sock.accept()
        start = time.time()
        all = 0
        if sock_type == "udt":            
            while all < N * SIZE:
                all += peer.recv(msg)
        else:
            while all < N * SIZE:
                msg = peer.recv(4096)
                all += len(msg)
        peer.send(b'0')
        peer.close()
    else:
        sock.connect(addr)
        start = time.time()
        for i in range(N):
            sent = 0
            while (sent < len(msg)):
                chunk = sock.send(memoryview(msg)[0:len(msg)-sent])
                sent += chunk
        if sock_type == "udt":
            bye = bytearray(1)
            sock.recv(bye)
        else:
            sock.recv(1)
        sock.close()
    delta = time.time() - start
    print("%.2f sec" % delta)
