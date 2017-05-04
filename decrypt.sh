#!/bin/bash

filename=$1
SEN_PUB=$2
decrypted_filename=$4

RECV_PRIV=$3   # backup.pem 

if [[ "$1" == "-h" || "$#" -ne 4 ]]; then
    echo "Usage: `basename $0` filename SEN_PUB RECV_PRIV decrypted_filename"
    echo ""
    echo "This script uses Elliptic Curve Diffi Helman via OpenSSL to decrypt a file. "
    echo ""
    echo "Example: "
    echo " `basename $0` untrusted_storage/backup.sql.encrypted ./SEN_PUB.pem  ./RECV_PRIV.pem  ./backup.sql"
    echo ""
    echo "This file requires:      ( Used for D=Decrypt, V=Verification)      Explanation"
    echo " ${RECV_PRIV}                   D   the private key generated from Receiver (REC_PRIV) "
    echo " SEN_PUB                        V   the public key of the encryption machine.  (SEN_PUB) "
    echo " filename.encrypted             D   the encrypted filecontents. The script will NOT prepend .encrypted !"
    echo " filename.encrypted.pubkey      D   the public key used to generate the ECDH (TEMP_PUB)"
    echo " filename.encrypted.signed      V   Signature. Verifies the file actually comes from the backup machine and the encrypted file has not been changed. Uses SEN_PUB to verify."
    echo ""
    echo "The encryption process is explained on the wiki (Or ask Machiel)."
    echo "The only requirements for decryption is RECV_PRIV.pem, filename.encrypted and filename.encrypted.pubkey (TEMP_PUB). "
    echo "filename.encrypted.signed is used to verify the encrypted contents has not been changed and the origin of the encrypted files."
    echo "Note, the pubkey is not signed."
    exit 0
fi

echo -n "Verify the encrypted contents & signature is from the backup pc.."
mac_verification=$(openssl pkeyutl -verify -in ${filename} -sigfile ${filename}.signed -pubin -inkey ${SEN_PUB})
if [[ ${mac_verification} == "Signature Verified Successfully" ]]; then 
   echo  "$(tput setaf 2) ${mac_verification} $( tput sgr0)"
else
   echo  "$(tput setaf 1) ${mac_verification} $( tput sgr0)"
   echo ""
   echo "The signature could not be verified! "
   echo ""
   echo "Are you sure you're using the correct public key (SEN_PUB) to verify?"
   echo ""
   echo "!!! If yes, then the encrypted contents and/or the signature has been changed !!!"
   echo ""
   echo "STOPPPPPPPPPPPPPPPPPINGGGGGGGGGGGGGGGGg..................>!!!!!!"
   exit -1
fi

echo  "Re-generating AES_ENCRYPTION_KEY using our RECV_PRIV and their TEMP_PUB.. " 
EncryptionKey=$(openssl pkeyutl -derive -inkey ${RECV_PRIV} -peerkey ${filename}.pubkey | openssl dgst -sha256 | cut -d ' ' -f2)
# echo "$( tput sgr0) Encryption key is $EncryptionKey.."

echo "Decrypting file contents..."
openssl enc -aes-256-ofb -iv "0000000000000000000000000000000" -K "$EncryptionKey" -in "${filename}" -out "${decrypted_filename}"
echo "Saved decrypted contents as ${decrypted_filename}."
