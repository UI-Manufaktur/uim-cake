module uim.cake.views;

@safe:
import uim.cake;

/**
 * View, the V in the MVC triad. View interacts with Helpers and view variables passed
 * in from the controller to render the results of the controller action. Often this is HTML,
 * but can also take the form of JSON, XML, PDF"s or streaming files.
 *
 * UIM uses a two-step-view pattern. This means that the template content is rendered first,
 * and then inserted into the selected layout. This also means you can pass data from the template to the
 * layout using `this.set()`
 *
 * View class supports using plugins as themes. You can set
 *
 * ```
 * function beforeRender(\Cake\Event\IEvent myEvent)
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
 * @property \Cake\View\Helper\BreadcrumbsHelper $Breadcrumbs
 * @property \Cake\View\Helper\FlashHelper $Flash
 * @property \Cake\View\Helper\FormHelper $Form
 * @property \Cake\View\Helper\HtmlHelper $Html
 * @property \Cake\View\Helper\NumberHelper $Number
 * @property \Cake\View\Helper\PaginatorHelper $Paginator
 * @property \Cake\View\Helper\TextHelper $Text
 * @property \Cake\View\Helper\TimeHelper $Time
 * @property \Cake\View\Helper\UrlHelper myUrl
 * @property \Cake\View\ViewBlock $Blocks
 */
class View : IEventDispatcher {
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
     * @var \Cake\View\HelperRegistry
     */
    protected _helpers;

    /**
     * ViewBlock instance.
     *
     * @var \Cake\View\ViewBlock
     */
    protected Blocks;

    /**
     * The name of the plugin.
     *
     * @var string|null
     */
    protected myPlugin;

    // Name of the controller that created the View if any.
    protected string myName = "";

    /**
     * An array of names of built-in helpers to include.
     *
     * @var array
     */
    protected helpers = [];


    /**
     * The name of the template file to render. The name specified
     * is the filename in `templates/<SubFolder>/` without the .php extension.
     */
    protected string myTemplate = "";

    /**
     * The name of the layout file to render the template inside of. The name specified
     * is the filename of the layout in `templates/layout/` without the .php
     * extension.
     */
    protected string layout = "default";

    /**
     * Turns on or off UIM"s conventional mode of applying layout files. On by default.
     * Setting to off means that layouts will not be automatically applied to rendered templates.
     *
     * @var bool
     */
    protected autoLayout = true;

    /**
     * An array of variables
     *
     * @var array<string, mixed>
     */
    protected viewVars = [];

    /**
     * File extension. Defaults to ".php".
     */
    protected string _ext = ".php";

    /**
     * Sub-directory for this template file. This is often used for extension based routing.
     * Eg. With an `xml` extension, $subDir would be `xml/`
     */
    protected string subDir = "";

    /**
     * The view theme to use.
     *
     * @var string|null
     */
    protected theme;

    /**
     * An instance of a \Cake\Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var \Cake\Http\ServerRequest
     */
    protected myRequest;

    /**
     * The Cache configuration View will use to store cached elements. Changing this will change
     * the default configuration elements are stored under. You can also choose a cache config
     * per element.
     *
     * @var string
     * @see \Cake\View\View::element()
     */
    protected elementCache = "default";

    /**
     * List of variables to collect from the associated controller.
     *
     * @var array<string>
     */
    protected _passedVars = [
        "viewVars", "autoLayout", "helpers", "template", "layout", "name", "theme",
        "layoutPath", "templatePath", "plugin",
    ];

    /**
     * Default custom config options.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [];

    /**
     * Holds an array of paths.
     *
     * @var array<string>
     */
    protected _paths = [];

    /**
     * Holds an array of plugin paths.
     *
     * @var array<string[]>
     */
    protected _pathsForPlugin = [];

    /**
     * The names of views and their parents used with View::extend();
     *
     * @var array<string>
     */
    protected _parents = [];

    /**
     * The currently rendering view file. Used for resolving parent files.
     */
    protected string _current;

    /**
     * Currently rendering an element. Used for finding parent fragments
     * for elements.
     */
    protected string _currentType = "";

    /**
     * Content stack, used for nested templates that all use View::extend();
     *
     * @var array<string>
     */
    protected _stack = [];

    /**
     * ViewBlock class.
     *
     * @var string
     * @psalm-var class-string<\Cake\View\ViewBlock>
     */
    protected _viewBlockClass = ViewBlock::class;

