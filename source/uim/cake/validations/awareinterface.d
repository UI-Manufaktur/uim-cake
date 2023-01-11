/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.validations.awareinterface_;

@safe:
import uim.cake;

/**
 * Provides methods for managing multiple validators.
 */
interface ValidatorAwareInterface
{
    /**
     * Returns the validation rules tagged with $name.
     *
     * If a $name argument has not been provided, the default validator will be returned.
     * You can configure your default validator name in a `DEFAULT_VALIDATOR`
     * class constant.
     *
     * @param string|null $name The name of the validation set to return.
     * @return uim.cake.validations.Validator
     */
    function getValidator(Nullable!string aName = null): Validator;

    /**
     * This method stores a custom validator under the given name.
     *
     * @param string aName The name of a validator to be set.
     * @param uim.cake.validations.Validator $validator Validator object to be set.
     * @return this
     */
    function setValidator(string aName, Validator $validator);

    /**
     * Checks whether a validator has been set.
     *
     * @param string aName The name of a validator.
     */
    bool hasValidator(string aName);
}
