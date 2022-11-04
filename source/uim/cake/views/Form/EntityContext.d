module uim.cake.View\Form;

use ArrayAccess;
import uim.cake.collection\Collection;
import uim.cake.Datasource\IEntity;
import uim.cake.Datasource\InvalidPropertyInterface;
import uim.cake.ORM\Entity;
import uim.cake.ORM\Locator\LocatorAwareTrait;
import uim.cake.ORM\Table;
import uim.cake.Utility\Inflector;
import uim.cake.validations\Validator;
use RuntimeException;
use Traversable;

/**
 * Provides a form context around a single entity and its relations.
 * It also can be used as context around an array or iterator of entities.
 *
 * This class lets FormHelper interface with entities or collections
 * of entities.
 *
 * Important Keys:
 *
 * - `entity` The entity this context is operating on.
 * - `table` Either the ORM\Table instance to fetch schema/validators
 *   from, an array of table instances in the case of a form spanning
 *   multiple entities, or the name(s) of the table.
 *   If this is null the table name(s) will be determined using naming
 *   conventions.
 * - `validator` Either the Validation\Validator to use, or the name of the
 *   validation method to call on the table object. For example 'default'.
 *   Defaults to 'default'. Can be an array of table alias=>validators when
 *   dealing with associated forms.
 */
class EntityContext : IContext
{
    use LocatorAwareTrait;

    /**
     * Context data for this object.
     *
     * @var array
     */
    protected $_context;

    /**
     * The name of the top level entity/table object.
     *
     * @var string
     */
    protected $_rootName;

    /**
     * Boolean to track whether the entity is a
     * collection.
     *
     * @var bool
     */
    protected $_isCollection = false;

    /**
     * A dictionary of tables
     *
     * @var array<\Cake\ORM\Table>
     */
    protected $_tables = [];

    /**
     * Dictionary of validators.
     *
     * @var array<\Cake\Validation\Validator>
     */
    protected $_validator = [];

    /**
     * Constructor.
     *
     * @param array $context Context info.
     */
    this(array $context) {
        $context += [
            'entity' => null,
            'table' => null,
            'validator' => [],
        ];
        this._context = $context;
        this._prepare();
    }

    /**
     * Prepare some additional data from the context.
     *
     * If the table option was provided to the constructor and it
     * was a string, TableLocator will be used to get the correct table instance.
     *
     * If an object is provided as the table option, it will be used as is.
     *
     * If no table option is provided, the table name will be derived based on
     * naming conventions. This inference will work with a number of common objects
     * like arrays, Collection objects and ResultSets.
     *
     * @return void
     * @throws \RuntimeException When a table object cannot be located/inferred.
     */
    protected auto _prepare(): void
    {
        /** @var \Cake\ORM\Table|null myTable */
        myTable = this._context['table'];
        /** @var \Cake\Datasource\IEntity|iterable $entity */
        $entity = this._context['entity'];
        if (empty(myTable)) {
            if (is_iterable($entity)) {
                foreach ($entity as $e) {
                    $entity = $e;
                    break;
                }
            }
            $isEntity = $entity instanceof IEntity;

            if ($isEntity) {
                /** @psalm-suppress PossiblyInvalidMethodCall */
                myTable = $entity.getSource();
            }
            if (!myTable && $isEntity && get_class($entity) !== Entity::class) {
                [, $entityClass] = moduleSplit(get_class($entity));
                myTable = Inflector::pluralize($entityClass);
            }
        }
        if (is_string(myTable) && myTable !== '') {
            myTable = this.getTableLocator().get(myTable);
        }

        if (!(myTable instanceof Table)) {
            throw new RuntimeException(
                'Unable to find table class for current entity.'
            );
        }
        this._isCollection = (
            is_array($entity) ||
            $entity instanceof Traversable
        );

        myAlias = this._rootName = myTable.getAlias();
        this._tables[myAlias] = myTable;
    }

    /**
     * Get the primary key data for the context.
     *
     * Gets the primary key columns from the root entity's schema.
     *
     * @return array<string>
     * @deprecated 4.0.0 Renamed to {@link getPrimaryKey()}.
     */
    function primaryKey(): array
    {
        deprecationWarning('`EntityContext::primaryKey()` is deprecated. Use `EntityContext::getPrimaryKey()`.');

        return (array)this._tables[this._rootName].getPrimaryKey();
    }

    /**
     * Get the primary key data for the context.
     *
     * Gets the primary key columns from the root entity's schema.
     *
     * @return array<string>
     */
    auto getPrimaryKey(): array
    {
        return (array)this._tables[this._rootName].getPrimaryKey();
    }

