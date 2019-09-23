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
UDTEpoll tests.
"""


import threading
import time
import unittest
from udt4py import UDTSocket, UDTException, UDTEpoll


class UDTEpollTest(unittest.TestCase):
    def testEpoll(self):
        self.socket = UDTSocket()
        self.socket.bind("0.0.0.0:7015")
        self.socket.listen()
        other_thread = threading.Thread(target=self.otherConnect)
        other_thread.start()
        sock, _ = self.socket.accept()
        poll = UDTEpoll()
        poll.add(sock)
        rs = []
        while len(rs) == 0:
            rs, ws, _, _ = poll.wait()
        self.assertEqual(sock, rs[0])
        self.assertEqual(sock, ws[0])
        msg = bytearray(5)
        sock.recv(msg)

    def otherConnect(self):
        sock = UDTSocket()
        sock.connect("127.0.0.1:7015")
        self.assertEqual(UDTSocket.Status.CONNECTED, sock.status)
        sock.send(b"hello")

if __name__ == "__main__":
    unittest.main()
