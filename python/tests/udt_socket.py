"""
Copyright (c) 2014, Samsung Electronics Co.,Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of Samsung Electronics Co.,Ltd..
"""

"""
udt4py - libudt4 Cython-ish wrapper.
URL:                    https://github.com/vmarkovtsev/udt4py
Original author:        Vadim Markovtsev <v.markovtsev@samsung.com>

libudt4 is (c)2001 - 2011, The Board of Trustees of the University of Illinois.
libudt4 URL:            http://udt.sourceforge.net/
"""

"""
UDTSocket tests.
"""


import os
import socket
import threading
import time
import unittest
from udt4py import UDTSocket, UDTException


class UDTSocketTest(unittest.TestCase):
    def testOptions(self):
        self.socket = UDTSocket()
        self.assertEqual(socket.AF_INET, self.socket.family)
        self.assertEqual(socket.SOCK_STREAM, self.socket.type)
        self.assertTrue(self.socket.UDT_SNDSYN)
        self.assertTrue(self.socket.UDT_RCVSYN)
        self.assertEqual(65536, self.socket.UDP_SNDBUF)
        self.assertEqual(12288000, self.socket.UDP_RCVBUF)
        self.assertEqual(12058624, self.socket.UDT_SNDBUF)
        self.assertEqual(12058624, self.socket.UDT_RCVBUF)
        self.assertEqual(25600, self.socket.UDT_FC)
        self.socket.UDP_SNDBUF = 1024001
        self.assertEqual(1024001, self.socket.UDP_SNDBUF)

    def testRecvSend(self):
        self.socket = UDTSocket()
        self.assertEqual(UDTSocket.Status.INIT, self.socket.status)
        self.socket.bind("0.0.0.0:7013")
        self.assertEqual(UDTSocket.Status.OPENED, self.socket.status)
        self.assertEqual(("0.0.0.0", 7013), self.socket.address)
        self.socket.listen()
        self.assertEqual(UDTSocket.Status.LISTENING, self.socket.status)
        other_thread = threading.Thread(target=self.otherConnect)
        other_thread.start()
        sock, _ = self.socket.accept()
        self.assertEqual(UDTSocket.Status.CONNECTED, sock.status)
        self.assertEqual(socket.AF_INET, sock.family)
        self.assertEqual(socket.SOCK_STREAM, sock.type)
        self.assertEqual(("127.0.0.1", 7013), sock.address)
        self.assertEqual("127.0.0.1", sock.peer_address[0][0:9])
        msg = bytearray(5)
        sock.recv(msg)
        self.assertEqual(b"hello", msg)
        msg = b"12345"
        sock.recv(msg)
        self.assertEqual(b"hello", msg)
        buf = bytearray(6)
        msg = memoryview(buf)[1:]
        sock.recv(msg)
        self.assertEqual(b"hello", msg)
        other_thread.join()

    def otherConnect(self):
        sock = UDTSocket()
        sock.connect("127.0.0.1:7013")
        self.assertEqual(UDTSocket.Status.CONNECTED, sock.status)
        sock.send(b"hello")
        sock.send(b"hello")
        sock.send(b"hello")

    def testNoBlock(self):
        other_thread = threading.Thread(target=self.otherConnectNoBlock)
        other_thread.start()
        time.sleep(0.1)
        self.socket = UDTSocket(type=socket.SOCK_DGRAM)
        self.assertEqual(socket.SOCK_DGRAM, self.socket.type)
        self.socket.UDT_RCVSYN = False
        self.assertFalse(self.socket.UDT_RCVSYN)
        self.socket.bind(("0.0.0.0", 7014))
        self.socket.listen()
        sock = None
        while sock is None:
            try:
                sock, _ = self.socket.accept()
            except UDTException as e:
                self.assertEqual(UDTException.EASYNCRCV, e.error_code)
        msg = bytearray(5)
        msg[0] = 0
        while msg[0] == 0:
            try:
                sock.recvmsg(msg)
            except UDTException as e:
                self.assertEqual(UDTException.EASYNCRCV, e.error_code)
        self.assertEqual(b"hello", msg)
        other_thread.join()

    def otherConnectNoBlock(self):
        sock = UDTSocket(type=socket.SOCK_DGRAM)
        sock.UDT_SNDSYN = False
        self.assertFalse(sock.UDT_SNDSYN)
        while sock.status != UDTSocket.Status.CONNECTED:
            try:
                sock.connect("127.0.0.1:7014")
            except UDTException as e:
                self.assertEqual(UDTException.EASYNCRCV, e.error_code)
        self.assertEqual(UDTSocket.Status.CONNECTED, sock.status)
        sock.sendmsg(b"hello")

    CONTENTS = "contents123456"

    def testFiles(self):
        FILE_OUT = "/tmp/udtsocket_test_out.txt"
        sock1 = UDTSocket()
        sock2 = UDTSocket()
        sock1.bind("0.0.0.0:7015")
        sock1.listen()
        other_thread = threading.Thread(target=self.sendFile, args=(sock2,))
        other_thread.start()
        sock, _ = sock1.accept()
        sock.recvfile(FILE_OUT, 0, len(UDTSocketTest.CONTENTS))
        with open(FILE_OUT, "r") as fr:
            self.assertEqual(UDTSocketTest.CONTENTS, fr.read())
        os.remove(FILE_OUT)
        other_thread.join()

    def sendFile(self, sock):
        FILE_IN = "/tmp/udtsocket_test_in.txt"
        with open(FILE_IN, "w") as fw:
            fw.write(UDTSocketTest.CONTENTS)
        sock.connect("127.0.0.1:7015")
        sock.sendfile(FILE_IN)
        os.remove(FILE_IN)


if __name__ == "__main__":
    unittest.main()
