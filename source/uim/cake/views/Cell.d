module uim.cake.views;

use BadMethodCallException;
import uim.cake.cache\Cache;
import uim.cake.Datasource\ModelAwareTrait;
import uim.cake.Event\IEventDispatcher;
import uim.cake.Event\EventDispatcherTrait;
import uim.cake.Event\IEventManager;
import uim.cake.Http\Response;
import uim.cake.Http\ServerRequest;
import uim.cake.ORM\Locator\LocatorAwareTrait;
import uim.cake.Utility\Inflector;
import uim.cake.views\Exception\MissingCellTemplateException;
import uim.cake.views\Exception\MissingTemplateException;
use Error;
use Exception;
use ReflectionException;
use ReflectionMethod;

/**
 * Cell base.
 */
abstract class Cell : IEventDispatcher
{
    use EventDispatcherTrait;
    use LocatorAwareTrait;
    use ModelAwareTrait;
    use ViewVarsTrait;

    /**
     * Constant for folder name containing cell templates.
     *
     * @var string
     */
    public const TEMPLATE_FOLDER = 'cell';

    /**
     * Instance of the View created during rendering. Won't be set until after
     * Cell::__toString()/render() is called.
     *
     * @var \Cake\View\View
     */
    protected $View;

    /**
     * An instance of a Cake\Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var \Cake\Http\ServerRequest
     */
    protected myRequest;

    /**
     * An instance of a Response object that contains information about the impending response
     *
     * @var \Cake\Http\Response
     */
    protected $response;

    /**
     * The cell's action to invoke.
     *
     * @var string
     */
    protected $action;

    /**
     * Arguments to pass to cell's action.
     *
     * @var array
     */
    protected $args = [];

    /**
     * List of valid options (constructor's fourth arguments)
     * Override this property in subclasses to allow
     * which options you want set as properties in your Cell.
     *
     * @var array<string>
     */
    protected $_validCellOptions = [];

    /**
     * Caching setup.
     *
     * @var array|bool
     */
    protected $_cache = false;

    /**
     * Constructor.
     *
     * @param \Cake\Http\ServerRequest myRequest The request to use in the cell.
     * @param \Cake\Http\Response $response The response to use in the cell.
     * @param \Cake\Event\IEventManager|null myEventManager The eventManager to bind events to.
     * @param array<string, mixed> $cellOptions Cell options to apply.
     */
    this(
        ServerRequest myRequest,
        Response $response,
        ?IEventManager myEventManager = null,
        array $cellOptions = []
    ) {
        if (myEventManager !== null) {
            this.setEventManager(myEventManager);
        }
        this.request = myRequest;
        this.response = $response;
        this.modelFactory('Table', [this.getTableLocator(), 'get']);

        this._validCellOptions = array_merge(['action', 'args'], this._validCellOptions);
        foreach (this._validCellOptions as $var) {
            if (isset($cellOptions[$var])) {
                this.{$var} = $cellOptions[$var];
            }
        }
        if (!empty($cellOptions['cache'])) {
            this._cache = $cellOptions['cache'];
        }

        this.initialize();
    }

    /**
     * Initialization hook method.
     *
     * Implement this method to avoid having to overwrite
     * the constructor and calling super.this().
     *
     * @return void
     */
    function initialize(): void
    {
    }

    /**
     * Render the cell.
     *
     * @param string|null myTemplate Custom template name to render. If not provided (null), the last
     * value will be used. This value is automatically set by `CellTrait::cell()`.
     * @return string The rendered cell.
     * @throws \Cake\View\Exception\MissingCellTemplateException
     *   When a MissingTemplateException is raised during rendering.
     * @throws \BadMethodCallException
     */
    function render(?string myTemplate = null): string
    {
        $cache = [];
        if (this._cache) {
            $cache = this._cacheConfig(this.action, myTemplate);
        }

        $render = function () use (myTemplate) {
            try {
                $reflect = new ReflectionMethod(this, this.action);
                $reflect.invokeArgs(this, this.args);
            } catch (ReflectionException $e) {
                throw new BadMethodCallException(sprintf(
                    'Class %s does not have a "%s" method.',
                    static::class,
                    this.action
                ));
            }

            myBuilder = this.viewBuilder();

            if (myTemplate !== null) {
                myBuilder.setTemplate(myTemplate);
            }

            myClassName = static::class;
            myNamePrefix = '\View\Cell\\';
            /** @psalm-suppress PossiblyFalseOperand */
            myName = substr(myClassName, strpos(myClassName, myNamePrefix) + strlen(myNamePrefix));
            myName = substr(myName, 0, -4);
            if (!myBuilder.getTemplatePath()) {
                myBuilder.setTemplatePath(
                    static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . str_replace('\\', DIRECTORY_SEPARATOR, myName)
                );
            }
            myTemplate = myBuilder.getTemplate();

            $view = this.createView();
            try {
                return $view.render(myTemplate, false);
            } catch (MissingTemplateException $e) {
                $attributes = $e.getAttributes();
                throw new MissingCellTemplateException(
                    myName,
                    $attributes['file'],
                    $attributes['paths'],
                    null,
                    $e
                );
            }
        };

        if ($cache) {
            return Cache::remember($cache['key'], $render, $cache['config']);
        }

        return $render();
    }

    /**
     * Generate the cache key to use for this cell.
     *
     * If the key is undefined, the cell class and action name will be used.
     *
     * @param string $action The action invoked.
     * @param string|null myTemplate The name of the template to be rendered.
     * @return array The cache configuration.
     */
    protected auto _cacheConfig(string $action, ?string myTemplate = null): array
    {
        if (empty(this._cache)) {
            return [];
        }
        myTemplate = myTemplate ?: 'default';
        myKey = 'cell_' . Inflector::underscore(static::class) . '_' . $action . '_' . myTemplate;
        myKey = str_replace('\\', '_', myKey);
        $default = [
            'config' => 'default',
            'key' => myKey,
        ];
        if (this._cache === true) {
            return $default;
        }

        /** @psalm-suppress PossiblyFalseOperand */
        return this._cache + $default;
    }

    /**
     * Magic method.
     *
     * Starts the rendering process when Cell is echoed.
     *
     * *Note* This method will trigger an error when view rendering has a problem.
     * This is because PHP will not allow a __toString() method to throw an exception.
     *
     * @return string Rendered cell
     * @throws \Error Include error details for PHP 7 fatal errors.
     */
    auto __toString(): string
    {
        try {
            return this.render();
        } catch (Exception $e) {
            trigger_error(sprintf(
                'Could not render cell - %s [%s, line %d]',
                $e.getMessage(),
                $e.getFile(),
                $e.getLine()
            ), E_USER_WARNING);

            return '';
        } catch (Error $e) {
            throw new Error(sprintf(
                'Could not render cell - %s [%s, line %d]',
                $e.getMessage(),
                $e.getFile(),
                $e.getLine()
            ), 0, $e);
        }
    }

    /**
     * Debug info.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            'action' => this.action,
            'args' => this.args,
            'request' => this.request,
            'response' => this.response,
            'viewBuilder' => this.viewBuilder(),
        ];
    }
}
