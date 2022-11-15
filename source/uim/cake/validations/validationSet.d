

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakelidations;

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
     * @var array<\Cake\Validation\ValidationRule>
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
        return this._validatePresent;
    }

    /**
     * Sets whether a field is required to be present in data array.
     *
     * @param callable|string|bool $validatePresent Valid values are true, false, 'create', 'update' or a callable.
     * @return this
     */
    function requirePresence($validatePresent) {
        this._validatePresent = $validatePresent;

        return this;
    }

    /**
     * Returns whether a field can be left empty.
     *
     * @return callable|string|bool
     */
    function isEmptyAllowed() {
        return this._allowEmpty;
    }

    /**
     * Sets whether a field value is allowed to be empty.
     *
     * @param callable|string|bool $allowEmpty Valid values are true, false,
     * 'create', 'update' or a callable.
     * @return this
     */
    function allowEmpty($allowEmpty) {
        this._allowEmpty = $allowEmpty;

        return this;
    }

    /**
     * Gets a rule for a given name if exists
     *
     * @param string myName The name under which the rule is set.
     * @return \Cake\Validation\ValidationRule|null
     */
    function rule(string myName): ?ValidationRule
    {
        if (!empty(this._rules[myName])) {
            return this._rules[myName];
        }

        return null;
    }

    /**
     * Returns all rules for this validation set
     *
     * @return array<\Cake\Validation\ValidationRule>
     */
    function rules(): array
    {
        return this._rules;
    }

    /**
     * Sets a ValidationRule $rule with a myName
     *
     * ### Example:
     *
     * ```
     *      $set
     *          .add('notBlank', ['rule' => 'notBlank'])
     *          .add('inRange', ['rule' => ['between', 4, 10])
     * ```
     *
     * @param string myName The name under which the rule should be set
     * @param \Cake\Validation\ValidationRule|array $rule The validation rule to be set
     * @return this
     */
    function add(string myName, $rule) {
        if (!($rule instanceof ValidationRule)) {
            $rule = new ValidationRule($rule);
        }
        this._rules[myName] = $rule;

        return this;
    }

    /**
     * Removes a validation rule from the set
     *
     * ### Example:
     *
     * ```
     *      $set
     *          .remove('notBlank')
     *          .remove('inRange')
     * ```
     *
     * @param string myName The name under which the rule should be unset
     * @return this
     */
    function remove(string myName) {
        unset(this._rules[myName]);

        return this;
    }

    /**
     * Returns whether an index exists in the rule set
     *
     * @param string $index name of the rule
     * @return bool
     */
    bool offsetExists($index) {
        return isset(this._rules[$index]);
    }

    /**
     * Returns a rule object by its index
     *
     * @param string $index name of the rule
     * @return \Cake\Validation\ValidationRule
     */
    function offsetGet($index): ValidationRule
    {
        return this._rules[$index];
    }

    /**
     * Sets or replace a validation rule
     *
     * @param string $index name of the rule
     * @param \Cake\Validation\ValidationRule|array $rule Rule to add to $index
     * @return void
     */
    function offsetSet($index, $rule): void
    {
        this.add($index, $rule);
    }

    /**
     * Unsets a validation rule
     *
     * @param string $index name of the rule
     * @return void
     */
    function offsetUnset($index): void
    {
        unset(this._rules[$index]);
    }

    /**
     * Returns an iterator for each of the rules to be applied
     *
     * @return \Traversable<string, \Cake\Validation\ValidationRule>
     */
    auto getIterator(): Traversable
    {
        return new ArrayIterator(this._rules);
    }

    /**
     * Returns the number of rules in this set
     *
     * @return int
     */
    int count() {
        return count(this._rules);
    }
}
