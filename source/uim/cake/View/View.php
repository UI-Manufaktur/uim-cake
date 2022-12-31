


 *


 * @since         0.10.0

 */module uim.cake.View;

import uim.cake.caches.Cache;
import uim.cake.core.App;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.core.Plugin;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.events.EventManager;
import uim.cake.http.Response;
import uim.cake.http.ServerRequest;
import uim.cake.logs.LogTrait;
import uim.cake.routings.Router;
import uim.cake.utilities.Inflector;
import uim.cake.View\exceptions.MissingElementException;
import uim.cake.View\exceptions.MissingLayoutException;
import uim.cake.View\exceptions.MissingTemplateException;
use InvalidArgumentException;
use LogicException;
use RuntimeException;
use Throwable;

/**
 * View, the V in the MVC triad. View interacts with Helpers and view variables passed
 * in from the controller to render the results of the controller action. Often this is HTML,
 * but can also take the form of JSON, XML, PDF"s or streaming files.
 *
 * CakePHP uses a two-step-view pattern. This means that the template content is rendered first,
 * and then inserted into the selected layout. This also means you can pass data from the template to the
 * layout using `this.set()`
 *
 * View class supports using plugins as themes. You can set
 *
 * ```
 * function beforeRender(uim.cake.events.IEvent $event)
 * {
 *      this.viewBuilder().setTheme("SuperHot");
 * }
 * ```
 *
 * in your Controller to use plugin `SuperHot` as a theme. Eg. If current action
 * is PostsController::index() then View class will look for template file
 * `plugins/SuperHot/templates/Posts/index.php`. If a theme template
 * is not found for the current action the default app template file is used.
 *
 * @property uim.cake.View\Helper\BreadcrumbsHelper $Breadcrumbs
 * @property uim.cake.View\Helper\FlashHelper $Flash
 * @property uim.cake.View\Helper\FormHelper $Form
 * @property uim.cake.View\Helper\HtmlHelper $Html
 * @property uim.cake.View\Helper\NumberHelper $Number
 * @property uim.cake.View\Helper\PaginatorHelper $Paginator
 * @property uim.cake.View\Helper\TextHelper $Text
 * @property uim.cake.View\Helper\TimeHelper $Time
 * @property uim.cake.View\Helper\UrlHelper $Url
 * @property uim.cake.View\ViewBlock $Blocks
 */
#[\AllowDynamicProperties]
class View : EventDispatcherInterface
{
    use CellTrait {
        cell as public;
    }
    use EventDispatcherTrait;
    use InstanceConfigTrait {
        getConfig as private _getConfig;
    }
    use LogTrait;

    /**
     * Helpers collection
     *
     * @var uim.cake.View\HelperRegistry
     */
    protected $_helpers;

    /**
     * ViewBlock instance.
     *
     * @var uim.cake.View\ViewBlock
     */
    protected $Blocks;

    /**
     * The name of the plugin.
     *
     * @var string|null
     */
    protected $plugin;

    /**
     * Name of the controller that created the View if any.
     *
     */
    protected string aName = "";

    /**
     * An array of names of built-in helpers to include.
     *
     * @var array
     */
    protected $helpers = [];

    /**
     * The name of the subfolder containing templates for this View.
     *
     */
    protected string $templatePath = "";

    /**
     * The name of the template file to render. The name specified
     * is the filename in `templates/<SubFolder>/` without the .php extension.
     *
     */
    protected string $template = "";

    /**
     * The name of the layout file to render the template inside of. The name specified
     * is the filename of the layout in `templates/layout/` without the .php
     * extension.
     *
     */
    protected string $layout = "default";

    /**
     * The name of the layouts subfolder containing layouts for this View.
     *
     */
    protected string $layoutPath = "";

    /**
     * Turns on or off CakePHP"s conventional mode of applying layout files. On by default.
     * Setting to off means that layouts will not be automatically applied to rendered templates.
     *
     */
    protected bool $autoLayout = true;

    /**
     * An array of variables
     *
     * @var array<string, mixed>
     */
    protected $viewVars = [];

    /**
     * File extension. Defaults to ".php".
     *
     */
    protected string $_ext = ".php";

    /**
     * Sub-directory for this template file. This is often used for extension based routing.
     * Eg. With an `xml` extension, $subDir would be `xml/`
     *
     */
    protected string $subDir = "";

    /**
     * The view theme to use.
     *
     * @var string|null
     */
    protected $theme;

    /**
     * An instance of a uim.cake.Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var uim.cake.http.ServerRequest
     */
    protected $request;

    /**
     * Reference to the Response object
     *
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * The Cache configuration View will use to store cached elements. Changing this will change
     * the default configuration elements are stored under. You can also choose a cache config
     * per element.
     *
     * @var string
     * @see uim.cake.View\View::element()
     */
    protected $elementCache = "default";

    /**
     * List of variables to collect from the associated controller.
     *
     * @var array<string>
     */
    protected $_passedVars = [
        "viewVars", "autoLayout", "helpers", "template", "layout", "name", "theme",
        "layoutPath", "templatePath", "plugin",
    ];

    /**
     * Default custom config options.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * Holds an array of paths.
     *
     * @var array<string>
     */
    protected $_paths = [];

    /**
     * Holds an array of plugin paths.
     *
     * @var array<string[]>
     */
    protected $_pathsForPlugin = [];

