/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.validations;

@safe:
import uim.cake;

/**
 * Validator object encapsulates all methods related to data validations for a model
 * It also provides an API to dynamically change validation rules for each model field.
 *
 * : ArrayAccess to easily modify rules in the set
 *
 * @link https://book.UIM.org/4/en/core-libraries/validation.html
 */
class Validator : ArrayAccess, IteratorAggregate, Countable {
    /**
     * By using "create" you can make fields required when records are first created.
     */
    public const string WHEN_CREATE = "create";

    // By using "update", you can make fields required when they are updated.
    public const string WHEN_UPDATE = "update";

    // Used to flag nested rules created with addNested() and addNestedMany()
    public const string NESTED = "_nested";

    /**
     * A flag for allowEmptyFor()
     *
     * When `null` is given, it will be recognized as empty.
    */
    public const int EMPTY_NULL = 0;

    /**
     * A flag for allowEmptyFor()
     *
     * When an empty string is given, it will be recognized as empty.
    */
    public const int EMPTY_STRING = 1;

    /**
     * A flag for allowEmptyFor()
     *
     * When an empty array is given, it will be recognized as empty.
    */
    public const int EMPTY_ARRAY = 2;

    /**
     * A flag for allowEmptyFor()
     *
     * When an array is given, if it has at least the `name`, `type`, `tmp_name` and `error` keys,
     * and the value of `error` is equal to `UPLOAD_ERR_NO_FILE`, the value will be recognized as
     * empty.
     *
     * When an instance of \Psr\Http\Message\UploadedFileInterface is given the
     * return value of it"s getError() method must be equal to `UPLOAD_ERR_NO_FILE`.
    */
    public const int EMPTY_FILE = 4;

    /**
     * A flag for allowEmptyFor()
     *
     * When an array is given, if it contains the `year` key, and only empty strings
     * or null values, it will be recognized as empty.
     */
    public const int EMPTY_DATE = 8;

    /**
     * A flag for allowEmptyFor()
     *
     * When an array is given, if it contains the `hour` key, and only empty strings
     * or null values, it will be recognized as empty.
     */
    public const int EMPTY_TIME = 16;

    /**
     * A combination of the all EMPTY_* flags
    */
    public const int EMPTY_ALL = self::EMPTY_STRING
        | self::EMPTY_ARRAY
        | self::EMPTY_FILE
        | self::EMPTY_DATE
        | self::EMPTY_TIME;

    /**
     * Holds the ValidationSet objects array
     *
     * @var array<string, \Cake\Validation\ValidationSet>
     */
    protected _fields = [];

    /**
     * An associative array of objects or classes containing methods
     * used for validation
     *
     * @var array<string, object|string>
     * @psalm-var array<string, object|class-string>
     */
    protected _providers = [];

    /**
     * An associative array of objects or classes used as a default provider list
     *
     * @var array<string, object|string>
     * @psalm-var array<string, object|class-string>
     */
    protected static $_defaultProviders = [];

    /**
     * Contains the validation messages associated with checking the presence
     * for each corresponding field.
     *
     * @var array
     */
    protected _presenceMessages = [];

    /**
     * Whether to use I18n functions for translating default error messages
     *
     * @var bool
     */
    protected _useI18n = false;

    /**
     * Contains the validation messages associated with checking the emptiness
     * for each corresponding field.
     *
     * @var array
     */
    protected _allowEmptyMessages = [];

    /**
     * Contains the flags which specify what is empty for each corresponding field.
     *
     * @var array
     */
    protected _allowEmptyFlags = [];

    /**
     * Whether to apply last flag to generated rule(s).
     *
     * @var bool
     */
    protected _stopOnFailure = false;

    /**
     * Constructor
     */
    this() {
        _useI18n = function_exists("__d");
        _providers = self::$_defaultProviders;
    }

    /**
     * Whether to stop validation rule evaluation on the first failed rule.
     *
     * When enabled the first failing rule per field will cause validation to stop.
     * When disabled all rules will be run even if there are failures.
     *
     * @param bool $stopOnFailure If to apply last flag.
     * @return this
     */
    auto setStopOnFailure(bool $stopOnFailure = true) {
        _stopOnFailure = $stopOnFailure;

        return this;
    }

    /**
     * Validates and returns an array of failed fields and their error messages.
     *
     * @param array myData The data to be checked for errors
     * @param bool $newRecord whether the data to be validated is new or to be updated.
     * @return array<array> Array of failed fields
     * @deprecated 3.9.0 Renamed to {@link validate()}.
     */
    function errors(array myData, bool $newRecord = true): array
    {
        deprecationWarning("`Validator::errors()` is deprecated. Use `Validator::validate()` instead.");

        return this.validate(myData, $newRecord);
    }

    /**
     * Validates and returns an array of failed fields and their error messages.
     *
     * @param array myData The data to be checked for errors
     * @param bool $newRecord whether the data to be validated is new or to be updated.
     * @return array<array> Array of failed fields
     */
    function validate(array myData, bool $newRecord = true): array
    {
        myErrors = [];

        foreach (_fields as myName: myField) {
            myKeyPresent = array_key_exists(myName, myData);

            $providers = _providers;
            $context = compact("data", "newRecord", "field", "providers");

            if (!myKeyPresent && !_checkPresence(myField, $context)) {
                myErrors[myName]["_required"] = this.getRequiredMessage(myName);
                continue;
            }
            if (!myKeyPresent) {
                continue;
            }

            $canBeEmpty = _canBeEmpty(myField, $context);

            $flags = static::EMPTY_NULL;
            if (isset(_allowEmptyFlags[myName])) {
                $flags = _allowEmptyFlags[myName];
            }

            $isEmpty = this.isEmpty(myData[myName], $flags);

            if (!$canBeEmpty && $isEmpty) {
                myErrors[myName]["_empty"] = this.getNotEmptyMessage(myName);
                continue;
            }

            if ($isEmpty) {
                continue;
            }

            myResult = _processRules(myName, myField, myData, $newRecord);
            if (myResult) {
                myErrors[myName] = myResult;
            }
        }

        return myErrors;
    }

    /**
     * Returns a ValidationSet object containing all validation rules for a field, if
     * passed a ValidationSet as second argument, it will replace any other rule set defined
     * before
     *
     * @param string myName [optional] The fieldname to fetch.
     * @param \Cake\Validation\ValidationSet|null $set The set of rules for field
     * @return \Cake\Validation\ValidationSet
     */
    function field(string myName, ?ValidationSet $set = null): ValidationSet
    {
        if (empty(_fields[myName])) {
            $set = $set ?: new ValidationSet();
            _fields[myName] = $set;
        }

        return _fields[myName];
    }

    /**
     * Check whether a validator contains any rules for the given field.
     *
     * @param string myName The field name to check.
     */
    bool hasField(string myName) {
        return isset(_fields[myName]);
    }

