/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.controllerss.components;

@safe:
import uim.cake;

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
class SecurityComponent : Component {
    /**
     * Default message used for exceptions thrown
     */
    public const string DEFAULT_EXCEPTION_MESSAGE = "The request has been black-holed";

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
     */
    protected string _action;

    /**
     * Component startup. All security checking happens here.
     *
     * @param uim.cake.Event\IEvent myEvent An Event instance
     * @return uim.cake.http.Response|null
     */
    function startup(IEvent myEvent): ?Response
    {
        /** @var uim.cake.controllers.Controller $controller */
        $controller = myEvent.getSubject();
        myRequest = $controller.getRequest();
        _action = myRequest.getParam("action");
        $hasData = (myRequest.getData() || myRequest.is(["put", "post", "delete", "patch"]));
        try {
            _secureRequired($controller);

            if (_action == _config["blackHoleCallback"]) {
                throw new AuthSecurityException(sprintf(
                    "Action %s is defined as the blackhole callback.",
                    _action
                ));
            }

            if (
                !in_array(_action, (array)_config["unlockedActions"], true) &&
                $hasData &&
                _config["validatePost"]
            ) {
                _validatePost($controller);
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
    array implementedEvents() {
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
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @param string myError Error method
     * @param uim.cake.Controller\Exception\SecurityException|null myException Additional debug info describing the cause
     * @return mixed If specified, controller blackHoleCallback"s response, or no return otherwise
     * @see uim.cake.controllers.Component\SecurityComponent::$blackHoleCallback
     * @link https://book.UIM.org/4/en/controllers/components/security.html#handling-blackhole-callbacks
     * @throws uim.cake.http.Exception\BadRequestException
     */
    function blackHole(Controller $controller, string myError = "", ?SecurityException myException = null) {
        if (!_config["blackHoleCallback"]) {
            _throwException(myException);
        }

        return _callback($controller, _config["blackHoleCallback"], [myError, myException]);
    }

    /**
     * Check debug status and throw an Exception based on the existing one
     *
     * @param uim.cake.Controller\Exception\SecurityException|null myException Additional debug info describing the cause
     * @throws uim.cake.http.Exception\BadRequestException
     */
    protected void _throwException(?SecurityException myException = null) {
        if (myException  !is null) {
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
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @throws uim.cake.Controller\Exception\SecurityException
     */
    protected void _secureRequired(Controller $controller) {
        if (
            empty(_config["requireSecure"]) ||
            !is_array(_config["requireSecure"])
        ) {
            return;
        }

        $requireSecure = _config["requireSecure"];
        if (
            ($requireSecure[0] == "*" ||
                in_array(_action, $requireSecure, true)
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
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @throws uim.cake.Controller\Exception\AuthSecurityException
     */
    protected void _validatePost(Controller $controller) {
        $token = _validToken($controller);
        $hashParts = _hashParts($controller);
        $check = hash_hmac("sha1", implode("", $hashParts), Security::getSalt());

        if (hash_equals($check, $token)) {
            return;
        }

        $msg = static::DEFAULT_EXCEPTION_MESSAGE;
        if (Configure::read("debug")) {
            $msg = _debugPostTokenNotMatching($controller, $hashParts);
        }

        throw new AuthSecurityException($msg);
    }

    /**
     * Check if token is valid
     *
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @throws uim.cake.Controller\Exception\SecurityException
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
        if (indexOf($token, ":")) {
            [$token, ] = explode(":", $token, 2);
        }

        return $token;
    }

    /**
     * Return hash parts for the Token generation
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     */
    protected string[] _hashParts(Controller $controller) {
        myRequest = $controller.getRequest();

        // Start the session to ensure we get the correct session id.
        $session = myRequest.getSession();
        $session.start();

        myData = (array)myRequest.getData();
        myFieldList = _fieldsList(myData);
        $unlocked = _sortedUnlocked(myData);

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
    protected array _fieldsList(array $check) {
        $locked = "";
        $token = urldecode($check["_Token"]["fields"]);
        $unlocked = _unlocked($check);

        if (indexOf($token, ":")) {
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
                (array)_config["unlockedFields"],
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
        $unlocked = _unlocked(myData);
        $unlocked = explode("|", $unlocked);
        sort($unlocked, SORT_STRING);

        return implode("|", $unlocked);
    }

    /**
     * Create a message for humans to understand why Security token is not matching
     *
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @param $hashParts Elements used to generate the Token hash
     * @return string Message explaining why the tokens are not matching
     */
    protected string _debugPostTokenNotMatching(Controller $controller, string[] $hashParts) {
        myMessages = [];
        $expectedParts = json_decode(urldecode($controller.getRequest().getData("_Token.debug")), true);
        if (!is_array($expectedParts) || count($expectedParts) != 3) {
            return "Invalid security debug token.";
        }
        $expectedUrl = Hash::get($expectedParts, 0);
        myUrl = Hash::get($hashParts, 0);
        if ($expectedUrl != myUrl) {
            myMessages[] = sprintf("URL mismatch in POST data (expected \"%s\" but found \"%s\")", $expectedUrl, myUrl);
        }
        $expectedFields = Hash::get($expectedParts, 1);
        myDataFields = Hash::get($hashParts, 1);
        if (myDataFields) {
            myDataFields = unserialize(myDataFields);
        }
        myFieldsMessages = _debugCheckFields(
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
        $unlockFieldsMessages = _debugCheckFields(
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
     * @param string intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string stringKeyMessage Message string if tampered found in
     *  data fields indexed by string (protected).
     * @param string missingMessage Message string if missing field
     * @return Messages
     */
    protected string[] _debugCheckFields(
        array myDataFields,
        array $expectedFields = [],
        string intKeyMessage = "",
        string stringKeyMessage = "",
        string missingMessage = ""
    ) {
        myMessages = _matchExistingFields(myDataFields, $expectedFields, $intKeyMessage, $stringKeyMessage);
        $expectedFieldsMessage = _debugExpectedFields($expectedFields, $missingMessage);
        if ($expectedFieldsMessage  !is null) {
            myMessages[] = $expectedFieldsMessage;
        }

        return myMessages;
    }

    /**
     * Manually add form tampering prevention token information into the provided
     * request object.
     *
     * @param uim.cake.http.ServerRequest myRequest The request object to add into.
     * @return uim.cake.http.ServerRequest The modified request.
     */
    ServerRequest generateToken(ServerRequest myRequest) {
        $token = [
            "unlockedFields":_config["unlockedFields"],
        ];

        return myRequest.withAttribute("formTokenData", [
            "unlockedFields":$token["unlockedFields"],
        ]);
    }

    /**
     * Calls a controller callback method
     *
     * @param uim.cake.Controller\Controller $controller Instantiating controller
     * @param string method Method to execute
     * @param array myParams Parameters to send to method
     * @return mixed Controller callback method"s response
     * @throws uim.cake.http.Exception\BadRequestException When a the blackholeCallback is not callable.
     */
    protected auto _callback(Controller $controller, string method, array myParams = []) {
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
     * @param string intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string stringKeyMessage Message string if tampered found in
     *   data fields indexed by string (protected)
     * @return Error messages
     */
    protected string[] _matchExistingFields(
        array myDataFields,
        array &$expectedFields,
        string intKeyMessage,
        string stringKeyMessage
    ) {
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
                if (isset($expectedFields[myKey]) && myValue != $expectedFields[myKey]) {
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
     * @param string missingMessage Message template
     * @return string|null Error message about expected fields
     */
    protected string _debugExpectedFields(array $expectedFields = [], string missingMessage = "") {
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
