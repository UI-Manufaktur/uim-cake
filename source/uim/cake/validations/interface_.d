/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.validations;

@safe:
import uim.cake;

// Describes objects that can be validated by passing a Validator object.
interface IValidatable {
    /**
     * Validates the internal properties using a validator object and returns any
     * validation errors found.
     *
     * @param uim.cake.Validation\Validator $validator The validator to use when validating the entity.
     * @return array
     */
    function validate(Validator $validator): array;
}
