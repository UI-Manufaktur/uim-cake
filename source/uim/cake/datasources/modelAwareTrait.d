module uim.cake.datasources;

@safe:
import uim.cake;

/**
 * Provides functionality for loading table classes
 * and other repositories onto properties of the host object.
 *
 * Example users of this trait are Cake\Controller\Controller and
 * Cake\Console\Shell.
 *
 * @deprecated 4.3.0 Use `Cake\ORM\Locator\LocatorAwareTrait` instead.
 */
trait ModelAwareTrait
{
    /**
     * This object"s primary model class name. Should be a plural form.
     * UIM will not inflect the name.
     *
     * Example: For an object named "Comments", the modelClass would be "Comments".
     * Plugin classes should use `Plugin.Comments` style names to correctly load
     * models from the correct plugin.
     *
     * Use empty string to not use auto-loading on this object. Null auto-detects based on
     * controller name.
     *
     * @var string|null
     * @deprecated 4.3.0 Use `Cake\ORM\Locator\LocatorAwareTrait::$defaultTable` instead.
     */
    protected myModelClass;

    /**
     * A list of overridden model factory functions.
     *
     * @var array<callable|\Cake\Datasource\Locator\ILocator>
     */
    protected $_modelFactories = [];

    /**
     * The model type to use.
     */
    protected string $_modelType = "Table";

    /**
     * Set the modelClass property based on conventions.
     *
     * If the property is already set it will not be overwritten
     *
     * @param string myName Class name.
     */
    protected void _setModelClass(string myName) {
        if (this.modelClass == null) {
            this.modelClass = myName;
        }
    }

    /**
     * Loads and constructs repository objects required by this object
     *
     * Typically used to load ORM Table objects as required. Can
     * also be used to load other types of repository objects your application uses.
     *
     * If a repository provider does not return an object a MissingModelException will
     * be thrown.
     *
     * @param string|null myModelClass Name of model class to load. Defaults to this.modelClass.
     *  The name can be an alias like `"Post"` or FQCN like `App\Model\Table\PostsTable::class`.
     * @param string|null myModelType The type of repository to load. Defaults to the getModelType() value.
     * @return \Cake\Datasource\IRepository The model instance created.
     * @throws \Cake\Datasource\Exception\MissingModelException If the model class cannot be found.
     * @throws \UnexpectedValueException If myModelClass argument is not provided
     *   and ModelAwareTrait::myModelClass property value is empty.
     * @deprecated 4.3.0 Use `LocatorAwareTrait::fetchTable()` instead.
     */
    function loadModel(Nullable!string myModelClass = null, Nullable!string myModelType = null): IRepository
    {
        myModelClass = myModelClass ?? this.modelClass;
        if (empty(myModelClass)) {
            throw new UnexpectedValueException("Default modelClass is empty");
        }
        myModelType = myModelType ?? this.getModelType();

        myOptions = [];
        if (strpos(myModelClass, "\\") == false) {
            [, myAlias] = pluginSplit(myModelClass, true);
        } else {
            myOptions["className"] = myModelClass;
            /** @psalm-suppress PossiblyFalseOperand */
            myAlias = substr(
                myModelClass,
                strrpos(myModelClass, "\\") + 1,
                -strlen(myModelType)
            );
            myModelClass = myAlias;
        }

        if (isset(this.{myAlias})) {
            return this.{myAlias};
        }

        $factory = this._modelFactories[myModelType] ?? FactoryLocator::get(myModelType);
        if ($factory instanceof ILocator) {
            this.{myAlias} = $factory.get(myModelClass, myOptions);
        } else {
            this.{myAlias} = $factory(myModelClass, myOptions);
        }

        if (!this.{myAlias}) {
            throw new MissingModelException([myModelClass, myModelType]);
        }

        return this.{myAlias};
    }

    /**
     * Override a existing callable to generate repositories of a given type.
     *
     * @param string myType The name of the repository type the factory function is for.
     * @param \Cake\Datasource\Locator\ILocator|callable $factory The factory function used to create instances.
     */
    void modelFactory(string myType, $factory) {
        if (!$factory instanceof ILocator && !is_callable($factory)) {
            throw new InvalidArgumentException(sprintf(
                "`$factory` must be an instance of Cake\Datasource\Locator\ILocator or a callable."
                . " Got type `%s` instead.",
                getTypeName($factory)
            ));
        }

        this._modelFactories[myType] = $factory;
    }

    /**
     * Get the model type to be used by this class
     */
    string getModelType() {
        return this._modelType;
    }

    /**
     * Set the model type to be used by this class
     *
     * @param string myModelType The model type
     * @return this
     */
    auto setModelType(string myModelType) {
        this._modelType = myModelType;

        return this;
    }
}
