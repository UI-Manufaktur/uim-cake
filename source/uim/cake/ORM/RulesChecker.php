
module uim.cake.ORM;

import uim.cake.datasources.RuleInvoker;
import uim.cake.datasources.RulesChecker as BaseRulesChecker;
import uim.cake.orm.Rule\ExistsIn;
import uim.cake.orm.Rule\IsUnique;
import uim.cake.orm.Rule\LinkConstraint;
import uim.cake.orm.Rule\ValidCount;
import uim.cake.utilities.Inflector;

/**
 * ORM flavoured rules checker.
 *
 * Adds ORM related features to the RulesChecker class.
 *
 * @see uim.cake.datasources.RulesChecker
 */
class RulesChecker : BaseRulesChecker
{
    /**
     * Returns a callable that can be used as a rule for checking the uniqueness of a value
     * in the table.
     *
     * ### Example
     *
     * ```
     * $rules.add($rules.isUnique(["email"], "The email should be unique"));
     * ```
     *
     * ### Options
     *
     * - `allowMultipleNulls` Allows any field to have multiple null values. Defaults to false.
     *
     * @param array<string> $fields The list of fields to check for uniqueness.
     * @param array<string, mixed>|string|null $message The error message to show in case the rule does not pass. Can
     *   also be an array of options. When an array, the "message" key can be used to provide a message.
     * @return uim.cake.Datasource\RuleInvoker
     */
    function isUnique(array $fields, $message = null): RuleInvoker
    {
        $options = is_array($message) ? $message : ["message": $message];
        $message = $options["message"] ?? null;
        unset($options["message"]);

        if (!$message) {
            if (_useI18n) {
                $message = __d("cake", "This value is already in use");
            } else {
                $message = "This value is already in use";
            }
        }

        $errorField = current($fields);

        return _addError(new IsUnique($fields, $options), "_isUnique", compact("errorField", "message"));
    }

    /**
     * Returns a callable that can be used as a rule for checking that the values
     * extracted from the entity to check exist as the primary key in another table.
     *
     * This is useful for enforcing foreign key integrity checks.
     *
     * ### Example:
     *
     * ```
     * $rules.add($rules.existsIn("author_id", "Authors", "Invalid Author"));
     *
     * $rules.add($rules.existsIn("site_id", new SitesTable(), "Invalid Site"));
     * ```
     *
     * Available $options are error "message" and "allowNullableNulls" flag.
     * "message" sets a custom error message.
     * Set "allowNullableNulls" to true to accept composite foreign keys where one or more nullable columns are null.
     *
     * @param array<string>|string $field The field or list of fields to check for existence by
     * primary key lookup in the other table.
     * @param uim.cake.ORM\Table|\Cake\ORM\Association|string $table The table name where the fields existence will be checked.
     * @param array<string, mixed>|string|null $message The error message to show in case the rule does not pass. Can
     *   also be an array of options. When an array, the "message" key can be used to provide a message.
     * @return uim.cake.Datasource\RuleInvoker
     */
    function existsIn($field, $table, $message = null): RuleInvoker
    {
        $options = [];
        if (is_array($message)) {
            $options = $message + ["message": null];
            $message = $options["message"];
            unset($options["message"]);
        }

        if (!$message) {
            if (_useI18n) {
                $message = __d("cake", "This value does not exist");
            } else {
                $message = "This value does not exist";
            }
        }

        $errorField = is_string($field) ? $field : current($field);

        return _addError(new ExistsIn($field, $table, $options), "_existsIn", compact("errorField", "message"));
    }

    /**
     * Validates whether links to the given association exist.
     *
     * ### Example:
     *
     * ```
     * $rules.addUpdate($rules.isLinkedTo("Articles", "article"));
     * ```
     *
     * On a `Comments` table that has a `belongsTo Articles` association, this check would ensure that comments
     * can only be edited as long as they are associated to an existing article.
     *
     * @param uim.cake.ORM\Association|string $association The association to check for links.
     * @param string|null $field The name of the association property. When supplied, this is the name used to set
     *  possible errors. When absent, the name is inferred from `$association`.
     * @param string|null $message The error message to show in case the rule does not pass.
     * @return uim.cake.Datasource\RuleInvoker
     * @since 4.0.0
     */
    function isLinkedTo($association, ?string $field = null, ?string $message = null): RuleInvoker
    {
        return _addLinkConstraintRule(
            $association,
            $field,
            $message,
            LinkConstraint::STATUS_LINKED,
            "_isLinkedTo"
        );
    }

