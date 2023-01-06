module uim.cake.ORM;

/**
 * Represents a single level in the associations tree to be eagerly loaded
 * for a specific query. This contains all the information required to
 * fetch the results from the database from an associations and all its children
 * levels.
 *
 * @internal
 */
class EagerLoadable
{
    /**
     * The name of the association to load.
     */
    protected string _name;

    /**
     * A list of other associations to load from this level.
     *
     * @var array<uim.cake.orm.EagerLoadable>
     */
    protected _associations = [];

    /**
     * The Association class instance to use for loading the records.
     *
     * @var uim.cake.orm.Association|null
     */
    protected _instance;

    /**
     * A list of options to pass to the association object for loading
     * the records.
     *
     * @var array<string, mixed>
     */
    protected _config = [];

    /**
     * A dotted separated string representing the path of associations
     * that should be followed to fetch this level.
     */
    protected string _aliasPath;

    /**
     * A dotted separated string representing the path of entity properties
     * in which results for this level should be placed.
     *
     * For example, in the following nested property:
     *
     * ```
     *  $article.author.company.country
     * ```
     *
     * The property path of `country` will be `author.company`
     *
     */
    protected Nullable!string _propertyPath;

    /**
     * Whether this level can be fetched using a join.
     */
    protected bool _canBeJoined = false;

    /**
     * Whether this level was meant for a "matching" fetch
     * operation
     *
     * @var bool|null
     */
    protected _forMatching;

    /**
     * The property name where the association result should be nested
     * in the result.
     *
     * For example, in the following nested property:
     *
     * ```
     *  $article.author.company.country
     * ```
     *
     * The target property of `country` will be just `country`
     *
     */
    protected Nullable!string _targetProperty;

    /**
     * Constructor. The aConfig parameter accepts the following array
     * keys:
     *
     * - associations
     * - instance
     * - config
     * - canBeJoined
     * - aliasPath
     * - propertyPath
     * - forMatching
     * - targetProperty
     *
     * The keys maps to the settable properties in this class.
     *
     * @param string aName The Association name.
     * @param array<string, mixed> aConfig The list of properties to set.
     */
    this(string aName, Json aConfig = []) {
        _name = $name;
        $allowed = [
            "associations", "instance", "config", "canBeJoined",
            "aliasPath", "propertyPath", "forMatching", "targetProperty",
        ];
        foreach ($allowed as $property) {
            if (isset(aConfig[$property])) {
                this.{"_" ~ $property} = aConfig[$property];
            }
        }
    }

    /**
     * Adds a new association to be loaded from this level.
     *
     * @param string aName The association name.
     * @param uim.cake.orm.EagerLoadable $association The association to load.
     */
    void addAssociation(string aName, EagerLoadable $association) {
        _associations[$name] = $association;
    }

    /**
     * Returns the Association class instance to use for loading the records.
     *
     * @return array<uim.cake.orm.EagerLoadable>
     */
    array associations() {
        return _associations;
    }

    /**
     * Gets the Association class instance to use for loading the records.
     *
     * @return uim.cake.orm.Association
     * @throws \RuntimeException
     */
    function instance(): Association
    {
        if (_instance == null) {
            throw new \RuntimeException("No instance set.");
        }

        return _instance;
    }

    /**
     * Gets a dot separated string representing the path of associations
     * that should be followed to fetch this level.
     */
    string aliasPath() {
        return _aliasPath;
    }

    /**
     * Gets a dot separated string representing the path of entity properties
     * in which results for this level should be placed.
     *
     * For example, in the following nested property:
     *
     * ```
     *  $article.author.company.country
     * ```
     *
     * The property path of `country` will be `author.company`
     *
     */
    Nullable!string propertyPath() {
        return _propertyPath;
    }

    /**
     * Sets whether this level can be fetched using a join.
     *
     * @param bool $possible The value to set.
     * @return this
     */
    function setCanBeJoined(bool $possible) {
        _canBeJoined = $possible;

        return this;
    }

    /**
     * Gets whether this level can be fetched using a join.
     */
    bool canBeJoined() {
        return _canBeJoined;
    }

    /**
     * Sets the list of options to pass to the association object for loading
     * the records.
     *
     * @param array<string, mixed> aConfig The value to set.
     * @return this
     */
    function setConfig(Json aConfig) {
        _config = aConfig;

        return this;
    }

    /**
     * Gets the list of options to pass to the association object for loading
     * the records.
     *
     * @return array<string, mixed>
     */
    array getConfig() {
        return _config;
    }

    /**
     * Gets whether this level was meant for a
     * "matching" fetch operation.
     *
     * @return bool|null
     */
    function forMatching(): ?bool
    {
        return _forMatching;
    }

    /**
     * The property name where the result of this association
     * should be nested at the end.
     *
     * For example, in the following nested property:
     *
     * ```
     *  $article.author.company.country
     * ```
     *
     * The target property of `country` will be just `country`
     *
     */
    Nullable!string targetProperty() {
        return _targetProperty;
    }

    /**
     * Returns a representation of this object that can be passed to
     * Cake\orm.EagerLoader::contain()
     *
     * @return array<string, array>
     */
    array asContainArray() {
        $associations = [];
        foreach (_associations as $assoc) {
            $associations += $assoc.asContainArray();
        }
        aConfig = _config;
        if (_forMatching != null) {
            aConfig = ["matching": _forMatching] + aConfig;
        }

        return [
            _name: [
                "associations": $associations,
                "config": aConfig,
            ],
        ];
    }

    /**
     * Handles cloning eager loadables.
     */
    void __clone() {
        foreach (_associations as $i: $association) {
            _associations[$i] = clone $association;
        }
    }
}
