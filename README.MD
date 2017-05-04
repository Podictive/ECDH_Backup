# BACKUP PROCESS
```
 SENDER --> [ UNTRUSTED STORAGE ] --> Receiver 
 * Backup         (STACK)              * Verify
 * Encrypt                       	   * Decrypt
```
## Pre-requisites:

1. Sender has a private key unique to that machine (SEN_PRIV)
2. Sender has the public key from the receiver (RECV_PUB).
3. Sender has openssl installed and can generate its own ECDH-keys. (TEMP_PRIV / TEMP_PUB)
4. Receiver has public key from Sender   (SEN_PUB)
5. Receiver has the private key of the public key referenced in 2. (RECV_PRIV)

## BACKUP PROCESS (encrypt.sh) :

1) Generate the files to be backedup (e.g. a sqldump. Outside scope of this document)
1) Generate a new temporary private key TEMP_PRIV
2a) Derive a "SharedSecret" using TEMP_PRIV and RECV_PUB - using Elliptic Curve Diffi Helman (ECDH)
2b) Create the SHA 256-hash of SharedSecret.. To be used as AES_ENCRYPTION_KEY 
3) Encrypt the file using AES_ENCRYPTION_KEY
4) Sign the encrypted contents with SEN_PRIV. This provides Integrity, Authentication and Non-Repudiation of the encrypted contents. 
5) Save TEMP_PUB as filename.encrypted.pubkey. Remove TEMP_PRIV.
6) Send : 
		filename.encrypted				the encrypted contents
		filename.encrypted.pubkey		the ephemereal public key / TEMP_PUB 
		filename.encrypted.signed   	the encrypted contents signed with SEN_PRIV

## RESTORE PROCSS (decrypt.sh) :

0) Make sure you have at least filename.encrypted, filename.encrypted.pubkey (TEMP_PUB) and SEN_PRIV
1) Verify the encrypted file comes from Sender by using your copy of SEN_PUB
2) Regenerate AES_ENCRYPTION_KEY using your RECV_PRIV and TEMP_PUB (aka filename.encrypted.pubkey)  
3) Decrypt the contents using AES_ENCRYPTION_KEY
4) Make sure the contents match what you expect
     => It may be theoretically possible an attacker changes filename.encrypted.pubkey
	 => The ECDH will then create a different AES_ENCRYPTION_KEY, and decryption using
	 => that key may result in a possible malicious plaintext ! 
