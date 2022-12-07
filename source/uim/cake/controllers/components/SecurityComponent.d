

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         0.10.8
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.controllerss.components;

import uim.cake.controllerss.components;
import uim.cake.controllers\Controller;
import uim.cake.controllers\Exception\AuthSecurityException;
import uim.cake.controllers\Exception\SecurityException;
import uim.cake.core.Configure;
import uim.cakeents\IEvent;
import uim.caketps\Exception\BadRequestException;
import uim.caketps\Response;
import uim.caketps\ServerRequest;
import uim.cakeutings\Router;
import uim.cakeilities.Hash;
import uim.cakeilities.Security;

/**
 * The Security Component creates an easy way to integrate tighter security in
 * your application. It provides methods for these tasks:
 *
 * - Form tampering protection.
 * - Requiring that SSL be used.
 *
 * @link https://book.UIM.org/4/en/controllers/components/security.html
 * @deprecated 4.0.0 Use {@link FormProtectionComponent} instead, for form tampering protection
 *   or {@link HttpsEnforcerMiddleware} to enforce use of HTTPS (SSL) for requests.
 */
class SecurityComponent : Component
{
    /**
     * Default message used for exceptions thrown
     *
     * @var string
     */
    public const DEFAULT_EXCEPTION_MESSAGE = "The request has been black-holed";

    /**
     * Default config
     *
     * - `blackHoleCallback` - The controller method that will be called if this
     *   request is black-hole"d.
     * - `requireSecure` - List of actions that require an SSL-secured connection.
     * - `unlockedFields` - Form fields to exclude from POST validation. Fields can
     *   be unlocked either in the Component, or with FormHelper::unlockField().
     *   Fields that have been unlocked are not required to be part of the POST
     *   and hidden unlocked fields do not have their values checked.
     * - `unlockedActions` - Actions to exclude from POST validation checks.
     *   Other checks like requireSecure() etc. will still be applied.
     * - `validatePost` - Whether to validate POST data. Set to false to disable
     *   for data coming from 3rd party services, etc.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "blackHoleCallback":null,
        "requireSecure":[],
        "unlockedFields":[],
        "unlockedActions":[],
        "validatePost":true,
    ];

    /**
     * Holds the current action of the controller
     *
     * @var string
     */
    protected $_action;

    /**
     * Component startup. All security checking happens here.
     *
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @return \Cake\Http\Response|null
     */
    function startup(IEvent myEvent): ?Response
    {
        /** @var \Cake\Controller\Controller $controller */
        $controller = myEvent.getSubject();
        myRequest = $controller.getRequest();
        this._action = myRequest.getParam("action");
        $hasData = (myRequest.getData() || myRequest.is(["put", "post", "delete", "patch"]));
        try {
            this._secureRequired($controller);

            if (this._action == this._config["blackHoleCallback"]) {
                throw new AuthSecurityException(sprintf(
                    "Action %s is defined as the blackhole callback.",
                    this._action
                ));
            }

            if (
                !in_array(this._action, (array)this._config["unlockedActions"], true) &&
                $hasData &&
                this._config["validatePost"]
            ) {
                this._validatePost($controller);
            }
        } catch (SecurityException $se) {
            return this.blackHole($controller, $se.getType(), $se);
        }

        myRequest = this.generateToken(myRequest);
        if ($hasData && is_array($controller.getRequest().getData())) {
            myRequest = myRequest.withoutData("_Token");
        }
        $controller.setRequest(myRequest);

        return null;
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [
            "Controller.startup":"startup",
        ];
    }

    /**
     * Sets the actions that require a request that is SSL-secured, or empty for all actions
     *
     * @param array<string>|string|null $actions Actions list
     */
    void requireSecure($actions = null) {
        $actions = (array)$actions;
        this.setConfig("requireSecure", empty($actions) ? ["*"] : $actions);
    }

