module uim.cake.ORM;

use ArrayObject;
use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.databases.Connection;
import uim.cake.databases.Schema\TableSchemaInterface;
import uim.cake.databases.TypeFactory;
import uim.cake.Datasource\ConnectionManager;
import uim.cake.Datasource\IEntity;
import uim.cake.Datasource\Exception\InvalidPrimaryKeyException;
import uim.cake.Datasource\IRepository;
import uim.cake.Datasource\RulesAwareTrait;
import uim.cake.Event\IEventDispatcher;
import uim.cake.Event\EventDispatcherTrait;
import uim.cake.Event\IEventListener;
import uim.cake.Event\EventManager;
import uim.cake.orm.Association\BelongsTo;
import uim.cake.orm.Association\BelongsToMany;
import uim.cake.orm.Association\HasMany;
import uim.cake.orm.Association\HasOne;
import uim.cake.orm.Exception\MissingEntityException;
import uim.cake.orm.Exception\PersistenceFailedException;
import uim.cake.orm.Exception\RolledbackTransactionException;
import uim.cake.orm.Rule\IsUnique;
import uim.cake.utikities.Inflector;
import uim.cake.validations\ValidatorAwareInterface;
import uim.cake.validations\ValidatorAwareTrait;
use Exception;
use InvalidArgumentException;
use RuntimeException;

/**
 * Represents a single database table.
 *
 * Exposes methods for retrieving data out of it, and manages the associations
 * this table has to other tables. Multiple instances of this class can be created
 * for the same database table with different aliases, this allows you to address
 * your database structure in a richer and more expressive way.
 *
 * ### Retrieving data
 *
 * The primary way to retrieve data is using Table::find(). See that method
 * for more information.
 *
 * ### Dynamic finders
 *
 * In addition to the standard find(myType) finder methods, CakePHP provides dynamic
 * finder methods. These methods allow you to easily set basic conditions up. For example
 * to filter users by username you would call
 *
 * ```
 * myQuery = myUsers.findByUsername('mark');
 * ```
 *
 * You can also combine conditions on multiple fields using either `Or` or `And`:
 *
 * ```
 * myQuery = myUsers.findByUsernameOrEmail('mark', 'mark@example.org');
 * ```
 *
 * ### Bulk updates/deletes
 *
 * You can use Table::updateAll() and Table::deleteAll() to do bulk updates/deletes.
 * You should be aware that events will *not* be fired for bulk updates/deletes.
 *
 * ### Events
 *
 * Table objects emit several events during as life-cycle hooks during find, delete and save
 * operations. All events use the CakePHP event package:
 *
 * - `Model.beforeFind` Fired before each find operation. By stopping the event and
 *   supplying a return value you can bypass the find operation entirely. Any
 *   changes done to the myQuery instance will be retained for the rest of the find. The
 *   `$primary` parameter indicates whether this is the root query, or an
 *   associated query.
 *
 * - `Model.buildValidator` Allows listeners to modify validation rules
 *   for the provided named validator.
 *
 * - `Model.buildRules` Allows listeners to modify the rules checker by adding more rules.
 *
 * - `Model.beforeRules` Fired before an entity is validated using the rules checker.
 *   By stopping this event, you can return the final value of the rules checking operation.
 *
 * - `Model.afterRules` Fired after the rules have been checked on the entity. By
 *   stopping this event, you can return the final value of the rules checking operation.
 *
 * - `Model.beforeSave` Fired before each entity is saved. Stopping this event will
 *   abort the save operation. When the event is stopped the result of the event will be returned.
 *
 * - `Model.afterSave` Fired after an entity is saved.
 *
 * - `Model.afterSaveCommit` Fired after the transaction in which the save operation is
 *   wrapped has been committed. It’s also triggered for non atomic saves where database
 *   operations are implicitly committed. The event is triggered only for the primary
 *   table on which save() is directly called. The event is not triggered if a
 *   transaction is started before calling save.
 *
 * - `Model.beforeDelete` Fired before an entity is deleted. By stopping this
 *   event you will abort the delete operation.
 *
 * - `Model.afterDelete` Fired after an entity has been deleted.
 *
 * ### Callbacks
 *
 * You can subscribe to the events listed above in your table classes by implementing the
 * lifecycle methods below:
 *
 * - `beforeFind(IEvent myEvent, Query myQuery, ArrayObject myOptions, boolean $primary)`
 * - `beforeMarshal(IEvent myEvent, ArrayObject myData, ArrayObject myOptions)`
 * - `afterMarshal(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `buildValidator(IEvent myEvent, Validator $validator, string myName)`
 * - `buildRules(RulesChecker $rules)`
 * - `beforeRules(IEvent myEvent, IEntity $entity, ArrayObject myOptions, string $operation)`
 * - `afterRules(IEvent myEvent, IEntity $entity, ArrayObject myOptions, bool myResult, string $operation)`
 * - `beforeSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `afterSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `afterSaveCommit(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `beforeDelete(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `afterDelete(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 * - `afterDeleteCommit(IEvent myEvent, IEntity $entity, ArrayObject myOptions)`
 *
 * @see \Cake\Event\EventManager for reference on the events system.
 * @link https://book.cakephp.org/4/en/orm/table-objects.html#event-list
 */
class Table : IRepository, IEventListener, IEventDispatcher, ValidatorAwareInterface
{
    use EventDispatcherTrait;
    use RulesAwareTrait;
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
    public const VALIDATOR_PROVIDER_NAME = 'table';

    /**
     * The name of the event dispatched when a validator has been built.
     *
     * @var string
     */
    public const BUILD_VALIDATOR_EVENT = 'Model.buildValidator';

    /**
     * The rules class name that is used.
     *
     * @var string
     */
    public const RULES_CLASS = RulesChecker::class;

    /**
     * The IsUnique class name that is used.
     *
     * @var string
     */
    public const IS_UNIQUE_CLASS = IsUnique::class;

    /**
     * Name of the table as it can be found in the database
     *
     * @var string|null
     */
    protected $_table;

    /**
     * Human name giving to this particular instance. Multiple objects representing
     * the same database table can exist by using different aliases.
     *
     * @var string|null
     */
    protected $_alias;

    /**
     * Connection instance
     *
     * @var \Cake\Database\Connection|null
     */
    protected $_connection;

    /**
     * The schema object containing a description of this table fields
     *
     * @var \Cake\Database\Schema\TableSchemaInterface|null
     */
    protected $_schema;

    /**
     * The name of the field that represents the primary key in the table
     *
     * @var array<string>|string|null
     */
    protected $_primaryKey;

    /**
     * The name of the field that represents a human-readable representation of a row
     *
     * @var array<string>|string|null
     */
    protected $_displayField;

    /**
     * The associations container for this Table.
     *
     * @var \Cake\ORM\AssociationCollection
     */
    protected $_associations;

    /**
     * BehaviorRegistry for this table
     *
     * @var \Cake\ORM\BehaviorRegistry
     */
    protected $_behaviors;

    /**
     * The name of the class that represent a single row for this table
     *
     * @var string
     * @psalm-var class-string<\Cake\Datasource\IEntity>
     */
    protected $_entityClass;

    /**
     * Registry key used to create this table object
     *
     * @var string|null
     */
    protected $_registryAlias;

    /**
     * Initializes a new instance
     *
     * The myConfig array understands the following keys:
     *
     * - table: Name of the database table to represent
     * - alias: Alias to be assigned to this table (default to table name)
     * - connection: The connection instance to use
     * - entityClass: The fully moduled class name of the entity class that will
     *   represent rows in this table.
     * - schema: A \Cake\Database\Schema\TableSchemaInterface object or an array that can be
     *   passed to it.
     * - eventManager: An instance of an event manager to use for internal events
     * - behaviors: A BehaviorRegistry. Generally not used outside of tests.
     * - associations: An AssociationCollection instance.
     * - validator: A Validator instance which is assigned as the "default"
     *   validation set, or an associative array, where key is the name of the
     *   validation set and value the Validator instance.
     *
     * @param array<string, mixed> myConfig List of options for this table
     */
    this(array myConfig = []) {
        if (!empty(myConfig['registryAlias'])) {
            this.setRegistryAlias(myConfig['registryAlias']);
        }
        if (!empty(myConfig['table'])) {
            this.setTable(myConfig['table']);
        }
        if (!empty(myConfig['alias'])) {
            this.setAlias(myConfig['alias']);
        }
        if (!empty(myConfig['connection'])) {
            this.setConnection(myConfig['connection']);
        }
        if (!empty(myConfig['schema'])) {
            this.setSchema(myConfig['schema']);
        }
        if (!empty(myConfig['entityClass'])) {
            this.setEntityClass(myConfig['entityClass']);
        }
        myEventManager = $behaviors = $associations = null;
        if (!empty(myConfig['eventManager'])) {
            myEventManager = myConfig['eventManager'];
        }
        if (!empty(myConfig['behaviors'])) {
            $behaviors = myConfig['behaviors'];
        }
        if (!empty(myConfig['associations'])) {
            $associations = myConfig['associations'];
        }
        if (!empty(myConfig['validator'])) {
            if (!is_array(myConfig['validator'])) {
                this.setValidator(static::DEFAULT_VALIDATOR, myConfig['validator']);
            } else {
                foreach (myConfig['validator'] as myName => $validator) {
                    this.setValidator(myName, $validator);
                }
            }
        }
        this._eventManager = myEventManager ?: new EventManager();
        this._behaviors = $behaviors ?: new BehaviorRegistry();
        this._behaviors.setTable(this);
        this._associations = $associations ?: new AssociationCollection();

        this.initialize(myConfig);
        this._eventManager.on(this);
        this.dispatchEvent('Model.initialize');
    }

    /**
     * Get the default connection name.
     *
     * This method is used to get the fallback connection name if an
     * instance is created through the TableLocator without a connection.
     *
     * @return string
     * @see \Cake\ORM\Locator\TableLocator::get()
     */
    static function defaultConnectionName(): string
    {
        return 'default';
    }

    /**
     * Initialize a table instance. Called after the constructor.
     *
     * You can use this method to define associations, attach behaviors
     * define validation and do any other initialization logic you need.
     *
     * ```
     *  function initialize(array myConfig)
     *  {
     *      this.belongsTo('Users');
     *      this.belongsToMany('Tagging.Tags');
     *      this.setPrimaryKey('something_else');
     *  }
     * ```
     *
     * @param array<string, mixed> myConfig Configuration options passed to the constructor
     * @return void
     */
    function initialize(array myConfig): void
    {
    }

    /**
     * Sets the database table name.
     *
     * This can include the database schema name in the form 'schema.table'.
     * If the name must be quoted, enable automatic identifier quoting.
     *
     * @param string myTable Table name.
     * @return this
     */
    auto setTable(string myTable) {
        this._table = myTable;

        return this;
    }

    /**
     * Returns the database table name.
     *
     * This can include the database schema name if set using `setTable()`.
     *
     * @return string
     */
    auto getTable(): string
    {
        if (this._table === null) {
            myTable = moduleSplit(static::class);
            myTable = substr(end(myTable), 0, -5);
            if (!myTable) {
                myTable = this.getAlias();
            }
            this._table = Inflector::underscore(myTable);
        }

        return this._table;
    }

