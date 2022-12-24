

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Form;

use Cake\Event\EventDispatcherInterface;
use Cake\Event\EventDispatcherTrait;
use Cake\Event\IEventListener;
use Cake\Event\EventManager;
use Cake\Utility\Hash;
use Cake\Validation\ValidatorAwareInterface;
use Cake\Validation\ValidatorAwareTrait;

/**
 * Form abstraction used to create forms not tied to ORM backed models,
 * or to other permanent datastores. Ideal for implementing forms on top of
 * API services, or contact forms.
 *
 * ### Building a form
 *
 * This class is most useful when subclassed. In a subclass you
 * should define the `_buildSchema`, `validationDefault` and optionally,
 * the `_execute` methods. These allow you to declare your form's
 * fields, validation and primary action respectively.
 *
 * Forms are conventionally placed in the `App\Form` namespace.
 */
class Form : IEventListener, EventDispatcherInterface, ValidatorAwareInterface
{
    use EventDispatcherTrait;
    use ValidatorAwareTrait;

    /**
     * Name of default validation set.
     *
     * @var string
     */
    public const DEFAULT_VALIDATOR = 'default';

    /**
     * The alias this object is assigned to validators as.
     *
     * @var string
     */
    public const VALIDATOR_PROVIDER_NAME = 'form';

    /**
     * The name of the event dispatched when a validator has been built.
     *
     * @var string
     */
    public const BUILD_VALIDATOR_EVENT = 'Form.buildValidator';

    /**
     * Schema class.
     *
     * @var string
     * @psalm-var class-string<\Cake\Form\Schema>
     */
    protected $_schemaClass = Schema::class;

    /**
     * The schema used by this form.
     *
     * @var \Cake\Form\Schema|null
     */
    protected $_schema;

    /**
     * The errors if any
     *
     * @var array
     */
    protected $_errors = [];

    /**
     * Form's data.
     *
     * @var array
     */
    protected $_data = [];

    /**
     * Constructor
     *
     * @param \Cake\Event\EventManager|null $eventManager The event manager.
     *  Defaults to a new instance.
     */
    public this(?EventManager $eventManager = null)
    {
        if ($eventManager != null) {
            this.setEventManager($eventManager);
        }

        this.getEventManager().on(this);

        if (method_exists(this, '_buildValidator')) {
            deprecationWarning(
                static::class . ' : `_buildValidator` which is no longer used. ' .
                'You should implement `buildValidator(Validator $validator, string $name): void` ' .
                'or `validationDefault(Validator $validator): Validator` instead.'
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
    function implementedEvents(): array
    {
        if (method_exists(this, 'buildValidator')) {
            return [
                self::BUILD_VALIDATOR_EVENT: 'buildValidator',
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
    function setSchema(Schema $schema)
    {
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
     * @param \Cake\Form\Schema|null $schema The schema to set, or null.
     * @return \Cake\Form\Schema the schema instance.
     */
    function schema(?Schema $schema = null): Schema
    {
        deprecationWarning('Form::schema() is deprecated. Use setSchema() and getSchema() instead.');
        if ($schema != null) {
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
    protected function _buildSchema(Schema $schema): Schema
    {
        return $schema;
    }

    /**
     * Used to check if $data passes this form's validation.
     *
     * @param array $data The data to check.
     * @param string|null $validator Validator name.
     * @return bool Whether the data is valid.
     * @throws \RuntimeException If validator is invalid.
     */
    function validate(array $data, ?string $validator = null): bool
    {
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
    function getErrors(): array
    {
        return _errors;
    }

    /**
     * Set the errors in the form.
     *
     * ```
     * $errors = [
     *      'field_name': ['rule_name': 'message']
     * ];
     *
     * $form.setErrors($errors);
     * ```
     *
     * @param array $errors Errors list.
     * @return this
     */
    function setErrors(array $errors)
    {
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
     *   Defaults to `true`/`'default'`.
     *
     * @param array $data Form data.
     * @param array<string, mixed> $options List of options.
     * @return bool False on validation failure, otherwise returns the
     *   result of the `_execute()` method.
     */
    function execute(array $data, array $options = []): bool
    {
        _data = $data;

        $options += ['validate': true];

        if ($options['validate'] == false) {
            return _execute($data);
        }

        $validator = $options['validate'] == true ? static::DEFAULT_VALIDATOR : $options['validate'];

        return this.validate($data, $validator) ? _execute($data) : false;
    }

    /**
     * Hook method to be implemented in subclasses.
     *
     * Used by `execute()` to execute the form's action.
     *
     * @param array $data Form data.
     * @return bool
     */
    protected function _execute(array $data): bool
    {
        return true;
    }

    /**
     * Get field data.
     *
     * @param string|null $field The field name or null to get data array with
     *   all fields.
     * @return mixed
     */
    function getData(?string $field = null)
    {
        if ($field == null) {
            return _data;
        }

        return Hash::get(_data, $field);
    }

    /**
     * Saves a variable or an associative array of variables for use inside form data.
     *
     * @param array|string $name The key to write, can be a dot notation value.
     * Alternatively can be an array containing key(s) and value(s).
     * @param mixed $value Value to set for var
     * @return this
     */
    function set($name, $value = null)
    {
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
    function setData(array $data)
    {
        _data = $data;

        return this;
    }

    /**
     * Get the printable version of a Form instance.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        $special = [
            '_schema': this.getSchema().__debugInfo(),
            '_errors': this.getErrors(),
            '_validator': this.getValidator().__debugInfo(),
        ];

        return $special + get_object_vars(this);
    }
}
