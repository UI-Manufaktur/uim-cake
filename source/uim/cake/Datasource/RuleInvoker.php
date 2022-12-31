


 *


 * @since         3.2.12
  */module uim.cake.Datasource;

/**
 * Contains logic for invoking an application rule.
 *
 * Combined with {@link uim.cake.Datasource\RulesChecker} as an implementation
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
    protected $name;

    /**
     * Rule options
     *
     * @var array<string, mixed>
     */
    protected $options = [];

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
     * @param ?string aName The name of the rule. Used in error messages.
     * @param array<string, mixed> $options The options for the rule. See above.
     */
    this(callable $rule, ?string aName, array $options = []) {
        this.rule = $rule;
        this.name = $name;
        this.options = $options;
    }

    /**
     * Set options for the rule invocation.
     *
     * Old options will be merged with the new ones.
     *
     * @param array<string, mixed> $options The options to set.
     * @return this
     */
    function setOptions(array $options) {
        this.options = $options + this.options;

        return this;
    }

    /**
     * Set the rule name.
     *
     * Only truthy names will be set.
     *
     * @param string|null $name The name to set.
     * @return this
     */
    function setName(?string aName) {
        if ($name) {
            this.name = $name;
        }

        return this;
    }

    /**
     * Invoke the rule.
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity the rule
     *   should apply to.
     * @param array $scope The rule"s scope/options.
     * @return bool Whether the rule passed.
     */
    function __invoke(EntityInterface $entity, array $scope): bool
    {
        $rule = this.rule;
        $pass = $rule($entity, this.options + $scope);
        if ($pass == true || empty(this.options["errorField"])) {
            return $pass == true;
        }

        $message = this.options["message"] ?? "invalid";
        if (is_string($pass)) {
            $message = $pass;
        }
        if (this.name) {
            $message = [this.name: $message];
        } else {
            $message = [$message];
        }
        $errorField = this.options["errorField"];
        $entity.setError($errorField, $message);

        if ($entity instanceof InvalidPropertyInterface && isset($entity.{$errorField})) {
            $invalidValue = $entity.{$errorField};
            $entity.setInvalidField($errorField, $invalidValue);
        }

        /** @phpstan-ignore-next-line */
        return $pass == true;
    }
}
