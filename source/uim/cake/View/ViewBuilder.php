
module uim.cake.View;

import uim.cake.core.App;
import uim.cake.events.IEventManager;
import uim.cake.http.Response;
import uim.cake.http.ServerRequest;
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
     * The subdirectory to the template.
     *
     * @var string|null
     */
    protected $_templatePath;

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
     * The layout path to build the view with.
     *
     * @var string|null
     */
    protected $_layoutPath;

    /**
     * The view variables to use
     *
     * @var string|null
     */
    protected $_name;

    /**
     * The view class name to use.
     * Can either use plugin notation, a short name
     * or a fully namespaced classname.
     *
     * @var string|null
     * @psalm-var class-string<uim.cake.View\View>|string|null
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
     * @param string $name A string or an array of data.
     * @param mixed $value Value.
     * @return this
     */
    function setVar(string $name, $value = null) {
        _vars[$name] = $value;

        return this;
    }

    /**
     * Saves view vars for use inside templates.
     *
     * @param array<string, mixed> $data Array of data.
     * @param bool $merge Whether to merge with existing vars, default true.
     * @return this
     */
    function setVars(array $data, bool $merge = true) {
        if ($merge) {
            _vars = $data + _vars;
        } else {
            _vars = $data;
        }

        return this;
    }

    /**
     * Check if view var is set.
     *
     * @param string $name Var name
     * @return bool
     */
    function hasVar(string $name): bool
    {
        return array_key_exists($name, _vars);
    }

    /**
     * Get view var
     *
     * @param string $name Var name
     * @return mixed The var value or null if unset.
     */
    function getVar(string $name) {
        return _vars[$name] ?? null;
    }

    /**
     * Get all view vars.
     *
     * @return array<string, mixed>
     */
    function getVars(): array
    {
        return _vars;
    }

    /**
     * Sets path for template files.
     *
     * @param string|null $path Path for view files.
     * @return this
     */
    function setTemplatePath(?string $path) {
        _templatePath = $path;

        return this;
    }

    /**
     * Gets path for template files.
     *
     * @return string|null
     */
    function getTemplatePath(): ?string
    {
        return _templatePath;
    }

    /**
     * Sets path for layout files.
     *
     * @param string|null $path Path for layout files.
     * @return this
     */
    function setLayoutPath(?string $path) {
        _layoutPath = $path;

        return this;
    }

    /**
     * Gets path for layout files.
     *
     * @return string|null
     */
    function getLayoutPath(): ?string
    {
        return _layoutPath;
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
        _autoLayout = $enable;

        return this;
    }

    /**
     * Turns off CakePHP"s conventional mode of applying layout files.
     *
     * Setting to off means that layouts will not be automatically applied to
     * rendered views.
     *
     * @return this
     */
    function disableAutoLayout() {
        _autoLayout = false;

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
        return _autoLayout;
    }

    /**
     * Sets the plugin name to use.
     *
     * @param string|null $name Plugin name.
     *   Use null to remove the current plugin name.
     * @return this
     */
    function setPlugin(?string $name) {
        _plugin = $name;

        return this;
    }

    /**
     * Gets the plugin name to use.
     *
     * @return string|null
     */
    function getPlugin(): ?string
    {
        return _plugin;
    }

    /**
     * Adds a helper to use.
     *
     * @param string $helper Helper to use.
     * @param array<string, mixed> $options Options.
     * @return this
     * @since 4.1.0
     */
    function addHelper(string $helper, array $options = []) {
        if ($options) {
            $array = [$helper: $options];
        } else {
            $array = [$helper];
        }

        _helpers = array_merge(_helpers, $array);

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
        foreach ($helpers as $helper: $config) {
            if (is_int($helper)) {
                $helper = $config;
                $config = [];
            }
            this.addHelper($helper, $config);
        }

        return this;
    }

    /**
     * Sets the helpers to use.
     *
     * @param array $helpers Helpers to use.
     * @param bool $merge Whether to merge existing data with the new data.
     * @return this
     */
    function setHelpers(array $helpers, bool $merge = true) {
        if ($merge) {
            deprecationWarning("The $merge param is deprecated, use addHelper()/addHelpers() instead.");
            $helpers = array_merge(_helpers, $helpers);
        }
        _helpers = $helpers;

        return this;
    }

    /**
     * Gets the helpers to use.
     *
     * @return array
     */
    function getHelpers(): array
    {
        return _helpers;
    }

    /**
     * Sets the view theme to use.
     *
     * @param string|null $theme Theme name.
     *   Use null to remove the current theme.
     * @return this
     */
    function setTheme(?string $theme) {
        _theme = $theme;

        return this;
    }

    /**
     * Gets the view theme to use.
     *
     * @return string|null
     */
    function getTheme(): ?string
    {
        return _theme;
    }

    /**
     * Sets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @param string|null $name View file name to set, or null to remove the template name.
     * @return this
     */
    function setTemplate(?string $name) {
        _template = $name;

        return this;
    }

    /**
     * Gets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @return string|null
     */
    function getTemplate(): ?string
    {
        return _template;
    }

    /**
     * Sets the name of the layout file to render the view inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @param string|null $name Layout file name to set.
     * @return this
     */
    function setLayout(?string $name) {
        _layout = $name;

        return this;
    }

    /**
     * Gets the name of the layout file to render the view inside of.
     *
     * @return string|null
     */
    function getLayout(): ?string
    {
        return _layout;
    }

    /**
     * Get view option.
     *
     * @param string $name The name of the option.
     * @return mixed
     */
    function getOption(string $name) {
        return _options[$name] ?? null;
    }

    /**
     * Set view option.
     *
     * @param string $name The name of the option.
     * @param mixed $value Value to set.
     * @return this
     */
    function setOption(string $name, $value) {
        _options[$name] = $value;

        return this;
    }

    /**
     * Sets additional options for the view.
     *
     * This lets you provide custom constructor arguments to application/plugin view classes.
     *
     * @param array<string, mixed> $options An array of options.
     * @param bool $merge Whether to merge existing data with the new data.
     * @return this
     */
    function setOptions(array $options, bool $merge = true) {
        if ($merge) {
            $options = array_merge(_options, $options);
        }
        _options = $options;

        return this;
    }

    /**
     * Gets additional options for the view.
     *
     * @return array<string, mixed>
     */
    function getOptions(): array
    {
        return _options;
    }

    /**
     * Sets the view name.
     *
     * @param string|null $name The name of the view, or null to remove the current name.
     * @return this
     */
    function setName(?string $name) {
        _name = $name;

        return this;
    }

    /**
     * Gets the view name.
     *
     * @return string|null
     */
    function getName(): ?string
    {
        return _name;
    }

    /**
     * Sets the view classname.
     *
     * Accepts either a short name (Ajax) a plugin name (MyPlugin.Ajax)
     * or a fully namespaced name (App\View\AppView) or null to use the
     * View class provided by CakePHP.
     *
     * @param string|null $name The class name for the view.
     * @return this
     */
    function setClassName(?string $name) {
        _className = $name;

        return this;
    }

    /**
     * Gets the view classname.
     *
     * @return string|null
     */
    function getClassName(): ?string
    {
        return _className;
    }

    /**
     * Using the data in the builder, create a view instance.
     *
     * If className() is null, App\View\AppView will be used.
     * If that class does not exist, then {@link uim.cake.View\View} will be used.
     *
     * @param array<string, mixed> $vars The view variables/context to use.
     * @param uim.cake.http.ServerRequest|null $request The request to use.
     * @param uim.cake.http.Response|null $response The response to use.
     * @param uim.cake.Event\IEventManager|null $events The event manager to use.
     * @return uim.cake.View\View
     * @throws uim.cake.View\Exception\MissingViewException
     */
    function build(
        array $vars = [],
        ?ServerRequest $request = null,
        ?Response $response = null,
        ?IEventManager $events = null
    ): View {
        $className = _className;
        if ($className == null) {
            $className = App::className("App", "View", "View") ?? View::class;
        } elseif ($className == "View") {
            $className = App::className($className, "View");
        } else {
            $className = App::className($className, "View", "View");
        }
        if ($className == null) {
            throw new MissingViewException(["class": _className]);
        }

        if (!empty($vars)) {
            deprecationWarning(
                "The $vars argument is deprecated. Use the setVar()/setVars() methods instead."
            );
        }

        $data = [
            "name": _name,
            "templatePath": _templatePath,
            "template": _template,
            "plugin": _plugin,
            "theme": _theme,
            "layout": _layout,
            "autoLayout": _autoLayout,
            "layoutPath": _layoutPath,
            "helpers": _helpers,
            "viewVars": $vars + _vars,
        ];
        $data += _options;

        /** @var uim.cake.View\View */
        return new $className($request, $response, $events, $data);
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
            "_templatePath", "_template", "_plugin", "_theme", "_layout", "_autoLayout",
            "_layoutPath", "_name", "_className", "_options", "_helpers", "_vars",
        ];

        $array = [];

        foreach ($properties as $property) {
            $array[$property] = this.{$property};
        }

        array_walk_recursive($array["_vars"], [this, "_checkViewVars"]);

        return array_filter($array, function ($i) {
            return !is_array($i) && strlen((string)$i) || !empty($i);
        });
    }

    /**
     * Iterates through hash to clean up and normalize.
     *
     * @param mixed $item Reference to the view var value.
     * @param string $key View var key.
     * @return void
     * @throws \RuntimeException
     */
    protected function _checkViewVars(&$item, string $key): void
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
                "Failed serializing the `%s` %s in the `%s` view var",
                is_resource($item) ? get_resource_type($item) : get_class($item),
                is_resource($item) ? "resource" : "object",
                $key
            ));
        }
    }

    /**
     * Configures a view builder instance from serialized config.
     *
     * @param array<string, mixed> $config View builder configuration array.
     * @return this
     */
    function createFromArray(array $config) {
        foreach ($config as $property: $value) {
            this.{$property} = $value;
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
    function __serialize(): array
    {
        return this.jsonSerialize();
    }

    /**
     * Unserializes the view builder object.
     *
     * @param string $data Serialized string.
     * @return void
     */
    function unserialize($data): void
    {
        this.createFromArray(unserialize($data));
    }

    /**
     * Magic method used to rebuild the view builder object.
     *
     * @param array<string, mixed> $data Data array.
     * @return void
     */
    function __unserialize(array $data): void
    {
        this.createFromArray($data);
    }
}
