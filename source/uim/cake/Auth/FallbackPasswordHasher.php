


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

/**
 * A password hasher that can use multiple different hashes where only
 * one is the preferred one. This is useful when trying to migrate an
 * existing database of users from one password type to another.
 */
class FallbackPasswordHasher : AbstractPasswordHasher
{
    /**
     * Default config for this object.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "hashers": [],
    ];

    /**
     * Holds the list of password hasher objects that will be used
     *
     * @var array<\Cake\Auth\AbstractPasswordHasher>
     */
    protected $_hashers = [];

    /**
     * Constructor
     *
     * @param array<string, mixed> $config configuration options for this object. Requires the
     * `hashers` key to be present in the array with a list of other hashers to be
     * used.
     */
    public this(array $config = []) {
        super(($config);
        foreach (_config["hashers"] as $key: $hasher) {
            if (is_array($hasher) && !isset($hasher["className"])) {
                $hasher["className"] = $key;
            }
            _hashers[] = PasswordHasherFactory::build($hasher);
        }
    }

    /**
     * Generates password hash.
     *
     * Uses the first password hasher in the list to generate the hash
     *
     * @param string $password Plain text password to hash.
     * @return string|false Password hash or false
     */
    function hash(string $password) {
        return _hashers[0].hash($password);
    }

    /**
     * Verifies that the provided password corresponds to its hashed version
     *
     * This will iterate over all configured hashers until one of them returns
     * true.
     *
     * @param string $password Plain text password to hash.
     * @param string $hashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string $password, string $hashedPassword) {
        foreach (_hashers as $hasher) {
            if ($hasher.check($password, $hashedPassword)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns true if the password need to be rehashed, with the first hasher present
     * in the list of hashers
     *
     * @param string $password The password to verify
     * @return bool
     */
    bool needsRehash(string $password) {
        return _hashers[0].needsRehash($password);
    }
}
