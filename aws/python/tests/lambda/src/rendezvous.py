import json
import asyncio
import websockets
#import socket
import sys
import time
from io import BlockingIOError
from random import choice
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config as BotoCoreConfig
import string
import os
from udt4py import UDTSocket
import random

# Websocket endpoint
api_gw_uri = 'wss://services.serverlesstech.net/natpunch'
lambdasdk = boto3.client('lambda')

def lambda_handler(event, context):
    if ('invoke_type' in event):
        invoke_type = event['invoke_type']
    else:
        # Assume the parent role if not instructed otherwise
        invoke_type = 'parent'

    # If a pairing name is provided, use that; otherwise, generate a random one.
    if ('pairing_name' in event):
        pairing_name = event['pairing_name']
    else:
        pairing_name = generate_pairing_name(10)

    eprint('Type of invoke: ' + invoke_type)
    eprint('Pairing name to be used: ' + pairing_name)

    if (invoke_type == 'parent'):
        other_side = 'child'
        spawn_child(pairing_name)
    else:
        other_side = 'parent'

    # Do the IP exchange with the peer; if I'm the parent, my child will be
    # doing likewise. If I'm the child, my parent did this after spawning me.
    remote_ip = asyncio.get_event_loop().run_until_complete(p2p_connect(pairing_name, invoke_type))
    assert(remote_ip)

    # Now we have remote IP but still need to do the actual NAT punch.
    # The two roles share a common prolog, but then diverge depending on their role.
    # P2P communication is datagram (UDP) based and is set to non blocking
    # Retries, errors, and socket closure are handled manually for this
    # conversation.
    begin = time.time()
    sock = UDTSocket()
    sock.UDT_MSS = 9000 # Experiment with this setting...
    sock.UDT_RENDEZVOUS = True
    my_address = ('0.0.0.0', 10000)
    sock.bind(my_address)
    remote_address = (remote_ip, 10000)
    sock.connect(remote_address)
    handshake_time = time.time() - begin
    eprint('' + invoke_type + ': pairing test completed successfully, took ' + str(int(handshake_time*1000)) + 'ms')
    # Verify integrity of connection. Note that the messages are short
    # so we don't have to worry about looping over incremental send/receive results.
    # Allow any exceptions to go uncaught for now (results will show up in CW Logs).
    # On the sending side we also validate that zero-copy memory views work correctly.
    #  Send a hello from myself...
    send_msg = memoryview(("hello from " + invoke_type).encode("utf8"))
    bytes_sent = sock.send(send_msg)
    assert(bytes_sent == len(send_msg))
    #  ...and expect to receive the corresponding greeting from the other side
    recv_buf = bytearray(100)
    bytes_received = sock.recv(recv_buf)
    recv_msg = recv_buf[0:bytes_received].decode("utf8")
    eprint('Received: ' + recv_msg)
    assert(recv_msg == "hello from " + other_side)
    sock.close()
    return {'statusCode': 200, 'body': 'Pairing test completed successfully'}

# Generate a random string matching the regexp [_a-zA-Z0-9]{length}
def generate_pairing_name(len=10):
    chars = string.ascii_letters + string.digits + '_'
    return ''.join(choice(chars) for i in range(len))

# Launch a "child" Lambda to act as the other side of the pair, passing
# it the pairing name to use. Note that we simply use another instance of this
# function. This function does not block after the (asynchronous)
# invocation; the caller is responsible for establishing the UDP peering.
def spawn_child(pairing_name):
    eprint('Beginning spawn_child for pairing name ' + pairing_name)
    child_args_json = {
        'invoke_type': 'child',
        'pairing_name': pairing_name
    }
    child_args_string = json.dumps(child_args_json)
    child_args_bytes = child_args_string.encode()
    try:
        eprint('calling lambda invoke...')
        response = lambdasdk.invoke(
            FunctionName=os.environ['AWS_LAMBDA_FUNCTION_NAME'],
            InvocationType='Event', # aka async
            LogType='None',
            #ClientContext='string', Not needed by this application
            Payload=child_args_bytes
            #Qualifier='string' Run latest version of the function
        )
        eprint('...lambda invoke succeeded')
    except ClientError as e:
        eprint('Attempt to spawn child Lambda failed: ' + e.response['Error']['Message'])
        raise e # Re-raise

async def p2p_connect(pairing_name, invoke_type):
    async with websockets.connect(api_gw_uri, extra_headers={'x-api-key':'serverlessnetworkingfreetrial'}) as websocket:
        # Communication with API GW is blocking, TCP-based, and via
        # websockets. The TCP connection will be closed via the "async with"
        # closure around us.
        msg = {
            "action":       "pair",
            "pairing_name": pairing_name
        }
        eprint(invoke_type + ' initiating source IP exchange using NATPunch Websocket...')
        msg_as_string = json.dumps(msg)
        await websocket.send(msg_as_string)
        response = await websocket.recv()
        eprint('...API GW connection response: ' + response)
        response_as_json = json.loads(response)
        return response_as_json['SourceIP']

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
    
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return str(obj)
        # Let the base class default method raise the TypeError
        return json.JSONEncoder.default(self, obj)
