module uim.cake.Validation;

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
     * @return uim.cake.Validation\Validator
     */
    function getValidator(?string $name = null): Validator;

    /**
     * This method stores a custom validator under the given name.
     *
     * @param string $name The name of a validator to be set.
     * @param uim.cake.Validation\Validator $validator Validator object to be set.
     * @return this
     */
    function setValidator(string $name, Validator $validator);

    /**
     * Checks whether a validator has been set.
     *
     * @param string $name The name of a validator.
     * @return bool
     */
    function hasValidator(string $name): bool;
}
