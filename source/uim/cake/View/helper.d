module uim.cake.views;

import uim.cake.core.InstanceConfigTrait;
import uim.cake.events.IEventListener;

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
 * - `beforeRender(IEvent $event, $viewFile)` - beforeRender is called before the view file is rendered.
 * - `afterRender(IEvent $event, $viewFile)` - afterRender is called after the view file is rendered
 *   but before the layout has been rendered.
 * - beforeLayout(IEvent $event, $layoutFile)` - beforeLayout is called before the layout is rendered.
 * - `afterLayout(IEvent $event, $layoutFile)` - afterLayout is called after the layout has rendered.
 * - `beforeRenderFile(IEvent $event, $viewFile)` - Called before any view fragment is rendered.
 * - `afterRenderFile(IEvent $event, $viewFile, $content)` - Called after any view fragment is rendered.
 *   If a listener returns a non-null value, the output of the rendered file will be set to that.
 */
#[\AllowDynamicProperties]
class Helper : IEventListener
{
    use InstanceConfigTrait;

    /**
     * List of helpers used by this helper
     *
     * @var array
     */
    protected $helpers = null;

    /**
     * Default config for this helper.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = null;

    /**
     * A helper lookup table used to lazy load helper objects.
     *
     * @var array<string, array>
     */
    protected _helperMap = null;

    /**
     * The View instance this helper is attached to
     *
     * @var uim.cake.views\View
     */
    protected _View;

    /**
     * Default Constructor
     *
     * @param uim.cake.views\View $view The View this helper is being attached to.
     * @param array<string, mixed> aConfig Configuration settings for the helper.
     */
    this(View $view, Json aConfig = null) {
        _View = $view;
        this.setConfig(aConfig);

        if (!empty(this.helpers)) {
            _helperMap = $view.helpers().normalizeArray(this.helpers);
        }

        this.initialize(aConfig);
    }

    /**
     * Provide non fatal errors on missing method calls.
     *
     * @param string $method Method to invoke
     * @param array $params Array of params for the method.
     * @return mixed|void
     */
    function __call(string $method, array $params) {
        trigger_error(sprintf("Method %1$s::%2$s does not exist", static::class, $method), E_USER_WARNING);
    }

    /**
     * Lazy loads helpers.
     *
     * @param string aName Name of the property being accessed.
     * @return uim.cake.views\Helper|null|void Helper instance if helper with provided name exists
     */
    function __get(string aName) {
        if (isset(_helperMap[$name]) && !isset(this.{$name})) {
            aConfig = ["enabled": false] + (array)_helperMap[$name]["config"];
            this.{$name} = _View.loadHelper(_helperMap[$name]["class"], aConfig);

            return this.{$name};
        }
    }

    /**
     * Get the view instance this helper is bound to.
     *
     * @return uim.cake.views\View The bound view instance.
     */
    function getView(): View
    {
        return _View;
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
     * @param array<string, mixed> $options Array options/attributes to add a class to
     * @param string $class The class name being added.
     * @param string aKey the key to use for class. Defaults to `"class"`.
     * @return array<string, mixed> Array of options with $key set.
     */
    array addClass(STRINGAA someOptions, string $class, string aKey = "class") {
        if (isset($options[$key]) && is_array($options[$key])) {
            $options[$key][] = $class;
        } elseif (isset($options[$key]) && trim($options[$key])) {
            $options[$key] ~= " " ~ $class;
        } else {
            $options[$key] = $class;
        }

        return $options;
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
    array implementedEvents() {
        $eventMap = [
            "View.beforeRenderFile": "beforeRenderFile",
            "View.afterRenderFile": "afterRenderFile",
            "View.beforeRender": "beforeRender",
            "View.afterRender": "afterRender",
            "View.beforeLayout": "beforeLayout",
            "View.afterLayout": "afterLayout",
        ];
        $events = null;
        foreach ($eventMap as $event: $method) {
            if (method_exists(this, $method)) {
                $events[$event] = $method;
            }
        }

        return $events;
    }

    /**
     * Constructor hook method.
     *
     * Implement this method to avoid having to overwrite the constructor and call parent.
     *
     * @param array<string, mixed> aConfig The configuration settings provided to this helper.
     */
    void initialize(Json aConfig) {
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        return [
            "helpers": this.helpers,
            "implementedEvents": this.implementedEvents(),
            "_config": this.getConfig(),
        ];
    }
}
