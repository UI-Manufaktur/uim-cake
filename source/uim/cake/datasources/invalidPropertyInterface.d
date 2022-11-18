module uim.cake.datasources;

/**
 * Describes the methods that any class representing a data storage should
 * comply with.
 */
interface InvalidPropertyInterface
{
    /**
     * Get a list of invalid fields and their data for errors upon validation/patching
     *
     * @return array
     */
    auto getInvalid(): array;

    /**
     * Set fields as invalid and not patchable into the entity.
     *
     * This is useful for batch operations when one needs to get the original value for an error message after patching.
     * This value could not be patched into the entity and is simply copied into the _invalid property for debugging
     * purposes or to be able to log it away.
     *
     * @param array myFields The values to set.
     * @param bool $overwrite Whether to overwrite pre-existing values for myField.
     * @return this
     */
    auto setInvalid(array myFields, bool $overwrite = false);

    /**
     * Get a single value of an invalid field. Returns null if not set.
     *
     * @param string myField The name of the field.
     * @return mixed|null
     */
    auto getInvalidField(string myField);

    /**
     * Sets a field as invalid and not patchable into the entity.
     *
     * @param string myField The value to set.
     * @param mixed myValue The invalid value to be set for myField.
     * @return this
     */
    auto setInvalidField(string myField, myValue);
}
