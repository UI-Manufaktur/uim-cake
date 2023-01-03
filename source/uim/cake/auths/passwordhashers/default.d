module uim.cake.auth;

@safe:
import uim.cake

/**
 * Default password hashing class.
 */
class DefaultPasswordHasher : AbstractPasswordHasher
{
    /**
     * Default config for this object.
     *
     * ### Options
     *
     * - `hashType` - Hashing algo to use. Valid values are those supported by `$algo`
     *   argument of `password_hash()`. Defaults to `PASSWORD_DEFAULT`
     * - `hashOptions` - Associative array of options. Check the PHP manual for
     *   supported options for each hash type. Defaults to empty array.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "hashType": PASSWORD_DEFAULT,
        "hashOptions": [],
    ];

    /**
     * Generates password hash.
     *
     * @param string $password Plain text password to hash.
     * @return string|false Password hash or false on failure
     * @psalm-suppress InvalidNullableReturnType
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#hashing-passwords
     */
    bool hash(string $password) {
        /** @psalm-suppress NullableReturnStatement */
        return password_hash(
            $password,
            _config["hashType"],
            _config["hashOptions"]
        );
    }

    /**
     * Check hash. Generate hash for user provided password and check against existing hash.
     *
     * @param string $password Plain text password to hash.
     * @param string $hashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    bool check(string $password, string $hashedPassword) {
        return password_verify($password, $hashedPassword);
    }

    /**
     * Returns true if the password need to be rehashed, due to the password being
     * created with anything else than the passwords generated by this class.
     *
     * @param string $password The password to verify
     */
    bool needsRehash(string $password) {
        return password_needs_rehash($password, _config["hashType"], _config["hashOptions"]);
    }
}