    /**
     * The names of views and their parents used with View::extend();
     *
     * @var array<string>
     */
    protected $_parents = [];

    /**
     * The currently rendering view file. Used for resolving parent files.
     *
     */
    protected string $_current;

    /**
     * Currently rendering an element. Used for finding parent fragments
     * for elements.
     *
     */
    protected string $_currentType = "";

    /**
     * Content stack, used for nested templates that all use View::extend();
     *
     * @var array<string>
     */
    protected $_stack = [];

    /**
     * ViewBlock class.
     *
     * @var string
     * @psalm-var class-string<uim.cake.View\ViewBlock>
     */
    protected $_viewBlockClass = ViewBlock::class;

    /**
     * Constant for view file type "template".
     *
     * @var string
     */
    const TYPE_TEMPLATE = "template";

    /**
     * Constant for view file type "element"
     *
     * @var string
     */
    const TYPE_ELEMENT = "element";

    /**
     * Constant for view file type "layout"
     *
     * @var string
     */
    const TYPE_LAYOUT = "layout";

    /**
     * Constant for type used for App::path().
     *
     * @var string
     */
    const NAME_TEMPLATE = "templates";

    /**
     * Constant for folder name containing files for overriding plugin templates.
     *
     * @var string
     */
    const PLUGIN_TEMPLATE_FOLDER = "plugin";

    /**
     * The magic "match-all" content type that views can use to
     * behave as a fallback during content-type negotiation.
     *
     * @var string
     */
    const TYPE_MATCH_ALL = "_match_all_";

    /**
     * Constructor
     *
     * @param uim.cake.http.ServerRequest|null $request Request instance.
     * @param uim.cake.http.Response|null $response Response instance.
     * @param uim.cake.events.EventManager|null $eventManager Event manager instance.
     * @param array<string, mixed> $viewOptions View options. See {@link View::$_passedVars} for list of
     *   options which get set as class properties.
     */
    this(
        ?ServerRequest $request = null,
        ?Response $response = null,
        ?EventManager $eventManager = null,
        array $viewOptions = []
    ) {
        foreach (_passedVars as $var) {
            if (isset($viewOptions[$var])) {
                this.{$var} = $viewOptions[$var];
            }
        }
        this.setConfig(array_diff_key(
            $viewOptions,
            array_flip(_passedVars)
        ));

        if ($eventManager != null) {
            this.setEventManager($eventManager);
        }
        if ($request == null) {
            $request = Router::getRequest() ?: new ServerRequest(["base": "", "url": "", "webroot": "/"]);
        }
        this.request = $request;
        this.response = $response ?: new Response();
        this.Blocks = new _viewBlockClass();
        this.initialize();
        this.loadHelpers();
    }

    /**
     * Initialization hook method.
     *
     * Properties like $helpers etc. cannot be initialized statically in your custom
     * view class as they are overwritten by values from controller in constructor.
     * So this method allows you to manipulate them as required after view instance
     * is constructed.
     */
    void initialize(): void
    {
        this.setContentType();
    }

    /**
     * Set the response content-type based on the view"s contentType()
     *
     */
    protected void setContentType(): void
    {
        $viewContentType = this.contentType();
        if (!$viewContentType || $viewContentType == static::TYPE_MATCH_ALL) {
            return;
        }
        $response = this.getResponse();
        $responseType = $response.getHeaderLine("Content-Type");
        if ($responseType == "" || substr($responseType, 0, 9) == "text/html") {
            $response = $response.withType($viewContentType);
        }
        this.setResponse($response);
    }

    /**
     * Mime-type this view class renders as.
     *
     * @return string Either the content type or "" which means no type.
     */
    static function contentType(): string
    {
        return "";
    }

    /**
     * Gets the request instance.
     *
     * @return uim.cake.http.ServerRequest

     */
    function getRequest(): ServerRequest
    {
        return this.request;
    }

    /**
     * Sets the request objects and configures a number of controller properties
     * based on the contents of the request. The properties that get set are:
     *
     * - this.request - To the $request parameter
     * - this.plugin - To the value returned by $request.getParam("plugin")
     *
     * @param uim.cake.http.ServerRequest $request Request instance.
     * @return this
     */
    function setRequest(ServerRequest $request) {
        this.request = $request;
        this.plugin = $request.getParam("plugin");

        return this;
    }

    /**
     * Gets the response instance.
     *
     * @return uim.cake.http.Response
     */
    function getResponse(): Response
    {
        return this.response;
    }

    /**
     * Sets the response instance.
     *
     * @param uim.cake.http.Response $response Response instance.
     * @return this
     */
    function setResponse(Response $response) {
        this.response = $response;

        return this;
    }

    /**
     * Get path for templates files.
     */
    string getTemplatePath(): string
    {
        return this.templatePath;
    }

    /**
     * Set path for templates files.
     *
     * @param string $path Path for template files.
     * @return this
     */
    function setTemplatePath(string $path) {
        this.templatePath = $path;

        return this;
    }

    /**
     * Get path for layout files.
     */
    string getLayoutPath(): string
    {
        return this.layoutPath;
    }

    /**
     * Set path for layout files.
     *
     * @param string $path Path for layout files.
     * @return this
     */
    function setLayoutPath(string $path) {
        this.layoutPath = $path;

        return this;
    }

