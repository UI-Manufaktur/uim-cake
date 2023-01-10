module uim.cake.views;

@safe:
import uim.cake;

/**
 * Provides an interface for registering and inserting
 * content into simple logic-less string templates.
 *
 * Used by several helpers to provide simple flexible templates
 * for generating HTML and other content.
 */
class StringTemplate {
    use InstanceConfigTrait {
        getConfig as get;
    }

    /**
     * List of attributes that can be made compact.
     *
     * @var array<string, bool>
     */
    protected _compactAttributes = [
        "allowfullscreen": true,
        "async": true,
        "autofocus": true,
        "autoplay": true,
        "checked": true,
        "compact": true,
        "controls": true,
        "declare": true,
        "default": true,
        "defaultchecked": true,
        "defaultmuted": true,
        "defaultselected": true,
        "defer": true,
        "disabled": true,
        "enabled": true,
        "formnovalidate": true,
        "hidden": true,
        "indeterminate": true,
        "inert": true,
        "ismap": true,
        "itemscope": true,
        "loop": true,
        "multiple": true,
        "muted": true,
        "nohref": true,
        "noresize": true,
        "noshade": true,
        "novalidate": true,
        "nowrap": true,
        "open": true,
        "pauseonexit": true,
        "readonly": true,
        "required": true,
        "reversed": true,
        "scoped": true,
        "seamless": true,
        "selected": true,
        "sortable": true,
        "truespeed": true,
        "typemustmatch": true,
        "visible": true,
    ];

    /**
     * The default templates this instance holds.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [];

    /**
     * A stack of template sets that have been stashed temporarily.
     *
     * @var array
     */
    protected _configStack = [];

    /**
     * Contains the list of compiled templates
     *
     * @var array<string, array>
     */
    protected _compiled = [];

    /**
     * Constructor.
     *
     * @param array<string, mixed> myConfig A set of templates to add.
     */
    this(array myConfig = []) {
        this.add(myConfig);
    }

    /**
     * Push the current templates into the template stack.
     */
    void push() {
      _configStack[] = [
          _config,
          _compiled,
      ];
    }

    /**
     * Restore the most recently pushed set of templates.
     */
    void pop() {
      if (empty(_configStack)) {
          return;
      }
      [_config, _compiled] = array_pop(_configStack);
    }

    /**
     * Registers a list of templates by name
     *
     * ### Example:
     *
     * ```
     * myTemplater.add([
     *   "link": "<a href="{{url}}">{{title}}</a>"
     *   "button": "<button>{{text}}</button>"
     * ]);
     * ```
     *
     * @param array<string> myTemplates An associative list of named templates.
     * @return this
     */
    function add(array myTemplates) {
      this.setConfig(myTemplates);
      _compileTemplates(array_keys(myTemplates));

      return this;
    }

    /**
     * Compile templates into a more efficient printf() compatible format.
     *
     * @param array<string> myTemplates The template names to compile. If empty all templates will be compiled.
     */
    protected void _compileTemplates(array myTemplates = []) {
      if (empty(myTemplates)) {
          myTemplates = array_keys(_config);
      }
      foreach (myTemplates as myName) {
        myTemplate = this.get(myName);
        if (myTemplate is null) {
            _compiled[myName] = [null, null];
        }

        myTemplate = replace("%", "%%", myTemplate);
        preg_match_all("#\{\{([\w\._]+)\}\}#", myTemplate, $matches);
        _compiled[myName] = [
            replace($matches[0], '%s', myTemplate),
            $matches[1],
        ];
      }
    }

    /**
     * Load a config file containing templates.
     *
     * Template files should define a `myConfig` variable containing
     * all the templates to load. Loaded templates will be merged with existing
     * templates.
     *
     * @param string myfile The file to load
     */
    void load(string myfile) {
        if (myfile == "") {
            throw new UIMException("String template filename cannot be an empty string");
        }

        $loader = new PhpConfig();
        myTemplates = $loader.read(myfile);
        this.add(myTemplates);
    }

    /**
     * Remove the named template.
     *
     * @param string myName The template to remove.
     */
    void remove(string myName) {
        this.setConfig(myName, null);
        unset(_compiled[myName]);
    }

