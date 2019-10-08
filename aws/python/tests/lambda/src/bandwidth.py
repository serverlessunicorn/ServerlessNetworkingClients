# Serverless Networking: Bandwidth testing
# Instructions:
#   (1) Run this as a python3.7 AWS Lambda function whose role permits
#       Lambda invocations.
#   (2) Ensure that the Serverless Networking Python 3 layer is attached.
#   (3) The function must reside in us-east-1 during the beta in order
#       to contact the NAT punching service endpoint.
#   (4) Ensure that the Lambda function has a duration >= 60 seconds to enable enough time
#       for spawning and connecting. ***To avoid paging overhead being measured, set
#       memory size to 3GB.***
import boto3
from botocore.exceptions import ClientError
import json
from random import choice, getrandbits 
import string
import sys
import os
import time
from udt4py import UDTSocket, p2p_connect
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
    eprint('' + invoke_type + ' using pairing_name ' + pairing_name)
    if (invoke_type == 'parent'):
        spawn_child(pairing_name)
    begin = time.time()
    sock = p2p_connect(pairing_name)
    if (not sock or sock.status != UDTSocket.Status.CONNECTED):
        return {
            'statusCode': 500,
            'body': ('socket failed to rendezvous, state is:' + str(sock.status)) if sock else 'socket failed to pair'
        }
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
        msg = memoryview(bytearray(getrandbits(8) for i in range(total)))
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
    child_args = {
        'invoke_type': 'child',
        'pairing_name': pairing_name
    }
    child_args_bytes = json.dumps(child_args).encode()
    try:
        eprint('calling lambda invoke...')
        response = lambdasdk.invoke(
            FunctionName=os.environ['AWS_LAMBDA_FUNCTION_NAME'],
            InvocationType='Event', # aka async
            LogType='None',
            Payload=child_args_bytes
        )
        eprint('...lambda invoke succeeded')
    except ClientError as e:
        eprint('Attempt to spawn child Lambda failed: ' + e.response['Error']['Message'])
        raise e # Re-raise

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
    
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return str(obj)
        # Let the base class default method raise the TypeError
        return json.JSONEncoder.default(self, obj)
