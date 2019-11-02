import asyncio
import json
import os

import websockets
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import Credentials

# Local version, because we had to patch it.
import udt4py

def pair(pairing_name:     str,
                api_key:          str='serverlessnetworkingfreetrial',
                local_port:       int=10000,
                remote_port:      int=10000,
                natpunch_timeout: int=30,
                natpunch_server:  str='services.serverlesstech.net/natpunch') -> UDTSocket:
    """ 
    Connect to a remote networking peer.
  
    Performs both NAT punching and rendezvous. The result is a new UDTSocket instance
    ready to perform reliable messaging and file transfers.

    Parameters: 
    pairing_name (str):     Virtual address; both sides must use the same pairing_name to connect. Required argument.
    api_key (str):          API key to pass to NAT punch web socket. Optional, defaults to 'serverlessnetworkingfreetrial' (which is only valid if natpunch_server is set to the default)
    local_port (int):       UDP port number to use on this side of the connection. Optional, defaults to 10000.
    remote_port (int):      UDP port number to use for the remote side of the connection. Optional, defaults to 10000.
    natpunch_timeout (int): Seconds to wait attempting to NAT punch/pair. Optional, defaults to 30. Note that rendezvous has a separate, udt-specified timeout.
    natpunch_server (str):  Host and path portion of URL to use for websocket NAT punch operation. Optional, defaults to services.serverlesstech.net/natpunch.

    Returns:
    UDTSocket: A new UDTSocket instance representing the p2p connection for pairing_name, or None if NAT punching failed. Clients should
               check the status of the socket to ensure it's in a CONNECTED state before proceeding to use it.
    
    """

    # Create a version of the websocket client class that handles AWS sigv4
    # authorization by overriding the 'write_http_request' method with the
    # logic to construct an x-amzn-auth header at the last possible moment.
    class WebSocketSigv4ClientProtocol(websockets.WebSocketClientProtocol):
        def __init__(self, *args, **kwargs) -> None:
            super().__init__(*args, **kwargs)
        def write_http_request(self, path: str, headers) -> None:
            # Intercept the GET that initiates the websocket protocol at the point where
            # all of its 'real' headers have been constructed. Add in the sigv4 header AWS needs.
            credentials = Credentials(
                os.environ['AWS_ACCESS_KEY_ID'],
                os.environ['AWS_SECRET_ACCESS_KEY'],
                os.environ['AWS_SESSION_TOKEN'])
            sigv4 = SigV4Auth(credentials, 'execute-api', os.environ['AWS_REGION'])
            request = AWSRequest(method='GET', url='https://' + natpunch_server)
            sigv4.add_auth(request)
            prepped = request.prepare()
            headers['Authorization'       ] = prepped.headers['Authorization'       ]
            headers['X-Amz-Date'          ] = prepped.headers['X-Amz-Date'          ]
            headers['x-amz-security-token'] = prepped.headers['x-amz-security-token']
            # Run the original code with the added sigv4 auth header now included:
            super().write_http_request(path, headers)

    async def natpunch():
        if (not 'AWS_ACCESS_KEY_ID' in os.environ):
            raise Exception('missing environment variable(s) required for signing',
                            'AWS_ACCESS_KEY_ID not present')
        if (not 'AWS_SECRET_ACCESS_KEY' in os.environ):
            raise Exception('missing environment variable(s) required for signing',
                            'AWS_SECRET_ACCESS_KEY not present')
        if (not 'AWS_SESSION_TOKEN' in os.environ):
            raise Exception('missing environment variable(s) required for signing',
                            'AWS_SESSION_TOKEN not present')
        if (not 'AWS_REGION' in os.environ):
            raise Exception('missing environment variable(s) required for signing',
                            'AWS_REGION not present')

        async with websockets.connect('wss://' + natpunch_server,
                                      create_protocol=WebSocketSigv4ClientProtocol,
                                      extra_headers={'x-api-key':api_key}) as websocket:
            msg_as_string = json.dumps({
                "action":       "pair",
                "pairing_name": pairing_name
            })
            await websocket.send(msg_as_string)
            try:
                result = await asyncio.wait_for(websocket.recv(), timeout=natpunch_timeout)
                json_result = json.loads(result)
                source_ip = json_result['SourceIP']
                return source_ip
            except asyncio.TimeoutError:
                return None
    remote_ip = asyncio.run(natpunch())
    if (not remote_ip):
        return None
    usock = UDTSocket()
    usock.UDT_MSS = 9000
    usock.UDT_RENDEZVOUS = True
    usock.bind(('0.0.0.0', local_port))
    print('Trying to connect to ' + remote_ip, flush=True)
    usock.connect((remote_ip, remote_port))
    return usock

# Some simple tests to verify package and shared library loading...
if __name__ == "__main__":
    print('connect: successfully loaded all packages')
    usock = UDTSocket()
    usock.bind(('0.0.0.0', 10000))
    print('lambda_networking.connect: verified udt4py shared lib was loaded')