    /**
     * Sets the table alias.
     *
     * @param string myAlias Table alias
     * @return this
     */
    auto setAlias(string myAlias) {
        this._alias = myAlias;

        return this;
    }

    /**
     * Returns the table alias.
     *
     * @return string
     */
    auto getAlias(): string
    {
        if (this._alias === null) {
            myAlias = moduleSplit(static::class);
            myAlias = substr(end(myAlias), 0, -5) ?: this.getTable();
            this._alias = myAlias;
        }

        return this._alias;
    }

    /**
     * Alias a field with the table's current alias.
     *
     * If field is already aliased it will result in no-op.
     *
     * @param string myField The field to alias.
     * @return string The field prefixed with the table alias.
     */
    function aliasField(string myField): string
    {
        if (strpos(myField, '.') !== false) {
            return myField;
        }

        return this.getAlias() . '.' . myField;
    }

    /**
     * Sets the table registry key used to create this table instance.
     *
     * @param string $registryAlias The key used to access this object.
     * @return this
     */
    auto setRegistryAlias(string $registryAlias) {
        this._registryAlias = $registryAlias;

        return this;
    }

    /**
     * Returns the table registry key used to create this table instance.
     *
     * @return string
     */
    auto getRegistryAlias(): string
    {
        if (this._registryAlias === null) {
            this._registryAlias = this.getAlias();
        }

        return this._registryAlias;
    }

    /**
     * Sets the connection instance.
     *
     * @param \Cake\Database\Connection myConnection The connection instance
     * @return this
     */
    auto setConnection(Connection myConnection) {
        this._connection = myConnection;

        return this;
    }

    /**
     * Returns the connection instance.
     *
     * @return \Cake\Database\Connection
     */
    auto getConnection(): Connection
    {
        if (!this._connection) {
            /** @var \Cake\Database\Connection myConnection */
            myConnection = ConnectionManager::get(static::defaultConnectionName());
            this._connection = myConnection;
        }

        return this._connection;
    }

    /**
     * Returns the schema table object describing this table's properties.
     *
     * @return \Cake\Database\Schema\TableSchemaInterface
     */
    auto getSchema(): TableSchemaInterface
    {
        if (this._schema === null) {
            this._schema = this._initializeSchema(
                this.getConnection()
                    .getSchemaCollection()
                    .describe(this.getTable())
            );
            if (Configure::read('debug')) {
                this.checkAliasLengths();
            }
        }

        return this._schema;
    }

    /**
     * Sets the schema table object describing this table's properties.
     *
     * If an array is passed, a new TableSchemaInterface will be constructed
     * out of it and used as the schema for this table.
     *
     * @param \Cake\Database\Schema\TableSchemaInterface|array $schema Schema to be used for this table
     * @return this
     */
    auto setSchema($schema) {
        if (is_array($schema)) {
            $constraints = [];

            if (isset($schema['_constraints'])) {
                $constraints = $schema['_constraints'];
                unset($schema['_constraints']);
            }

            $schema = this.getConnection().getDriver().newTableSchema(this.getTable(), $schema);

            foreach ($constraints as myName => myValue) {
                $schema.addConstraint(myName, myValue);
            }
        }

        this._schema = $schema;
        if (Configure::read('debug')) {
            this.checkAliasLengths();
        }

        return this;
    }

    /**
     * Checks if all table name + column name combinations used for
     * queries fit into the max length allowed by database driver.
     *
     * @return void
     * @throws \RuntimeException When an alias combination is too long
     */
    protected auto checkAliasLengths(): void
    {
        if (this._schema === null) {
            throw new RuntimeException("Unable to check max alias lengths for  `{this.getAlias()}` without schema.");
        }

        $maxLength = null;
        if (method_exists(this.getConnection().getDriver(), 'getMaxAliasLength')) {
            $maxLength = this.getConnection().getDriver().getMaxAliasLength();
        }
        if ($maxLength === null) {
            return;
        }

        myTable = this.getAlias();
        foreach (this._schema.columns() as myName) {
            if (strlen(myTable . '__' . myName) > $maxLength) {
                myNameLength = $maxLength - 2;
                throw new RuntimeException(
                    'ORM queries generate field aliases using the table name/alias and column name. ' .
                    "The table alias `{myTable}` and column `{myName}` create an alias longer than ({myNameLength}). " .
                    'You must change the table schema in the database and shorten either the table or column ' .
                    'identifier so they fit within the database alias limits.'
                );
            }
        }
    }

    /**
     * Override this function in order to alter the schema used by this table.
     * This function is only called after fetching the schema out of the database.
     * If you wish to provide your own schema to this table without touching the
     * database, you can override schema() or inject the definitions though that
     * method.
     *
     * ### Example:
     *
     * ```
     * protected auto _initializeSchema(\Cake\Database\Schema\TableSchemaInterface $schema) {
     *  $schema.setColumnType('preferences', 'json');
     *  return $schema;
     * }
     * ```
     *
     * @param \Cake\Database\Schema\TableSchemaInterface $schema The table definition fetched from database.
     * @return \Cake\Database\Schema\TableSchemaInterface the altered schema
     */
    protected auto _initializeSchema(TableSchemaInterface $schema): TableSchemaInterface
    {
        return $schema;
    }

    /**
     * Test to see if a Table has a specific field/column.
     *
     * Delegates to the schema object and checks for column presence
     * using the Schema\Table instance.
     *
     * @param string myField The field to check for.
     * @return bool True if the field exists, false if it does not.
     */
    bool hasField(string myField)
    {
        $schema = this.getSchema();

        return $schema.getColumn(myField) !== null;
    }

    /**
     * Sets the primary key field name.
     *
     * @param array<string>|string myKey Sets a new name to be used as primary key
     * @return this
     */
    auto setPrimaryKey(myKey) {
        this._primaryKey = myKey;

        return this;
    }

    /**
     * Returns the primary key field name.
     *
     * @return array<string>|string
     */
    auto getPrimaryKey() {
        if (this._primaryKey === null) {
            myKey = this.getSchema().getPrimaryKey();
            if (count(myKey) === 1) {
                myKey = myKey[0];
            }
            this._primaryKey = myKey;
        }

        return this._primaryKey;
    }

    /**
     * Sets the display field.
     *
     * @param array<string>|string myField Name to be used as display field.
     * @return this
     */
    auto setDisplayField(myField) {
        this._displayField = myField;

        return this;
    }

    /**
     * Returns the display field.
     *
     * @return array<string>|string|null
     */
    auto getDisplayField() {
        if (this._displayField === null) {
            $schema = this.getSchema();
            this._displayField = this.getPrimaryKey();
            foreach (['title', 'name', 'label'] as myField) {
                if ($schema.hasColumn(myField)) {
                    this._displayField = myField;
                    break;
                }
            }
        }

        return this._displayField;
    }

    /**
     * Returns the class used to hydrate rows for this table.
     *
     * @return string
     * @psalm-return class-string<\Cake\Datasource\IEntity>
     */
    auto getEntityClass(): string
    {
        if (!this._entityClass) {
            $default = Entity::class;
            $self = static::class;
            $parts = explode('\\', $self);

            if ($self === self::class || count($parts) < 3) {
                return this._entityClass = $default;
            }

            myAlias = Inflector::classify(Inflector::underscore(substr(array_pop($parts), 0, -5)));
            myName = implode('\\', array_slice($parts, 0, -1)) . '\\Entity\\' . myAlias;
            if (!class_exists(myName)) {
                return this._entityClass = $default;
            }

            /** @var class-string<\Cake\Datasource\IEntity>|null myClass */
            myClass = App::className(myName, 'Model/Entity');
            if (!myClass) {
                throw new MissingEntityException([myName]);
            }

            this._entityClass = myClass;
        }

        return this._entityClass;
    }

    /**
     * Sets the class used to hydrate rows for this table.
     *
     * @param string myName The name of the class to use
     * @throws \Cake\ORM\Exception\MissingEntityException when the entity class cannot be found
     * @return this
     */
    auto setEntityClass(string myName) {
        /** @psalm-var class-string<\Cake\Datasource\IEntity>|null */
        myClass = App::className(myName, 'Model/Entity');
        if (myClass === null) {
            throw new MissingEntityException([myName]);
        }

        this._entityClass = myClass;

        return this;
    }

    /**
     * Add a behavior.
     *
     * Adds a behavior to this table's behavior collection. Behaviors
     * provide an easy way to create horizontally re-usable features
     * that can provide trait like functionality, and allow for events
     * to be listened to.
     *
     * Example:
     *
     * Load a behavior, with some settings.
     *
     * ```
     * this.addBehavior('Tree', ['parent' => 'parentId']);
     * ```
     *
     * Behaviors are generally loaded during Table::initialize().
     *
     * @param string myName The name of the behavior. Can be a short class reference.
     * @param array<string, mixed> myOptions The options for the behavior to use.
     * @return this
     * @throws \RuntimeException If a behavior is being reloaded.
     * @see \Cake\ORM\Behavior
     */
    function addBehavior(string myName, array myOptions = []) {
        this._behaviors.load(myName, myOptions);

        return this;
    }

    /**
     * Adds an array of behaviors to the table's behavior collection.
     *
     * Example:
     *
     * ```
     * this.addBehaviors([
     *      'Timestamp',
     *      'Tree' => ['level' => 'level'],
     * ]);
     * ```
     *
     * @param array $behaviors All the behaviors to load.
     * @return this
     * @throws \RuntimeException If a behavior is being reloaded.
     */
    function addBehaviors(array $behaviors) {
        foreach ($behaviors as myName => myOptions) {
            if (is_int(myName)) {
                myName = myOptions;
                myOptions = [];
            }

            this.addBehavior(myName, myOptions);
        }

        return this;
    }

    /**
     * Removes a behavior from this table's behavior registry.
     *
     * Example:
     *
     * Remove a behavior from this table.
     *
     * ```
     * this.removeBehavior('Tree');
     * ```
     *
     * @param string myName The alias that the behavior was added with.
     * @return this
     * @see \Cake\ORM\Behavior
     */
    function removeBehavior(string myName) {
        this._behaviors.unload(myName);

        return this;
    }

    /**
     * Returns the behavior registry for this table.
     *
     * @return \Cake\ORM\BehaviorRegistry The BehaviorRegistry instance.
     */
    function behaviors(): BehaviorRegistry
    {
        return this._behaviors;
    }

    /**
     * Get a behavior from the registry.
     *
     * @param string myName The behavior alias to get from the registry.
     * @return \Cake\ORM\Behavior
     * @throws \InvalidArgumentException If the behavior does not exist.
     */
    auto getBehavior(string myName): Behavior
    {
        if (!this._behaviors.has(myName)) {
            throw new InvalidArgumentException(sprintf(
                'The %s behavior is not defined on %s.',
                myName,
                static::class
            ));
        }

        $behavior = this._behaviors.get(myName);

        return $behavior;
    }

    /**
     * Check if a behavior with the given alias has been loaded.
     *
     * @param string myName The behavior alias to check.
     * @return bool Whether the behavior exists.
     */
    bool hasBehavior(string myName)
    {
        return this._behaviors.has(myName);
    }

