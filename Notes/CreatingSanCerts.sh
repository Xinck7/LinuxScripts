Sign into server needing new cerificates
Create san.config (touch san.config)
populate with information required as well as SAN information
WARNING: if you don't put in the SAN infromation Chrome won't accept the certificate
example - vi and append this information in the san.config
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext

prompt = no
[ req_distinguished_name ]
countryName                 = <>
stateOrProvinceName         = <>
localityName               = <>
organizationName           = <>
commonName                 = <>
[ req_ext ]
subjectAltName = @alt_names
[alt_names]
DNS.1   = hostname not FQDN
DNS.2   = FQDN


Create new private key and CSR (example - openssl req -out hostname-csr.csr -newkey rsa:2048 -nodes -keyout hostname-private.key -config san.conf)
Cat the .csr created
Navigate to CA to where you can sign your certificate 
Select Request a Certificate
Select advanced certificate request
Copy and Paste the .csr contents to the saved request 
Select web server as the certificate template
click submit
download the base 64 certificate
copy the certificate to the server requiring the certificate
rename as .pem instead of .cer
change the nginx.conf file to point to the new certificate and private key
restart nginx (systemctl restart nginx)

#eg
mkdir /tmp/certs/
touch /tmp/certs/san.config
cd /tmp/certs/
san_config='/tmp/certs/san.config'
echo '[ req ]' > ${san_config}
echo 'default_bits       = 2048' >> ${san_config}
echo 'distinguished_name = req_distinguished_name' >> ${san_config}
echo 'req_extensions     = req_ext' >> ${san_config}
echo 'prompt = no' >> ${san_config}
echo '[ req_distinguished_name ]' >> ${san_config}
echo 'countryName                 = <>' >> ${san_config}
echo 'stateOrProvinceName         = <>' >> ${san_config}
echo 'localityName               = <>' >> ${san_config}
echo 'organizationName           = <>' >> ${san_config}
echo "commonName                 = $(hostname).domain" >> ${san_config}
echo '[ req_ext ]' >> ${san_config}
echo 'subjectAltName = @alt_names' >> ${san_config}
echo '[alt_names]' >> ${san_config}
echo "DNS.1   = $(hostname)" >> ${san_config}
echo "DNS.2   = $(hostname).domain" >> ${san_config}