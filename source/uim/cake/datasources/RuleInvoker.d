

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.2.12
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.caketasources;

/**
 * Contains logic for invoking an application rule.
 *
 * Combined with {@link \Cake\Datasource\RulesChecker} as an implementation
 * detail to de-duplicate rule decoration and provide cleaner separation
 * of duties.
 *
 * @internal
 */
class RuleInvoker
{
    /**
     * The rule name
     *
     * @var string|null
     */
    protected string myName;

    /**
     * Rule options
     *
     * @var array
     */
    protected myOptions = [];

    /**
     * Rule callable
     *
     * @var callable
     */
    protected $rule;

    /**
     * Constructor
     *
     * ### Options
     *
     * - `errorField` The field errors should be set onto.
     * - `message` The error message.
     *
     * Individual rules may have additional options that can be
     * set here. Any options will be passed into the rule as part of the
     * rule $scope.
     *
     * @param callable $rule The rule to be invoked.
     * @param Nullable!string myName The name of the rule. Used in error messages.
     * @param array<string, mixed> myOptions The options for the rule. See above.
     */
    this(callable $rule, Nullable!string myName, array myOptions = []) {
        this.rule = $rule;
        this.name = myName;
        this.options = myOptions;
    }

    /**
     * Set options for the rule invocation.
     *
     * Old options will be merged with the new ones.
     *
     * @param array<string, mixed> myOptions The options to set.
     * @return this
     */
    auto setOptions(array myOptions) {
        this.options = myOptions + this.options;

        return this;
    }

    /**
     * Set the rule name.
     *
     * Only truthy names will be set.
     *
     * @param string|null myName The name to set.
     * @return this
     */
    auto setName(Nullable!string myName) {
        if (myName) {
            this.name = myName;
        }

        return this;
    }

    /**
     * Invoke the rule.
     *
     * @param \Cake\Datasource\IEntity $entity The entity the rule
     *   should apply to.
     * @param array $scope The rule's scope/options.
     * @return bool Whether the rule passed.
     */
    bool __invoke(IEntity $entity, array $scope) {
        $rule = this.rule;
        $pass = $rule($entity, this.options + $scope);
        if ($pass === true || empty(this.options['errorField'])) {
            return $pass === true;
        }

        myMessage = this.options['message'] ?? 'invalid';
        if (is_string($pass)) {
            myMessage = $pass;
        }
        if (this.name) {
            myMessage = [this.name => myMessage];
        } else {
            myMessage = [myMessage];
        }
        myErrorField = this.options['errorField'];
        $entity.setError(myErrorField, myMessage);

        if ($entity instanceof InvalidPropertyInterface && isset($entity.{myErrorField})) {
            $invalidValue = $entity.{myErrorField};
            $entity.setInvalidField(myErrorField, $invalidValue);
        }

        return $pass === true;
    }
}