    /**
     * Returns if CakePHP"s conventional mode of applying layout files is enabled.
     * Disabled means that layouts will not be automatically applied to rendered views.
     *
     * @return bool
     */
    function isAutoLayoutEnabled(): bool
    {
        return this.autoLayout;
    }

    /**
     * Turns on or off CakePHP"s conventional mode of applying layout files.
     * On by default. Setting to off means that layouts will not be
     * automatically applied to rendered views.
     *
     * @param bool $enable Boolean to turn on/off.
     * @return this
     */
    function enableAutoLayout(bool $enable = true) {
        this.autoLayout = $enable;

        return this;
    }

    /**
     * Turns off CakePHP"s conventional mode of applying layout files.
     * Layouts will not be automatically applied to rendered views.
     *
     * @return this
     */
    function disableAutoLayout() {
        this.autoLayout = false;

        return this;
    }

    /**
     * Get the current view theme.
     *
     * @return string|null
     */
    function getTheme(): ?string
    {
        return this.theme;
    }

    /**
     * Set the view theme to use.
     *
     * @param string|null $theme Theme name.
     * @return this
     */
    function setTheme(?string $theme) {
        this.theme = $theme;

        return this;
    }

    /**
     * Get the name of the template file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     */
    string getTemplate(): string
    {
        return this.template;
    }

    /**
     * Set the name of the template file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @param string aName Template file name to set.
     * @return this
     */
    function setTemplate(string aName) {
        this.template = $name;

        return this;
    }

    /**
     * Get the name of the layout file to render the template inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     */
    string getLayout(): string
    {
        return this.layout;
    }

    /**
     * Set the name of the layout file to render the template inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @param string aName Layout file name to set.
     * @return this
     */
    function setLayout(string aName) {
        this.layout = $name;

        return this;
    }

    /**
     * Get config value.
     *
     * Currently if config is not set it fallbacks to checking corresponding
     * view var with underscore prefix. Using underscore prefixed special view
     * vars is deprecated and this fallback will be removed in CakePHP 4.1.0.
     *
     * @param string|null $key The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Config value being read.
     * @psalm-suppress PossiblyNullArgument
     */
    function getConfig(?string aKey = null, $default = null) {
        $value = _getConfig($key);

        if ($value != null) {
            return $value;
        }

        if (isset(this.viewVars["_{$key}"])) {
            deprecationWarning(sprintf(
                "Setting special view var "_%s" is deprecated. Use ViewBuilder::setOption(\"%s\", $value) instead.",
                $key,
                $key
            ));

            return this.viewVars["_{$key}"];
        }

        return $default;
    }

    /**
     * Renders a piece of PHP with provided parameters and returns HTML, XML, or any other string.
     *
     * This realizes the concept of Elements, (or "partial layouts") and the $params array is used to send
     * data to be used in the element. Elements can be cached improving performance by using the `cache` option.
     *
     * @param string aName Name of template file in the `templates/element/` folder,
     *   or `MyPlugin.template` to use the template element from MyPlugin. If the element
     *   is not found in the plugin, the normal view path cascade will be searched.
     * @param array $data Array of data to be made available to the rendered view (i.e. the Element)
     * @param array<string, mixed> $options Array of options. Possible keys are:
     *
     * - `cache` - Can either be `true`, to enable caching using the config in View::$elementCache. Or an array
     *   If an array, the following keys can be used:
     *
     *   - `config` - Used to store the cached element in a custom cache configuration.
     *   - `key` - Used to define the key used in the Cache::write(). It will be prefixed with `element_`
     *
     * - `callbacks` - Set to true to fire beforeRender and afterRender helper callbacks for this element.
     *   Defaults to false.
     * - `ignoreMissing` - Used to allow missing elements. Set to true to not throw exceptions.
     * - `plugin` - setting to false will force to use the application"s element from plugin templates, when the
     *   plugin has element with same name. Defaults to true
     * @return string Rendered Element
     * @throws uim.cake.View\exceptions.MissingElementException When an element is missing and `ignoreMissing`
     *   is false.
     * @psalm-param array{cache?:array|true, callbacks?:bool, plugin?:string|false, ignoreMissing?:bool} $options
     */
    function element(string aName, array $data = [], array $options = []): string
    {
        $options += ["callbacks": false, "cache": null, "plugin": null, "ignoreMissing": false];
        if (isset($options["cache"])) {
            $options["cache"] = _elementCache(
                $name,
                $data,
                array_diff_key($options, ["callbacks": false, "plugin": null, "ignoreMissing": null])
            );
        }

        $pluginCheck = $options["plugin"] != false;
        $file = _getElementFileName($name, $pluginCheck);
        if ($file && $options["cache"]) {
            return this.cache(function () use ($file, $data, $options): void {
                echo _renderElement($file, $data, $options);
            }, $options["cache"]);
        }
        if ($file) {
            return _renderElement($file, $data, $options);
        }

        if ($options["ignoreMissing"]) {
            return "";
        }

        [$plugin, $elementName] = this.pluginSplit($name, $pluginCheck);
        $paths = iterator_to_array(this.getElementPaths($plugin));
        throw new MissingElementException([$name . _ext, $elementName . _ext], $paths);
    }

