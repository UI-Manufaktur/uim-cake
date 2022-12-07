module uim.cake.views.forms;

import uim.cakeilities.Hash;

/**
 * Provides a context provider for {@link \Cake\Form\Form} instances.
 *
 * This context provider simply fulfils the interface requirements
 * that FormHelper has and allows access to the form data.
 */
class FormContext : IContext
{
    /**
     * The form object.
     *
     * @var \Cake\Form\Form
     */
    protected $_form;

    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
        $context += [
            "entity" => null,
        ];
        this._form = $context["entity"];
    }

    /**
     * Get the fields used in the context as a primary key.
     *
     * @return array<string>
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    function primaryKey(): array
    {
        deprecationWarning("`FormContext::primaryKey()` is deprecated. Use `FormContext::getPrimaryKey()`.");

        return [];
    }


    auto getPrimaryKey(): array
    {
        return [];
    }


    bool isPrimaryKey(string myField) {
        return false;
    }


    bool isCreate() {
        return true;
    }


    function val(string myField, array myOptions = []) {
        myOptions += [
            "default" => null,
            "schemaDefault" => true,
        ];

        $val = this._form.getData(myField);
        if ($val !== null) {
            return $val;
        }

        if (myOptions["default"] !== null || !myOptions["schemaDefault"]) {
            return myOptions["default"];
        }

        return this._schemaDefault(myField);
    }

    /**
     * Get default value from form schema for given field.
     *
     * @param string myField Field name.
     * @return mixed
     */
    protected auto _schemaDefault(string myField) {
        myField = this._form.getSchema().field(myField);
        if (myField) {
            return myField["default"];
        }

        return null;
    }


    function isRequired(string myField): ?bool
    {
        $validator = this._form.getValidator();
        if (!$validator.hasField(myField)) {
            return null;
        }
        if (this.type(myField) !== "boolean") {
            return !$validator.isEmptyAllowed(myField, this.isCreate());
        }

        return false;
    }


    auto getRequiredMessage(string myField): Nullable!string
    {
        $parts = explode(".", myField);

        $validator = this._form.getValidator();
        myFieldName = array_pop($parts);
        if (!$validator.hasField(myFieldName)) {
            return null;
        }

        $ruleset = $validator.field(myFieldName);
        if (!$ruleset.isEmptyAllowed()) {
            return $validator.getNotEmptyMessage(myFieldName);
        }

        return null;
    }


    auto getMaxLength(string myField): Nullable!int
    {
        $validator = this._form.getValidator();
        if (!$validator.hasField(myField)) {
            return null;
        }
        foreach ($validator.field(myField).rules() as $rule) {
            if ($rule.get("rule") === "maxLength") {
                return $rule.get("pass")[0];
            }
        }

        $attributes = this.attributes(myField);
        if (!empty($attributes["length"])) {
            return $attributes["length"];
        }

        return null;
    }


    function fieldNames(): array
    {
        return this._form.getSchema().fields();
    }


    function type(string myField): Nullable!string
    {
        return this._form.getSchema().fieldType(myField);
    }


    function attributes(string myField): array
    {
        return array_intersect_key(
            (array)this._form.getSchema().field(myField),
            array_flip(static::VALID_ATTRIBUTES)
        );
    }

    bool hasError(string myField) {
        myErrors = this.error(myField);

        return count(myErrors) > 0;
    }

    function error(string myField): array
    {
        return (array)Hash::get(this._form.getErrors(), myField, []);
    }
}
