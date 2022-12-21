module uim.cake.Form;

import uim.cake.events\IEventDispatcher;
import uim.cake.events\EventDispatcherTrait;
import uim.cake.events\IEventListener;
import uim.cake.events\EventManager;
import uim.cake.utilities.Hash;
import uim.cake.validations\IValidatorAware;
import uim.cake.validations\ValidatorAwareTrait;

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
 * Forms are conventionally placed in the `App\Form` module.
 */
class Form : IEventListener, IEventDispatcher, IValidatorAware
{
    use EventDispatcherTrait;
    use ValidatorAwareTrait;

    /**
     * Name of default validation set.
     */
    public const string DEFAULT_VALIDATOR = "default";

    /**
     * The alias this object is assigned to validators as.
     */
    public const string VALIDATOR_PROVIDER_NAME = "form";

    /**
     * The name of the event dispatched when a validator has been built.
     */
    public const string BUILD_VALIDATOR_EVENT = "Form.buildValidator";

    /**
     * Schema class.
     * @psalm-var class-string<\Cake\Form\Schema>
     */
    protected string _schemaClass = Schema::class;

    /**
     * The schema used by this form.
     *
     * @var \Cake\Form\Schema|null
     */
    protected Schema $_schema;

    /**
     * The errors if any
     *
     * @var array
     */
    protected _errors = [];

    // Form"s data.
    protected array $_data = [];

    /**
     * Constructor
     *
     * @param \Cake\Event\EventManager|null myEventManager The event manager.
     *  Defaults to a new instance.
     */
    this(?EventManager myEventManager = null) {
        if (myEventManager !== null) {
            this.setEventManager(myEventManager);
        }

        this.getEventManager().on(this);

        if (method_exists(this, "_buildValidator")) {
            deprecationWarning(
                static::class . " : `_buildValidator` which is no longer used. " .
                "You should implement `buildValidator(Validator $validator, string myName): void` " .
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
     * @param \Cake\Form\Schema $schema The schema to set
     * @return this
     */
    auto setSchema(Schema $schema) {
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
     * @return \Cake\Form\Schema the schema instance.
     */
    auto getSchema(): Schema
    {
        if (_schema is null) {
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
     * @param \Cake\Form\Schema|null $schema The schema to set, or null.
     * @return \Cake\Form\Schema the schema instance.
     */
    function schema(?Schema $schema = null): Schema
    {
        deprecationWarning("Form::schema() is deprecated. Use setSchema() and getSchema() instead.");
        if ($schema !== null) {
            this.setSchema($schema);
        }

        return this.getSchema();
    }

    /**
     * A hook method intended to be implemented by subclasses.
     *
     * You can use this method to define the schema using
     * the methods on {@link \Cake\Form\Schema}, or loads a pre-defined
     * schema from a concrete class.
     *
     * @param \Cake\Form\Schema $schema The schema to customize.
     * @return \Cake\Form\Schema The schema to use.
     */
    protected auto _buildSchema(Schema $schema): Schema
    {
        return $schema;
    }

    /**
     * Used to check if myData passes this form"s validation.
     *
     * @param array myData The data to check.
     * @param string|null $validator Validator name.
     * @return bool Whether the data is valid.
     * @throws \RuntimeException If validator is invalid.
     */
    bool validate(array myData, Nullable!string validator = null) {
        _errors = this.getValidator($validator ?: static::DEFAULT_VALIDATOR)
            .validate(myData);

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
     * myErrors = [
     *      "field_name":["rule_name":"message"]
     * ];
     *
     * $form.setErrors(myErrors);
     * ```
     *
     * @param array myErrors Errors list.
     * @return this
     */
    auto setErrors(array myErrors) {
        _errors = myErrors;

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
     * @param array myData Form data.
     * @param array myOptions List of options.
     * @return bool False on validation failure, otherwise returns the
     *   result of the `_execute()` method.
     */
    bool execute(array myData, array myOptions = []) {
        _data = myData;

        myOptions += ["validate":true];

        if (myOptions["validate"] == false) {
            return _execute(myData);
        }

        $validator = myOptions["validate"] == true ? static::DEFAULT_VALIDATOR : myOptions["validate"];

        return this.validate(myData, $validator) ? _execute(myData) : false;
    }

    /**
     * Hook method to be implemented in subclasses.
     *
     * Used by `execute()` to execute the form"s action.
     *
     * @param array myData Form data.
     */
    protected bool _execute(array myData) {
        return true;
    }

    /**
     * Get field data.
     *
     * @param string|null myField The field name or null to get data array with
     *   all fields.
     * @return mixed
     */
    auto getData(Nullable!string myField = null) {
        if (myField is null) {
            return _data;
        }

        return Hash::get(_data, myField);
    }

    /**
     * Saves a variable or an associative array of variables for use inside form data.
     *
     * @param array|string myName The key to write, can be a dot notation value.
     * Alternatively can be an array containing key(s) and value(s).
     * @param mixed myValue Value to set for var
     * @return this
     */
    auto set(myName, myValue = null) {
        $write = myName;
        if (!is_array(myName)) {
            $write = [myName: myValue];
        }

        /** @psalm-suppress PossiblyInvalidIterator */
        foreach ($write as myKey: $val) {
            _data = Hash::insert(_data, myKey, $val);
        }

        return this;
    }

    /**
     * Set form data.
     *
     * @param array myData Data array.
     * @return this
     */
    auto setData(array myData) {
        _data = myData;

        return this;
    }

    /**
     * Get the printable version of a Form instance.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        $special = [
            "_schema":this.getSchema().__debugInfo(),
            "_errors":this.getErrors(),
            "_validator":this.getValidator().__debugInfo(),
        ];

        return $special + get_object_vars(this);
    }
}