    /**
     * Validates whether links to the given association do not exist.
     *
     * ### Example:
     *
     * ```
     * $rules.addDelete($rules.isNotLinkedTo("Comments", "comments"));
     * ```
     *
     * On a `Articles` table that has a `hasMany Comments` association, this check would ensure that articles
     * can only be deleted when no associated comments exist.
     *
     * @param uim.cake.ORM\Association|string $association The association to check for links.
     * @param string|null $field The name of the association property. When supplied, this is the name used to set
     *  possible errors. When absent, the name is inferred from `$association`.
     * @param string|null $message The error message to show in case the rule does not pass.
     * @return uim.cake.Datasource\RuleInvoker
     * @since 4.0.0
     */
    function isNotLinkedTo($association, ?string $field = null, ?string $message = null): RuleInvoker
    {
        return _addLinkConstraintRule(
            $association,
            $field,
            $message,
            LinkConstraint::STATUS_NOT_LINKED,
            "_isNotLinkedTo"
        );
    }

    /**
     * Adds a link constraint rule.
     *
     * @param uim.cake.ORM\Association|string $association The association to check for links.
     * @param string|null $errorField The name of the property to use for setting possible errors. When absent,
     *   the name is inferred from `$association`.
     * @param string|null $message The error message to show in case the rule does not pass.
     * @param string $linkStatus The ink status required for the check to pass.
     * @param string $ruleName The alias/name of the rule.
     * @return uim.cake.Datasource\RuleInvoker
     * @throws \InvalidArgumentException In case the `$association` argument is of an invalid type.
     * @since 4.0.0
     * @see uim.cake.ORM\RulesChecker::isLinkedTo()
     * @see uim.cake.ORM\RulesChecker::isNotLinkedTo()
     * @see uim.cake.ORM\Rule\LinkConstraint::STATUS_LINKED
     * @see uim.cake.ORM\Rule\LinkConstraint::STATUS_NOT_LINKED
     */
    protected function _addLinkConstraintRule(
        $association,
        ?string $errorField,
        ?string $message,
        string $linkStatus,
        string $ruleName
    ): RuleInvoker {
        if ($association instanceof Association) {
            $associationAlias = $association.getName();

            if ($errorField == null) {
                $errorField = $association.getProperty();
            }
        } elseif (is_string($association)) {
            $associationAlias = $association;

            if ($errorField == null) {
                $repository = _options["repository"] ?? null;
                if ($repository instanceof Table) {
                    $association = $repository.getAssociation($association);
                    $errorField = $association.getProperty();
                } else {
                    $errorField = Inflector::underscore($association);
                }
            }
        } else {
            throw new \InvalidArgumentException(sprintf(
                "Argument 1 is expected to be of type `\Cake\ORM\Association|string`, `%s` given.",
                getTypeName($association)
            ));
        }

        if (!$message) {
            if (_useI18n) {
                $message = __d(
                    "cake",
                    "Cannot modify row: a constraint for the `{0}` association fails.",
                    $associationAlias
                );
            } else {
                $message = sprintf(
                    "Cannot modify row: a constraint for the `%s` association fails.",
                    $associationAlias
                );
            }
        }

        $rule = new LinkConstraint(
            $association,
            $linkStatus
        );

        return _addError($rule, $ruleName, compact("errorField", "message"));
    }

    /**
     * Validates the count of associated records.
     *
     * @param string $field The field to check the count on.
     * @param int $count The expected count.
     * @param string $operator The operator for the count comparison.
     * @param string|null $message The error message to show in case the rule does not pass.
     * @return uim.cake.Datasource\RuleInvoker
     */
    function validCount(
        string $field,
        int $count = 0,
        string $operator = ">",
        ?string $message = null
    ): RuleInvoker {
        if (!$message) {
            if (_useI18n) {
                $message = __d("cake", "The count does not match {0}{1}", [$operator, $count]);
            } else {
                $message = sprintf("The count does not match %s%d", $operator, $count);
            }
        }

        $errorField = $field;

        return _addError(
            new ValidCount($field),
            "_validCount",
            compact("count", "operator", "errorField", "message")
        );
    }
}
