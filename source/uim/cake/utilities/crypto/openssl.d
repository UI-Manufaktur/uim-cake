module uim.cake.uilities.Crypto;

@safe:
import uim.cake;

/**
 * OpenSSL implementation of crypto features for Cake\Utility\Security
 *
 * This class is not intended to be used directly and should only
 * be used in the context of {@link \Cake\Utility\Security}.
 *
 * @internal
 */
class OpenSsl {

    protected const string METHOD_AES_256_CBC = "aes-256-cbc";

    /**
     * Encrypt a value using AES-256.
     *
     * *Caveat* You cannot properly encrypt/decrypt data with trailing null bytes.
     * Any trailing null bytes will be removed on decryption due to how PHP pads messages
     * with nulls prior to encryption.
     *
     * @param string $plain The value to encrypt.
     * @param string myKey The 256 bit/32 byte key to use as a cipher key.
     * @return string Encrypted data.
     * @throws \InvalidArgumentException On invalid data or key.
     */
    static function encrypt(string $plain, string myKey): string
    {
        $method = static::METHOD_AES_256_CBC;
        $ivSize = openssl_cipher_iv_length($method);

        $iv = openssl_random_pseudo_bytes($ivSize);

        return $iv . openssl_encrypt($plain, $method, myKey, OPENSSL_RAW_DATA, $iv);
    }

    /**
     * Decrypt a value using AES-256.
     *
     * @param string $cipher The ciphertext to decrypt.
     * @param string myKey The 256 bit/32 byte key to use as a cipher key.
     * @return string Decrypted data. Any trailing null bytes will be removed.
     * @throws \InvalidArgumentException On invalid data or key.
     */
    static function decrypt(string $cipher, string myKey): Nullable!string
    {
        $method = static::METHOD_AES_256_CBC;
        $ivSize = openssl_cipher_iv_length($method);

        $iv = mb_substr($cipher, 0, $ivSize, "8bit");
        $cipher = mb_substr($cipher, $ivSize, null, "8bit");

        myValue = openssl_decrypt($cipher, $method, myKey, OPENSSL_RAW_DATA, $iv);
        if (myValue === false) {
            return null;
        }

        return myValue;
    }
}
