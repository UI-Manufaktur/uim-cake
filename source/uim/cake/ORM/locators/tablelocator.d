module uim.cake.orm.Locator;

import uim.cake.core.App;
import uim.cake.datasources.ConnectionManager;
import uim.cake.datasources.Locator\AbstractLocator;
import uim.cake.datasources.IRepository;
import uim.cake.orm.AssociationCollection;
import uim.cake.orm.exceptions.MissingTableClassException;
import uim.cake.orm.Table;
import uim.cake.utilities.Inflector;
use RuntimeException;

/**
 * Provides a default registry/factory for Table objects.
 */
class TableLocator : AbstractLocator : ILocator
{
    /**
     * Contains a list of locations where table classes should be looked for.
     *
     * @var array<string>
     */
    protected $locations = [];

    /**
     * Configuration for aliases.
     *
     * @var array<string, array|null>
     */
    protected _config = [];

    /**
     * Instances that belong to the registry.
     *
     * @var array<string, uim.cake.orm.Table>
     */
    protected $instances = [];

    /**
     * Contains a list of Table objects that were created out of the
     * built-in Table class. The list is indexed by table alias
     *
     * @var array<uim.cake.orm.Table>
     */
    protected _fallbacked = [];

    /**
     * Fallback class to use
     *
     * @var string
     * @psalm-var class-string<uim.cake.orm.Table>
     */
    protected $fallbackClassName = Table::class;

    /**
     * Whether fallback class should be used if a table class could not be found.
     */
    protected bool $allowFallbackClass = true;

    /**
     * Constructor.
     *
     * @param array<string>|null $locations Locations where tables should be looked for.
     *   If none provided, the default `Model\Table` under your app"s namespace is used.
     */
    this(?array $locations = null) {
        if ($locations == null) {
            $locations = [
                "Model/Table",
            ];
        }

        foreach ($locations as $location) {
            this.addLocation($location);
        }
    }

    /**
     * Set if fallback class should be used.
     *
     * Controls whether a fallback class should be used to create a table
     * instance if a concrete class for alias used in `get()` could not be found.
     *
     * @param bool $allow Flag to enable or disable fallback
     * @return this
     */
    function allowFallbackClass(bool $allow) {
        this.allowFallbackClass = $allow;

        return this;
    }

    /**
     * Set fallback class name.
     *
     * The class that should be used to create a table instance if a concrete
     * class for alias used in `get()` could not be found. Defaults to
     * `Cake\orm.Table`.
     *
     * @param string $className Fallback class name
     * @return this
     * @psalm-param class-string<uim.cake.orm.Table> $className
     */
    function setFallbackClassName($className) {
        this.fallbackClassName = $className;

        return this;
    }


    function setConfig($alias, $options = null) {
        if (!is_string($alias)) {
            _config = $alias;

            return this;
        }

        if (isset(this.instances[$alias])) {
            throw new RuntimeException(sprintf(
                "You cannot configure '%s', it has already been constructed.",
                $alias
            ));
        }

        _config[$alias] = $options;

        return this;
    }


    array getConfig(Nullable!string $alias = null) {
        if ($alias == null) {
            return _config;
        }

        return _config[$alias] ?? [];
    }

    /**
     * Get a table instance from the registry.
     *
     * Tables are only created once until the registry is flushed.
     * This means that aliases must be unique across your application.
     * This is important because table associations are resolved at runtime
     * and cyclic references need to be handled correctly.
     *
     * The options that can be passed are the same as in {@link uim.cake.orm.Table::__construct()}, but the
     * `className` key is also recognized.
     *
     * ### Options
     *
     * - `className` Define the specific class name to use. If undefined, UIM will generate the
     *   class name based on the alias. For example "Users" would result in
     *   `App\Model\Table\UsersTable` being used. If this class does not exist,
     *   then the default `Cake\orm.Table` class will be used. By setting the `className`
     *   option you can define the specific class to use. The className option supports
     *   plugin short class references {@link uim.cake.Core\App::shortName()}.
     * - `table` Define the table name to use. If undefined, this option will default to the underscored
     *   version of the alias name.
     * - `connection` Inject the specific connection object to use. If this option and `connectionName` are undefined,
     *   The table class" `defaultConnectionName()` method will be invoked to fetch the connection name.
     * - `connectionName` Define the connection name to use. The named connection will be fetched from
     *   {@link uim.cake.Datasource\ConnectionManager}.
     *
     * *Note* If your `$alias` uses plugin syntax only the name part will be used as
     * key in the registry. This means that if two plugins, or a plugin and app provide
     * the same alias, the registry will only store the first instance.
     *
     * @param string $alias The alias name you want to get. Should be in CamelCase format.
     * @param array<string, mixed> $options The options you want to build the table with.
     *   If a table has already been loaded the options will be ignored.
     * @return uim.cake.orm.Table
     * @throws \RuntimeException When you try to configure an alias that already exists.
     */
    function get(string $alias, array $options = []): Table
    {
        /** @var uim.cake.orm.Table */
        return super.get($alias, $options);
    }