    /**
     * Returns an association object configured for the specified alias.
     *
     * The name argument also supports dot syntax to access deeper associations.
     *
     * ```
     * myUsers = this.getAssociation('Articles.Comments.Users');
     * ```
     *
     * Note that this method requires the association to be present or otherwise
     * throws an exception.
     * If you are not sure, use hasAssociation() before calling this method.
     *
     * @param string myName The alias used for the association.
     * @return \Cake\ORM\Association The association.
     * @throws \InvalidArgumentException
     */
    auto getAssociation(string myName): Association
    {
        $association = this.findAssociation(myName);
        if (!$association) {
            $assocations = this.associations().keys();

            myMessage = "The `{myName}` association is not defined on `{this.getAlias()}`.";
            if ($assocations) {
                myMessage .= "\nValid associations are: " . implode(', ', $assocations);
            }
            throw new InvalidArgumentException(myMessage);
        }

        return $association;
    }

    /**
     * Checks whether a specific association exists on this Table instance.
     *
     * The name argument also supports dot syntax to access deeper associations.
     *
     * ```
     * $hasUsers = this.hasAssociation('Articles.Comments.Users');
     * ```
     *
     * @param string myName The alias used for the association.
     * @return bool
     */
    bool hasAssociation(string myName)
    {
        return this.findAssociation(myName) !== null;
    }

    /**
     * Returns an association object configured for the specified alias if any.
     *
     * The name argument also supports dot syntax to access deeper associations.
     *
     * ```
     * myUsers = this.getAssociation('Articles.Comments.Users');
     * ```
     *
     * @param string myName The alias used for the association.
     * @return \Cake\ORM\Association|null Either the association or null.
     */
    protected auto findAssociation(string myName): ?Association
    {
        if (strpos(myName, '.') === false) {
            return this._associations.get(myName);
        }

        myResult = null;
        [myName, $next] = array_pad(explode('.', myName, 2), 2, null);
        if (myName !== null) {
            myResult = this._associations.get(myName);
        }

        if (myResult !== null && $next !== null) {
            myResult = myResult.getTarget().getAssociation($next);
        }

        return myResult;
    }

    /**
     * Get the associations collection for this table.
     *
     * @return \Cake\ORM\AssociationCollection The collection of association objects.
     */
    function associations(): AssociationCollection
    {
        return this._associations;
    }

    /**
     * Setup multiple associations.
     *
     * It takes an array containing set of table names indexed by association type
     * as argument:
     *
     * ```
     * this.Posts.addAssociations([
     *   'belongsTo' => [
     *     'Users' => ['className' => 'App\Model\Table\UsersTable']
     *   ],
     *   'hasMany' => ['Comments'],
     *   'belongsToMany' => ['Tags']
     * ]);
     * ```
     *
     * Each association type accepts multiple associations where the keys
     * are the aliases, and the values are association config data. If numeric
     * keys are used the values will be treated as association aliases.
     *
     * @param array myParams Set of associations to bind (indexed by association type)
     * @return this
     * @see \Cake\ORM\Table::belongsTo()
     * @see \Cake\ORM\Table::hasOne()
     * @see \Cake\ORM\Table::hasMany()
     * @see \Cake\ORM\Table::belongsToMany()
     */
    function addAssociations(array myParams) {
        foreach (myParams as $assocType => myTables) {
            foreach (myTables as $associated => myOptions) {
                if (is_numeric($associated)) {
                    $associated = myOptions;
                    myOptions = [];
                }
                this.{$assocType}($associated, myOptions);
            }
        }

        return this;
    }

    /**
     * Creates a new BelongsTo association between this table and a target
     * table. A "belongs to" association is a N-1 relationship where this table
     * is the N side, and where there is a single associated record in the target
     * table for each one in this table.
     *
     * Target table can be inferred by its name, which is provided in the
     * first argument, or you can either pass the to be instantiated or
     * an instance of it directly.
     *
     * The options array accept the following keys:
     *
     * - className: The class name of the target table object
     * - targetTable: An instance of a table object to be used as the target table
     * - foreignKey: The name of the field to use as foreign key, if false none
     *   will be used
     * - conditions: array with a list of conditions to filter the join with
     * - joinType: The type of join to be used (e.g. INNER)
     * - strategy: The loading strategy to use. 'join' and 'select' are supported.
     * - finder: The finder method to use when loading records from this association.
     *   Defaults to 'all'. When the strategy is 'join', only the fields, containments,
     *   and where conditions will be used from the finder.
     *
     * This method will return the association object that was built.
     *
     * @param string $associated the alias for the target table. This is used to
     * uniquely identify the association
     * @param array<string, mixed> myOptions list of options to configure the association definition
     * @return \Cake\ORM\Association\BelongsTo
     */
    function belongsTo(string $associated, array myOptions = []): BelongsTo
    {
        myOptions += ['sourceTable' => this];

        /** @var \Cake\ORM\Association\BelongsTo $association */
        $association = this._associations.load(BelongsTo::class, $associated, myOptions);

        return $association;
    }

    /**
     * Creates a new HasOne association between this table and a target
     * table. A "has one" association is a 1-1 relationship.
     *
     * Target table can be inferred by its name, which is provided in the
     * first argument, or you can either pass the class name to be instantiated or
     * an instance of it directly.
     *
     * The options array accept the following keys:
     *
     * - className: The class name of the target table object
     * - targetTable: An instance of a table object to be used as the target table
     * - foreignKey: The name of the field to use as foreign key, if false none
     *   will be used
     * - dependent: Set to true if you want CakePHP to cascade deletes to the
     *   associated table when an entity is removed on this table. The delete operation
     *   on the associated table will not cascade further. To get recursive cascades enable
     *   `cascadeCallbacks` as well. Set to false if you don't want CakePHP to remove
     *   associated data, or when you are using database constraints.
     * - cascadeCallbacks: Set to true if you want CakePHP to fire callbacks on
     *   cascaded deletes. If false the ORM will use deleteAll() to remove data.
     *   When true records will be loaded and then deleted.
     * - conditions: array with a list of conditions to filter the join with
     * - joinType: The type of join to be used (e.g. LEFT)
     * - strategy: The loading strategy to use. 'join' and 'select' are supported.
     * - finder: The finder method to use when loading records from this association.
     *   Defaults to 'all'. When the strategy is 'join', only the fields, containments,
     *   and where conditions will be used from the finder.
     *
     * This method will return the association object that was built.
     *
     * @param string $associated the alias for the target table. This is used to
     * uniquely identify the association
     * @param array<string, mixed> myOptions list of options to configure the association definition
     * @return \Cake\ORM\Association\HasOne
     */
    function hasOne(string $associated, array myOptions = []): HasOne
    {
        myOptions += ['sourceTable' => this];

        /** @var \Cake\ORM\Association\HasOne $association */
        $association = this._associations.load(HasOne::class, $associated, myOptions);

        return $association;
    }

    /**
     * Creates a new HasMany association between this table and a target
     * table. A "has many" association is a 1-N relationship.
     *
     * Target table can be inferred by its name, which is provided in the
     * first argument, or you can either pass the class name to be instantiated or
     * an instance of it directly.
     *
     * The options array accept the following keys:
     *
     * - className: The class name of the target table object
     * - targetTable: An instance of a table object to be used as the target table
     * - foreignKey: The name of the field to use as foreign key, if false none
     *   will be used
     * - dependent: Set to true if you want CakePHP to cascade deletes to the
     *   associated table when an entity is removed on this table. The delete operation
     *   on the associated table will not cascade further. To get recursive cascades enable
     *   `cascadeCallbacks` as well. Set to false if you don't want CakePHP to remove
     *   associated data, or when you are using database constraints.
     * - cascadeCallbacks: Set to true if you want CakePHP to fire callbacks on
     *   cascaded deletes. If false the ORM will use deleteAll() to remove data.
     *   When true records will be loaded and then deleted.
     * - conditions: array with a list of conditions to filter the join with
     * - sort: The order in which results for this association should be returned
     * - saveStrategy: Either 'append' or 'replace'. When 'append' the current records
     *   are appended to any records in the database. When 'replace' associated records
     *   not in the current set will be removed. If the foreign key is a null able column
     *   or if `dependent` is true records will be orphaned.
     * - strategy: The strategy to be used for selecting results Either 'select'
     *   or 'subquery'. If subquery is selected the query used to return results
     *   in the source table will be used as conditions for getting rows in the
     *   target table.
     * - finder: The finder method to use when loading records from this association.
     *   Defaults to 'all'.
     *
     * This method will return the association object that was built.
     *
     * @param string $associated the alias for the target table. This is used to
     * uniquely identify the association
     * @param array<string, mixed> myOptions list of options to configure the association definition
     * @return \Cake\ORM\Association\HasMany
     */
    function hasMany(string $associated, array myOptions = []): HasMany
    {
        myOptions += ['sourceTable' => this];

        /** @var \Cake\ORM\Association\HasMany $association */
        $association = this._associations.load(HasMany::class, $associated, myOptions);

        return $association;
    }

    /**
     * Creates a new BelongsToMany association between this table and a target
     * table. A "belongs to many" association is a M-N relationship.
     *
     * Target table can be inferred by its name, which is provided in the
     * first argument, or you can either pass the class name to be instantiated or
     * an instance of it directly.
     *
     * The options array accept the following keys:
     *
     * - className: The class name of the target table object.
     * - targetTable: An instance of a table object to be used as the target table.
     * - foreignKey: The name of the field to use as foreign key.
     * - targetForeignKey: The name of the field to use as the target foreign key.
     * - joinTable: The name of the table representing the link between the two
     * - through: If you choose to use an already instantiated link table, set this
     *   key to a configured Table instance containing associations to both the source
     *   and target tables in this association.
     * - dependent: Set to false, if you do not want junction table records removed
     *   when an owning record is removed.
     * - cascadeCallbacks: Set to true if you want CakePHP to fire callbacks on
     *   cascaded deletes. If false the ORM will use deleteAll() to remove data.
     *   When true join/junction table records will be loaded and then deleted.
     * - conditions: array with a list of conditions to filter the join with.
     * - sort: The order in which results for this association should be returned.
     * - strategy: The strategy to be used for selecting results Either 'select'
     *   or 'subquery'. If subquery is selected the query used to return results
     *   in the source table will be used as conditions for getting rows in the
     *   target table.
     * - saveStrategy: Either 'append' or 'replace'. Indicates the mode to be used
     *   for saving associated entities. The former will only create new links
     *   between both side of the relation and the latter will do a wipe and
     *   replace to create the links between the passed entities when saving.
     * - strategy: The loading strategy to use. 'select' and 'subquery' are supported.
     * - finder: The finder method to use when loading records from this association.
     *   Defaults to 'all'.
     *
     * This method will return the association object that was built.
     *
     * @param string $associated the alias for the target table. This is used to
     * uniquely identify the association
     * @param array<string, mixed> myOptions list of options to configure the association definition
     * @return \Cake\ORM\Association\BelongsToMany
     */
    function belongsToMany(string $associated, array myOptions = []): BelongsToMany
    {
        myOptions += ['sourceTable' => this];

        /** @var \Cake\ORM\Association\BelongsToMany $association */
        $association = this._associations.load(BelongsToMany::class, $associated, myOptions);

        return $association;
    }

