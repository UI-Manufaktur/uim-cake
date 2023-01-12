module uim.cake.views\Widget;

import uim.cake.core.App;
import uim.cake.core.configures.engines.PhpConfig;
import uim.cake.views\StringTemplate;
import uim.cake.views\View;
use ReflectionClass;
use RuntimeException;

/**
 * A registry/factory for input widgets.
 *
 * Can be used by helpers/view logic to build form widgets
 * and other HTML widgets.
 *
 * This class handles the mapping between names and concrete classes.
 * It also has a basic name based dependency resolver that allows
 * widgets to depend on each other.
 *
 * Each widget should expect a StringTemplate instance as their first
 * argument. All other dependencies will be included after.
 *
 * Widgets can ask for the current view by using the `_view` widget.
 */
class WidgetLocator
{
    /**
     * Array of widgets + widget configuration.
     *
     * @var array
     */
    protected _widgets = null;

    /**
     * Templates to use.
     *
     * @var uim.cake.views\StringTemplate
     */
    protected _templates;

    /**
     * View instance.
     *
     * @var uim.cake.views\View
     */
    protected _view;

    /**
     * Constructor
     *
     * @param uim.cake.views\StringTemplate $templates Templates instance to use.
     * @param uim.cake.views\View $view The view instance to set as a widget.
     * @param array $widgets See add() method for more information.
     */
    this(StringTemplate $templates, View $view, array $widgets = null) {
        _templates = $templates;
        _view = $view;

        this.add($widgets);
    }

    /**
     * Load a config file containing widgets.
     *
     * Widget files should define a `aConfig` variable containing
     * all the widgets to load. Loaded widgets will be merged with existing
     * widgets.
     *
     * @param string $file The file to load
     */
    void load(string $file) {
        $loader = new PhpConfig();
        $widgets = $loader.read($file);
        this.add($widgets);
    }

    /**
     * Adds or replaces existing widget instances/configuration with new ones.
     *
     * Widget arrays can either be descriptions or instances. For example:
     *
     * ```
     * $registry.add([
     *   "label": new MyLabelWidget($templates),
     *   "checkbox": ["Fancy.MyCheckbox", "label"]
     * ]);
     * ```
     *
     * The above shows how to define widgets as instances or as
     * descriptions including dependencies. Classes can be defined
     * with plugin notation, or fully namespaced class names.
     *
     * @param array $widgets Array of widgets to use.
     * @return void
     * @throws \RuntimeException When class does not implement WidgetInterface.
     */
    void add(array $widgets) {
        $files = null;

        foreach ($widgets as $key: $widget) {
            if (is_int($key)) {
                $files[] = $widget;
                continue;
            }

            if (is_object($widget) && !($widget instanceof WidgetInterface)) {
                throw new RuntimeException(sprintf(
                    "Widget objects must implement `%s`. Got `%s` instance instead.",
                    WidgetInterface::class,
                    getTypeName($widget)
                ));
            }

            _widgets[$key] = $widget;
        }

        foreach ($files as $file) {
            this.load($file);
        }
    }

    /**
     * Get a widget.
     *
     * Will either fetch an already created widget, or create a new instance
     * if the widget has been defined. If the widget is undefined an instance of
     * the `_default` widget will be returned. An exception will be thrown if
     * the `_default` widget is undefined.
     *
     * @param string aName The widget name to get.
     * @return uim.cake.views\Widget\WidgetInterface WidgetInterface instance.
     * @throws \RuntimeException when widget is undefined.
     */
    function get(string aName): WidgetInterface
    {
        if (!isset(_widgets[$name])) {
            if (empty(_widgets["_default"])) {
                throw new RuntimeException(sprintf("Unknown widget `%s`", $name));
            }

            $name = "_default";
        }

        if (_widgets[$name] instanceof WidgetInterface) {
            return _widgets[$name];
        }

        return _widgets[$name] = _resolveWidget(_widgets[$name]);
    }

    /**
     * Clear the registry and reset the widgets.
     */
    void clear() {
        _widgets = null;
    }

    /**
     * Resolves a widget spec into an instance.
     *
     * @param mixed aConfig The widget config.
     * @return uim.cake.views\Widget\WidgetInterface Widget instance.
     * @throws \ReflectionException
     */
    protected function _resolveWidget(aConfig): WidgetInterface
    {
        if (is_string(aConfig)) {
            aConfig = [aConfig];
        }

        if (!is_array(aConfig)) {
            throw new RuntimeException("Widget config must be a string or array.");
        }

        $class = array_shift(aConfig);
        $className = App::className($class, "View/Widget", "Widget");
        if ($className == null) {
            throw new RuntimeException(sprintf("Unable to locate widget class '%s'", $class));
        }
        if (count(aConfig)) {
            $reflection = new ReflectionClass($className);
            $arguments = [_templates];
            foreach (aConfig as $requirement) {
                if ($requirement == "_view") {
                    $arguments[] = _view;
                } else {
                    $arguments[] = this.get($requirement);
                }
            }
            /** @var uim.cake.views\Widget\WidgetInterface $instance */
            $instance = $reflection.newInstanceArgs($arguments);
        } else {
            /** @var uim.cake.views\Widget\WidgetInterface $instance */
            $instance = new $className(_templates);
        }

        return $instance;
    }
}
