/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.viewss.widgets;

@safe:
import uim.cake;

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
     * @param uim.cake.views\StringTemplate myTemplates Templates instance to use.
     * @param uim.cake.views\View $view The view instance to set as a widget.
     * @param array $widgets See add() method for more information.
     */
    this(StringTemplate myTemplates, View $view, array $widgets = null) {
        _templates = myTemplates;
        _view = $view;

        this.add($widgets);
    }

    /**
     * Load a config file containing widgets.
     *
     * Widget files should define a `myConfig` variable containing
     * all the widgets to load. Loaded widgets will be merged with existing
     * widgets.
     *
     * @param string myfile The file to load
     */
    void load(string myfile) {
        $loader = new PhpConfig();
        $widgets = $loader.read(myfile);
        this.add($widgets);
    }

    /**
     * Adds or replaces existing widget instances/configuration with new ones.
     *
     * Widget arrays can either be descriptions or instances. For example:
     *
     * ```
     * $registry.add([
     *   "label": new MyLabelWidget(myTemplates),
     *   "checkbox": ["Fancy.MyCheckbox", "label"]
     * ]);
     * ```
     *
     * The above shows how to define widgets as instances or as
     * descriptions including dependencies. Classes can be defined
     * with plugin notation, or fully moduled class names.
     *
     * @param array $widgets Array of widgets to use.
     * @throws \RuntimeException When class does not implement IWidget.
     */
    void add(array $widgets) {
        myfiles = null;

        foreach ($widgets as myKey: $widget) {
            if (is_int(myKey)) {
                myfiles[] = $widget;
                continue;
            }

            if (is_object($widget) && !($widget instanceof IWidget)) {
                throw new RuntimeException(sprintf(
                    "Widget objects must implement `%s`. Got `%s` instance instead.",
                    IWidget::class,
                    getTypeName($widget)
                ));
            }

            _widgets[myKey] = $widget;
        }

        foreach (myfiles as myfile) {
            this.load(myfile);
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
     * @param string myName The widget name to get.
     * @return uim.cake.views\Widget\IWidget IWidget instance.
     * @throws \RuntimeException when widget is undefined.
     */
    auto get(string myName): IWidget
    {
        if (!isset(_widgets[myName])) {
            if (empty(_widgets["_default"])) {
                throw new RuntimeException(sprintf("Unknown widget `%s`", myName));
            }

            myName = "_default";
        }

        if (_widgets[myName] instanceof IWidget) {
            return _widgets[myName];
        }

        return _widgets[myName] = _resolveWidget(_widgets[myName]);
    }

    // Clear the registry and reset the widgets.
    void clear() {
        _widgets = null;
    }

    /**
     * Resolves a widget spec into an instance.
     *
     * @param mixed myConfig The widget config.
     * @return uim.cake.views\Widget\IWidget Widget instance.
     * @throws \ReflectionException
     */
    protected IWidget _resolveWidget(myConfig) {
        if (is_string(myConfig)) {
            myConfig = [myConfig];
        }

        if (!is_array(myConfig)) {
            throw new RuntimeException("Widget config must be a string or array.");
        }

        myClass = array_shift(myConfig);
        myClassName = App::className(myClass, "View/Widget", "Widget");
        if (myClassName is null) {
            throw new RuntimeException(sprintf("Unable to locate widget class '%s'", myClass));
        }
        if (count(myConfig)) {
            $reflection = new ReflectionClass(myClassName);
            $arguments = [_templates];
            foreach (myConfig as $requirement) {
                if ($requirement == "_view") {
                    $arguments[] = _view;
                } else {
                    $arguments[] = this.get($requirement);
                }
            }
            /** @var uim.cake.views\Widget\IWidget $instance */
            $instance = $reflection.newInstanceArgs($arguments);
        } else {
            /** @var uim.cake.views\Widget\IWidget $instance */
            $instance = new myClassName(_templates);
        }

        return $instance;
    }
}
