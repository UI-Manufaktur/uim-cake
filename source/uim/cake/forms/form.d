/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Form;

@safe:
import uim.cake;


/**
 * Form abstraction used to create forms not tied to ORM backed models,
 * or to other permanent datastores. Ideal for implementing forms on top of
 * API services, or contact forms.
 *
 * ### Building a form
 *
 * This class is most useful when subclassed. In a subclass you
 * should define the `_buildSchema`, `validationDefault` and optionally,
 * the `_execute` methods. These allow you to declare your form"s
 * fields, validation and primary action respectively.
 *
 * Forms are conventionally placed in the `App\Form` namespace.
 */
class Form : IEventListener, IEventDispatcher, ValidatorAwareInterface
{
    use EventDispatcherTrait;
    use ValidatorAwareTrait;

    /**
     * Name of default validation set.
     */
    const string DEFAULT_VALIDATOR = "default";

    /**
     * The alias this object is assigned to validators as.
     */
    const string VALIDATOR_PROVIDER_NAME = "form";

    /**
     * The name of the event dispatched when a validator has been built.
     */
    const string BUILD_VALIDATOR_EVENT = "Form.buildValidator";

    /**
     * Schema class.
     *
     * @var string
     * @psalm-var class-string<uim.cake.Form\Schema>
     */
    protected _schemaClass = Schema::class;

    /**
     * The schema used by this form.
     *
     * @var uim.cake.Form\Schema|null
     */
    protected _schema;

    /**
     * The errors if any
     *
     * @var array
     */
    protected _errors = null;

    /**
     * Form"s data.
     *
     * @var array
     */
    protected _data = null;

    /**
     * Constructor
     *
     * @param uim.cake.events.EventManager|null $eventManager The event manager.
     *  Defaults to a new instance.
     */
    this(?EventManager $eventManager = null) {
        if ($eventManager != null) {
            this.setEventManager($eventManager);
        }

        this.getEventManager().on(this);

        if (method_exists(this, "_buildValidator")) {
            deprecationWarning(
                static::class ~ " : `_buildValidator` which is no longer used~ " ~
                "You should implement `buildValidator(Validator $validator, string aName) : void` " ~
                "or `validationDefault(Validator $validator): Validator` instead."
            );
        }
    }

    /**
     * Get the Form callbacks this form is interested in.
     *
     * The conventional method map is:
     *
     * - Form.buildValidator: buildValidator
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        if (method_exists(this, "buildValidator")) {
            return [
                self::BUILD_VALIDATOR_EVENT: "buildValidator",
            ];
        }

        return [];
    }

    /**
     * Set the schema for this form.
     *
     * @since 4.1.0
     * @param uim.cake.Form\Schema $schema The schema to set
     * @return this
     */
    function setSchema(Schema $schema) {
        _schema = $schema;

        return this;
    }

    /**
     * Get the schema for this form.
     *
     * This method will call `_buildSchema()` when the schema
     * is first built. This hook method lets you configure the
     * schema or load a pre-defined one.
     *
     * @since 4.1.0
     * @return uim.cake.Form\Schema the schema instance.
     */
    function getSchema(): Schema
    {
        if (_schema == null) {
            _schema = _buildSchema(new _schemaClass());
        }

        return _schema;
    }

    /**
     * Get/Set the schema for this form.
     *
     * This method will call `_buildSchema()` when the schema
     * is first built. This hook method lets you configure the
     * schema or load a pre-defined one.
     *
     * @deprecated 4.1.0 Use {@link setSchema()}/{@link getSchema()} instead.
     * @param uim.cake.Form\Schema|null $schema The schema to set, or null.
     * @return uim.cake.Form\Schema the schema instance.
     */
    function schema(?Schema $schema = null): Schema
    {
        deprecationWarning("Form::schema() is deprecated. Use setSchema() and getSchema() instead.");
        if ($schema != null) {
            this.setSchema($schema);
        }

        return this.getSchema();
    }