    /**
     * Create a cached block of view logic.
     *
     * This allows you to cache a block of view output into the cache
     * defined in `elementCache`.
     *
     * This method will attempt to read the cache first. If the cache
     * is empty, the $block will be run and the output stored.
     *
     * @param callable $block The block of code that you want to cache the output of.
     * @param array<string, mixed> $options The options defining the cache key etc.
     * @return string The rendered content.
     * @throws \RuntimeException When $options is lacking a "key" option.
     */
    function cache(callable $block, array $options = []): string
    {
        $options += ["key": "", "config": this.elementCache];
        if (empty($options["key"])) {
            throw new RuntimeException("Cannot cache content with an empty key");
        }
        $result = Cache::read($options["key"], $options["config"]);
        if ($result) {
            return $result;
        }

        $bufferLevel = ob_get_level();
        ob_start();

        try {
            $block();
        } catch (Throwable $exception) {
            while (ob_get_level() > $bufferLevel) {
                ob_end_clean();
            }

            throw $exception;
        }

        $result = ob_get_clean();

        Cache::write($options["key"], $result, $options["config"]);

        return $result;
    }

    /**
     * Checks if an element exists
     *
     * @param string aName Name of template file in the `templates/element/` folder,
     *   or `MyPlugin.template` to check the template element from MyPlugin. If the element
     *   is not found in the plugin, the normal view path cascade will be searched.
     * @return bool Success
     */
    function elementExists(string aName): bool
    {
        return (bool)_getElementFileName($name);
    }

    /**
     * Renders view for given template file and layout.
     *
     * Render triggers helper callbacks, which are fired before and after the template are rendered,
     * as well as before and after the layout. The helper callbacks are called:
     *
     * - `beforeRender`
     * - `afterRender`
     * - `beforeLayout`
     * - `afterLayout`
     *
     * If View::$autoLayout is set to `false`, the template will be returned bare.
     *
     * Template and layout names can point to plugin templates or layouts. Using the `Plugin.template` syntax
     * a plugin template/layout/ can be used instead of the app ones. If the chosen plugin is not found
     * the template will be located along the regular view path cascade.
     *
     * @param string|null $template Name of template file to use
     * @param string|false|null $layout Layout to use. False to disable.
     * @return string Rendered content.
     * @throws uim.cake.Core\exceptions.CakeException If there is an error in the view.
     * @triggers View.beforeRender this, [$templateFileName]
     * @triggers View.afterRender this, [$templateFileName]
     */
    function render(?string $template = null, $layout = null): string
    {
        $defaultLayout = "";
        $defaultAutoLayout = null;
        if ($layout == false) {
            $defaultAutoLayout = this.autoLayout;
            this.autoLayout = false;
        } elseif ($layout != null) {
            $defaultLayout = this.layout;
            this.layout = $layout;
        }

        $templateFileName = _getTemplateFileName($template);
        _currentType = static::TYPE_TEMPLATE;
        this.dispatchEvent("View.beforeRender", [$templateFileName]);
        this.Blocks.set("content", _render($templateFileName));
        this.dispatchEvent("View.afterRender", [$templateFileName]);

        if (this.autoLayout) {
            if (empty(this.layout)) {
                throw new RuntimeException(
                    "View::$layout must be a non-empty string." .
                    "To disable layout rendering use method View::disableAutoLayout() instead."
                );
            }

            this.Blocks.set("content", this.renderLayout("", this.layout));
        }
        if ($layout != null) {
            this.layout = $defaultLayout;
        }
        if ($defaultAutoLayout != null) {
            this.autoLayout = $defaultAutoLayout;
        }

        return this.Blocks.get("content");
    }

    /**
     * Renders a layout. Returns output from _render().
     *
     * Several variables are created for use in layout.
     *
     * @param string $content Content to render in a template, wrapped by the surrounding layout.
     * @param string|null $layout Layout name
     * @return string Rendered output.
     * @throws uim.cake.Core\exceptions.CakeException if there is an error in the view.
     * @triggers View.beforeLayout this, [$layoutFileName]
     * @triggers View.afterLayout this, [$layoutFileName]
     */
    function renderLayout(string $content, ?string $layout = null): string
    {
        $layoutFileName = _getLayoutFileName($layout);

        if (!empty($content)) {
            this.Blocks.set("content", $content);
        }

        this.dispatchEvent("View.beforeLayout", [$layoutFileName]);

        $title = this.Blocks.get("title");
        if ($title == "") {
            $title = Inflector::humanize(str_replace(DIRECTORY_SEPARATOR, "/", this.templatePath));
            this.Blocks.set("title", $title);
        }

        _currentType = static::TYPE_LAYOUT;
        this.Blocks.set("content", _render($layoutFileName));

        this.dispatchEvent("View.afterLayout", [$layoutFileName]);

        return this.Blocks.get("content");
    }

    /**
     * Returns a list of variables available in the current View context
     *
     * @return array<string> Array of the set view variable names.
     */
    string[] getVars(): array
    {
        return array_keys(this.viewVars);
    }

    /**
     * Returns the contents of the given View variable.
     *
     * @param string $var The view var you want the contents of.
     * @param mixed $default The default/fallback content of $var.
     * @return mixed The content of the named var if its set, otherwise $default.
     */
    function get(string $var, $default = null) {
        return this.viewVars[$var] ?? $default;
    }

