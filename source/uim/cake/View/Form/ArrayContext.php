
module uim.cake.View\Form;

import uim.cake.utilities.Hash;

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
 *    "data": [
 *      "id": "1",
 *      "title": "First post!",
 *    ],
 *    "schema": [
 *      "id": ["type": "integer"],
 *      "title": ["type": "string", "length": 255],
 *      "_constraints": [
 *        "primary": ["type": "primary", "columns": ["id"]]
 *      ]
 *    ],
 *    "defaults": [
 *      "title": "Default title",
 *    ],
 *    "required": [
 *      "id": true, // will use default required message
 *      "title": "Please enter a title",
 *      "body": false,
 *    ],
 *  ];
 *  ```
 */
class ArrayContext : ContextInterface
{
    /**
     * Context data for this object.
     *
     * @var array<string, mixed>
     */
    protected $_context;

    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
        $context += [
            "data": [],
            "schema": [],
            "required": [],
            "defaults": [],
            "errors": [],
        ];
        _context = $context;
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
    function getPrimaryKey(): array
    {
        if (
            empty(_context["schema"]["_constraints"]) ||
            !is_array(_context["schema"]["_constraints"])
        ) {
            return [];
        }
        foreach (_context["schema"]["_constraints"] as $data) {
            if (isset($data["type"]) && $data["type"] == "primary") {
                return (array)($data["columns"] ?? []);
            }
        }

        return [];
    }


    function isPrimaryKey(string $field): bool
    {
        $primaryKey = this.getPrimaryKey();

        return in_array($field, $primaryKey, true);
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
    function isCreate(): bool
    {
        $primary = this.getPrimaryKey();
        foreach ($primary as $column) {
            if (!empty(_context["defaults"][$column])) {
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
     * @param string $field A dot separated path to the field a value
     *   is needed for.
     * @param array<string, mixed> $options Options:
     *
     *   - `default`: Default value to return if no value found in data or
     *     context record.
     *   - `schemaDefault`: Boolean indicating whether default value from
     *     context"s schema should be used if it"s not explicitly provided.
     * @return mixed
     */
    function val(string $field, array $options = []) {
        $options += [
            "default": null,
            "schemaDefault": true,
        ];

        if (Hash::check(_context["data"], $field)) {
            return Hash::get(_context["data"], $field);
        }

        if ($options["default"] != null || !$options["schemaDefault"]) {
            return $options["default"];
        }
        if (empty(_context["defaults"]) || !is_array(_context["defaults"])) {
            return null;
        }

        // Using Hash::check here incase the default value is actually null
        if (Hash::check(_context["defaults"], $field)) {
            return Hash::get(_context["defaults"], $field);
        }

        return Hash::get(_context["defaults"], this.stripNesting($field));
    }

    /**
     * Check if a given field is "required".
     *
     * In this context class, this is simply defined by the "required" array.
     *
     * @param string $field A dot separated path to check required-ness for.
     * @return bool|null
     */
    function isRequired(string $field): ?bool
    {
        if (!is_array(_context["required"])) {
            return null;
        }

        $required = Hash::get(_context["required"], $field);

        if ($required == null) {
            $required = Hash::get(_context["required"], this.stripNesting($field));
        }

        if (!empty($required) || $required == "0") {
            return true;
        }

        return $required;
    }


    function getRequiredMessage(string $field): ?string
    {
        if (!is_array(_context["required"])) {
            return null;
        }
        $required = Hash::get(_context["required"], $field);
        if ($required == null) {
            $required = Hash::get(_context["required"], this.stripNesting($field));
        }

        if ($required == false) {
            return null;
        }

        if ($required == true) {
            $required = __d("cake", "This field cannot be left empty");
        }

        return $required;
    }

    /**
     * Get field length from validation
     *
     * In this context class, this is simply defined by the "length" array.
     *
     * @param string $field A dot separated path to check required-ness for.
     * @return int|null
     */
    function getMaxLength(string $field): ?int
    {
        if (!is_array(_context["schema"])) {
            return null;
        }

        return Hash::get(_context["schema"], "$field.length");
    }


    function fieldNames(): array
    {
        $schema = _context["schema"];
        unset($schema["_constraints"], $schema["_indexes"]);

        return array_keys($schema);
    }

    /**
     * Get the abstract field type for a given field name.
     *
     * @param string $field A dot separated path to get a schema type for.
     * @return string|null An abstract data type or null.
     * @see uim.cake.Database\TypeFactory
     */
    function type(string $field): ?string
    {
        if (!is_array(_context["schema"])) {
            return null;
        }

        $schema = Hash::get(_context["schema"], $field);
        if ($schema == null) {
            $schema = Hash::get(_context["schema"], this.stripNesting($field));
        }

        return $schema["type"] ?? null;
    }

    /**
     * Get an associative array of other attributes for a field name.
     *
     * @param string $field A dot separated path to get additional data on.
     * @return array An array of data describing the additional attributes on a field.
     */
    function attributes(string $field): array
    {
        if (!is_array(_context["schema"])) {
            return [];
        }
        $schema = Hash::get(_context["schema"], $field);
        if ($schema == null) {
            $schema = Hash::get(_context["schema"], this.stripNesting($field));
        }

        return array_intersect_key(
            (array)$schema,
            array_flip(static::VALID_ATTRIBUTES)
        );
    }

    /**
     * Check whether a field has an error attached to it
     *
     * @param string $field A dot separated path to check errors on.
     * @return bool Returns true if the errors for the field are not empty.
     */
    function hasError(string $field): bool
    {
        if (empty(_context["errors"])) {
            return false;
        }

        return Hash::check(_context["errors"], $field);
    }

    /**
     * Get the errors for a given field
     *
     * @param string $field A dot separated path to check errors on.
     * @return array An array of errors, an empty array will be returned when the
     *    context has no errors.
     */
    function error(string $field): array
    {
        if (empty(_context["errors"])) {
            return [];
        }

        return (array)Hash::get(_context["errors"], $field);
    }

    /**
     * Strips out any numeric nesting
     *
     * For example users.0.age will output as users.age
     *
     * @param string $field A dot separated path
     * @return string A string with stripped numeric nesting
     */
    protected function stripNesting(string $field): string
    {
        return preg_replace("/\.\d*\./", ".", $field);
    }
}