    /**
     * Black-hole an invalid request with a 400 error or custom callback. If SecurityComponent::$blackHoleCallback
     * is specified, it will use this callback by executing the method indicated in myError
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @param string myError Error method
     * @param \Cake\Controller\Exception\SecurityException|null myException Additional debug info describing the cause
     * @return mixed If specified, controller blackHoleCallback"s response, or no return otherwise
     * @see \Cake\Controller\Component\SecurityComponent::$blackHoleCallback
     * @link https://book.UIM.org/4/en/controllers/components/security.html#handling-blackhole-callbacks
     * @throws \Cake\Http\Exception\BadRequestException
     */
    function blackHole(Controller $controller, string myError = "", ?SecurityException myException = null) {
        if (!this._config["blackHoleCallback"]) {
            this._throwException(myException);
        }

        return this._callback($controller, this._config["blackHoleCallback"], [myError, myException]);
    }

    /**
     * Check debug status and throw an Exception based on the existing one
     *
     * @param \Cake\Controller\Exception\SecurityException|null myException Additional debug info describing the cause
     * @throws \Cake\Http\Exception\BadRequestException
     */
    protected void _throwException(?SecurityException myException = null) {
        if (myException !== null) {
            if (!Configure::read("debug")) {
                myException.setReason(myException.getMessage());
                myException.setMessage(static::DEFAULT_EXCEPTION_MESSAGE);
            }
            throw myException;
        }
        throw new BadRequestException(static::DEFAULT_EXCEPTION_MESSAGE);
    }

    /**
     * Check if access requires secure connection
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @return void
     * @throws \Cake\Controller\Exception\SecurityException
     */
    protected void _secureRequired(Controller $controller) {
        if (
            empty(this._config["requireSecure"]) ||
            !is_array(this._config["requireSecure"])
        ) {
            return;
        }

        $requireSecure = this._config["requireSecure"];
        if (
            ($requireSecure[0] == "*" ||
                in_array(this._action, $requireSecure, true)
            ) &&
            !$controller.getRequest().is("ssl")
        ) {
            throw new SecurityException(
                "Request is not SSL and the action is required to be secure"
            );
        }
    }

    /**
     * Validate submitted form
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @return void
     * @throws \Cake\Controller\Exception\AuthSecurityException
     */
    protected void _validatePost(Controller $controller) {
        $token = this._validToken($controller);
        $hashParts = this._hashParts($controller);
        $check = hash_hmac("sha1", implode("", $hashParts), Security::getSalt());

        if (hash_equals($check, $token)) {
            return;
        }

        $msg = static::DEFAULT_EXCEPTION_MESSAGE;
        if (Configure::read("debug")) {
            $msg = this._debugPostTokenNotMatching($controller, $hashParts);
        }

        throw new AuthSecurityException($msg);
    }

    /**
     * Check if token is valid
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @throws \Cake\Controller\Exception\SecurityException
     * @return string fields token
     */
    protected string _validToken(Controller $controller) {
        $check = $controller.getRequest().getData();

        myMessage = "\"%s\" was not found in request data.";
        if (!isset($check["_Token"])) {
            throw new AuthSecurityException(sprintf(myMessage, "_Token"));
        }
        if (!isset($check["_Token"]["fields"])) {
            throw new AuthSecurityException(sprintf(myMessage, "_Token.fields"));
        }
        if (!is_string($check["_Token"]["fields"])) {
            throw new AuthSecurityException(""_Token.fields" is invalid.");
        }
        if (!isset($check["_Token"]["unlocked"])) {
            throw new AuthSecurityException(sprintf(myMessage, "_Token.unlocked"));
        }
        if (Configure::read("debug") && !isset($check["_Token"]["debug"])) {
            throw new SecurityException(sprintf(myMessage, "_Token.debug"));
        }
        if (!Configure::read("debug") && isset($check["_Token"]["debug"])) {
            throw new SecurityException("Unexpected \"_Token.debug\" found in request data");
        }

        $token = urldecode($check["_Token"]["fields"]);
        if (strpos($token, ":")) {
            [$token, ] = explode(":", $token, 2);
        }

        return $token;
    }

    /**
     * Return hash parts for the Token generation
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @return array<string>
     */
    protected auto _hashParts(Controller $controller): array
    {
        myRequest = $controller.getRequest();

        // Start the session to ensure we get the correct session id.
        $session = myRequest.getSession();
        $session.start();

        myData = (array)myRequest.getData();
        myFieldList = this._fieldsList(myData);
        $unlocked = this._sortedUnlocked(myData);

        return [
            Router::url(myRequest.getRequestTarget()),
            serialize(myFieldList),
            $unlocked,
            $session.id(),
        ];
    }