    /**
     * Saves a variable or an associative array of variables for use inside a template.
     *
     * @param array|string aName A string or an array of data.
     * @param mixed $value Value in case $name is a string (which then works as the key).
     *   Unused if $name is an associative array, otherwise serves as the values to $name"s keys.
     * @return this
     * @throws \RuntimeException If the array combine operation failed.
     */
    function set($name, $value = null) {
        if (is_array($name)) {
            if (is_array($value)) {
                /** @var array|false $data */
                $data = array_combine($name, $value);
                if ($data == false) {
                    throw new RuntimeException(
                        "Invalid data provided for array_combine() to work: Both $name and $value require same count."
                    );
                }
            } else {
                $data = $name;
            }
        } else {
            $data = [$name: $value];
        }
        this.viewVars = $data + this.viewVars;

        return this;
    }

    /**
     * Get the names of all the existing blocks.
     *
     * @return array<string> An array containing the blocks.
     * @see uim.cake.View\ViewBlock::keys()
     */
    string[] blocks(): array
    {
        return this.Blocks.keys();
    }

    /**
     * Start capturing output for a "block"
     *
     * You can use start on a block multiple times to
     * append or prepend content in a capture mode.
     *
     * ```
     * // Append content to an existing block.
     * this.start("content");
     * echo this.fetch("content");
     * echo "Some new content";
     * this.end();
     *
     * // Prepend content to an existing block
     * this.start("content");
     * echo "Some new content";
     * echo this.fetch("content");
     * this.end();
     * ```
     *
     * @param string aName The name of the block to capture for.
     * @return this
     * @see uim.cake.View\ViewBlock::start()
     */
    function start(string aName) {
        this.Blocks.start($name);

        return this;
    }

    /**
     * Append to an existing or new block.
     *
     * Appending to a new block will create the block.
     *
     * @param string aName Name of the block
     * @param mixed $value The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see uim.cake.View\ViewBlock::concat()
     */
    function append(string aName, $value = null) {
        this.Blocks.concat($name, $value);

        return this;
    }

    /**
     * Prepend to an existing or new block.
     *
     * Prepending to a new block will create the block.
     *
     * @param string aName Name of the block
     * @param mixed $value The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see uim.cake.View\ViewBlock::concat()
     */
    function prepend(string aName, $value) {
        this.Blocks.concat($name, $value, ViewBlock::PREPEND);

        return this;
    }

    /**
     * Set the content for a block. This will overwrite any
     * existing content.
     *
     * @param string aName Name of the block
     * @param mixed $value The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see uim.cake.View\ViewBlock::set()
     */
    function assign(string aName, $value) {
        this.Blocks.set($name, $value);

        return this;
    }

    /**
     * Reset the content for a block. This will overwrite any
     * existing content.
     *
     * @param string aName Name of the block
     * @return this
     * @see uim.cake.View\ViewBlock::set()
     */
    function reset(string aName) {
        this.assign($name, "");

        return this;
    }

    /**
     * Fetch the content for a block. If a block is
     * empty or undefined "" will be returned.
     *
     * @param string aName Name of the block
     * @param string $default Default text
     * @return string The block content or $default if the block does not exist.
     * @see uim.cake.View\ViewBlock::get()
     */
    function fetch(string aName, string $default = ""): string
    {
        return this.Blocks.get($name, $default);
    }

    /**
     * End a capturing block. The compliment to View::start()
     *
     * @return this
     * @see uim.cake.View\ViewBlock::end()
     */
    function end() {
        this.Blocks.end();

        return this;
    }

    /**
     * Check if a block exists
     *
     * @param string aName Name of the block
     * @return bool
     */
    function exists(string aName): bool
    {
        return this.Blocks.exists($name);
    }

    /**
     * Provides template or element extension/inheritance. Templates can : a
     * parent template and populate blocks in the parent template.
     *
     * @param string aName The template or element to "extend" the current one with.
     * @return this
     * @throws \LogicException when you extend a template with itself or make extend loops.
     * @throws \LogicException when you extend an element which doesn"t exist
     */
    function extend(string aName) {
        $type = $name[0] == "/" ? static::TYPE_TEMPLATE : _currentType;
        switch ($type) {
            case static::TYPE_ELEMENT:
                $parent = _getElementFileName($name);
                if (!$parent) {
                    [$plugin, $name] = this.pluginSplit($name);
                    $paths = _paths($plugin);
                    $defaultPath = $paths[0] . static::TYPE_ELEMENT . DIRECTORY_SEPARATOR;
                    throw new LogicException(sprintf(
                        "You cannot extend an element which does not exist (%s).",
                        $defaultPath . $name . _ext
                    ));
                }
                break;
            case static::TYPE_LAYOUT:
                $parent = _getLayoutFileName($name);
                break;
            default:
                $parent = _getTemplateFileName($name);
        }

        if ($parent == _current) {
            throw new LogicException("You cannot have templates extend themselves.");
        }
        if (isset(_parents[$parent]) && _parents[$parent] == _current) {
            throw new LogicException("You cannot have templates extend in a loop.");
        }
        _parents[_current] = $parent;

        return this;
    }

    /**
     * Retrieve the current template type
     */
    string getCurrentType(): string
    {
        return _currentType;
    }

    /**
     * Magic accessor for helpers.
     *
     * @param string aName Name of the attribute to get.
     * @return uim.cake.View\Helper|null
     */
    function __get(string aName) {
        $registry = this.helpers();
        if (!isset($registry.{$name})) {
            return null;
        }

        this.{$name} = $registry.{$name};

        return $registry.{$name};
    }