    /**
     * Creates a new Query for this repository and applies some defaults based on the
     * type of search that was selected.
     *
     * ### Model.beforeFind event
     *
     * Each find() will trigger a `Model.beforeFind` event for all attached
     * listeners. Any listener can set a valid result set using myQuery
     *
     * By default, `myOptions` will recognize the following keys:
     *
     * - fields
     * - conditions
     * - order
     * - limit
     * - offset
     * - page
     * - group
     * - having
     * - contain
     * - join
     *
     * ### Usage
     *
     * Using the options array:
     *
     * ```
     * myQuery = $articles.find('all', [
     *   'conditions' => ['published' => 1],
     *   'limit' => 10,
     *   'contain' => ['Users', 'Comments']
     * ]);
     * ```
     *
     * Using the builder interface:
     *
     * ```
     * myQuery = $articles.find()
     *   .where(['published' => 1])
     *   .limit(10)
     *   .contain(['Users', 'Comments']);
     * ```
     *
     * ### Calling finders
     *
     * The find() method is the entry point for custom finder methods.
     * You can invoke a finder by specifying the type:
     *
     * ```
     * myQuery = $articles.find('published');
     * ```
     *
     * Would invoke the `findPublished` method.
     *
     * @param string myType the type of query to perform
     * @param array<string, mixed> myOptions An array that will be passed to Query::applyOptions()
     * @return \Cake\ORM\Query The query builder
     */
    function find(string myType = 'all', array myOptions = []): Query
    {
        myQuery = this.query();
        myQuery.select();

        return this.callFinder(myType, myQuery, myOptions);
    }

    /**
     * Returns the query as passed.
     *
     * By default findAll() applies no conditions, you
     * can override this method in subclasses to modify how `find('all')` works.
     *
     * @param \Cake\ORM\Query myQuery The query to find with
     * @param array<string, mixed> myOptions The options to use for the find
     * @return \Cake\ORM\Query The query builder
     */
    function findAll(Query myQuery, array myOptions): Query
    {
        return myQuery;
    }

    /**
     * Sets up a query object so results appear as an indexed array, useful for any
     * place where you would want a list such as for populating input select boxes.
     *
     * When calling this finder, the fields passed are used to determine what should
     * be used as the array key, value and optionally what to group the results by.
     * By default, the primary key for the model is used for the key, and the display
     * field as value.
     *
     * The results of this finder will be in the following form:
     *
     * ```
     * [
     *  1 => 'value for id 1',
     *  2 => 'value for id 2',
     *  4 => 'value for id 4'
     * ]
     * ```
     *
     * You can specify which property will be used as the key and which as value
     * by using the `myOptions` array, when not specified, it will use the results
     * of calling `primaryKey` and `displayField` respectively in this table:
     *
     * ```
     * myTable.find('list', [
     *  'keyField' => 'name',
     *  'valueField' => 'age'
     * ]);
     * ```
     *
     * The `valueField` can also be an array, in which case you can also specify
     * the `valueSeparator` option to control how the values will be concatenated:
     *
     * ```
     * myTable.find('list', [
     *  'valueField' => ['first_name', 'last_name'],
     *  'valueSeparator' => ' | ',
     * ]);
     * ```
     *
     * The results of this finder will be in the following form:
     *
     * ```
     * [
     *  1 => 'John | Doe',
     *  2 => 'Steve | Smith'
     * ]
     * ```
     *
     * Results can be put together in bigger groups when they share a property, you
     * can customize the property to use for grouping by setting `groupField`:
     *
     * ```
     * myTable.find('list', [
     *  'groupField' => 'category_id',
     * ]);
     * ```
     *
     * When using a `groupField` results will be returned in this format:
     *
     * ```
     * [
     *  'group_1' => [
     *      1 => 'value for id 1',
     *      2 => 'value for id 2',
     *  ]
     *  'group_2' => [
     *      4 => 'value for id 4'
     *  ]
     * ]
     * ```
     *
     * @param \Cake\ORM\Query myQuery The query to find with
     * @param array<string, mixed> myOptions The options for the find
     * @return \Cake\ORM\Query The query builder
     */
    function findList(Query myQuery, array myOptions): Query
    {
        myOptions += [
            'keyField' => this.getPrimaryKey(),
            'valueField' => this.getDisplayField(),
            'groupField' => null,
            'valueSeparator' => ';',
        ];

        if (
            !myQuery.clause('select') &&
            !is_object(myOptions['keyField']) &&
            !is_object(myOptions['valueField']) &&
            !is_object(myOptions['groupField'])
        ) {
            myFields = array_merge(
                (array)myOptions['keyField'],
                (array)myOptions['valueField'],
                (array)myOptions['groupField']
            );
            $columns = this.getSchema().columns();
            if (count(myFields) === count(array_intersect(myFields, $columns))) {
                myQuery.select(myFields);
            }
        }

        myOptions = this._setFieldMatchers(
            myOptions,
            ['keyField', 'valueField', 'groupField']
        );

        return myQuery.formatResults(function (myResults) use (myOptions) {
            /** @var \Cake\Collection\ICollection myResults */
            return myResults.combine(
                myOptions['keyField'],
                myOptions['valueField'],
                myOptions['groupField']
            );
        });
    }

    /**
     * Results for this finder will be a nested array, and is appropriate if you want
     * to use the parent_id field of your model data to build nested results.
     *
     * Values belonging to a parent row based on their parent_id value will be
     * recursively nested inside the parent row values using the `children` property
     *
     * You can customize what fields are used for nesting results, by default the
     * primary key and the `parent_id` fields are used. If you wish to change
     * these defaults you need to provide the keys `keyField`, `parentField` or `nestingKey` in
     * `myOptions`:
     *
     * ```
     * myTable.find('threaded', [
     *  'keyField' => 'id',
     *  'parentField' => 'ancestor_id'
     *  'nestingKey' => 'children'
     * ]);
     * ```
     *
     * @param \Cake\ORM\Query myQuery The query to find with
     * @param array<string, mixed> myOptions The options to find with
     * @return \Cake\ORM\Query The query builder
     */
    function findThreaded(Query myQuery, array myOptions): Query
    {
        myOptions += [
            'keyField' => this.getPrimaryKey(),
            'parentField' => 'parent_id',
            'nestingKey' => 'children',
        ];

        myOptions = this._setFieldMatchers(myOptions, ['keyField', 'parentField']);

        return myQuery.formatResults(function (myResults) use (myOptions) {
            /** @var \Cake\Collection\ICollection myResults */
            return myResults.nest(myOptions['keyField'], myOptions['parentField'], myOptions['nestingKey']);
        });
    }

    /**
     * Out of an options array, check if the keys described in `myKeys` are arrays
     * and change the values for closures that will concatenate the each of the
     * properties in the value array when passed a row.
     *
     * This is an auxiliary function used for result formatters that can accept
     * composite keys when comparing values.
     *
     * @param array<string, mixed> myOptions the original options passed to a finder
     * @param array<string> myKeys the keys to check in myOptions to build matchers from
     * the associated value
     * @return array
     */
    protected auto _setFieldMatchers(array myOptions, array myKeys): array
    {
        foreach (myKeys as myField) {
            if (!is_array(myOptions[myField])) {
                continue;
            }

            if (count(myOptions[myField]) === 1) {
                myOptions[myField] = current(myOptions[myField]);
                continue;
            }

            myFields = myOptions[myField];
            $glue = in_array(myField, ['keyField', 'parentField'], true) ? ';' : myOptions['valueSeparator'];
            myOptions[myField] = function ($row) use (myFields, $glue) {
                $matches = [];
                foreach (myFields as myField) {
                    $matches[] = $row[myField];
                }

                return implode($glue, $matches);
            };
        }

        return myOptions;
    }

    /**
     * {@inheritDoc}
     *
     * ### Usage
     *
     * Get an article and some relationships:
     *
     * ```
     * $article = $articles.get(1, ['contain' => ['Users', 'Comments']]);
     * ```
     *
     * @param mixed $primaryKey primary key value to find
     * @param array<string, mixed> myOptions options accepted by `Table::find()`
     * @return \Cake\Datasource\IEntity
     * @throws \Cake\Datasource\Exception\RecordNotFoundException if the record with such id
     * could not be found
     * @throws \Cake\Datasource\Exception\InvalidPrimaryKeyException When $primaryKey has an
     *      incorrect number of elements.
     * @see \Cake\Datasource\IRepository::find()
     * @psalm-suppress InvalidReturnType
     */
    auto get($primaryKey, array myOptions = []): IEntity
    {
        myKey = (array)this.getPrimaryKey();
        myAlias = this.getAlias();
        foreach (myKey as $index => myKeyname) {
            myKey[$index] = myAlias . '.' . myKeyname;
        }
        $primaryKey = (array)$primaryKey;
        if (count(myKey) !== count($primaryKey)) {
            $primaryKey = $primaryKey ?: [null];
            $primaryKey = array_map(function (myKey) {
                return var_export(myKey, true);
            }, $primaryKey);

            throw new InvalidPrimaryKeyException(sprintf(
                'Record not found in table "%s" with primary key [%s]',
                this.getTable(),
                implode(', ', $primaryKey)
            ));
        }
        $conditions = array_combine(myKey, $primaryKey);

        $cacheConfig = myOptions['cache'] ?? false;
        $cacheKey = myOptions['key'] ?? false;
        myFinder = myOptions['finder'] ?? 'all';
        unset(myOptions['key'], myOptions['cache'], myOptions['finder']);

        myQuery = this.find(myFinder, myOptions).where($conditions);

        if ($cacheConfig) {
            if (!$cacheKey) {
                $cacheKey = sprintf(
                    'get:%s.%s%s',
                    this.getConnection().configName(),
                    this.getTable(),
                    json_encode($primaryKey)
                );
            }
            myQuery.cache($cacheKey, $cacheConfig);
        }

        /** @psalm-suppress InvalidReturnStatement */
        return myQuery.firstOrFail();
    }

    /**
     * Handles the logic executing of a worker inside a transaction.
     *
     * @param callable $worker The worker that will run inside the transaction.
     * @param bool $atomic Whether to execute the worker inside a database transaction.
     * @return mixed
     */
    protected auto _executeTransaction(callable $worker, bool $atomic = true) {
        if ($atomic) {
            return this.getConnection().transactional(function () use ($worker) {
                return $worker();
            });
        }

        return $worker();
    }

    /**
     * Checks if the caller would have executed a commit on a transaction.
     *
     * @param bool $atomic True if an atomic transaction was used.
     * @param bool $primary True if a primary was used.
     * @return bool Returns true if a transaction was committed.
     */
    protected bool _transactionCommitted(bool $atomic, bool $primary)
    {
        return !this.getConnection().inTransaction() && ($atomic || $primary);
    }