    /**
     * Return the fields list for the hash calculation
     *
     * @param array $check Data array
     * @return array
     */
    protected auto _fieldsList(array $check): array
    {
        $locked = "";
        $token = urldecode($check["_Token"]["fields"]);
        $unlocked = this._unlocked($check);

        if (strpos($token, ":")) {
            [, $locked] = explode(":", $token, 2);
        }
        unset($check["_Token"]);

        $locked = $locked ? explode("|", $locked) : [];
        $unlocked = $unlocked ? explode("|", $unlocked) : [];

        myFields = Hash::flatten($check);
        myFieldList = array_keys(myFields);
        $multi = $lockedFields = [];
        $isUnlocked = false;

        foreach (myFieldList as $i: myKey) {
            if (is_string(myKey) && preg_match("/(\.\d+){1,10}$/", myKey)) {
                $multi[$i] = preg_replace("/(\.\d+){1,10}$/", "", myKey);
                unset(myFieldList[$i]);
            } else {
                myFieldList[$i] = (string)myKey;
            }
        }
        if (!empty($multi)) {
            myFieldList += array_unique($multi);
        }

        $unlockedFields = array_unique(
            array_merge(
                (array)this._config["unlockedFields"],
                $unlocked
            )
        );

        foreach (myFieldList as $i: myKey) {
            $isLocked = in_array(myKey, $locked, true);

            if (!empty($unlockedFields)) {
                foreach ($unlockedFields as $off) {
                    $off = explode(".", $off);
                    myField = array_values(array_intersect(explode(".", myKey), $off));
                    $isUnlocked = (myField == $off);
                    if ($isUnlocked) {
                        break;
                    }
                }
            }

            if ($isUnlocked || $isLocked) {
                unset(myFieldList[$i]);
                if ($isLocked) {
                    $lockedFields[myKey] = myFields[myKey];
                }
            }
        }
        sort(myFieldList, SORT_STRING);
        ksort($lockedFields, SORT_STRING);
        myFieldList += $lockedFields;

        return myFieldList;
    }

    /**
     * Get the unlocked string
     *
     * @param array myData Data array
     * @return string
     */
    protected string _unlocked(array myData) {
        return urldecode(myData["_Token"]["unlocked"]);
    }

    /**
     * Get the sorted unlocked string
     *
     * @param array myData Data array
     * @return string
     */
    protected string _sortedUnlocked(array myData) {
        $unlocked = this._unlocked(myData);
        $unlocked = explode("|", $unlocked);
        sort($unlocked, SORT_STRING);

        return implode("|", $unlocked);
    }

    /**
     * Create a message for humans to understand why Security token is not matching
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @param array<string> $hashParts Elements used to generate the Token hash
     * @return string Message explaining why the tokens are not matching
     */
    protected string _debugPostTokenNotMatching(Controller $controller, array $hashParts) {
        myMessages = [];
        $expectedParts = json_decode(urldecode($controller.getRequest().getData("_Token.debug")), true);
        if (!is_array($expectedParts) || count($expectedParts) !== 3) {
            return "Invalid security debug token.";
        }
        $expectedUrl = Hash::get($expectedParts, 0);
        myUrl = Hash::get($hashParts, 0);
        if ($expectedUrl !== myUrl) {
            myMessages[] = sprintf("URL mismatch in POST data (expected \"%s\" but found \"%s\")", $expectedUrl, myUrl);
        }
        $expectedFields = Hash::get($expectedParts, 1);
        myDataFields = Hash::get($hashParts, 1);
        if (myDataFields) {
            myDataFields = unserialize(myDataFields);
        }
        myFieldsMessages = this._debugCheckFields(
            myDataFields,
            $expectedFields,
            "Unexpected field \"%s\" in POST data",
            "Tampered field \"%s\" in POST data (expected value \"%s\" but found \"%s\")",
            "Missing field \"%s\" in POST data"
        );
        $expectedUnlockedFields = Hash::get($expectedParts, 2);
        myDataUnlockedFields = Hash::get($hashParts, 2) ?: null;
        if (myDataUnlockedFields) {
            myDataUnlockedFields = explode("|", myDataUnlockedFields);
        }
        $unlockFieldsMessages = this._debugCheckFields(
            (array)myDataUnlockedFields,
            $expectedUnlockedFields,
            "Unexpected unlocked field \"%s\" in POST data",
            "",
            "Missing unlocked field: \"%s\""
        );

        myMessages = array_merge(myMessages, myFieldsMessages, $unlockFieldsMessages);

        return implode(", ", myMessages);
    }

