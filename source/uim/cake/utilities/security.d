module uim.cake.uilities;

@safe:
import uim.cake;

// Security Library contains utility methods related to security
class Security {
    /**
     * Default hash method. If `myType` param for `Security::hash()` is not specified
     * this value is used. Defaults to "sha1".
     *
     * @var string
     */
    static $hashType = "sha1";

    /**
     * The HMAC salt to use for encryption and decryption routines
     *
     * @var string|null
     */
    protected static $_salt;

    /**
     * The crypto implementation to use.
     *
     * @var object|null
     */
    protected static $_instance;

    /**
     * Create a hash from string using given method.
     *
     * @param string $string String to hash
     * @param string|null $algorithm Hashing algo to use (i.e. sha1, sha256 etc.).
     *   Can be any valid algo included in list returned by hash_algos().
     *   If no value is passed the type specified by `Security::$hashType` is used.
     * @param mixed $salt If true, automatically prepends the value returned by
     *   Security::getSalt() to $string.
     * @return string Hash
     * @throws \RuntimeException
     * @link https://book.UIM.org/4/en/core-libraries/security.html#hashing-data
     */
    static string hash(string $string, Nullable!string $algorithm = null, $salt = false) {
        if (empty($algorithm)) {
            $algorithm = static::$hashType;
        }
        $algorithm = strtolower($algorithm);

        $availableAlgorithms = hash_algos();
        if (!in_array($algorithm, $availableAlgorithms, true)) {
            throw new RuntimeException(sprintf(
                "The hash type `%s` was not found. Available algorithms are: %s",
                $algorithm,
                implode(", ", $availableAlgorithms)
            ));
        }

        if ($salt) {
            if (!is_string($salt)) {
                $salt = static::getSalt();
            }
            $string = $salt . $string;
        }

        return hash($algorithm, $string);
    }

    /**
     * Sets the default hash method for the Security object. This affects all objects
     * using Security::hash().
     *
     * @param string $hash Method to use (sha1/sha256/md5 etc.)
     * @return void
     * @see \Cake\Utility\Security::hash()
     */
    static void setHash(string $hash) {
        static::$hashType = $hash;
    }

    /**
     * Get random bytes from a secure source.
     *
     * This method will fall back to an insecure source an trigger a warning
     * if it cannot find a secure source of random data.
     *
     * @param int $length The number of bytes you want.
     * @return string Random bytes in binary.
     */
    static string randomBytes(int $length) {
        return random_bytes($length);
    }

    /**
     * Creates a secure random string.
     *
     * @param int $length String length. Default 64.
     * @return string
     */
    static string randomString(int $length = 64) {
        return substr(
            bin2hex(Security::randomBytes((int)ceil($length / 2))),
            0,
            $length
        );
    }

    /**
     * Like randomBytes() above, but not cryptographically secure.
     *
     * @param int $length The number of bytes you want.
     * @return string Random bytes in binary.
     * @see \Cake\Utility\Security::randomBytes()
     */
    static string insecureRandomBytes(int $length) {
        $length *= 2;

        $bytes = "";
        $byteLength = 0;
        while ($byteLength < $length) {
            $bytes .= static::hash(Text::uuid() . uniqid((string)mt_rand(), true), "sha512", true);
            $byteLength = strlen($bytes);
        }
        $bytes = substr($bytes, 0, $length);

        return pack("H*", $bytes);
    }

    /**
     * Get the crypto implementation based on the loaded extensions.
     *
     * You can use this method to forcibly decide between openssl/custom implementations.
     *
     * @param \Cake\Utility\Crypto\OpenSsl|null $instance The crypto instance to use.
     * @return \Cake\Utility\Crypto\OpenSsl Crypto instance.
     * @throws \InvalidArgumentException When no compatible crypto extension is available.
     * @psalm-suppress MoreSpecificReturnType
     */
    static function engine($instance = null) {
        if ($instance == null && static::$_instance == null) {
            if (extension_loaded("openssl")) {
                $instance = new OpenSsl();
            }
        }
        if ($instance) {
            static::$_instance = $instance;
        }
        if (isset(static::$_instance)) {
            /** @psalm-suppress LessSpecificReturnStatement */
            return static::$_instance;
        }
        throw new InvalidArgumentException(
            "No compatible crypto engine available. " .
            "Load the openssl extension."
        );
    }