    /**
     * Format a template string with myData
     *
     * @param string myName The template name.
     * @param array<string, mixed> myData The data to insert.
     * @return string Formatted string
     * @throws \RuntimeException If template not found.
     */
    string format(string myName, array myData) {
        if (!isset(_compiled[myName])) {
            throw new RuntimeException("Cannot find template named "myName".");
        }
        [myTemplate, $placeholders] = _compiled[myName];

        if (isset(myData["templateVars"])) {
            myData += myData["templateVars"];
            unset(myData["templateVars"]);
        }
        $replace = [];
        foreach ($placeholders as $placeholder) {
            $replacement = myData[$placeholder] ?? null;
            if (is_array($replacement)) {
                $replacement = implode("", $replacement);
            }
            $replace[] = $replacement;
        }

        return vsprintf(myTemplate, $replace);
    }

    /**
     * Returns a space-delimited string with items of the myOptions array. If a key
     * of myOptions array happens to be one of those listed
     * in `StringTemplate::_compactAttributes` and its value is one of:
     *
     * - "1" (string)
     * - 1 (integer)
     * - true (boolean)
     * - "true" (string)
     *
     * Then the value will be reset to be identical with key"s name.
     * If the value is not one of these 4, the parameter is not output.
     *
     * "escape" is a special option in that it controls the conversion of
     * attributes to their HTML-entity encoded equivalents. Set to false to disable HTML-encoding.
     *
     * If value for any option key is set to `null` or `false`, that option will be excluded from output.
     *
     * This method uses the "attribute" and "compactAttribute" templates. Each of
     * these templates uses the `name` and `value` variables. You can modify these
     * templates to change how attributes are formatted.
     *
     * @param array<string, mixed>|null myOptions Array of options.
     * @param array<string>|null $exclude Array of options to be excluded, the options here will not be part of the return.
     * @return string Composed attributes.
     */
    string formatAttributes(?array myOptions, ?array $exclude = null) {
        $insertBefore = " ";
        myOptions = (array)myOptions + ["escape": true];

        if (!is_array($exclude)) {
            $exclude = [];
        }

        $exclude = ["escape": true, "idPrefix": true, "templateVars": true, "fieldName": true]
            + array_flip($exclude);
        $escape = myOptions["escape"];
        $attributes = [];

        foreach (myOptions as myKey: myValue) {
            if (!isset($exclude[myKey]) && myValue != false && myValue  !is null) {
                $attributes[] = _formatAttribute((string)myKey, myValue, $escape);
            }
        }
        $out = trim(implode(" ", $attributes));

        return $out ? $insertBefore . $out : "";
    }

    /**
     * Formats an individual attribute, and returns the string value of the composed attribute.
     * Works with minimized attributes that have the same value as their name such as "disabled" and "checked"
     *
     * @param string myKey The name of the attribute to create
     * @param array<string>|string myValue The value of the attribute to create.
     * @param bool $escape Define if the value must be escaped
     * @return string The composed attribute.
     */
    protected string _formatAttribute(string myKey, myValue, $escape = true) {
        if (is_array(myValue)) {
            myValue = implode(" ", myValue);
        }
        if (is_numeric(myKey)) {
            return "myValue=\"myValue\"";
        }
        $truthy = [1, "1", true, "true", myKey];
        $isMinimized = isset(_compactAttributes[myKey]);
        if (!preg_match("/\A(\w|[.-])+\z/", myKey)) {
            myKey = h(myKey);
        }
        if ($isMinimized && hasAllValues(myValue, $truthy, true)) {
            return "myKey=\"myKey\"";
        }
        if ($isMinimized) {
            return "";
        }

        return myKey ~ "="" ~ ($escape ? h(myValue) : myValue) ~ """;
    }

    /**
     * Adds a class and returns a unique list either in array or space separated
     *
     * @param array|string input The array or string to add the class to
     * @param array<string>|string newClass the new class or classes to add
     * @param string useIndex if you are inputting an array with an element other than default of "class".
     */
    string[] addClass($input, $newClass, string useIndex = "class") {
        // NOOP
        if (empty($newClass)) {
            return $input;
        }

        if (is_array($input)) {
            myClass = Hash::get($input, $useIndex, []);
        } else {
            myClass = $input;
            $input = [];
        }

        // Convert and sanitise the inputs
        if (!is_array(myClass)) {
            if (is_string(myClass) && !empty(myClass)) {
                myClass = explode(" ", myClass);
            } else {
                myClass = [];
            }
        }

        if (is_string($newClass)) {
            $newClass = explode(" ", $newClass);
        }

        myClass = array_unique(array_merge(myClass, $newClass));

        $input = Hash::insert($input, $useIndex, myClass);

        return $input;
    }
}
