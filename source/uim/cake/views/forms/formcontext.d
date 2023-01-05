module uim.cake.views.forms;

import uim.cakeilities.Hash;

/**
 * Provides a context provider for {@link uim.cake.Form\Form} instances.
 *
 * This context provider simply fulfils the interface requirements
 * that FormHelper has and allows access to the form data.
 */
class FormContext : IContext
{
    /**
     * The form object.
     *
     * @var uim.cake.Form\Form
     */
    protected _form;

    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
        $context += [
            "entity": null,
        ];
        _form = $context["entity"];
    }

    /**
     * Get the fields used in the context as a primary key.
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    string[] primaryKey() {
        deprecationWarning("`FormContext::primaryKey()` is deprecated. Use `FormContext::getPrimaryKey()`.");

        return [];
    }


    auto getPrimaryKey() {
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
            "default": null,
            "schemaDefault": true,
        ];

        $val = _form.getData(myField);
        if ($val  !is null) {
            return $val;
        }

        if (myOptions["default"]  !is null || !myOptions["schemaDefault"]) {
            return myOptions["default"];
        }

        return _schemaDefault(myField);
    }

    /**
     * Get default value from form schema for given field.
     *
     * @param string myField Field name.
     * @return mixed
     */
    protected auto _schemaDefault(string myField) {
        myField = _form.getSchema().field(myField);
        if (myField) {
            return myField["default"];
        }

        return null;
    }


    bool isRequired(string myField): ?bool
    {
        $validator = _form.getValidator();
        if (!$validator.hasField(myField)) {
            return null;
        }
        if (this.type(myField) != "boolean") {
            return !$validator.isEmptyAllowed(myField, this.isCreate());
        }

        return false;
    }

    Nullable!string getRequiredMessage(string myField) {
        $parts = explode(".", myField);

        $validator = _form.getValidator();
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


    Nullable!int getMaxLength(string myField) {
        $validator = _form.getValidator();
        if (!$validator.hasField(myField)) {
            return null;
        }
        foreach ($validator.field(myField).rules() as $rule) {
            if ($rule.get("rule") == "maxLength") {
                return $rule.get("pass")[0];
            }
        }

        $attributes = this.attributes(myField);
        if (!empty($attributes["length"])) {
            return $attributes["length"];
        }

        return null;
    }


    array fieldNames() {
        return _form.getSchema().fields();
    }


    Nullable!string type(string myField) {
        return _form.getSchema().fieldType(myField);
    }


    array attributes(string myField) {
        return array_intersect_key(
            (array)_form.getSchema().field(myField),
            array_flip(static::VALID_ATTRIBUTES)
        );
    }

    bool hasError(string myField) {
        myErrors = this.error(myField);

        return count(myErrors) > 0;
    }

    array error(string myField) {
        return (array)Hash::get(_form.getErrors(), myField, []);
    }
}
