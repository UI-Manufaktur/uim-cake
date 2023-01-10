module uim.datasources;

@safe:
import uim.cake;

import uim.datasources.exceptions.MissingModelException;
import uim.datasources.Locator\ILocator;
use InvalidArgumentException;
use UnexpectedValueException;

/**
 * Provides functionality for loading table classes
 * and other repositories onto properties of the host object.
 *
 * Example users of this trait are Cake\Controller\Controller and
 * Cake\Console\Shell.
 *
 * @deprecated 4.3.0 Use `Cake\orm.Locator\LocatorAwareTrait` instead.
 */
trait ModelAwareTrait
{
    /**
     * This object"s primary model class name. Should be a plural form.
     * Example: For an object named "Comments", the modelClass would be "Comments".
     * Plugin classes should use `Plugin.Comments` style names to correctly load models from the correct plugin.
     *
     * Use empty string to not use auto-loading on this object. Null auto-detects based on
     * controller name.
     *
     * @deprecated 4.3.0 Use `Cake\orm.Locator\LocatorAwareTrait::$defaultTable` instead.
     */
    protected string _modelClassName;

    /**
     * A list of overridden model factory functions.
     *
     * @var array<callable|uim.cake.Datasource\Locator\ILocator>
     */
    protected _modelFactories = [];

    /**
     * The model type to use.
     */
    protected string _modelType = "Table";

    /**
     * Set the modelClass property based on conventions.
     *
     * If the property is already set it will not be overwritten
     *
     * @param string aName Class name.
     */
    protected void _setModelClass(string aName) {
        if (this.modelClass == null) {
            this.modelClass = $name;
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
     * @param string|null _modelClassName Name of model class to load. Defaults to this.modelClass.
     *  The name can be an alias like `"Post"` or FQCN like `App\Model\Table\PostsTable::class`.
     * @param string|null $modelType The type of repository to load. Defaults to the getModelType() value.
     * @return uim.cake.Datasource\IRepository The model instance created.
     * @throws uim.cake.Datasource\exceptions.MissingModelException If the model class cannot be found.
     * @throws \UnexpectedValueException If _modelClassName argument is not provided
     *   and ModelAwareTrait::_modelClassName property value is empty.
     * @deprecated 4.3.0 Use `LocatorAwareTrait::fetchTable()` instead.
     */
    function loadModel(Nullable!string _modelClassName = null, Nullable!string $modelType = null): IRepository
    {
        _modelClassName = _modelClassName ?? this.modelClass;
        if (empty(_modelClassName)) {
            throw new UnexpectedValueException("Default modelClass is empty");
        }
        $modelType = $modelType ?? this.getModelType();

        $options = [];
        if (strpos(_modelClassName, "\\") == false) {
            [, $alias] = pluginSplit(_modelClassName, true);
        } else {
            $options["className"] = _modelClassName;
            /** @psalm-suppress PossiblyFalseOperand */
            $alias = substr(
                _modelClassName,
                strrpos(_modelClassName, "\\") + 1,
                -strlen($modelType)
            );
            _modelClassName = $alias;
        }

        if (isset(this.{$alias})) {
            return this.{$alias};
        }

        $factory = _modelFactories[$modelType] ?? FactoryLocator::get($modelType);
        if ($factory instanceof ILocator) {
            this.{$alias} = $factory.get(_modelClassName, $options);
        } else {
            this.{$alias} = $factory(_modelClassName, $options);
        }

        if (!this.{$alias}) {
            throw new MissingModelException([_modelClassName, $modelType]);
        }

        return this.{$alias};
    }

    /**
     * Override a existing callable to generate repositories of a given type.
     *
     * @param string $type The name of the repository type the factory bool is for.
     * @param uim.cake.Datasource\Locator\ILocator|callable $factory The factory function used to create instances.
     */
    void modelFactory(string $type, $factory) {
        if (!$factory instanceof ILocator&& !is_callable($factory)) {
            throw new InvalidArgumentException(sprintf(
                "`$factory` must be an instance of Cake\Datasource\Locator\ILocatoror a callable."
                ~ " Got type `%s` instead.",
                getTypeName($factory)
            ));
        }

        _modelFactories[$type] = $factory;
    }

    /**
     * Get the model type to be used by this class
     */
    string getModelType() {
        return _modelType;
    }

    /**
     * Set the model type to be used by this class
     *
     * @param string $modelType The model type
     * @return this
     */
    function setModelType(string $modelType) {
        _modelType = $modelType;

        return this;
    }
}
