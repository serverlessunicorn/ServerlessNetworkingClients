# NATPunch bandwidth testing.
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

# Global data:
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
        spawn_child(pairing_name)

    remote_ip = asyncio.get_event_loop().run_until_complete(p2p_connect(pairing_name, invoke_type))
    assert(remote_ip)
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
 
    eprint('====BANDWIDTH TEST====')
    if (invoke_type == 'parent'):
        eprint('Server (aka parent) starting...')
        buf_size = 20000000
        msg = bytearray(buf_size)
        total_bytes_received = 0
        start_time = None
        bytes_to_skip = 0
        try:
            while True:
                bytes_received = sock.recv(msg)
                total_bytes_received += bytes_received
                # Don't start timer until the first bytes are received, to avoid
                # timing the cosntruction of the payload in the client.
                if (start_time == None):
                    start_time = time.time()
                    bytes_to_skip = total_bytes_received # Don't count towards bandwidth
                eprint('MB: ' + str(int(total_bytes_received/100000) / 10))
                if (total_bytes_received >= buf_size or not bytes_received):
                    break
        except Exception as e:
            eprint('Server received exception: ' + str(e))
        elapsed_seconds = time.time() - start_time
        eprint('Server: total of ' + str(total_bytes_received) + ' bytes received in ' + str(elapsed_seconds) + 'seconds')
        # Subtract the first payload from the bandwidth calculation, because we didn't start the timer until after the
        # first payload.
        bits_received = (total_bytes_received - bytes_to_skip) * 8
        megabits_per_second = int((bits_received / elapsed_seconds) / 1000000)
        eprint('Server: receive complete. Transfer rate was ' + str(megabits_per_second) + ' Mbit/s')
        try:
            perf_stats = sock.perfmon()
            eprint('Perf stats: ' + str(vars(perf_stats)))
            if (perf_stats.pktRcvLossTotal > 0):
                normalized_bandwidth = int((bits_received / (elapsed_seconds * (1.0 - perf_stats.pktRcvLossTotal/perf_stats.pktRecvTotal) )) / 1000000)
                eprint('Normalized bandwidth: ' + str(normalized_bandwidth))
            else:
                eprint('Normalized bandwidth is the same as real bandwidth (no packets lost)')
        except Exception as e:
            eprint('Perfmon stats not available: ' + str(e))
        sock.close()
        return {
            'statusCode': 200,
            'body': 'Pairing and bandwidth test completed successfully with Mbit/s transfer rate of ' + str(megabits_per_second)
        }
    else:
        eprint('Client (aka child) starting...')
        eprint('Client: generating random payload...')
        total = 20000000
        msg = memoryview(bytearray(random.getrandbits(8) for i in range(total)))
        eprint('Client: ...done. Attempting to send...')
        total_bytes_sent = 0
        while (True):
            bytes_sent = sock.send(msg)
            total_bytes_sent += bytes_sent
            if (total_bytes_sent >= total):
                break;
        eprint('...' + str(total_bytes_sent / 1000000) + ' MB sent')
        assert(total_bytes_sent == total)
        eprint('Client: transfer complete from client (sending) side')
        sock.close()
    return {'statusCode': 200, 'body': 'Pairing and bandwidth test completed successfully'}

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
    async with websockets.connect(api_gw_uri) as websocket:
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

if __name__ == '__main__':
    # If run from the command line, run a simple test.
    # If this is done from a laptop, the nat punching probably won't work, but
    # at least it's a good way to determine if the Python syntax and imports are valid before
    # attempting a real run in Lambda...
    eprint('Result: ' + lambda_handler(None, None))
