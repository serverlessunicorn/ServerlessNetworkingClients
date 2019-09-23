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


import os

from libc.string cimport memset
from libc.stdint cimport int64_t, uint64_t, int32_t, uint32_t, uint16_t, \
    intptr_t
from libcpp cimport bool, set
from libcpp.set cimport *


cdef extern from "Python.h":
    ctypedef struct Py_buffer:
        void *buf

    char* PyByteArray_AsString(object bytearray) except NULL
    Py_buffer *PyMemoryView_GET_BUFFER(object mview) except NULL


cdef extern from "sys/socket.h":
    struct sockaddr:
        pass

    int getsockname(int, sockaddr *, unsigned int *)

    int SOCK_DGRAM
    int SOCK_STREAM


cdef extern from "netinet/in.h":
    struct in_addr:
        uint32_t s_addr

    struct sockaddr_in:
        unsigned short int sin_family
        uint16_t sin_port
        in_addr sin_addr

    uint16_t htons(uint16_t)
    uint16_t ntohs(uint16_t)

    int AF_INET6
    int AF_INET


cdef extern from "arpa/inet.h":
    int inet_aton(const char *, in_addr *)
    char *inet_ntoa(in_addr)


cdef extern from "udt/udt.h":
    ctypedef int SYSSOCKET
    ctypedef SYSSOCKET UDPSOCKET
    ctypedef int UDTSOCKET

    enum UDTSTATUS:
        _INIT "INIT"
        _OPENED "OPENED"
        _LISTENING "LISTENING"
        _CONNECTING "CONNECTING"
        _CONNECTED "CONNECTED"
        _BROKEN "BROKEN"
        _CLOSING "CLOSING"
        _CLOSED "CLOSED"
        _NONEXIST "NONEXIST"

    enum EPOLLOpt:
        _UDT_EPOLL_IN "UDT_EPOLL_IN"
        _UDT_EPOLL_OUT "UDT_EPOLL_OUT"
        _UDT_EPOLL_ERR "UDT_EPOLL_ERR"

    enum UDTOpt:
        UDT_MSS
        UDT_SNDSYN
        UDT_RCVSYN
        UDT_CC
        UDT_FC
        UDT_SNDBUF
        UDT_RCVBUF
        UDT_LINGER
        UDP_SNDBUF
        UDP_RCVBUF
        UDT_MAXMSG
        UDT_MSGTTL
        UDT_RENDEZVOUS
        UDT_SNDTIMEO
        UDT_RCVTIMEO
        UDT_REUSEADDR
        UDT_MAXBW
        UDT_STATE
        UDT_EVENT
        UDT_SNDDATA
        UDT_RCVDATA

    struct CPerfMon:
        # global measurements
        int64_t msTimeStamp
        int64_t pktSentTotal
        int64_t pktRecvTotal
        int pktSndLossTotal
        int pktRcvLossTotal
        int pktRetransTotal
        int pktSentACKTotal
        int pktRecvACKTotal
        int pktSentNAKTotal
        int pktRecvNAKTotal
        int64_t usSndDurationTotal

        # local measurements
        int64_t pktSent
        int64_t pktRecv
        int pktSndLoss
        int pktRcvLoss
        int pktRetrans
        int pktSentACK
        int pktRecvACK
        int pktSentNAK
        int pktRecvNAK
        double mbpsSendRate
        double mbpsRecvRate
        int64_t usSndDuration

        # instant measurements
        double usPktSndPeriod
        int pktFlowWindow
        int pktCongestionWindow
        int pktFlightSize
        double msRTT
        double mbpsBandwidth
        int byteAvailSndBuf
        int byteAvailRcvBuf

    cdef cppclass CUDTException:
        CUDTException(int major=0, int minor=0, int err=-1)
        CUDTException(const CUDTException& e)
        const char* getErrorMessage()
        int getErrorCode() const
        void clear()


cdef extern from "udt/udt.h" namespace "CUDTException":
    const int _SUCCESS "CUDTException::SUCCESS"
    const int _ECONNSETUP "CUDTException::ECONNSETUP"
    const int _ENOSERVER "CUDTException::ENOSERVER"
    const int _ECONNREJ "CUDTException::ECONNREJ"
    const int _ESOCKFAIL "CUDTException::ESOCKFAIL"
    const int _ESECFAIL "CUDTException::ESECFAIL"
    const int _ECONNFAIL "CUDTException::ECONNFAIL"
    const int _ECONNLOST "CUDTException::ECONNLOST"
    const int _ENOCONN "CUDTException::ENOCONN"
    const int _ERESOURCE "CUDTException::ERESOURCE"
    const int _ETHREAD "CUDTException::ETHREAD"
    const int _ENOBUF "CUDTException::ENOBUF"
    const int _EFILE "CUDTException::EFILE"
    const int _EINVRDOFF "CUDTException::EINVRDOFF"
    const int _ERDPERM "CUDTException::ERDPERM"
    const int _EINVWROFF "CUDTException::EINVWROFF"
    const int _EWRPERM "CUDTException::EWRPERM"
    const int _EINVOP "CUDTException::EINVOP"
    const int _EBOUNDSOCK "CUDTException::EBOUNDSOCK"
    const int _ECONNSOCK "CUDTException::ECONNSOCK"
    const int _EINVPARAM "CUDTException::EINVPARAM"
    const int _EINVSOCK "CUDTException::EINVSOCK"
    const int _EUNBOUNDSOCK "CUDTException::EUNBOUNDSOCK"
    const int _ENOLISTEN "CUDTException::ENOLISTEN"
    const int _ERDVNOSERV "CUDTException::ERDVNOSERV"
    const int _ERDVUNBOUND "CUDTException::ERDVUNBOUND"
    const int _ESTREAMILL "CUDTException::ESTREAMILL"
    const int _EDGRAMILL "CUDTException::EDGRAMILL"
    const int _EDUPLISTEN "CUDTException::EDUPLISTEN"
    const int _ELARGEMSG "CUDTException::ELARGEMSG"
    const int _EINVPOLLID "CUDTException::EINVPOLLID"
    const int _EASYNCFAIL "CUDTException::EASYNCFAIL"
    const int _EASYNCSND "CUDTException::EASYNCSND"
    const int _EASYNCRCV "CUDTException::EASYNCRCV"
    const int _ETIMEOUT "CUDTException::ETIMEOUT"
    const int _EPEERERR "CUDTException::EPEERERR"
    const int _EUNKNOWN "CUDTException::EUNKNOWN"


