#! /bin/bash

set -e

# Test setup
if [[ -d /root/.getssl ]]; then
    rm -r /root/.getssl
fi

wget --no-clobber https://raw.githubusercontent.com/letsencrypt/pebble/master/test/certs/pebble.minica.pem
# cat /etc/pki/tls/certs/ca-bundle.crt /root/pebble.minica.pem > /root/pebble-ca-bundle.crt
cat /etc/ssl/certs/ca-certificates.crt /root/pebble.minica.pem > /root/pebble-ca-bundle.crt
export CURL_CA_BUNDLE=/root/pebble-ca-bundle.crt
export GETSSL_HOST=getssl.test

curl -X POST -d '{"host":"'$GETSSL_HOST'", "addresses":["10.30.50.4"]}' http://10.30.50.3:8055/add-a
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

for testpath in /getssl/test/test-config/getssl*.cfg; do
    testfile=${testpath##*/}

    # Test #1 - http-01 verification
    echo "${BLUE}Test #$((testnum+=1)) - ${testfile} verification ${RESET}"

    cp /getssl/test/test-config/nginx-ubuntu-no-ssl /etc/nginx/sites-enabled/default
    service nginx restart
    /getssl/getssl -c $GETSSL_HOST
    cp "$testpath" /root/.getssl/${GETSSL_HOST}/getssl.cfg
    /getssl/getssl $GETSSL_HOST

    # Test #2 - http-01 forced renewal
    echo "${BLUE}Test #$((testnum+=1)) - ${testfile} forced renewal $RESET"
    /getssl/getssl $GETSSL_HOST -f

    # Test cleanup
    rm -r /root/.getssl
done
