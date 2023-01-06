module uim.cake.orm.locators;

@safe:
import uim.cake;

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
    protected myLocations = [];

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
    protected instances = [];

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
    protected fallbackClassName = Table::class;

    /**
     * Whether fallback class should be used if a table class could not be found.
     *
     * @var bool
     */
    protected allowFallbackClass = true;

    /**
     * Constructor.
     *
     * @param array<string>|null myLocations Locations where tables should be looked for.
     *   If none provided, the default `Model\Table` under your app"s module is used.
     */
    this(?array myLocations = null) {
        if (myLocations is null) {
            myLocations = [
                "Model/Table",
            ];
        }

        foreach (myLocations as myLocation) {
            this.addLocation(myLocation);
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
     * @param string myClassName Fallback class name
     * @return this
     * @psalm-param class-string<uim.cake.orm.Table> myClassName
     */
    auto setFallbackClassName(myClassName) {
        this.fallbackClassName = myClassName;

        return this;
    }


    auto setConfig(myAlias, myOptions = null) {
        if (!is_string(myAlias)) {
            _config = myAlias;

            return this;
        }

        if (isset(this.instances[myAlias])) {
            throw new RuntimeException(sprintf(
                "You cannot configure '%s', it has already been constructed.",
                myAlias
            ));
        }

        _config[myAlias] = myOptions;

        return this;
    }


    array getConfig(Nullable!string myAlias = null) {
        if (myAlias is null) {
            return _config;
        }

        return _config[myAlias] ?? [];
    }

    /**
     * Get a table instance from the registry.
     *
     * Tables are only created once until the registry is flushed.
     * This means that aliases must be unique across your application.
     * This is important because table associations are resolved at runtime
     * and cyclic references need to be handled correctly.
     *
     * The options that can be passed are the same as in {@link uim.cake.orm.Table::this()}, but the
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
     * *Note* If your `myAlias` uses plugin syntax only the name part will be used as
     * key in the registry. This means that if two plugins, or a plugin and app provide
     * the same alias, the registry will only store the first instance.
     *
     * @param string myAlias The alias name you want to get. Should be in CamelCase format.
     * @param array<string, mixed> myOptions The options you want to build the table with.
     *   If a table has already been loaded the options will be ignored.
     * @return uim.cake.orm.Table
     * @throws \RuntimeException When you try to configure an alias that already exists.
     */
    auto get(string myAlias, array myOptions = []): Table
    {
        /** @var uim.cake.orm.Table */
        return super.get(myAlias, myOptions);
    }


    protected auto createInstance(string myAlias, array myOptions) {
        if (indexOf(myAlias, "\\") == false) {
            [, myClassAlias] = pluginSplit(myAlias);
            myOptions = ["alias": myClassAlias] + myOptions;
        } elseif (!isset(myOptions["alias"])) {
            myOptions["className"] = myAlias;
            /** @psalm-suppress PossiblyFalseOperand */
            myAlias = substr(myAlias, strrpos(myAlias, "\\") + 1, -5);
        }

        if (isset(_config[myAlias])) {
            myOptions += _config[myAlias];
        }

        $allowFallbackClass = myOptions["allowFallbackClass"] ?? this.allowFallbackClass;
        myClassName = _getClassName(myAlias, myOptions);
        if (myClassName) {
            myOptions["className"] = myClassName;
        } elseif ($allowFallbackClass) {
            if (empty(myOptions["className"])) {
                myOptions["className"] = myAlias;
            }
            if (!isset(myOptions["table"]) && indexOf(myOptions["className"], "\\") == false) {
                [, myTable] = pluginSplit(myOptions["className"]);
                myOptions["table"] = Inflector::underscore(myTable);
            }
            myOptions["className"] = this.fallbackClassName;
        } else {
            myMessage = myOptions["className"] ?? myAlias;
            myMessage = "`" ~ myMessage ~ "`";
            if (indexOf(myMessage, "\\") == false) {
                myMessage = "for alias " ~ myMessage;
            }
            throw new MissingTableClassException([myMessage]);
        }

        if (empty(myOptions["connection"])) {
            if (!empty(myOptions["connectionName"])) {
                myConnectionName = myOptions["connectionName"];
            } else {
                /** @var uim.cake.orm.Table myClassName */
                myClassName = myOptions["className"];
                myConnectionName = myClassName::defaultConnectionName();
            }
            myOptions["connection"] = ConnectionManager::get(myConnectionName);
        }
        if (empty(myOptions["associations"])) {
            $associations = new AssociationCollection(this);
            myOptions["associations"] = $associations;
        }

        myOptions["registryAlias"] = myAlias;
        $instance = _create(myOptions);

        if (myOptions["className"] == this.fallbackClassName) {
            _fallbacked[myAlias] = $instance;
        }

        return $instance;
    }

    /**
     * Gets the table class name.
     *
     * @param string myAlias The alias name you want to get. Should be in CamelCase format.
     * @param array<string, mixed> myOptions Table options array.
     * @return string|null
     */
    protected Nullable!string _getClassName(string myAlias, array myOptions = []) {
        if (empty(myOptions["className"])) {
            myOptions["className"] = myAlias;
        }

        if (indexOf(myOptions["className"], "\\") != false && class_exists(myOptions["className"])) {
            return myOptions["className"];
        }

        foreach (this.locations as myLocation) {
            myClass = App::className(myOptions["className"], myLocation, "Table");
            if (myClass  !is null) {
                return myClass;
            }
        }

        return null;
    }

    /**
     * Wrapper for creating table instances
     *
     * @param array<string, mixed> myOptions The alias to check for.
     * @return uim.cake.orm.Table
     */
    protected auto _create(array myOptions): Table
    {
        /** @var uim.cake.orm.Table */
        return new myOptions["className"](myOptions);
    }

    /**
     * Set a Table instance.
     *
     * @param string myAlias The alias to set.
     * @param uim.cake.orm.Table myRepository The Table to set.
     * @return uim.cake.orm.Table
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    auto set(string myAlias, IRepository myRepository): Table
    {
        return this.instances[myAlias] = myRepository;
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


    void remove(string myAlias) {
        super.remove(myAlias);

        unset(_fallbacked[myAlias]);
    }

    /**
     * Adds a location where tables should be looked for.
     *
     * @param string myLocation Location to add.
     * @return this
     * @since 3.8.0
     */
    function addLocation(string myLocation) {
        myLocation = str_replace("\\", "/", myLocation);
        this.locations[] = trim(myLocation, "/");

        return this;
    }
}
