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
     *
     * @var string
     */
    protected $_name;

    /**
     * A list of other associations to load from this level.
     *
     * @var array<\Cake\ORM\EagerLoadable>
     */
    protected $_associations = [];

    /**
     * The Association class instance to use for loading the records.
     *
     * @var \Cake\ORM\Association|null
     */
    protected $_instance;

    /**
     * A list of options to pass to the association object for loading
     * the records.
     *
     * @var array
     */
    protected $_config = [];

    /**
     * A dotted separated string representing the path of associations
     * that should be followed to fetch this level.
     *
     * @var string
     */
    protected $_aliasPath;

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
     * @var string|null
     */
    protected $_propertyPath;

    /**
     * Whether this level can be fetched using a join.
     *
     * @var bool
     */
    protected $_canBeJoined = false;

    /**
     * Whether this level was meant for a "matching" fetch
     * operation
     *
     * @var bool|null
     */
    protected $_forMatching;

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
     * @var string|null
     */
    protected $_targetProperty;

    /**
     * Constructor. The myConfig parameter accepts the following array
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
     * @param string myName The Association name.
     * @param array<string, mixed> myConfig The list of properties to set.
     */
    this(string myName, array myConfig = []) {
        this._name = myName;
        $allowed = [
            "associations", "instance", "config", "canBeJoined",
            "aliasPath", "propertyPath", "forMatching", "targetProperty",
        ];
        foreach ($allowed as $property) {
            if (isset(myConfig[$property])) {
                this.{"_" . $property} = myConfig[$property];
            }
        }
    }

    /**
     * Adds a new association to be loaded from this level.
     *
     * @param string myName The association name.
     * @param \Cake\ORM\EagerLoadable $association The association to load.
     * @return void
     */
    function addAssociation(string myName, EagerLoadable $association): void
    {
        this._associations[myName] = $association;
    }

    /**
     * Returns the Association class instance to use for loading the records.
     *
     * @return array<\Cake\ORM\EagerLoadable>
     */
    function associations(): array
    {
        return this._associations;
    }

    /**
     * Gets the Association class instance to use for loading the records.
     *
     * @return \Cake\ORM\Association
     * @throws \RuntimeException
     */
    function instance(): Association
    {
        if (this._instance === null) {
            throw new \RuntimeException("No instance set.");
        }

        return this._instance;
    }

    /**
     * Gets a dot separated string representing the path of associations
     * that should be followed to fetch this level.
     */
    string aliasPath() {
        return this._aliasPath;
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
     * @return string|null
     */
    function propertyPath(): Nullable!string
    {
        return this._propertyPath;
    }

    /**
     * Sets whether this level can be fetched using a join.
     *
     * @param bool $possible The value to set.
     * @return this
     */
    auto setCanBeJoined(bool $possible) {
        this._canBeJoined = $possible;

        return this;
    }

    /**
     * Gets whether this level can be fetched using a join.
     *
     * @return bool
     */
    bool canBeJoined() {
        return this._canBeJoined;
    }

    /**
     * Sets the list of options to pass to the association object for loading
     * the records.
     *
     * @param array<string, mixed> myConfig The value to set.
     * @return this
     */
    auto setConfig(array myConfig) {
        this._config = myConfig;

        return this;
    }

    /**
     * Gets the list of options to pass to the association object for loading
     * the records.
     *
     * @return array
     */
    auto getConfig(): array
    {
        return this._config;
    }

    /**
     * Gets whether this level was meant for a
     * "matching" fetch operation.
     *
     * @return bool|null
     */
    function forMatching(): ?bool
    {
        return this._forMatching;
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
     * @return string|null
     */
    function targetProperty(): Nullable!string
    {
        return this._targetProperty;
    }

    /**
     * Returns a representation of this object that can be passed to
     * Cake\ORM\EagerLoader::contain()
     *
     * @return array
     */
    function asContainArray(): array
    {
        $associations = [];
        foreach (this._associations as $assoc) {
            $associations += $assoc.asContainArray();
        }
        myConfig = this._config;
        if (this._forMatching !== null) {
            myConfig = ["matching" => this._forMatching] + myConfig;
        }

        return [
            this._name => [
                "associations" => $associations,
                "config" => myConfig,
            ],
        ];
    }

    /**
     * Handles cloning eager loadables.
     *
     * @return void
     */
    auto __clone() {
        foreach (this._associations as $i => $association) {
            this._associations[$i] = clone $association;
        }
    }
}
