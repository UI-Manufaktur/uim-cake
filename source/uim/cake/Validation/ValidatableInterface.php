


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Validation;

/**
 * Describes objects that can be validated by passing a Validator object.
 *
 * @deprecated 4.4.5 This interface is unused.
 */
interface ValidatableInterface
{
    /**
     * Validates the internal properties using a validator object and returns any
     * validation errors found.
     *
     * @param uim.cake.Validation\Validator $validator The validator to use when validating the entity.
     * @return array
     */
    function validate(Validator $validator): array;
}
