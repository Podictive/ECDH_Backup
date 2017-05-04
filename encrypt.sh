#!/bin/bash

if [[ "$1" == "-h" || "$#" -ne 4 ]] ; then
    echo "Usage: `basename $0` filename workingdirectory RECV_PUB.pem SEN_PRIV.pem"
    echo ""
    echo "This script uses Elliptic Curve Diffi Helman via OpenSSL to encrypt a file. "
    echo "It will encrypt filename in workingdirectory. It will create multiple other files in the same directory"
    echo "It will not remove the original file".
    echo ""
    echo "Example: "
    echo " `basename $0` backup.sql /backup/staging_mysql_backup/ ./RECV_PUB.pem ./SEN_PRIV.pem "
    echo ""
    echo "This file requires:      ( Used for E=Encrypt, V=Verification)      Explanation"
    echo " ${RECV_PUB}    E   the public key of Receiver  (RECV_PUB)"
    echo " ${SEN_PRIV}       V   the private key of the encryption machine. (SEN_PRIV)"
    echo " filename                       E   the unencrypted filecontents in workingdirectory. E.g. backup.sql "
    echo ""
    echo "This file creates in the workingdirectory: "
    echo " filename.encrypted             D   The encrypted file"
    echo " filename.encrypted.pubkey      D   the public key used to generate the ECDH (TEMP_PUB)"
    echo " filename.encrypted.signed      V   the signed MAC. Verifies the file actually comes from the backup machine and the MAC has not been changed. Uses SEN_PRIV to sign."
    echo ""
    echo "The encryption process is explained on the wiki (Or ask Machiel)."
    echo "The only requirements for decryption is backup.pem, filename.encrypted and filename.encrypted.pubkey. "
    echo "The other files are used to verify the encrypted contents has not been changed and the origin of the encrypted files."
    exit 0
fi


filename=$1
cd $2 
RECV_PUB=$3 
SEN_PRIV=$4  

echo -n "Encrypting ${filename}.. "
echo -n "Generating TEMP_PRIV.. "
openssl ecparam -genkey -out temporary_private_key.pem -name prime256v1
echo -n "Deriving AES_ENCRYPTION_KEY from TEMP_PRIV and RECV_PUB.. "
EncryptionKey=$(openssl pkeyutl -derive -inkey temporary_private_key.pem  -peerkey ${RECV_PUB} | openssl dgst -sha256 | cut -d ' ' -f2)
# echo "Encryption key is ${EncryptionKey}"
echo -n "Encrypt.. " 
openssl enc -aes-256-ofb -iv "0000000000000000000000000000000" -K "${EncryptionKey}" -in "${filename}" -out "${filename}.encrypted"
echo -n "Sign MAC Digest with SEN_PRIV.. "
openssl pkeyutl -sign -in "${filename}.encrypted" -inkey ${SEN_PRIV} -out "${filename}.encrypted.signed"
echo -n "Writing TEMP_PUB.. "
openssl ec -pubout -in temporary_private_key.pem  -out "${filename}.encrypted.pubkey" 
echo -n "Removing files.."
rm temporary_private_key.pem
echo  "Done! "
