# Serverless Networking: Sample code
# Instructions:
#   (1) Run this as a python3.7 AWS Lambda function whose role permits
#       Lambda invocations.
#   (2) Ensure that the Serverless Networking Python 3 layer is attached.
#   (3) The function must reside in us-east-1 during the beta in order
#       to contact the NAT punching service endpoint.
#   (4) Ensure that the Lambda function has a duration >= 10 seconds to enable enough time
#       for spawning and connecting.

import json
import os
from random import choice
import string
import time

import boto3
from botocore.exceptions import ClientError

from udt4py import UDTSocket
from lambda_networking.connect import pair

lambdasdk = boto3.client('lambda')

def lambda_handler(event, context):
    if ('invoke_type' in event):
        invoke_type = event['invoke_type']
    else:
        invoke_type = 'parent'
    # If a pairing name is provided, use that; otherwise, generate a random one.
    if ('pairing_name' in event):
        pairing_name = event['pairing_name']
    else:
        pairing_name = generate_pairing_name(10)
    print('' + invoke_type + ' using pairing_name ' + pairing_name)
    if (invoke_type == 'parent'):
        spawn_child(pairing_name)
    sock = pair(pairing_name)
    if (not sock or sock.status != UDTSocket.Status.CONNECTED):
        return {
            'statusCode': 500,
            'body': ('socket failed to rendezvous, state is:' + str(sock.status)) if sock else 'socket failed to pair'
        }
    print('networking connection established')
    if (invoke_type == 'parent'):
        # Receives block by default, so you can build simple
        # barrier synchronization or other choreographies, such as creating
        # pre-warmed Lambdas that wait to run until input is available, just
        # by waiting for messages.
        # You can also put sockets into non-blocking mode (see UDTEpoll).
        buf = bytearray(6)
        len = sock.recv(buf)
        msg = buf[0:len].decode('utf8')
        assert(msg == 'Test 1')
        len = sock.recv(buf)
        msg = buf[0:len].decode('utf8')
        assert(msg == 'Test 2')
        len = sock.recv(buf)
        msg = buf[0:len].decode('utf8')
        assert(msg == 'Test 3')

        with open('/tmp/foo', 'a') as file:
            file.write('hello at time ' + str(time.time()) + '\n')
        len = str(os.path.getsize('/tmp/foo')).encode('utf8')

        # Sockets are bidirectional:
        bytes_sent4 = sock.send(len)

        # You can also send files:
        sock.sendfile('/tmp/foo')
    else: # child
        # You can send data using bytes, bytearrays, and memoryviews.
        # Memory views guarantee zero copy transfers.
        bytes_sent1 = sock.send('Test 1'.encode('utf8'))
        bytes_sent2 = sock.send(bytes('Test 2', 'utf8'))
        bytes_sent3 = sock.send(memoryview(b'Test 3'))
        buf = bytearray(20)
        len = sock.recv(buf)
        msg = buf[0:len].decode('utf8')
        bytes_received = sock.recvfile('/tmp/bar', 0, int(msg))
        assert(bytes_received == int(msg))
        with open('/tmp/bar', 'r') as f:
            print(f.read()) # Check logs to verify file content
    # Other things you can try:
    #   sendmsg() and recvmsg() - datagram-like transmission with TTLs
    #   perfmon() - retrieve udt performance statistics
    #   UDTEpoll - a select-like capability; can be used with non-blocking mode sends and receives to create
    #              asynchronous applications
    sock.close()
    return {'statusCode': 200, 'body': 'sample completed successfully'}

# Generate a random string matching the regexp [_a-zA-Z0-9]{len}
def generate_pairing_name(len=10):
    chars = string.ascii_letters + string.digits + '_'
    return ''.join(choice(chars) for i in range(len))

# Launch an async "child" Lambda to act as the other side of the pair, passing
# it the pairing name to use. Note that we simply use another instance of this
# function for simplicity, but that's not required.
def spawn_child(pairing_name):
    print('Beginning spawn_child for pairing name ' + pairing_name)
    args = {
        'invoke_type': 'child',
        'pairing_name': pairing_name
    }
    try:
        response = lambdasdk.invoke(
            FunctionName=os.environ['AWS_LAMBDA_FUNCTION_NAME'],
            InvocationType='Event', # (i.e., async)
            LogType='None',
            Payload=json.dumps(args).encode()
        )
    except ClientError as e:
        print('Attempt to spawn child Lambda failed: ' + e.response['Error']['Message'])
        raise e
