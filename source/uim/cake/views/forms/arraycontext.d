module uim.cake.views.forms;

import uim.cakeilities.Hash;

/**
 * Provides a basic array based context provider for FormHelper.
 *
 * This adapter is useful in testing or when you have forms backed by
 * simple array data structures.
 *
 * Important keys:
 *
 * - `data` Holds the current values supplied for the fields.
 * - `defaults` The default values for fields. These values
 *   will be used when there is no data set. Data should be nested following
 *   the dot separated paths you access your fields with.
 * - `required` A nested array of fields, relationships and boolean
 *   flags to indicate a field is required. The value can also be a string to be used
 *   as the required error message
 * - `schema` An array of data that emulate the column structures that
 *   Cake\Database\Schema\Schema uses. This array allows you to control
 *   the inferred type for fields and allows auto generation of attributes
 *   like maxlength, step and other HTML attributes. If you want
 *   primary key/id detection to work. Make sure you have provided a `_constraints`
 *   array that contains `primary`. See below for an example.
 * - `errors` An array of validation errors. Errors should be nested following
 *   the dot separated paths you access your fields with.
 *
 *  ### Example
 *
 *  ```
 *  $article = [
 *    "data" => [
 *      "id" => "1",
 *      "title" => "First post!",
 *    ],
 *    "schema" => [
 *      "id" => ["type" => "integer"],
 *      "title" => ["type" => "string", "length" => 255],
 *      "_constraints" => [
 *        "primary" => ["type" => "primary", "columns" => ["id"]]
 *      ]
 *    ],
 *    "defaults" => [
 *      "title" => "Default title",
 *    ],
 *    "required" => [
 *      "id" => true, // will use default required message
 *      "title" => "Please enter a title",
 *      "body" => false,
 *    ],
 *  ];
 *  ```
 */
