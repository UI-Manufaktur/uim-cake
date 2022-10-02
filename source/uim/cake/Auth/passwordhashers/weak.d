module uim.cake.Auth;

@safe:
import uim.cake;

/* import uim.cake.core.Configure;
import uim.cake.Error\Debugger;
import uim.cake.Utility\Security;
 */
/**
 * Password hashing class that use weak hashing algorithms. This class is
 * intended only to be used with legacy databases where passwords have
 * not been migrated to a stronger algorithm yet.
 */
class WeakPasswordHasher : AbstractPasswordHasher
{
    /**
     * Default config for this object.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'hashType' => null,
    ];

    /**
     * @inheritDoc
     */
    this(array myConfig = []) {
        if (Configure::read('debug')) {
            Debugger::checkSecurityKeys();
        }

        super.this(myConfig);
    }

    /**
     * @inheritDoc
     */
    function hash(string myPassword)
    {
        return Security::hash(myPassword, this._config['hashType'], true);
    }

    /**
     * Check hash. Generate hash for user provided password and check against existing hash.
     *
     * @param string myPassword Plain text password to hash.
     * @param string myHashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string myPassword, string myHashedPassword) {
        return myHashedPassword === this.hash(myPassword);
    }
}
