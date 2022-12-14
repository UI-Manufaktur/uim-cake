/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.validations;

@safe:
import uim.cake;

use RuntimeException;

/**
 * A trait that provides methods for building and
 * interacting with Validators.
 *
 * This trait is useful when building ORM like features where
 * the implementing class wants to build and customize a variety
 * of validator instances.
 *
 * This trait expects that classes including it define three constants:
 *
 * - `DEFAULT_VALIDATOR` - The default validator name.
 * - `VALIDATOR_PROVIDER_NAME ` - The provider name the including class is assigned
 *   in validators.
 * - `BUILD_VALIDATOR_EVENT` - The name of the event to be triggred when validators
 *   are built.
 *
 * If the including class also : events the `Model.buildValidator` event
 * will be triggered when validators are created.
 */
trait ValidatorAwareTrait
{
    /**
     * Validator class.
     */
    protected string _validatorClass = Validator::class;

    /**
     * A list of validation objects indexed by name
     *
     * @var array<uim.cake.validations.Validator>
     */
    protected _validators = null;

    /**
     * Returns the validation rules tagged with $name. It is possible to have
     * multiple different named validation sets, this is useful when you need
     * to use varying rules when saving from different routines in your system.
     *
     * If a validator has not been set earlier, this method will build a valiator
     * using a method inside your class.
     *
     * For example, if you wish to create a validation set called "forSubscription",
     * you will need to create a method in your Table subclass as follows:
     *
     * ```
     * function validationForSubscription($validator)
     * {
     *     return $validator
     *         .add("email", "valid-email", ["rule": "email"])
     *         .add("password", "valid", ["rule": "notBlank"])
     *         .requirePresence("username");
     * }
     *
     * $validator = this.getValidator("forSubscription");
     * ```
     *
     * You can implement the method in `validationDefault` in your Table subclass
     * should you wish to have a validation set that applies in cases where no other
     * set is specified.
     *
     * If a $name argument has not been provided, the default validator will be returned.
     * You can configure your default validator name in a `DEFAULT_VALIDATOR`
     * class constant.
     *
     * @param string|null $name The name of the validation set to return.
     * @return uim.cake.validations.Validator
     */
    function getValidator(Nullable!string aName = null): Validator
    {
        $name = $name ?: static::DEFAULT_VALIDATOR;
        if (!isset(_validators[$name])) {
            this.setValidator($name, this.createValidator($name));
        }

        return _validators[$name];
    }

    /**
     * Creates a validator using a custom method inside your class.
     *
     * This method is used only to build a new validator and it does not store
     * it in your object. If you want to build and reuse validators,
     * use getValidator() method instead.
     *
     * @param string aName The name of the validation set to create.
     * @return uim.cake.validations.Validator
     * @throws \RuntimeException
     */
    protected function createValidator(string aName): Validator
    {
        $method = "validation" ~ ucfirst($name);
        if (!this.validationMethodExists($method)) {
            $message = sprintf("The %s::%s() validation method does not exists.", static::class, $method);
            throw new RuntimeException($message);
        }

        $validator = new _validatorClass();
        $validator = this.$method($validator);
        if (this instanceof IEventDispatcher) {
            $event = defined(static::class ~ "::BUILD_VALIDATOR_EVENT")
                ? static::BUILD_VALIDATOR_EVENT
                : "Model.buildValidator";
            this.dispatchEvent($event, compact("validator", "name"));
        }

        if (!$validator instanceof Validator) {
            throw new RuntimeException(sprintf(
                "The %s::%s() validation method must return an instance of %s.",
                static::class,
                $method,
                Validator::class
            ));
        }

        return $validator;
    }

    /**
     * This method stores a custom validator under the given name.
     *
     * You can build the object by yourself and store it in your object:
     *
     * ```
     * $validator = new uim.cake.validations.Validator();
     * $validator
     *     .add("email", "valid-email", ["rule": "email"])
     *     .add("password", "valid", ["rule": "notBlank"])
     *     .allowEmpty("bio");
     * this.setValidator("forSubscription", $validator);
     * ```
     *
     * @param string aName The name of a validator to be set.
     * @param uim.cake.validations.Validator $validator Validator object to be set.
     * @return this
     */
    function setValidator(string aName, Validator $validator) {
        $validator.setProvider(static::VALIDATOR_PROVIDER_NAME, this);
        _validators[$name] = $validator;

        return this;
    }

    /**
     * Checks whether a validator has been set.
     *
     * @param string aName The name of a validator.
     */
    bool hasValidator(string aName) {
        $method = "validation" ~ ucfirst($name);
        if (this.validationMethodExists($method)) {
            return true;
        }

        return isset(_validators[$name]);
    }

    /**
     * Checks if validation method exists.
     *
     * @param string aName Validation method name.
     */
    protected bool validationMethodExists(string aName) {
        return method_exists(this, $name);
    }

    /**
     * Returns the default validator object. Subclasses can override this function
     * to add a default validation set to the validator object.
     *
     * @param uim.cake.validations.Validator $validator The validator that can be modified to
     * add some rules to it.
     * @return uim.cake.validations.Validator
     */
    function validationDefault(Validator $validator): Validator
    {
        return $validator;
    }
}
