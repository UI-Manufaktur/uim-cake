module uim.cake.View;

import uim.cake.core.App;
import uim.cake.events\IEventManager;
import uim.cake.Http\Response;
import uim.cake.Http\ServerRequest;
import uim.cake.View\Exception\MissingViewException;
use Closure;
use Exception;
use JsonSerializable;
use PDO;
use RuntimeException;
use Serializable;

/**
 * Provides an API for iteratively building a view up.
 *
 * Once you have configured the view and established all the context
 * you can create a view instance with `build()`.
 */
class ViewBuilder : JsonSerializable, Serializable
{


    /**
     * The template file to render.
     *
     * @var string|null
     */
    protected $_template;

    /**
     * The plugin name to use.
     *
     * @var string|null
     */
    protected $_plugin;

    /**
     * The theme name to use.
     *
     * @var string|null
     */
    protected $_theme;

    /**
     * The layout name to render.
     *
     * @var string|null
     */
    protected $_layout;

    /**
     * Whether autoLayout should be enabled.
     *
     * @var bool
     */
    protected $_autoLayout = true;



    /**
     * The view variables to use
     *
     * @var string|null
     */
    protected $_name;

    /**
     * The view class name to use.
     * Can either use plugin notation, a short name
     * or a fully moduled classname.
     *
     * @var string|null
     * @psalm-var class-string<\Cake\View\View>|string|null
     */
    protected $_className;

    /**
     * Additional options used when constructing the view.
     *
     * These options array lets you provide custom constructor
     * arguments to application/plugin view classes.
     *
     * @var array<string, mixed>
     */
    protected $_options = [];

    /**
     * The helpers to use
     *
     * @var array
     */
    protected $_helpers = [];

    /**
     * View vars
     *
     * @var array<string, mixed>
     */
    protected $_vars = [];

    /**
     * Saves a variable for use inside a template.
     *
     * @param string myName A string or an array of data.
     * @param mixed myValue Value.
     * @return this
     */
    auto setVar(string myName, myValue = null) {
        this._vars[myName] = myValue;

        return this;
    }

    /**
     * Saves view vars for use inside templates.
     *
     * @param array<string, mixed> myData Array of data.
     * @param bool myMerge Whether to merge with existing vars, default true.
     * @return this
     */
    auto setVars(array myData, bool myMerge = true) {
        if (myMerge) {
            this._vars = myData + this._vars;
        } else {
            this._vars = myData;
        }

        return this;
    }

    /**
     * Check if view var is set.
     *
     * @param string myName Var name
     * @return bool
     */
    function hasVar(string myName): bool
    {
        return array_key_exists(myName, this._vars);
    }

    /**
     * Get view var
     *
     * @param string myName Var name
     * @return mixed The var value or null if unset.
     */
    auto getVar(string myName) {
        return this._vars[myName] ?? null;
    }

    /**
     * Get all view vars.
     *
     * @return array<string, mixed>
     */
    auto getVars(): array
    {
        return this._vars;
    }

    // The subdirectory to the template.
    mixin(OProperty!("string", "templatePath"));

    // The layout path to build the view with.
    mixin(OProperty!("string", "layoutPath"));

    /**
     * Turns on or off CakePHP's conventional mode of applying layout files.
     * On by default. Setting to off means that layouts will not be
     * automatically applied to rendered views.
     *
     * @param bool myEnable Boolean to turn on/off.
     * @return this
     */
    O enableAutoLayout(this O)(bool myEnable = true) {
        this._autoLayout = myEnable;

        return cast(O)this;
    }

    /**
     * Turns off CakePHP's conventional mode of applying layout files.
     *
     * Setting to off means that layouts will not be automatically applied to
     * rendered views.
     *
     * @return this
     */
    function disableAutoLayout() {
        this._autoLayout = false;

        return this;
    }

    /**
     * Returns if CakePHP's conventional mode of applying layout files is enabled.
     * Disabled means that layouts will not be automatically applied to rendered views.
     *
     * @return bool
     */
    function isAutoLayoutEnabled(): bool
    {
        return this._autoLayout;
    }

    /**
     * Sets the plugin name to use.
     *
     * @param string|null myName Plugin name.
     *   Use null to remove the current plugin name.
     * @return this
     */
    auto setPlugin(?string myName) {
        this._plugin = myName;

        return this;
    }

    /**
     * Gets the plugin name to use.
     *
     * @return string|null
     */
    auto getPlugin(): ?string
    {
        return this._plugin;
    }

