module uim.cake.views;

@safe:
import uim.cake;

/* import uim.cake.Event\IEventDispatcher;
 */
/**
 * Provides the set() method for collecting template context.
 *
 * Once collected context data can be passed to another object.
 * This is done in Controller, TemplateTask and View for example.
 */
trait ViewVarsTrait {
    /**
     * The view builder instance being used.
     *
     * @var \Cake\View\ViewBuilder|null
     */
    protected $_viewBuilder;

    /**
     * Get the view builder being used.
     *
     * @return \Cake\View\ViewBuilder
     */
    function viewBuilder(): ViewBuilder
    {
        if (!isset(this._viewBuilder)) {
            this._viewBuilder = new ViewBuilder();
        }

        return this._viewBuilder;
    }

    /**
     * Constructs the view class instance based on the current configuration.
     *
     * @param string|null $viewClass Optional moduled class name of the View class to instantiate.
     * @return \Cake\View\View
     * @throws \Cake\View\Exception\MissingViewException If view class was not found.
     */
    function createView(?string $viewClass = null): View
    {
        myBuilder = this.viewBuilder();
        if ($viewClass) {
            myBuilder.setClassName($viewClass);
        }

        foreach (['name', 'plugin'] as $prop) {
            if (isset(this.{$prop})) {
                $method = 'set' . ucfirst($prop);
                myBuilder.{$method}(this.{$prop});
            }
        }

        /** @psalm-suppress RedundantPropertyInitializationCheck */
        return myBuilder.build(
            [],
            this.request ?? null,
            this.response ?? null,
            this instanceof IEventDispatcher ? this.getEventManager() : null
        );
    }

    /**
     * Saves a variable or an associative array of variables for use inside a template.
     *
     * @param array|string myName A string or an array of data.
     * @param mixed myValue Value in case myName is a string (which then works as the key).
     *   Unused if myName is an associative array, otherwise serves as the values to myName's keys.
     * @return this
     */
    auto set(myName, myValue = null) {
        if (is_array(myName)) {
            if (is_array(myValue)) {
                myData = array_combine(myName, myValue);
            } else {
                myData = myName;
            }
        } else {
            myData = [myName => myValue];
        }
        this.viewBuilder().setVars(myData);

        return this;
    }
}
