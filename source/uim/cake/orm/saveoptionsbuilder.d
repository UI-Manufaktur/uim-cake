/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.orm;

use ArrayObject;
use RuntimeException;

/**
 * OOP style Save Option Builder.
 *
 * This allows you to build options to save entities in a OOP style and helps
 * you to avoid mistakes by validating the options as you build them.
 *
 * @see uim.cake.datasources.RulesChecker
 */
class SaveOptionsBuilder : ArrayObject {
    use AssociationsNormalizerTrait;

    /**
     * Options
     *
     * @var array
     */
    protected _options = [];

    /**
     * Table object.
     *
     * @var uim.cake.orm.Table
     */
    protected _table;

    /**
     * Constructor.
     *
     * @param uim.cake.orm.Table myTable A table instance.
     * @param array<string, mixed> myOptions Options to parse when instantiating.
     */
    this(Table myTable, array myOptions = []) {
        _table = myTable;
        this.parseArrayOptions(myOptions);

        super.this();
    }

    /**
     * Takes an options array and populates the option object with the data.
     *
     * This can be used to turn an options array into the object.
     *
     * @throws \InvalidArgumentException If a given option key does not exist.
     * @param array $array Options array.
     * @return this
     */
    function parseArrayOptions(array $array) {
        foreach ($array as myKey: myValue) {
            this.{myKey}(myValue);
        }

        return this;
    }

    /**
     * Set associated options.
     *
     * @param array|string associated String or array of associations.
     * @return this
     */
    function associated($associated) {
        $associated = _normalizeAssociations($associated);
        _associated(_table, $associated);
        _options["associated"] = $associated;

        return this;
    }

    /**
     * Checks that the associations exists recursively.
     *
     * @param uim.cake.orm.Table myTable Table object.
     * @param array $associations An associations array.
     */
    protected void _associated(Table myTable, array $associations) {
        foreach ($associations as myKey: $associated) {
            if (is_int(myKey)) {
                _checkAssociation(myTable, $associated);
                continue;
            }
            _checkAssociation(myTable, myKey);
            if (isset($associated["associated"])) {
                _associated(myTable.getAssociation(myKey).getTarget(), $associated["associated"]);
                continue;
            }
        }
    }

    /**
     * Checks if an association exists.
     *
     * @throws \RuntimeException If no such association exists for the given table.
     * @param uim.cake.orm.Table myTable Table object.
     * @param string association Association name.
     */
    protected void _checkAssociation(Table myTable, string association) {
        if (!myTable.associations().has($association)) {
            throw new RuntimeException(sprintf(
                "Table `%s` is not associated with `%s`",
                get_class(myTable),
                $association
            ));
        }
    }

    /**
     * Set the guard option.
     *
     * @param bool $guard Guard the properties or not.
     * @return this
     */
    function guard(bool $guard) {
        _options["guard"] = $guard;

        return this;
    }

    /**
     * Set the validation rule set to use.
     *
     * @param string validate Name of the validation rule set to use.
     * @return this
     */
    function validate(string validate) {
        _table.getValidator($validate);
        _options["validate"] = $validate;

        return this;
    }

    /**
     * Set check existing option.
     *
     * @param bool $checkExisting Guard the properties or not.
     * @return this
     */
    function checkExisting(bool $checkExisting) {
        _options["checkExisting"] = $checkExisting;

        return this;
    }

    /**
     * Option to check the rules.
     *
     * @param bool $checkRules Check the rules or not.
     * @return this
     */
    function checkRules(bool $checkRules) {
        _options["checkRules"] = $checkRules;

        return this;
    }

    /**
     * Sets the atomic option.
     *
     * @param bool $atomic Atomic or not.
     * @return this
     */
    function atomic(bool $atomic) {
        _options["atomic"] = $atomic;

        return this;
    }

    /**
     * @return array
     */
    function toArray(): array
    {
        return _options;
    }

    /**
     * Setting custom options.
     *
     * @param string option Option key.
     * @param mixed myValue Option value.
     * @return this
     */
    auto set(string option, myValue) {
        if (method_exists(this, $option)) {
            return this.{$option}(myValue);
        }
        _options[$option] = myValue;

        return this;
    }
}
