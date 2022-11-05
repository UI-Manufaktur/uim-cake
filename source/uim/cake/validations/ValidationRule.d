

/**
 * ValidationRule.
 *
 * Provides the Model validation logic.
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.validations;

use InvalidArgumentException;

/**
 * ValidationRule object. Represents a validation method, error message and
 * rules for applying such method to a field.
 */
class ValidationRule
{
    /**
     * The method to be called for a given scope
     *
     * @var callable|string
     */
    protected $_rule;

    /**
     * The 'on' key
     *
     * @var callable|string
     */
    protected $_on;

    /**
     * The 'last' key
     *
     * @var bool
     */
    protected $_last = false;

    /**
     * The 'message' key
     *
     * @var string
     */
    protected $_message;

    /**
     * Key under which the object or class where the method to be used for
     * validation will be found
     *
     * @var string
     */
    protected $_provider = 'default';

    /**
     * Extra arguments to be passed to the validation method
     *
     * @var array
     */
    protected $_pass = [];

    /**
     * Constructor
     *
     * @param array $validator [optional] The validator properties
     */
    this(array $validator = []) {
        this._addValidatorProps($validator);
    }

    /**
     * Returns whether this rule should break validation process for associated field
     * after it fails
     *
     * @return bool
     */
    function isLast(): bool
    {
        return this._last;
    }

    /**
     * Dispatches the validation rule to the given validator method and returns
     * a boolean indicating whether the rule passed or not. If a string is returned
     * it is assumed that the rule failed and the error message was given as a result.
     *
     * @param mixed myValue The data to validate
     * @param array<string, mixed> $providers Associative array with objects or class names that will
     * be passed as the last argument for the validation method
     * @param array<string, mixed> $context A key value list of data that could be used as context
     * during validation. Recognized keys are:
     * - newRecord: (boolean) whether the data to be validated belongs to a
     *   new record
     * - data: The full data that was passed to the validation process
     * - field: The name of the field that is being processed
     * @return array|string|bool
     * @throws \InvalidArgumentException when the supplied rule is not a valid
     * callable for the configured scope
     */
    function process(myValue, array $providers, array $context = []) {
        $context += ['data' => [], 'newRecord' => true, 'providers' => $providers];

        if (this._skip($context)) {
            return true;
        }

        if (!is_string(this._rule) && is_callable(this._rule)) {
            $callable = this._rule;
            $isCallable = true;
        } else {
            $provider = $providers[this._provider];
            $callable = [$provider, this._rule];
            $isCallable = is_callable($callable);
        }

        if (!$isCallable) {
            /** @psalm-suppress PossiblyInvalidArgument */
            myMessage = sprintf(
                'Unable to call method "%s" in "%s" provider for field "%s"',
                this._rule,
                this._provider,
                $context['field']
            );
            throw new InvalidArgumentException(myMessage);
        }

        if (this._pass) {
            $args = array_values(array_merge([myValue], this._pass, [$context]));
            myResult = $callable(...$args);
        } else {
            myResult = $callable(myValue, $context);
        }

        if (myResult === false) {
            return this._message ?: false;
        }

        return myResult;
    }

    /**
     * Checks if the validation rule should be skipped
     *
     * @param array<string, mixed> $context A key value list of data that could be used as context
     * during validation. Recognized keys are:
     * - newRecord: (boolean) whether the data to be validated belongs to a
     *   new record
     * - data: The full data that was passed to the validation process
     * - providers associative array with objects or class names that will
     *   be passed as the last argument for the validation method
     * @return bool True if the ValidationRule should be skipped
     */
    protected auto _skip(array $context): bool
    {
        if (!is_string(this._on) && is_callable(this._on)) {
            $function = this._on;

            return !$function($context);
        }

        $newRecord = $context['newRecord'];
        if (!empty(this._on)) {
            return (this._on === Validator::WHEN_CREATE && !$newRecord)
                || (this._on === Validator::WHEN_UPDATE && $newRecord);
        }

        return false;
    }

    /**
     * Sets the rule properties from the rule entry in validate
     *
     * @param array $validator [optional]
     * @return void
     */
    protected auto _addValidatorProps(array $validator = []): void
    {
        foreach ($validator as myKey => myValue) {
            if (empty(myValue)) {
                continue;
            }
            if (myKey === 'rule' && is_array(myValue) && !is_callable(myValue)) {
                this._pass = array_slice(myValue, 1);
                myValue = array_shift(myValue);
            }
            if (in_array(myKey, ['rule', 'on', 'message', 'last', 'provider', 'pass'], true)) {
                this.{"_myKey"} = myValue;
            }
        }
    }

    /**
     * Returns the value of a property by name
     *
     * @param string $property The name of the property to retrieve.
     * @return mixed
     */
    auto get(string $property) {
        $property = '_' . $property;

        return this.{$property} ?? null;
    }
}
