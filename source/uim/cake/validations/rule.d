

// ValidationRule - Provides the Model validation logic.
/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.validations.rule;

@safe:
import uim.cake;

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
     */
    protected bool $_last = false;

    // The "message" key
    protected string _message;

    /**
     * Key under which the object or class where the method to be used for
     * validation will be found
     */
    protected string _provider = "default";

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
        _addValidatorProps($validator);
    }

    /**
     * Returns whether this rule should break validation process for associated field
     * after it fails
     */
    bool isLast() {
        return _last;
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
        $context += ["data" => [], "newRecord" => true, "providers" => $providers];

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
            myMessage = sprintf(
                "Unable to call method "%s" in "%s" provider for field "%s"",
                _rule,
                _provider,
                $context["field"]
            );
            throw new InvalidArgumentException(myMessage);
        }

        if (_pass) {
            $args = array_values(array_merge([myValue], _pass, [$context]));
            myResult = $callable(...$args);
        } else {
            myResult = $callable(myValue, $context);
        }

        if (myResult == false) {
            return _message ?: false;
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
    protected bool _skip(array $context) {
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
     * @param array $validator [optional]
     */
    protected void _addValidatorProps(array $validator = []) {
      foreach (myKey => myValue; $validator) {
        if (empty(myValue)) continue;

        if (myKey == "rule" && is_array(myValue) && !is_callable(myValue)) {
            _pass = array_slice(myValue, 1);
            myValue = array_shift(myValue);
        }
        if (in_array(myKey, ["rule", "on", "message", "last", "provider", "pass"], true)) {
            this.{"_myKey"} = myValue;
        }
      }
    }

    /**
     * Returns the value of a property by name
     *
     * @param string property The name of the property to retrieve.
     * @return mixed
     */
    auto get(string property) {
      $property = "_" . $property;

      return this.{$property} ?? null;
    }
}