    /**
     * Constant for view file type "template".
     */
    public const string TYPE_TEMPLATE = "template";

    /**
     * Constant for view file type "element"
     */
    public const string TYPE_ELEMENT = "element";

    /**
     * Constant for view file type "layout"
     */
    public const string TYPE_LAYOUT = "layout";

    /**
     * Constant for type used for App::path().
     */
    public const string NAME_TEMPLATE = "templates";

    /**
     * Constant for folder name containing files for overriding plugin templates.
     */
    public const string PLUGIN_TEMPLATE_FOLDER = "plugin";

    /**
     * Constructor
     *
     * @param \Cake\Http\ServerRequest|null myRequest Request instance.
     * @param \Cake\Http\Response|null $response Response instance.
     * @param \Cake\Event\EventManager|null myEventManager Event manager instance.
     * @param array<string, mixed> $viewOptions View options. See {@link View::$_passedVars} for list of
     *   options which get set as class properties.
     */
    this(
        ?ServerRequest myRequest = null,
        ?Response $response = null,
        ?EventManager myEventManager = null,
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

        if (myEventManager  !is null) {
            this.setEventManager(myEventManager);
        }
        if (myRequest is null) {
            myRequest = Router::getRequest() ?: new ServerRequest(["base" => "", "url" => "", "webroot" => "/"]);
        }
        this.request = myRequest;
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
     *
     * @return void
     */
    void initialize() {
    }

    /**
     * Gets the request instance.
     *
     * @return \Cake\Http\ServerRequest

     */
    auto getRequest(): ServerRequest
    {
        return this.request;
    }

    /**
     * Sets the request objects and configures a number of controller properties
     * based on the contents of the request. The properties that get set are:
     *
     * - this.request - To the myRequest parameter
     * - this.plugin - To the value returned by myRequest.getParam("plugin")
     *
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     * @return this
     */
    auto setRequest(ServerRequest myRequest) {
        this.request = myRequest;
        this.plugin = myRequest.getParam("plugin");

        return this;
    }

    // Reference to the Response object
    mixin(OProperty!("Response", "response");

    // The name of the subfolder containing templates for this view.
    mixin(OProperty!("string", "templatePath");

    // The name of the layouts subfolder containing layouts for this View.
    mixin(OProperty!("string", "layoutPath");
    
    /**
     * Returns if UIM"s conventional mode of applying layout files is enabled.
     * Disabled means that layouts will not be automatically applied to rendered views.
     *
     * @return bool
     */
    bool isAutoLayoutEnabled() {
        return this.autoLayout;
    }

    /**
     * Turns on or off UIM"s conventional mode of applying layout files.
     * On by default. Setting to off means that layouts will not be
     * automatically applied to rendered views.
     *
     * @param bool myEnable Boolean to turn on/off.
     * @return this
     */
    function enableAutoLayout(bool myEnable = true) {
        this.autoLayout = myEnable;

        return this;
    }

    /**
     * Turns off UIM"s conventional mode of applying layout files.
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
    Nullable!string getTheme() {
        return this.theme;
    }

    /**
     * Set the view theme to use.
     *
     * @param string|null $theme Theme name.
     * @return this
     */
    auto setTheme(Nullable!string theme) {
        this.theme = $theme;

        return this;
    }

    /**
     * Get the name of the template file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @return string
     */
    string getTemplate() {
        return this.template;
    }

    /**
     * Set the name of the template file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @param string myName Template file name to set.
     * @return this
     */
    auto setTemplate(string myName) {
        this.template = myName;

        return this;
    }

    /**
     * Get the name of the layout file to render the template inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @return string
     */
    string getLayout() {
        return this.layout;
    }

    /**
     * Set the name of the layout file to render the template inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @param string myName Layout file name to set.
     * @return this
     */
    auto setLayout(string myName) {
        this.layout = myName;

        return this;
    }

    /**
     * Get config value.
     *
     * Currently if config is not set it fallbacks to checking corresponding
     * view var with underscore prefix. Using underscore prefixed special view
     * vars is deprecated and this fallback will be removed in UIM 4.1.0.
     *
     * @param string|null myKey The key to get or null for the whole config.
     * @param mixed $default The return value when the key does not exist.
     * @return mixed Config value being read.
     * @psalm-suppress PossiblyNullArgument
     */
    auto getConfig(Nullable!string myKey = null, $default = null) {
        myValue = _getConfig(myKey);

        if (myValue  !is null) {
            return myValue;
        }

        if (isset(this.viewVars["_{myKey}"])) {
            deprecationWarning(sprintf(
                "Setting special view var "_%s" is deprecated. Use ViewBuilder::setOption(\"%s\", myValue) instead.",
                myKey,
                myKey
            ));

            return this.viewVars["_{myKey}"];
        }

        return $default;
    }

    /**
     * Renders a piece of PHP with provided parameters and returns HTML, XML, or any other string.
     *
     * This realizes the concept of Elements, (or "partial layouts") and the myParams array is used to send
     * data to be used in the element. Elements can be cached improving performance by using the `cache` option.
     *
     * @param string myName Name of template file in the `templates/element/` folder,
     *   or `MyPlugin.template` to use the template element from MyPlugin. If the element
     *   is not found in the plugin, the normal view path cascade will be searched.
     * @param array myData Array of data to be made available to the rendered view (i.e. the Element)
     * @param array<string, mixed> myOptions Array of options. Possible keys are:
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
     * @throws \Cake\View\Exception\MissingElementException When an element is missing and `ignoreMissing`
     *   is false.
     * @psalm-param array{cache?:array|true, callbacks?:bool, plugin?:string|false, ignoreMissing?:bool} myOptions
     */
    string element(string myName, array myData = [], array myOptions = []) {
        myOptions += ["callbacks" => false, "cache" => null, "plugin" => null, "ignoreMissing" => false];
        if (isset(myOptions["cache"])) {
            myOptions["cache"] = _elementCache(
                myName,
                myData,
                array_diff_key(myOptions, ["callbacks" => false, "plugin" => null, "ignoreMissing" => null])
            );
        }

        myPluginCheck = myOptions["plugin"] != false;
        myfile = _getElementFileName(myName, myPluginCheck);
        if (myfile && myOptions["cache"]) {
            return this.cache(void () use (myfile, myData, myOptions) {
                echo _renderElement(myfile, myData, myOptions);
            }, myOptions["cache"]);
        }
        if (myfile) {
            return _renderElement(myfile, myData, myOptions);
        }

        if (myOptions["ignoreMissing"]) {
            return "";
        }

        [myPlugin, $elementName] = this.pluginSplit(myName, myPluginCheck);
        myPaths = iterator_to_array(this.getElementPaths(myPlugin));
        throw new MissingElementException([myName . _ext, $elementName . _ext], myPaths);
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
     * @param array<string, mixed> myOptions The options defining the cache key etc.
     * @return string The rendered content.
     * @throws \RuntimeException When myOptions is lacking a "key" option.
     */
    string cache(callable $block, array myOptions = []) {
        myOptions += ["key" => "", "config" => this.elementCache];
        if (empty(myOptions["key"])) {
            throw new RuntimeException("Cannot cache content with an empty key");
        }
        myResult = Cache::read(myOptions["key"], myOptions["config"]);
        if (myResult) {
            return myResult;
        }

        $bufferLevel = ob_get_level();
        ob_start();

        try {
            $block();
        } catch (Throwable myException) {
            while (ob_get_level() > $bufferLevel) {
                ob_end_clean();
            }

            throw myException;
        }

        myResult = ob_get_clean();

        Cache::write(myOptions["key"], myResult, myOptions["config"]);

        return myResult;
    }

    /**
     * Checks if an element exists
     *
     * @param string myName Name of template file in the `templates/element/` folder,
     *   or `MyPlugin.template` to check the template element from MyPlugin. If the element
     *   is not found in the plugin, the normal view path cascade will be searched.
     * @return bool Success
     */
    bool elementExists(string myName) {
        return (bool)_getElementFileName(myName);
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
     * @param string|null myTemplate Name of template file to use
     * @param string|false|null $layout Layout to use. False to disable.
     * @return string Rendered content.
     * @throws \Cake\Core\Exception\CakeException If there is an error in the view.
     * @triggers View.beforeRender this, [myTemplateFileName]
     * @triggers View.afterRender this, [myTemplateFileName]
     */
    string render(Nullable!string myTemplate = null, $layout = null) {
        $defaultLayout = "";
        $defaultAutoLayout = null;
        if ($layout == false) {
            $defaultAutoLayout = this.autoLayout;
            this.autoLayout = false;
        } elseif ($layout  !is null) {
            $defaultLayout = this.layout;
            this.layout = $layout;
        }

        myTemplateFileName = _getTemplateFileName(myTemplate);
        _currentType = static::TYPE_TEMPLATE;
        this.dispatchEvent("View.beforeRender", [myTemplateFileName]);
        this.Blocks.set("content", _render(myTemplateFileName));
        this.dispatchEvent("View.afterRender", [myTemplateFileName]);

        if (this.autoLayout) {
            if (empty(this.layout)) {
                throw new RuntimeException(
                    "View::$layout must be a non-empty string." .
                    "To disable layout rendering use method View::disableAutoLayout() instead."
                );
            }

            this.Blocks.set("content", this.renderLayout("", this.layout));
        }
        if ($layout  !is null) {
            this.layout = $defaultLayout;
        }
        if ($defaultAutoLayout  !is null) {
            this.autoLayout = $defaultAutoLayout;
        }

        return this.Blocks.get("content");
    }

    /**
     * Renders a layout. Returns output from _render().
     *
     * Several variables are created for use in layout.
     *
     * @param string myContents Content to render in a template, wrapped by the surrounding layout.
     * @param string|null $layout Layout name
     * @return string Rendered output.
     * @throws \Cake\Core\Exception\CakeException if there is an error in the view.
     * @triggers View.beforeLayout this, [$layoutFileName]
     * @triggers View.afterLayout this, [$layoutFileName]
     */
    string renderLayout(string myContents, Nullable!string layout = null) {
        $layoutFileName = _getLayoutFileName($layout);

        if (!empty(myContents)) {
            this.Blocks.set("content", myContents);
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
     * @return Array of the set view variable names.
     */
    string[] getVars() {
        return array_keys(this.viewVars);
    }

    /**
     * Returns the contents of the given View variable.
     *
     * @param string var The view var you want the contents of.
     * @param mixed $default The default/fallback content of $var.
     * @return mixed The content of the named var if its set, otherwise $default.
     */
    auto get(string var, $default = null) {
        return this.viewVars[$var] ?? $default;
    }

    /**
     * Saves a variable or an associative array of variables for use inside a template.
     *
     * @param array|string myName A string or an array of data.
     * @param mixed myValue Value in case myName is a string (which then works as the key).
     *   Unused if myName is an associative array, otherwise serves as the values to myName"s keys.
     * @return this
     * @throws \RuntimeException If the array combine operation failed.
     */
    auto set(myName, myValue = null) {
        if (is_array(myName)) {
            if (is_array(myValue)) {
                /** @var array|false myData */
                myData = array_combine(myName, myValue);
                if (myData == false) {
                    throw new RuntimeException(
                        "Invalid data provided for array_combine() to work: Both myName and myValue require same count."
                    );
                }
            } else {
                myData = myName;
            }
        } else {
            myData = [myName => myValue];
        }
        this.viewVars = myData + this.viewVars;

        return this;
    }

    /**
     * Get the names of all the existing blocks.
     *
     * @return An array containing the blocks.
     * @see \Cake\View\ViewBlock::keys()
     */
    string[] blocks() {
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
     * @param string myName The name of the block to capture for.
     * @return this
     * @see \Cake\View\ViewBlock::start()
     */
    function start(string myName) {
        this.Blocks.start(myName);

        return this;
    }

    /**
     * Append to an existing or new block.
     *
     * Appending to a new block will create the block.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see \Cake\View\ViewBlock::concat()
     */
    function append(string myName, myValue = null) {
        this.Blocks.concat(myName, myValue);

        return this;
    }

    /**
     * Prepend to an existing or new block.
     *
     * Prepending to a new block will create the block.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see \Cake\View\ViewBlock::concat()
     */
    function prepend(string myName, myValue) {
        this.Blocks.concat(myName, myValue, ViewBlock::PREPEND);

        return this;
    }

    /**
     * Set the content for a block. This will overwrite any
     * existing content.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @return this
     * @see \Cake\View\ViewBlock::set()
     */
    function assign(string myName, myValue) {
        this.Blocks.set(myName, myValue);

        return this;
    }

    /**
     * Reset the content for a block. This will overwrite any
     * existing content.
     *
     * @param string myName Name of the block
     * @return this
     * @see \Cake\View\ViewBlock::set()
     */
    function reset(string myName) {
        this.assign(myName, "");

        return this;
    }

    /**
     * Fetch the content for a block. If a block is
     * empty or undefined "" will be returned.
     *
     * @param string myName Name of the block
     * @param string default Default text
     * @return string The block content or $default if the block does not exist.
     * @see \Cake\View\ViewBlock::get()
     */
    string fetch(string myName, string default = "") {
        return this.Blocks.get(myName, $default);
    }

    /**
     * End a capturing block. The compliment to View::start()
     *
     * @return this
     * @see \Cake\View\ViewBlock::end()
     */
    function end() {
        this.Blocks.end();

        return this;
    }

    /**
     * Check if a block exists
     *
     * @param string myName Name of the block
     * @return bool
     */
    bool exists(string myName) {
        return this.Blocks.exists(myName);
    }

    /**
     * Provides template or element extension/inheritance. Templates can : a
     * parent template and populate blocks in the parent template.
     *
     * @param string myName The template or element to "extend" the current one with.
     * @return this
     * @throws \LogicException when you extend a template with itself or make extend loops.
     * @throws \LogicException when you extend an element which doesn"t exist
     */
    function extend(string myName) {
        myType = myName[0] == "/" ? static::TYPE_TEMPLATE : _currentType;
        switch (myType) {
            case static::TYPE_ELEMENT:
                $parent = _getElementFileName(myName);
                if (!$parent) {
                    [myPlugin, myName] = this.pluginSplit(myName);
                    myPaths = _paths(myPlugin);
                    $defaultPath = myPaths[0] . static::TYPE_ELEMENT . DIRECTORY_SEPARATOR;
                    throw new LogicException(sprintf(
                        "You cannot extend an element which does not exist (%s).",
                        $defaultPath . myName . _ext
                    ));
                }
                break;
            case static::TYPE_LAYOUT:
                $parent = _getLayoutFileName(myName);
                break;
            default:
                $parent = _getTemplateFileName(myName);
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
     *
     * @return string
     */
    string getCurrentType() {
        return _currentType;
    }

    /**
     * Magic accessor for helpers.
     *
     * @param string myName Name of the attribute to get.
     * @return \Cake\View\Helper|null
     */
    auto __get(string myName) {
        $registry = this.helpers();
        if (!isset($registry.{myName})) {
            return null;
        }

        this.{myName} = $registry.{myName};

        return $registry.{myName};
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
     * @param string myTemplateFile Filename of the template
     * @param array myData Data to include in rendered view. If empty the current
     *   View::$viewVars will be used.
     * @return string Rendered output
     * @throws \LogicException When a block is left open.
     * @triggers View.beforeRenderFile this, [myTemplateFile]
     * @triggers View.afterRenderFile this, [myTemplateFile, myContents]
     */
    protected string _render(string myTemplateFile, array myData = []) {
        if (empty(myData)) {
            myData = this.viewVars;
        }
        _current = myTemplateFile;
        $initialBlocks = count(this.Blocks.unclosed());

        this.dispatchEvent("View.beforeRenderFile", [myTemplateFile]);

        myContents = _evaluate(myTemplateFile, myData);

        $afterEvent = this.dispatchEvent("View.afterRenderFile", [myTemplateFile, myContents]);
        if ($afterEvent.getResult()  !is null) {
            myContents = $afterEvent.getResult();
        }

        if (isset(_parents[myTemplateFile])) {
            _stack[] = this.fetch("content");
            this.assign("content", myContents);

            myContents = _render(_parents[myTemplateFile]);
            this.assign("content", array_pop(_stack));
        }

        $remainingBlocks = count(this.Blocks.unclosed());

        if ($initialBlocks != $remainingBlocks) {
            throw new LogicException(sprintf(
                "The "%s" block was left open. Blocks are not allowed to cross files.",
                (string)this.Blocks.active()
            ));
        }

        return myContents;
    }

    /**
     * Sandbox method to evaluate a template / view script in.
     *
     * @param string myTemplateFile Filename of the template.
     * @param array myDataForView Data to include in rendered view.
     * @return string Rendered output
     */
    protected string _evaluate(string myTemplateFile, array myDataForView) {
        extract(myDataForView);

        $bufferLevel = ob_get_level();
        ob_start();

        try {
            // Avoiding myTemplateFile here due to collision with extract() vars.
            include func_get_arg(0);
        } catch (Throwable myException) {
            while (ob_get_level() > $bufferLevel) {
                ob_end_clean();
            }

            throw myException;
        }

        return ob_get_clean();
    }

    /**
     * Get the helper registry in use by this View class.
     *
     * @return \Cake\View\HelperRegistry
     */
    function helpers(): HelperRegistry
    {
        if (_helpers is null) {
            _helpers = new HelperRegistry(this);
        }

        return _helpers;
    }

    /**
     * Loads a helper. Delegates to the `HelperRegistry::load()` to load the helper
     *
     * @param string myName Name of the helper to load.
     * @param array<string, mixed> myConfig Settings for the helper
     * @return \Cake\View\Helper a constructed helper object.
     * @see \Cake\View\HelperRegistry::load()
     */
    Helper loadHelper(string myName, array myConfig = []) {
        [, myClass] = pluginSplit(myName);
        $helpers = this.helpers();

        return this.{myClass} = $helpers.load(myName, myConfig);
    }

    /**
     * Set sub-directory for this template files.
     *
     * @param string subDir Sub-directory name.
     * @return this
     * @see \Cake\View\View::$subDir

     */
    auto setSubDir(string subDir) {
        this.subDir = $subDir;

        return this;
    }

    /**
     * Get sub-directory for this template files.
     *
     * @return string
     * @see \Cake\View\View::$subDir

     */
    string getSubDir() {
        return this.subDir;
    }

    /**
     * Returns the View"s controller name.
     *
     * @return string
     * @since 3.7.7
     */
    string getName() {
        return this.name;
    }

    /**
     * Returns the plugin name.
     *
     * @return string|null

     */
    Nullable!string getPlugin() {
        return this.plugin;
    }

    /**
     * Sets the plugin name.
     *
     * @param string|null myName Plugin name.
     * @return this

     */
    auto setPlugin(Nullable!string myName) {
        this.plugin = myName;

        return this;
    }

    /**
     * Set The cache configuration View will use to store cached elements
     *
     * @param string elementCache Cache config name.
     * @return this
     * @see \Cake\View\View::$elementCache

     */
    auto setElementCache(string elementCache) {
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
     * @param string|null myName Controller action to find template filename for
     * @return string Template filename
     * @throws \Cake\View\Exception\MissingTemplateException when a template file could not be found.
     * @throws \RuntimeException When template name not provided.
     */
    protected string _getTemplateFileName(Nullable!string myName = null) {
        myTemplatePath = $subDir = "";

        if (this.templatePath) {
            myTemplatePath = this.templatePath . DIRECTORY_SEPARATOR;
        }
        if (this.subDir != "") {
            $subDir = this.subDir . DIRECTORY_SEPARATOR;
            // Check if templatePath already terminates with subDir
            if (myTemplatePath != $subDir && substr(myTemplatePath, -strlen($subDir)) == $subDir) {
                $subDir = "";
            }
        }

        if (myName is null) {
            myName = this.template;
        }

        if (empty(myName)) {
            throw new RuntimeException("Template name not provided");
        }

        [myPlugin, myName] = this.pluginSplit(myName);
        myName = str_replace("/", DIRECTORY_SEPARATOR, myName);

        if (indexOf(myName, DIRECTORY_SEPARATOR) == false && myName != "" && myName[0] != ".") {
            myName = myTemplatePath . $subDir . _inflectTemplateFileName(myName);
        } elseif (indexOf(myName, DIRECTORY_SEPARATOR) != false) {
            if (myName[0] == DIRECTORY_SEPARATOR || myName[1] == ":") {
                myName = trim(myName, DIRECTORY_SEPARATOR);
            } elseif (!myPlugin || this.templatePath != this.name) {
                myName = myTemplatePath . $subDir . myName;
            } else {
                myName = $subDir . myName;
            }
        }

        myName .= _ext;
        myPaths = _paths(myPlugin);
        foreach (myPaths as myPath) {
            if (is_file(myPath . myName)) {
                return _checkFilePath(myPath . myName, myPath);
            }
        }

        throw new MissingTemplateException(myName, myPaths);
    }

    /**
     * Change the name of a view template file into underscored format.
     *
     * @param string myName Name of file which should be inflected.
     * @return string File name after conversion
     */
    protected string _inflectTemplateFileName(string myName) {
        return Inflector::underscore(myName);
    }

    /**
     * Check that a view file path does not go outside of the defined template paths.
     *
     * Only paths that contain `..` will be checked, as they are the ones most likely to
     * have the ability to resolve to files outside of the template paths.
     *
     * @param string myfile The path to the template file.
     * @param string myPath Base path that myfile should be inside of.
     * @return string The file path
     * @throws \InvalidArgumentException
     */
    protected string _checkFilePath(string myfile, string myPath) {
        if (indexOf(myfile, "..") == false) {
            return myfile;
        }
        $absolute = realpath(myfile);
        if (indexOf($absolute, myPath) != 0) {
            throw new InvalidArgumentException(sprintf(
                "Cannot use "%s" as a template, it is not within any view template path.",
                myfile
            ));
        }

        return $absolute;
    }

    /**
     * Splits a dot syntax plugin name into its plugin and filename.
     * If myName does not have a dot, then index 0 will be null.
     * It checks if the plugin is loaded, else filename will stay unchanged for filenames containing dot
     *
     * @param string myName The name you want to plugin split.
     * @param bool $fallback If true uses the plugin set in the current Request when parsed plugin is not loaded
     * @return array Array with 2 indexes. 0 => plugin name, 1 => filename.
     * @psalm-return array{string|null, string}
     */
    function pluginSplit(string myName, bool $fallback = true): array
    {
        myPlugin = null;
        [$first, $second] = pluginSplit(myName);
        if ($first && Plugin::isLoaded($first)) {
            myName = $second;
            myPlugin = $first;
        }
        if (isset(this.plugin) && !myPlugin && $fallback) {
            myPlugin = this.plugin;
        }

        return [myPlugin, myName];
    }

    /**
     * Returns layout filename for this template as a string.
     *
     * @param string|null myName The name of the layout to find.
     * @return string Filename for layout file.
     * @throws \Cake\View\Exception\MissingLayoutException when a layout cannot be located
     * @throws \RuntimeException
     */
    protected string _getLayoutFileName(Nullable!string myName = null) {
        if (myName is null) {
            if (empty(this.layout)) {
                throw new RuntimeException(
                    "View::$layout must be a non-empty string." .
                    "To disable layout rendering use method View::disableAutoLayout() instead."
                );
            }
            myName = this.layout;
        }
        [myPlugin, myName] = this.pluginSplit(myName);
        myName .= _ext;

        foreach (this.getLayoutPaths(myPlugin) as myPath) {
            if (is_file(myPath . myName)) {
                return _checkFilePath(myPath . myName, myPath);
            }
        }

        myPaths = iterator_to_array(this.getLayoutPaths(myPlugin));
        throw new MissingLayoutException(myName, myPaths);
    }

    /**
     * Get an iterator for layout paths.
     *
     * @param string|null myPlugin The plugin to fetch paths for.
     * @return \Generator
     */
    protected auto getLayoutPaths(Nullable!string myPlugin) {
        $subDir = "";
        if (this.layoutPath) {
            $subDir = this.layoutPath . DIRECTORY_SEPARATOR;
        }
        $layoutPaths = _getSubPaths(static::TYPE_LAYOUT . DIRECTORY_SEPARATOR . $subDir);

        foreach (_paths(myPlugin) as myPath) {
            foreach ($layoutPaths as $layoutPath) {
                yield myPath . $layoutPath;
            }
        }
    }

    /**
     * Finds an element filename, returns false on failure.
     *
     * @param string myName The name of the element to find.
     * @param bool myPluginCheck - if false will ignore the request"s plugin if parsed plugin is not loaded
     * @return string|false Either a string to the element filename or false when one can"t be found.
     */
    protected auto _getElementFileName(string myName, bool myPluginCheck = true) {
        [myPlugin, myName] = this.pluginSplit(myName, myPluginCheck);

        myName .= _ext;
        foreach (this.getElementPaths(myPlugin) as myPath) {
            if (is_file(myPath . myName)) {
                return myPath . myName;
            }
        }

        return false;
    }

    /**
     * Get an iterator for element paths.
     *
     * @param string|null myPlugin The plugin to fetch paths for.
     * @return \Generator
     */
    protected auto getElementPaths(Nullable!string myPlugin) {
        $elementPaths = _getSubPaths(static::TYPE_ELEMENT);
        foreach (_paths(myPlugin) as myPath) {
            foreach ($elementPaths as $subdir) {
                yield myPath . $subdir . DIRECTORY_SEPARATOR;
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
     * @param string basePath Base path on which to get the prefixed one.
     * @return Array with all the templates paths.
     */
    protected string[] _getSubPaths(string basePath) {
        myPaths = [$basePath];
        if (this.request.getParam("prefix")) {
            $prefixPath = explode("/", this.request.getParam("prefix"));
            myPath = "";
            foreach ($prefixPath as $prefixPart) {
                myPath .= Inflector::camelize($prefixPart) . DIRECTORY_SEPARATOR;

                array_unshift(
                    myPaths,
                    myPath . $basePath
                );
            }
        }

        return myPaths;
    }

    /**
     * Return all possible paths to find view files in order
     *
     * @param string|null myPlugin Optional plugin name to scan for view files.
     * @param bool $cached Set to false to force a refresh of view paths. Default true.
     * @return paths
     */
    protected string[] _paths(Nullable!string myPlugin = null, bool $cached = true) {
        if ($cached == true) {
            if (myPlugin is null && !empty(_paths)) {
                return _paths;
            }
            if (myPlugin  !is null && isset(_pathsForPlugin[myPlugin])) {
                return _pathsForPlugin[myPlugin];
            }
        }
        myTemplatePaths = App::path(static::NAME_TEMPLATE);
        myPluginPaths = $themePaths = [];
        if (!empty(myPlugin)) {
            for ($i = 0, myCount = count(myTemplatePaths); $i < myCount; $i++) {
                myPluginPaths[] = myTemplatePaths[$i]
                    . static::PLUGIN_TEMPLATE_FOLDER
                    . DIRECTORY_SEPARATOR
                    . myPlugin
                    . DIRECTORY_SEPARATOR;
            }
            myPluginPaths[] = Plugin::templatePath(myPlugin);
        }

        if (!empty(this.theme)) {
            $themePaths[] = Plugin::templatePath(Inflector::camelize(this.theme));

            if (myPlugin) {
                for ($i = 0, myCount = count($themePaths); $i < myCount; $i++) {
                    array_unshift(
                        $themePaths,
                        $themePaths[$i]
                            . static::PLUGIN_TEMPLATE_FOLDER
                            . DIRECTORY_SEPARATOR
                            . myPlugin
                            . DIRECTORY_SEPARATOR
                    );
                }
            }
        }

        myPaths = array_merge(
            $themePaths,
            myPluginPaths,
            myTemplatePaths,
            App::core("templates")
        );

        if (myPlugin  !is null) {
            return _pathsForPlugin[myPlugin] = myPaths;
        }

        return _paths = myPaths;
    }

    /**
     * Generate the cache configuration options for an element.
     *
     * @param string myName Element name
     * @param array myData Data
     * @param array<string, mixed> myOptions Element options
     * @return array Element Cache configuration.
     * @psalm-return array{key:string, config:string}
     */
    protected auto _elementCache(string myName, array myData, array myOptions): array
    {
        if (isset(myOptions["cache"]["key"], myOptions["cache"]["config"])) {
            /** @psalm-var array{key:string, config:string}*/
            $cache = myOptions["cache"];
            $cache["key"] = "element_" . $cache["key"];

            return $cache;
        }

        [myPlugin, myName] = this.pluginSplit(myName);

        myPluginKey = null;
        if (myPlugin) {
            myPluginKey = str_replace("/", "_", Inflector::underscore(myPlugin));
        }
        $elementKey = str_replace(["\\", "/"], "_", myName);

        $cache = myOptions["cache"];
        unset(myOptions["cache"]);
        myKeys = array_merge(
            [myPluginKey, $elementKey],
            array_keys(myOptions),
            array_keys(myData)
        );
        myConfig = [
            "config" => this.elementCache,
            "key" => implode("_", myKeys),
        ];
        if (is_array($cache)) {
            myConfig = $cache + myConfig;
        }
        myConfig["key"] = "element_" . myConfig["key"];

        return myConfig;
    }

    /**
     * Renders an element and fires the before and afterRender callbacks for it
     * and writes to the cache if a cache is used
     *
     * @param string myfile Element file path
     * @param array myData Data to render
     * @param array<string, mixed> myOptions Element options
     * @return string
     * @triggers View.beforeRender this, [myfile]
     * @triggers View.afterRender this, [myfile, $element]
     */
    protected string _renderElement(string myfile, array myData, array myOptions) {
        $current = _current;
        $restore = _currentType;
        _currentType = static::TYPE_ELEMENT;

        if (myOptions["callbacks"]) {
            this.dispatchEvent("View.beforeRender", [myfile]);
        }

        $element = _render(myfile, array_merge(this.viewVars, myData));

        if (myOptions["callbacks"]) {
            this.dispatchEvent("View.afterRender", [myfile, $element]);
        }

        _currentType = $restore;
        _current = $current;

        return $element;
    }
}
