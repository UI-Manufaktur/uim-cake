
module uim.cake.views;

import uim.cake.core.InstanceConfigTrait;
import uim.cakeents\IEventListener;

/**
 * Abstract base class for all other Helpers in UIM.
 * Provides common methods and features.
 *
 * ### Callback methods
 *
 * Helpers support a number of callback methods. These callbacks allow you to hook into
 * the various view lifecycle events and either modify existing view content or perform
 * other application specific logic. The events are not implemented by this base class, as
 * implementing a callback method subscribes a helper to the related event. The callback methods
 * are as follows:
 *
 * - `beforeRender(IEvent myEvent, $viewFile)` - beforeRender is called before the view file is rendered.
 * - `afterRender(IEvent myEvent, $viewFile)` - afterRender is called after the view file is rendered
 *   but before the layout has been rendered.
 * - beforeLayout(IEvent myEvent, $layoutFile)` - beforeLayout is called before the layout is rendered.
 * - `afterLayout(IEvent myEvent, $layoutFile)` - afterLayout is called after the layout has rendered.
 * - `beforeRenderFile(IEvent myEvent, $viewFile)` - Called before any view fragment is rendered.
 * - `afterRenderFile(IEvent myEvent, $viewFile, myContents)` - Called after any view fragment is rendered.
 *   If a listener returns a non-null value, the output of the rendered file will be set to that.
 */
class Helper : IEventListener
{
    use InstanceConfigTrait;

    /**
     * List of helpers used by this helper
     *
     * @var array
     */
    protected $helpers = [];

    /**
     * Default config for this helper.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [];

    /**
     * A helper lookup table used to lazy load helper objects.
     *
     * @var array<string, array>
     */
    protected $_helperMap = [];

    /**
     * The View instance this helper is attached to
     *
     * @var \Cake\View\View
     */
    protected $_View;

    /**
     * Default Constructor
     *
     * @param \Cake\View\View $view The View this helper is being attached to.
     * @param array<string, mixed> myConfig Configuration settings for the helper.
     */
    this(View $view, array myConfig = []) {
        this._View = $view;
        this.setConfig(myConfig);

        if (!empty(this.helpers)) {
            this._helperMap = $view.helpers().normalizeArray(this.helpers);
        }

        this.initialize(myConfig);
    }

    /**
     * Provide non fatal errors on missing method calls.
     *
     * @param string $method Method to invoke
     * @param array myParams Array of params for the method.
     * @return mixed|void
     */
    auto __call(string $method, array myParams) {
        trigger_error(sprintf("Method %1$s::%2$s does not exist", static::class, $method), E_USER_WARNING);
    }

    /**
     * Lazy loads helpers.
     *
     * @param string myName Name of the property being accessed.
     * @return \Cake\View\Helper|null|void Helper instance if helper with provided name exists
     */
    auto __get(string myName) {
        if (isset(this._helperMap[myName]) && !isset(this.{myName})) {
            myConfig = ["enabled" => false] + (array)this._helperMap[myName]["config"];
            this.{myName} = this._View.loadHelper(this._helperMap[myName]["class"], myConfig);

            return this.{myName};
        }
    }

    /**
     * Get the view instance this helper is bound to.
     *
     * @return \Cake\View\View The bound view instance.
     */
    auto getView(): View
    {
        return this._View;
    }

    /**
     * Returns a string to be used as onclick handler for confirm dialogs.
     *
     * @param string $okCode Code to be executed after user chose "OK"
     * @param string $cancelCode Code to be executed after user chose "Cancel"
     * @return string "onclick" JS code
     */
    protected string _confirm(string $okCode, string $cancelCode) {
        return "if (confirm(this.dataset.confirmMessage)) { {$okCode} } {$cancelCode}";
    }

    /**
     * Adds the given class to the element options
     *
     * @param array<string, mixed> myOptions Array options/attributes to add a class to
     * @param string myClass The class name being added.
     * @param string myKey the key to use for class. Defaults to `"class"`.
     * @return array<string, mixed> Array of options with myKey set.
     */
    function addClass(array myOptions, string myClass, string myKey = "class"): array
    {
        if (isset(myOptions[myKey]) && is_array(myOptions[myKey])) {
            myOptions[myKey][] = myClass;
        } elseif (isset(myOptions[myKey]) && trim(myOptions[myKey])) {
            myOptions[myKey] .= " " . myClass;
        } else {
            myOptions[myKey] = myClass;
        }

        return myOptions;
    }

    /**
     * Get the View callbacks this helper is interested in.
     *
     * By defining one of the callback methods a helper is assumed
     * to be interested in the related event.
     *
     * Override this method if you need to add non-conventional event listeners.
     * Or if you want helpers to listen to non-standard events.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        myEventMap = [
            "View.beforeRenderFile" => "beforeRenderFile",
            "View.afterRenderFile" => "afterRenderFile",
            "View.beforeRender" => "beforeRender",
            "View.afterRender" => "afterRender",
            "View.beforeLayout" => "beforeLayout",
            "View.afterLayout" => "afterLayout",
        ];
        myEvents = [];
        foreach (myEventMap as myEvent => $method) {
            if (method_exists(this, $method)) {
                myEvents[myEvent] = $method;
            }
        }

        return myEvents;
    }

    /**
     * Constructor hook method.
     *
     * Implement this method to avoid having to overwrite the constructor and call parent.
     *
     * @param array<string, mixed> myConfig The configuration settings provided to this helper.
     */
    void initialize(array myConfig) {
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array {
        return [
            "helpers" => this.helpers,
            "implementedEvents" => this.implementedEvents(),
            "_config" => this.getConfig(),
        ];
    }
}
