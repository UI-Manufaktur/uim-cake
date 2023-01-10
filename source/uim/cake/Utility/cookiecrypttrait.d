


 *


 * @since         3.1.6
  */module uim.cake.Utility;

use RuntimeException;

/**
 * Cookie Crypt Trait.
 *
 * Provides the encrypt/decrypt logic for the CookieComponent.
 *
 * @link https://book.cakephp.org/4/en/controllers/components/cookie.html
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
     * Encrypts $value using $type method in Security class
     *
     * @param array|string aValue Value to encrypt
     * @param string|false $encrypt Encryption mode to use. False
     *   disabled encryption.
     * @param string|null $key Used as the security salt if specified.
     * @return string Encoded values
     */
    protected string _encrypt($value, $encrypt, Nullable!string aKey = null) {
        if (is_array($value)) {
            $value = _implode($value);
        }
        if ($encrypt == false) {
            return $value;
        }
        _checkCipher($encrypt);
        $prefix = "Q2FrZQ==.";
        $cipher = "";
        if ($key == null) {
            $key = _getCookieEncryptionKey();
        }
        if ($encrypt == "aes") {
            $cipher = Security::encrypt($value, $key);
        }

        return $prefix . base64_encode($cipher);
    }

    /**
     * Helper method for validating encryption cipher names.
     *
     * @param string $encrypt The cipher name.
     * @return void
     * @throws \RuntimeException When an invalid cipher is provided.
     */
    protected void _checkCipher(string $encrypt) {
        if (!hasAllValues($encrypt, _validCiphers, true)) {
            $msg = sprintf(
                "Invalid encryption cipher. Must be one of %s or false.",
                implode(", ", _validCiphers)
            );
            throw new RuntimeException($msg);
        }
    }

    /**
     * Decrypts $value using $type method in Security class
     *
     * @param array<string>|string aValues Values to decrypt
     * @param string|false $mode Encryption mode
     * @param string|null $key Used as the security salt if specified.
     * @return array|string Decrypted values
     */
    protected function _decrypt($values, $mode, Nullable!string aKey = null) {
        if (is_string($values)) {
            return _decode($values, $mode, $key);
        }

        $decrypted = null;
        foreach ($values as $name: $value) {
            $decrypted[$name] = _decode($value, $mode, $key);
        }

        return $decrypted;
    }

    /**
     * Decodes and decrypts a single value.
     *
     * @param string aValue The value to decode & decrypt.
     * @param string|false $encrypt The encryption cipher to use.
     * @param string|null $key Used as the security salt if specified.
     * @return array|string Decoded values.
     */
    protected function _decode(string aValue, $encrypt, Nullable!string aKey) {
        if (!$encrypt) {
            return _explode($value);
        }
        _checkCipher($encrypt);
        $prefix = "Q2FrZQ==.";
        $prefixLength = strlen($prefix);

        if (strncmp($value, $prefix, $prefixLength) != 0) {
            return "";
        }

        $value = base64_decode(substr($value, $prefixLength), true);

        if ($value == false || $value == "") {
            return "";
        }

        if ($key == null) {
            $key = _getCookieEncryptionKey();
        }
        if ($encrypt == "aes") {
            $value = Security::decrypt($value, $key);
        }

        if ($value == null) {
            return "";
        }

        return _explode($value);
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
     * @param string $string A string containing JSON encoded data, or a bare string.
     * @return array|string Map of key and values
     */
    protected function _explode(string $string) {
        $first = substr($string, 0, 1);
        if ($first == "{" || $first == "[") {
            $ret = json_decode($string, true);

            return $ret ?? $string;
        }
        $array = null;
        foreach (explode(",", $string) as $pair) {
            $key = explode("|", $pair);
            if (!isset(string aKey[1])) {
                return $key[0];
            }
            $array[$key[0]] = $key[1];
        }

        return $array;
    }
}