    /**
     * A hook method intended to be implemented by subclasses.
     *
     * You can use this method to define the schema using
     * the methods on {@link uim.cake.Form\Schema}, or loads a pre-defined
     * schema from a concrete class.
     *
     * @param uim.cake.Form\Schema $schema The schema to customize.
     * @return uim.cake.Form\Schema The schema to use.
     */
    protected function _buildSchema(Schema $schema): Schema
    {
        return $schema;
    }

    /**
     * Used to check if $data passes this form"s validation.
     *
     * @param array $data The data to check.
     * @param string|null $validator Validator name.
     * @return bool Whether the data is valid.
     * @throws \RuntimeException If validator is invalid.
     */
    bool validate(array $data, Nullable!string $validator = null) {
        _errors = this.getValidator($validator ?: static::DEFAULT_VALIDATOR)
            .validate($data);

        return count(_errors) == 0;
    }

    /**
     * Get the errors in the form
     *
     * Will return the errors from the last call
     * to `validate()` or `execute()`.
     *
     * @return array Last set validation errors.
     */
    array getErrors() {
        return _errors;
    }

    /**
     * Set the errors in the form.
     *
     * ```
     * $errors = [
     *      "field_name": ["rule_name": "message"]
     * ];
     *
     * $form.setErrors($errors);
     * ```
     *
     * @param array $errors Errors list.
     * @return this
     */
    function setErrors(array $errors) {
        _errors = $errors;

        return this;
    }

    /**
     * Execute the form if it is valid.
     *
     * First validates the form, then calls the `_execute()` hook method.
     * This hook method can be implemented in subclasses to perform
     * the action of the form. This may be sending email, interacting
     * with a remote API, or anything else you may need.
     *
     * ### Options:
     *
     * - validate: Set to `false` to disable validation. Can also be a string of the validator ruleset to be applied.
     *   Defaults to `true`/`"default"`.
     *
     * @param array $data Form data.
     * @param array<string, mixed> $options List of options.
     * @return bool False on validation failure, otherwise returns the
     *   result of the `_execute()` method.
     */
    bool execute(array $data, STRINGAA someOptions = null) {
        _data = $data;

        $options += ["validate": true];

        if ($options["validate"] == false) {
            return _execute($data);
        }

        $validator = $options["validate"] == true ? static::DEFAULT_VALIDATOR : $options["validate"];

        return this.validate($data, $validator) ? _execute($data) : false;
    }

    /**
     * Hook method to be implemented in subclasses.
     *
     * Used by `execute()` to execute the form"s action.
     *
     * @param array $data Form data.
     */
    protected bool _execute(array $data) {
        return true;
    }

    /**
     * Get field data.
     *
     * @param string|null $field The field name or null to get data array with
     *   all fields.
     * @return mixed
     */
    function getData(Nullable!string $field = null) {
        if ($field == null) {
            return _data;
        }

        return Hash::get(_data, $field);
    }

    /**
     * Saves a variable or an associative array of variables for use inside form data.
     *
     * @param array|string aName The key to write, can be a dot notation value.
     * Alternatively can be an array containing key(s) and value(s).
     * @param mixed $value Value to set for var
     * @return this
     */
    function set($name, $value = null) {
        $write = $name;
        if (!is_array($name)) {
            $write = [$name: $value];
        }

        /** @psalm-suppress PossiblyInvalidIterator */
        foreach ($write as $key: $val) {
            _data = Hash::insert(_data, $key, $val);
        }

        return this;
    }

    /**
     * Set form data.
     *
     * @param array $data Data array.
     * @return this
     */
    function setData(array $data) {
        _data = $data;

        return this;
    }

    /**
     * Get the printable version of a Form instance.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        $special = [
            "_schema": this.getSchema().__debugInfo(),
            "_errors": this.getErrors(),
            "_validator": this.getValidator().__debugInfo(),
        ];

        return $special + get_object_vars(this);
    }
}