cdef extern from "udt/udt.h" namespace "UDT" nogil:
    ctypedef CUDTException ERRORINFO
    ctypedef UDTOpt SOCKOPT
    ctypedef CPerfMon TRACEINFO

    const UDTSOCKET INVALID_SOCK
    const int ERROR

    int startup()
    int cleanup()
    UDTSOCKET socket(int af, int type, int protocol)
    int bind(UDTSOCKET u, const sockaddr* name, int namelen)
    int bind2(UDTSOCKET u, UDPSOCKET udpsock)
    int listen(UDTSOCKET u, int backlog)
    UDTSOCKET accept(UDTSOCKET u, sockaddr* addr, int* addrlen)
    int connect(UDTSOCKET u, const sockaddr* name, int namelen)
    int close(UDTSOCKET u)
    int getpeername(UDTSOCKET u, sockaddr* name, int* namelen)
    int udt_getsockname "UDT::getsockname" (UDTSOCKET u, sockaddr* name,
                                            int* namelen)
    int getsockopt(UDTSOCKET u, int level, SOCKOPT optname, void* optval,
                   int* optlen)
    int setsockopt(UDTSOCKET u, int level, SOCKOPT optname, const void* optval,
                   int optlen)
    int send(UDTSOCKET u, const char* buf, int len, int flags)
    int recv(UDTSOCKET u, char* buf, int len, int flags)
    int sendmsg(UDTSOCKET u, const char* buf, int len, int ttl,
                bool inorder)
    int recvmsg(UDTSOCKET u, char* buf, int len)
    int64_t sendfile2(UDTSOCKET u, const char* path, int64_t* offset,
                      int64_t size, int block)
    int64_t recvfile2(UDTSOCKET u, const char* path, int64_t* offset,
                      int64_t size, int block)
    int epoll_create()
    int epoll_add_usock(int eid, UDTSOCKET u, const int* events)
    int epoll_add_ssock(int eid, SYSSOCKET s, const int* events)
    int epoll_remove_usock(int eid, UDTSOCKET u)
    int epoll_remove_ssock(int eid, SYSSOCKET s)
    int epoll_wait(int eid, set[UDTSOCKET]* readfds, set[UDTSOCKET]* writefds,
                   int64_t msTimeOut, set[SYSSOCKET]* lrfds,
                   set[SYSSOCKET]* wrfds)
    int epoll_release(int eid)
    ERRORINFO& getlasterror()
    int getlasterror_code()
    const char* getlasterror_desc()
    int perfmon(UDTSOCKET u, TRACEINFO* perf, bool clear)
    UDTSTATUS getsockstate(UDTSOCKET u)


"""
Here go Python wrappers. ------------------------------------------------------
"""


import atexit
import warnings
from functools import wraps

version = "1.0"


if startup() == ERROR:
    raise UDTException()


def shutdown():
    """
    Frees any resources allocated by libudt4.
    """
    cleanup()

atexit.register(shutdown)


cdef char *python_buffer_to_bytes(buf):
    if isinstance(buf, bytes):
        return buf
    if isinstance(buf, bytearray):
        return PyByteArray_AsString(buf)
    if isinstance(buf, memoryview):
        return <char *>PyMemoryView_GET_BUFFER(buf).buf
    raise ValueError("buf must be either an instance of bytes, bytearray or "
                     "memoryview")


class UDTException(Exception):
    """
    libudt4 error wrapper. Corresponds to libudt4's ERRORINFO.
    """

    SUCCESS = _SUCCESS
    ECONNSETUP = _ECONNSETUP
    ENOSERVER = _ENOSERVER
    ECONNREJ = _ECONNREJ
    ESOCKFAIL = _ESOCKFAIL
    ESECFAIL = _ESECFAIL
    ECONNFAIL = _ECONNFAIL
    ECONNLOST = _ECONNLOST
    ENOCONN = _ENOCONN
    ERESOURCE = _ERESOURCE
    ETHREAD = _ETHREAD
    ENOBUF = _ENOBUF
    EFILE = _EFILE
    EINVRDOFF = _EINVRDOFF
    ERDPERM = _ERDPERM
    EINVWROFF = _EINVWROFF
    EWRPERM = _EWRPERM
    EINVOP = _EINVOP
    EBOUNDSOCK = _EBOUNDSOCK
    ECONNSOCK = _ECONNSOCK
    EINVPARAM = _EINVPARAM
    EINVSOCK = _EINVSOCK
    EUNBOUNDSOCK = _EUNBOUNDSOCK
    ENOLISTEN = _ENOLISTEN
    ERDVNOSERV = _ERDVNOSERV
    ERDVUNBOUND = _ERDVUNBOUND
    ESTREAMILL = _ESTREAMILL
    EDGRAMILL = _EDGRAMILL
    EDUPLISTEN = _EDUPLISTEN
    ELARGEMSG = _ELARGEMSG
    EINVPOLLID = _EINVPOLLID
    EASYNCFAIL = _EASYNCFAIL
    EASYNCSND = _EASYNCSND
    EASYNCRCV = _EASYNCRCV
    ETIMEOUT = _ETIMEOUT
    EPEERERR = _EPEERERR
    EUNKNOWN = _EUNKNOWN

    error_code_map = {
        SUCCESS: "SUCCESS",
        ECONNSETUP: "ECONNSETUP",
        ENOSERVER: "ENOSERVER",
        ECONNREJ: "ECONNREJ",
        ESOCKFAIL: "ESOCKFAIL",
        ESECFAIL: "ESECFAIL",
        ECONNFAIL: "ECONNFAIL",
        ECONNLOST: "ECONNLOST",
        ENOCONN: "ENOCONN",
        ERESOURCE: "ERESOURCE",
        ETHREAD: "ETHREAD",
        ENOBUF: "ENOBUF",
        EFILE: "EFILE",
        EINVRDOFF: "EINVRDOFF",
        ERDPERM: "ERDPERM",
        EINVWROFF: "EINVWROFF",
        EWRPERM: "EWRPERM",
        EINVOP: "EINVOP",
        EBOUNDSOCK: "EBOUNDSOCK",
        ECONNSOCK: "ECONNSOCK",
        EINVPARAM: "EINVPARAM",
        EINVSOCK: "EINVSOCK",
        EUNBOUNDSOCK: "EUNBOUNDSOCK",
        ENOLISTEN: "ENOLISTEN",
        ERDVNOSERV: "ERDVNOSERV",
        ERDVUNBOUND: "ERDVUNBOUND",
        ESTREAMILL: "ESTREAMILL",
        EDGRAMILL: "EDGRAMILL",
        EDUPLISTEN: "EDUPLISTEN",
        ELARGEMSG: "ELARGEMSG",
        EINVPOLLID: "EINVPOLLID",
        EASYNCFAIL: "EASYNCFAIL",
        EASYNCSND: "EASYNCSND",
        EASYNCRCV: "EASYNCRCV",
        ETIMEOUT: "ETIMEOUT",
        EPEERERR: "EPEERERR",
        EUNKNOWN: "EUNKNOWN",
    }

    def __init__(self):
        self._error_code = getlasterror_code()
        self._message = getlasterror_desc().decode()
        super(UDTException, self).__init__(
            "%s(%d): %s" % (UDTException.error_code_map.get(self._error_code,
                                                            "EUNKNOWN"),
                            self._error_code,
                            self._message))

    def __int__(self):
        return self._error_code

    @property
    def error_code(self):
        return self._error_code

    @property
    def message(self):
        return self._message