    /**
     * Finds an existing record or creates a new one.
     *
     * A find() will be done to locate an existing record using the attributes
     * defined in $search. If records matches the conditions, the first record
     * will be returned.
     *
     * If no record can be found, a new entity will be created
     * with the $search properties. If a callback is provided, it will be
     * called allowing you to define additional default values. The new
     * entity will be saved and returned.
     *
     * If your find conditions require custom order, associations or conditions, then the $search
     * parameter can be a callable that takes the Query as the argument, or a \Cake\ORM\Query object passed
     * as the $search parameter. Allowing you to customize the find results.
     *
     * ### Options
     *
     * The options array is passed to the save method with exception to the following keys:
     *
     * - atomic: Whether to execute the methods for find, save and callbacks inside a database
     *   transaction (default: true)
     * - defaults: Whether to use the search criteria as default values for the new entity (default: true)
     *
     * @param \Cake\ORM\Query|callable|array $search The criteria to find existing
     *   records by. Note that when you pass a query object you'll have to use
     *   the 2nd arg of the method to modify the entity data before saving.
     * @param callable|null $callback A callback that will be invoked for newly
     *   created entities. This callback will be called *before* the entity
     *   is persisted.
     * @param array<string, mixed> myOptions The options to use when saving.
     * @return \Cake\Datasource\IEntity An entity.
     * @throws \Cake\ORM\Exception\PersistenceFailedException When the entity couldn't be saved
     */
    function findOrCreate($search, ?callable $callback = null, myOptions = []): IEntity
    {
        myOptions = new ArrayObject(myOptions + [
            'atomic' => true,
            'defaults' => true,
        ]);

        $entity = this._executeTransaction(function () use ($search, $callback, myOptions) {
            return this._processFindOrCreate($search, $callback, myOptions.getArrayCopy());
        }, myOptions['atomic']);

        if ($entity && this._transactionCommitted(myOptions['atomic'], true)) {
            this.dispatchEvent('Model.afterSaveCommit', compact('entity', 'options'));
        }

        return $entity;
    }

    /**
     * Performs the actual find and/or create of an entity based on the passed options.
     *
     * @param \Cake\ORM\Query|callable|array $search The criteria to find an existing record by, or a callable tha will
     *   customize the find query.
     * @param callable|null $callback A callback that will be invoked for newly
     *   created entities. This callback will be called *before* the entity
     *   is persisted.
     * @param array<string, mixed> myOptions The options to use when saving.
     * @return \Cake\Datasource\IEntity|array An entity.
     * @throws \Cake\ORM\Exception\PersistenceFailedException When the entity couldn't be saved
     * @throws \InvalidArgumentException
     */
    protected auto _processFindOrCreate($search, ?callable $callback = null, myOptions = []) {
        myQuery = this._getFindOrCreateQuery($search);

        $row = myQuery.first();
        if ($row !== null) {
            return $row;
        }

        $entity = this.newEmptyEntity();
        if (myOptions['defaults'] && is_array($search)) {
            $accessibleFields = array_combine(array_keys($search), array_fill(0, count($search), true));
            $entity = this.patchEntity($entity, $search, ['accessibleFields' => $accessibleFields]);
        }
        if ($callback !== null) {
            $entity = $callback($entity) ?: $entity;
        }
        unset(myOptions['defaults']);

        myResult = this.save($entity, myOptions);

        if (myResult === false) {
            throw new PersistenceFailedException($entity, ['findOrCreate']);
        }

        return $entity;
    }

    /**
     * Gets the query object for findOrCreate().
     *
     * @param \Cake\ORM\Query|callable|array $search The criteria to find existing records by.
     * @return \Cake\ORM\Query
     */
    protected auto _getFindOrCreateQuery($search): Query
    {
        if (is_callable($search)) {
            myQuery = this.find();
            $search(myQuery);
        } elseif (is_array($search)) {
            myQuery = this.find().where($search);
        } elseif ($search instanceof Query) {
            myQuery = $search;
        } else {
            throw new InvalidArgumentException(sprintf(
                'Search criteria must be an array, callable or Query. Got "%s"',
                getTypeName($search)
            ));
        }

        return myQuery;
    }

    /**
     * Creates a new Query instance for a table.
     *
     * @return \Cake\ORM\Query
     */
    function query(): Query
    {
        return new Query(this.getConnection(), this);
    }

    /**
     * Creates a new Query::subquery() instance for a table.
     *
     * @return \Cake\ORM\Query
     * @see \Cake\ORM\Query::subquery()
     */
    function subquery(): Query
    {
        return Query::subquery(this);
    }


    function updateAll(myFields, $conditions): int
    {
        myQuery = this.query();
        myQuery.update()
            .set(myFields)
            .where($conditions);
        $statement = myQuery.execute();
        $statement.closeCursor();

        return $statement.rowCount();
    }


    function deleteAll($conditions): int
    {
        myQuery = this.query()
            .delete()
            .where($conditions);
        $statement = myQuery.execute();
        $statement.closeCursor();

        return $statement.rowCount();
    }


    bool exists($conditions)
    {
        return (bool)count(
            this.find('all')
            .select(['existing' => 1])
            .where($conditions)
            .limit(1)
            .disableHydration()
            .toArray()
        );
    }

    /**
     * {@inheritDoc}
     *
     * ### Options
     *
     * The options array accepts the following keys:
     *
     * - atomic: Whether to execute the save and callbacks inside a database
     *   transaction (default: true)
     * - checkRules: Whether to check the rules on entity before saving, if the checking
     *   fails, it will abort the save operation. (default:true)
     * - associated: If `true` it will save 1st level associated entities as they are found
     *   in the passed `$entity` whenever the property defined for the association
     *   is marked as dirty. If an array, it will be interpreted as the list of associations
     *   to be saved. It is possible to provide different options for saving on associated
     *   table objects using this key by making the custom options the array value.
     *   If `false` no associated records will be saved. (default: `true`)
     * - checkExisting: Whether to check if the entity already exists, assuming that the
     *   entity is marked as not new, and the primary key has been set.
     *
     * ### Events
     *
     * When saving, this method will trigger four events:
     *
     * - Model.beforeRules: Will be triggered right before any rule checking is done
     *   for the passed entity if the `checkRules` key in myOptions is not set to false.
     *   Listeners will receive as arguments the entity, options array and the operation type.
     *   If the event is stopped the rules check result will be set to the result of the event itself.
     * - Model.afterRules: Will be triggered right after the `checkRules()` method is
     *   called for the entity. Listeners will receive as arguments the entity,
     *   options array, the result of checking the rules and the operation type.
     *   If the event is stopped the checking result will be set to the result of
     *   the event itself.
     * - Model.beforeSave: Will be triggered just before the list of fields to be
     *   persisted is calculated. It receives both the entity and the options as
     *   arguments. The options array is passed as an ArrayObject, so any changes in
     *   it will be reflected in every listener and remembered at the end of the event
     *   so it can be used for the rest of the save operation. Returning false in any
     *   of the listeners will abort the saving process. If the event is stopped
     *   using the event API, the event object's `result` property will be returned.
     *   This can be useful when having your own saving strategy implemented inside a
     *   listener.
     * - Model.afterSave: Will be triggered after a successful insert or save,
     *   listeners will receive the entity and the options array as arguments. The type
     *   of operation performed (insert or update) can be determined by checking the
     *   entity's method `isNew`, true meaning an insert and false an update.
     * - Model.afterSaveCommit: Will be triggered after the transaction is committed
     *   for atomic save, listeners will receive the entity and the options array
     *   as arguments.
     *
     * This method will determine whether the passed entity needs to be
     * inserted or updated in the database. It does that by checking the `isNew`
     * method on the entity. If the entity to be saved returns a non-empty value from
     * its `errors()` method, it will not be saved.
     *
     * ### Saving on associated tables
     *
     * This method will by default persist entities belonging to associated tables,
     * whenever a dirty property matching the name of the property name set for an
     * association in this table. It is possible to control what associations will
     * be saved and to pass additional option for saving them.
     *
     * ```
     * // Only save the comments association
     * $articles.save($entity, ['associated' => ['Comments']]);
     *
     * // Save the company, the employees and related addresses for each of them.
     * // For employees do not check the entity rules
     * $companies.save($entity, [
     *   'associated' => [
     *     'Employees' => [
     *       'associated' => ['Addresses'],
     *       'checkRules' => false
     *     ]
     *   ]
     * ]);
     *
     * // Save no associations
     * $articles.save($entity, ['associated' => false]);
     * ```
     *
     * @param \Cake\Datasource\IEntity $entity the entity to be saved
     * @param \Cake\ORM\SaveOptionsBuilder|\ArrayAccess|array myOptions The options to use when saving.
     * @return \Cake\Datasource\IEntity|false
     * @throws \Cake\ORM\Exception\RolledbackTransactionException If the transaction is aborted in the afterSave event.
     */
    function save(IEntity $entity, myOptions = []) {
        if (myOptions instanceof SaveOptionsBuilder) {
            myOptions = myOptions.toArray();
        }

        myOptions = new ArrayObject((array)myOptions + [
            'atomic' => true,
            'associated' => true,
            'checkRules' => true,
            'checkExisting' => true,
            '_primary' => true,
        ]);

        if ($entity.hasErrors((bool)myOptions['associated'])) {
            return false;
        }

        if ($entity.isNew() === false && !$entity.isDirty()) {
            return $entity;
        }

        $success = this._executeTransaction(function () use ($entity, myOptions) {
            return this._processSave($entity, myOptions);
        }, myOptions['atomic']);

        if ($success) {
            if (this._transactionCommitted(myOptions['atomic'], myOptions['_primary'])) {
                this.dispatchEvent('Model.afterSaveCommit', compact('entity', 'options'));
            }
            if (myOptions['atomic'] || myOptions['_primary']) {
                $entity.clean();
                $entity.setNew(false);
                $entity.setSource(this.getRegistryAlias());
            }
        }

        return $success;
    }

    /**
     * Try to save an entity or throw a PersistenceFailedException if the application rules checks failed,
     * the entity contains errors or the save was aborted by a callback.
     *
     * @param \Cake\Datasource\IEntity $entity the entity to be saved
     * @param \ArrayAccess|array myOptions The options to use when saving.
     * @return \Cake\Datasource\IEntity
     * @throws \Cake\ORM\Exception\PersistenceFailedException When the entity couldn't be saved
     * @see \Cake\ORM\Table::save()
     */
    function saveOrFail(IEntity $entity, myOptions = []): IEntity
    {
        $saved = this.save($entity, myOptions);
        if ($saved === false) {
            throw new PersistenceFailedException($entity, ['save']);
        }

        return $saved;
    }

    /**
     * Performs the actual saving of an entity based on the passed options.
     *
     * @param \Cake\Datasource\IEntity $entity the entity to be saved
     * @param \ArrayObject myOptions the options to use for the save operation
     * @return \Cake\Datasource\IEntity|false
     * @throws \RuntimeException When an entity is missing some of the primary keys.
     * @throws \Cake\ORM\Exception\RolledbackTransactionException If the transaction
     *   is aborted in the afterSave event.
     */
    protected auto _processSave(IEntity $entity, ArrayObject myOptions) {
        $primaryColumns = (array)this.getPrimaryKey();

        if (myOptions['checkExisting'] && $primaryColumns && $entity.isNew() && $entity.has($primaryColumns)) {
            myAlias = this.getAlias();
            $conditions = [];
            foreach ($entity.extract($primaryColumns) as $k => $v) {
                $conditions["myAlias.$k"] = $v;
            }
            $entity.setNew(!this.exists($conditions));
        }

        myMode = $entity.isNew() ? RulesChecker::CREATE : RulesChecker::UPDATE;
        if (myOptions['checkRules'] && !this.checkRules($entity, myMode, myOptions)) {
            return false;
        }

        myOptions['associated'] = this._associations.normalizeKeys(myOptions['associated']);
        myEvent = this.dispatchEvent('Model.beforeSave', compact('entity', 'options'));

        if (myEvent.isStopped()) {
            myResult = myEvent.getResult();
            if (myResult === null) {
                return false;
            }

            if (myResult !== false && !(myResult instanceof IEntity)) {
                throw new RuntimeException(sprintf(
                    'The beforeSave callback must return `false` or `IEntity` instance. Got `%s` instead.',
                    getTypeName(myResult)
                ));
            }

            return myResult;
        }

        $saved = this._associations.saveParents(
            this,
            $entity,
            myOptions['associated'],
            ['_primary' => false] + myOptions.getArrayCopy()
        );

        if (!$saved && myOptions['atomic']) {
            return false;
        }

        myData = $entity.extract(this.getSchema().columns(), true);
        $isNew = $entity.isNew();

        if ($isNew) {
            $success = this._insert($entity, myData);
        } else {
            $success = this._update($entity, myData);
        }

        if ($success) {
            $success = this._onSaveSuccess($entity, myOptions);
        }

        if (!$success && $isNew) {
            $entity.unset(this.getPrimaryKey());
            $entity.setNew(true);
        }

        return $success ? $entity : false;
    }