    /**
     * Associates an object to a name so it can be used as a provider. Providers are
     * objects or class names that can contain methods used during validation of for
     * deciding whether a validation rule can be applied. All validation methods,
     * when called will receive the full list of providers stored in this validator.
     *
     * @param string myName The name under which the provider should be set.
     * @param object|string object Provider object or class name.
     * @psalm-param object|class-string object
     * @return this
     */
    auto setProvider(string myName, $object) {
        if (!is_string($object) && !is_object($object)) {
            deprecationWarning(sprintf(
                "The provider must be an object or class name string. Got `%s` instead.",
                getTypeName($object)
            ));
        }

        _providers[myName] = $object;

        return this;
    }

    /**
     * Returns the provider stored under that name if it exists.
     *
     * @param string myName The name under which the provider should be set.
     * @return object|string|null
     * @psalm-return object|class-string|null
     */
    auto getProvider(string myName) {
        if (isset(_providers[myName])) {
            return _providers[myName];
        }
        if (myName != "default") {
            return null;
        }

        _providers[myName] = new RulesProvider();

        return _providers[myName];
    }

    /**
     * Returns the default provider stored under that name if it exists.
     *
     * @param string myName The name under which the provider should be retrieved.
     * @return object|string|null
     * @psalm-return object|class-string|null
     */
    static auto getDefaultProvider(string myName) {
        return self::$_defaultProviders[myName] ?? null;
    }

    /**
     * Associates an object to a name so it can be used as a default provider.
     *
     * @param string myName The name under which the provider should be set.
     * @param object|string object Provider object or class name.
     * @psalm-param object|class-string object
     * @return void
     */
    static void addDefaultProvider(string myName, $object) {
        if (!is_string($object) && !is_object($object)) {
            deprecationWarning(sprintf(
                "The provider must be an object or class name string. Got `%s` instead.",
                getTypeName($object)
            ));
        }

        self::$_defaultProviders[myName] = $object;
    }

    /**
     * Get the list of default providers.
     *
     * @return array<string>
     */
    static string[] getDefaultProviders(): array
    {
        return array_keys(self::$_defaultProviders);
    }

    /**
     * Get the list of providers in this validator.
     *
     * @return array<string>
     */
    string[] providers(): array
    {
        return array_keys(_providers);
    }

    /**
     * Returns whether a rule set is defined for a field or not
     *
     * @param string myField name of the field to check
     */
    bool offsetExists(myField) {
        return isset(_fields[myField]);
    }

    /**
     * Returns the rule set for a field
     *
     * @param string myField name of the field to check
     * @return \Cake\Validation\ValidationSet
     */
    function offsetGet(myField): ValidationSet
    {
        return this.field(myField);
    }

    /**
     * Sets the rule set for a field
     *
     * @param string myField name of the field to set
     * @param \Cake\Validation\ValidationSet|array $rules set of rules to apply to field
     */
    void offsetSet(myField, $rules) {
        if (!$rules instanceof ValidationSet) {
            $set = new ValidationSet();
            foreach ($rules as myName: $rule) {
                $set.add(myName, $rule);
            }
            $rules = $set;
        }
        _fields[myField] = $rules;
    }

    /**
     * Unsets the rule set for a field
     *
     * @param string myField name of the field to unset
     * @return void
     */
    void offsetUnset(myField) {
        unset(_fields[myField]);
    }

    /**
     * Returns an iterator for each of the fields to be validated
     *
     * @return \Traversable<string, \Cake\Validation\ValidationSet>
     */
    Traversable getIterator() {
        return new ArrayIterator(_fields);
    }

    /**
     * Returns the number of fields having validation rules
     */
    int count() {
        return count(_fields);
    }

    /**
     * Adds a new rule to a field"s rule set. If second argument is an array
     * then rules list for the field will be replaced with second argument and
     * third argument will be ignored.
     *
     * ### Example:
     *
     * ```
     *      $validator
     *          .add("title", "required", ["rule": "notBlank"])
     *          .add("user_id", "valid", ["rule": "numeric", "message": "Invalid User"])
     *
     *      $validator.add("password", [
     *          "size": ["rule": ["lengthBetween", 8, 20]],
     *          "hasSpecialCharacter": ["rule": "validateSpecialchar", "message": "not valid"]
     *      ]);
     * ```
     *
     * @param string myField The name of the field from which the rule will be added
     * @param array|string myName The alias for a single rule or multiple rules array
     * @param \Cake\Validation\ValidationRule|array $rule the rule to add
     * @throws \InvalidArgumentException If numeric index cannot be resolved to a string one
     * @return this
     */
    function add(string myField, myName, $rule = []) {
        $validationSet = this.field(myField);

        if (!is_array(myName)) {
            $rules = [myName: $rule];
        } else {
            $rules = myName;
        }

        foreach ($rules as myName: $rule) {
            if (is_array($rule)) {
                $rule += [
                    "rule": myName,
                    "last": _stopOnFailure,
                ];
            }
            if (!is_string(myName)) {
                /** @psalm-suppress PossiblyUndefinedMethod */
                myName = $rule["rule"];
                if (is_array(myName)) {
                    myName = array_shift(myName);
                }

                if ($validationSet.offsetExists(myName)) {
                    myMessage = "You cannot add a rule without a unique name, already existing rule found: " . myName;
                    throw new InvalidArgumentException(myMessage);
                }

                deprecationWarning(
                    "Adding validation rules without a name key is deprecated. Update rules array to have string keys."
                );
            }

            $validationSet.add(myName, $rule);
        }

        return this;
    }

    /**
     * Adds a nested validator.
     *
     * Nesting validators allows you to define validators for array
     * types. For example, nested validators are ideal when you want to validate a
     * sub-document, or complex array type.
     *
     * This method assumes that the sub-document has a 1:1 relationship with the parent.
     *
     * The providers of the parent validator will be synced into the nested validator, when
     * errors are checked. This ensures that any validation rule providers connected
     * in the parent will have the same values in the nested validator when rules are evaluated.
     *
     * @param string myField The root field for the nested validator.
     * @param \Cake\Validation\Validator $validator The nested validator.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @return this
     */
    function addNested(string myField, Validator $validator, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["message": myMessage, "on": $when]);

        $validationSet = this.field(myField);
        $validationSet.add(static::NESTED, $extra + ["rule": function (myValue, $context) use ($validator, myMessage) {
            if (!is_array(myValue)) {
                return false;
            }
            foreach (this.providers() as $provider) {
                /** @psalm-suppress PossiblyNullArgument */
                $validator.setProvider($provider, this.getProvider($provider));
            }
            myErrors = $validator.validate(myValue, $context["newRecord"]);

            myMessage = myMessage ? [static::NESTED: myMessage] : [];

            return empty(myErrors) ? true : myErrors + myMessage;
        }]);

