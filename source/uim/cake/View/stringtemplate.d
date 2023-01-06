module uim.cake.View;

import uim.cake.core.configures.engines.PhpConfig;
import uim.cake.core.exceptions.CakeException;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.utilities.Hash;
use RuntimeException;

/**
 * Provides an interface for registering and inserting
 * content into simple logic-less string templates.
 *
 * Used by several helpers to provide simple flexible templates
 * for generating HTML and other content.
 */
class StringTemplate
{
    use InstanceConfigTrait {
        getConfig as get;
    }

    /**
     * List of attributes that can be made compact.
     *
     * @var array<string, bool>
     */
    protected $_compactAttributes = [
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
    protected $_defaultConfig = [];

    /**
     * A stack of template sets that have been stashed temporarily.
     *
     * @var array
     */
    protected $_configStack = [];

    /**
     * Contains the list of compiled templates
     *
     * @var array<string, array>
     */
    protected $_compiled = [];

    /**
     * Constructor.
     *
     * @param array<string, mixed> aConfig A set of templates to add.
     */
    this(Json aConfig = []) {
        this.add(aConfig);
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
     * $templater.add([
     *   "link": "<a href="{{url}}">{{title}}</a>"
     *   "button": "<button>{{text}}</button>"
     * ]);
     * ```
     *
     * @param array<string> $templates An associative list of named templates.
     * @return this
     */
    function add(array $templates) {
        this.setConfig($templates);
        _compileTemplates(array_keys($templates));

        return this;
    }

    /**
     * Compile templates into a more efficient printf() compatible format.
     *
     * @param array<string> $templates The template names to compile. If empty all templates will be compiled.
     */
    protected void _compileTemplates(array $templates = []) {
        if (empty($templates)) {
            $templates = array_keys(_config);
        }
        foreach ($templates as $name) {
            $template = this.get($name);
            if ($template == null) {
                _compiled[$name] = [null, null];
            }

            $template = str_replace("%", "%%", $template);
            preg_match_all("#\{\{([\w\.]+)\}\}#", $template, $matches);
            _compiled[$name] = [
                str_replace($matches[0], "%s", $template),
                $matches[1],
            ];
        }
    }

    /**
     * Load a config file containing templates.
     *
     * Template files should define a `aConfig` variable containing
     * all the templates to load. Loaded templates will be merged with existing
     * templates.
     *
     * @param string $file The file to load
     */
    void load(string $file) {
        if ($file == "") {
            throw new CakeException("String template filename cannot be an empty string");
        }

        $loader = new PhpConfig();
        $templates = $loader.read($file);
        this.add($templates);
    }

    /**
     * Remove the named template.
     *
     * @param string aName The template to remove.
     */
    void remove(string aName) {
        this.setConfig($name, null);
        unset(_compiled[$name]);
    }

    /**
     * Format a template string with $data
     *
     * @param string aName The template name.
     * @param array<string, mixed> $data The data to insert.
     * @return string Formatted string
     * @throws \RuntimeException If template not found.
     */
    string format(string aName, array $data) {
        if (!isset(_compiled[$name])) {
            throw new RuntimeException("Cannot find template named "$name".");
        }
        [$template, $placeholders] = _compiled[$name];

        if (isset($data["templateVars"])) {
            $data += $data["templateVars"];
            unset($data["templateVars"]);
        }
        $replace = [];
        foreach ($placeholders as $placeholder) {
            $replacement = $data[$placeholder] ?? null;
            if (is_array($replacement)) {
                $replacement = implode("", $replacement);
            }
            $replace[] = $replacement;
        }

        return vsprintf($template, $replace);
    }

    /**
     * Returns a space-delimited string with items of the $options array. If a key
     * of $options array happens to be one of those listed
     * in `StringTemplate::$_compactAttributes` and its value is one of:
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
     * @param array<string, mixed>|null $options Array of options.
     * @param array<string>|null $exclude Array of options to be excluded, the options here will not be part of the return.
     * @return string Composed attributes.
     */
    string formatAttributes(?array $options, ?array $exclude = null) {
        $insertBefore = " ";
        $options = (array)$options + ["escape": true];

        if (!is_array($exclude)) {
            $exclude = [];
        }

        $exclude = ["escape": true, "idPrefix": true, "templateVars": true, "fieldName": true]
            + array_flip($exclude);
        $escape = $options["escape"];
        $attributes = [];

        foreach ($options as $key: $value) {
            if (!isset($exclude[$key]) && $value != false && $value != null) {
                $attributes[] = _formatAttribute((string)$key, $value, $escape);
            }
        }
        $out = trim(implode(" ", $attributes));

        return $out ? $insertBefore . $out : "";
    }

    /**
     * Formats an individual attribute, and returns the string value of the composed attribute.
     * Works with minimized attributes that have the same value as their name such as "disabled" and "checked"
     *
     * @param string aKey The name of the attribute to create
     * @param array<string>|string $value The value of the attribute to create.
     * @param bool $escape Define if the value must be escaped
     * @return string The composed attribute.
     */
    protected string _formatAttribute(string aKey, $value, $escape = true) {
        if (is_array($value)) {
            $value = implode(" ", $value);
        }
        if (is_numeric($key)) {
            return "$value=\"$value\"";
        }
        $truthy = [1, "1", true, "true", $key];
        $isMinimized = isset(_compactAttributes[$key]);
        if (!preg_match("/\A(\w|[.-])+\z/", $key)) {
            $key = h($key);
        }
        if ($isMinimized && in_array($value, $truthy, true)) {
            return "$key=\"$key\"";
        }
        if ($isMinimized) {
            return "";
        }

        return $key ~ "="" ~ ($escape ? h($value) : $value) ~ """;
    }

    /**
     * Adds a class and returns a unique list either in array or space separated
     *
     * @param array|string $input The array or string to add the class to
     * @param array<string>|string $newClass the new class or classes to add
     * @param string $useIndex if you are inputting an array with an element other than default of "class".
     * @return array<string>|string
     */
    function addClass($input, $newClass, string $useIndex = "class") {
        // NOOP
        if (empty($newClass)) {
            return $input;
        }

        if (is_array($input)) {
            $class = Hash::get($input, $useIndex, []);
        } else {
            $class = $input;
            $input = [];
        }

        // Convert and sanitise the inputs
        if (!is_array($class)) {
            if (is_string($class) && !empty($class)) {
                $class = explode(" ", $class);
            } else {
                $class = [];
            }
        }

        if (is_string($newClass)) {
            $newClass = explode(" ", $newClass);
        }

        $class = array_unique(array_merge($class, $newClass));

        return Hash::insert($input, $useIndex, $class);
    }
}
