module uim.cake.Form;

import uim.cake.core.Configure;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;

/**
 * Protects against form tampering. It ensures that:
 *
 * - Form"s action (URL) is not modified.
 * - Unknown / extra fields are not added to the form.
 * - Existing fields have not been removed from the form.
 * - Values of hidden inputs have not been changed.
 *
 * @internal
 */
class FormProtector
{
    /**
     * Fields list.
     *
     * @var array
     */
    protected myFields = [];

    /**
     * Unlocked fields.
     *
     * @var array<string>
     */
    protected $unlockedFields = [];

    /**
     * Error message providing detail for failed validation.
     *
     * @var string|null
     */
    protected $debugMessage;

    /**
     * Validate submitted form data.
     *
     * @param mixed $formData Form data.
     * @param string anURL URL form was POSTed to.
     * @param string $sessionId Session id for hash generation.
     * @return bool
     */
    bool validate($formData, string anURL, string $sessionId) {
        this.debugMessage = null;

        $extractedToken = this.extractToken($formData);
        if (empty($extractedToken)) {
            return false;
        }

        $hashParts = this.extractHashParts($formData);
        $generatedToken = this.generateHash(
            $hashParts["fields"],
            $hashParts["unlockedFields"],
            anURL,
            $sessionId
        );

        if (hash_equals($generatedToken, $extractedToken)) {
            return true;
        }

        if (Configure::read("debug")) {
            $debugMessage = this.debugTokenNotMatching($formData, $hashParts + compact("url", "sessionId"));
            if ($debugMessage) {
                this.debugMessage = $debugMessage;
            }
        }

        return false;
    }

    /**
     * Construct.
     *
     * @param array<string, mixed> myData Data array, can contain key `unlockedFields` with list of unlocked fields.
     */
    this(array myData = []) {
        if (!empty(myData["unlockedFields"])) {
            this.unlockedFields = myData["unlockedFields"];
        }
    }

    /**
     * Determine which fields of a form should be used for hash.
     *
     * @param array<string>|string myField Reference to field to be secured. Can be dot
     *   separated string to indicate nesting or array of fieldname parts.
     * @param bool $lock Whether this field should be part of the validation
     *   or excluded as part of the unlockedFields. Default `true`.
     * @param mixed myValue Field value, if value should not be tampered with.
     * @return this
     */
    function addField(myField, bool $lock = true, myValue = null) {
        if (is_string(myField)) {
            myField = this.getFieldNameArray(myField);
        }

        if (empty(myField)) {
            return this;
        }

        foreach (this.unlockedFields as $unlockField) {
            $unlockParts = explode(".", $unlockField);
            if (array_values(array_intersect(myField, $unlockParts)) == $unlockParts) {
                return this;
            }
        }

        myField = implode(".", myField);
        myField = preg_replace("/(\.\d+)+$/", "", myField);

        if ($lock) {
            if (!in_array(myField, this.fields, true)) {
                if (myValue !== null) {
                    this.fields[myField] = myValue;

                    return this;
                }
                if (isset(this.fields[myField])) {
                    unset(this.fields[myField]);
                }
                this.fields[] = myField;
            }
        } else {
            this.unlockField(myField);
        }

        return this;
    }

    /**
     * Parses the field name to create a dot separated name value for use in
     * field hash. If fieldname is of form Model[field] or Model.field an array of
     * fieldname parts like ["Model", "field"] is returned.
     *
     * @param string myName The form inputs name attribute.
     * @return Array of field name params like ["Model.field"] or
     *   ["Model", "field"] for array fields or empty array if myName is empty.
     */
    protected string[] getFieldNameArray(string myName) {
        if (empty(myName) && myName !== "0") {
            return [];
        }

        if (indexOf(myName, "[") == false) {
            return Hash::filter(explode(".", myName));
        }
        $parts = explode("[", myName);
        $parts = array_map(function ($el) {
            return trim($el, "]");
        }, $parts);

        return Hash::filter($parts, "strlen");
    }