cdef sockaddr_in str_to_sockaddr_in(str addr, unsigned short int family):
    str_host, str_port = \
        [part.strip() for part in addr.encode().split(b':')]
    cdef sockaddr_in addrv4
    memset(&addrv4, 0, sizeof(sockaddr_in))
    addrv4.sin_family = family
    addrv4.sin_port = htons(int(str_port))
    if inet_aton(str_host, &addrv4.sin_addr) == 0:
        raise ValueError("Could not parse IPv4 address \"%s\"" % str_host)
    return addrv4

cdef sockaddr_in tuple_to_sockaddr_in(addr, unsigned short int family):
    str_host, port = addr
    host = str_host.encode()
    cdef sockaddr_in addrv4
    memset(&addrv4, 0, sizeof(sockaddr_in))
    addrv4.sin_family = family
    addrv4.sin_port = htons(port)
    if inet_aton(host, &addrv4.sin_addr) == 0:
        raise ValueError("Could not parse IPv4 address \"%s\"" % host)
    return addrv4

"""
cdef sockaddr_in_to_str(sockaddr_in addr):
    cdef uint16_t port = ntohs(addr.sin_port)
    cdef const char *host = inet_ntoa(addr.sin_addr)
    return "%s:%d" % (host.decode(), port)
"""

cdef sockaddr_in_to_tuple(sockaddr_in addr):
    cdef int port = ntohs(addr.sin_port)
    cdef const char *host = inet_ntoa(addr.sin_addr)
    return (host.decode(), port)


