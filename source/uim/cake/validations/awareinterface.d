/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.validations.awareinterface_;

@safe:
import uim.cake;

// Provides methods for managing multiple validators.
interface IValidatorAware {
    /**
     * Returns the validation rules tagged with myName.
     *
     * If a myName argument has not been provided, the default validator will be returned.
     * You can configure your default validator name in a `DEFAULT_VALIDATOR`
     * class constant.
     */
    Validator validator(Nullable!string myName = null);

    // This method stores a custom validator under the given name.
    auto validator(string myName, Validator newValidator);

    // Checks whether a validator has been set.
    bool hasValidator(string myName);
}