    /**
     * Encrypt a value using AES-256.
     *
     * *Caveat* You cannot properly encrypt/decrypt data with trailing null bytes.
     * Any trailing null bytes will be removed on decryption due to how PHP pads messages
     * with nulls prior to encryption.
     *
     * @param string $plain The value to encrypt.
     * @param string myKey The 256 bit/32 byte key to use as a cipher key.
     * @param string|null $hmacSalt The salt to use for the HMAC process.
     *   Leave null to use value of Security::getSalt().
     * @return string Encrypted data.
     * @throws \InvalidArgumentException On invalid data or key.
     */
    static string encrypt(string $plain, string myKey, Nullable!string $hmacSalt = null) {
        self::_checkKey(myKey, "encrypt()");

        if ($hmacSalt == null) {
            $hmacSalt = static::getSalt();
        }
        // Generate the encryption and hmac key.
        myKey = mb_substr(hash("sha256", myKey . $hmacSalt), 0, 32, "8bit");

        $crypto = static::engine();
        $ciphertext = $crypto.encrypt($plain, myKey);
        $hmac = hash_hmac("sha256", $ciphertext, myKey);

        return $hmac . $ciphertext;
    }

    /**
     * Check the encryption key for proper length.
     *
     * @param string myKey Key to check.
     * @param string $method The method the key is being checked for.
     * @return void
     * @throws \InvalidArgumentException When key length is not 256 bit/32 bytes
     */
    protected static void _checkKey(string myKey, string $method) {
        if (mb_strlen(myKey, "8bit") < 32) {
            throw new InvalidArgumentException(
                sprintf("Invalid key for %s, key must be at least 256 bits (32 bytes) long.", $method)
            );
        }
    }

    /**
     * Decrypt a value using AES-256.
     *
     * @param string $cipher The ciphertext to decrypt.
     * @param string myKey The 256 bit/32 byte key to use as a cipher key.
     * @param string|null $hmacSalt The salt to use for the HMAC process.
     *   Leave null to use value of Security::getSalt().
     * @return string|null Decrypted data. Any trailing null bytes will be removed.
     * @throws \InvalidArgumentException On invalid data or key.
     */
    static Nullable!string decrypt(string $cipher, string myKey, Nullable!string $hmacSalt = null) {
        self::_checkKey(myKey, "decrypt()");
        if (empty($cipher)) {
            throw new InvalidArgumentException("The data to decrypt cannot be empty.");
        }
        if ($hmacSalt == null) {
            $hmacSalt = static::getSalt();
        }

        // Generate the encryption and hmac key.
        myKey = mb_substr(hash("sha256", myKey . $hmacSalt), 0, 32, "8bit");

        // Split out hmac for comparison
        $macSize = 64;
        $hmac = mb_substr($cipher, 0, $macSize, "8bit");
        $cipher = mb_substr($cipher, $macSize, null, "8bit");

        $compareHmac = hash_hmac("sha256", $cipher, myKey);
        if (!static::constantEquals($hmac, $compareHmac)) {
            return null;
        }

        $crypto = static::engine();

        return $crypto.decrypt($cipher, myKey);
    }

    /**
     * A timing attack resistant comparison that prefers native PHP implementations.
     *
     * @param mixed $original The original value.
     * @param mixed $compare The comparison value.
     * @return bool
     * @since 3.6.2
     */
    static bool constantEquals($original, $compare) {
        return is_string($original) && is_string($compare) && hash_equals($original, $compare);
    }

    /**
     * Gets the HMAC salt to be used for encryption/decryption
     * routines.
     *
     * @return string The currently configured salt
     */
    static string getSalt() {
        if (static::$_salt == null) {
            throw new RuntimeException(
                "Salt not set. Use Security::setSalt() to set one, ideally in `config/bootstrap.php`."
            );
        }

        return static::$_salt;
    }

    /**
     * Sets the HMAC salt to be used for encryption/decryption routines.
     *
     * @param string $salt The salt to use for encryption routines.
     */
    static void setSalt(string $salt) {
        static::$_salt = $salt;
    }
}