class UDTSocket(object):
    """
    UDT is a reliable UDP based application level data transport protocol for
    distributed data intensive applications over wide area high-speed networks.
    UDT uses UDP to transfer bulk data with its own reliability control and
    congestion control mechanisms. The new protocol can transfer data at a much
    higher speed than TCP does. UDT is also a highly configurable framework
    that can accommodate various congestion control algorithms.
    """

    @staticmethod
    def _udt_check(int ret):
        """
        Internal method. Do not use it.
        """
        if ret == ERROR:
            raise UDTException()
        return ret

    def _udtapi(fn):
        """
        Internal libudt4 API calls decorator which checks the resulting error
        code and throws an instance of UDTException in case of an error.
        """
        @wraps(fn)
        def wrapped(*args, **kwargs):
            ret = fn(*args, **kwargs)
            if ret is not None:
                return UDTSocket._udt_check(ret)
        return wrapped

    class Status(int):
        """
        UDTSocket status. Corresponds to libudt4's UDTSTATUS.
        """

        INIT = _INIT
        OPENED = _OPENED
        LISTENING = _LISTENING
        CONNECTING = _CONNECTING
        CONNECTED = _CONNECTED
        BROKEN = _BROKEN
        CLOSING = _CLOSING
        CLOSED = _CLOSED
        NONEXIST = _NONEXIST

        status_map = {
            INIT: "INIT",
            OPENED: "OPENED",
            LISTENING: "LISTENING",
            CONNECTING: "CONNECTING",
            CONNECTED: "CONNECTED",
            BROKEN: "BROKEN",
            CLOSING: "CLOSING",
            CLOSED: "CLOSED",
            NONEXIST: "NONEXIST",
        }

        def __new__(cls, value):
            instance = int.__new__(cls, value)
            return instance

        def __str__(self):
            return UDTSocket.Status.status_map.get(self, "UNKNOWN")

        def __repr__(self):
            return "UDT socket status %s(%d)" % (self, self)

    class TraceInfo(object):
        """
        UDTSocket.perfmon() call result. Corresponds to libudt4's
        UDT::TRACEINFO struct.
        """

        def __init__(self, *args):
            super(UDTSocket.TraceInfo, self).__init__()
            # global measurements
            self.msTimeStamp, self.pktSentTotal, self.pktRecvTotal,
            self.pktSndLossTotal, self.pktRcvLossTotal, self.pktRetransTotal,
            self.pktSentACKTotal, self.pktRecvACKTotal, self.pktSentNAKTotal,
            self.pktRecvNAKTotal, self.usSndDurationTotal,
            # local measurements
            self.pktSent, self.pktRecv, self.pktSndLoss, self.pktRcvLoss,
            self.pktRetrans, self.pktSentACK, self.pktRecvACK, self.pktSentNAK,
            self.pktRecvNAK, self.mbpsSendRate, self.mbpsRecvRate,
            self.usSndDuration,
            # instant measurements
            self.usPktSndPeriod, self.pktFlowWindow, self.pktCongestionWindow,
            self.pktFlightSize, self.msRTT, self.mbpsBandwidth,
            self.byteAvailSndBuf, self.byteAvailRcvBuf = args

    def __init__(self, int family=AF_INET, int type=SOCK_STREAM):
        """
        Creates a new UDT socket.

        Parameters:
            family      The address family. It must be either AF_INET (the
                        default) or AF_INET6.

            type        The socket type. It must be either SOCK_STREAM (the
                        default) or SOCK_DGRAM.

        Description:
            Creates a new UDT socket. The is no limits for the number of UDT
            sockets in one system, as long as there is enough system resource.
            UDT supports both IPv4 and IPv6, which can be selected by the v6
            parameter. On the other hand, two socket types are supported in
            UDT, i.e., SOCK_STREAM for data streaming and SOCK_DGRAM for
            messaging. Note that UDT sockets are connection oriented in all
            cases.
        """
        super(UDTSocket, self).__init__()
        self.socket = None
        if family != AF_INET and family != AF_INET6:
            raise ValueError("Unsupported address family.")
        if family == AF_INET6:
            warnings.warn("IPv6 sockets are currently  not supported by this "
                          "wrapper")
        self._family = family
        if type != SOCK_STREAM and type != SOCK_DGRAM:
            raise ValueError("Unsupported socket type.")
        self._type = type
        cdef UDTSOCKET mysocket = INVALID_SOCK
        with nogil:
            mysocket = socket(family, type, 0)  # ignored
        if mysocket == INVALID_SOCK:
            raise UDTException()
        self.socket = mysocket

    def __del__(self):
        try:
            self.close()
        except UDTException:
            pass

    def __enter__(self):
        return self

    def __exit__(self, type=None, value=None, traceback=None):
        self.close()

    @_udtapi
    def close(self):
        """
        Mark the socket closed. The underlying system resources are closed.
        Once that happens, all future operations on the socket object will
        fail. The remote end will receive no more data (after queued data is
        flushed).

        Sockets are automatically closed when they are garbage-collected, but
        it is recommended to close() them explicitly, or to use a with
        statement around them.
        """
        if self.socket is None:
            return
        cdef UDTSOCKET mysocket = self.socket
        self.socket = None
        with nogil:
            result = close(mysocket)
        return result

    def __str__(self):
        return "UDT socket (status %s, address %s)" % \
            (self.status, self.address if
                self.status > UDTSocket.Status.INIT and
                self.status < UDTSocket.Status.CLOSED
             else "<none>")

    def _bind_address(self, addr):
        """
        Internal method. Do not use it directly.
        """
        cdef int result = ERROR
        cdef UDTSOCKET mysocket = self.socket
        cdef sockaddr_in addrv4 = str_to_sockaddr_in(addr, self._family) \
            if isinstance(addr, str) \
            else tuple_to_sockaddr_in(addr, self._family)
        with nogil:
            result = bind(mysocket, <sockaddr *>&addrv4, sizeof(sockaddr))
        return result

    def _bind_socket(self, UDPSOCKET sock):
        """
        Internal method. Do not use it directly.
        """
        cdef int result = ERROR
        cdef UDTSOCKET mysocket = self.socket
        cdef UDPSOCKET udpsocket = sock
        with nogil:
            result = bind2(mysocket, udpsocket)
        return result

    @_udtapi
    def bind(self, address_or_udp_socket):
        """
        Binds a UDT socket to a known or an available local address.

        Parameters:
            address_or_udp_socket   ipaddr:port string or tuple to assign or
                                    an existing UDP socket for UDT to use. For
                                    example, '0.0.0.0:7777' or
                                    ('192.168.0.1', 0).

        Description:
            The bind method is usually to assign a UDT socket a local address,
            including IP address and port number. If INADDR_ANY is used,
            a proper IP address will be used once the UDT connection is set up.
            If 0 is used for the port, a randomly available port number will be
            used. The property name can be used to retrieve this port number.

            The second form of bind allows UDT to bind directly on an existing
            UDP socket. This is usefule for firewall traversing in certain
            situations: 1) a UDP socket is created and its address is learned
            from a name server, there is no need to close the UDP socket and
            open a UDT socket on the same address again; 2) for certain
            firewall, especially some on local system, the port mapping maybe
            changed or the "hole" may be closed when a UDP socket is closed and
            reopened, thus it is necessary to use the UDP socket directly in
            UDT.

            Use the second form of bind with caution, as it violates certain
            programming rules regarding code robustness. Once the UDP socket
            descriptor is passed to UDT, it MUST NOT be touched again. DO NOT
            use this unless you clearly understand how the related systems
            work.

            The bind call is necessary in all cases except for a socket to
            listen. If bind is not called, UDT will automatically bind a socket
            to a randomly available address when a connection is set up.

            By default, UDT allows to reuse existing UDP port for new UDT
            sockets, unless UDT_REUSEADDR is set to False. When UDT_REUSEADDR
            is False, UDT will create an exclusive UDP port for this UDT
            socket. UDT_REUSEADDR must be called before bind. To reuse
            an existing UDT/UDP port, the new UDT socket must explicitly bind
            to the port. If the port is already used by a UDT socket with
            UDT_REUSEADDR as False, the new bind will return error. If 0 is
            passed as the port number, bind always creates a new port,
            no matter what value the UDT_REUSEADDR sets.
        """
        if isinstance(address_or_udp_socket, str) or \
           isinstance(address_or_udp_socket, tuple):
            return self._bind_address(address_or_udp_socket)
        elif isinstance(address_or_udp_socket, int):
            return self._bind_socket(address_or_udp_socket)
        else:
            raise ValueError("address_or_udp_socket must be either a string, "
                             "a tuple (str, int) or an integer")

    @_udtapi
    def listen(self, int backlog=128):
        """
        The listen method enables a server UDT entity to wait for clients to
        connect.

        Parameters:
            backlog     Maximum number of pending connections. Defaults to
                        SOMAXCONN defined at sys/socket.h (128).

        Description:
            The listen method lets a UDT socket enter listening state.
            The socket must call bind before a listen call. In addition, if
            the socket is enable for rendezvous mode, neither listen nor accept
            can be used on the socket. A UDT socket can call listen more than
            once, in which case only the first call is effective, while all
            subsequent calls will be ignored if the socket is already in
            listening state.
        """
        cdef int result = ERROR
        cdef UDTSOCKET mysocket = self.socket
        cdef int mybacklog = backlog
        with nogil:
            result = listen(mysocket, mybacklog)
        return result

    def accept(self):
        """
        Retrieves an incoming connection. Returns a tuple
        (instance of UDTSocket, it's address).

        Description:
            Once a UDT socket is in listening state, it accepts new connections
            and maintains the pending connections in a queue. An accept call
            retrieves the first connection in the queue, removes it from the
            queue, and returns the associated socket descriptor together with
            the incoming socket address.

            If there is no connections in the queue when accept is called, a
            blocking socket will wait until a new connection is set up, whereas
            a non-blocking socket will return immediately with an error.

            The accepted sockets will inherit all proper attributes from the
            listening socket.
        """
        cdef UDTSOCKET result = INVALID_SOCK
        cdef UDTSOCKET mysocket = self.socket
        cdef sockaddr_in addrv4
        cdef int addrlen
        with nogil:
            result = accept(mysocket, <sockaddr*>&addrv4, &addrlen)
        if result == INVALID_SOCK:
            raise UDTException()
        rsock = UDTSocket.__new__(UDTSocket)
        super(UDTSocket, rsock).__init__()
        rsock.socket = result
        rsock._family = self._family
        rsock._type = self._type
        return (rsock, sockaddr_in_to_tuple(addrv4))

    @_udtapi
    def connect(self, addr):
        """
        Connects to a server socket (in regular mode) or a peer socket (in
        rendezvous mode) to set up a UDT connection.

        Parameters:
            addr        ipaddr:port string or tuple. For example,
                        '192.168.0.1:7777' or ('127.0.0.1', 8000).

        Description:
            UDT is connection oriented, for both of its SOCK_STREAM and
            SOCK_DGRAM mode. connect must be called in order to set up a UDT
            connection. The name parameter is the address of the server or the
            peer side. In regular (default) client/server mode, the server side
            must has called bind and listen. In rendezvous mode, both sides
            must call bind and connect to each other at (approximately)
            the same time. Rendezvous connect may not be used for more than one
            connections on the same UDP port pair, in which case UDT_REUSEADDR
            may be set to False.

            UDT connect takes at least one round trip to finish. This may
            become a bottleneck if applications frequently connect and
            disconnect to the same address.

            When UDT_RCVSYN is set to False, the connect call will return
            immediately and perform the actual connection setup at background.
            Applications may use epoll to wait for the connect to complete.

            When connect fails, the UDT socket can still be used to connect
            again. However, if the socket was not bound before, it may be bound
            implicitly, as mentioned above, even if the connect fails. In
            addition, in the situation when the connect call fails, the UDT
            socket will not be automatically released, it is the applications'
            responsibility to close the socket, if the socket is not needed
            anymore (e.g., to re-connect).
        """
        cdef int result = ERROR
        cdef UDTSOCKET mysocket = self.socket
        if not isinstance(addr, str) and not isinstance(addr, tuple):
            raise ValueError('addr must be either a string or a (str, int) '
                             'tuple')
        cdef sockaddr_in addrv4 = str_to_sockaddr_in(addr, self._family) \
            if isinstance(addr, str) \
            else tuple_to_sockaddr_in(addr, self._family)
        with nogil:
            result = connect(mysocket, <sockaddr*>&addrv4, sizeof(sockaddr))
        return result

    @_udtapi
    def send(self, buf):
        """
        Sends out len(buf) amount of data from an application buffer. Returns
        the actual size of data that has been sent.
        If UDT_SNDTIMEO is set to a positive value, zero will be returned if no
        data is sent before the timer expires.

        Parameters:
            buf         The buffer of data to be sent (bytes, bytearray or
                        memoryview).

        Description:
            The send method sends len(buf) amount of data from the application
            buffer. If the the size limit of sending buffer queue is reached,
            send only sends a portion of the application buffer and returns the
            actual size of data that has been sent.

            In blocking mode (default), send waits until there is some sending
            buffer space available. In non-blocking mode, send returns
            immediately and returns error if the sending queue limit is already
            limited.

            If UDT_SNDTIMEO is set and the socket is in blocking mode, send
            only waits a limited time specified by UDT_SNDTIMEO option. If
            there is still no buffer space available when the timer expires,
            error will be returned. UDT_SNDTIMEO has no effect for non-blocking
            socket.
        """
        cdef UDTSOCKET mysocket = self.socket
        cdef const char *cbuf = python_buffer_to_bytes(buf)
        cdef int length = len(buf)
        with nogil:
            result = send(mysocket, cbuf, length, 0)
        return result

    @_udtapi
    def recv(self, buf):
        """
        Reads len(buf) amount of data into a local memory buffer. Returns the
        actual size of received data. If UDT_RCVTIMEO is set to a positive
        value, zero will be returned if no data is received before the timer
        expires.

        Parameters:
            buf         The buffer used to store incoming data (bytes,
                        bytearray or memoryview).

        Description:
            The recv method reads len(buf) amount of data from the protocol
            buffer. If there is not enough data in the buffer, recv only reads
            the available data in the protocol buffer and returns the actual
            size of data received. However, recv will never read more data than
            the buffer size indicates by len.

            In blocking mode (default), recv waits until there is some data
            received into the receiver buffer. In non-blocking mode, recv
            returns immediately and returns error if no data available.

            If UDT_RCVTIMEO is set and the socket is in blocking mode, recv
            only waits a limited time specified by UDT_RCVTIMEO option. If
            there is still no data available when the timer expires, error will
            be returned. UDT_RCVTIMEO has no effect for non-blocking socket.
        """
        cdef UDTSOCKET mysocket = self.socket
        cdef char *cbuf = python_buffer_to_bytes(buf)
        cdef int length = len(buf)
        with nogil:
            result = recv(mysocket, cbuf, length, 0)
        return result

    @_udtapi
    def sendmsg(self, buf, int ttl=-1, bool inorder=False):
        """
        Sends a message to the peer side. Returns it's actual size. The size
        should be equal to len. Otherwise, ELARGEMSG is raised.
        If UDT_SNDTIMEO is set to a positive value, zero will be returned if
        the message cannot be sent before the timer expires.

        Parameters:
            buf         The buffer pointed to a message bytes, bytearray
                        or memoryview).

            ttl         Optional. The Time-to-Live of the message
                        (milliseconds). Default is -1, which means infinite.

            inorder     Optional. Flag indicating if the message should be
                        delivered in order. Default is False.

        Description:
            The sendmsg method sends a message to the peer side. The UDT socket
            must be in SOCK_DGRAM mode in order to send or receive messages.
            Message is the minimum data unit in this situation. In particular,
            sendmsg always tries to send the message out as a whole, that is,
            the message will either to completely sent or it is not sent at
            all.

            In blocking mode (default), sendmsg waits until there is enough
            space to hold the whole message. In non-blocking mode, sendmsg
            returns immediately and returns error if no buffer space available.

            If UDT_SNDTIMEO is set and the socket is in blocking mode, sendmsg
            only waits a limited time specified by UDT_SNDTIMEO option. If
            there is still no buffer space available when the timer expires,
            error will be returned. UDT_SNDTIMEO has no effect for non-blocking
            socket.

            The ttl parameter gives the message a limited life time, which
            starts counting once the first packet of the message is sent out.
            If the message has not been delivered to the receiver after the TTL
            timer expires and each packet in the message has been sent out at
            least once, the message will be discarded. Lost packets in
            the message will be retransmitted before TTL expires.

            On the other hand, the inorder option decides if this message
            should be delivered in order. That is, the message should not be
            delivered to the receiver side application unless all messages
            prior to it are either delivered or discarded.

            Finally, if the message size is greater than the size of
            the receiver buffer, the message will never be received in whole by
            the receiver side. Only the beginning part that can be hold in
            the receiver buffer may be read and the rest will be discarded.
        """
        cdef UDTSOCKET mysocket = self.socket
        cdef char *cbuf = python_buffer_to_bytes(buf)
        cdef int length = len(buf)
        with nogil:
            result = sendmsg(mysocket, cbuf, length, ttl, inorder)
        return result

    @_udtapi
    def recvmsg(self, buf):
        """
        Receives a valid message. Returns it's actual size.
        If UDT_RCVTIMEO is set to a positive value, zero will be returned if no
        message is received before the timer expires.

        Parameters:
            buf         The buffer used to store the incoming message (bytes,
                        bytearray or memoryview).

        Description:
            The recvmsg method reads a message from the protocol buffer. The
            UDT socket must be in SOCK_DGRAM mode in order to send or receive
            messages. Message is the minimum data unit in this situation. Each
            recvmsg will read no more than one message, even if the message is
            smaller than the size of buf and there are more messages available.
            On the other hand, if the buf is not enough to hold the first
            message, only part of the message will be copied into the buffer,
            but the message will still be discarded after this recvmsg call.

            In blocking mode (default), recvmsg waits until there is a valid
            message received into the receiver buffer. In non-blocking mode,
            recvmsg returns immediately and returns error if no message
            available.

            If UDT_RCVTIMEO is set and the socket is in blocking mode, recvmsg
            only waits a limited time specified by UDT_RCVTIMEO option. If
            there is still no message available when the timer expires, error
            will be returned. UDT_RCVTIMEO has no effect for non-blocking
            socket.
        """
        cdef UDTSOCKET mysocket = self.socket
        cdef char *cbuf = python_buffer_to_bytes(buf)
        cdef int length = len(buf)
        with nogil:
            result = recvmsg(mysocket, cbuf, length)
        return result

    @_udtapi
    def recvfile(self, str file_name, int offset, int size, int block=7280000):
        """
        Reads certain amount of data into a local file.
        Returns the actual size of received data.

        Parameters:
            file_name       The file name where to store incoming data.

            offset          The offset position from where the data is written
                            into the file.

            size            The total size to be received.
            block           The size of every data block for file IO.

        Description:
            The recvfile method reads certain amount of data and write it into
            a local file. It is always in blocking mode and neither UDT_RCVSYN
            nor UDT_RCVTIMEO affects this method. The actual size of data to
            expect must be known before calling recvfile, otherwise deadlock
            may occur due to insufficient incoming data.
        """

        cdef UDTSOCKET mysocket = self.socket
        bfn = file_name.encode()
        cdef const char *cfile_name = bfn
        cdef int64_t coffset = offset
        cdef int64_t csize = size
        cdef int cblock = block
        cdef int64_t received = 0
        with nogil:
            received = recvfile2(mysocket, cfile_name, &coffset, csize, cblock)
        return received

    @_udtapi
    def sendfile(self, str file_name, int offset=0, int size=-1,
                 int block=364000):
        """
        Sends out part or the whole of a local file.
        Returns the actual size of data that has been sent.

        Parameters:
            file_name       The file name where to store incoming data.

            offset          The offset position from where the data is read
                            from the file.

            size            The total size to be sent.
                            Any negative value sets it to (file size - offset).
            block           The size of every data block for file IO.

        Description:
            The sendfile method sends certain amount of out of a local file. It
            is always in blocking mode and will not return until the exact
            amount of data is sent, EOF is reached, or the connection is
            broken. Neither UDT_SNDSYN nor UDT_SNDTIMEO affects this method.

            Note that sendfile does NOT nessesarily require recvfile at the
            peer side. Send/recvfile and send/recv are orthogonal UDT methods.
        """

        cdef UDTSOCKET mysocket = self.socket
        bfn = file_name.encode()
        cdef const char *cfile_name = bfn
        cdef int64_t coffset = offset
        cdef int64_t csize = size if size >= 0 \
            else os.path.getsize(file_name) - offset
        cdef int cblock = block
        cdef int64_t sent = 0
        with nogil:
            sent = sendfile2(mysocket, cfile_name, &coffset, csize, cblock)
        return sent

    def perfmon(self, bool clear=True):
        """
        Retrieves the internal protocol parameters and performance trace.
        Returns an instance of UDTSocket.TraceInfo.

        Parameters:
            clear       Flag that indicates if the local traces should be
                        cleared and counts should be restarted. Default is
                        True.

        Description:
            The perfmon method reads the performance data since the last time
            perfmon is executed, or since the connection is started. The result
            in written into a TRACEINFO structure.

            There are three kinds of performance information that can be read
            by applications: the total counts since the connection is started,
            the periodical counts since last time the counts are cleared, and
            instant parameter values.
        """
        cdef TRACEINFO ti
        UDTSocket._udt_check(perfmon(self.socket, &ti, clear))
        return UDTSocket.TraceInfo(
            # global measurements
            ti.msTimeStamp, ti.pktSentTotal, ti.pktRecvTotal,
            ti.pktSndLossTotal, ti.pktRcvLossTotal, ti.pktRetransTotal,
            ti.pktSentACKTotal, ti.pktRecvACKTotal, ti.pktSentNAKTotal,
            ti.pktRecvNAKTotal, ti.usSndDurationTotal,
            # local measurements
            ti.pktSent, ti.pktRecv, ti.pktSndLoss, ti.pktRcvLoss,
            ti.pktRetrans, ti.pktSentACK, ti.pktRecvACK, ti.pktSentNAK,
            ti.pktRecvNAK, ti.mbpsSendRate, ti.mbpsRecvRate,
            ti.usSndDuration,
            # instant measurements
            ti.usPktSndPeriod, ti.pktFlowWindow, ti.pktCongestionWindow,
            ti.pktFlightSize, ti.msRTT, ti.mbpsBandwidth,
            ti.byteAvailSndBuf, ti.byteAvailRcvBuf)

    @property
    def peer_address(self):
        """
        Retrieves the address information of the peer side of a connected UDT
        socket. Returns a tuple ('ipaddr', port), for example,
        ('192.168.0.1', 7777).

        Description:
            The getpeername retrieves the address of the peer side associated
            to the connection. The UDT socket must be connected at the time
            when this method is called. On return, namelen contains the length
            of the result.
        """
        cdef sockaddr_in addrv4
        cdef int addrlen = sizeof(sockaddr_in)
        UDTSocket._udt_check(getpeername(self.socket, <sockaddr *>&addrv4,
                                         &addrlen))
        return sockaddr_in_to_tuple(addrv4)

    @property
    def address(self):
        """
        Retrieves the local address associated with a UDT socket. Returns
        a tuple ('ipaddr', port), for example, ('192.168.0.1', 7777).

        Description:
            The getsockname retrieves the local address associated with the
            socket. The UDT socket must be bound explicitly (via bind) or
            implicitly (via connect), otherwise this method will fail because
            there is no meaningful address bound to the socket.

            If getsockname is called after an explicit bind, but before
            connect, the IP address returned will be exactly the IP address
            that is used for bind and it may be 0.0.0.0 if ADDR_ANY is used. If
            getsockname is called after connect, the IP address returned will
            be the address that the peer socket sees. In the case when there is
            a proxy (e.g., NAT), the IP address returned will be the translated
            address by the proxy, but not a local address. If there is no
            proxy, the IP address returned will be a local address. In either
            case, the port number is local (i.e, not the translated proxy
            port).

            Because UDP is connection-less, using getsockname on a UDP port
            will almost always return 0.0.0.0 as IP address (unless it is bound
            to an explicit IP) . As a connection oriented protocol, UDT will
            return a meaningful IP address by getsockname if there is no proxy
            translation exist.

            UDT has no multihoming support yet. When there are multiple local
            addresses and more than one of them can be routed to
            the destination address, UDT may not behave properly due to the
            multi-path effect. In this case, the UDT socket must be explicitly
            bound to one of the local addresses.
        """
        cdef sockaddr_in addrv4
        cdef int addrlen = sizeof(sockaddr_in)
        UDTSocket._udt_check(udt_getsockname(self.socket, <sockaddr *>&addrv4,
                                             &addrlen))
        return sockaddr_in_to_tuple(addrv4)

    @property
    def family(self):
        """
        Socket's address family (AF_INET or AF_INET6).
        """
        return self._family

    @property
    def type(self):
        """
        Socket's type (SOCK_STREAM or SOCK_DGRAM).
        """
        return self._type

    @property
    def status(self):
        """
        Retrieves the current state of the socket. Returns an instance of
        UDTSocket.Status.
        """
        cdef UDTSTATUS status = getsockstate(self.socket)
        return UDTSocket.Status(status)

    def _getsockopt(self, UDTOpt optname):
        """
        Internal getsockopt wrapper. Do not use it directly. Use corresponding
        UDTSocket properties instead.
        """
        cdef uint64_t value = 0
        cdef int vallen
        UDTSocket._udt_check(getsockopt(self.socket, 0, optname, &value,
                                        &vallen))
        return value  # & (((<uint64_t>1) << ((1 << 3) * vallen)) - 1)

    @_udtapi
    def _setsockopt(self, UDTOpt optname, value):
        """
        Internal setsockopt wrapper. Do not use it directly. Use corresponding
        UDTSocket properties instead.
        """
        cdef uint64_t cvalue = value
        cdef int vallen = sizeof(value)
        return setsockopt(self.socket, 0, optname, &cvalue, vallen)

    @property
    def UDT_MSS(self):
        """
        Maximum packet size (bytes). Including all UDT, UDP, and IP headers.
        Default 1500 bytes.

        Type: int.
        """
        return <int>self._getsockopt(UDT_MSS)

    @UDT_MSS.setter
    def UDT_MSS(self, int value):
        self._setsockopt(UDT_MSS, value)

    @property
    def UDT_SNDSYN(self):
        """
        Synchronization mode of data sending. True for blocking sending; False
        for non-blocking sending. Default True.

        Type: bool.
        """
        return <bool>self._getsockopt(UDT_SNDSYN)

    @UDT_SNDSYN.setter
    def UDT_SNDSYN(self, bool value):
        self._setsockopt(UDT_SNDSYN, value)

    @property
    def UDT_RCVSYN(self):
        """
        Synchronization mode for receiving. True for blocking receiving; False
        for non-blocking receiving. Default True.

        Type: bool.
        """
        return <bool>self._getsockopt(UDT_RCVSYN)

    @UDT_RCVSYN.setter
    def UDT_RCVSYN(self, bool value):
        self._setsockopt(UDT_RCVSYN, value)

    @property
    def UDT_CC(self):
        """
        User defined congestion control algorithm. Not currently supported by
        this wrapper.

        Type: pointer.
        """
        return <intptr_t>self._getsockopt(UDT_CC)

    @UDT_CC.setter
    def UDT_CC(self, intptr_t value):
        self._setsockopt(UDT_CC, value)

    @property
    def UDT_FC(self):
        """
        Maximum window size (packets). Default 25600. Do NOT change this unless
        you know what you are doing. Must change this before modifying
        the buffer sizes.

        Type: int.
        """
        return <int>self._getsockopt(UDT_FC)

    @UDT_FC.setter
    def UDT_FC(self, int value):
        self._setsockopt(UDT_FC, value)

    @property
    def UDT_SNDBUF(self):
        """
        UDT sender buffer size limit (bytes). Default 12058624.

        Type: int.
        """
        return <int>self._getsockopt(UDT_SNDBUF)

    @UDT_SNDBUF.setter
    def UDT_SNDBUF(self, int value):
        self._setsockopt(UDT_SNDBUF, value)

    @property
    def UDT_RCVBUF(self):
        """
        UDT receiver buffer size limit (bytes). Default 12058624.

        Type: int.
        """
        return <int>self._getsockopt(UDT_RCVBUF)

    @UDT_RCVBUF.setter
    def UDT_RCVBUF(self, int value):
        self._setsockopt(UDT_RCVBUF, value)

    @property
    def UDT_LINGER(self):
        """
        Linger time on close(). Default 180 seconds.

        Type: int (I guess).
        """
        return <int>self._getsockopt(UDT_LINGER)

    @UDT_LINGER.setter
    def UDT_LINGER(self, int value):
        self._setsockopt(UDT_LINGER, value)

    @property
    def UDP_SNDBUF(self):
        """
        UDP socket sender buffer size (bytes). Default 65536.

        Type: int.
        """
        return <int>self._getsockopt(UDP_SNDBUF)

    @UDP_SNDBUF.setter
    def UDP_SNDBUF(self, int value):
        self._setsockopt(UDP_SNDBUF, value)

    @property
    def UDP_RCVBUF(self):
        """
        UDP socket receiver buffer size (bytes). Default 12288000.

        Type: int.
        """
        return <int>self._getsockopt(UDP_RCVBUF)

    @UDP_RCVBUF.setter
    def UDP_RCVBUF(self, int value):
        self._setsockopt(UDP_RCVBUF, value)

    @property
    def UDT_MAXMSG(self):
        """
        Not documented.

        Type: int.
        """
        return <int>self._getsockopt(UDT_MAXMSG)

    @UDT_MAXMSG.setter
    def UDT_MAXMSG(self, int value):
        self._setsockopt(UDT_MAXMSG, value)

    @property
    def UDT_MSGTTL(self):
        """
        Not documented.

        Type: int.
        """
        return <int>self._getsockopt(UDT_MSGTTL)

    @UDT_MSGTTL.setter
    def UDT_MSGTTL(self, int value):
        self._setsockopt(UDT_MSGTTL, value)

    @property
    def UDT_RENDEZVOUS(self):
        """
        Rendezvous connection setup. Default False (no rendezvous mode).

        Type: bool.
        """
        return <bool>self._getsockopt(UDT_RENDEZVOUS)

    @UDT_RENDEZVOUS.setter
    def UDT_RENDEZVOUS(self, bool value):
        self._setsockopt(UDT_RENDEZVOUS, value)

    @property
    def UDT_SNDTIMEO(self):
        """
        Sending call timeout (milliseconds). Default -1 (infinite).

        Type: int.
        """
        return <int>self._getsockopt(UDT_SNDTIMEO)

    @UDT_SNDTIMEO.setter
    def UDT_SNDTIMEO(self, int value):
        self._setsockopt(UDT_SNDTIMEO, value)

    @property
    def UDT_RCVTIMEO(self):
        """
        Receiving call timeout (milliseconds). Default -1 (infinite).

        Type: int.
        """
        return <int>self._getsockopt(UDT_RCVTIMEO)

    @UDT_RCVTIMEO.setter
    def UDT_RCVTIMEO(self, int value):
        self._setsockopt(UDT_RCVTIMEO, value)

    @property
    def UDT_REUSEADDR(self):
        """
        Reuse an existing address or create a new one. Default True (reuse).

        Type: bool.
        """
        return <bool>self._getsockopt(UDT_REUSEADDR)

    @UDT_REUSEADDR.setter
    def UDT_REUSEADDR(self, bool value):
        self._setsockopt(UDT_REUSEADDR, value)

    @property
    def UDT_MAXBW(self):
        """
        Maximum bandwidth that one single UDT connection can use (bytes per
        second). Default -1 (no upper limit).

        Type: 64-bit integer.
        """
        return <int64_t>self._getsockopt(UDT_MAXBW)

    @UDT_MAXBW.setter
    def UDT_MAXBW(self, int64_t value):
        self._setsockopt(UDT_MAXBW, value)

    @property
    def UDT_STATE(self):
        """
        Current status of the UDT socket. Read only.

        Type: int.
        """
        return <int32_t>self._getsockopt(UDT_STATE)

    @property
    def UDT_EVENT(self):
        """
        The EPOLL events available to this socket. Read only.

        Type: int.
        """
        return <int32_t>self._getsockopt(UDT_EVENT)

    @property
    def UDT_SNDDATA(self):
        """
        Size of pending data in the sending buffer. Read only.

        Type: int.
        """
        return <int32_t>self._getsockopt(UDT_SNDDATA)

    @property
    def UDT_RCVDATA(self):
        """
        Size of data available to read, in the receiving buffer. Read only.

        Type: int.
        """
        return <int32_t>self._getsockopt(UDT_RCVDATA)