    /**
     * Adds a helper to use.
     *
     * @param string $helper Helper to use.
     * @param array<string, mixed> myOptions Options.
     * @return this
     * @since 4.1.0
     */
    function addHelper(string $helper, array myOptions = []) {
        if (myOptions) {
            $array = [$helper => myOptions];
        } else {
            $array = [$helper];
        }

        this._helpers = array_merge(this._helpers, $array);

        return this;
    }

    /**
     * Adds helpers to use by merging with existing ones.
     *
     * @param array $helpers Helpers to use.
     * @return this
     * @since 4.3.0
     */
    function addHelpers(array $helpers) {
        foreach ($helpers as $helper => myConfig) {
            if (is_int($helper)) {
                $helper = myConfig;
                myConfig = [];
            }
            this.addHelper($helper, myConfig);
        }

        return this;
    }

    /**
     * Sets the helpers to use.
     *
     * @param array $helpers Helpers to use.
     * @param bool myMerge Whether to merge existing data with the new data.
     * @return this
     */
    auto setHelpers(array $helpers, bool myMerge = true) {
        if (myMerge) {
            deprecationWarning('The myMerge param is deprecated, use addHelper()/addHelpers() instead.');
            $helpers = array_merge(this._helpers, $helpers);
        }
        this._helpers = $helpers;

        return this;
    }

    /**
     * Gets the helpers to use.
     *
     * @return array
     */
    auto getHelpers(): array
    {
        return this._helpers;
    }

    /**
     * Sets the view theme to use.
     *
     * @param string|null $theme Theme name.
     *   Use null to remove the current theme.
     * @return this
     */
    auto setTheme(?string $theme) {
        this._theme = $theme;

        return this;
    }

    /**
     * Gets the view theme to use.
     *
     * @return string|null
     */
    auto getTheme(): ?string
    {
        return this._theme;
    }

    /**
     * Sets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @param string|null myName View file name to set, or null to remove the template name.
     * @return this
     */
    auto setTemplate(?string myName) {
        this._template = myName;

        return this;
    }

    /**
     * Gets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @return string|null
     */
    auto getTemplate(): ?string
    {
        return this._template;
    }

    /**
     * Sets the name of the layout file to render the view inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @param string|null myName Layout file name to set.
     * @return this
     */
    auto setLayout(?string myName) {
        this._layout = myName;

        return this;
    }

    /**
     * Gets the name of the layout file to render the view inside of.
     *
     * @return string|null
     */
    auto getLayout(): ?string
    {
        return this._layout;
    }

    /**
     * Get view option.
     *
     * @param string myName The name of the option.
     * @return mixed
     */
    auto getOption(string myName) {
        return this._options[myName] ?? null;
    }

    /**
     * Set view option.
     *
     * @param string myName The name of the option.
     * @param mixed myValue Value to set.
     * @return this
     */
    auto setOption(string myName, myValue) {
        this._options[myName] = myValue;

        return this;
    }

    /**
     * Sets additional options for the view.
     *
     * This lets you provide custom constructor arguments to application/plugin view classes.
     *
     * @param array<string, mixed> myOptions An array of options.
     * @param bool myMerge Whether to merge existing data with the new data.
     * @return this
     */
    auto setOptions(array myOptions, bool myMerge = true) {
        if (myMerge) {
            myOptions = array_merge(this._options, myOptions);
        }
        this._options = myOptions;

        return this;
    }

    /**
     * Gets additional options for the view.
     *
     * @return array<string, mixed>
     */
    auto getOptions(): array
    {
        return this._options;
    }

    /**
     * Sets the view name.
     *
     * @param string|null myName The name of the view, or null to remove the current name.
     * @return this
     */
    auto setName(?string myName) {
        this._name = myName;

        return this;
    }

    /**
     * Gets the view name.
     *
     * @return string|null
     */
    auto getName(): ?string
    {
        return this._name;
    }

    /**
     * Sets the view classname.
     *
     * Accepts either a short name (Ajax) a plugin name (MyPlugin.Ajax)
     * or a fully moduled name (App\View\AppView) or null to use the
     * View class provided by CakePHP.
     *
     * @param string|null myName The class name for the view.
     * @return this
     */
    auto setClassName(?string myName) {
        this._className = myName;

        return this;
    }

    /**
     * Gets the view classname.
     *
     * @return string|null
     */
    auto getClassName(): ?string
    {
        return this._className;
    }