    /**
     * @inheritDoc
     */
    function isPrimaryKey(string myField): bool
    {
        $parts = explode('.', myField);
        myTable = this._getTable($parts);
        if (!myTable) {
            return false;
        }
        $primaryKey = (array)myTable.getPrimaryKey();

        return in_array(array_pop($parts), $primaryKey, true);
    }

    /**
     * Check whether this form is a create or update.
     *
     * If the context is for a single entity, the entity's isNew() method will
     * be used. If isNew() returns null, a create operation will be assumed.
     *
     * If the context is for a collection or array the first object in the
     * collection will be used.
     *
     * @return bool
     */
    function isCreate(): bool
    {
        $entity = this._context['entity'];
        if (is_iterable($entity)) {
            foreach ($entity as $e) {
                $entity = $e;
                break;
            }
        }
        if ($entity instanceof IEntity) {
            return $entity.isNew() !== false;
        }

        return true;
    }

    /**
     * Get the value for a given path.
     *
     * Traverses the entity data and finds the value for myPath.
     *
     * @param string myField The dot separated path to the value.
     * @param array<string, mixed> myOptions Options:
     *
     *   - `default`: Default value to return if no value found in data or
     *     entity.
     *   - `schemaDefault`: Boolean indicating whether default value from table
     *     schema should be used if it's not explicitly provided.
     * @return mixed The value of the field or null on a miss.
     */
    function val(string myField, array myOptions = []) {
        myOptions += [
            'default' => null,
            'schemaDefault' => true,
        ];

        if (empty(this._context['entity'])) {
            return myOptions['default'];
        }
        $parts = explode('.', myField);
        $entity = this.entity($parts);

        if ($entity && end($parts) === '_ids') {
            return this._extractMultiple($entity, $parts);
        }

        if ($entity instanceof IEntity) {
            $part = end($parts);

            if ($entity instanceof InvalidPropertyInterface) {
                $val = $entity.getInvalidField($part);
                if ($val !== null) {
                    return $val;
                }
            }

            $val = $entity.get($part);
            if ($val !== null) {
                return $val;
            }
            if (
                myOptions['default'] !== null
                || !myOptions['schemaDefault']
                || !$entity.isNew()
            ) {
                return myOptions['default'];
            }

            return this._schemaDefault($parts);
        }
        if (is_array($entity) || $entity instanceof ArrayAccess) {
            myKey = array_pop($parts);

            return $entity[myKey] ?? myOptions['default'];
        }

        return null;
    }

    /**
     * Get default value from table schema for given entity field.
     *
     * @param array<string> $parts Each one of the parts in a path for a field name
     * @return mixed
     */
    protected auto _schemaDefault(array $parts) {
        myTable = this._getTable($parts);
        if (myTable === null) {
            return null;
        }
        myField = end($parts);
        $defaults = myTable.getSchema().defaultValues();
        if (!array_key_exists(myField, $defaults)) {
            return null;
        }

        return $defaults[myField];
    }

    /**
     * Helper method used to extract all the primary key values out of an array, The
     * primary key column is guessed out of the provided myPath array
     *
     * @param mixed myValues The list from which to extract primary keys from
     * @param array<string> myPath Each one of the parts in a path for a field name
     * @return array|null
     */
    protected auto _extractMultiple(myValues, array myPath): ?array
    {
        if (!is_iterable(myValues)) {
            return null;
        }
        myTable = this._getTable(myPath, false);
        $primary = myTable ? (array)myTable.getPrimaryKey() : ['id'];

        return (new Collection(myValues)).extract($primary[0]).toArray();
    }

    /**
     * Fetch the entity or data value for a given path
     *
     * This method will traverse the given path and find the entity
     * or array value for a given path.
     *
     * If you only want the terminal Entity for a path use `leafEntity` instead.
     *
     * @param array|null myPath Each one of the parts in a path for a field name
     *  or null to get the entity passed in constructor context.
     * @return \Cake\Datasource\IEntity|iterable|null
     * @throws \RuntimeException When properties cannot be read.
     */
    function entity(?array myPath = null) {
        if (myPath === null) {
            return this._context['entity'];
        }

        $oneElement = count(myPath) === 1;
        if ($oneElement && this._isCollection) {
            return null;
        }
        $entity = this._context['entity'];
        if ($oneElement) {
            return $entity;
        }

        if (myPath[0] === this._rootName) {
            myPath = array_slice(myPath, 1);
        }

        $len = count(myPath);
        $last = $len - 1;
        for ($i = 0; $i < $len; $i++) {
            $prop = myPath[$i];
            $next = this._getProp($entity, $prop);
            $isLast = ($i === $last);
            if (!$isLast && $next === null && $prop !== '_ids') {
                myTable = this._getTable(myPath);
                if (myTable) {
                    return myTable.newEmptyEntity();
                }
            }

            $isTraversable = (
                is_iterable($next) ||
                $next instanceof IEntity
            );
            if ($isLast || !$isTraversable) {
                return $entity;
            }
            $entity = $next;
        }
        throw new RuntimeException(sprintf(
            'Unable to fetch property "%s"',
            implode('.', myPath)
        ));
    }

