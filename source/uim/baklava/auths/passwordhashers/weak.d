module uim.baklava.Auth;

@safe:
import uim.baklava;

/* import uim.baklava.core.Configure;
import uim.baklava.errors\Debugger;
import uim.baklava.utikities.Security;
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


    this(array myConfig = []) {
        if (Configure::read('debug')) {
            Debugger::checkSecurityKeys();
        }

        super.this(myConfig);
    }


    function hash(string myPassword) {
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