    /**
     * Interact with the HelperRegistry to load all the helpers.
     *
     * @return this
     */
    function loadHelpers() {
        $registry = this.helpers();
        $helpers = $registry.normalizeArray(this.helpers);
        foreach ($helpers as $properties) {
            this.loadHelper($properties["class"], $properties["config"]);
        }

        return this;
    }

    /**
     * Renders and returns output for given template filename with its
     * array of data. Handles parent/extended templates.
     *
     * @param string $templateFile Filename of the template
     * @param array $data Data to include in rendered view. If empty the current
     *   View::$viewVars will be used.
     * @return string Rendered output
     * @throws \LogicException When a block is left open.
     * @triggers View.beforeRenderFile this, [$templateFile]
     * @triggers View.afterRenderFile this, [$templateFile, $content]
     */
    protected function _render(string $templateFile, array $data = []): string
    {
        if (empty($data)) {
            $data = this.viewVars;
        }
        _current = $templateFile;
        $initialBlocks = count(this.Blocks.unclosed());

        this.dispatchEvent("View.beforeRenderFile", [$templateFile]);

        $content = _evaluate($templateFile, $data);

        $afterEvent = this.dispatchEvent("View.afterRenderFile", [$templateFile, $content]);
        if ($afterEvent.getResult() != null) {
            $content = $afterEvent.getResult();
        }

        if (isset(_parents[$templateFile])) {
            _stack[] = this.fetch("content");
            this.assign("content", $content);

            $content = _render(_parents[$templateFile]);
            this.assign("content", array_pop(_stack));
        }

        $remainingBlocks = count(this.Blocks.unclosed());

        if ($initialBlocks != $remainingBlocks) {
            throw new LogicException(sprintf(
                "The "%s" block was left open. Blocks are not allowed to cross files.",
                (string)this.Blocks.active()
            ));
        }

        return $content;
    }

    /**
     * Sandbox method to evaluate a template / view script in.
     *
     * @param string $templateFile Filename of the template.
     * @param array $dataForView Data to include in rendered view.
     * @return string Rendered output
     */
    protected function _evaluate(string $templateFile, array $dataForView): string
    {
        extract($dataForView);

        $bufferLevel = ob_get_level();
        ob_start();

        try {
            // Avoiding $templateFile here due to collision with extract() vars.
            include func_get_arg(0);
        } catch (Throwable $exception) {
            while (ob_get_level() > $bufferLevel) {
                ob_end_clean();
            }

            throw $exception;
        }

        return ob_get_clean();
    }

    /**
     * Get the helper registry in use by this View class.
     *
     * @return uim.cake.View\HelperRegistry
     */
    function helpers(): HelperRegistry
    {
        if (_helpers == null) {
            _helpers = new HelperRegistry(this);
        }

        return _helpers;
    }

    /**
     * Loads a helper. Delegates to the `HelperRegistry::load()` to load the helper
     *
     * @param string aName Name of the helper to load.
     * @param array<string, mixed> $config Settings for the helper
     * @return uim.cake.View\Helper a constructed helper object.
     * @see uim.cake.View\HelperRegistry::load()
     */
    function loadHelper(string aName, array $config = []): Helper
    {
        [, $class] = pluginSplit($name);
        $helpers = this.helpers();

        return this.{$class} = $helpers.load($name, $config);
    }

    /**
     * Set sub-directory for this template files.
     *
     * @param string $subDir Sub-directory name.
     * @return this
     * @see uim.cake.View\View::$subDir

     */
    function setSubDir(string $subDir) {
        this.subDir = $subDir;

        return this;
    }

    /**
     * Get sub-directory for this template files.
     *
     * @return string
     * @see uim.cake.View\View::$subDir

     */
    function getSubDir(): string
    {
        return this.subDir;
    }

    /**
     * Returns the View"s controller name.
     *
     * @return string
     * @since 3.7.7
     */
    function getName(): string
    {
        return this.name;
    }

    /**
     * Returns the plugin name.
     *
     * @return string|null

     */
    function getPlugin(): ?string
    {
        return this.plugin;
    }

    /**
     * Sets the plugin name.
     *
     * @param string|null $name Plugin name.
     * @return this

     */
    function setPlugin(?string aName) {
        this.plugin = $name;

        return this;
    }

    /**
     * Set The cache configuration View will use to store cached elements
     *
     * @param string $elementCache Cache config name.
     * @return this
     * @see uim.cake.View\View::$elementCache

     */
    function setElementCache(string $elementCache) {
        this.elementCache = $elementCache;

        return this;
    }

