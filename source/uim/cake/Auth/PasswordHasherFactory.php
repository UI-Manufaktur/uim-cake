


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Auth;

import uim.cake.cores.App;
use RuntimeException;

/**
 * Builds password hashing objects
 */
class PasswordHasherFactory
{
    /**
     * Returns password hasher object out of a hasher name or a configuration array
     *
     * @param array<string, mixed>|string $passwordHasher Name of the password hasher or an array with
     * at least the key `className` set to the name of the class to use
     * @return \Cake\Auth\AbstractPasswordHasher Password hasher instance
     * @throws \RuntimeException If password hasher class not found or
     *   it does not extend {@link \Cake\Auth\AbstractPasswordHasher}
     */
    public static function build($passwordHasher): AbstractPasswordHasher
    {
        $config = [];
        if (is_string($passwordHasher)) {
            $class = $passwordHasher;
        } else {
            $class = $passwordHasher["className"];
            $config = $passwordHasher;
            unset($config["className"]);
        }

        $className = App::className($class, "Auth", "PasswordHasher");
        if ($className == null) {
            throw new RuntimeException(sprintf("Password hasher class "%s" was not found.", $class));
        }

        $hasher = new $className($config);
        if (!($hasher instanceof AbstractPasswordHasher)) {
            throw new RuntimeException("Password hasher must extend AbstractPasswordHasher class.");
        }

        return $hasher;
    }
}
