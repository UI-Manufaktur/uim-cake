module uim.cake.Event;

import uim.cake.core.Exception\CakeException;

/**
 * The event manager is responsible for keeping track of event listeners, passing the correct
 * data to them, and firing them in the correct order, when associated events are triggered. You
 * can create multiple instances of this object to manage local events or keep a single instance
 * and pass it around to manage all events in your app.
 */
class EventManager : IEventManager
{
    /**
     * The default priority queue value for new, attached listeners
     *
     * @var int
     */
    static $defaultPriority = 10;

    /**
     * The globally available instance, used for dispatching events attached from any scope
     *
     * @var \Cake\Event\EventManager|null
     */
    protected static $_generalManager;

    /**
     * List of listener callbacks associated to
     *
     * @var array
     */
    protected $_listeners = [];

    /**
     * Internal flag to distinguish a common manager from the singleton
     *
     * @var bool
     */
    protected $_isGlobal = false;

    /**
     * The event list object.
     *
     * @var \Cake\Event\EventList|null
     */
    protected $_eventList;

    /**
     * Enables automatic adding of events to the event list object if it is present.
     *
     * @var bool
     */
    protected $_trackEvents = false;

    /**
     * Returns the globally available instance of a Cake\Event\EventManager
     * this is used for dispatching events attached from outside the scope
     * other managers were created. Usually for creating hook systems or inter-class
     * communication
     *
     * If called with the first parameter, it will be set as the globally available instance
     *
     * @param \Cake\Event\EventManager|null $manager Event manager instance.
     * @return \Cake\Event\EventManager The global event manager
     */
    static function instance(?EventManager $manager = null) {
        if ($manager instanceof EventManager) {
            static::$_generalManager = $manager;
        }
        if (empty(static::$_generalManager)) {
            static::$_generalManager = new static();
        }

        static::$_generalManager._isGlobal = true;

        return static::$_generalManager;
    }


    function on(myEventKey, myOptions = [], ?callable $callable = null) {
        if (myEventKey instanceof IEventListener) {
            this._attachSubscriber(myEventKey);

            return this;
        }

        $argCount = func_num_args();
        if ($argCount === 2) {
            this._listeners[myEventKey][static::$defaultPriority][] = [
                'callable' => myOptions,
            ];

            return this;
        }

        $priority = myOptions['priority'] ?? static::$defaultPriority;
        this._listeners[myEventKey][$priority][] = [
            'callable' => $callable,
        ];

        return this;
    }

    /**
     * Auxiliary function to attach all implemented callbacks of a Cake\Event\IEventListener class instance
     * as individual methods on this manager
     *
     * @param \Cake\Event\IEventListener $subscriber Event listener.
     * @return void
     */
    protected auto _attachSubscriber(IEventListener $subscriber): void
    {
        foreach ($subscriber.implementedEvents() as myEventKey => $function) {
            myOptions = [];
            $method = $function;
            if (is_array($function) && isset($function['callable'])) {
                [$method, myOptions] = this._extractCallable($function, $subscriber);
            } elseif (is_array($function) && is_numeric(key($function))) {
                foreach ($function as $f) {
                    [$method, myOptions] = this._extractCallable($f, $subscriber);
                    this.on(myEventKey, myOptions, $method);
                }
                continue;
            }
            if (is_string($method)) {
                $method = [$subscriber, $function];
            }
            this.on(myEventKey, myOptions, $method);
        }
    }

    /**
     * Auxiliary function to extract and return a PHP callback type out of the callable definition
     * from the return value of the `implementedEvents()` method on a {@link \Cake\Event\IEventListener}
     *
     * @param array $function the array taken from a handler definition for an event
     * @param \Cake\Event\IEventListener $object The handler object
     * @return array
     */
    protected auto _extractCallable(array $function, IEventListener $object): array
    {
        /** @var callable $method */
        $method = $function['callable'];
        myOptions = $function;
        unset(myOptions['callable']);
        if (is_string($method)) {
            /** @var callable $method */
            $method = [$object, $method];
        }

        return [$method, myOptions];
    }


    function off(myEventKey, $callable = null) {
        if (myEventKey instanceof IEventListener) {
            this._detachSubscriber(myEventKey);

            return this;
        }

        if (!is_string(myEventKey)) {
            if (!is_callable(myEventKey)) {
                throw new CakeException(
                    'First argument of EventManager::off() must be ' .
                    ' string or IEventListener instance or callable.'
                );
            }

            foreach (array_keys(this._listeners) as myName) {
                this.off(myName, myEventKey);
            }

            return this;
        }

        if ($callable instanceof IEventListener) {
            this._detachSubscriber($callable, myEventKey);

            return this;
        }

        if ($callable === null) {
            unset(this._listeners[myEventKey]);

            return this;
        }

        if (empty(this._listeners[myEventKey])) {
            return this;
        }

        foreach (this._listeners[myEventKey] as $priority => $callables) {
            foreach ($callables as $k => $callback) {
                if ($callback['callable'] === $callable) {
                    unset(this._listeners[myEventKey][$priority][$k]);
                    break;
                }
            }
        }

        return this;
    }

    /**
     * Auxiliary function to help detach all listeners provided by an object implementing IEventListener
     *
     * @param \Cake\Event\IEventListener $subscriber the subscriber to be detached
     * @param string|null myEventKey optional event key name to unsubscribe the listener from
     * @return void
     */
    protected auto _detachSubscriber(IEventListener $subscriber, ?string myEventKey = null): void
    {
        myEvents = $subscriber.implementedEvents();
        if (!empty(myEventKey) && empty(myEvents[myEventKey])) {
            return;
        }
        if (!empty(myEventKey)) {
            myEvents = [myEventKey => myEvents[myEventKey]];
        }
        foreach (myEvents as myKey => $function) {
            if (is_array($function)) {
                if (is_numeric(key($function))) {
                    foreach ($function as $handler) {
                        $handler = $handler['callable'] ?? $handler;
                        this.off(myKey, [$subscriber, $handler]);
                    }
                    continue;
                }
                $function = $function['callable'];
            }
            this.off(myKey, [$subscriber, $function]);
        }
    }