    /**
     * Using the data in the builder, create a view instance.
     *
     * If className() is null, App\View\AppView will be used.
     * If that class does not exist, then {@link \Cake\View\View} will be used.
     *
     * @param array<string, mixed> $vars The view variables/context to use.
     * @param \Cake\Http\ServerRequest|null myRequest The request to use.
     * @param \Cake\Http\Response|null $response The response to use.
     * @param \Cake\Event\IEventManager|null myEvents The event manager to use.
     * @return \Cake\View\View
     * @throws \Cake\View\Exception\MissingViewException
     */
    function build(
        array $vars = [],
        ?ServerRequest myRequest = null,
        ?Response $response = null,
        ?IEventManager myEvents = null
    ): View {
        myClassName = this._className;
        if (myClassName === null) {
            myClassName = App::className('App', 'View', 'View') ?? View::class;
        } elseif (myClassName === 'View') {
            myClassName = App::className(myClassName, 'View');
        } else {
            myClassName = App::className(myClassName, 'View', 'View');
        }
        if (myClassName === null) {
            throw new MissingViewException(['class' => this._className]);
        }

        if (!empty($vars)) {
            deprecationWarning(
                'The $vars argument is deprecated. Use the setVar()/setVars() methods instead.'
            );
        }

        myData = [
            'name' => this._name,
            'templatePath' => this._templatePath,
            'template' => this._template,
            'plugin' => this._plugin,
            'theme' => this._theme,
            'layout' => this._layout,
            'autoLayout' => this._autoLayout,
            'layoutPath' => this._layoutPath,
            'helpers' => this._helpers,
            'viewVars' => $vars + this._vars,
        ];
        myData += this._options;

        /** @var \Cake\View\View */
        return new myClassName(myRequest, $response, myEvents, myData);
    }

    /**
     * Serializes the view builder object to a value that can be natively
     * serialized and re-used to clone this builder instance.
     *
     * There are  limitations for viewVars that are good to know:
     *
     * - ORM\Query executed and stored as resultset
     * - SimpleXMLElements stored as associative array
     * - Exceptions stored as strings
     * - Resources, \Closure and \PDO are not supported.
     *
     * @return array Serializable array of configuration properties.
     */
    function jsonSerialize(): array
    {
        $properties = [
            '_templatePath', '_template', '_plugin', '_theme', '_layout', '_autoLayout',
            '_layoutPath', '_name', '_className', '_options', '_helpers', '_vars',
        ];

        $array = [];

        foreach ($properties as $property) {
            $array[$property] = this.{$property};
        }

        array_walk_recursive($array['_vars'], [this, '_checkViewVars']);

        return array_filter($array, function ($i) {
            return !is_array($i) && strlen((string)$i) || !empty($i);
        });
    }

    /**
     * Iterates through hash to clean up and normalize.
     *
     * @param mixed $item Reference to the view var value.
     * @param string myKey View var key.
     * @return void
     * @throws \RuntimeException
     */
    protected auto _checkViewVars(&$item, string myKey): void
    {
        if ($item instanceof Exception) {
            $item = (string)$item;
        }

        if (
            is_resource($item) ||
            $item instanceof Closure ||
            $item instanceof PDO
        ) {
            throw new RuntimeException(sprintf(
                'Failed serializing the `%s` %s in the `%s` view var',
                is_resource($item) ? get_resource_type($item) : get_class($item),
                is_resource($item) ? 'resource' : 'object',
                myKey
            ));
        }
    }

    /**
     * Configures a view builder instance from serialized config.
     *
     * @param array<string, mixed> myConfig View builder configuration array.
     * @return this
     */
    function createFromArray(array myConfig) {
        foreach (myConfig as $property => myValue) {
            this.{$property} = myValue;
        }

        return this;
    }

    /**
     * Serializes the view builder object.
     *
     * @return string
     */
    function serialize(): string
    {
        $array = this.jsonSerialize();

        return serialize($array);
    }

    /**
     * Magic method used for serializing the view builder object.
     *
     * @return array
     */
    auto __serialize(): array
    {
        return this.jsonSerialize();
    }

    /**
     * Unserializes the view builder object.
     *
     * @param string myData Serialized string.
     * @return void
     */
    function unserialize(myData): void
    {
        this.createFromArray(unserialize(myData));
    }

    /**
     * Magic method used to rebuild the view builder object.
     *
     * @param array<string, mixed> myData Data array.
     * @return void
     */
    auto __unserialize(array myData): void
    {
        this.createFromArray(myData);
    }
}
