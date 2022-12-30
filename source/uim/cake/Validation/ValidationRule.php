

/**
 * ValidationRule.
 *
 * Provides the Model validation logic.
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.2.0
  */
module uim.cake.Validation;

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
     * The "on" key
     *
     * @var callable|string
     */
    protected $_on;

    /**
     * The "last" key
     *
     */
    protected bool $_last = false;

    /**
     * The "message" key
     *
     */
    protected string $_message;

    /**
     * Key under which the object or class where the method to be used for
     * validation will be found
     *
     */
    protected string $_provider = "default";

    /**
     * Extra arguments to be passed to the validation method
     *
     * @var array
     */
    protected $_pass = [];

    /**
     * Constructor
     *
     * @param array<string, mixed> $validator [optional] The validator properties
     */
    this(array $validator = []) {
        _addValidatorProps($validator);
    }

    /**
     * Returns whether this rule should break validation process for associated field
     * after it fails
     *
     * @return bool
     */
    function isLast(): bool
    {
        return _last;
    }

    /**
     * Dispatches the validation rule to the given validator method and returns
     * a boolean indicating whether the rule passed or not. If a string is returned
     * it is assumed that the rule failed and the error message was given as a result.
     *
     * @param mixed $value The data to validate
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
    function process($value, array $providers, array $context = []) {
        $context += ["data": [], "newRecord": true, "providers": $providers];

        if (_skip($context)) {
            return true;
        }

        if (!is_string(_rule) && is_callable(_rule)) {
            $callable = _rule;
            $isCallable = true;
        } else {
            $provider = $providers[_provider];
            $callable = [$provider, _rule];
            $isCallable = is_callable($callable);
        }

        if (!$isCallable) {
            /** @psalm-suppress PossiblyInvalidArgument */
            $message = sprintf(
                "Unable to call method "%s" in "%s" provider for field "%s"",
                _rule,
                _provider,
                $context["field"]
            );
            throw new InvalidArgumentException($message);
        }

        if (_pass) {
            $args = array_values(array_merge([$value], _pass, [$context]));
            $result = $callable(...$args);
        } else {
            $result = $callable($value, $context);
        }

        if ($result == false) {
            return _message ?: false;
        }

        return $result;
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
    protected function _skip(array $context): bool
    {
        if (!is_string(_on) && is_callable(_on)) {
            $function = _on;

            return !$function($context);
        }

        $newRecord = $context["newRecord"];
        if (!empty(_on)) {
            return (_on == Validator::WHEN_CREATE && !$newRecord)
                || (_on == Validator::WHEN_UPDATE && $newRecord);
        }

        return false;
    }

    /**
     * Sets the rule properties from the rule entry in validate
     *
     * @param array<string, mixed> $validator [optional]
     */
    protected void _addValidatorProps(array $validator = []): void
    {
        foreach ($validator as $key: $value) {
            if (empty($value)) {
                continue;
            }
            if ($key == "rule" && is_array($value) && !is_callable($value)) {
                _pass = array_slice($value, 1);
                $value = array_shift($value);
            }
            if (in_array($key, ["rule", "on", "message", "last", "provider", "pass"], true)) {
                this.{"_$key"} = $value;
            }
        }
    }

    /**
     * Returns the value of a property by name
     *
     * @param string $property The name of the property to retrieve.
     * @return mixed
     */
    function get(string $property) {
        $property = "_" . $property;

        return this.{$property} ?? null;
    }
}
