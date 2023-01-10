/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.auths.baseauthenticate;

@safe:
import uim.cake

// Base Authentication class with common methods and properties.
abstract class BaseAuthenticate : IEventListener {
    use InstanceConfigTrait;
    use LocatorAwareTrait;

    /**
     * Default config for this object.
     *
     * - `fields` The fields to use to identify a user by.
     * - `userModel` The alias for users table, defaults to Users.
     * - `finder` The finder method to use to fetch user record. Defaults to "all".
     *   You can set finder name as string or an array where key is finder name and value
     *   is an array passed to `Table::find()` options.
     *   E.g. ["finderName": ["some_finder_option": "some_value"]]
     * - `passwordHasher` Password hasher class. Can be a string specifying class name
     *    or an array containing `className` key, any other keys will be passed as
     *    config to the class. Defaults to "Default".
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "fields": [
            "username": "username",
            "password": "password",
        ],
        "userModel": "Users",
        "finder": "all",
        "passwordHasher": "Default",
    ];

    /**
     * A Component registry, used to get more components.
     *
     * @var uim.cake.controllers.ComponentRegistry
     */
    protected _registry;

    /**
     * Password hasher instance.
     *
     * @var uim.cake.auths.AbstractPasswordHasher|null
     */
    protected _passwordHasher;

    /**
     * Whether the user authenticated by this class
     * requires their password to be rehashed with another algorithm.
     */
    protected bool _needsPasswordRehash = false;

    /**
     * Constructor
     *
     * @param uim.cake.controllers.ComponentRegistry $registry The Component registry used on this request.
     * @param array<string, mixed> aConfig Array of config to use.
     */
    this(ComponentRegistry aRegistry, Json aConfig = null) {
        _registry = aRegistry;
        this.setConfig(aConfig);
    }

    void initialize() {
        // 
    }
    /**
     * Find a user record using the username and password provided.
     *
     * Input passwords will be hashed even when a user doesn"t exist. This
     * helps mitigate timing attacks that are attempting to find valid usernames.
     *
     * anUsername - The username/identifier.
     * aPassword  - The password, if not provided password checking is skipped
     *   and result of find is returned.
     * @return array<string, mixed>|false Either false on failure, or an array of user data.
     */
    protected array _findUser(string anUsername, Nullable!string aPassword = null) {
        $result = _query($username).first();

        if ($result == null) {
            // Waste time hashing the password, to prevent
            // timing side-channels. However, don"t hash
            // null passwords as authentication systems
            // like digest auth don"t use passwords
            // and hashing *could* create a timing side-channel.
            if ($password != null) {
                $hasher = this.passwordHasher();
                $hasher.hash($password);
            }

            return false;
        }

        $passwordField = _config["fields"]["password"];
        if ($password != null) {
            $hasher = this.passwordHasher();
            $hashedPassword = $result.get($passwordField);

            if ($hashedPassword == null || $hashedPassword == "") {
                // Waste time hashing the password, to prevent
                // timing side-channels to distinguish whether
                // user has password or not.
                $hasher.hash($password);

                return false;
            }

            if (!$hasher.check($password, $hashedPassword)) {
                return false;
            }

            _needsPasswordRehash = $hasher.needsRehash($hashedPassword);
            $result.unset($passwordField);
        }
        $hidden = $result.getHidden();
        if ($password == null && hasAllValues($passwordField, $hidden, true)) {
            $key = array_search($passwordField, $hidden, true);
            unset($hidden[$key]);
            $result.setHidden($hidden);
        }

        return $result.toArray();
    }

    /**
     * Get query object for fetching user from database.
     *
     * anUsername - The username/identifier.
     * @return uim.cake.orm.Query
     */
    protected Query _query(string anUsername) {
        aConfig = _config;
        $table = this.getTableLocator().get(aConfig["userModel"]);

        $options = [
            "conditions": [$table.aliasField(aConfig["fields"]["username"]): $username],
        ];

        $finder = aConfig["finder"];
        if (is_array($finder)) {
            $options += current($finder);
            $finder = key($finder);
        }

        $options["username"] = $options["username"] ?? $username;

        return $table.find($finder, $options);
    }

    /**
     * Return password hasher object
     *
     * @return uim.cake.Auth\AbstractPasswordHasher Password hasher instance
     * @throws \RuntimeException If password hasher class not found or
     *   it does not extend AbstractPasswordHasher
     */
    AbstractPasswordHasher passwordHasher() {
        if (_passwordHasher != null) {
            return _passwordHasher;
        }

        $passwordHasher = _config["passwordHasher"];

        return _passwordHasher = PasswordHasherFactory::build($passwordHasher);
    }

    /**
     * Returns whether the password stored in the repository for the logged in user
     * requires to be rehashed with another algorithm
     *
     * @return bool
     */
    bool needsPasswordRehash() {
        return _needsPasswordRehash;
    }

    /**
     * Authenticate a user based on the request information.
     *
     * @param uim.cake.http.ServerRequest myServerRequest Request to get authentication information from.
     * @param uim.cake.http.Response $response A response object that can have headers added.
     * @return array<string, mixed>|false Either false on failure, or an array of user data on success.
     */
    abstract function authenticate(ServerRequest myServerRequest, Response $response);

    /**
     * Get a user based on information in the request. Primarily used by stateless authentication
     * systems like basic and digest auth.
     *
     * @param uim.cake.http.ServerRequest myServerRequest Request object.
     * @return array<string, mixed>|false Either false or an array of user information
     */
    function getUser(ServerRequest myServerRequest) {
        return false;
    }

    /**
     * Handle unauthenticated access attempt. In implementation valid return values
     * can be:
     *
     * - Null - No action taken, AuthComponent should return appropriate response.
     * - uim.cake.Http\Response - A response object, which will cause AuthComponent to
     *   simply return that response.
     *
     * @param uim.cake.http.ServerRequest myServerRequest A request object.
     * @param uim.cake.http.Response $response A response object.
     * @return uim.cake.http.Response|null|void
     */
    function unauthenticated(ServerRequest myServerRequest, Response $response) {
    }

    /**
     * Returns a list of all events that this authenticate class will listen to.
     *
     * An authenticate class can listen to following events fired by AuthComponent:
     *
     * - `Auth.afterIdentify` - Fired after a user has been identified using one of
     *   configured authenticate class. The callback function should have signature
     *   like `afterIdentify(IEvent $event, array $user)` when `$user` is the
     *   identified user record.
     *
     * - `Auth.logout` - Fired when AuthComponent::logout() is called. The callback
     *   function should have signature like `logout(IEvent $event, array $user)`
     *   where `$user` is the user about to be logged out.
     *
     * @return array<string, mixed> List of events this class listens to. Defaults to `[]`.
     */
    array implementedEvents() {
        return [];
    }
}
