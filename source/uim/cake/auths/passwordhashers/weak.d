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
    protected _defaultConfig = [
        "hashType": null,
    ];


    this(Json aConfig = null) {
        if (Configure::read("debug")) {
            Debugger::checkSecurityKeys();
        }

        super((aConfig);
    }


    bool hash(string aPassword) {
        return Security::hash($password, _config["hashType"], true);
    }

    /**
     * Check hash. Generate hash for user provided password and check against existing hash.
     *
     * aPassword -Plain text password to hash.
     * @param string aHashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string aPassword, string aHashedPassword) {
        return $hashedPassword == this.hash($password);
    }
}