        return this;
    }

    /**
     * Adds a nested validator.
     *
     * Nesting validators allows you to define validators for array
     * types. For example, nested validators are ideal when you want to validate many
     * similar sub-documents or complex array types.
     *
     * This method assumes that the sub-document has a 1:N relationship with the parent.
     *
     * The providers of the parent validator will be synced into the nested validator, when
     * errors are checked. This ensures that any validation rule providers connected
     * in the parent will have the same values in the nested validator when rules are evaluated.
     *
     * @param string myField The root field for the nested validator.
     * @param \Cake\Validation\Validator $validator The nested validator.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @return this
     */
    function addNestedMany(string myField, Validator $validator, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["message": myMessage, "on": $when]);

        $validationSet = this.field(myField);
        $validationSet.add(static::NESTED, $extra + ["rule": function (myValue, $context) use ($validator, myMessage) {
            if (!is_array(myValue)) {
                return false;
            }
            foreach (this.providers() as $provider) {
                /** @psalm-suppress PossiblyNullArgument */
                $validator.setProvider($provider, this.getProvider($provider));
            }
            myErrors = [];
            foreach (myValue as $i: $row) {
                if (!is_array($row)) {
                    return false;
                }
                $check = $validator.validate($row, $context["newRecord"]);
                if (!empty($check)) {
                    myErrors[$i] = $check;
                }
            }

            myMessage = myMessage ? [static::NESTED: myMessage] : [];

            return empty(myErrors) ? true : myErrors + myMessage;
        }]);

        return this;
    }

    /**
     * Removes a rule from the set by its name
     *
     * ### Example:
     *
     * ```
     *      $validator
     *          .remove("title", "required")
     *          .remove("user_id")
     * ```
     *
     * @param string myField The name of the field from which the rule will be removed
     * @param string|null $rule the name of the rule to be removed
     * @return this
     */
    function remove(string myField, Nullable!string rule = null) {
        if ($rule is null) {
            unset(_fields[myField]);
        } else {
            this.field(myField).remove($rule);
        }

        return this;
    }

    /**
     * Sets whether a field is required to be present in data array.
     * You can also pass array. Using an array will let you provide the following
     * keys:
     *
     * - `mode` individual mode for field
     * - `message` individual error message for field
     *
     * You can also set mode and message for all passed fields, the individual
     * setting takes precedence over group settings.
     *
     * @param array|string myField the name of the field or list of fields.
     * @param callable|string|bool myMode Valid values are true, false, "create", "update".
     *   If a callable is passed then the field will be required only when the callback
     *   returns true.
     * @param string|null myMessage The message to show if the field presence validation fails.
     * @return this
     */
    function requirePresence(myField, myMode = true, Nullable!string myMessage = null) {
        $defaults = [
            "mode": myMode,
            "message": myMessage,
        ];

        if (!is_array(myField)) {
            myField = _convertValidatorToArray(myField, $defaults);
        }

        foreach (myField as myFieldName: $setting) {
            $settings = _convertValidatorToArray(myFieldName, $defaults, $setting);
            myFieldName = current(array_keys($settings));

            this.field(myFieldName).requirePresence($settings[myFieldName]["mode"]);
            if ($settings[myFieldName]["message"]) {
                _presenceMessages[myFieldName] = $settings[myFieldName]["message"];
            }
        }

        return this;
    }

    /**
     * Allows a field to be empty. You can also pass array.
     * Using an array will let you provide the following keys:
     *
     * - `when` individual when condition for field
     * - "message" individual message for field
     *
     * You can also set when and message for all passed fields, the individual setting
     * takes precedence over group settings.
     *
     * This is the opposite of notEmpty() which requires a field to not be empty.
     * By using myMode equal to "create" or "update", you can allow fields to be empty
     * when records are first created, or when they are updated.
     *
     * ### Example:
     *
     * ```
     * // Email can be empty
     * $validator.allowEmpty("email");
     *
     * // Email can be empty on create
     * $validator.allowEmpty("email", Validator::WHEN_CREATE);
     *
     * // Email can be empty on update
     * $validator.allowEmpty("email", Validator::WHEN_UPDATE);
     *
     * // Email and subject can be empty on update
     * $validator.allowEmpty(["email", "subject"], Validator::WHEN_UPDATE;
     *
     * // Email can be always empty, subject and content can be empty on update.
     * $validator.allowEmpty(
     *      [
     *          "email": [
     *              "when": true
     *          ],
     *          "content": [
     *              "message": "Content cannot be empty"
     *          ],
     *          "subject"
     *      ],
     *      Validator::WHEN_UPDATE
     * );
     * ```
     *
     * It is possible to conditionally allow emptiness on a field by passing a callback
     * as a second argument. The callback will receive the validation context array as
     * argument:
     *
     * ```
     * $validator.allowEmpty("email", function ($context) {
     *  return !$context["newRecord"] || $context["data"]["role"] == "admin";
     * });
     * ```
     *
     * This method will correctly detect empty file uploads and date/time/datetime fields.
     *
     * Because this and `notEmpty()` modify the same internal state, the last
     * method called will take precedence.
     *
     * @deprecated 3.7.0 Use {@link allowEmptyString()}, {@link allowEmptyArray()}, {@link allowEmptyFile()},
     *   {@link allowEmptyDate()}, {@link allowEmptyTime()}, {@link allowEmptyDateTime()} or {@link allowEmptyFor()} instead.
     * @param array|string myField the name of the field or a list of fields
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true (always), "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @param string|null myMessage The message to show if the field is not
     * @return this
     */
    function allowEmpty(myField, $when = true, myMessage = null) {
        deprecationWarning(
            "allowEmpty() is deprecated. "
            . "Use allowEmptyString(), allowEmptyArray(), allowEmptyFile(), allowEmptyDate(), allowEmptyTime(), "
            . "allowEmptyDateTime() or allowEmptyFor() instead."
        );

        $defaults = [
            "when": $when,
            "message": myMessage,
        ];
        if (!is_array(myField)) {
            myField = _convertValidatorToArray(myField, $defaults);
        }

        foreach (myField as myFieldName: $setting) {
            $settings = _convertValidatorToArray(myFieldName, $defaults, $setting);
            myFieldName = array_keys($settings)[0];
            this.allowEmptyFor(
                myFieldName,
                static::EMPTY_ALL,
                $settings[myFieldName]["when"],
                $settings[myFieldName]["message"]
            );
        }

        return this;
    }

    /**
     * Low-level method to indicate that a field can be empty.
     *
     * This method should generally not be used and instead you should
     * use:
     *
     * - `allowEmptyString()`
     * - `allowEmptyArray()`
     * - `allowEmptyFile()`
     * - `allowEmptyDate()`
     * - `allowEmptyDatetime()`
     * - `allowEmptyTime()`
     *
     * Should be used as their APIs are simpler to operate and read.
     *
     * You can also set flags, when and message for all passed fields, the individual
     * setting takes precedence over group settings.
     *
     * ### Example:
     *
     * ```
     * // Email can be empty
     * $validator.allowEmptyFor("email", Validator::EMPTY_STRING);
     *
     * // Email can be empty on create
     * $validator.allowEmptyFor("email", Validator::EMPTY_STRING, Validator::WHEN_CREATE);
     *
     * // Email can be empty on update
     * $validator.allowEmptyFor("email", Validator::EMPTY_STRING, Validator::WHEN_UPDATE);
     * ```
     *
     * It is possible to conditionally allow emptiness on a field by passing a callback
     * as a second argument. The callback will receive the validation context array as
     * argument:
     *
     * ```
     * $validator.allowEmpty("email", Validator::EMPTY_STRING, function ($context) {
     *   return !$context["newRecord"] || $context["data"]["role"] == "admin";
     * });
     * ```
     *
     * If you want to allow other kind of empty data on a field, you need to pass other
     * flags:
     *
     * ```
     * $validator.allowEmptyFor("photo", Validator::EMPTY_FILE);
     * $validator.allowEmptyFor("published", Validator::EMPTY_STRING | Validator::EMPTY_DATE | Validator::EMPTY_TIME);
     * $validator.allowEmptyFor("items", Validator::EMPTY_STRING | Validator::EMPTY_ARRAY);
     * ```
     *
     * You can also use convenience wrappers of this method. The following calls are the
     * same as above:
     *
     * ```
     * $validator.allowEmptyFile("photo");
     * $validator.allowEmptyDateTime("published");
     * $validator.allowEmptyArray("items");
     * ```
     *
     * @param string myField The name of the field.
     * @param int|null $flags A bitmask of EMPTY_* flags which specify what is empty.
     *   If no flags/bitmask is provided only `null` will be allowed as empty value.
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true, false, "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @param string|null myMessage The message to show if the field is not

     * @return this
     */
    function allowEmptyFor(string myField, Nullable!int $flags = null, $when = true, Nullable!string myMessage = null) {
        this.field(myField).allowEmpty($when);
        if (myMessage) {
            _allowEmptyMessages[myField] = myMessage;
        }
        if ($flags  !is null) {
            _allowEmptyFlags[myField] = $flags;
        }

        return this;
    }

    /**
     * Allows a field to be an empty string.
     *
     * This method is equivalent to calling allowEmptyFor() with EMPTY_STRING flag.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true, false, "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @return this
     * @see uim.cake.Validation\Validator::allowEmptyFor() For detail usage
     */
    function allowEmptyString(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_STRING, $when, myMessage);
    }

    /**
     * Requires a field to be not be an empty string.
     *
     * Opposite to allowEmptyString()
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @see uim.cake.Validation\Validator::allowEmptyString()
     * @since 3.8.0
     */
    function notEmptyString(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_STRING, $when, myMessage);
    }

    /**
     * Allows a field to be an empty array.
     *
     * This method is equivalent to calling allowEmptyFor() with EMPTY_STRING +
     * EMPTY_ARRAY flags.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true, false, "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @return this

     * @see uim.cake.Validation\Validator::allowEmptyFor() for examples.
     */
    function allowEmptyArray(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_ARRAY, $when, myMessage);
    }

    /**
     * Require a field to be a non-empty array
     *
     * Opposite to allowEmptyArray()
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @see uim.cake.Validation\Validator::allowEmptyArray()
     */
    function notEmptyArray(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_ARRAY, $when, myMessage);
    }

    /**
     * Allows a field to be an empty file.
     *
     * This method is equivalent to calling allowEmptyFor() with EMPTY_FILE flag.
     * File fields will not accept `""`, or `[]` as empty values. Only `null` and a file
     * upload with `error` equal to `UPLOAD_ERR_NO_FILE` will be treated as empty.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     *   Valid values are true, "create", "update". If a callable is passed then
     *   the field will allowed to be empty only when the callback returns true.
     * @return this

     * @see uim.cake.Validation\Validator::allowEmptyFor() For detail usage
     */
    function allowEmptyFile(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_FILE, $when, myMessage);
    }

    /**
     * Require a field to be a not-empty file.
     *
     * Opposite to allowEmptyFile()
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @since 3.8.0
     * @see uim.cake.Validation\Validator::allowEmptyFile()
     */
    function notEmptyFile(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_FILE, $when, myMessage);
    }

    /**
     * Allows a field to be an empty date.
     *
     * Empty date values are `null`, `""`, `[]` and arrays where all values are `""`
     * and the `year` key is present.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true, false, "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @return this
     * @see uim.cake.Validation\Validator::allowEmptyFor() for examples
     */
    function allowEmptyDate(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_DATE, $when, myMessage);
    }

    /**
     * Require a non-empty date value
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @see uim.cake.Validation\Validator::allowEmptyDate() for examples
     */
    function notEmptyDate(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_DATE, $when, myMessage);
    }

    /**
     * Allows a field to be an empty time.
     *
     * Empty date values are `null`, `""`, `[]` and arrays where all values are `""`
     * and the `hour` key is present.
     *
     * This method is equivalent to calling allowEmptyFor() with EMPTY_STRING +
     * EMPTY_TIME flags.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     * Valid values are true, false, "create", "update". If a callable is passed then
     * the field will allowed to be empty only when the callback returns true.
     * @return this

     * @see uim.cake.Validation\Validator::allowEmptyFor() for examples.
     */
    function allowEmptyTime(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_TIME, $when, myMessage);
    }

    /**
     * Require a field to be a non-empty time.
     *
     * Opposite to allowEmptyTime()
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @since 3.8.0
     * @see uim.cake.Validation\Validator::allowEmptyTime()
     */
    function notEmptyTime(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_TIME, $when, myMessage);
    }

    /**
     * Allows a field to be an empty date/time.
     *
     * Empty date values are `null`, `""`, `[]` and arrays where all values are `""`
     * and the `year` and `hour` keys are present.
     *
     * This method is equivalent to calling allowEmptyFor() with EMPTY_STRING +
     * EMPTY_DATE + EMPTY_TIME flags.
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is allowed to be empty
     *   Valid values are true, false, "create", "update". If a callable is passed then
     *   the field will allowed to be empty only when the callback returns false.
     * @return this

     * @see uim.cake.Validation\Validator::allowEmptyFor() for examples.
     */
    function allowEmptyDateTime(string myField, Nullable!string myMessage = null, $when = true) {
        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_DATE | self::EMPTY_TIME, $when, myMessage);
    }

    /**
     * Require a field to be a non empty date/time.
     *
     * Opposite to allowEmptyDateTime
     *
     * @param string myField The name of the field.
     * @param string|null myMessage The message to show if the field is empty.
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are false (never), "create", "update". If a
     *   callable is passed then the field will be required to be not empty when
     *   the callback returns true.
     * @return this
     * @since 3.8.0
     * @see uim.cake.Validation\Validator::allowEmptyDateTime()
     */
    function notEmptyDateTime(string myField, Nullable!string myMessage = null, $when = false) {
        $when = this.invertWhenClause($when);

        return this.allowEmptyFor(myField, self::EMPTY_STRING | self::EMPTY_DATE | self::EMPTY_TIME, $when, myMessage);
    }

    /**
     * Converts validator to fieldName: $settings array
     *
     * @param string|int myFieldName name of field
     * @param array<string, mixed> $defaults default settings
     * @param array<string, mixed>|string settings settings from data
     * @return array<array>
     * @throws \InvalidArgumentException
     */
    protected auto _convertValidatorToArray(myFieldName, array $defaults = [], $settings = []): array
    {
        if (is_string($settings)) {
            myFieldName = $settings;
            $settings = [];
        }
        if (!is_array($settings)) {
            throw new InvalidArgumentException(
                sprintf("Invalid settings for "%s". Settings must be an array.", myFieldName)
            );
        }
        $settings += $defaults;

        return [myFieldName: $settings];
    }

    /**
     * Sets a field to require a non-empty value. You can also pass array.
     * Using an array will let you provide the following keys:
     *
     * - `when` individual when condition for field
     * - `message` individual error message for field
     *
     * You can also set `when` and `message` for all passed fields, the individual setting
     * takes precedence over group settings.
     *
     * This is the opposite of `allowEmpty()` which allows a field to be empty.
     * By using myMode equal to "create" or "update", you can make fields required
     * when records are first created, or when they are updated.
     *
     * ### Example:
     *
     * ```
     * myMessage = "This field cannot be empty";
     *
     * // Email cannot be empty
     * $validator.notEmpty("email");
     *
     * // Email can be empty on update, but not create
     * $validator.notEmpty("email", myMessage, "create");
     *
     * // Email can be empty on create, but required on update.
     * $validator.notEmpty("email", myMessage, Validator::WHEN_UPDATE);
     *
     * // Email and title can be empty on create, but are required on update.
     * $validator.notEmpty(["email", "title"], myMessage, Validator::WHEN_UPDATE);
     *
     * // Email can be empty on create, title must always be not empty
     * $validator.notEmpty(
     *      [
     *          "email",
     *          "title": [
     *              "when": true,
     *              "message": "Title cannot be empty"
     *          ]
     *      ],
     *      myMessage,
     *      Validator::WHEN_UPDATE
     * );
     * ```
     *
     * It is possible to conditionally disallow emptiness on a field by passing a callback
     * as the third argument. The callback will receive the validation context array as
     * argument:
     *
     * ```
     * $validator.notEmpty("email", "Email is required", function ($context) {
     *   return $context["newRecord"] && $context["data"]["role"] != "admin";
     * });
     * ```
     *
     * Because this and `allowEmpty()` modify the same internal state, the last
     * method called will take precedence.
     *
     * @deprecated 3.7.0 Use {@link notEmptyString()}, {@link notEmptyArray()}, {@link notEmptyFile()},
     *   {@link notEmptyDate()}, {@link notEmptyTime()} or {@link notEmptyDateTime()} instead.
     * @param array|string myField the name of the field or list of fields
     * @param string|null myMessage The message to show if the field is not
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are true (always), "create", "update". If a
     *   callable is passed then the field will allowed to be empty only when
     *   the callback returns false.
     * @return this
     */
    function notEmpty(myField, Nullable!string myMessage = null, $when = false) {
        deprecationWarning(
            "notEmpty() is deprecated. "
            . "Use notEmptyString(), notEmptyArray(), notEmptyFile(), notEmptyDate(), notEmptyTime() "
            . "or notEmptyDateTime() instead."
        );

        $defaults = [
            "when": $when,
            "message": myMessage,
        ];

        if (!is_array(myField)) {
            myField = _convertValidatorToArray(myField, $defaults);
        }

        foreach (myField as myFieldName: $setting) {
            $settings = _convertValidatorToArray(myFieldName, $defaults, $setting);
            myFieldName = current(array_keys($settings));

            $whenSetting = this.invertWhenClause($settings[myFieldName]["when"]);

            this.field(myFieldName).allowEmpty($whenSetting);
            _allowEmptyFlags[myFieldName] = static::EMPTY_ALL;
            if ($settings[myFieldName]["message"]) {
                _allowEmptyMessages[myFieldName] = $settings[myFieldName]["message"];
            }
        }

        return this;
    }

    /**
     * Invert a when clause for creating notEmpty rules
     *
     * @param callable|string|bool $when Indicates when the field is not allowed
     *   to be empty. Valid values are true (always), "create", "update". If a
     *   callable is passed then the field will allowed to be empty only when
     *   the callback returns false.
     * @return callable|string|bool
     */
    protected auto invertWhenClause($when) {
        if ($when == static::WHEN_CREATE || $when == static::WHEN_UPDATE) {
            return $when == static::WHEN_CREATE ? static::WHEN_UPDATE : static::WHEN_CREATE;
        }
        if (is_callable($when)) {
            return function ($context) use ($when) {
                return !$when($context);
            };
        }

        return $when;
    }

    /**
     * Add a notBlank rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::notBlank()
     * @return this
     */
    function notBlank(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notBlank", $extra + [
            "rule": "notBlank",
        ]);
    }

    /**
     * Add an alphanumeric rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::alphaNumeric()
     * @return this
     */
    function alphaNumeric(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "alphaNumeric", $extra + [
            "rule": "alphaNumeric",
        ]);
    }

    /**
     * Add a non-alphanumeric rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::notAlphaNumeric()
     * @return this
     */
    function notAlphaNumeric(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notAlphaNumeric", $extra + [
            "rule": "notAlphaNumeric",
        ]);
    }

    /**
     * Add an ascii-alphanumeric rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::asciiAlphaNumeric()
     * @return this
     */
    function asciiAlphaNumeric(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "asciiAlphaNumeric", $extra + [
            "rule": "asciiAlphaNumeric",
        ]);
    }

    /**
     * Add a non-ascii alphanumeric rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::notAlphaNumeric()
     * @return this
     */
    function notAsciiAlphaNumeric(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notAsciiAlphaNumeric", $extra + [
            "rule": "notAsciiAlphaNumeric",
        ]);
    }

    /**
     * Add an rule that ensures a string length is within a range.
     *
     * @param string myField The field you want to apply the rule to.
     * @param array $range The inclusive minimum and maximum length you want permitted.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::alphaNumeric()
     * @return this
     * @throws \InvalidArgumentException
     */
    function lengthBetween(string myField, array $range, Nullable!string myMessage = null, $when = null) {
        if (count($range) != 2) {
            throw new InvalidArgumentException("The $range argument requires 2 numbers");
        }
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "lengthBetween", $extra + [
            "rule": ["lengthBetween", array_shift($range), array_shift($range)],
        ]);
    }

    /**
     * Add a credit card rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string myType The type of cards you want to allow. Defaults to "all".
     *   You can also supply an array of accepted card types. e.g `["mastercard", "visa", "amex"]`
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::creditCard()
     * @return this
     */
    function creditCard(string myField, string myType = "all", Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "creditCard", $extra + [
            "rule": ["creditCard", myType, true],
        ]);
    }

    /**
     * Add a greater than comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be greater than.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function greaterThan(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "greaterThan", $extra + [
            "rule": ["comparison", Validation::COMPARE_GREATER, myValue],
        ]);
    }

    /**
     * Add a greater than or equal to comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be greater than or equal to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function greaterThanOrEqual(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "greaterThanOrEqual", $extra + [
            "rule": ["comparison", Validation::COMPARE_GREATER_OR_EQUAL, myValue],
        ]);
    }

    /**
     * Add a less than comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be less than.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function lessThan(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "lessThan", $extra + [
            "rule": ["comparison", Validation::COMPARE_LESS, myValue],
        ]);
    }

    /**
     * Add a less than or equal comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be less than or equal to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function lessThanOrEqual(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "lessThanOrEqual", $extra + [
            "rule": ["comparison", Validation::COMPARE_LESS_OR_EQUAL, myValue],
        ]);
    }

    /**
     * Add a equal to comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be equal to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function equals(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "equals", $extra + [
            "rule": ["comparison", Validation::COMPARE_EQUAL, myValue],
        ]);
    }

    /**
     * Add a not equal to comparison rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param float|int myValue The value user data must be not be equal to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::comparison()
     * @return this
     */
    function notEquals(string myField, myValue, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notEquals", $extra + [
            "rule": ["comparison", Validation::COMPARE_NOT_EQUAL, myValue],
        ]);
    }

    /**
     * Add a rule to compare two fields to each other.
     *
     * If both fields have the exact same value the rule will pass.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this
     */
    function sameAs(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "sameAs", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_SAME],
        ]);
    }

    /**
     * Add a rule to compare that two fields have different values.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function notSameAs(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notSameAs", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_NOT_SAME],
        ]);
    }

    /**
     * Add a rule to compare one field is equal to another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function equalToField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "equalToField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_EQUAL],
        ]);
    }

    /**
     * Add a rule to compare one field is not equal to another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function notEqualToField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "notEqualToField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_NOT_EQUAL],
        ]);
    }

    /**
     * Add a rule to compare one field is greater than another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function greaterThanField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "greaterThanField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_GREATER],
        ]);
    }

    /**
     * Add a rule to compare one field is greater than or equal to another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function greaterThanOrEqualToField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "greaterThanOrEqualToField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_GREATER_OR_EQUAL],
        ]);
    }

    /**
     * Add a rule to compare one field is less than another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function lessThanField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "lessThanField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_LESS],
        ]);
    }

    /**
     * Add a rule to compare one field is less than or equal to another.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string secondField The field you want to compare against.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::compareFields()
     * @return this

     */
    function lessThanOrEqualToField(string myField, string secondField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "lessThanOrEqualToField", $extra + [
            "rule": ["compareFields", $secondField, Validation::COMPARE_LESS_OR_EQUAL],
        ]);
    }

    /**
     * Add a rule to check if a field contains non alpha numeric characters.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int $limit The minimum number of non-alphanumeric fields required.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::containsNonAlphaNumeric()
     * @return this
     * @deprecated 4.0.0 Use {@link notAlphaNumeric()} instead. Will be removed in 5.0
     */
    function containsNonAlphaNumeric(string myField, int $limit = 1, Nullable!string myMessage = null, $when = null) {
        deprecationWarning("Validator::containsNonAlphaNumeric() is deprecated. Use notAlphaNumeric() instead.");
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "containsNonAlphaNumeric", $extra + [
            "rule": ["containsNonAlphaNumeric", $limit],
        ]);
    }

    /**
     * Add a date format validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param $formats A list of accepted date formats.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::date()
     * @return this
     */
    function date(string myField, string[] $formats = ["ymd"], Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "date", $extra + [
            "rule": ["date", $formats],
        ]);
    }

    /**
     * Add a date time format validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param array<string> $formats A list of accepted date formats.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::datetime()
     * @return this
     */
    function dateTime(string myField, array $formats = ["ymd"], Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "dateTime", $extra + [
            "rule": ["datetime", $formats],
        ]);
    }

    /**
     * Add a time format validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::time()
     * @return this
     */
    function time(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "time", $extra + [
            "rule": "time",
        ]);
    }

    /**
     * Add a localized time, date or datetime format validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string myType Parser type, one out of "date", "time", and "datetime"
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::localizedTime()
     * @return this
     */
    function localizedTime(string myField, string myType = "datetime", Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "localizedTime", $extra + [
            "rule": ["localizedTime", myType],
        ]);
    }

    /**
     * Add a boolean validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::boolean()
     * @return this
     */
    function boolean(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "boolean", $extra + [
            "rule": "boolean",
        ]);
    }

    /**
     * Add a decimal validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int|null $places The number of decimal places to require.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::decimal()
     * @return this
     */
    function decimal(string myField, Nullable!int $places = null, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "decimal", $extra + [
            "rule": ["decimal", $places],
        ]);
    }

    /**
     * Add an email validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param bool $checkMX Whether to check the MX records.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::email()
     * @return this
     */
    function email(string myField, bool $checkMX = false, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "email", $extra + [
            "rule": ["email", $checkMX],
        ]);
    }

    /**
     * Add an IP validation rule to a field.
     *
     * This rule will accept both IPv4 and IPv6 addresses.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::ip()
     * @return this
     */
    function ip(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "ip", $extra + [
            "rule": "ip",
        ]);
    }

    /**
     * Add an IPv4 validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::ip()
     * @return this
     */
    function ipv4(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "ipv4", $extra + [
            "rule": ["ip", "ipv4"],
        ]);
    }

    /**
     * Add an IPv6 validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::ip()
     * @return this
     */
    function ipv6(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "ipv6", $extra + [
            "rule": ["ip", "ipv6"],
        ]);
    }

    /**
     * Add a string length validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int $min The minimum length required.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::minLength()
     * @return this
     */
    function minLength(string myField, int $min, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "minLength", $extra + [
            "rule": ["minLength", $min],
        ]);
    }

    /**
     * Add a string length validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int $min The minimum length required.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::minLengthBytes()
     * @return this
     */
    function minLengthBytes(string myField, int $min, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "minLengthBytes", $extra + [
            "rule": ["minLengthBytes", $min],
        ]);
    }

    /**
     * Add a string length validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int $max The maximum length allowed.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::maxLength()
     * @return this
     */
    function maxLength(string myField, int $max, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "maxLength", $extra + [
            "rule": ["maxLength", $max],
        ]);
    }

    /**
     * Add a string length validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param int $max The maximum length allowed.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::maxLengthBytes()
     * @return this
     */
    function maxLengthBytes(string myField, int $max, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "maxLengthBytes", $extra + [
            "rule": ["maxLengthBytes", $max],
        ]);
    }

    /**
     * Add a numeric value validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::numeric()
     * @return this
     */
    function numeric(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "numeric", $extra + [
            "rule": "numeric",
        ]);
    }

    /**
     * Add a natural number validation rule to a field.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::naturalNumber()
     * @return this
     */
    function naturalNumber(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "naturalNumber", $extra + [
            "rule": ["naturalNumber", false],
        ]);
    }

    /**
     * Add a validation rule to ensure a field is a non negative integer.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::naturalNumber()
     * @return this
     */
    function nonNegativeInteger(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "nonNegativeInteger", $extra + [
            "rule": ["naturalNumber", true],
        ]);
    }

    /**
     * Add a validation rule to ensure a field is within a numeric range
     *
     * @param string myField The field you want to apply the rule to.
     * @param array $range The inclusive upper and lower bounds of the valid range.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::range()
     * @return this
     * @throws \InvalidArgumentException
     */
    function range(string myField, array $range, Nullable!string myMessage = null, $when = null) {
        if (count($range) != 2) {
            throw new InvalidArgumentException("The $range argument requires 2 numbers");
        }
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "range", $extra + [
            "rule": ["range", array_shift($range), array_shift($range)],
        ]);
    }

    /**
     * Add a validation rule to ensure a field is a URL.
     *
     * This validator does not require a protocol.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::url()
     * @return this
     */
    function url(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "url", $extra + [
            "rule": ["url", false],
        ]);
    }

    /**
     * Add a validation rule to ensure a field is a URL.
     *
     * This validator requires the URL to have a protocol.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::url()
     * @return this
     */
    function urlWithProtocol(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "urlWithProtocol", $extra + [
            "rule": ["url", true],
        ]);
    }

    /**
     * Add a validation rule to ensure the field value is within an allowed list.
     *
     * @param string myField The field you want to apply the rule to.
     * @param array $list The list of valid options.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::inList()
     * @return this
     */
    function inList(string myField, array $list, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "inList", $extra + [
            "rule": ["inList", $list],
        ]);
    }

    /**
     * Add a validation rule to ensure the field is a UUID
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::uuid()
     * @return this
     */
    function uuid(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "uuid", $extra + [
            "rule": "uuid",
        ]);
    }

    /**
     * Add a validation rule to ensure the field is an uploaded file
     *
     * @param string myField The field you want to apply the rule to.
     * @param array<string, mixed> myOptions An array of options.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::uploadedFile() For options
     * @return this
     */
    function uploadedFile(string myField, array myOptions, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "uploadedFile", $extra + [
            "rule": ["uploadedFile", myOptions],
        ]);
    }

    /**
     * Add a validation rule to ensure the field is a lat/long tuple.
     *
     * e.g. `<lat>, <lng>`
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::uuid()
     * @return this
     */
    function latLong(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "latLong", $extra + [
            "rule": "geoCoordinate",
        ]);
    }

    /**
     * Add a validation rule to ensure the field is a latitude.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::latitude()
     * @return this
     */
    function latitude(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "latitude", $extra + [
            "rule": "latitude",
        ]);
    }

    /**
     * Add a validation rule to ensure the field is a longitude.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::longitude()
     * @return this
     */
    function longitude(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "longitude", $extra + [
            "rule": "longitude",
        ]);
    }

    /**
     * Add a validation rule to ensure a field contains only ascii bytes
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::ascii()
     * @return this
     */
    function ascii(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "ascii", $extra + [
            "rule": "ascii",
        ]);
    }

    /**
     * Add a validation rule to ensure a field contains only BMP utf8 bytes
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::utf8()
     * @return this
     */
    function utf8(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "utf8", $extra + [
            "rule": ["utf8", ["extended": false]],
        ]);
    }

    /**
     * Add a validation rule to ensure a field contains only utf8 bytes.
     *
     * This rule will accept 3 and 4 byte UTF8 sequences, which are necessary for emoji.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::utf8()
     * @return this
     */
    function utf8Extended(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "utf8Extended", $extra + [
            "rule": ["utf8", ["extended": true]],
        ]);
    }

    /**
     * Add a validation rule to ensure a field is an integer value.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::isInteger()
     * @return this
     */
    function integer(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "integer", $extra + [
            "rule": "isInteger",
        ]);
    }

    /**
     * Add a validation rule to ensure that a field contains an array.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::isArray()
     * @return this
     */
    function isArray(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "isArray", $extra + [
                "rule": "isArray",
            ]);
    }

    /**
     * Add a validation rule to ensure that a field contains a scalar.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::isScalar()
     * @return this
     */
    function scalar(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "scalar", $extra + [
                "rule": "isScalar",
            ]);
    }

    /**
     * Add a validation rule to ensure a field is a 6 digits hex color value.
     *
     * @param string myField The field you want to apply the rule to.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::hexColor()
     * @return this
     */
    function hexColor(string myField, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "hexColor", $extra + [
            "rule": "hexColor",
        ]);
    }

    /**
     * Add a validation rule for a multiple select. Comparison is case sensitive by default.
     *
     * @param string myField The field you want to apply the rule to.
     * @param array<string, mixed> myOptions The options for the validator. Includes the options defined in
     *   \Cake\Validation\Validation::multiple() and the `caseInsensitive` parameter.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::multiple()
     * @return this
     */
    function multipleOptions(string myField, array myOptions = [], Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);
        $caseInsensitive = myOptions["caseInsensitive"] ?? false;
        unset(myOptions["caseInsensitive"]);

        return this.add(myField, "multipleOptions", $extra + [
            "rule": ["multiple", myOptions, $caseInsensitive],
        ]);
    }

    /**
     * Add a validation rule to ensure that a field is an array containing at least
     * the specified amount of elements
     *
     * @param string myField The field you want to apply the rule to.
     * @param int myCount The number of elements the array should at least have
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::numElements()
     * @return this
     */
    function hasAtLeast(string myField, int myCount, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "hasAtLeast", $extra + [
            "rule": function (myValue) use (myCount) {
                if (is_array(myValue) && isset(myValue["_ids"])) {
                    myValue = myValue["_ids"];
                }

                return Validation::numElements(myValue, Validation::COMPARE_GREATER_OR_EQUAL, myCount);
            },
        ]);
    }

    /**
     * Add a validation rule to ensure that a field is an array containing at most
     * the specified amount of elements
     *
     * @param string myField The field you want to apply the rule to.
     * @param int myCount The number maximum amount of elements the field should have
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @see uim.cake.Validation\Validation::numElements()
     * @return this
     */
    function hasAtMost(string myField, int myCount, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "hasAtMost", $extra + [
            "rule": function (myValue) use (myCount) {
                if (is_array(myValue) && isset(myValue["_ids"])) {
                    myValue = myValue["_ids"];
                }

                return Validation::numElements(myValue, Validation::COMPARE_LESS_OR_EQUAL, myCount);
            },
        ]);
    }

    /**
     * Returns whether a field can be left empty for a new or already existing
     * record.
     *
     * @param string myField Field name.
     * @param bool $newRecord whether the data to be validated is new or to be updated.
     */
    bool isEmptyAllowed(string myField, bool $newRecord) {
        $providers = _providers;
        myData = [];
        $context = compact("data", "newRecord", "field", "providers");

        return _canBeEmpty(this.field(myField), $context);
    }

    /**
     * Returns whether a field can be left out for a new or already existing
     * record.
     *
     * @param string myField Field name.
     * @param bool $newRecord Whether the data to be validated is new or to be updated.
     */
    bool isPresenceRequired(string myField, bool $newRecord) {
        $providers = _providers;
        myData = [];
        $context = compact("data", "newRecord", "field", "providers");

        return !_checkPresence(this.field(myField), $context);
    }

    /**
     * Returns whether a field matches against a regular expression.
     *
     * @param string myField Field name.
     * @param string regex Regular expression.
     * @param string|null myMessage The error message when the rule fails.
     * @param callable|string|null $when Either "create" or "update" or a callable that returns
     *   true when the validation rule should be applied.
     * @return this
     */
    function regex(string myField, string regex, Nullable!string myMessage = null, $when = null) {
        $extra = array_filter(["on": $when, "message": myMessage]);

        return this.add(myField, "regex", $extra + [
            "rule": ["custom", $regex],
        ]);
    }

    /**
     * Gets the required message for a field
     *
     * @param string myField Field name
     * @return string|null
     */
    Nullable!string getRequiredMessage(string myField) {
        if (!isset(_fields[myField])) {
            return null;
        }

        $defaultMessage = "This field is required";
        if (_useI18n) {
            $defaultMessage = __d("cake", "This field is required");
        }

        return _presenceMessages[myField] ?? $defaultMessage;
    }

    /**
     * Gets the notEmpty message for a field
     *
     * @param string myField Field name
     * @return string|null
     */
    Nullable!string getNotEmptyMessage(string myField) {
        if (!isset(_fields[myField])) {
            return null;
        }

        $defaultMessage = "This field cannot be left empty";
        if (_useI18n) {
            $defaultMessage = __d("cake", "This field cannot be left empty");
        }

        foreach (_fields[myField] as $rule) {
            if ($rule.get("rule") == "notBlank" && $rule.get("message")) {
                return $rule.get("message");
            }
        }

        return _allowEmptyMessages[myField] ?? $defaultMessage;
    }

    /**
     * Returns false if any validation for the passed rule set should be stopped
     * due to the field missing in the data array
     *
     * @param \Cake\Validation\ValidationSet myField The set of rules for a field.
     * @param array<string, mixed> $context A key value list of data containing the validation context.
     */
    protected bool _checkPresence(ValidationSet myField, array $context) {
        $required = myField.isPresenceRequired();

        if (!is_string($required) && is_callable($required)) {
            return !$required($context);
        }

        $newRecord = $context["newRecord"];
        if (in_array($required, [static::WHEN_CREATE, static::WHEN_UPDATE], true)) {
            return ($required == static::WHEN_CREATE && !$newRecord) ||
                ($required == static::WHEN_UPDATE && $newRecord);
        }

        return !$required;
    }

    /**
     * Returns whether the field can be left blank according to `allowEmpty`
     *
     * @param \Cake\Validation\ValidationSet myField the set of rules for a field
     * @param array<string, mixed> $context a key value list of data containing the validation context.
     */
    protected bool _canBeEmpty(ValidationSet myField, array $context) {
        $allowed = myField.isEmptyAllowed();

        if (!is_string($allowed) && is_callable($allowed)) {
            return $allowed($context);
        }

        $newRecord = $context["newRecord"];
        if (in_array($allowed, [static::WHEN_CREATE, static::WHEN_UPDATE], true)) {
            $allowed = ($allowed == static::WHEN_CREATE && $newRecord) ||
                ($allowed == static::WHEN_UPDATE && !$newRecord);
        }

        return (bool)$allowed;
    }

    /**
     * Returns true if the field is empty in the passed data array
     *
     * @param mixed myData Value to check against.
     * @return bool
     * @deprecated 3.7.0 Use {@link isEmpty()} instead
     */
    protected bool _fieldIsEmpty(myData) {
        return this.isEmpty(myData, static::EMPTY_ALL);
    }

    /**
     * Returns true if the field is empty in the passed data array
     *
     * @param mixed myData Value to check against.
     * @param int $flags A bitmask of EMPTY_* flags which specify what is empty
     */
    protected bool isEmpty(myData, int $flags) {
        if (myData is null) {
            return true;
        }

        if (myData == "" && ($flags & self::EMPTY_STRING)) {
            return true;
        }

        $arrayTypes = self::EMPTY_ARRAY | self::EMPTY_DATE | self::EMPTY_TIME;
        if (myData == [] && ($flags & $arrayTypes)) {
            return true;
        }

        if (is_array(myData)) {
            if (
                ($flags & self::EMPTY_FILE)
                && isset(myData["name"], myData["type"], myData["tmp_name"], myData["error"])
                && (int)myData["error"] == UPLOAD_ERR_NO_FILE
            ) {
                return true;
            }

            $allFieldsAreEmpty = true;
            foreach (myData as myField) {
                if (myField  !is null && myField != "") {
                    $allFieldsAreEmpty = false;
                    break;
                }
            }

            if ($allFieldsAreEmpty) {
                if (($flags & self::EMPTY_DATE) && isset(myData["year"])) {
                    return true;
                }

                if (($flags & self::EMPTY_TIME) && isset(myData["hour"])) {
                    return true;
                }
            }
        }

        if (
            ($flags & self::EMPTY_FILE)
            && myData instanceof UploadedFileInterface
            && myData.getError() == UPLOAD_ERR_NO_FILE
        ) {
            return true;
        }

        return false;
    }

    /**
     * Iterates over each rule in the validation set and collects the errors resulting
     * from executing them
     *
     * @param string myField The name of the field that is being processed
     * @param \Cake\Validation\ValidationSet $rules the list of rules for a field
     * @param array myData the full data passed to the validator
     * @param bool $newRecord whether is it a new record or an existing one
     * @return array<string, mixed>
     */
    protected auto _processRules(string myField, ValidationSet $rules, array myData, bool $newRecord): array
    {
        myErrors = [];
        // Loading default provider in case there is none
        this.getProvider("default");
        myMessage = "The provided value is invalid";

        if (_useI18n) {
            myMessage = __d("cake", "The provided value is invalid");
        }

        /**
         * @var uim.cake.Validation\ValidationRule $rule
         */
        foreach ($rules as myName: $rule) {
            myResult = $rule.process(myData[myField], _providers, compact("newRecord", "data", "field"));
            if (myResult == true) {
                continue;
            }

            myErrors[myName] = myMessage;
            if (is_array(myResult) && myName == static::NESTED) {
                myErrors = myResult;
            }
            if (is_string(myResult)) {
                myErrors[myName] = myResult;
            }

            if ($rule.isLast()) {
                break;
            }
        }

        return myErrors;
    }

    /**
     * Get the printable version of this object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        myFields = [];
        foreach (_fields as myName: myFieldSet) {
            myFields[myName] = [
                "isPresenceRequired": myFieldSet.isPresenceRequired(),
                "isEmptyAllowed": myFieldSet.isEmptyAllowed(),
                "rules": array_keys(myFieldSet.rules()),
            ];
        }

        return [
            "_presenceMessages": _presenceMessages,
            "_allowEmptyMessages": _allowEmptyMessages,
            "_allowEmptyFlags": _allowEmptyFlags,
            "_useI18n": _useI18n,
            "_stopOnFailure": _stopOnFailure,
            "_providers": array_keys(_providers),
            "_fields": myFields,
        ];
    }
}