    protected function createInstance(string $alias, array $options) {
        if (strpos($alias, "\\") == false) {
            [, $classAlias] = pluginSplit($alias);
            $options = ["alias": $classAlias] + $options;
        } elseif (!isset($options["alias"])) {
            $options["className"] = $alias;
        }

        if (isset(_config[$alias])) {
            $options += _config[$alias];
        }

        $allowFallbackClass = $options["allowFallbackClass"] ?? this.allowFallbackClass;
        $className = _getClassName($alias, $options);
        if ($className) {
            $options["className"] = $className;
        } elseif ($allowFallbackClass) {
            if (empty($options["className"])) {
                $options["className"] = $alias;
            }
            if (!isset($options["table"]) && strpos($options["className"], "\\") == false) {
                [, $table] = pluginSplit($options["className"]);
                $options["table"] = Inflector::underscore($table);
            }
            $options["className"] = this.fallbackClassName;
        } else {
            $message = $options["className"] ?? $alias;
            $message = "`" ~ $message ~ "`";
            if (strpos($message, "\\") == false) {
                $message = "for alias " ~ $message;
            }
            throw new MissingTableClassException([$message]);
        }

        if (empty($options["connection"])) {
            if (!empty($options["connectionName"])) {
                $connectionName = $options["connectionName"];
            } else {
                /** @var uim.cake.orm.Table $className */
                $className = $options["className"];
                $connectionName = $className::defaultConnectionName();
            }
            $options["connection"] = ConnectionManager::get($connectionName);
        }
        if (empty($options["associations"])) {
            $associations = new AssociationCollection(this);
            $options["associations"] = $associations;
        }

        $options["registryAlias"] = $alias;
        $instance = _create($options);

        if ($options["className"] == this.fallbackClassName) {
            _fallbacked[$alias] = $instance;
        }

        return $instance;
    }

    /**
     * Gets the table class name.
     *
     * @param string $alias The alias name you want to get. Should be in CamelCase format.
     * @param array<string, mixed> $options Table options array.
     * @return string|null
     */
    protected Nullable!string _getClassName(string $alias, array $options = []) {
        if (empty($options["className"])) {
            $options["className"] = $alias;
        }

        if (strpos($options["className"], "\\") != false && class_exists($options["className"])) {
            return $options["className"];
        }

        foreach (this.locations as $location) {
            $class = App::className($options["className"], $location, "Table");
            if ($class != null) {
                return $class;
            }
        }

        return null;
    }

    /**
     * Wrapper for creating table instances
     *
     * @param array<string, mixed> $options The alias to check for.
     * @return uim.cake.orm.Table
     */
    protected function _create(array $options): Table
    {
        /** @var uim.cake.orm.Table */
        return new $options["className"]($options);
    }

    /**
     * Set a Table instance.
     *
     * @param string $alias The alias to set.
     * @param uim.cake.orm.Table $repository The Table to set.
     * @return uim.cake.orm.Table
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function set(string $alias, IRepository $repository): Table
    {
        return this.instances[$alias] = $repository;
    }


    void clear() {
        super.clear();

        _fallbacked = [];
        _config = [];
    }

    /**
     * Returns the list of tables that were created by this registry that could
     * not be instantiated from a specific subclass. This method is useful for
     * debugging common mistakes when setting up associations or created new table
     * classes.
     *
     * @return array<uim.cake.orm.Table>
     */
    array genericInstances() {
        return _fallbacked;
    }


    void remove(string $alias) {
        super.remove($alias);

        unset(_fallbacked[$alias]);
    }

    /**
     * Adds a location where tables should be looked for.
     *
     * @param string $location Location to add.
     * @return this
     * @since 3.8.0
     */
    function addLocation(string $location) {
        $location = str_replace("\\", "/", $location);
        this.locations[] = trim($location, "/");

        return this;
    }
}
