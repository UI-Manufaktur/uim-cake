module uim.cake.validations;

@safe:
import uim.cake;

// Describes objects that can be validated by passing a Validator object.
interface IValidatable {
    /**
     * Validates the internal properties using a validator object and returns any
     * validation errors found.
     *
     * @param \Cake\Validation\Validator $validator The validator to use when validating the entity.
     * @return array
     */
    function validate(Validator $validator): array;
}
