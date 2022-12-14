/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Form;

@safe:
import uim.cake;


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
    protected $fields = null;

    /**
     * Unlocked fields.
     *
     * @var array<string>
     */
    protected $unlockedFields = null;

    /**
     * Error message providing detail for failed validation.
     *
     */
    protected Nullable!string debugMessage;

    /**
     * Validate submitted form data.
     *
     * @param mixed $formData Form data.
     * @param string $url URL form was POSTed to.
     * @param string $sessionId Session id for hash generation.
     */
    bool validate($formData, string $url, string $sessionId) {
        this.debugMessage = null;

        $extractedToken = this.extractToken($formData);
        if (empty($extractedToken)) {
            return false;
        }

        $hashParts = this.extractHashParts($formData);
        $generatedToken = this.generateHash(
            $hashParts["fields"],
            $hashParts["unlockedFields"],
            $url,
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
     * @param array<string, mixed> $data Data array, can contain key `unlockedFields` with list of unlocked fields.
     */
    this(array $data = null) {
        if (!empty($data["unlockedFields"])) {
            this.unlockedFields = $data["unlockedFields"];
        }
    }

    /**
     * Determine which fields of a form should be used for hash.
     *
     * @param array<string>|string $field Reference to field to be secured. Can be dot
     *   separated string to indicate nesting or array of fieldname parts.
     * @param bool $lock Whether this field should be part of the validation
     *   or excluded as part of the unlockedFields. Default `true`.
     * @param mixed $value Field value, if value should not be tampered with.
     * @return this
     */
    function addField($field, bool $lock = true, $value = null) {
        if (is_string($field)) {
            $field = this.getFieldNameArray($field);
        }

        if (empty($field)) {
            return this;
        }

        foreach (this.unlockedFields as $unlockField) {
            $unlockParts = explode(".", $unlockField);
            if (array_values(array_intersect($field, $unlockParts)) == $unlockParts) {
                return this;
            }
        }

        $field = implode(".", $field);
        $field = preg_replace("/(\.\d+)+$/", "", $field);

        if ($lock) {
            if (!hasAllValues($field, this.fields, true)) {
                if ($value != null) {
                    this.fields[$field] = $value;

                    return this;
                }
                if (isset(this.fields[$field])) {
                    unset(this.fields[$field]);
                }
                this.fields[] = $field;
            }
        } else {
            this.unlockField($field);
        }

        return this;
    }

    /**
     * Parses the field name to create a dot separated name value for use in
     * field hash. If fieldname is of form Model[field] or Model.field an array of
     * fieldname parts like ["Model", "field"] is returned.
     *
     * @param string aName The form inputs name attribute.
     * @return array<string> Array of field name params like ["Model.field"] or
     *   ["Model", "field"] for array fields or empty array if $name is empty.
     */
    protected array getFieldNameArray(string aName) {
        if (empty($name) && $name != "0") {
            return [];
        }

        if (strpos($name, "[") == false) {
            return Hash::filter(explode(".", $name));
        }
        $parts = explode("[", $name);
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
     * @param string aName The dot separated name for the field.
     * @return this
     */
    function unlockField($name) {
        if (!hasAllValues($name, this.unlockedFields, true)) {
            this.unlockedFields[] = $name;
        }

        $index = array_search($name, this.fields, true);
        if ($index != false) {
            unset(this.fields[$index]);
        }
        unset(this.fields[$name]);

        return this;
    }

    /**
     * Get validation error message.
     *
     */
    Nullable!string getError() {
        return this.debugMessage;
    }

    /**
     * Extract token from data.
     *
     * @param mixed $formData Data to validate.
     * @return string|null Fields token on success, null on failure.
     */
    protected Nullable!string extractToken($formData) {
        if (!is_array($formData)) {
            this.debugMessage = "Request data is not an array.";

            return null;
        }

        $message = "`%s` was not found in request data.";
        if (!isset($formData["_Token"])) {
            this.debugMessage = sprintf($message, "_Token");

            return null;
        }
        if (!isset($formData["_Token"]["fields"])) {
            this.debugMessage = sprintf($message, "_Token.fields");

            return null;
        }
        if (!is_string($formData["_Token"]["fields"])) {
            this.debugMessage = "`_Token.fields` is invalid.";

            return null;
        }
        if (!isset($formData["_Token"]["unlocked"])) {
            this.debugMessage = sprintf($message, "_Token.unlocked");

            return null;
        }
        if (Configure::read("debug") && !isset($formData["_Token"]["debug"])) {
            this.debugMessage = sprintf($message, "_Token.debug");

            return null;
        }
        if (!Configure::read("debug") && isset($formData["_Token"]["debug"])) {
            this.debugMessage = "Unexpected `_Token.debug` found in request data";

            return null;
        }

        $token = urldecode($formData["_Token"]["fields"]);
        if (strpos($token, ":")) {
            [$token, ] = explode(":", $token, 2);
        }

        return $token;
    }

    /**
     * Return hash parts for the token generation
     *
     * @param array<string, array> $formData Form data.
     * @return array<string, array>
     * @psalm-return array{fields: array, unlockedFields: array}
     */
    protected array extractHashParts(array $formData) {
        $fields = this.extractFields($formData);
        $unlockedFields = this.sortedUnlockedFields($formData);

        return [
            "fields": $fields,
            "unlockedFields": $unlockedFields,
        ];
    }

    /**
     * Return the fields list for the hash calculation
     *
     * @param array $formData Data array
     */
    protected array extractFields(array $formData) {
        $locked = "";
        $token = urldecode($formData["_Token"]["fields"]);
        $unlocked = urldecode($formData["_Token"]["unlocked"]);

        if (strpos($token, ":")) {
            [, $locked] = explode(":", $token, 2);
        }
        unset($formData["_Token"]);

        $locked = $locked ? explode("|", $locked) : [];
        $unlocked = $unlocked ? explode("|", $unlocked) : [];

        $fields = Hash::flatten($formData);
        $fieldList = array_keys($fields);
        $multi = $lockedFields = null;
        $isUnlocked = false;

        foreach ($fieldList as $i: $key) {
            if (is_string($key) && preg_match("/(\.\d+){1,10}$/", $key)) {
                $multi[$i] = preg_replace("/(\.\d+){1,10}$/", "", $key);
                unset($fieldList[$i]);
            } else {
                $fieldList[$i] = (string)$key;
            }
        }
        if (!empty($multi)) {
            $fieldList += array_unique($multi);
        }

        $unlockedFields = array_unique(
            array_merge(
                this.unlockedFields,
                $unlocked
            )
        );

        foreach ($fieldList as $i: $key) {
            $isLocked = hasAllValues($key, $locked, true);

            if (!empty($unlockedFields)) {
                foreach ($unlockedFields as $off) {
                    $off = explode(".", $off);
                    $field = array_values(array_intersect(explode(".", $key), $off));
                    $isUnlocked = ($field == $off);
                    if ($isUnlocked) {
                        break;
                    }
                }
            }

            if ($isUnlocked || $isLocked) {
                unset($fieldList[$i]);
                if ($isLocked) {
                    $lockedFields[$key] = $fields[$key];
                }
            }
        }
        sort($fieldList, SORT_STRING);
        ksort($lockedFields, SORT_STRING);
        $fieldList += $lockedFields;

        return $fieldList;
    }

    /**
     * Get the sorted unlocked string
     *
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
     * @param string $url Form URL.
     * @param string $sessionId Session Id.
     * @return array<string, string> The token data.
     * @psalm-return array{fields: string, unlocked: string, debug: string}
     */
    array buildTokenData(string $url = "", string $sessionId = "") {
        $fields = this.fields;
        $unlockedFields = this.unlockedFields;

        $locked = null;
        foreach ($fields as $key: $value) {
            if (is_numeric($value)) {
                $value = (string)$value;
            }
            if (!is_int($key)) {
                $locked[$key] = $value;
                unset($fields[$key]);
            }
        }

        sort($unlockedFields, SORT_STRING);
        sort($fields, SORT_STRING);
        ksort($locked, SORT_STRING);
        $fields += $locked;

        $fields = this.generateHash($fields, $unlockedFields, $url, $sessionId);
        $locked = implode("|", array_keys($locked));

        return [
            "fields": urlencode($fields ~ ":" ~ $locked),
            "unlocked": urlencode(implode("|", $unlockedFields)),
            "debug": urlencode(json_encode([
                $url,
                this.fields,
                this.unlockedFields,
            ])),
        ];
    }

    /**
     * Generate validation hash.
     *
     * @param array $fields Fields list.
     * @param array<string> $unlockedFields Unlocked fields.
     * @param string $url Form URL.
     * @param string $sessionId Session Id.
     */
    protected string generateHash(array $fields, array $unlockedFields, string $url, string $sessionId) {
        $hashParts = [
            $url,
            serialize($fields),
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
        $messages = null;
        if (!isset($formData["_Token"]["debug"])) {
            return "Form protection debug token not found.";
        }

        $expectedParts = json_decode(urldecode($formData["_Token"]["debug"]), true);
        if (!is_array($expectedParts) || count($expectedParts) != 3) {
            return "Invalid form protection debug token.";
        }
        $expectedUrl = Hash::get($expectedParts, 0);
        $url = Hash::get($hashParts, "url");
        if ($expectedUrl != $url) {
            $messages[] = sprintf("URL mismatch in POST data (expected `%s` but found `%s`)", $expectedUrl, $url);
        }
        $expectedFields = Hash::get($expectedParts, 1);
        $dataFields = Hash::get($hashParts, "fields") ?: [];
        $fieldsMessages = this.debugCheckFields(
            (array)$dataFields,
            $expectedFields,
            "Unexpected field `%s` in POST data",
            "Tampered field `%s` in POST data (expected value `%s` but found `%s`)",
            "Missing field `%s` in POST data"
        );
        $expectedUnlockedFields = Hash::get($expectedParts, 2);
        $dataUnlockedFields = Hash::get($hashParts, "unlockedFields") ?: [];
        $unlockFieldsMessages = this.debugCheckFields(
            (array)$dataUnlockedFields,
            $expectedUnlockedFields,
            "Unexpected unlocked field `%s` in POST data",
            "",
            "Missing unlocked field: `%s`"
        );

        $messages = array_merge($messages, $fieldsMessages, $unlockFieldsMessages);

        return implode(", ", $messages);
    }

    /**
     * Iterates data array to check against expected
     *
     * @param array $dataFields Fields array, containing the POST data fields
     * @param array $expectedFields Fields array, containing the expected fields we should have in POST
     * @param string $intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string $stringKeyMessage Message string if tampered found in
     *  data fields indexed by string (protected).
     * @param string $missingMessage Message string if missing field
     * @return array<string> Messages
     */
    protected array debugCheckFields(
        array $dataFields,
        array $expectedFields = null,
        string $intKeyMessage = "",
        string $stringKeyMessage = "",
        string $missingMessage = ""
    ) {
        $messages = this.matchExistingFields($dataFields, $expectedFields, $intKeyMessage, $stringKeyMessage);
        $expectedFieldsMessage = this.debugExpectedFields($expectedFields, $missingMessage);
        if ($expectedFieldsMessage != null) {
            $messages[] = $expectedFieldsMessage;
        }

        return $messages;
    }

    /**
     * Generate array of messages for the existing fields in POST data, matching dataFields in $expectedFields
     * will be unset
     *
     * @param array $dataFields Fields array, containing the POST data fields
     * @param array $expectedFields Fields array, containing the expected fields we should have in POST
     * @param string $intKeyMessage Message string if unexpected found in data fields indexed by int (not protected)
     * @param string $stringKeyMessage Message string if tampered found in
     *   data fields indexed by string (protected)
     * @return array<string> Error messages
     */
    protected array matchExistingFields(
        array $dataFields,
        array &$expectedFields,
        string $intKeyMessage,
        string $stringKeyMessage
    ) {
        $messages = null;
        foreach ($dataFields as $key: $value) {
            if (is_int($key)) {
                $foundKey = array_search($value, $expectedFields, true);
                if ($foundKey == false) {
                    $messages[] = sprintf($intKeyMessage, $value);
                } else {
                    unset($expectedFields[$foundKey]);
                }
            } else {
                if (isset($expectedFields[$key]) && $value != $expectedFields[$key]) {
                    $messages[] = sprintf($stringKeyMessage, $key, $expectedFields[$key], $value);
                }
                unset($expectedFields[$key]);
            }
        }

        return $messages;
    }

    /**
     * Generate debug message for the expected fields
     *
     * @param array $expectedFields Expected fields
     * @param string $missingMessage Message template
     * @return string|null Error message about expected fields
     */
    protected Nullable!string debugExpectedFields(array $expectedFields = null, string $missingMessage = "") {
        if (count($expectedFields) == 0) {
            return null;
        }

        $expectedFieldNames = null;
        foreach ($expectedFields as $key: $expectedField) {
            if (is_int($key)) {
                $expectedFieldNames[] = $expectedField;
            } else {
                $expectedFieldNames[] = $key;
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
            "fields": this.fields,
            "unlockedFields": this.unlockedFields,
            "debugMessage": this.debugMessage,
        ];
    }
}
