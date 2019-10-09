# Welcome to Serverless Networking!

The beta release of Serverless Networking enables you to establish reliable communication between two non-VPC AWS Lambda functions.

## Fast path:
The easiest way to get up and running is to [deploy the sample app in us-east-1 from the AWS Serverless App Repository.](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:293602984666:applications~ServerlessNetworkingPython3) This will create two sample functions, one that demonstrates basic buffer and file transfers, and a second that runs a bandwidth test. You can also clone the sample code, and the rest of the Serverless Networking client stack, from [its GitHub repo](https://github.com/serverlessunicorn/ServerlessNetworkingClients).


## Step-by-step guide to using Serverless Networking:
1. Setup. If you're not starting from the sample code, make sure you're in us-east-1 and have a 3.7 Python Lambda function created. Add the following layer ARN to your function: `arn:aws:lambda:us-east-1:293602984666:layer:ServerlessNetworking-Python3:9`.

1. Add imports: `from udt4py import UDTSocket, p2p_connect`  
1. To communicate, you need both sides to execute the connection code. This can be two Lambda functions, two instances of the same Lambda function, a Lambda function and a server, etc.  

        sock = p2p_connect(pairing_name)
        if (not sock or sock.status != UDTSocket.Status.CONNECTED):
            return {
                'statusCode': 500,
                'body': ('socket failed to rendezvous, state is:' + str(sock.status)) if sock else 'socket failed to pair'
            }

1. Sending data is easy - you can use the bytearray, byte (readonly bytearray), encoded strings, or memoryviews:

        bytes_sent1 = sock.send('Test 1'.encode('utf8'))
        bytes_sent2 = sock.send(bytes('Test 2', 'utf8'))
        bytes_sent3 = sock.send(memoryview(b'Test 3'))

1. Receiving is equally easy; if you're working with strings, you'll probably want to decode it into utf8. The code below shows how to avoid trailing NULLs in your string.

        buf = bytearray(20)
        len = sock.recv(buf)
        msg = buf[0:len].decode('utf8')
        
1. An example of transferring disk files (from Lambda's /tmp filesystem) is included in the sample code.
1. Other things you can do include sending datagram-like messages with lower reliability guarantees, poll for sockets that are ready to send or receive (UDTEpoll, similar to unix select), or retrieve performance data using perfmon().
1. When you're finished with a socket, execute `sock.close()` for graceful shutdown.
1. Best practice is to recreate any sockets you need on each Lambda invocation; placing a socket in a global variable may lead to broken connections between Lambda invocations. (At a minimum, you should check the status of such a socket before attempting to reuse it on the next Lambda invoke.)
