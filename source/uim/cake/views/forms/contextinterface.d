module uim.cake.views.forms;

/**
 * Interface for FormHelper context implementations.
 */
interface IContext
{
    /**
     * @var array<string>
     */
    public const VALID_ATTRIBUTES = ["length", "precision", "comment", "null", "default"];

    /**
     * Get the fields used in the context as a primary key.
     */
    string[] primaryKeys();

    /**
     * Returns true if the passed field name is part of the primary key for this context
     *
     * @param string myField A dot separated path to the field a value
     *   is needed for.
     */
    bool isPrimaryKey(string myField);

    // Returns whether this form is for a create operation.
    bool isCreate();

    /**
     * Get the current value for a given field.
     *
     * Classes implementing this method can optionally have a second argument
     * `myOptions`. Valid key for `myOptions` array are:
     *
     *   - `default`: Default value to return if no value found in data or
     *     context record.
     *   - `schemaDefault`: Boolean indicating whether default value from
     *     context"s schema should be used if it"s not explicitly provided.
     *
     * @param string myField A dot separated path to the field a value
     * @param array<string, mixed> myOptions Options.
     *   is needed for.
     * @return mixed
     */
    function val(string myField, array myOptions = []);

    /**
     * Check if a given field is "required".
     *
     * In this context class, this is simply defined by the "required" array.
     *
     * @param string myField A dot separated path to check required-ness for.
     * @return bool|null
     */
    function isRequired(string myField): ?bool;

    /**
     * Gets the default "required" error message for a field
     *
     * @param string myField A dot separated path to the field name
     * @return string|null
     */
    Nullable!string getRequiredMessage(string myField);

    /**
     * Get maximum length of a field from model validation.
     *
     * @param string myField Field name.
     * @return int|null
     */
    Nullable!int getMaxLength(string myField);

    /**
     * Get the field names of the top level object in this context.
     *
     * @return A list of the field names in the context.
     */
    string[] fieldNames();

    /**
     * Get the abstract field type for a given field name.
     *
     * @param string myField A dot separated path to get a schema type for.
     * @return string|null An abstract data type or null.
     * @see \Cake\Database\TypeFactory
     */
    Nullable!string type(string myField);

    /**
     * Get an associative array of other attributes for a field name.
     *
     * @param string myField A dot separated path to get additional data on.
     * @return array An array of data describing the additional attributes on a field.
     */
    function attributes(string myField): array;

    /**
     * Check whether a field has an error attached to it
     *
     * @param string myField A dot separated path to check errors on.
     * @return Returns true if the errors for the field are not empty.
     */
    bool hasError(string myField);

    /**
     * Get the errors for a given field
     *
     * @param string myField A dot separated path to check errors on.
     * @return array An array of errors, an empty array will be returned when the
     *    context has no errors.
     */
    function error(string myField): array;
}
