/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.auths.authenticates.authenticate;

@safe:
import uim.cake

// Base Authentication class with common methods and properties.
abstract class DAuthenticate : IEventListener {
    /**
     * Default config for this object.
     *
     * - `fields` The fields to use to identify a user by.
     * - `userModel` The alias for users table, defaults to Users.
     * - `finder` The finder method to use to fetch user record. Defaults to "all".
     *   You can set finder name as string or an array where key is finder name and value
     *   is an array passed to `Table::find()` options.
     *   E.g. ["finderName":["some_finder_option":"some_value"]]
     * - `passwordHasher` Password hasher class. Can be a string specifying class name
     *    or an array containing `className` key, any other keys will be passed as
     *    config to the class. Defaults to "Default".
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "fields":[
            "username":"username",
            "password":"password",
        ],
        "userModel":"Users",
        "finder":"all",
        "passwordHasher":"Default",
    ];

    /**
     * A Component registry, used to get more components.
     *
     * @var \Cake\Controller\ComponentRegistry
     */
    protected $_registry;

    /**
     * Password hasher instance.
     *
     * @var \Cake\Auth\AbstractPasswordHasher|null
     */
    protected $_passwordHasher;

    /**
     * Whether the user authenticated by this class
     * requires their password to be rehashed with another algorithm.
     *
     * @var bool
     */
    protected $_needsPasswordRehash = false;

    /**
     * Constructor
     *
     * @param \Cake\Controller\ComponentRegistry $registry The Component registry used on this request.
     * @param array<string, mixed> myConfig Array of config to use.
     */
    this(ComponentRegistry $registry, array myConfig = []) {
        this._registry = $registry;
        this.setConfig(myConfig);
    }

    /**
     * Find a user record using the username and password provided.
     *
     * Input passwords will be hashed even when a user doesn"t exist. This
     * helps mitigate timing attacks that are attempting to find valid usernames.
     *
     * @param string myUsername The username/identifier.
     * @param string|null myPassword The password, if not provided password checking is skipped
     *   and result of find is returned.
     * @return array<string, mixed>|false Either false on failure, or an array of user data.
     */
    protected auto _findUser(string myUsername, Nullable!string myPassword = null) {
        myResult = this._query(myUsername).first();

        if (myResult === null) {
            // Waste time hashing the password, to prevent
            // timing side-channels. However, don"t hash
            // null passwords as authentication systems
            // like digest auth don"t use passwords
            // and hashing *could* create a timing side-channel.
            if (myPassword !== null) {
                myHasher = this.passwordHasher();
                myHasher.hash(myPassword);
            }

            return false;
        }

        myPasswordField = this._config["fields"]["password"];
        if (myPassword !== null) {
            myHasher = this.passwordHasher();
            myHashedPassword = myResult.get(myPasswordField);

            if (myHashedPassword === null || myHashedPassword == "") {
                // Waste time hashing the password, to prevent
                // timing side-channels to distinguish whether
                // user has password or not.
                myHasher.hash(myPassword);

                return false;
            }

            if (!myHasher.check(myPassword, myHashedPassword)) {
                return false;
            }

            this._needsPasswordRehash = myHasher.needsRehash(myHashedPassword);
            myResult.unset(myPasswordField);
        }
        myHidden = myResult.getHidden();
        if (myPassword === null && in_array(myPasswordField, myHidden, true)) {
            myKey = array_search(myPasswordField, myHidden, true);
            unset(myHidden[myKey]);
            myResult.setHidden(myHidden);
        }

        return myResult.toArray();
    }

    /**
     * Get query object for fetching user from database.
     *
     * @param string myUsername The username/identifier.
     * @return \Cake\ORM\Query
     */
    protected auto _query(string myUsername): Query
    {
        myConfig = this._config;
        myTable = this.getTableLocator().get(myConfig["userModel"]);

        myOptions = [
            "conditions":[myTable.aliasField(myConfig["fields"]["username"]) => myUsername],
        ];

        myFinder = myConfig["finder"];
        if (is_array(myFinder)) {
            myOptions += current(myFinder);
            myFinder = key(myFinder);
        }

        myOptions["username"] = myOptions["username"] ?? myUsername;

        return myTable.find(myFinder, myOptions);
    }

    /**
     * Return password hasher object
     *
     * @return \Cake\Auth\AbstractPasswordHasher Password hasher instance
     * @throws \RuntimeException If password hasher class not found or
     *   it does not extend AbstractPasswordHasher
     */
    function passwordHasher(): AbstractPasswordHasher
    {
        if (this._passwordHasher !== null) {
            return this._passwordHasher;
        }

        myPasswordHasher = this._config["passwordHasher"];

        return this._passwordHasher = PasswordHasherFactory::build(myPasswordHasher);
    }

    /**
     * Returns whether the password stored in the repository for the logged in user
     * requires to be rehashed with another algorithm
     */
    bool needsPasswordRehash() {
        return this._needsPasswordRehash;
    }

    /**
     * Authenticate a user based on the request information.
     *
     * @param \Cake\Http\ServerRequest myRequest Request to get authentication information from.
     * @param \Cake\Http\Response $response A response object that can have headers added.
     * @return array<string, mixed>|false Either false on failure, or an array of user data on success.
     */
    abstract function authenticate(ServerRequest myRequest, Response $response);

    /**
     * Get a user based on information in the request. Primarily used by stateless authentication
     * systems like basic and digest auth.
     *
     * @param \Cake\Http\ServerRequest myRequest Request object.
     * @return array<string, mixed>|false Either false or an array of user information
     */
    auto getUser(ServerRequest myRequest) {
        return false;
    }

    /**
     * Handle unauthenticated access attempt. In implementation valid return values
     * can be:
     *
     * - Null - No action taken, AuthComponent should return appropriate response.
     * - \Cake\Http\Response - A response object, which will cause AuthComponent to
     *   simply return that response.
     *
     * @param \Cake\Http\ServerRequest myRequest A request object.
     * @param \Cake\Http\Response $response A response object.
     * @return \Cake\Http\Response|null|void
     */
    function unauthenticated(ServerRequest myRequest, Response $response) {
    }

    /**
     * Returns a list of all events that this authenticate class will listen to.
     *
     * An authenticate class can listen to following events fired by AuthComponent:
     *
     * - `Auth.afterIdentify` - Fired after a user has been identified using one of
     *   configured authenticate class. The callback function should have signature
     *   like `afterIdentify(IEvent myEvent, array myUser)` when `myUser` is the
     *   identified user record.
     *
     * - `Auth.logout` - Fired when AuthComponent::logout() is called. The callback
     *   function should have signature like `logout(IEvent myEvent, array myUser)`
     *   where `myUser` is the user about to be logged out.
     *
     * @return array<string, mixed> List of events this class listens to. Defaults to `[]`.
     */
    function implementedEvents(): array
    {
        return [];
    }
}