class UDTEpoll(object):
    """
    Provides a highly scalable and efficient way to wait for UDT sockets
    IO events. In addition, epoll also offers to wait on system sockets at the
    same time, which can be convenient when an application uses both UDT and
    TCP/UDP.

    Multiple epoll entities can be created and there is no upper limits as long
    as system resource allows. There is also no hard limit on the number of UDT
    sockets. The number system descriptors supported by UDT::epoll are platform
    dependent.
    """

    @staticmethod
    def _epoll_check(int ret):
        """
        Internal method. Do not use it.
        """
        if ret < 0:
            raise UDTException()
        return ret

    UDT_EPOLL_IN = _UDT_EPOLL_IN
    UDT_EPOLL_OUT = _UDT_EPOLL_OUT
    UDT_EPOLL_ERR = _UDT_EPOLL_ERR

    def __init__(self):
        """
        Initializes a new epoll ID.
        """
        self.epid = None
        self.epid = UDTEpoll._epoll_check(epoll_create())
        self.udt_map = {}

    def __del__(self):
        try:
            self.__exit__()
        except:
            pass

    def __enter__(self):
        return self

    def __exit__(self, type=None, value=None, traceback=None):
        if self.epid is not None:
            UDTEpoll._epoll_check(epoll_release(self.epid))

    def add(self, sock, *events):
        """
        Adds a UDT (UDTSocket) or OS (int) socket. If a socket is already in
        the epoll set, it will be ignored if being added again. Adding invalid
        or closed sockets will cause error. However, they will simply be
        ignored without any error returned when being removed.

        Parameters:
            sock        UDTSocket instance or an OS socket descriptor.

            events      For system sockets on Linux, developers may choose to
                        watch individual events from UDT_EPOLLIN (read),
                        UDT_EPOLLOUT (write), and UDT_EPOLLERR (exceptions).
                        For all other situations, the parameter is ignored and
                        all events will be watched. Note that exceptions are
                        categorized as write events, so when the application
                        choose to write to this socket, it will detect
                        the exception.
        """
        if not isinstance(sock, UDTSocket) and not isinstance(sock, int):
            raise ValueError("sock must be either an instance of "
                             "udt4py.UDTSocket or an integer")
        cdef int cevents = 0
        for event in events:
            if not isinstance(event, int):
                raise ValueError("events must be integers")
            cevents |= event
        revents = &cevents if cevents != 0 else NULL
        if isinstance(sock, UDTSocket):
            self.udt_map[sock.socket] = sock
            UDTEpoll._epoll_check(epoll_add_usock(self.epid, sock.socket,
                                                  revents))
        else:
            UDTEpoll._epoll_check(epoll_add_ssock(self.epid, sock, revents))

    def remove(self, sock):
        """
        Removes a UDT (UDTSocket) or OS (int) socket. If the OS socket is
        waiting on multiple events, only those specified in events are removed.

        Parameters:
            sock        UDTSocket or an OS socket ID.
        """
        if not isinstance(sock, UDTSocket) and not isinstance(sock, int):
            raise ValueError("sock must be either an instance of "
                             "udt4py.UDTSocket or an integer")
        if isinstance(sock, UDTSocket):
            UDTEpoll._epoll_check(epoll_remove_usock(self.epid, sock.socket))
            del(self.udt_map[sock.socket])
        else:
            UDTEpoll._epoll_check(epoll_remove_ssock(self.epid, sock))

    def wait(self, float timeout=-1):
        """
        Polls for IO events in added sockets. Returns a tuple of size 4 of
        lists: UDTSocket-s which are ready to read, UDTSocket-s which are ready
        to write, system socket IDs that are ready to read, system socket IDs
        that are ready to write, or are broken.
        If timeout occurs before any event happens, the function returns empty
        lists.

        Parameters:
            timeout     The time that this epoll should wait for the status
                        change in the input groups.
                        Negative value will make the function to wait until an
                        event happens. If the value is 0, then the function
                        returns immediately with any sockets associated
                        an IO event. Positive value is the usual Pythonic
                        time interval representation in fractions of a second,
                        as used, for example, in time.sleep().
        """
        cdef set[UDTSOCKET] urs = set[UDTSOCKET](), uws = set[UDTSOCKET]()
        cdef set[SYSSOCKET] srs = set[SYSSOCKET](), sws = set[SYSSOCKET]()
        cdef int ctimeout = <int>(timeout * 1000)
        cdef int eid = self.epid
        cdef int result
        with nogil:
            result = epoll_wait(eid, &urs, &uws, ctimeout, &srs, &sws)
        if result < 0:
            raise UDTException()
        rurs = [self.udt_map.get(s, None) for s in urs]
        ruws = [self.udt_map.get(s, None) for s in uws]
        rsrs = []
        rsrs.extend(srs)
        rsws = []
        rsws.extend(sws)
        return (rurs, ruws, rsrs, rsws)