    /**
     * Handles the saving of children associations and executing the afterSave logic
     * once the entity for this table has been saved successfully.
     *
     * @param \Cake\Datasource\IEntity $entity the entity to be saved
     * @param \ArrayObject myOptions the options to use for the save operation
     * @return bool True on success
     * @throws \Cake\ORM\Exception\RolledbackTransactionException If the transaction
     *   is aborted in the afterSave event.
     */
    protected bool _onSaveSuccess(IEntity $entity, ArrayObject myOptions)
    {
        $success = this._associations.saveChildren(
            this,
            $entity,
            myOptions['associated'],
            ['_primary' => false] + myOptions.getArrayCopy()
        );

        if (!$success && myOptions['atomic']) {
            return false;
        }

        this.dispatchEvent('Model.afterSave', compact('entity', 'options'));

        if (myOptions['atomic'] && !this.getConnection().inTransaction()) {
            throw new RolledbackTransactionException(['table' => static::class]);
        }

        if (!myOptions['atomic'] && !myOptions['_primary']) {
            $entity.clean();
            $entity.setNew(false);
            $entity.setSource(this.getRegistryAlias());
        }

        return true;
    }

    /**
     * Auxiliary function to handle the insert of an entity's data in the table
     *
     * @param \Cake\Datasource\IEntity $entity the subject entity from were myData was extracted
     * @param array myData The actual data that needs to be saved
     * @return \Cake\Datasource\IEntity|false
     * @throws \RuntimeException if not all the primary keys where supplied or could
     * be generated when the table has composite primary keys. Or when the table has no primary key.
     */
    protected auto _insert(IEntity $entity, array myData) {
        $primary = (array)this.getPrimaryKey();
        if (empty($primary)) {
            $msg = sprintf(
                'Cannot insert row in "%s" table, it has no primary key.',
                this.getTable()
            );
            throw new RuntimeException($msg);
        }
        myKeys = array_fill(0, count($primary), null);
        $id = (array)this._newId($primary) + myKeys;

        // Generate primary keys preferring values in myData.
        $primary = array_combine($primary, $id) ?: [];
        $primary = array_intersect_key(myData, $primary) + $primary;

        $filteredKeys = array_filter($primary, function ($v) {
            return $v !== null;
        });
        myData += $filteredKeys;

        if (count($primary) > 1) {
            $schema = this.getSchema();
            foreach ($primary as $k => $v) {
                if (!isset(myData[$k]) && empty($schema.getColumn($k)['autoIncrement'])) {
                    $msg = 'Cannot insert row, some of the primary key values are missing. ';
                    $msg .= sprintf(
                        'Got (%s), expecting (%s)',
                        implode(', ', $filteredKeys + $entity.extract(array_keys($primary))),
                        implode(', ', array_keys($primary))
                    );
                    throw new RuntimeException($msg);
                }
            }
        }

        $success = false;
        if (empty(myData)) {
            return $success;
        }

        $statement = this.query().insert(array_keys(myData))
            .values(myData)
            .execute();

        if ($statement.rowCount() !== 0) {
            $success = $entity;
            $entity.set($filteredKeys, ['guard' => false]);
            $schema = this.getSchema();
            myDriver = this.getConnection().getDriver();
            foreach ($primary as myKey => $v) {
                if (!isset(myData[myKey])) {
                    $id = $statement.lastInsertId(this.getTable(), myKey);
                    /** @var string myType */
                    myType = $schema.getColumnType(myKey);
                    $entity.set(myKey, TypeFactory::build(myType).toPHP($id, myDriver));
                    break;
                }
            }
        }
        $statement.closeCursor();

        return $success;
    }

    /**
     * Generate a primary key value for a new record.
     *
     * By default, this uses the type system to generate a new primary key
     * value if possible. You can override this method if you have specific requirements
     * for id generation.
     *
     * Note: The ORM will not generate primary key values for composite primary keys.
     * You can overwrite _newId() in your table class.
     *
     * @param array<string> $primary The primary key columns to get a new ID for.
     * @return string|null Either null or the primary key value or a list of primary key values.
     */
    protected auto _newId(array $primary) {
        if (!$primary || count($primary) > 1) {
            return null;
        }
        /** @var string myTypeName */
        myTypeName = this.getSchema().getColumnType($primary[0]);
        myType = TypeFactory::build(myTypeName);

        return myType.newId();
    }

    /**
     * Auxiliary function to handle the update of an entity's data in the table
     *
     * @param \Cake\Datasource\IEntity $entity the subject entity from were myData was extracted
     * @param array myData The actual data that needs to be saved
     * @return \Cake\Datasource\IEntity|false
     * @throws \InvalidArgumentException When primary key data is missing.
     */
    protected auto _update(IEntity $entity, array myData) {
        $primaryColumns = (array)this.getPrimaryKey();
        $primaryKey = $entity.extract($primaryColumns);

        myData = array_diff_key(myData, $primaryKey);
        if (empty(myData)) {
            return $entity;
        }

        if (count($primaryColumns) === 0) {
            $entityClass = get_class($entity);
            myTable = this.getTable();
            myMessage = "Cannot update `$entityClass`. The `myTable` has no primary key.";
            throw new InvalidArgumentException(myMessage);
        }

        if (!$entity.has($primaryColumns)) {
            myMessage = 'All primary key value(s) are needed for updating, ';
            myMessage .= get_class($entity) . ' is missing ' . implode(', ', $primaryColumns);
            throw new InvalidArgumentException(myMessage);
        }

        myQuery = this.query();
        $statement = myQuery.update()
            .set(myData)
            .where($primaryKey)
            .execute();

        $success = false;
        if ($statement.errorCode() === '00000') {
            $success = $entity;
        }
        $statement.closeCursor();

        return $success;
    }

    /**
     * Persists multiple entities of a table.
     *
     * The records will be saved in a transaction which will be rolled back if
     * any one of the records fails to save due to failed validation or database
     * error.
     *
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to save.
     * @param \Cake\ORM\SaveOptionsBuilder|\ArrayAccess|array myOptions Options used when calling Table::save() for each entity.
     * @return \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity>|false False on failure, entities list on success.
     * @throws \Exception
     */
    function saveMany(iterable $entities, myOptions = []) {
        try {
            return this._saveMany($entities, myOptions);
        } catch (PersistenceFailedException myException) {
            return false;
        }
    }

    /**
     * Persists multiple entities of a table.
     *
     * The records will be saved in a transaction which will be rolled back if
     * any one of the records fails to save due to failed validation or database
     * error.
     *
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to save.
     * @param \ArrayAccess|array myOptions Options used when calling Table::save() for each entity.
     * @return \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> Entities list.
     * @throws \Exception
     * @throws \Cake\ORM\Exception\PersistenceFailedException If an entity couldn't be saved.
     */
    function saveManyOrFail(iterable $entities, myOptions = []): iterable
    {
        return this._saveMany($entities, myOptions);
    }

    /**
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to save.
     * @param \Cake\ORM\SaveOptionsBuilder|\ArrayAccess|array myOptions Options used when calling Table::save() for each entity.
     * @throws \Cake\ORM\Exception\PersistenceFailedException If an entity couldn't be saved.
     * @throws \Exception If an entity couldn't be saved.
     * @return \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> Entities list.
     */
    protected auto _saveMany(iterable $entities, myOptions = []): iterable
    {
        myOptions = new ArrayObject(
            (array)myOptions + [
                'atomic' => true,
                'checkRules' => true,
                '_primary' => true,
            ]
        );

        /** @var array<bool> $isNew */
        $isNew = [];
        $cleanup = function ($entities) use (&$isNew): void {
            /** @var array<\Cake\Datasource\IEntity> $entities */
            foreach ($entities as myKey => $entity) {
                if (isset($isNew[myKey]) && $isNew[myKey]) {
                    $entity.unset(this.getPrimaryKey());
                    $entity.setNew(true);
                }
            }
        };

        /** @var \Cake\Datasource\IEntity|null $failed */
        $failed = null;
        try {
            this.getConnection()
                .transactional(function () use ($entities, myOptions, &$isNew, &$failed) {
                    foreach ($entities as myKey => $entity) {
                        $isNew[myKey] = $entity.isNew();
                        if (this.save($entity, myOptions) === false) {
                            $failed = $entity;

                            return false;
                        }
                    }
                });
        } catch (Exception $e) {
            $cleanup($entities);

            throw $e;
        }

        if ($failed !== null) {
            $cleanup($entities);

            throw new PersistenceFailedException($failed, ['saveMany']);
        }

        if (this._transactionCommitted(myOptions['atomic'], myOptions['_primary'])) {
            foreach ($entities as $entity) {
                this.dispatchEvent('Model.afterSaveCommit', compact('entity', 'options'));
            }
        }

        return $entities;
    }

    /**
     * {@inheritDoc}
     *
     * For HasMany and HasOne associations records will be removed based on
     * the dependent option. Join table records in BelongsToMany associations
     * will always be removed. You can use the `cascadeCallbacks` option
     * when defining associations to change how associated data is deleted.
     *
     * ### Options
     *
     * - `atomic` Defaults to true. When true the deletion happens within a transaction.
     * - `checkRules` Defaults to true. Check deletion rules before deleting the record.
     *
     * ### Events
     *
     * - `Model.beforeDelete` Fired before the delete occurs. If stopped the delete
     *   will be aborted. Receives the event, entity, and options.
     * - `Model.afterDelete` Fired after the delete has been successful. Receives
     *   the event, entity, and options.
     * - `Model.afterDeleteCommit` Fired after the transaction is committed for
     *   an atomic delete. Receives the event, entity, and options.
     *
     * The options argument will be converted into an \ArrayObject instance
     * for the duration of the callbacks, this allows listeners to modify
     * the options used in the delete operation.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to remove.
     * @param \ArrayAccess|array myOptions The options for the delete.
     * @return bool success
     */
    bool delete(IEntity $entity, myOptions = [])
    {
        myOptions = new ArrayObject((array)myOptions + [
            'atomic' => true,
            'checkRules' => true,
            '_primary' => true,
        ]);

        $success = this._executeTransaction(function () use ($entity, myOptions) {
            return this._processDelete($entity, myOptions);
        }, myOptions['atomic']);

        if ($success && this._transactionCommitted(myOptions['atomic'], myOptions['_primary'])) {
            this.dispatchEvent('Model.afterDeleteCommit', [
                'entity' => $entity,
                'options' => myOptions,
            ]);
        }

        return $success;
    }

