import boto3
import json
# Globals
LayerName = 'ServerlessNetworking-Python3'
lambda_sdk = boto3.client('lambda')

# Create a new (version of) this layer. Requires the build & package
# step to have been previously performed in this directory. AWS permissions
# sufficient for the two calls below must be in the ambiant environment for this to work.
try:
    print('Initiating layer publish (this will take a few seconds)...')
    layer = lambda_sdk.publish_layer_version(
        LayerName=LayerName,
        Description='ServerlessNetworking AWS Lambda layer for Python3 functions',
        Content={
            'ZipFile': open('stage_layer/layer.zip', 'rb').read()
        },
        CompatibleRuntimes=['python3.7'],
        LicenseInfo='BSD-3-Clause'
    )
    print('Layer publishing result:')
    print(json.dumps(layer))
    # Give the world permission to use this layer.
    response = lambda_sdk.add_layer_version_permission(
        LayerName=LayerName,
        VersionNumber=layer["Version"],
        StatementId='ServerlessNetworkingClientPublishScript',
        Action='lambda:GetLayerVersion',
        Principal='*'
    )
    print('Layer permissioning result:')
    print(json.dumps(response))
except Exception as e:
    print('Attempt to create layer failed: ' + str(e))