    /**
     * Fetch the terminal or leaf entity for the given path.
     *
     * Traverse the path until an entity cannot be found. Lists containing
     * entities will be traversed if the first element contains an entity.
     * Otherwise the containing Entity will be assumed to be the terminal one.
     *
     * @param array|null myPath Each one of the parts in a path for a field name
     *  or null to get the entity passed in constructor context.
     * @return array Containing the found entity, and remaining un-matched path.
     * @throws \RuntimeException When properties cannot be read.
     */
    protected auto leafEntity(myPath = null) {
        if (myPath === null) {
            return this._context['entity'];
        }

        $oneElement = count(myPath) === 1;
        if ($oneElement && this._isCollection) {
            throw new RuntimeException(sprintf(
                'Unable to fetch property "%s"',
                implode('.', myPath)
            ));
        }
        $entity = this._context['entity'];
        if ($oneElement) {
            return [$entity, myPath];
        }

        if (myPath[0] === this._rootName) {
            myPath = array_slice(myPath, 1);
        }

        $len = count(myPath);
        $leafEntity = $entity;
        for ($i = 0; $i < $len; $i++) {
            $prop = myPath[$i];
            $next = this._getProp($entity, $prop);

            // Did not dig into an entity, return the current one.
            if (is_array($entity) && !($next instanceof IEntity || $next instanceof Traversable)) {
                return [$leafEntity, array_slice(myPath, $i - 1)];
            }

            if ($next instanceof IEntity) {
                $leafEntity = $next;
            }

            // If we are at the end of traversable elements
            // return the last entity found.
            $isTraversable = (
                is_array($next) ||
                $next instanceof Traversable ||
                $next instanceof IEntity
            );
            if (!$isTraversable) {
                return [$leafEntity, array_slice(myPath, $i)];
            }
            $entity = $next;
        }
        throw new RuntimeException(sprintf(
            'Unable to fetch property "%s"',
            implode('.', myPath)
        ));
    }

    /**
     * Read property values or traverse arrays/iterators.
     *
     * @param mixed myTarget The entity/array/collection to fetch myField from.
     * @param string myField The next field to fetch.
     * @return mixed
     */
    protected auto _getProp(myTarget, myField) {
        if (is_array(myTarget) && isset(myTarget[myField])) {
            return myTarget[myField];
        }
        if (myTarget instanceof IEntity) {
            return myTarget.get(myField);
        }
        if (myTarget instanceof Traversable) {
            foreach (myTarget as $i => $val) {
                if ((string)$i === myField) {
                    return $val;
                }
            }

            return false;
        }

        return null;
    }

    /**
     * Check if a field should be marked as required.
     *
     * @param string myField The dot separated path to the field you want to check.
     * @return bool|null
     */
    function isRequired(string myField): ?bool
    {
        $parts = explode('.', myField);
        $entity = this.entity($parts);

        $isNew = true;
        if ($entity instanceof IEntity) {
            $isNew = $entity.isNew();
        }

        $validator = this._getValidator($parts);
        myFieldName = array_pop($parts);
        if (!$validator.hasField(myFieldName)) {
            return null;
        }
        if (this.type(myField) !== 'boolean') {
            return !$validator.isEmptyAllowed(myFieldName, $isNew);
        }

        return false;
    }