    /**
     * Returns filename of given action"s template file as a string.
     * CamelCased action names will be under_scored by default.
     * This means that you can have LongActionNames that refer to
     * long_action_names.php templates. You can change the inflection rule by
     * overriding _inflectTemplateFileName.
     *
     * @param string|null $name Controller action to find template filename for
     * @return string Template filename
     * @throws uim.cake.View\exceptions.MissingTemplateException when a template file could not be found.
     * @throws \RuntimeException When template name not provided.
     */
    protected function _getTemplateFileName(?string aName = null): string
    {
        $templatePath = $subDir = "";

        if (this.templatePath) {
            $templatePath = this.templatePath . DIRECTORY_SEPARATOR;
        }
        if (this.subDir != "") {
            $subDir = this.subDir . DIRECTORY_SEPARATOR;
            // Check if templatePath already terminates with subDir
            if ($templatePath != $subDir && substr($templatePath, -strlen($subDir)) == $subDir) {
                $subDir = "";
            }
        }

        if ($name == null) {
            $name = this.template;
        }

        if (empty($name)) {
            throw new RuntimeException("Template name not provided");
        }

        [$plugin, $name] = this.pluginSplit($name);
        $name = str_replace("/", DIRECTORY_SEPARATOR, $name);

        if (strpos($name, DIRECTORY_SEPARATOR) == false && $name != "" && $name[0] != ".") {
            $name = $templatePath . $subDir . _inflectTemplateFileName($name);
        } elseif (strpos($name, DIRECTORY_SEPARATOR) != false) {
            if ($name[0] == DIRECTORY_SEPARATOR || $name[1] == ":") {
                $name = trim($name, DIRECTORY_SEPARATOR);
            } elseif (!$plugin || this.templatePath != this.name) {
                $name = $templatePath . $subDir . $name;
            } else {
                $name = $subDir . $name;
            }
        }

        $name .= _ext;
        $paths = _paths($plugin);
        foreach ($paths as $path) {
            if (is_file($path . $name)) {
                return _checkFilePath($path . $name, $path);
            }
        }

        throw new MissingTemplateException($name, $paths);
    }

    /**
     * Change the name of a view template file into underscored format.
     *
     * @param string aName Name of file which should be inflected.
     * @return string File name after conversion
     */
    protected function _inflectTemplateFileName(string aName): string
    {
        return Inflector::underscore($name);
    }

    /**
     * Check that a view file path does not go outside of the defined template paths.
     *
     * Only paths that contain `..` will be checked, as they are the ones most likely to
     * have the ability to resolve to files outside of the template paths.
     *
     * @param string $file The path to the template file.
     * @param string $path Base path that $file should be inside of.
     * @return string The file path
     * @throws \InvalidArgumentException
     */
    protected function _checkFilePath(string $file, string $path): string
    {
        if (strpos($file, "..") == false) {
            return $file;
        }
        $absolute = realpath($file);
        if (strpos($absolute, $path) != 0) {
            throw new InvalidArgumentException(sprintf(
                "Cannot use "%s" as a template, it is not within any view template path.",
                $file
            ));
        }

        return $absolute;
    }

    /**
     * Splits a dot syntax plugin name into its plugin and filename.
     * If $name does not have a dot, then index 0 will be null.
     * It checks if the plugin is loaded, else filename will stay unchanged for filenames containing dot
     *
     * @param string aName The name you want to plugin split.
     * @param bool $fallback If true uses the plugin set in the current Request when parsed plugin is not loaded
     * @return array Array with 2 indexes. 0: plugin name, 1: filename.
     * @psalm-return array{string|null, string}
     */
    function pluginSplit(string aName, bool $fallback = true): array
    {
        $plugin = null;
        [$first, $second] = pluginSplit($name);
        if ($first && Plugin::isLoaded($first)) {
            $name = $second;
            $plugin = $first;
        }
        if (isset(this.plugin) && !$plugin && $fallback) {
            $plugin = this.plugin;
        }

        return [$plugin, $name];
    }

    /**
     * Returns layout filename for this template as a string.
     *
     * @param string|null $name The name of the layout to find.
     * @return string Filename for layout file.
     * @throws uim.cake.View\exceptions.MissingLayoutException when a layout cannot be located
     * @throws \RuntimeException
     */
    protected function _getLayoutFileName(?string aName = null): string
    {
        if ($name == null) {
            if (empty(this.layout)) {
                throw new RuntimeException(
                    "View::$layout must be a non-empty string." .
                    "To disable layout rendering use method View::disableAutoLayout() instead."
                );
            }
            $name = this.layout;
        }
        [$plugin, $name] = this.pluginSplit($name);
        $name .= _ext;

        foreach (this.getLayoutPaths($plugin) as $path) {
            if (is_file($path . $name)) {
                return _checkFilePath($path . $name, $path);
            }
        }

        $paths = iterator_to_array(this.getLayoutPaths($plugin));
        throw new MissingLayoutException($name, $paths);
    }

    /**
     * Get an iterator for layout paths.
     *
     * @param string|null $plugin The plugin to fetch paths for.
     * @return \Generator
     */
    protected function getLayoutPaths(?string $plugin) {
        $subDir = "";
        if (this.layoutPath) {
            $subDir = this.layoutPath . DIRECTORY_SEPARATOR;
        }
        $layoutPaths = _getSubPaths(static::TYPE_LAYOUT . DIRECTORY_SEPARATOR . $subDir);

        foreach (_paths($plugin) as $path) {
            foreach ($layoutPaths as $layoutPath) {
                yield $path . $layoutPath;
            }
        }
    }

    /**
     * Finds an element filename, returns false on failure.
     *
     * @param string aName The name of the element to find.
     * @param bool $pluginCheck - if false will ignore the request"s plugin if parsed plugin is not loaded
     * @return string|false Either a string to the element filename or false when one can"t be found.
     */
    protected function _getElementFileName(string aName, bool $pluginCheck = true) {
        [$plugin, $name] = this.pluginSplit($name, $pluginCheck);

        $name .= _ext;
        foreach (this.getElementPaths($plugin) as $path) {
            if (is_file($path . $name)) {
                return $path . $name;
            }
        }

        return false;
    }

