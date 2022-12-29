


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Form;

/**
 * Contains the schema information for Form instances.
 */
class Schema
{
    /**
     * The fields in this schema.
     *
     * @var array<string, array<string, mixed>>
     */
    protected $_fields = [];

    /**
     * The default values for fields.
     *
     * @var array<string, mixed>
     */
    protected $_fieldDefaults = [
        "type": null,
        "length": null,
        "precision": null,
        "default": null,
    ];

    /**
     * Add multiple fields to the schema.
     *
     * @param array<string, array<string, mixed>|string> $fields The fields to add.
     * @return this
     */
    function addFields(array $fields) {
        foreach ($fields as $name: $attrs) {
            this.addField($name, $attrs);
        }

        return this;
    }

    /**
     * Adds a field to the schema.
     *
     * @param string $name The field name.
     * @param array<string, mixed>|string $attrs The attributes for the field, or the type
     *   as a string.
     * @return this
     */
    function addField(string $name, $attrs) {
        if (is_string($attrs)) {
            $attrs = ["type": $attrs];
        }
        $attrs = array_intersect_key($attrs, _fieldDefaults);
        _fields[$name] = $attrs + _fieldDefaults;

        return this;
    }

    /**
     * Removes a field to the schema.
     *
     * @param string $name The field to remove.
     * @return this
     */
    function removeField(string $name) {
        unset(_fields[$name]);

        return this;
    }

    /**
     * Get the list of fields in the schema.
     *
     * @return array<string> The list of field names.
     */
    function fields(): array
    {
        return array_keys(_fields);
    }

    /**
     * Get the attributes for a given field.
     *
     * @param string $name The field name.
     * @return array<string, mixed>|null The attributes for a field, or null.
     */
    function field(string $name): ?array
    {
        return _fields[$name] ?? null;
    }

    /**
     * Get the type of the named field.
     *
     * @param string $name The name of the field.
     * @return string|null Either the field type or null if the
     *   field does not exist.
     */
    function fieldType(string $name): ?string
    {
        $field = this.field($name);
        if (!$field) {
            return null;
        }

        return $field["type"];
    }

    /**
     * Get the printable version of this object
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        return [
            "_fields": _fields,
        ];
    }
}
