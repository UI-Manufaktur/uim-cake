module uim.cake.Auth;

@safe:
import uim.cake;

/* import uim.cake.core.InstanceConfigTrait;
 */
/**
 * Abstract password hashing class
 */
abstract class AbstractPasswordHasher
{
    use InstanceConfigTrait;

    /**
     * Default config
     *
     * These are merged with user-provided config when the object is used.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Array of config.
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }

    /**
     * Generates password hash.
     *
     * @param string myPassword Plain text password to hash.
     * @return string|false Either the password hash string or false
     */
    abstract function hash(string myPassword);

    /**
     * Check hash. Generate hash from user provided password string or data array
     * and check against existing hash.
     *
     * @param string myPassword Plain text password to hash.
     * @param string myHashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    abstract function check(string myPassword, string myHashedPassword): bool;

    /**
     * Returns true if the password need to be rehashed, due to the password being
     * created with anything else than the passwords generated by this class.
     *
     * Returns true by default since the only implementation users should rely
     * on is the one provided by default in php 5.5+ or any compatible library
     *
     * @param string myPassword The password to verify
     * @return bool
     */
    bool needsRehash(string myPassword) {
        return password_needs_rehash(myPassword, PASSWORD_DEFAULT);
    }
}
