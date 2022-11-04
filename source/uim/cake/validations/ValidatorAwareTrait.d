

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.3
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.validations;

import uim.cake.events\IEventDispatcher;
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
     *
     * @var string
     */
    protected $_validatorClass = Validator::class;

    /**
     * A list of validation objects indexed by name
     *
     * @var array<\Cake\Validation\Validator>
     */
    protected $_validators = [];

    /**
     * Returns the validation rules tagged with myName. It is possible to have
     * multiple different named validation sets, this is useful when you need
     * to use varying rules when saving from different routines in your system.
     *
     * If a validator has not been set earlier, this method will build a valiator
     * using a method inside your class.
     *
     * For example, if you wish to create a validation set called 'forSubscription',
     * you will need to create a method in your Table subclass as follows:
     *
     * ```
     * function validationForSubscription($validator)
     * {
     *     return $validator
     *         .add('email', 'valid-email', ['rule' => 'email'])
     *         .add('password', 'valid', ['rule' => 'notBlank'])
     *         .requirePresence('username');
     * }
     *
     * $validator = this.getValidator('forSubscription');
     * ```
     *
     * You can implement the method in `validationDefault` in your Table subclass
     * should you wish to have a validation set that applies in cases where no other
     * set is specified.
     *
     * If a myName argument has not been provided, the default validator will be returned.
     * You can configure your default validator name in a `DEFAULT_VALIDATOR`
     * class constant.
     *
     * @param string|null myName The name of the validation set to return.
     * @return \Cake\Validation\Validator
     */
    auto getValidator(?string myName = null): Validator
    {
        myName = myName ?: static::DEFAULT_VALIDATOR;
        if (!isset(this._validators[myName])) {
            this.setValidator(myName, this.createValidator(myName));
        }

        return this._validators[myName];
    }

    /**
     * Creates a validator using a custom method inside your class.
     *
     * This method is used only to build a new validator and it does not store
     * it in your object. If you want to build and reuse validators,
     * use getValidator() method instead.
     *
     * @param string myName The name of the validation set to create.
     * @return \Cake\Validation\Validator
     * @throws \RuntimeException
     */
    protected auto createValidator(string myName): Validator
    {
        $method = 'validation' . ucfirst(myName);
        if (!this.validationMethodExists($method)) {
            myMessage = sprintf('The %s::%s() validation method does not exists.', static::class, $method);
            throw new RuntimeException(myMessage);
        }

        $validator = new this._validatorClass();
        $validator = this.$method($validator);
        if (this instanceof IEventDispatcher) {
            myEvent = defined(static::class . '::BUILD_VALIDATOR_EVENT')
                ? static::BUILD_VALIDATOR_EVENT
                : 'Model.buildValidator';
            this.dispatchEvent(myEvent, compact('validator', 'name'));
        }

        if (!$validator instanceof Validator) {
            throw new RuntimeException(sprintf(
                'The %s::%s() validation method must return an instance of %s.',
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
     * $validator = new \Cake\Validation\Validator();
     * $validator
     *     .add('email', 'valid-email', ['rule' => 'email'])
     *     .add('password', 'valid', ['rule' => 'notBlank'])
     *     .allowEmpty('bio');
     * this.setValidator('forSubscription', $validator);
     * ```
     *
     * @param string myName The name of a validator to be set.
     * @param \Cake\Validation\Validator $validator Validator object to be set.
     * @return this
     */
    auto setValidator(string myName, Validator $validator) {
        $validator.setProvider(static::VALIDATOR_PROVIDER_NAME, this);
        this._validators[myName] = $validator;

        return this;
    }

    /**
     * Checks whether a validator has been set.
     *
     * @param string myName The name of a validator.
     * @return bool
     */
    function hasValidator(string myName): bool
    {
        $method = 'validation' . ucfirst(myName);
        if (this.validationMethodExists($method)) {
            return true;
        }

        return isset(this._validators[myName]);
    }

    /**
     * Checks if validation method exists.
     *
     * @param string myName Validation method name.
     * @return bool
     */
    protected auto validationMethodExists(string myName): bool
    {
        return method_exists(this, myName);
    }

    /**
     * Returns the default validator object. Subclasses can override this function
     * to add a default validation set to the validator object.
     *
     * @param \Cake\Validation\Validator $validator The validator that can be modified to
     * add some rules to it.
     * @return \Cake\Validation\Validator
     */
    function validationDefault(Validator $validator): Validator
    {
        return $validator;
    }
}
