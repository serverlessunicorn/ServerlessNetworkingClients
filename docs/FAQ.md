# Serverless Networking FAQ

1. _What is Serverless Networking?_  
The Serverless Networking project brings reliable peer-to-peer networking to serverless applications, allowing cloud functions to easily exchange data and files.

1. _What can I do with Serverless Networking?_  
You can add get many of the capabilities that "serverful" applications enjoy: function-to-function messaging and other forms of distributed communication without paying per-message fees, stream data between cloud functions or between cloud functions and server-based applications, remotely control serverless functions to create warm capacity, choreograph functions without the need for an additional service, send multiple inputs (or receive multiple responses) from a single function invocation, and much more.

1. _Can you show me a simple example?_  
The following code sends string between two Lambda functions (error handling has been omitted for clarity):

|           Source function         |        Destination function       |
|-----------------------------------|-----------------------------------|
|`conn = connect('pairing_key_123')`|`conn = connect('pairing_key_123')`|
|`conn.send(b'Hello!')`             |`conn.recv(buf)`                   |

1. _Do I have to understand or write retry logic, sliding windows, or other networking-level code in order to use Serverless Networking?_  
No! Serverless Networking handles the hard work for you. Reliable transport, including flow control, dynamic bandwidth tuning, and retry logic as well as higher level capabilities like buffer and file transfer in Python 3 work "out of the box".

1. _What cloud platforms does Serverless Networking support?_  
The beta release targets AWS Lambda functions running outside of VPCs. Future releases will bring serverless networking capabilities to other platforms and additional AWS Lambda configurations.

1. _What languages does Serverless Networking support?_  
The beta release supports low-level C++ access (to the UDT library) and a higher-level Python 3.7 language binding. The open source Serverless Networking project is actively seeking participation to create additional language bindings and convenience layers built on top of the networking core code.

1. _How much does Serverless Networking cost?_  
The Serverless Networking client code is open source and free of charge. Currently, AWS does not charge data transfer fees for data sent between functions, and so data transferred using Serverless Networking is also free of additional charges. Forming connections between functions requires a NAT Punching coordinator; ServerlessTech offers a fully hosted NAT Punching service with a free tier, free beta evaluation mode, and modest pay-per-connect rates for production accounts. You can also deploy your own serverless NAT Punching coordinator.

1. _How fast is Serverless Networking?_  
Serverless Networking adds a reliability layer to UDP sockets; it generally performs as good or better than TCP/IP communication. _Note that network bandwidth is determined by your cloud vendor's hypervisor and operating system settings._

1. _How is Serverless Networking licensed?_
Serverless Networking and the udt4 library offer an enterprise-friendly BSD license.

1. _I'm an advanced networking user. Can I get access to the UDP sockets and code directly against them?_  
Yes. You can use the NAT Punching service to establish connectivity (and optionally handle rendezvous) but then write your own UDP code directly against Unix sockets in either C/C++ or Python 3.

1. _Can I use Serverless Networking in asynchronous programs?_  
Yes. Serverless Networking exposes an efficient select()-like mechanism and a non-blocking mode. The underlying udt4 C++ library is thread safe and can be used in multi-threaded C/C++ applications.