    function dispatch(myEvent): IEvent
    {
        if (is_string(myEvent)) {
            myEvent = new Event(myEvent);
        }

        $listeners = this.listeners(myEvent.getName());

        if (this._trackEvents) {
            this.addEventToList(myEvent);
        }

        if (!this._isGlobal && static::instance().isTrackingEvents()) {
            static::instance().addEventToList(myEvent);
        }

        if (empty($listeners)) {
            return myEvent;
        }

        foreach ($listeners as $listener) {
            if (myEvent.isStopped()) {
                break;
            }
            myResult = this._callListener($listener['callable'], myEvent);
            if (myResult === false) {
                myEvent.stopPropagation();
            }
            if (myResult !== null) {
                myEvent.setResult(myResult);
            }
        }

        return myEvent;
    }

    /**
     * Calls a listener.
     *
     * @param callable $listener The listener to trigger.
     * @param \Cake\Event\IEvent myEvent Event instance.
     * @return mixed The result of the $listener function.
     */
    protected auto _callListener(callable $listener, IEvent myEvent) {
        myData = (array)myEvent.getData();

        return $listener(myEvent, ...array_values(myData));
    }


    function listeners(string myEventKey): array
    {
        $localListeners = [];
        if (!this._isGlobal) {
            $localListeners = this.prioritisedListeners(myEventKey);
            $localListeners = empty($localListeners) ? [] : $localListeners;
        }
        $globalListeners = static::instance().prioritisedListeners(myEventKey);
        $globalListeners = empty($globalListeners) ? [] : $globalListeners;

        $priorities = array_merge(array_keys($globalListeners), array_keys($localListeners));
        $priorities = array_unique($priorities);
        asort($priorities);

        myResult = [];
        foreach ($priorities as $priority) {
            if (isset($globalListeners[$priority])) {
                myResult = array_merge(myResult, $globalListeners[$priority]);
            }
            if (isset($localListeners[$priority])) {
                myResult = array_merge(myResult, $localListeners[$priority]);
            }
        }

        return myResult;
    }

    /**
     * Returns the listeners for the specified event key indexed by priority
     *
     * @param string myEventKey Event key.
     * @return array
     */
    function prioritisedListeners(string myEventKey): array
    {
        if (empty(this._listeners[myEventKey])) {
            return [];
        }

        return this._listeners[myEventKey];
    }

    /**
     * Returns the listeners matching a specified pattern
     *
     * @param string myEventKeyPattern Pattern to match.
     * @return array
     */
    function matchingListeners(string myEventKeyPattern): array
    {
        $matchPattern = '/' . preg_quote(myEventKeyPattern, '/') . '/';
        $matches = array_intersect_key(
            this._listeners,
            array_flip(
                preg_grep($matchPattern, array_keys(this._listeners), 0)
            )
        );

        return $matches;
    }

    /**
     * Returns the event list.
     *
     * @return \Cake\Event\EventList|null
     */
    auto getEventList(): ?EventList
    {
        return this._eventList;
    }

    /**
     * Adds an event to the list if the event list object is present.
     *
     * @param \Cake\Event\IEvent myEvent An event to add to the list.
     * @return this
     */
    function addEventToList(IEvent myEvent) {
        if (this._eventList) {
            this._eventList.add(myEvent);
        }

        return this;
    }

    /**
     * Enables / disables event tracking at runtime.
     *
     * @param bool myEnabled True or false to enable / disable it.
     * @return this
     */
    function trackEvents(bool myEnabled) {
        this._trackEvents = myEnabled;

        return this;
    }

    /**
     * Returns whether this manager is set up to track events
     */
    bool isTrackingEvents() {
        return this._trackEvents && this._eventList;
    }

    /**
     * Enables the listing of dispatched events.
     *
     * @param \Cake\Event\EventList myEventList The event list object to use.
     * @return this
     */
    auto setEventList(EventList myEventList) {
        this._eventList = myEventList;
        this._trackEvents = true;

        return this;
    }

    /**
     * Disables the listing of dispatched events.
     *
     * @return this
     */
    function unsetEventList() {
        this._eventList = null;
        this._trackEvents = false;

        return this;
    }

    /**
     * Debug friendly object properties.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        $properties = get_object_vars(this);
        $properties['_generalManager'] = '(object) EventManager';
        $properties['_listeners'] = [];
        foreach (this._listeners as myKey => $priorities) {
            $listenerCount = 0;
            foreach ($priorities as $listeners) {
                $listenerCount += count($listeners);
            }
            $properties['_listeners'][myKey] = $listenerCount . ' listener(s)';
        }
        if (this._eventList) {
            myCount = count(this._eventList);
            for ($i = 0; $i < myCount; $i++) {
                myEvent = this._eventList[$i];
                try {
                    $subject = myEvent.getSubject();
                    $properties['_dispatchedEvents'][] = myEvent.getName() . ' with subject ' . get_class($subject);
                } catch (CakeException $e) {
                    $properties['_dispatchedEvents'][] = myEvent.getName() . ' with no subject';
                }
            }
        } else {
            $properties['_dispatchedEvents'] = null;
        }
        unset($properties['_eventList']);

        return $properties;
    }
}
