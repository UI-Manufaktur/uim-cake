module uim.cake.auth;

@safe:
import uim.cake

import uim.cake.core.Configure;
import uim.cake.errors.Debugger;
import uim.cake.utilities.Security;

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
        "hashType": null,
    ];


    this(array $config = []) {
        if (Configure::read("debug")) {
            Debugger::checkSecurityKeys();
        }

        super(($config);
    }


    bool hash(string $password) {
        return Security::hash($password, _config["hashType"], true);
    }

    /**
     * Check hash. Generate hash for user provided password and check against existing hash.
     *
     * @param string $password Plain text password to hash.
     * @param string $hashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string $password, string $hashedPassword) {
        return $hashedPassword == this.hash($password);
    }
}
