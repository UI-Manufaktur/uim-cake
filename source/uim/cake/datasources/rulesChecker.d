module uim.cake.datasources;

@safe:
import uim.cake;

/**
 * Contains logic for storing and checking rules on entities
 *
 * RulesCheckers are used by Table classes to ensure that the
 * current entity state satisfies the application logic and business rules.
 *
 * RulesCheckers afford different rules to be applied in the create and update
 * scenario.
 *
 * ### Adding rules
 *
 * Rules must be callable objects that return true/false depending on whether
 * the rule has been satisfied. You can use RulesChecker::add(), RulesChecker::addCreate(),
 * RulesChecker::addUpdate() and RulesChecker::addDelete to add rules to a checker.
 *
 * ### Running checks
 *
 * Generally a Table object will invoke the rules objects, but you can manually
 * invoke the checks by calling RulesChecker::checkCreate(), RulesChecker::checkUpdate() or
 * RulesChecker::checkDelete().
 */
class RulesChecker
{
    /**
     * Indicates that the checking rules to apply are those used for creating entities
     */
    public const string CREATE = "create";

    /**
     * Indicates that the checking rules to apply are those used for updating entities
     */
    public const string UPDATE = "update";

    /**
     * Indicates that the checking rules to apply are those used for deleting entities
     */
    public const string DELETE = "delete";

    /**
     * The list of rules to be checked on both create and update operations
     *
     * @var array<\Cake\Datasource\RuleInvoker>
     */
    protected $_rules = [];

    /**
     * The list of rules to check during create operations
     *
     * @var array<\Cake\Datasource\RuleInvoker>
     */
    protected $_createRules = [];

    /**
     * The list of rules to check during update operations
     *
     * @var array<\Cake\Datasource\RuleInvoker>
     */
    protected $_updateRules = [];

    /**
     * The list of rules to check during delete operations
     *
     * @var array<\Cake\Datasource\RuleInvoker>
     */
    protected $_deleteRules = [];

    /**
     * List of options to pass to every callable rule
     *
     * @var array
     */
    protected $_options = [];

    /**
     * Whether to use I18n functions for translating default error messages
     *
     * @var bool
     */
    protected $_useI18n = false;

    /**
     * Constructor. Takes the options to be passed to all rules.
     *
     * @param array<string, mixed> myOptions The options to pass to every rule
     */
    this(array myOptions = []) {
        _options = myOptions;
        _useI18n = function_exists("__d");
    }

    /**
     * Adds a rule that will be applied to the entity both on create and update
     * operations.
     *
     * ### Options
     *
     * The options array accept the following special keys:
     *
     * - `errorField`: The name of the entity field that will be marked as invalid
     *    if the rule does not pass.
     * - `message`: The error message to set to `errorField` if the rule does not pass.
     *
     * @param callable $rule A callable function or object that will return whether
     * the entity is valid or not.
     * @param array|string|null myName The alias for a rule, or an array of options.
     * @param array<string, mixed> myOptions List of extra options to pass to the rule callable as
     * second argument.
     * @return this
     */
    function add(callable $rule, myName = null, array myOptions = []) {
        _rules[] = _addError($rule, myName, myOptions);

        return this;
    }

    /**
     * Adds a rule that will be applied to the entity on create operations.
     *
     * ### Options
     *
     * The options array accept the following special keys:
     *
     * - `errorField`: The name of the entity field that will be marked as invalid
     *    if the rule does not pass.
     * - `message`: The error message to set to `errorField` if the rule does not pass.
     *
     * @param callable $rule A callable function or object that will return whether
     * the entity is valid or not.
     * @param array|string|null myName The alias for a rule or an array of options.
     * @param array<string, mixed> myOptions List of extra options to pass to the rule callable as
     * second argument.
     * @return this
     */
    function addCreate(callable $rule, myName = null, array myOptions = []) {
        _createRules[] = _addError($rule, myName, myOptions);

        return this;
    }

    /**
     * Adds a rule that will be applied to the entity on update operations.
     *
     * ### Options
     *
     * The options array accept the following special keys:
     *
     * - `errorField`: The name of the entity field that will be marked as invalid
     *    if the rule does not pass.
     * - `message`: The error message to set to `errorField` if the rule does not pass.
     *
     * @param callable $rule A callable function or object that will return whether
     * the entity is valid or not.
     * @param array|string|null myName The alias for a rule, or an array of options.
     * @param array<string, mixed> myOptions List of extra options to pass to the rule callable as
     * second argument.
     * @return this
     */
    function addUpdate(callable $rule, myName = null, array myOptions = []) {
        _updateRules[] = _addError($rule, myName, myOptions);

        return this;
    }

