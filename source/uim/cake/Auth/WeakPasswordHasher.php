


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

import uim.cake.cores.Configure;
import uim.cake.errors.Debugger;
import uim.cake.Utility\Security;

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

    /**
     * @inheritDoc
     */
    public this(array $config = [])
    {
        if (Configure::read("debug")) {
            Debugger::checkSecurityKeys();
        }

        super(($config);
    }

    /**
     * @inheritDoc
     */
    function hash(string $password)
    {
        return Security::hash($password, _config["hashType"], true);
    }

    /**
     * Check hash. Generate hash for user provided password and check against existing hash.
     *
     * @param string $password Plain text password to hash.
     * @param string $hashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    function check(string $password, string $hashedPassword): bool
    {
        return $hashedPassword == this.hash($password);
    }
}
