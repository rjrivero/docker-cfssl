Certification Authority server
==============================

Certificate Authority server based on cfssl, including a few scripts to easy configuration of a two-level hierarchy of CAs (root and subordinates).

To build the container:

```
git clone https://github.com/rjrivero/docker-cfssl
cd docker-cfssl

# To build
docker build --rm -t rjrivero/cfssl .
```

To run:

```
docker run -d -p 8888:8888 -v /opt/ca/role:/opt/ca --name ca rjrivero/cfssl
```

Volumes
-------

The CA files are stored in the volume **/etc/cfssl**. This path is owned by the **cfssl** user, uid **1000**, gid **1000**. The container expects the following folder structure under /etc/cfssl (and creates it, if not found):

  - /etc/cfssl/ca-config.json: cfssl config file.
  - /etc/cfssl/db-config.json: database config file
  - /etc/cfssl/ca-key.pem: private key of the CA
  - /etc/cfssl/ca.pem: certificate of the CA
  - /etc/cfssl/root-bundle.crt: certificate bundle with the root CA's cert.

Then some other book-keeping files like the cert database *certs.db*, for keeping track of issued certificates.

The most important files are:

  - **/etc/cfssl/ca-key.pem**: The CA private key file.
  - **/etc/cfssl/ca.pem**: The CA certificate.
  - **/etc/cfssl/ca-config.json**: Defines settings for your CAs, like profiles, OCSP URLs, API Keys, etc.

Ports
-----

The container exposes SSH port **8888**.

Bootstrap
---------

  - Create the CSR for the Root CA certificate using the **csr.sh** script bundled in the container, passing the **-root* flag (single dash!)

```
# Let's assume your CA files will live under /opt/ca. We will create
# two volumes:
# - /opt/ca/root for the root CA files
# - /opt/ca/sub  for the subordinate CA files

sudo mkdir -p /opt/ca/root
sudo mkdir -p /opt/ca/sub
sudo chown -R 1000:1000 /opt/ca

# Run the container with the root CA volume, and generate a CSR
docker run --rm --name root-ca \
    -v /opt/ca/root:/etc/cfssl \
    rjrivero/cfssl csr.sh -root > ca-csr.json
```

  - Save the generated csr to **/opt/ca/root/ca-csr.json**, and customize it to match your environment.

```
# Edit the file to your heart's content, then
sudo mv ca-csr.json /opt/ca/root/
```

  - Run the container again with command ***root_ca.sh**, to generate your root private key and certificate

```
docker run --rm --name root-ca \
    -v /opt/ca/root:/etc/cfssl \
    rjrivero/cfssl root_ca.sh

# Test your certificate, if you like
openssl x509 -noout -text -in /opt/ca/root/ca.pem
```

  - Now you can start your root CA, in order to have it sign its first subordinate.

```
# Run the root CA. Notice we don't map the exposed port.
docker run -d --name root-ca -v /opt/ca/root:/etc/cfssl rjrivero/cfssl

# Take note of the CA's IP address
export CA_IP=`docker inspect --format '{ .NetworkSettings.IPAddress }' root-ca`
```

  - You should now create your subordinate CA. The steps are almost the same, using the sub CA volume:

```
# Run the container with the sub CA volume, and generate a CSR
# Leave out the -root flag this time.
docker run --rm --name sub-ca \
    -v /opt/ca/sub:/etc/cfssl \
    rjrivero/cfssl csr.sh > ca-csr.json

# Edit the file to your heart's content, then
sudo mv ca-csr.json /opt/ca/sub/

# Run the sub-ca script. Point it to the Root CA server API.
docker run --rm --name sub-ca \
    -v /opt/ca/sub:/etc/cfssl \
    rjrivero/cfssl sub_ca.sh "http://${CA_IP}:8888"

# Test the sub-CA certificate
openssl x509 -noout -text -in /opt/ca/sub/ca.pem

# Start the subordinate CA
docker run -d --name sub-ca -p 8888:8888 \
    -v /opt/ca/sub:/etc/cfssl rjrivero/cfssl
```

Now you can take offline your Root CA, encrypt the volume data, and store it safely somewhere:

```
docker stop ca-root
docker rm   ca-root

tar -cj /opt/ca/root | gpg --cipher-algo AES256 -c > root-ca.tbz.gpg
rm  -rf /opt/ca/root
```

Notice that just removing the root CA data with *rm* is not nearly secure enough. All staff related to your Root CA should be performed in an isolated computer, ideally with an encrypted disk, that is turned off when finished. This instructions are just for convenience, must no be considered the pinnacle of security.
