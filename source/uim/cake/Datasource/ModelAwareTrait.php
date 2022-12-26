


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Datasource;

import uim.cake.Datasource\Exception\MissingModelException;
import uim.cake.Datasource\Locator\ILocator;
use InvalidArgumentException;
use UnexpectedValueException;

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
     * CakePHP will not inflect the name.
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
    protected $modelClass;

    /**
     * A list of overridden model factory functions.
     *
     * @var array<callable|\Cake\Datasource\Locator\ILocator>
     */
    protected $_modelFactories = [];

    /**
     * The model type to use.
     *
     * @var string
     */
    protected $_modelType = "Table";

    /**
     * Set the modelClass property based on conventions.
     *
     * If the property is already set it will not be overwritten
     *
     * @param string $name Class name.
     * @return void
     */
    protected function _setModelClass(string $name): void
    {
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
     * @param string|null $modelClass Name of model class to load. Defaults to this.modelClass.
     *  The name can be an alias like `"Post"` or FQCN like `App\Model\Table\PostsTable::class`.
     * @param string|null $modelType The type of repository to load. Defaults to the getModelType() value.
     * @return \Cake\Datasource\RepositoryInterface The model instance created.
     * @throws \Cake\Datasource\Exception\MissingModelException If the model class cannot be found.
     * @throws \UnexpectedValueException If $modelClass argument is not provided
     *   and ModelAwareTrait::$modelClass property value is empty.
     * @deprecated 4.3.0 Use `LocatorAwareTrait::fetchTable()` instead.
     */
    function loadModel(?string $modelClass = null, ?string $modelType = null): RepositoryInterface
    {
        $modelClass = $modelClass ?? this.modelClass;
        if (empty($modelClass)) {
            throw new UnexpectedValueException("Default modelClass is empty");
        }
        $modelType = $modelType ?? this.getModelType();

        $options = [];
        if (strpos($modelClass, "\\") == false) {
            [, $alias] = pluginSplit($modelClass, true);
        } else {
            $options["className"] = $modelClass;
            /** @psalm-suppress PossiblyFalseOperand */
            $alias = substr(
                $modelClass,
                strrpos($modelClass, "\\") + 1,
                -strlen($modelType)
            );
            $modelClass = $alias;
        }

        if (isset(this.{$alias})) {
            return this.{$alias};
        }

        $factory = _modelFactories[$modelType] ?? FactoryLocator::get($modelType);
        if ($factory instanceof ILocator) {
            this.{$alias} = $factory.get($modelClass, $options);
        } else {
            this.{$alias} = $factory($modelClass, $options);
        }

        if (!this.{$alias}) {
            throw new MissingModelException([$modelClass, $modelType]);
        }

        return this.{$alias};
    }

    /**
     * Override a existing callable to generate repositories of a given type.
     *
     * @param string $type The name of the repository type the factory function is for.
     * @param \Cake\Datasource\Locator\ILocator|callable $factory The factory function used to create instances.
     * @return void
     */
    function modelFactory(string $type, $factory): void
    {
        if (!$factory instanceof ILocator&& !is_callable($factory)) {
            throw new InvalidArgumentException(sprintf(
                "`$factory` must be an instance of Cake\Datasource\Locator\ILocatoror a callable."
                . " Got type `%s` instead.",
                getTypeName($factory)
            ));
        }

        _modelFactories[$type] = $factory;
    }

    /**
     * Get the model type to be used by this class
     *
     * @return string
     */
    function getModelType(): string
    {
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