    /**
     * Add to the list of fields that are currently unlocked.
     *
     * Unlocked fields are not included in the field hash.
     *
     * @param string myName The dot separated name for the field.
     * @return this
     */
    function unlockField(myName) {
        if (!in_array(myName, this.unlockedFields, true)) {
            this.unlockedFields[] = myName;
        }

        $index = array_search(myName, this.fields, true);
        if ($index !== false) {
            unset(this.fields[$index]);
        }
        unset(this.fields[myName]);

        return this;
    }

    /**
     * Get validation error message.
     *
     * @return string|null
     */
    string getError() {
        return this.debugMessage;
    }

    /**
     * Extract token from data.
     *
     * @param mixed $formData Data to validate.
     * @return string|null Fields token on success, null on failure.
     */
    protected string extractToken($formData) {
        if (!is_array($formData)) {
            this.debugMessage = "Request data is not an array.";

            return null;
        }

        myMessage = "`%s` was not found in request data.";
        if (!isset($formData["_Token"])) {
            this.debugMessage = sprintf(myMessage, "_Token");

            return null;
        }
        if (!isset($formData["_Token"]["fields"])) {
            this.debugMessage = sprintf(myMessage, "_Token.fields");

            return null;
        }
        if (!is_string($formData["_Token"]["fields"])) {
            this.debugMessage = "`_Token.fields` is invalid.";

            return null;
        }
        if (!isset($formData["_Token"]["unlocked"])) {
            this.debugMessage = sprintf(myMessage, "_Token.unlocked");

            return null;
        }
        if (Configure::read("debug") && !isset($formData["_Token"]["debug"])) {
            this.debugMessage = sprintf(myMessage, "_Token.debug");

            return null;
        }
        if (!Configure::read("debug") && isset($formData["_Token"]["debug"])) {
            this.debugMessage = "Unexpected `_Token.debug` found in request data";

            return null;
        }

        $token = urldecode($formData["_Token"]["fields"]);
        if (indexOf($token, ":")) {
            [$token, ] = explode(":", $token, 2);
        }

        return $token;
    }

    /**
     * Return hash parts for the token generation
     *
     * @param array $formData Form data.
     * @return array
     * @psalm-return array{fields: array, unlockedFields: array}
     */
    protected array extractHashParts(array $formData) {
        myFields = this.extractFields($formData);
        $unlockedFields = this.sortedUnlockedFields($formData);

        return [
            "fields":myFields,
            "unlockedFields":$unlockedFields,
        ];
    }

