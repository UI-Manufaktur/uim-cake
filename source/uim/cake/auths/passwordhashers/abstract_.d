/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.auths.passwordhashers.abstract_;

@safe:
import uim.cake

module uim.cake.auths.passwordhashers;

import uim.cake.core.InstanceConfigTrait;

// Abstract password hashing class
abstract class AbstractPasswordHasher {
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
     * @param array<string, mixed> $config Array of config.
     */
    this(array $config = []) {
        this.setConfig($config);
    }

    /**
     * Generates password hash.
     *
     * @param string $password Plain text password to hash.
     * @return string|false Either the password hash string or false
     */
    abstract function hash(string $password);

    /**
     * Check hash. Generate hash from user provided password string or data array
     * and check against existing hash.
     *
     * @param string $password Plain text password to hash.
     * @param string $hashedPassword Existing hashed password.
     * @return bool True if hashes match else false.
     */
    abstract bool check(string $password, string $hashedPassword);

    /**
     * Returns true if the password need to be rehashed, due to the password being
     * created with anything else than the passwords generated by this class.
     *
     * Returns true by default since the only implementation users should rely
     * on is the one provided by default in php 5.5+ or any compatible library
     *
     * @param string $password The password to verify
     */
    bool needsRehash(string $password) {
        return password_needs_rehash($password, PASSWORD_DEFAULT);
    }
}
