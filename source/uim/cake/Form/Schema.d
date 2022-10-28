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
        'type' => null,
        'length' => null,
        'precision' => null,
        'default' => null,
    ];

    /**
     * Add multiple fields to the schema.
     *
     * @param array<string, array<string, mixed>|string> myFields The fields to add.
     * @return this
     */
    function addFields(array myFields) {
        foreach (myFields as myName => $attrs) {
            this.addField(myName, $attrs);
        }

        return this;
    }

    /**
     * Adds a field to the schema.
     *
     * @param string myName The field name.
     * @param array<string, mixed>|string $attrs The attributes for the field, or the type
     *   as a string.
     * @return this
     */
    function addField(string myName, $attrs) {
        if (is_string($attrs)) {
            $attrs = ['type' => $attrs];
        }
        $attrs = array_intersect_key($attrs, this._fieldDefaults);
        this._fields[myName] = $attrs + this._fieldDefaults;

        return this;
    }

    /**
     * Removes a field to the schema.
     *
     * @param string myName The field to remove.
     * @return this
     */
    function removeField(string myName) {
        unset(this._fields[myName]);

        return this;
    }

    /**
     * Get the list of fields in the schema.
     *
     * @return array<string> The list of field names.
     */
    function fields(): array
    {
        return array_keys(this._fields);
    }

    /**
     * Get the attributes for a given field.
     *
     * @param string myName The field name.
     * @return array<string, mixed>|null The attributes for a field, or null.
     */
    function field(string myName): ?array
    {
        return this._fields[myName] ?? null;
    }

    /**
     * Get the type of the named field.
     *
     * @param string myName The name of the field.
     * @return string|null Either the field type or null if the
     *   field does not exist.
     */
    function fieldType(string myName): ?string
    {
        myField = this.field(myName);
        if (!myField) {
            return null;
        }

        return myField['type'];
    }

    /**
     * Get the printable version of this object
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            '_fields' => this._fields,
        ];
    }
}
