module uim.cake.Datasource;

use ArrayAccess;
use JsonSerializable;

/**
 * Describes the methods that any class representing a data storage should
 * comply with.
 *
 * @property mixed $id Alias for commonly used primary key.
 * @method bool[] getAccessible() Accessible configuration for this entity.
 */
interface EntityInterface : ArrayAccess, JsonSerializable
{
    /**
     * Sets hidden fields.
     *
     * @param array<string> $fields An array of fields to hide from array exports.
     * @param bool $merge Merge the new fields with the existing. By default false.
     * @return this
     */
    function setHidden(array $fields, bool $merge = false);

    /**
     * Gets the hidden fields.
     *
     * @return array<string>
     */
    function getHidden(): array;

    /**
     * Sets the virtual fields on this entity.
     *
     * @param array<string> $fields An array of fields to treat as virtual.
     * @param bool $merge Merge the new fields with the existing. By default false.
     * @return this
     */
    function setVirtual(array $fields, bool $merge = false);

    /**
     * Gets the virtual fields on this entity.
     *
     * @return array<string>
     */
    function getVirtual(): array;

    /**
     * Sets the dirty status of a single field.
     *
     * @param string $field the field to set or check status for
     * @param bool $isDirty true means the field was changed, false means
     * it was not changed. Default true.
     * @return this
     */
    function setDirty(string $field, bool $isDirty = true);

    /**
     * Checks if the entity is dirty or if a single field of it is dirty.
     *
     * @param string|null $field The field to check the status for. Null for the whole entity.
     * @return bool Whether the field was changed or not
     */
    function isDirty(?string $field = null): bool;

    /**
     * Gets the dirty fields.
     *
     * @return array<string>
     */
    function getDirty(): array;

    /**
     * Returns whether this entity has errors.
     *
     * @param bool $includeNested true will check nested entities for hasErrors()
     * @return bool
     */
    function hasErrors(bool $includeNested = true): bool;

    /**
     * Returns all validation errors.
     */
    array getErrors(): array;

    /**
     * Returns validation errors of a field
     *
     * @param string $field Field name to get the errors from
     */
    array getError(string $field): array;

    /**
     * Sets error messages to the entity
     *
     * @param array $errors The array of errors to set.
     * @param bool $overwrite Whether to overwrite pre-existing errors for $fields
     * @return this
     */
    function setErrors(array $errors, bool $overwrite = false);

    /**
     * Sets errors for a single field
     *
     * @param string $field The field to get errors for, or the array of errors to set.
     * @param array|string $errors The errors to be set for $field
     * @param bool $overwrite Whether to overwrite pre-existing errors for $field
     * @return this
     */
    function setError(string $field, $errors, bool $overwrite = false);

    /**
     * Stores whether a field value can be changed or set in this entity.
     *
     * @param array<string>|string $field single or list of fields to change its accessibility
     * @param bool $set true marks the field as accessible, false will
     * mark it as protected.
     * @return this
     */
    function setAccess($field, bool $set);

    /**
     * Checks if a field is accessible
     *
     * @param string $field Field name to check
     * @return bool
     */
    function isAccessible(string $field): bool;

    /**
     * Sets the source alias
     *
     * @param string $alias the alias of the repository
     * @return this
     */
    function setSource(string $alias);

    // Returns the alias of the repository from which this entity came from.
    string getSource();

    /**
     * Returns an array with the requested original fields
     * stored in this entity, indexed by field name.
     *
     * @param array<string> $fields List of fields to be returned
     */
    array extractOriginal(array $fields): array;

    /**
     * Returns an array with only the original fields
     * stored in this entity, indexed by field name.
     *
     * @param array<string> $fields List of fields to be returned
     */
    array extractOriginalChanged(array $fields): array;

    /**
     * Sets one or multiple fields to the specified value
     *
     * @param array<string, mixed>|string $field the name of field to set or a list of
     * fields with their respective values
     * @param mixed $value The value to set to the field or an array if the
     * first argument is also an array, in which case will be treated as $options
     * @param array<string, mixed> $options Options to be used for setting the field. Allowed option
     * keys are `setter` and `guard`
     * @return this
     */
    function set($field, $value = null, array $options = []);

    /**
     * Returns the value of a field by name
     *
     * @param string $field the name of the field to retrieve
     * @return mixed
     */
    function &get(string $field);

    /**
     * Returns the original value of a field.
     *
     * @param string $field The name of the field.
     * @return mixed
     */
    function getOriginal(string $field);

    /**
     * Gets all original values of the entity.
     */
    array getOriginalValues(): array;

    /**
     * Returns whether this entity contains a field named $field
     * and is not set to null.
     *
     * @param array<string>|string $field The field to check.
     * @return bool
     */
    function has($field): bool;

    /**
     * Removes a field or list of fields from this entity
     *
     * @param array<string>|string $field The field to unset.
     * @return this
     */
    function unset($field);

    /**
     * Get the list of visible fields.
     *
     * @return array<string> A list of fields that are "visible" in all representations.
     */
    string[] getVisible(): array;

    /**
     * Returns an array with all the visible fields set in this entity.
     *
     * *Note* hidden fields are not visible, and will not be output
     * by toArray().
     */
    array toArray(): array;

    /**
     * Returns an array with the requested fields
     * stored in this entity, indexed by field name
     *
     * @param array<string> $fields list of fields to be returned
     * @param bool $onlyDirty Return the requested field only if it is dirty
     */
    array extract(array $fields, bool $onlyDirty = false): array;

    /**
     * Sets the entire entity as clean, which means that it will appear as
     * no fields being modified or added at all. This is an useful call
     * for an initial object hydration
     */
    void clean(): void;

    /**
     * Set the status of this entity.
     *
     * Using `true` means that the entity has not been persisted in the database,
     * `false` indicates that the entity has been persisted.
     *
     * @param bool $new Indicate whether this entity has been persisted.
     * @return this
     */
    function setNew(bool $new);

    /**
     * Returns whether this entity has already been persisted.
     *
     * @return bool Whether the entity has been persisted.
     */
    function isNew(): bool;
}