class ArrayContext : IContext
{
    /**
     * Context data for this object.
     *
     * @var array
     */
    protected $_context;

    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
        $context += [
            "data" => [],
            "schema" => [],
            "required" => [],
            "defaults" => [],
            "errors" => [],
        ];
        this._context = $context;
    }

    /**
     * Get the fields used in the context as a primary key.
     *
     * @return array<string>
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    function primaryKey(): array
    {
        deprecationWarning("`ArrayContext::primaryKey()` is deprecated. Use `ArrayContext::getPrimaryKey()`.");

        return this.getPrimaryKey();
    }

    /**
     * Get the fields used in the context as a primary key.
     *
     * @return array<string>
     */
    auto getPrimaryKey(): array
    {
        if (
            empty(this._context["schema"]["_constraints"]) ||
            !is_array(this._context["schema"]["_constraints"])
        ) {
            return [];
        }
        foreach (this._context["schema"]["_constraints"] as myData) {
            if (isset(myData["type"]) && myData["type"] === "primary") {
                return (array)(myData["columns"] ?? []);
            }
        }

        return [];
    }


    bool isPrimaryKey(string myField) {
        $primaryKey = this.getPrimaryKey();

        return in_array(myField, $primaryKey, true);
    }

    /**
     * Returns whether this form is for a create operation.
     *
     * For this method to return true, both the primary key constraint
     * must be defined in the "schema" data, and the "defaults" data must
     * contain a value for all fields in the key.
     *
     * @return bool
     */
    bool isCreate() {
        $primary = this.getPrimaryKey();
        foreach ($primary as $column) {
            if (!empty(this._context["defaults"][$column])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Get the current value for a given field.
     *
     * This method will coalesce the current data and the "defaults" array.
     *
     * @param string myField A dot separated path to the field a value
     *   is needed for.
     * @param array<string, mixed> myOptions Options:
     *
     *   - `default`: Default value to return if no value found in data or
     *     context record.
     *   - `schemaDefault`: Boolean indicating whether default value from
     *     context"s schema should be used if it"s not explicitly provided.
     * @return mixed
     */
    function val(string myField, array myOptions = []) {
        myOptions += [
            "default" => null,
            "schemaDefault" => true,
        ];

        if (Hash::check(this._context["data"], myField)) {
            return Hash::get(this._context["data"], myField);
        }

        if (myOptions["default"] !== null || !myOptions["schemaDefault"]) {
            return myOptions["default"];
        }
        if (empty(this._context["defaults"]) || !is_array(this._context["defaults"])) {
            return null;
        }

        // Using Hash::check here incase the default value is actually null
        if (Hash::check(this._context["defaults"], myField)) {
            return Hash::get(this._context["defaults"], myField);
        }

        return Hash::get(this._context["defaults"], this.stripNesting(myField));
    }

    /**
     * Check if a given field is "required".
     *
     * In this context class, this is simply defined by the "required" array.
     *
     * @param string myField A dot separated path to check required-ness for.
     * @return bool|null
     */
    function isRequired(string myField): ?bool
    {
        if (!is_array(this._context["required"])) {
            return null;
        }

        $required = Hash::get(this._context["required"], myField);

        if ($required === null) {
            $required = Hash::get(this._context["required"], this.stripNesting(myField));
        }

        if (!empty($required) || $required === "0") {
            return true;
        }

        return $required;
    }


    auto getRequiredMessage(string myField): Nullable!string
    {
        if (!is_array(this._context["required"])) {
            return null;
        }
        $required = Hash::get(this._context["required"], myField);
        if ($required === null) {
            $required = Hash::get(this._context["required"], this.stripNesting(myField));
        }

        if ($required === false) {
            return null;
        }

        if ($required === true) {
            $required = __d("cake", "This field cannot be left empty");
        }

        return $required;
    }

    /**
     * Get field length from validation
     *
     * In this context class, this is simply defined by the "length" array.
     *
     * @param string myField A dot separated path to check required-ness for.
     * @return int|null
     */
    auto getMaxLength(string myField): Nullable!int
    {
        if (!is_array(this._context["schema"])) {
            return null;
        }

        return Hash::get(this._context["schema"], "myField.length");
    }


    function fieldNames(): array
    {
        $schema = this._context["schema"];
        unset($schema["_constraints"], $schema["_indexes"]);

        return array_keys($schema);
    }

    /**
     * Get the abstract field type for a given field name.
     *
     * @param string myField A dot separated path to get a schema type for.
     * @return string|null An abstract data type or null.
     * @see \Cake\Database\TypeFactory
     */
    function type(string myField): Nullable!string
    {
        if (!is_array(this._context["schema"])) {
            return null;
        }

        $schema = Hash::get(this._context["schema"], myField);
        if ($schema === null) {
            $schema = Hash::get(this._context["schema"], this.stripNesting(myField));
        }

        return $schema["type"] ?? null;
    }

    /**
     * Get an associative array of other attributes for a field name.
     *
     * @param string myField A dot separated path to get additional data on.
     * @return array An array of data describing the additional attributes on a field.
     */
    function attributes(string myField): array
    {
        if (!is_array(this._context["schema"])) {
            return [];
        }
        $schema = Hash::get(this._context["schema"], myField);
        if ($schema === null) {
            $schema = Hash::get(this._context["schema"], this.stripNesting(myField));
        }

        return array_intersect_key(
            (array)$schema,
            array_flip(static::VALID_ATTRIBUTES)
        );
    }

    /**
     * Check whether a field has an error attached to it
     *
     * @param string myField A dot separated path to check errors on.
     * @return bool Returns true if the errors for the field are not empty.
     */
    bool hasError(string myField) {
        if (empty(this._context["errors"])) {
            return false;
        }

        return Hash::check(this._context["errors"], myField);
    }

    /**
     * Get the errors for a given field
     *
     * @param string myField A dot separated path to check errors on.
     * @return array An array of errors, an empty array will be returned when the
     *    context has no errors.
     */
    function error(string myField): array
    {
        if (empty(this._context["errors"])) {
            return [];
        }

        return (array)Hash::get(this._context["errors"], myField);
    }

    /**
     * Strips out any numeric nesting
     *
     * For example users.0.age will output as users.age
     *
     * @param string myField A dot separated path
     * @return string A string with stripped numeric nesting
     */
    protected auto stripNesting(string myField): string
    {
        return preg_replace("/\.\d*\./", ".", myField);
    }
}