    /**
     * Adds a rule that will be applied to the entity on delete operations.
     *
     * ### Options
     *
     * The options array accept the following special keys:
     *
     * - `errorField`: The name of the entity field that will be marked as invalid
     *    if the rule does not pass.
     * - `message`: The error message to set to `errorField` if the rule does not pass.
     *
     * @param callable $rule A callable function or object that will return whether
     * the entity is valid or not.
     * @param array|string|null myName The alias for a rule, or an array of options.
     * @param array<string, mixed> myOptions List of extra options to pass to the rule callable as
     * second argument.
     * @return this
     */
    function addDelete(callable $rule, myName = null, array myOptions = []) {
        _deleteRules[] = _addError($rule, myName, myOptions);

        return this;
    }

    /**
     * Runs each of the rules by passing the provided entity and returns true if all
     * of them pass. The rules to be applied are depended on the myMode parameter which
     * can only be RulesChecker::CREATE, RulesChecker::UPDATE or RulesChecker::DELETE
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param string myMode Either "create, "update" or "delete".
     * @param array<string, mixed> myOptions Extra options to pass to checker functions.
     * @return bool
     * @throws \InvalidArgumentException if an invalid mode is passed.
     */
    bool check(IEntity $entity, string myMode, array myOptions = []) {
        if (myMode == self::CREATE) {
            return this.checkCreate($entity, myOptions);
        }

        if (myMode == self::UPDATE) {
            return this.checkUpdate($entity, myOptions);
        }

        if (myMode == self::DELETE) {
            return this.checkDelete($entity, myOptions);
        }

        throw new InvalidArgumentException("Wrong checking mode: " . myMode);
    }

    /**
     * Runs each of the rules by passing the provided entity and returns true if all
     * of them pass. The rules selected will be only those specified to be run on "create"
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param array<string, mixed> myOptions Extra options to pass to checker functions.
     */
    bool checkCreate(IEntity $entity, array myOptions = []) {
        return _checkRules($entity, myOptions, array_merge(_rules, _createRules));
    }

    /**
     * Runs each of the rules by passing the provided entity and returns true if all
     * of them pass. The rules selected will be only those specified to be run on "update"
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param array<string, mixed> myOptions Extra options to pass to checker functions.
     */
    bool checkUpdate(IEntity $entity, array myOptions = []) {
        return _checkRules($entity, myOptions, array_merge(_rules, _updateRules));
    }

    /**
     * Runs each of the rules by passing the provided entity and returns true if all
     * of them pass. The rules selected will be only those specified to be run on "delete"
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param array<string, mixed> myOptions Extra options to pass to checker functions.
     */
    bool checkDelete(IEntity $entity, array myOptions = []) {
        return _checkRules($entity, myOptions, _deleteRules);
    }

    /**
     * Used by top level functions checkDelete, checkCreate and checkUpdate, this function
     * iterates an array containing the rules to be checked and checks them all.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to check for validity.
     * @param array<string, mixed> myOptions Extra options to pass to checker functions.
     * @param array<\Cake\Datasource\RuleInvoker> $rules The list of rules that must be checked.
     */
    protected bool _checkRules(IEntity $entity, array myOptions = [], array $rules = []) {
        $success = true;
        myOptions += _options;
        foreach ($rules as $rule) {
            $success = $rule($entity, myOptions) && $success;
        }

        return $success;
    }

    /**
     * Utility method for decorating any callable so that if it returns false, the correct
     * property in the entity is marked as invalid.
     *
     * @param callable|\Cake\Datasource\RuleInvoker $rule The rule to decorate
     * @param array|string|null myName The alias for a rule or an array of options
     * @param array<string, mixed> myOptions The options containing the error message and field.
     * @return \Cake\Datasource\RuleInvoker
     */
    protected auto _addError(callable $rule, myName = null, array myOptions = []): RuleInvoker
    {
        if (is_array(myName)) {
            myOptions = myName;
            myName = null;
        }

        if (!($rule instanceof RuleInvoker)) {
            $rule = new RuleInvoker($rule, myName, myOptions);
        } else {
            $rule.setOptions(myOptions).setName(myName);
        }

        return $rule;
    }
}
