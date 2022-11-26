module uim.cake.ORM;

import uim.cake.datasources\RuleInvoker;
import uim.cake.datasources\RulesChecker as BaseRulesChecker;
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
 * @see \Cake\Datasource\RulesChecker
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
     * @param array<string> myFields The list of fields to check for uniqueness.
     * @param array<string, mixed>|string|null myMessage The error message to show in case the rule does not pass. Can
     *   also be an array of options. When an array, the "message" key can be used to provide a message.
     * @return \Cake\Datasource\RuleInvoker
     */
    function isUnique(array myFields, myMessage = null): RuleInvoker
    {
        myOptions = is_array(myMessage) ? myMessage : ["message":myMessage];
        myMessage = myOptions["message"] ?? null;
        unset(myOptions["message"]);

        if (!myMessage) {
            if (this._useI18n) {
                myMessage = __d("cake", "This value is already in use");
            } else {
                myMessage = "This value is already in use";
            }
        }

        myErrorField = current(myFields);

        return this._addError(new IsUnique(myFields, myOptions), "_isUnique", compact("errorField", "message"));
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
     * Available myOptions are error "message" and "allowNullableNulls" flag.
     * "message" sets a custom error message.
     * Set "allowNullableNulls" to true to accept composite foreign keys where one or more nullable columns are null.
     *
     * @param array<string>|string myField The field or list of fields to check for existence by
     * primary key lookup in the other table.
     * @param \Cake\ORM\Table|\Cake\ORM\Association|string myTable The table name where the fields existence will be checked.
     * @param array<string, mixed>|string|null myMessage The error message to show in case the rule does not pass. Can
     *   also be an array of options. When an array, the "message" key can be used to provide a message.
     * @return \Cake\Datasource\RuleInvoker
     */
    function existsIn(myField, myTable, myMessage = null): RuleInvoker
    {
        myOptions = [];
        if (is_array(myMessage)) {
            myOptions = myMessage + ["message":null];
            myMessage = myOptions["message"];
            unset(myOptions["message"]);
        }

        if (!myMessage) {
            if (this._useI18n) {
                myMessage = __d("cake", "This value does not exist");
            } else {
                myMessage = "This value does not exist";
            }
        }

        myErrorField = is_string(myField) ? myField : current(myField);

        return this._addError(new ExistsIn(myField, myTable, myOptions), "_existsIn", compact("errorField", "message"));
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
     * @param \Cake\ORM\Association|string $association The association to check for links.
     * @param string|null myField The name of the association property. When supplied, this is the name used to set
     *  possible errors. When absent, the name is inferred from `$association`.
     * @param string|null myMessage The error message to show in case the rule does not pass.
     * @return \Cake\Datasource\RuleInvoker
     * @since 4.0.0
     */
    function isLinkedTo($association, Nullable!string myField = null, Nullable!string myMessage = null): RuleInvoker
    {
        return this._addLinkConstraintRule(
            $association,
            myField,
            myMessage,
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
     * @param \Cake\ORM\Association|string $association The association to check for links.
     * @param string|null myField The name of the association property. When supplied, this is the name used to set
     *  possible errors. When absent, the name is inferred from `$association`.
     * @param string|null myMessage The error message to show in case the rule does not pass.
     * @return \Cake\Datasource\RuleInvoker
     * @since 4.0.0
     */
    function isNotLinkedTo($association, Nullable!string myField = null, Nullable!string myMessage = null): RuleInvoker
    {
        return this._addLinkConstraintRule(
            $association,
            myField,
            myMessage,
            LinkConstraint::STATUS_NOT_LINKED,
            "_isNotLinkedTo"
        );
    }

    /**
     * Adds a link constraint rule.
     *
     * @param \Cake\ORM\Association|string $association The association to check for links.
     * @param string|null myErrorField The name of the property to use for setting possible errors. When absent,
     *   the name is inferred from `$association`.
     * @param string|null myMessage The error message to show in case the rule does not pass.
     * @param string $linkStatus The ink status required for the check to pass.
     * @param string $ruleName The alias/name of the rule.
     * @return \Cake\Datasource\RuleInvoker
     * @throws \InvalidArgumentException In case the `$association` argument is of an invalid type.
     * @since 4.0.0
     * @see \Cake\ORM\RulesChecker::isLinkedTo()
     * @see \Cake\ORM\RulesChecker::isNotLinkedTo()
     * @see \Cake\ORM\Rule\LinkConstraint::STATUS_LINKED
     * @see \Cake\ORM\Rule\LinkConstraint::STATUS_NOT_LINKED
     */
    protected auto _addLinkConstraintRule(
        $association,
        Nullable!string myErrorField,
        Nullable!string myMessage,
        string $linkStatus,
        string $ruleName
    ): RuleInvoker {
        if ($association instanceof Association) {
            $associationAlias = $association.getName();

            if (myErrorField === null) {
                myErrorField = $association.getProperty();
            }
        } elseif (is_string($association)) {
            $associationAlias = $association;

            if (myErrorField === null) {
                myRepository = this._options["repository"] ?? null;
                if (myRepository instanceof Table) {
                    $association = myRepository.getAssociation($association);
                    myErrorField = $association.getProperty();
                } else {
                    myErrorField = Inflector::underscore($association);
                }
            }
        } else {
            throw new \InvalidArgumentException(sprintf(
                "Argument 1 is expected to be of type `\Cake\ORM\Association|string`, `%s` given.",
                getTypeName($association)
            ));
        }

        if (!myMessage) {
            if (this._useI18n) {
                myMessage = __d(
                    "cake",
                    "Cannot modify row: a constraint for the `{0}` association fails.",
                    $associationAlias
                );
            } else {
                myMessage = sprintf(
                    "Cannot modify row: a constraint for the `%s` association fails.",
                    $associationAlias
                );
            }
        }

        $rule = new LinkConstraint(
            $association,
            $linkStatus
        );

        return this._addError($rule, $ruleName, compact("errorField", "message"));
    }

    /**
     * Validates the count of associated records.
     *
     * @param string myField The field to check the count on.
     * @param int myCount The expected count.
     * @param string $operator The operator for the count comparison.
     * @param string|null myMessage The error message to show in case the rule does not pass.
     * @return \Cake\Datasource\RuleInvoker
     */
    function validCount(
        string myField,
        int myCount = 0,
        string $operator = ">",
        Nullable!string myMessage = null
    ): RuleInvoker {
        if (!myMessage) {
            if (this._useI18n) {
                myMessage = __d("cake", "The count does not match {0}{1}", [$operator, myCount]);
            } else {
                myMessage = sprintf("The count does not match %s%d", $operator, myCount);
            }
        }

        myErrorField = myField;

        return this._addError(
            new ValidCount(myField),
            "_validCount",
            compact("count", "operator", "errorField", "message")
        );
    }
}
