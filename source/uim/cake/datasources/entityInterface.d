module uim.cake.datasources;

use ArrayAccess;
use JsonSerializable;

/**
 * Describes the methods that any class representing a data storage should
 * comply with.
 *
 * @property mixed $id Alias for commonly used primary key.
 * @method bool[] getAccessible() Accessible configuration for this entity.
 */
interface IEntity : ArrayAccess, JsonSerializable
{
    /**
     * Sets hidden fields.
     *
     * @param array<string> myFields An array of fields to hide from array exports.
     * @param bool myMerge Merge the new fields with the existing. By default false.
     * @return this
     */
    auto setHidden(array myFields, bool myMerge = false);

    /**
     * Gets the hidden fields.
     */
    string[] getHidden();

    /**
     * Sets the virtual fields on this entity.
     *
     * @param array<string> myFields An array of fields to treat as virtual.
     * @param bool myMerge Merge the new fields with the existing. By default false.
     * @return this
     */
    auto setVirtual(string[] myFields, bool myMerge = false);

    // Gets the virtual fields on this entity.aaa
    string[] getVirtual();

    /**
     * Sets the dirty status of a single field.
     *
     * @param string myField the field to set or check status for
     * @param bool $isDirty true means the field was changed, false means
     * it was not changed. Default true.
     * @return this
     */
    auto setDirty(string myField, bool $isDirty = true);

    /**
     * Checks if the entity is dirty or if a single field of it is dirty.
     *
     * @param string|null myField The field to check the status for. Null for the whole entity.
     * @return bool Whether the field was changed or not
     */
    bool isDirty(Nullable!string myField = null);

    // Gets the dirty fields.
    string[] getDirty();

    /**
     * Returns whether this entity has errors.
     *
     * @param bool $includeNested true will check nested entities for hasErrors()
     */
    bool hasErrors(bool $includeNested = true);

    /**
     * Returns all validation errors.
     *
     * @return array
     */
    auto getErrors(): array;

    /**
     * Returns validation errors of a field
     *
     * @param string myField Field name to get the errors from
     * @return array
     */
    auto getError(string myField): array;

    /**
     * Sets error messages to the entity
     *
     * @param array myErrors The array of errors to set.
     * @param bool $overwrite Whether to overwrite pre-existing errors for myFields
     * @return this
     */
    auto setErrors(array myErrors, bool $overwrite = false);

    /**
     * Sets errors for a single field
     *
     * @param string myField The field to get errors for, or the array of errors to set.
     * @param array|string myErrors The errors to be set for myField
     * @param bool $overwrite Whether to overwrite pre-existing errors for myField
     * @return this
     */
    auto setError(string myField, myErrors, bool $overwrite = false);

    /**
     * Stores whether a field value can be changed or set in this entity.
     *
     * @param array<string>|string myField single or list of fields to change its accessibility
     * @param bool $set true marks the field as accessible, false will
     * mark it as protected.
     * @return this
     */
    auto setAccess(myField, bool $set);

    /**
     * Checks if a field is accessible
     *
     * @param string myField Field name to check
     */
    bool isAccessible(string myField);

    /**
     * Sets the source alias
     *
     * @param string myAlias the alias of the repository
     * @return this
     */
    auto setSource(string myAlias);

    // Returns the alias of the repository from which this entity came from.
    string getSource();

    /**
     * Returns an array with the requested original fields
     * stored in this entity, indexed by field name.
     *
     * @param array<string> myFields List of fields to be returned
     * @return array
     */
    function extractOriginal(array myFields): array;

    /**
     * Returns an array with only the original fields
     * stored in this entity, indexed by field name.
     *
     * @param array<string> myFields List of fields to be returned
     * @return array
     */
    function extractOriginalChanged(array myFields): array;

    /**
     * Sets one or multiple fields to the specified value
     *
     * @param array<string, mixed>|string myField the name of field to set or a list of
     * fields with their respective values
     * @param mixed myValue The value to set to the field or an array if the
     * first argument is also an array, in which case will be treated as myOptions
     * @param array<string, mixed> myOptions Options to be used for setting the field. Allowed option
     * keys are `setter` and `guard`
     * @return this
     */
    auto set(myField, myValue = null, array myOptions = []);

    /**
     * Returns the value of a field by name
     *
     * @param string myField the name of the field to retrieve
     * @return mixed
     */
    function &get(string myField);

    /**
     * Returns the original value of a field.
     *
     * @param string myField The name of the field.
     * @return mixed
     */
    auto getOriginal(string myField);

    /**
     * Gets all original values of the entity.
     *
     * @return array
     */
    auto getOriginalValues(): array;

    // Returns whether this entity contains a field named myField regardless of if it is empty.
    // array<string>|string myField The field to check.
    bool has(string[] myFields...);

    /**
     * Removes a field or list of fields from this entity
     *
     * @param array<string>|string myField The field to unset.
     * @return this
     */
    O unset(this O)(string[] myFields...);

    /**
     * Get the list of visible fields.
     * @return A list of fields that are "visible" in all representations.
     */
    string[] getVisible();

    /**
     * Returns an array with all the visible fields set in this entity.
     *
     * *Note* hidden fields are not visible, and will not be output
     * by toArray().
     *
     * @return array
     */
    function toArray(): array;

    /**
     * Returns an array with the requested fields
     * stored in this entity, indexed by field name
     *
     * @param array<string> myFields list of fields to be returned
     * @param bool $onlyDirty Return the requested field only if it is dirty
     * @return array
     */
    function extract(array myFields, bool $onlyDirty = false): array;

    /**
     * Sets the entire entity as clean, which means that it will appear as
     * no fields being modified or added at all. This is an useful call
     * for an initial object hydration
     */
    void clean();

    /**
     * Set the status of this entity.
     *
     * Using `true` means that the entity has not been persisted in the database,
     * `false` indicates that the entity has been persisted.
     *
     * @param bool $new Indicate whether this entity has been persisted.
     * @return this
     */
    auto setNew(bool $new);

    /**
     * Returns whether this entity has already been persisted.
     * @return bool Whether the entity has been persisted.
     */
    bool isNew();
}
