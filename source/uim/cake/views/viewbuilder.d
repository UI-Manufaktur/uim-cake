/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views;

@safe:
import uim.cake;

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
    protected _template;

    /**
     * The plugin name to use.
     *
     * @var string|null
     */
    protected _plugin;

    /**
     * The theme name to use.
     *
     * @var string|null
     */
    protected _theme;

    /**
     * The layout name to render.
     *
     * @var string|null
     */
    protected _layout;

    /**
     * Whether autoLayout should be enabled.
     *
     * @var bool
     */
    protected _autoLayout = true;



    /**
     * The view variables to use
     *
     * @var string|null
     */
    protected _name;

    /**
     * The view class name to use.
     * Can either use plugin notation, a short name
     * or a fully moduled classname.
     *
     * @var string|null
     * @psalm-var class-string<uim.cake.View\View>|string|null
     */
    protected _className;

    /**
     * Additional options used when constructing the view.
     *
     * These options array lets you provide custom constructor
     * arguments to application/plugin view classes.
     *
     * @var array<string, mixed>
     */
    protected _options = null;

    /**
     * The helpers to use
     *
     * @var array
     */
    protected _helpers = null;

    /**
     * View vars
     *
     * @var array<string, mixed>
     */
    protected _vars = null;

    /**
     * Saves a variable for use inside a template.
     *
     * @param string myName A string or an array of data.
     * @param mixed myValue Value.
     * @return this
     */
    auto setVar(string myName, myValue = null) {
        _vars[myName] = myValue;

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
            _vars = myData + _vars;
        } else {
            _vars = myData;
        }

        return this;
    }

    /**
     * Check if view var is set.
     *
     * @param string myName Var name
     */
    bool hasVar(string myName) {
        return array_key_exists(myName, _vars);
    }

    /**
     * Get view var
     *
     * @param string myName Var name
     * @return mixed The var value or null if unset.
     */
    auto getVar(string myName) {
        return _vars[myName] ?? null;
    }

    /**
     * Get all view vars.
     *
     * @return array<string, mixed>
     */
    array getVars() {
        return _vars;
    }

    // The subdirectory to the template.
    mixin(OProperty!("string", "templatePath"));

    // The layout path to build the view with.
    mixin(OProperty!("string", "layoutPath"));

    /**
     * Turns on or off UIM"s conventional mode of applying layout files.
     * On by default. Setting to off means that layouts will not be
     * automatically applied to rendered views.
     *
     * @param bool myEnable Boolean to turn on/off.
     * @return this
     */
    O enableAutoLayout(this O)(bool myEnable = true) {
        _autoLayout = myEnable;

        return cast(O)this;
    }

    /**
     * Turns off UIM"s conventional mode of applying layout files.
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
     * Returns if UIM"s conventional mode of applying layout files is enabled.
     * Disabled means that layouts will not be automatically applied to rendered views.
     */
    bool isAutoLayoutEnabled() {
        return _autoLayout;
    }

    /**
     * Sets the plugin name to use.
     *
     * @param string|null myName Plugin name.
     *   Use null to remove the current plugin name.
     * @return this
     */
    auto setPlugin(Nullable!string myName) {
        _plugin = myName;

        return this;
    }

    /**
     * Gets the plugin name to use.
     *
     * @return string|null
     */
    Nullable!string getPlugin() {
        return _plugin;
    }

    /**
     * Adds a helper to use.
     *
     * @param string helper Helper to use.
     * @param array<string, mixed> myOptions Options.
     * @return this
     * @since 4.1.0
     */
    function addHelper(string helper, array myOptions = null) {
        if (myOptions) {
            $array = [$helper: myOptions];
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
        foreach ($helpers as $helper: myConfig) {
            if (is_int($helper)) {
                $helper = myConfig;
                myConfig = null;
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
            deprecationWarning("The myMerge param is deprecated, use addHelper()/addHelpers() instead.");
            $helpers = array_merge(_helpers, $helpers);
        }
        _helpers = $helpers;

        return this;
    }

    /**
     * Gets the helpers to use.
     */
    array getHelpers() {
        return _helpers;
    }

    /**
     * Sets the view theme to use.
     *
     * @param string|null $theme Theme name.
     *   Use null to remove the current theme.
     * @return this
     */
    auto setTheme(Nullable!string theme) {
        _theme = $theme;

        return this;
    }

    /**
     * Gets the view theme to use.
     *
     * @return string|null
     */
    Nullable!string getTheme() {
        return _theme;
    }

    /**
     * Sets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @param string|null myName View file name to set, or null to remove the template name.
     * @return this
     */
    auto setTemplate(Nullable!string myName) {
        _template = myName;

        return this;
    }

    /**
     * Gets the name of the view file to render. The name specified is the
     * filename in `templates/<SubFolder>/` without the .php extension.
     *
     * @return string|null
     */
    Nullable!string getTemplate() {
        return _template;
    }

    /**
     * Sets the name of the layout file to render the view inside of.
     * The name specified is the filename of the layout in `templates/layout/`
     * without the .php extension.
     *
     * @param string|null myName Layout file name to set.
     * @return this
     */
    auto setLayout(Nullable!string myName) {
        _layout = myName;

        return this;
    }

    /**
     * Gets the name of the layout file to render the view inside of.
     *
     * @return string|null
     */
    Nullable!string getLayout() {
        return _layout;
    }

    /**
     * Get view option.
     *
     * @param string myName The name of the option.
     * @return mixed
     */
    auto getOption(string myName) {
        return _options[myName] ?? null;
    }

    /**
     * Set view option.
     *
     * @param string myName The name of the option.
     * @param mixed myValue Value to set.
     * @return this
     */
    auto setOption(string myName, myValue) {
        _options[myName] = myValue;

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
            myOptions = array_merge(_options, myOptions);
        }
        _options = myOptions;

        return this;
    }

    /**
     * Gets additional options for the view.
     *
     * @return array<string, mixed>
     */
    array getOptions() {
        return _options;
    }

    /**
     * Sets the view name.
     *
     * @param string|null myName The name of the view, or null to remove the current name.
     * @return this
     */
    auto setName(Nullable!string myName) {
        _name = myName;

        return this;
    }

    /**
     * Gets the view name.
     *
     * @return string|null
     */
    Nullable!string getName() {
        return _name;
    }

    /**
     * Sets the view classname.
     *
     * Accepts either a short name (Ajax) a plugin name (MyPlugin.Ajax)
     * or a fully moduled name (App\View\AppView) or null to use the
     * View class provided by UIM.
     *
     * @param string|null myName The class name for the view.
     * @return this
     */
    auto setClassName(Nullable!string myName) {
        _className = myName;

        return this;
    }

    /**
     * Gets the view classname.
     *
     * @return string|null
     */
    Nullable!string getClassName() {
        return _className;
    }

    /**
     * Using the data in the builder, create a view instance.
     *
     * If className() is null, App\View\AppView will be used.
     * If that class does not exist, then {@link uim.cake.View\View} will be used.
     *
     * @param array<string, mixed> $vars The view variables/context to use.
     * @param uim.cake.http.ServerRequest|null myRequest The request to use.
     * @param uim.cake.http.Response|null $response The response to use.
     * @param uim.cake.events.IEventManager|null myEvents The event manager to use.
     * @return uim.cake.View\View
     * @throws uim.cake.View\exceptions.MissingViewException
     */
    function build(
        array $vars = null,
        ?ServerRequest myRequest = null,
        ?Response $response = null,
        ?IEventManager myEvents = null
    ): View {
        myClassName = _className;
        if (myClassName is null) {
            myClassName = App::className("App", "View", "View") ?? View::class;
        } elseif (myClassName == "View") {
            myClassName = App::className(myClassName, "View");
        } else {
            myClassName = App::className(myClassName, "View", "View");
        }
        if (myClassName is null) {
            throw new MissingViewException(["class": _className]);
        }

        if (!empty($vars)) {
            deprecationWarning(
                "The $vars argument is deprecated. Use the setVar()/setVars() methods instead."
            );
        }

        myData = [
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
        myData += _options;

        /** @var uim.cake.View\View */
        return new myClassName(myRequest, $response, myEvents, myData);
    }

    /**
     * Serializes the view builder object to a value that can be natively
     * serialized and re-used to clone this builder instance.
     *
     * There are  limitations for viewVars that are good to know:
     *
     * - orm.Query executed and stored as resultset
     * - SimpleXMLElements stored as associative array
     * - Exceptions stored as strings
     * - Resources, \Closure and \PDO are not supported.
     *
     * @return array Serializable array of configuration properties.
     */
    array jsonSerialize() {
        $properties = [
            "_templatePath", "_template", "_plugin", "_theme", "_layout", "_autoLayout",
            "_layoutPath", "_name", "_className", "_options", "_helpers", "_vars",
        ];

        $array = null;

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
     * @param string myKey View var key.
     * @throws \RuntimeException
     */
    protected void _checkViewVars(&$item, string myKey) {
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
        foreach (myConfig as $property: myValue) {
            this.{$property} = myValue;
        }

        return this;
    }

    // Serializes the view builder object.
    string serialize() {
        $array = this.jsonSerialize();

        return serialize($array);
    }

    /**
     * Magic method used for serializing the view builder object.
     */
    array __serialize() {
        return this.jsonSerialize();
    }

    /**
     * Unserializes the view builder object.
     *
     * @param string myData Serialized string.
     */
    void unserialize(myData) {
        this.createFromArray(unserialize(myData));
    }

    /**
     * Magic method used to rebuild the view builder object.
     *
     * @param array<string, mixed> myData Data array.
     */
    void __unserialize(array myData) {
        this.createFromArray(myData);
    }
}
