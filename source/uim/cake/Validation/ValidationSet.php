


 *


 * @since         2.2.0
  */module uim.cake.Validation;

use ArrayAccess;
use ArrayIterator;
use Countable;
use IteratorAggregate;
use Traversable;

/**
 * ValidationSet object. Holds all validation rules for a field and exposes
 * methods to dynamically add or remove validation rules
 */
class ValidationSet : ArrayAccess, IteratorAggregate, Countable
{
    /**
     * Holds the ValidationRule objects
     *
     * @var array<uim.cake.Validation\ValidationRule>
     */
    protected $_rules = [];

    /**
     * Denotes whether the fieldname key must be present in data array
     *
     * @var callable|string|bool
     */
    protected $_validatePresent = false;

    /**
     * Denotes if a field is allowed to be empty
     *
     * @var callable|string|bool
     */
    protected $_allowEmpty = false;

    /**
     * Returns whether a field can be left out.
     *
     * @return callable|string|bool
     */
    function isPresenceRequired() {
        return _validatePresent;
    }

    /**
     * Sets whether a field is required to be present in data array.
     *
     * @param callable|string|bool $validatePresent Valid values are true, false, "create", "update" or a callable.
     * @return this
     */
    function requirePresence($validatePresent) {
        _validatePresent = $validatePresent;

        return this;
    }

    /**
     * Returns whether a field can be left empty.
     *
     * @return callable|string|bool
     */
    function isEmptyAllowed() {
        return _allowEmpty;
    }

    /**
     * Sets whether a field value is allowed to be empty.
     *
     * @param callable|string|bool $allowEmpty Valid values are true, false,
     * "create", "update" or a callable.
     * @return this
     */
    function allowEmpty($allowEmpty) {
        _allowEmpty = $allowEmpty;

        return this;
    }

    /**
     * Gets a rule for a given name if exists
     *
     * @param string $name The name under which the rule is set.
     * @return uim.cake.Validation\ValidationRule|null
     */
    function rule(string $name): ?ValidationRule
    {
        if (!empty(_rules[$name])) {
            return _rules[$name];
        }

        return null;
    }

    /**
     * Returns all rules for this validation set
     *
     * @return array<uim.cake.Validation\ValidationRule>
     */
    function rules(): array
    {
        return _rules;
    }

    /**
     * Sets a ValidationRule $rule with a $name
     *
     * ### Example:
     *
     * ```
     *      $set
     *          .add("notBlank", ["rule": "notBlank"])
     *          .add("inRange", ["rule": ["between", 4, 10])
     * ```
     *
     * @param string $name The name under which the rule should be set
     * @param uim.cake.Validation\ValidationRule|array $rule The validation rule to be set
     * @return this
     */
    function add(string $name, $rule) {
        if (!($rule instanceof ValidationRule)) {
            $rule = new ValidationRule($rule);
        }
        _rules[$name] = $rule;

        return this;
    }

    /**
     * Removes a validation rule from the set
     *
     * ### Example:
     *
     * ```
     *      $set
     *          .remove("notBlank")
     *          .remove("inRange")
     * ```
     *
     * @param string $name The name under which the rule should be unset
     * @return this
     */
    function remove(string $name) {
        unset(_rules[$name]);

        return this;
    }

    /**
     * Returns whether an index exists in the rule set
     *
     * @param string $index name of the rule
     * @return bool
     */
    function offsetExists($index): bool
    {
        return isset(_rules[$index]);
    }

    /**
     * Returns a rule object by its index
     *
     * @param string $index name of the rule
     * @return uim.cake.Validation\ValidationRule
     */
    function offsetGet($index): ValidationRule
    {
        return _rules[$index];
    }

    /**
     * Sets or replace a validation rule
     *
     * @param string $index name of the rule
     * @param uim.cake.Validation\ValidationRule|array $rule Rule to add to $index
     */
    void offsetSet($index, $rule): void
    {
        this.add($index, $rule);
    }

    /**
     * Unsets a validation rule
     *
     * @param string $index name of the rule
     */
    void offsetUnset($index): void
    {
        unset(_rules[$index]);
    }

    /**
     * Returns an iterator for each of the rules to be applied
     *
     * @return \Traversable<string, uim.cake.Validation\ValidationRule>
     */
    function getIterator(): Traversable
    {
        return new ArrayIterator(_rules);
    }

    /**
     * Returns the number of rules in this set
     *
     */
    int count(): int
    {
        return count(_rules);
    }
}
