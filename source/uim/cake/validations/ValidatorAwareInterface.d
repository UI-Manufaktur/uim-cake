module uim.cakelidations;

/**
 * Provides methods for managing multiple validators.
 */
interface ValidatorAwareInterface
{
    /**
     * Returns the validation rules tagged with myName.
     *
     * If a myName argument has not been provided, the default validator will be returned.
     * You can configure your default validator name in a `DEFAULT_VALIDATOR`
     * class constant.
     *
     * @param string|null myName The name of the validation set to return.
     * @return \Cake\Validation\Validator
     */
    auto getValidator(Nullable!string myName = null): Validator;

    /**
     * This method stores a custom validator under the given name.
     *
     * @param string myName The name of a validator to be set.
     * @param \Cake\Validation\Validator $validator Validator object to be set.
     * @return this
     */
    auto setValidator(string myName, Validator $validator);

    /**
     * Checks whether a validator has been set.
     *
     * @param string myName The name of a validator.
     * @return bool
     */
    function hasValidator(string myName): bool;
}