    /**
     * @inheritDoc
     */
    auto getRequiredMessage(string myField): ?string
    {
        $parts = explode('.', myField);

        $validator = this._getValidator($parts);
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

    /**
     * Get field length from validation
     *
     * @param string myField The dot separated path to the field you want to check.
     * @return int|null
     */
    auto getMaxLength(string myField): ?int
    {
        $parts = explode('.', myField);
        $validator = this._getValidator($parts);
        myFieldName = array_pop($parts);

        if ($validator.hasField(myFieldName)) {
            foreach ($validator.field(myFieldName).rules() as $rule) {
                if ($rule.get('rule') === 'maxLength') {
                    return $rule.get('pass')[0];
                }
            }
        }

        $attributes = this.attributes(myField);
        if (!empty($attributes['length'])) {
            return (int)$attributes['length'];
        }

        return null;
    }

    /**
     * Get the field names from the top level entity.
     *
     * If the context is for an array of entities, the 0th index will be used.
     *
     * @return array<string> Array of field names in the table/entity.
     */
    function fieldNames(): array
    {
        myTable = this._getTable('0');
        if (!myTable) {
            return [];
        }

        return myTable.getSchema().columns();
    }

    /**
     * Get the validator associated to an entity based on naming
     * conventions.
     *
     * @param array $parts Each one of the parts in a path for a field name
     * @return \Cake\Validation\Validator
     * @throws \RuntimeException If validator cannot be retrieved based on the parts.
     */
    protected auto _getValidator(array $parts): Validator
    {
        myKeyParts = array_filter(array_slice($parts, 0, -1), function ($part) {
            return !is_numeric($part);
        });
        myKey = implode('.', myKeyParts);
        $entity = this.entity($parts) ?: null;

        if (isset(this._validator[myKey])) {
            if (is_object($entity)) {
                this._validator[myKey].setProvider('entity', $entity);
            }

            return this._validator[myKey];
        }

        myTable = this._getTable($parts);
        if (!myTable) {
            throw new RuntimeException('Validator not found: ' . myKey);
        }
        myAlias = myTable.getAlias();

        $method = 'default';
        if (is_string(this._context['validator'])) {
            $method = this._context['validator'];
        } elseif (isset(this._context['validator'][myAlias])) {
            $method = this._context['validator'][myAlias];
        }

        $validator = myTable.getValidator($method);

        if (is_object($entity)) {
            $validator.setProvider('entity', $entity);
        }

        return this._validator[myKey] = $validator;
    }

    /**
     * Get the table instance from a property path
     *
     * @param \Cake\Datasource\IEntity|array<string>|string $parts Each one of the parts in a path for a field name
     * @param bool $fallback Whether to fallback to the last found table
     *  when a nonexistent field/property is being encountered.
     * @return \Cake\ORM\Table|null Table instance or null
     */
    protected auto _getTable($parts, $fallback = true): ?Table
    {
        if (!is_array($parts) || count($parts) === 1) {
            return this._tables[this._rootName];
        }

        $normalized = array_slice(array_filter($parts, function ($part) {
            return !is_numeric($part);
        }), 0, -1);

        myPath = implode('.', $normalized);
        if (isset(this._tables[myPath])) {
            return this._tables[myPath];
        }

        if (current($normalized) === this._rootName) {
            $normalized = array_slice($normalized, 1);
        }

        myTable = this._tables[this._rootName];
        $assoc = null;
        foreach ($normalized as $part) {
            if ($part === '_joinData') {
                if ($assoc !== null) {
                    myTable = $assoc.junction();
                    $assoc = null;
                    continue;
                }
            } else {
                $associationCollection = myTable.associations();
                $assoc = $associationCollection.getByProperty($part);
            }

            if ($assoc === null) {
                if ($fallback) {
                    break;
                }

                return null;
            }

            myTable = $assoc.getTarget();
        }

        return this._tables[myPath] = myTable;
    }

    /**
     * Get the abstract field type for a given field name.
     *
     * @param string myField A dot separated path to get a schema type for.
     * @return string|null An abstract data type or null.
     * @see \Cake\Database\TypeFactory
     */
    function type(string myField): ?string
    {
        $parts = explode('.', myField);
        myTable = this._getTable($parts);
        if (!myTable) {
            return null;
        }

        return myTable.getSchema().baseColumnType(array_pop($parts));
    }

    /**
     * Get an associative array of other attributes for a field name.
     *
     * @param string myField A dot separated path to get additional data on.
     * @return array An array of data describing the additional attributes on a field.
     */
    function attributes(string myField): array
    {
        $parts = explode('.', myField);
        myTable = this._getTable($parts);
        if (!myTable) {
            return [];
        }

        return array_intersect_key(
            (array)myTable.getSchema().getColumn(array_pop($parts)),
            array_flip(static::VALID_ATTRIBUTES)
        );
    }

    /**
     * Check whether a field has an error attached to it
     *
     * @param string myField A dot separated path to check errors on.
     * @return bool Returns true if the errors for the field are not empty.
     */
    function hasError(string myField): bool
    {
        return this.error(myField) !== [];
    }

    /**
     * Get the errors for a given field
     *
     * @param string myField A dot separated path to check errors on.
     * @return array An array of errors.
     */
    function error(string myField): array
    {
        $parts = explode('.', myField);
        try {
            [$entity, $remainingParts] = this.leafEntity($parts);
        } catch (RuntimeException $e) {
            return [];
        }
        if (count($remainingParts) === 0) {
            return $entity.getErrors();
        }

        if ($entity instanceof IEntity) {
            myError = $entity.getError(implode('.', $remainingParts));
            if (myError) {
                return myError;
            }

            return $entity.getError(array_pop($parts));
        }

        return [];
    }
}