    /**
     * Return the fields list for the hash calculation
     *
     * @param array $formData Data array
     * @return array
     */
    protected array extractFields(array $formData) {
        $locked = "";
        $token = urldecode($formData["_Token"]["fields"]);
        $unlocked = urldecode($formData["_Token"]["unlocked"]);

        if (indexOf($token, ":")) {
            [, $locked] = explode(":", $token, 2);
        }
        unset($formData["_Token"]);

        $locked = $locked ? explode("|", $locked) : [];
        $unlocked = $unlocked ? explode("|", $unlocked) : [];

        myFields = Hash::flatten($formData);
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
                this.unlockedFields,
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
     * Get the sorted unlocked string
     * @param array $formData Data array
     */
    protected string[] sortedUnlockedFields(array $formData) {
        $unlocked = urldecode($formData["_Token"]["unlocked"]);
        if (empty($unlocked)) {
            return [];
        }

        $unlocked = explode("|", $unlocked);
        sort($unlocked, SORT_STRING);

        return $unlocked;
    }

    /**
     * Generate the token data.
     *
     * @param string anURL Form URL.
     * @param string $sessionId Session Id.
     * @return The token data.
     * @psalm-return array{fields: string, unlocked: string, debug: string}
     */
    STRINGAA buildTokenData(string anURL = "", string $sessionId = "") {
        myFields = this.fields;
        $unlockedFields = this.unlockedFields;

        $locked = [];
        foreach (myFields as myKey: myValue) {
            if (is_numeric(myValue)) {
                myValue = (string)myValue;
            }
            if (!is_int(myKey)) {
                $locked[myKey] = myValue;
                unset(myFields[myKey]);
            }
        }

        sort($unlockedFields, SORT_STRING);
        sort(myFields, SORT_STRING);
        ksort($locked, SORT_STRING);
        myFields += $locked;

        myFields = this.generateHash(myFields, $unlockedFields, anURL, $sessionId);
        $locked = implode("|", array_keys($locked));

        return [
            "fields":urlencode(myFields . ":" . $locked),
            "unlocked":urlencode(implode("|", $unlockedFields)),
            "debug":urlencode(json_encode([
                anURL,
                this.fields,
                this.unlockedFields,
            ])),
        ];
    }

    /**
     * Generate validation hash.
     *
     * @param array myFields Fields list.
     * @param array $unlockedFields Unlocked fields.
     * @param string anURL Form URL.
     * @param string $sessionId Session Id.
     * @return string
     */
    protected auto generateHash(array myFields, array $unlockedFields, string anURL, string $sessionId) {
        $hashParts = [
            anURL,
            serialize(myFields),
            implode("|", $unlockedFields),
            $sessionId,
        ];

        return hash_hmac("sha1", implode("", $hashParts), Security::getSalt());
    }

    /**
     * Create a message for humans to understand why Security token is not matching
     *
     * @param array $formData Data.
     * @param array $hashParts Elements used to generate the Token hash
     * @return string Message explaining why the tokens are not matching
     */
    protected string debugTokenNotMatching(array $formData, array $hashParts) {
        myMessages = [];
        if (!isset($formData["_Token"]["debug"])) {
            return "Form protection debug token not found.";
        }

        $expectedParts = json_decode(urldecode($formData["_Token"]["debug"]), true);
        if (!is_array($expectedParts) || count($expectedParts) !== 3) {
            return "Invalid form protection debug token.";
        }
        $expectedUrl = Hash::get($expectedParts, 0);
        anURL = Hash::get($hashParts, "url");
        if ($expectedUrl !== anURL) {
            myMessages[] = sprintf("URL mismatch in POST data (expected `%s` but found `%s`)", $expectedUrl, anURL);
        }
        $expectedFields = Hash::get($expectedParts, 1);
        myDataFields = Hash::get($hashParts, "fields") ?: [];
        myFieldsMessages = this.debugCheckFields(
            (array)myDataFields,
            $expectedFields,
            "Unexpected field `%s` in POST data",
            "Tampered field `%s` in POST data (expected value `%s` but found `%s`)",
            "Missing field `%s` in POST data"
        );
        $expectedUnlockedFields = Hash::get($expectedParts, 2);
        myDataUnlockedFields = Hash::get($hashParts, "unlockedFields") ?: [];
        $unlockFieldsMessages = this.debugCheckFields(
            (array)myDataUnlockedFields,
            $expectedUnlockedFields,
            "Unexpected unlocked field `%s` in POST data",
            "",
            "Missing unlocked field: `%s`"
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
     * return data fields indexed by string (protected).
     * @param string $missingMessage Message string if missing field
     * @return Messages
     */
    protected string[] debugCheckFields(
        array myDataFields,
        array $expectedFields = [],
        string $intKeyMessage = "",
        string $stringKeyMessage = "",
        string $missingMessage = ""
    ) {
        myMessages = this.matchExistingFields(myDataFields, $expectedFields, $intKeyMessage, $stringKeyMessage);
        $expectedFieldsMessage = this.debugExpectedFields($expectedFields, $missingMessage);
        if ($expectedFieldsMessage !== null) {
            myMessages[] = $expectedFieldsMessage;
        }

        return myMessages;
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
     * @return Error messages
     */
    protected string[] matchExistingFields(
        array myDataFields,
        array &$expectedFields,
        string $intKeyMessage,
        string $stringKeyMessage
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
    protected string debugExpectedFields(array $expectedFields = [], string $missingMessage = "") {
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

    /**
     * Return debug info
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        return [
            "fields":this.fields,
            "unlockedFields":this.unlockedFields,
            "debugMessage":this.debugMessage,
        ];
    }
}