    /**
     * Deletes multiple entities of a table.
     *
     * The records will be deleted in a transaction which will be rolled back if
     * any one of the records fails to delete due to failed validation or database
     * error.
     *
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to delete.
     * @param \ArrayAccess|array myOptions Options used when calling Table::save() for each entity.
     * @return \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity>|false Entities list
     *   on success, false on failure.
     * @see \Cake\ORM\Table::delete() for options and events related to this method.
     */
    function deleteMany(iterable $entities, myOptions = []) {
        $failed = this._deleteMany($entities, myOptions);

        if ($failed !== null) {
            return false;
        }

        return $entities;
    }

    /**
     * Deletes multiple entities of a table.
     *
     * The records will be deleted in a transaction which will be rolled back if
     * any one of the records fails to delete due to failed validation or database
     * error.
     *
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to delete.
     * @param \ArrayAccess|array myOptions Options used when calling Table::save() for each entity.
     * @return \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> Entities list.
     * @throws \Cake\ORM\Exception\PersistenceFailedException
     * @see \Cake\ORM\Table::delete() for options and events related to this method.
     */
    function deleteManyOrFail(iterable $entities, myOptions = []): iterable
    {
        $failed = this._deleteMany($entities, myOptions);

        if ($failed !== null) {
            throw new PersistenceFailedException($failed, ['deleteMany']);
        }

        return $entities;
    }

    /**
     * @param \Cake\Datasource\ResultSetInterface|array<\Cake\Datasource\IEntity> $entities Entities to delete.
     * @param \ArrayAccess|array myOptions Options used.
     * @return \Cake\Datasource\IEntity|null
     */
    protected auto _deleteMany(iterable $entities, myOptions = []): ?IEntity
    {
        myOptions = new ArrayObject((array)myOptions + [
                'atomic' => true,
                'checkRules' => true,
                '_primary' => true,
            ]);

        $failed = this._executeTransaction(function () use ($entities, myOptions) {
            foreach ($entities as $entity) {
                if (!this._processDelete($entity, myOptions)) {
                    return $entity;
                }
            }

            return null;
        }, myOptions['atomic']);

        if ($failed === null && this._transactionCommitted(myOptions['atomic'], myOptions['_primary'])) {
            foreach ($entities as $entity) {
                this.dispatchEvent('Model.afterDeleteCommit', [
                    'entity' => $entity,
                    'options' => myOptions,
                ]);
            }
        }

        return $failed;
    }

    /**
     * Try to delete an entity or throw a PersistenceFailedException if the entity is new,
     * has no primary key value, application rules checks failed or the delete was aborted by a callback.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to remove.
     * @param \ArrayAccess|array myOptions The options for the delete.
     * @return true
     * @throws \Cake\ORM\Exception\PersistenceFailedException
     * @see \Cake\ORM\Table::delete()
     */
    bool deleteOrFail(IEntity $entity, myOptions = [])
    {
        $deleted = this.delete($entity, myOptions);
        if ($deleted === false) {
            throw new PersistenceFailedException($entity, ['delete']);
        }

        return $deleted;
    }

    /**
     * Perform the delete operation.
     *
     * Will delete the entity provided. Will remove rows from any
     * dependent associations, and clear out join tables for BelongsToMany associations.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to delete.
     * @param \ArrayObject myOptions The options for the delete.
     * @throws \InvalidArgumentException if there are no primary key values of the
     * passed entity
     * @return bool success
     */
    protected bool _processDelete(IEntity $entity, ArrayObject myOptions)
    {
        if ($entity.isNew()) {
            return false;
        }

        $primaryKey = (array)this.getPrimaryKey();
        if (!$entity.has($primaryKey)) {
            $msg = 'Deleting requires all primary key values.';
            throw new InvalidArgumentException($msg);
        }

        if (myOptions['checkRules'] && !this.checkRules($entity, RulesChecker::DELETE, myOptions)) {
            return false;
        }

        myEvent = this.dispatchEvent('Model.beforeDelete', [
            'entity' => $entity,
            'options' => myOptions,
        ]);

        if (myEvent.isStopped()) {
            return (bool)myEvent.getResult();
        }

        $success = this._associations.cascadeDelete(
            $entity,
            ['_primary' => false] + myOptions.getArrayCopy()
        );
        if (!$success) {
            return $success;
        }

        myQuery = this.query();
        $conditions = $entity.extract($primaryKey);
        $statement = myQuery.delete()
            .where($conditions)
            .execute();

        $success = $statement.rowCount() > 0;
        if (!$success) {
            return $success;
        }

        this.dispatchEvent('Model.afterDelete', [
            'entity' => $entity,
            'options' => myOptions,
        ]);

        return $success;
    }

    /**
     * Returns true if the finder exists for the table
     *
     * @param string myType name of finder to check
     * @return bool
     */
    bool hasFinder(string myType)
    {
        myFinder = 'find' . myType;

        return method_exists(this, myFinder) || this._behaviors.hasFinder(myType);
    }

    /**
     * Calls a finder method directly and applies it to the passed query,
     * if no query is passed a new one will be created and returned
     *
     * @param string myType name of the finder to be called
     * @param \Cake\ORM\Query myQuery The query object to apply the finder options to
     * @param array<string, mixed> myOptions List of options to pass to the finder
     * @return \Cake\ORM\Query
     * @throws \BadMethodCallException
     * @uses findAll()
     * @uses findList()
     * @uses findThreaded()
     */
    function callFinder(string myType, Query myQuery, array myOptions = []): Query
    {
        myQuery.applyOptions(myOptions);
        myOptions = myQuery.getOptions();
        myFinder = 'find' . myType;
        if (method_exists(this, myFinder)) {
            return this.{myFinder}(myQuery, myOptions);
        }

        if (this._behaviors.hasFinder(myType)) {
            return this._behaviors.callFinder(myType, [myQuery, myOptions]);
        }

        throw new BadMethodCallException(sprintf(
            'Unknown finder method "%s" on %s.',
            myType,
            static::class
        ));
    }

    /**
     * Provides the dynamic findBy and findAllBy methods.
     *
     * @param string $method The method name that was fired.
     * @param array $args List of arguments passed to the function.
     * @return \Cake\ORM\Query
     * @throws \BadMethodCallException when there are missing arguments, or when
     *  and & or are combined.
     */
    protected auto _dynamicFinder(string $method, array $args) {
        $method = Inflector::underscore($method);
        preg_match('/^find_([\w]+)_by_/', $method, $matches);
        if (empty($matches)) {
            // find_by_ is 8 characters.
            myFields = substr($method, 8);
            $findType = 'all';
        } else {
            myFields = substr($method, strlen($matches[0]));
            $findType = Inflector::variable($matches[1]);
        }
        $hasOr = strpos(myFields, '_or_');
        $hasAnd = strpos(myFields, '_and_');

        $makeConditions = function (myFields, $args) {
            $conditions = [];
            if (count($args) < count(myFields)) {
                throw new BadMethodCallException(sprintf(
                    'Not enough arguments for magic finder. Got %s required %s',
                    count($args),
                    count(myFields)
                ));
            }
            foreach (myFields as myField) {
                $conditions[this.aliasField(myField)] = array_shift($args);
            }

            return $conditions;
        };

        if ($hasOr !== false && $hasAnd !== false) {
            throw new BadMethodCallException(
                'Cannot mix "and" & "or" in a magic finder. Use find() instead.'
            );
        }

        if ($hasOr === false && $hasAnd === false) {
            $conditions = $makeConditions([myFields], $args);
        } elseif ($hasOr !== false) {
            myFields = explode('_or_', myFields);
            $conditions = [
                'OR' => $makeConditions(myFields, $args),
            ];
        } else {
            myFields = explode('_and_', myFields);
            $conditions = $makeConditions(myFields, $args);
        }

        return this.find($findType, [
            'conditions' => $conditions,
        ]);
    }

    /**
     * Handles behavior delegation + dynamic finders.
     *
     * If your Table uses any behaviors you can call them as if
     * they were on the table object.
     *
     * @param string $method name of the method to be invoked
     * @param array $args List of arguments passed to the function
     * @return mixed
     * @throws \BadMethodCallException
     */
    auto __call($method, $args) {
        if (this._behaviors.hasMethod($method)) {
            return this._behaviors.call($method, $args);
        }
        if (preg_match('/^find(?:\w+)?By/', $method) > 0) {
            return this._dynamicFinder($method, $args);
        }

        throw new BadMethodCallException(
            sprintf('Unknown method "%s" called on %s', $method, static::class)
        );
    }

    /**
     * Returns the association named after the passed value if exists, otherwise
     * throws an exception.
     *
     * @param string $property the association name
     * @return \Cake\ORM\Association
     * @throws \RuntimeException if no association with such name exists
     */
    auto __get($property) {
        $association = this._associations.get($property);
        if (!$association) {
            throw new RuntimeException(sprintf(
                'Undefined property `%s`. ' .
                'You have not defined the `%s` association on `%s`.',
                $property,
                $property,
                static::class
            ));
        }

        return $association;
    }

    /**
     * Returns whether an association named after the passed value
     * exists for this table.
     *
     * @param string $property the association name
     * @return bool
     */
    auto __isset($property) {
        return this._associations.has($property);
    }

    /**
     * Get the object used to marshal/convert array data into objects.
     *
     * Override this method if you want a table object to use custom
     * marshalling logic.
     *
     * @return \Cake\ORM\Marshaller
     * @see \Cake\ORM\Marshaller
     */
    function marshaller(): Marshaller
    {
        return new Marshaller(this);
    }

    /**
     * {@inheritDoc}
     *
     * @return \Cake\Datasource\IEntity
     */
    function newEmptyEntity(): IEntity
    {
        myClass = this.getEntityClass();

        return new myClass([], ['source' => this.getRegistryAlias()]);
    }

    /**
     * {@inheritDoc}
     *
     * By default all the associations on this table will be hydrated. You can
     * limit which associations are built, or include deeper associations
     * using the options parameter:
     *
     * ```
     * $article = this.Articles.newEntity(
     *   this.request.getData(),
     *   ['associated' => ['Tags', 'Comments.Users']]
     * );
     * ```
     *
     * You can limit fields that will be present in the constructed entity by
     * passing the `fields` option, which is also accepted for associations:
     *
     * ```
     * $article = this.Articles.newEntity(this.request.getData(), [
     *  'fields' => ['title', 'body', 'tags', 'comments'],
     *  'associated' => ['Tags', 'Comments.Users' => ['fields' => 'username']]
     * ]
     * );
     * ```
     *
     * The `fields` option lets remove or restrict input data from ending up in
     * the entity. If you'd like to relax the entity's default accessible fields,
     * you can use the `accessibleFields` option:
     *
     * ```
     * $article = this.Articles.newEntity(
     *   this.request.getData(),
     *   ['accessibleFields' => ['protected_field' => true]]
     * );
     * ```
     *
     * By default, the data is validated before being passed to the new entity. In
     * the case of invalid fields, those will not be present in the resulting object.
     * The `validate` option can be used to disable validation on the passed data:
     *
     * ```
     * $article = this.Articles.newEntity(
     *   this.request.getData(),
     *   ['validate' => false]
     * );
     * ```
     *
     * You can also pass the name of the validator to use in the `validate` option.
     * If `null` is passed to the first param of this function, no validation will
     * be performed.
     *
     * You can use the `Model.beforeMarshal` event to modify request data
     * before it is converted into entities.
     *
     * @param array myData The data to build an entity with.
     * @param array<string, mixed> myOptions A list of options for the object hydration.
     * @return \Cake\Datasource\IEntity
     * @see \Cake\ORM\Marshaller::one()
     */
    function newEntity(array myData, array myOptions = []): IEntity
    {
        myOptions['associated'] = myOptions['associated'] ?? this._associations.keys();
        $marshaller = this.marshaller();

        return $marshaller.one(myData, myOptions);
    }

