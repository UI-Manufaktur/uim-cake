/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.validations;

@safe:
import uim.cake;

/**
 * ValidationSet object. Holds all validation rules for a field and exposes
 * methods to dynamically add or remove validation rules
 */
class ValidationSet : ArrayAccess, IteratorAggregate, Countable {
    /**
     * Holds the ValidationRule objects
     *
     * @var array<uim.cake.validations.>
     */
    protected ValidationRule[] _rules = null;

    /**
     * Denotes whether the fieldname key must be present in data array
     *
     * @var callable|string|bool
     */
    protected _validatePresent = false;

    /**
     * Denotes if a field is allowed to be empty
     *
     * @var callable|string|bool
     */
    protected _allowEmpty = false;

    /**
     * Returns whether a field can be left out.
     *
     * @return callable|string|bool
     */
    bool isPresenceRequired() {
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
    bool isEmptyAllowed() {
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
     * @param string myName The name under which the rule is set.
     * @return uim.cake.validations.ValidationRule|null
     */
    function rule(string myName): ?ValidationRule
    {
        if (!empty(_rules[myName])) {
            return _rules[myName];
        }

        return null;
    }

    /**
     * Returns all rules for this validation set
     *
     * @return array<uim.cake.validations.ValidationRule>
     */
    array rules() {
        return _rules;
    }

    /**
     * Sets a ValidationRule $rule with a myName
     *
     * ### Example:
     *
     * ```
     *      $set
     *          .add("notBlank", ["rule": "notBlank"])
     *          .add("inRange", ["rule": ["between", 4, 10])
     * ```
     *
     * @param string myName The name under which the rule should be set
     * @param uim.cake.validations.ValidationRule|array $rule The validation rule to be set
     * @return this
     */
    function add(string myName, $rule) {
        if (!($rule instanceof ValidationRule)) {
            $rule = new ValidationRule($rule);
        }
        _rules[myName] = $rule;

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
     * @param string myName The name under which the rule should be unset
     * @return this
     */
    function remove(string myName) {
        unset(_rules[myName]);

        return this;
    }

    /**
     * Returns whether an index exists in the rule set
     *
     * @param string index name of the rule
     */
    bool offsetExists($index) {
        return isset(_rules[$index]);
    }

    /**
     * Returns a rule object by its index
     *
     * @param string index name of the rule
     * @return uim.cake.validations.ValidationRule
     */
    function offsetGet($index): ValidationRule
    {
        return _rules[$index];
    }

    /**
     * Sets or replace a validation rule
     *
     * @param string index name of the rule
     * @param uim.cake.validations.ValidationRule|array $rule Rule to add to $index
     */
    void offsetSet($index, $rule) {
        this.add($index, $rule);
    }

    /**
     * Unsets a validation rule
     *
     * @param string index name of the rule
     */
    void offsetUnset($index) {
        unset(_rules[$index]);
    }

    /**
     * Returns an iterator for each of the rules to be applied
     *
     * @return \Traversable<string, uim.cake.validations.ValidationRule>
     */
    Traversable getIterator() {
        return new ArrayIterator(_rules);
    }

    /**
     * Returns the number of rules in this set
     */
    size_t count() {
        return count(_rules);
    }
}
