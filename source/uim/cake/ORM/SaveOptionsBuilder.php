


 *


 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM;

use ArrayObject;
use RuntimeException;

/**
 * OOP style Save Option Builder.
 *
 * This allows you to build options to save entities in a OOP style and helps
 * you to avoid mistakes by validating the options as you build them.
 *
 * @see uim.cake.Datasource\RulesChecker
 * @deprecated 4.4.0 Use a normal array for options instead.
 */
class SaveOptionsBuilder : ArrayObject
{
    use AssociationsNormalizerTrait;

    /**
     * Options
     *
     * @var array<string, mixed>
     */
    protected $_options = [];

    /**
     * Table object.
     *
     * @var \Cake\ORM\Table
     */
    protected $_table;

    /**
     * Constructor.
     *
     * @param \Cake\ORM\Table $table A table instance.
     * @param array<string, mixed> $options Options to parse when instantiating.
     */
    public this(Table $table, array $options = []) {
        _table = $table;
        this.parseArrayOptions($options);

        super(();
    }

    /**
     * Takes an options array and populates the option object with the data.
     *
     * This can be used to turn an options array into the object.
     *
     * @throws \InvalidArgumentException If a given option key does not exist.
     * @param array<string, mixed> $array Options array.
     * @return this
     */
    function parseArrayOptions(array $array) {
        foreach ($array as $key: $value) {
            this.{$key}($value);
        }

        return this;
    }

    /**
     * Set associated options.
     *
     * @param array|string $associated String or array of associations.
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
     * @param \Cake\ORM\Table $table Table object.
     * @param array $associations An associations array.
     * @return void
     */
    protected function _associated(Table $table, array $associations): void
    {
        foreach ($associations as $key: $associated) {
            if (is_int($key)) {
                _checkAssociation($table, $associated);
                continue;
            }
            _checkAssociation($table, $key);
            if (isset($associated["associated"])) {
                _associated($table.getAssociation($key).getTarget(), $associated["associated"]);
                continue;
            }
        }
    }

    /**
     * Checks if an association exists.
     *
     * @throws \RuntimeException If no such association exists for the given table.
     * @param \Cake\ORM\Table $table Table object.
     * @param string $association Association name.
     * @return void
     */
    protected function _checkAssociation(Table $table, string $association): void
    {
        if (!$table.associations().has($association)) {
            throw new RuntimeException(sprintf(
                "Table `%s` is not associated with `%s`",
                get_class($table),
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
     * @param string $validate Name of the validation rule set to use.
     * @return this
     */
    function validate(string $validate) {
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
     * @return array<string, mixed>
     */
    function toArray(): array
    {
        return _options;
    }

    /**
     * Setting custom options.
     *
     * @param string $option Option key.
     * @param mixed $value Option value.
     * @return this
     */
    function set(string $option, $value) {
        if (method_exists(this, $option)) {
            return this.{$option}($value);
        }
        _options[$option] = $value;

        return this;
    }
}
