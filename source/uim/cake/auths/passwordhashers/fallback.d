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
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "hashers":[],
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
     * @param array<string, mixed> myConfig configuration options for this object. Requires the
     * `hashers` key to be present in the array with a list of other hashers to be
     * used.
     */
    this(array myConfig = []) {
        super.this(myConfig);
        foreach (_config["hashers"] as myKey: myHasher) {
            if (is_array(myHasher) && !isset(myHasher["className"])) {
                myHasher["className"] = myKey;
            }
            _hashers[] = PasswordHasherFactory::build(myHasher);
        }
    }

    /**
     * Generates password hash.
     *
     * Uses the first password hasher in the list to generate the hash
     *
     * @param string myPassword Plain text password to hash.
     * @return string|false Password hash or false
     */
    function hash(string myPassword) {
        return _hashers[0].hash(myPassword);
    }

    /**
     * Verifies that the provided password corresponds to its hashed version
     *
     * This will iterate over all configured hashers until one of them returns
     * true.
     *
     * @param string myPassword Plain text password to hash.
     * @param string myHashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string myPassword, string myHashedPassword) {
        foreach (_hashers as myHasher) {
            if (myHasher.check(myPassword, myHashedPassword)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns true if the password need to be rehashed, with the first hasher present
     * in the list of hashers
     *
     * @param string myPassword The password to verify
     */
    bool needsRehash(string myPassword) {
        return _hashers[0].needsRehash(myPassword);
    }
}