    /**
     * Get an iterator for element paths.
     *
     * @param string|null $plugin The plugin to fetch paths for.
     * @return \Generator
     */
    protected function getElementPaths(?string $plugin) {
        $elementPaths = _getSubPaths(static::TYPE_ELEMENT);
        foreach (_paths($plugin) as $path) {
            foreach ($elementPaths as $subdir) {
                yield $path . $subdir . DIRECTORY_SEPARATOR;
            }
        }
    }

    /**
     * Find all sub templates path, based on $basePath
     * If a prefix is defined in the current request, this method will prepend
     * the prefixed template path to the $basePath, cascading up in case the prefix
     * is nested.
     * This is essentially used to find prefixed template paths for elements
     * and layouts.
     *
     * @param string $basePath Base path on which to get the prefixed one.
     * @return array<string> Array with all the templates paths.
     */
    protected function _getSubPaths(string $basePath): array
    {
        $paths = [$basePath];
        if (this.request.getParam("prefix")) {
            $prefixPath = explode("/", this.request.getParam("prefix"));
            $path = "";
            foreach ($prefixPath as $prefixPart) {
                $path .= Inflector::camelize($prefixPart) . DIRECTORY_SEPARATOR;

                array_unshift(
                    $paths,
                    $path . $basePath
                );
            }
        }

        return $paths;
    }

    /**
     * Return all possible paths to find view files in order
     *
     * @param string|null $plugin Optional plugin name to scan for view files.
     * @param bool $cached Set to false to force a refresh of view paths. Default true.
     * @return array<string> paths
     */
    protected string[] _paths(?string $plugin = null, bool $cached = true): array
    {
        if ($cached == true) {
            if ($plugin == null && !empty(_paths)) {
                return _paths;
            }
            if ($plugin != null && isset(_pathsForPlugin[$plugin])) {
                return _pathsForPlugin[$plugin];
            }
        }
        $templatePaths = App::path(static::NAME_TEMPLATE);
        $pluginPaths = $themePaths = [];
        if (!empty($plugin)) {
            for ($i = 0, $count = count($templatePaths); $i < $count; $i++) {
                $pluginPaths[] = $templatePaths[$i]
                    . static::PLUGIN_TEMPLATE_FOLDER
                    . DIRECTORY_SEPARATOR
                    . $plugin
                    . DIRECTORY_SEPARATOR;
            }
            $pluginPaths[] = Plugin::templatePath($plugin);
        }

        if (!empty(this.theme)) {
            $themePaths[] = Plugin::templatePath(Inflector::camelize(this.theme));

            if ($plugin) {
                for ($i = 0, $count = count($themePaths); $i < $count; $i++) {
                    array_unshift(
                        $themePaths,
                        $themePaths[$i]
                            . static::PLUGIN_TEMPLATE_FOLDER
                            . DIRECTORY_SEPARATOR
                            . $plugin
                            . DIRECTORY_SEPARATOR
                    );
                }
            }
        }

        $paths = array_merge(
            $themePaths,
            $pluginPaths,
            $templatePaths,
            App::core("templates")
        );

        if ($plugin != null) {
            return _pathsForPlugin[$plugin] = $paths;
        }

        return _paths = $paths;
    }

    /**
     * Generate the cache configuration options for an element.
     *
     * @param string aName Element name
     * @param array $data Data
     * @param array<string, mixed> $options Element options
     * @return array Element Cache configuration.
     * @psalm-return array{key:string, config:string}
     */
    protected function _elementCache(string aName, array $data, array $options): array
    {
        if (isset($options["cache"]["key"], $options["cache"]["config"])) {
            /** @psalm-var array{key:string, config:string}*/
            $cache = $options["cache"];
            $cache["key"] = "element_" . $cache["key"];

            return $cache;
        }

        [$plugin, $name] = this.pluginSplit($name);

        $pluginKey = null;
        if ($plugin) {
            $pluginKey = str_replace("/", "_", Inflector::underscore($plugin));
        }
        $elementKey = str_replace(["\\", "/"], "_", $name);

        $cache = $options["cache"];
        unset($options["cache"]);
        $keys = array_merge(
            [$pluginKey, $elementKey],
            array_keys($options),
            array_keys($data)
        );
        $config = [
            "config": this.elementCache,
            "key": implode("_", $keys),
        ];
        if (is_array($cache)) {
            $config = $cache + $config;
        }
        $config["key"] = "element_" . $config["key"];

        return $config;
    }

    /**
     * Renders an element and fires the before and afterRender callbacks for it
     * and writes to the cache if a cache is used
     *
     * @param string $file Element file path
     * @param array $data Data to render
     * @param array<string, mixed> $options Element options
     * @return string
     * @triggers View.beforeRender this, [$file]
     * @triggers View.afterRender this, [$file, $element]
     */
    protected function _renderElement(string $file, array $data, array $options): string
    {
        $current = _current;
        $restore = _currentType;
        _currentType = static::TYPE_ELEMENT;

        if ($options["callbacks"]) {
            this.dispatchEvent("View.beforeRender", [$file]);
        }

        $element = _render($file, array_merge(this.viewVars, $data));

        if ($options["callbacks"]) {
            this.dispatchEvent("View.afterRender", [$file, $element]);
        }

        _currentType = $restore;
        _current = $current;

        return $element;
    }
}
