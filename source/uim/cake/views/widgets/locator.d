module uim.cake.views.widgets;

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
    protected $_widgets = [];

    /**
     * Templates to use.
     *
     * @var \Cake\View\StringTemplate
     */
    protected $_templates;

    /**
     * View instance.
     *
     * @var \Cake\View\View
     */
    protected $_view;

    /**
     * Constructor
     *
     * @param \Cake\View\StringTemplate myTemplates Templates instance to use.
     * @param \Cake\View\View $view The view instance to set as a widget.
     * @param array $widgets See add() method for more information.
     */
    this(StringTemplate myTemplates, View $view, array $widgets = []) {
        this._templates = myTemplates;
        this._view = $view;

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
        myfiles = [];

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

            this._widgets[myKey] = $widget;
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
     * @return \Cake\View\Widget\IWidget IWidget instance.
     * @throws \RuntimeException when widget is undefined.
     */
    auto get(string myName): IWidget
    {
        if (!isset(this._widgets[myName])) {
            if (empty(this._widgets["_default"])) {
                throw new RuntimeException(sprintf("Unknown widget `%s`", myName));
            }

            myName = "_default";
        }

        if (this._widgets[myName] instanceof IWidget) {
            return this._widgets[myName];
        }

        return this._widgets[myName] = this._resolveWidget(this._widgets[myName]);
    }

    // Clear the registry and reset the widgets.
    void clear() {
        this._widgets = [];
    }

    /**
     * Resolves a widget spec into an instance.
     *
     * @param mixed myConfig The widget config.
     * @return \Cake\View\Widget\IWidget Widget instance.
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
        if (myClassName == null) {
            throw new RuntimeException(sprintf("Unable to locate widget class "%s"", myClass));
        }
        if (count(myConfig)) {
            $reflection = new ReflectionClass(myClassName);
            $arguments = [this._templates];
            foreach (myConfig as $requirement) {
                if ($requirement == "_view") {
                    $arguments[] = this._view;
                } else {
                    $arguments[] = this.get($requirement);
                }
            }
            /** @var \Cake\View\Widget\IWidget $instance */
            $instance = $reflection.newInstanceArgs($arguments);
        } else {
            /** @var \Cake\View\Widget\IWidget $instance */
            $instance = new myClassName(this._templates);
        }

        return $instance;
    }
}