    /**
     * Iterates data array to check against expected
     *
     * @param array myDataFields Fields array, containing the POST data fields
     * @param array $expectedFields Fields array, containing the expected fields we should have in POST
     * @param string $intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string $stringKeyMessage Message string if tampered found in
     *  data fields indexed by string (protected).
     * @param string $missingMessage Message string if missing field
     * @return array<string> Messages
     */
    protected auto _debugCheckFields(
        array myDataFields,
        array $expectedFields = [],
        string $intKeyMessage = "",
        string $stringKeyMessage = "",
        string $missingMessage = ""
    ): array {
        myMessages = this._matchExistingFields(myDataFields, $expectedFields, $intKeyMessage, $stringKeyMessage);
        $expectedFieldsMessage = this._debugExpectedFields($expectedFields, $missingMessage);
        if ($expectedFieldsMessage !== null) {
            myMessages[] = $expectedFieldsMessage;
        }

        return myMessages;
    }

    /**
     * Manually add form tampering prevention token information into the provided
     * request object.
     *
     * @param \Cake\Http\ServerRequest myRequest The request object to add into.
     * @return \Cake\Http\ServerRequest The modified request.
     */
    function generateToken(ServerRequest myRequest): ServerRequest
    {
        $token = [
            "unlockedFields":this._config["unlockedFields"],
        ];

        return myRequest.withAttribute("formTokenData", [
            "unlockedFields":$token["unlockedFields"],
        ]);
    }

    /**
     * Calls a controller callback method
     *
     * @param \Cake\Controller\Controller $controller Instantiating controller
     * @param string $method Method to execute
     * @param array myParams Parameters to send to method
     * @return mixed Controller callback method"s response
     * @throws \Cake\Http\Exception\BadRequestException When a the blackholeCallback is not callable.
     */
    protected auto _callback(Controller $controller, string $method, array myParams = []) {
        $callable = [$controller, $method];

        if (!is_callable($callable)) {
            throw new BadRequestException("The request has been black-holed");
        }

        return $callable(...myParams);
    }

    /**
     * Generate array of messages for the existing fields in POST data, matching dataFields in $expectedFields
     * will be unset
     *
     * @param array myDataFields Fields array, containing the POST data fields
     * @param array $expectedFields Fields array, containing the expected fields we should have in POST
     * @param string $intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string $stringKeyMessage Message string if tampered found in
     *   data fields indexed by string (protected)
     * @return array<string> Error messages
     */
    protected auto _matchExistingFields(
        array myDataFields,
        array &$expectedFields,
        string $intKeyMessage,
        string $stringKeyMessage
    ): array {
        myMessages = [];
        foreach (myDataFields as myKey: myValue) {
            if (is_int(myKey)) {
                $foundKey = array_search(myValue, $expectedFields, true);
                if ($foundKey == false) {
                    myMessages[] = sprintf($intKeyMessage, myValue);
                } else {
                    unset($expectedFields[$foundKey]);
                }
            } else {
                if (isset($expectedFields[myKey]) && myValue !== $expectedFields[myKey]) {
                    myMessages[] = sprintf($stringKeyMessage, myKey, $expectedFields[myKey], myValue);
                }
                unset($expectedFields[myKey]);
            }
        }

        return myMessages;
    }

    /**
     * Generate debug message for the expected fields
     *
     * @param array $expectedFields Expected fields
     * @param string $missingMessage Message template
     * @return string|null Error message about expected fields
     */
    protected string _debugExpectedFields(array $expectedFields = [], string $missingMessage = "") {
        if (count($expectedFields) == 0) {
            return null;
        }

        $expectedFieldNames = [];
        foreach ($expectedFields as myKey: $expectedField) {
            if (is_int(myKey)) {
                $expectedFieldNames[] = $expectedField;
            } else {
                $expectedFieldNames[] = myKey;
            }
        }

        return sprintf($missingMessage, implode(", ", $expectedFieldNames));
    }
}