    /**
     * {@inheritDoc}
     *
     * By default all the associations on this table will be hydrated. You can
     * limit which associations are built, or include deeper associations
     * using the options parameter:
     *
     * ```
     * $articles = this.Articles.newEntities(
     *   this.request.getData(),
     *   ['associated' => ['Tags', 'Comments.Users']]
     * );
     * ```
     *
     * You can limit fields that will be present in the constructed entities by
     * passing the `fields` option, which is also accepted for associations:
     *
     * ```
     * $articles = this.Articles.newEntities(this.request.getData(), [
     *  'fields' => ['title', 'body', 'tags', 'comments'],
     *  'associated' => ['Tags', 'Comments.Users' => ['fields' => 'username']]
     *  ]
     * );
     * ```
     *
     * You can use the `Model.beforeMarshal` event to modify request data
     * before it is converted into entities.
     *
     * @param array myData The data to build an entity with.
     * @param array<string, mixed> myOptions A list of options for the objects hydration.
     * @return array<\Cake\Datasource\IEntity> An array of hydrated records.
     */
    function newEntities(array myData, array myOptions = []): array
    {
        myOptions['associated'] = myOptions['associated'] ?? this._associations.keys();
        $marshaller = this.marshaller();

        return $marshaller.many(myData, myOptions);
    }

    /**
     * {@inheritDoc}
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `myData` array will appear, those that can be matched by primary key will get
     * the data merged, but those that cannot, will be discarded.
     *
     * You can limit fields that will be present in the merged entity by
     * passing the `fields` option, which is also accepted for associations:
     *
     * ```
     * $article = this.Articles.patchEntity($article, this.request.getData(), [
     *  'fields' => ['title', 'body', 'tags', 'comments'],
     *  'associated' => ['Tags', 'Comments.Users' => ['fields' => 'username']]
     *  ]
     * );
     * ```
     *
     * ```
     * $article = this.Articles.patchEntity($article, this.request.getData(), [
     *   'associated' => [
     *     'Tags' => ['accessibleFields' => ['*' => true]]
     *   ]
     * ]);
     * ```
     *
     * By default, the data is validated before being passed to the entity. In
     * the case of invalid fields, those will not be assigned to the entity.
     * The `validate` option can be used to disable validation on the passed data:
     *
     * ```
     * $article = this.patchEntity($article, this.request.getData(),[
     *  'validate' => false
     * ]);
     * ```
     *
     * You can use the `Model.beforeMarshal` event to modify request data
     * before it is converted into entities.
     *
     * When patching scalar values (null/booleans/string/integer/float), if the property
     * presently has an identical value, the setter will not be called, and the
     * property will not be marked as dirty. This is an optimization to prevent unnecessary field
     * updates when persisting entities.
     *
     * @param \Cake\Datasource\IEntity $entity the entity that will get the
     * data merged in
     * @param array myData key value list of fields to be merged into the entity
     * @param array<string, mixed> myOptions A list of options for the object hydration.
     * @return \Cake\Datasource\IEntity
     * @see \Cake\ORM\Marshaller::merge()
     */
    function patchEntity(IEntity $entity, array myData, array myOptions = []): IEntity
    {
        myOptions['associated'] = myOptions['associated'] ?? this._associations.keys();
        $marshaller = this.marshaller();

        return $marshaller.merge($entity, myData, myOptions);
    }

    /**
     * {@inheritDoc}
     *
     * Those entries in `$entities` that cannot be matched to any record in
     * `myData` will be discarded. Records in `myData` that could not be matched will
     * be marshalled as a new entity.
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `myData` array will appear, those that can be matched by primary key will get
     * the data merged, but those that cannot, will be discarded.
     *
     * You can limit fields that will be present in the merged entities by
     * passing the `fields` option, which is also accepted for associations:
     *
     * ```
     * $articles = this.Articles.patchEntities($articles, this.request.getData(), [
     *  'fields' => ['title', 'body', 'tags', 'comments'],
     *  'associated' => ['Tags', 'Comments.Users' => ['fields' => 'username']]
     *  ]
     * );
     * ```
     *
     * You can use the `Model.beforeMarshal` event to modify request data
     * before it is converted into entities.
     *
     * @param \Traversable|array<\Cake\Datasource\IEntity> $entities the entities that will get the
     * data merged in
     * @param array myData list of arrays to be merged into the entities
     * @param array<string, mixed> myOptions A list of options for the objects hydration.
     * @return array<\Cake\Datasource\IEntity>
     */
    function patchEntities(iterable $entities, array myData, array myOptions = []): array
    {
        myOptions['associated'] = myOptions['associated'] ?? this._associations.keys();
        $marshaller = this.marshaller();

        return $marshaller.mergeMany($entities, myData, myOptions);
    }

    /**
     * Validator method used to check the uniqueness of a value for a column.
     * This is meant to be used with the validation API and not to be called
     * directly.
     *
     * ### Example:
     *
     * ```
     * $validator.add('email', [
     *  'unique' => ['rule' => 'validateUnique', 'provider' => 'table']
     * ])
     * ```
     *
     * Unique validation can be scoped to the value of another column:
     *
     * ```
     * $validator.add('email', [
     *  'unique' => [
     *      'rule' => ['validateUnique', ['scope' => 'site_id']],
     *      'provider' => 'table'
     *  ]
     * ]);
     * ```
     *
     * In the above example, the email uniqueness will be scoped to only rows having
     * the same site_id. Scoping will only be used if the scoping field is present in
     * the data to be validated.
     *
     * @param mixed myValue The value of column to be checked for uniqueness.
     * @param array<string, mixed> myOptions The options array, optionally containing the 'scope' key.
     *   May also be the validation context, if there are no options.
     * @param array|null $context Either the validation context or null.
     * @return bool True if the value is unique, or false if a non-scalar, non-unique value was given.
     */
    bool validateUnique(myValue, array myOptions, ?array $context = null)
    {
        if ($context === null) {
            $context = myOptions;
        }
        $entity = new Entity(
            $context['data'],
            [
                'useSetters' => false,
                'markNew' => $context['newRecord'],
                'source' => this.getRegistryAlias(),
            ]
        );
        myFields = array_merge(
            [$context['field']],
            isset(myOptions['scope']) ? (array)myOptions['scope'] : []
        );
        myValues = $entity.extract(myFields);
        foreach (myValues as myField) {
            if (myField !== null && !is_scalar(myField)) {
                return false;
            }
        }
        myClass = static::IS_UNIQUE_CLASS;
        /** @var \Cake\ORM\Rule\IsUnique $rule */
        $rule = new myClass(myFields, myOptions);

        return $rule($entity, ['repository' => this]);
    }

    /**
     * Get the Model callbacks this table is interested in.
     *
     * By implementing the conventional methods a table class is assumed
     * to be interested in the related event.
     *
     * Override this method if you need to add non-conventional event listeners.
     * Or if you want you table to listen to non-standard events.
     *
     * The conventional method map is:
     *
     * - Model.beforeMarshal => beforeMarshal
     * - Model.afterMarshal => afterMarshal
     * - Model.buildValidator => buildValidator
     * - Model.beforeFind => beforeFind
     * - Model.beforeSave => beforeSave
     * - Model.afterSave => afterSave
     * - Model.afterSaveCommit => afterSaveCommit
     * - Model.beforeDelete => beforeDelete
     * - Model.afterDelete => afterDelete
     * - Model.afterDeleteCommit => afterDeleteCommit
     * - Model.beforeRules => beforeRules
     * - Model.afterRules => afterRules
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        myEventMap = [
            'Model.beforeMarshal' => 'beforeMarshal',
            'Model.afterMarshal' => 'afterMarshal',
            'Model.buildValidator' => 'buildValidator',
            'Model.beforeFind' => 'beforeFind',
            'Model.beforeSave' => 'beforeSave',
            'Model.afterSave' => 'afterSave',
            'Model.afterSaveCommit' => 'afterSaveCommit',
            'Model.beforeDelete' => 'beforeDelete',
            'Model.afterDelete' => 'afterDelete',
            'Model.afterDeleteCommit' => 'afterDeleteCommit',
            'Model.beforeRules' => 'beforeRules',
            'Model.afterRules' => 'afterRules',
        ];
        myEvents = [];

        foreach (myEventMap as myEvent => $method) {
            if (!method_exists(this, $method)) {
                continue;
            }
            myEvents[myEvent] = $method;
        }

        return myEvents;
    }

    /**
     * {@inheritDoc}
     *
     * @param \Cake\ORM\RulesChecker $rules The rules object to be modified.
     * @return \Cake\ORM\RulesChecker
     */
    function buildRules(RulesChecker $rules): RulesChecker
    {
        return $rules;
    }

    /**
     * Gets a SaveOptionsBuilder instance.
     *
     * @param array<string, mixed> myOptions Options to parse by the builder.
     * @return \Cake\ORM\SaveOptionsBuilder
     */
    auto getSaveOptionsBuilder(array myOptions = []): SaveOptionsBuilder
    {
        return new SaveOptionsBuilder(this, myOptions);
    }

    /**
     * Loads the specified associations in the passed entity or list of entities
     * by executing extra queries in the database and merging the results in the
     * appropriate properties.
     *
     * ### Example:
     *
     * ```
     * myUser = myUsersTable.get(1);
     * myUser = myUsersTable.loadInto(myUser, ['Articles.Tags', 'Articles.Comments']);
     * echo myUser.articles[0].title;
     * ```
     *
     * You can also load associations for multiple entities at once
     *
     * ### Example:
     *
     * ```
     * myUsers = myUsersTable.find().where([...]).toList();
     * myUsers = myUsersTable.loadInto(myUsers, ['Articles.Tags', 'Articles.Comments']);
     * echo myUser[1].articles[0].title;
     * ```
     *
     * The properties for the associations to be loaded will be overwritten on each entity.
     *
     * @param \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity> $entities a single entity or list of entities
     * @param array $contain A `contain()` compatible array.
     * @see \Cake\ORM\Query::contain()
     * @return \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity>
     */
    function loadInto($entities, array $contain) {
        return (new LazyEagerLoader()).loadInto($entities, $contain, this);
    }


    protected bool validationMethodExists(string myName)
    {
        return method_exists(this, myName) || this.behaviors().hasMethod(myName);
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array
     */
    auto __debugInfo() {
        $conn = this.getConnection();

        return [
            'registryAlias' => this.getRegistryAlias(),
            'table' => this.getTable(),
            'alias' => this.getAlias(),
            'entityClass' => this.getEntityClass(),
            'associations' => this._associations.keys(),
            'behaviors' => this._behaviors.loaded(),
            'defaultConnection' => static::defaultConnectionName(),
            'connectionName' => $conn.configName(),
        ];
    }
}
