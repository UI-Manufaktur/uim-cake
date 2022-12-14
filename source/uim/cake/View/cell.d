module uim.cake.views;

@safe:
import uim.cake;

use BadMethodCallException;
use Error;
use Exception;
use ReflectionException;
use ReflectionMethod;

/**
 * Cell base.
 */
#[\AllowDynamicProperties]
abstract class Cell : IEventDispatcher
{
    use EventDispatcherTrait;
    use LocatorAwareTrait;
    use ModelAwareTrait;
    use ViewVarsTrait;

    /**
     * Constant for folder name containing cell templates.
     */
    const string TEMPLATE_FOLDER = "cell";

    /**
     * Instance of the View created during rendering. Won"t be set until after
     * Cell::__toString()/render() is called.
     *
     * @var uim.cake.views\View
     */
    protected $View;

    /**
     * An instance of a Cake\Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var uim.cake.http.ServerRequest
     */
    protected myServerRequest;

    /**
     * An instance of a Response object that contains information about the impending response
     *
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * The cell"s action to invoke.
     */
    protected string $action;

    /**
     * Arguments to pass to cell"s action.
     *
     * @var array
     */
    protected $args = null;

    /**
     * List of valid options (constructor"s fourth arguments)
     * Override this property in subclasses to allow
     * which options you want set as properties in your Cell.
     *
     * @var array<string>
     */
    protected _validCellOptions = null;

    /**
     * Caching setup.
     *
     * @var array|bool
     */
    protected _cache = false;

    /**
     * Constructor.
     *
     * @param uim.cake.http.ServerRequest myServerRequest The request to use in the cell.
     * @param uim.cake.http.Response $response The response to use in the cell.
     * @param uim.cake.events.IEventManager|null $eventManager The eventManager to bind events to.
     * @param array<string, mixed> $cellOptions Cell options to apply.
     */
    this(
        ServerRequest myServerRequest,
        Response $response,
        ?IEventManager $eventManager = null,
        array $cellOptions = null
    ) {
        if ($eventManager != null) {
            this.setEventManager($eventManager);
        }
        this.request = myServerRequest;
        this.response = $response;
        this.modelFactory("Table", [this.getTableLocator(), "get"]);

        _validCellOptions = array_merge(["action", "args"], _validCellOptions);
        foreach (_validCellOptions as $var) {
            if (isset($cellOptions[$var])) {
                this.{$var} = $cellOptions[$var];
            }
        }
        if (!empty($cellOptions["cache"])) {
            _cache = $cellOptions["cache"];
        }

        this.initialize();
    }

    /**
     * Initialization hook method.
     *
     * Implement this method to avoid having to overwrite
     * the constructor and calling super(().
     */
    void initialize() {
    }

    /**
     * Render the cell.
     *
     * @param string|null $template Custom template name to render. If not provided (null), the last
     * value will be used. This value is automatically set by `CellTrait::cell()`.
     * @return string The rendered cell.
     * @throws uim.cake.views\exceptions.MissingCellTemplateException
     *   When a MissingTemplateException is raised during rendering.
     * @throws \BadMethodCallException
     */
    string render(Nullable!string $template = null) {
        $cache = null;
        if (_cache) {
            $cache = _cacheConfig(this.action, $template);
        }

        $render = function () use ($template) {
            try {
                $reflect = new ReflectionMethod(this, this.action);
                $reflect.invokeArgs(this, this.args);
            } catch (ReflectionException $e) {
                throw new BadMethodCallException(sprintf(
                    "Class %s does not have a '%s' method.",
                    static::class,
                    this.action
                ));
            }

            $builder = this.viewBuilder();

            if ($template != null) {
                $builder.setTemplate($template);
            }

            $className = static::class;
            $namePrefix = "\View\Cell\\";
            /** @psalm-suppress PossiblyFalseOperand */
            $name = substr($className, strpos($className, $namePrefix) + strlen($namePrefix));
            $name = substr($name, 0, -4);
            if (!$builder.getTemplatePath()) {
                $builder.setTemplatePath(
                    static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . replace("\\", DIRECTORY_SEPARATOR, $name)
                );
            }
            $template = $builder.getTemplate();

            $view = this.createView();
            try {
                return $view.render($template, false);
            } catch (MissingTemplateException $e) {
                $attributes = $e.getAttributes();
                throw new MissingCellTemplateException(
                    $name,
                    $attributes["file"],
                    $attributes["paths"],
                    null,
                    $e
                );
            }
        };

        if ($cache) {
            return Cache::remember($cache["key"], $render, $cache["config"]);
        }

        return $render();
    }

    /**
     * Generate the cache key to use for this cell.
     *
     * If the key is undefined, the cell class and action name will be used.
     *
     * @param string $action The action invoked.
     * @param string|null $template The name of the template to be rendered.
     * @return array The cache configuration.
     */
    protected array _cacheConfig(string $action, Nullable!string $template = null) {
        if (empty(_cache)) {
            return [];
        }
        $template = $template ?: "default";
        $key = "cell_" ~ Inflector::underscore(static::class) ~ "_" ~ $action ~ "_" ~ $template;
        $key = replace("\\", "_", $key);
        $default = [
            "config": "default",
            "key": $key,
        ];
        if (_cache == true) {
            return $default;
        }

        /** @psalm-suppress PossiblyFalseOperand */
        return _cache + $default;
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
    string toString() {
        try {
            return this.render();
        } catch (Exception $e) {
            trigger_error(sprintf(
                "Could not render cell - %s [%s, line %d]",
                $e.getMessage(),
                $e.getFile(),
                $e.getLine()
            ), E_USER_WARNING);

            return "";
        } catch (Error $e) {
            throw new Error(sprintf(
                "Could not render cell - %s [%s, line %d]",
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
    array __debugInfo() {
        return [
            "action": this.action,
            "args": this.args,
            "request": this.request,
            "response": this.response,
            "viewBuilder": this.viewBuilder(),
        ];
    }
}
