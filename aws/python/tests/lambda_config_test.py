# Basic test - verifies that UDT-containing layer and LD_LIBRARY_PATH are set up correctly.
import udt4py
def lambda_handler(event, context):
    sock = UDTSocket()
    return {'statusCode': 200, 'body': 'Configuration test completed successfully'}
