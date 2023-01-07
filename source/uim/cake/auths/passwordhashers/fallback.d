module uim.cake.auth;

@safe:
import uim.cake

/**
 * A password hasher that can use multiple different hashes where only
 * one is the preferred one. This is useful when trying to migrate an
 * existing database of users from one password type to another.
 */
class FallbackPasswordHasher : AbstractPasswordHasher {
    /**
     * Default config for this object.
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "hashers": [],
    ];

    /**
     * Holds the list of password hasher objects that will be used
     *
     * @var array<uim.cake.Auth\AbstractPasswordHasher>
     */
    protected _hashers = [];

    /**
     * Constructor
     *
     * @param array<string, mixed> aConfig configuration options for this object. Requires the
     * `hashers` key to be present in the array with a list of other hashers to be
     * used.
     */
    this(Json aConfig = []) {
        super((aConfig);
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
     * aPassword -Plain text password to hash.
     * @return string|false Password hash or false
     */
    bool hash(string aPassword) {
        return _hashers[0].hash($password);
    }

    /**
     * Verifies that the provided password corresponds to its hashed version
     *
     * This will iterate over all configured hashers until one of them returns
     * true.
     *
     * aPassword -Plain text password to hash.
     * @param string aHashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string aPassword, string aHashedPassword) {
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
     * aPassword -The password to verify
     * @return bool
     */
    bool needsRehash(string aPassword) {
        return _hashers[0].needsRehash($password);
    }
}
