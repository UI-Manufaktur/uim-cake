module uim.cake.uilities;

@safe:
import uim.cake;

/**
 * Cookie Crypt Trait.
 *
 * Provides the encrypt/decrypt logic for the CookieComponent.
 *
 * @link https://book.UIM.org/4/en/controllers/components/cookie.html
 */
trait CookieCryptTrait
{
    /**
     * Valid cipher names for encrypted cookies.
     *
     * @var array<string>
     */
    protected _validCiphers = ["aes"];

    /**
     * Returns the encryption key to be used.
     *
     * @return string
     */
    abstract protected string _getCookieEncryptionKey();

    /**
     * Encrypts myValue using public myType method in Security class
     *
     * @param array|string myValue Value to encrypt
     * @param string|false $encrypt Encryption mode to use. False
     *   disabled encryption.
     * @param string|null myKey Used as the security salt if specified.
     * @return string Encoded values
     */
    protected string _encrypt(myValue, $encrypt, Nullable!string myKey = null) {
        if (is_array(myValue)) {
            myValue = _implode(myValue);
        }
        if ($encrypt == false) {
            return myValue;
        }
        _checkCipher($encrypt);
        $prefix = "Q2FrZQ==.";
        $cipher = "";
        if (myKey is null) {
            myKey = _getCookieEncryptionKey();
        }
        if ($encrypt == "aes") {
            $cipher = Security::encrypt(myValue, myKey);
        }

        return $prefix . base64_encode($cipher);
    }

    /**
     * Helper method for validating encryption cipher names.
     *
     * @param string encrypt The cipher name.
     * @throws \RuntimeException When an invalid cipher is provided.
     */
    protected void _checkCipher(string encrypt) {
        if (!in_array($encrypt, _validCiphers, true)) {
            $msg = sprintf(
                "Invalid encryption cipher. Must be one of %s or false.",
                implode(", ", _validCiphers)
            );
            throw new RuntimeException($msg);
        }
    }

    /**
     * Decrypts myValue using public myType method in Security class
     *
     * @param array<string>|string myValues Values to decrypt
     * @param string|false myMode Encryption mode
     * @param string|null myKey Used as the security salt if specified.
     * @return array|string Decrypted values
     */
    protected auto _decrypt(myValues, myMode, Nullable!string myKey = null) {
        if (is_string(myValues)) {
            return _decode(myValues, myMode, myKey);
        }

        $decrypted = [];
        foreach (myValues as myName => myValue) {
            $decrypted[myName] = _decode(myValue, myMode, myKey);
        }

        return $decrypted;
    }

    /**
     * Decodes and decrypts a single value.
     *
     * @param string myValue The value to decode & decrypt.
     * @param string|false $encrypt The encryption cipher to use.
     * @param string|null myKey Used as the security salt if specified.
     * @return array|string Decoded values.
     */
    protected auto _decode(string myValue, $encrypt, Nullable!string myKey) {
        if (!$encrypt) {
            return _explode(myValue);
        }
        _checkCipher($encrypt);
        $prefix = "Q2FrZQ==.";
        $prefixLength = strlen($prefix);

        if (strncmp(myValue, $prefix, $prefixLength) != 0) {
            return "";
        }

        myValue = base64_decode(substr(myValue, $prefixLength), true);

        if (myValue == false || myValue == "") {
            return "";
        }

        if (myKey is null) {
            myKey = _getCookieEncryptionKey();
        }
        if ($encrypt == "aes") {
            myValue = Security::decrypt(myValue, myKey);
        }

        if (myValue is null) {
            return "";
        }

        return _explode(myValue);
    }

    /**
     * Implode method to keep keys are multidimensional arrays
     *
     * @param array $array Map of key and values
     * @return string A JSON encoded string.
     */
    protected string _implode(array $array) {
        return json_encode($array);
    }

    /**
     * Explode method to return array from string set in CookieComponent::_implode()
     * Maintains reading backwards compatibility with 1.x CookieComponent::_implode().
     *
     * @param string string A string containing JSON encoded data, or a bare string.
     * @return array|string Map of key and values
     */
    protected auto _explode(string string) {
        $first = substr($string, 0, 1);
        if ($first == "{" || $first == "[") {
            $ret = json_decode($string, true);

            return $ret ?? $string;
        }
        $array = [];
        foreach (explode(",", $string) as $pair) {
            myKey = explode("|", $pair);
            if (!isset(myKey[1])) {
                return myKey[0];
            }
            $array[myKey[0]] = myKey[1];
        }

        return $array;
    }
}
