


 *


 * @since         3.0.0
  */
module uim.cake.View\Form;

/**
 * Interface for FormHelper context implementations.
 */
interface ContextInterface
{
    /**
     * @var array<string>
     */
    public const VALID_ATTRIBUTES = ["length", "precision", "comment", "null", "default"];

    /**
     * Get the fields used in the context as a primary key.
     *
     * @return array<string>
     */
    function getPrimaryKey(): array;

    /**
     * Returns true if the passed field name is part of the primary key for this context
     *
     * @param string $field A dot separated path to the field a value
     *   is needed for.
     * @return bool
     */
    function isPrimaryKey(string $field): bool;

    /**
     * Returns whether this form is for a create operation.
     *
     * @return bool
     */
    function isCreate(): bool;

    /**
     * Get the current value for a given field.
     *
     * Classes implementing this method can optionally have a second argument
     * `$options`. Valid key for `$options` array are:
     *
     *   - `default`: Default value to return if no value found in data or
     *     context record.
     *   - `schemaDefault`: Boolean indicating whether default value from
     *     context"s schema should be used if it"s not explicitly provided.
     *
     * @param string $field A dot separated path to the field a value
     * @param array<string, mixed> $options Options.
     *   is needed for.
     * @return mixed
     */
    function val(string $field, array $options = []);

    /**
     * Check if a given field is "required".
     *
     * In this context class, this is simply defined by the "required" array.
     *
     * @param string $field A dot separated path to check required-ness for.
     * @return bool|null
     */
    function isRequired(string $field): ?bool;

    /**
     * Gets the default "required" error message for a field
     *
     * @param string $field A dot separated path to the field name
     * @return string|null
     */
    function getRequiredMessage(string $field): ?string;

    /**
     * Get maximum length of a field from model validation.
     *
     * @param string $field Field name.
     * @return int|null
     */
    function getMaxLength(string $field): ?int;

    /**
     * Get the field names of the top level object in this context.
     *
     * @return array<string> A list of the field names in the context.
     */
    function fieldNames(): array;

    /**
     * Get the abstract field type for a given field name.
     *
     * @param string $field A dot separated path to get a schema type for.
     * @return string|null An abstract data type or null.
     * @see uim.cake.Database\TypeFactory
     */
    function type(string $field): ?string;

    /**
     * Get an associative array of other attributes for a field name.
     *
     * @param string $field A dot separated path to get additional data on.
     * @return array An array of data describing the additional attributes on a field.
     */
    function attributes(string $field): array;

    /**
     * Check whether a field has an error attached to it
     *
     * @param string $field A dot separated path to check errors on.
     * @return bool Returns true if the errors for the field are not empty.
     */
    function hasError(string $field): bool;

    /**
     * Get the errors for a given field
     *
     * @param string $field A dot separated path to check errors on.
     * @return array An array of errors, an empty array will be returned when the
     *    context has no errors.
     */
    function error(string $field): array;
}
