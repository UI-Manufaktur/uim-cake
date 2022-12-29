


 *


 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Datasource;

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
    function getInvalid(): array;

    /**
     * Set fields as invalid and not patchable into the entity.
     *
     * This is useful for batch operations when one needs to get the original value for an error message after patching.
     * This value could not be patched into the entity and is simply copied into the _invalid property for debugging
     * purposes or to be able to log it away.
     *
     * @param array<string, mixed> $fields The values to set.
     * @param bool $overwrite Whether to overwrite pre-existing values for $field.
     * @return this
     */
    function setInvalid(array $fields, bool $overwrite = false);

    /**
     * Get a single value of an invalid field. Returns null if not set.
     *
     * @param string $field The name of the field.
     * @return mixed|null
     */
    function getInvalidField(string $field);

    /**
     * Sets a field as invalid and not patchable into the entity.
     *
     * @param string $field The value to set.
     * @param mixed $value The invalid value to be set for $field.
     * @return this
     */
    function setInvalidField(string $field, $value);
}
