print('setup.py for lambda_networking package is starting...')
import setuptools

print('Loading README.md')
with open("README.md", "r") as fh:
    long_description = fh.read()

print('Running setup on lambda_networking package')
setuptools.setup(
    name="lambda_networking",
    version="0.0.1",
    author="Tim Wagner",
    author_email="info@serverlesstech.net",
    description="Peer-to-peer networking for AWS Lambda",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/serverlessunicorn/ServerlessNetworkingClients",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: BSD License",
        "Operating System :: Unix",
    ],
    python_requires='>=3.7',
)
print('Setup of lambda_networking package complete')

