module uim.cake.View\Form;

import uim.cake.core.exceptions.CakeException;
import uim.cake.Form\Form;
import uim.cake.utilities.Hash;

/**
 * Provides a context provider for {@link uim.cake.Form\Form} instances.
 *
 * This context provider simply fulfils the interface requirements
 * that FormHelper has and allows access to the form data.
 */
class FormContext : ContextInterface
{
    /**
     * The form object.
     *
     * @var uim.cake.Form\Form
     */
    protected $_form;

    /**
     * Validator name.
     *
     * @var string|null
     */
    protected $_validator = null;

    /**
     * Constructor.
     *
     * @param array $context Context info.
     *
     * Keys:
     *
     * - `entity` The Form class instance this context is operating on. **(required)**
     * - `validator` Optional name of the validation method to call on the Form object.
     */
    this(array $context) {
        if (!isset($context["entity"]) || !$context["entity"] instanceof Form) {
            throw new CakeException("`$context[\"entity\"]` must be an instance of Cake\Form\Form");
        }

        _form = $context["entity"];
        _validator = $context["validator"] ?? null;
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


    function getPrimaryKey(): array
    {
        return [];
    }


    bool isPrimaryKey(string $field): bool
    {
        return false;
    }


    bool isCreate()
    {
        return true;
    }


    function val(string $field, array $options = []) {
        $options += [
            "default": null,
            "schemaDefault": true,
        ];

        $val = _form.getData($field);
        if ($val != null) {
            return $val;
        }

        if ($options["default"] != null || !$options["schemaDefault"]) {
            return $options["default"];
        }

        return _schemaDefault($field);
    }

    /**
     * Get default value from form schema for given field.
     *
     * @param string $field Field name.
     * @return mixed
     */
    protected function _schemaDefault(string $field) {
        $field = _form.getSchema().field($field);
        if ($field) {
            return $field["default"];
        }

        return null;
    }


    bool isRequired(string $field): ?bool
    {
        $validator = _form.getValidator(_validator);
        if (!$validator.hasField($field)) {
            return null;
        }
        if (this.type($field) != "boolean") {
            return !$validator.isEmptyAllowed($field, this.isCreate());
        }

        return false;
    }


    function getRequiredMessage(string $field): ?string
    {
        $parts = explode(".", $field);

        $validator = _form.getValidator(_validator);
        $fieldName = array_pop($parts);
        if (!$validator.hasField($fieldName)) {
            return null;
        }

        $ruleset = $validator.field($fieldName);
        if (!$ruleset.isEmptyAllowed()) {
            return $validator.getNotEmptyMessage($fieldName);
        }

        return null;
    }


    function getMaxLength(string $field): ?int
    {
        $validator = _form.getValidator(_validator);
        if (!$validator.hasField($field)) {
            return null;
        }
        foreach ($validator.field($field).rules() as $rule) {
            if ($rule.get("rule") == "maxLength") {
                return $rule.get("pass")[0];
            }
        }

        $attributes = this.attributes($field);
        if (!empty($attributes["length"])) {
            return $attributes["length"];
        }

        return null;
    }


    function fieldNames(): array
    {
        return _form.getSchema().fields();
    }


    function type(string $field): ?string
    {
        return _form.getSchema().fieldType($field);
    }


    function attributes(string $field): array
    {
        return array_intersect_key(
            (array)_form.getSchema().field($field),
            array_flip(static::VALID_ATTRIBUTES)
        );
    }


    function hasError(string $field): bool
    {
        $errors = this.error($field);

        return count($errors) > 0;
    }


    function error(string $field): array
    {
        return (array)Hash::get(_form.getErrors(), $field, []);
    }
}
