


 *


 * @since         2.1.0
  */module uim.cake.Event;

import uim.cake.core.exceptions.CakeException;

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
     * @var uim.cake.events.EventManager|null
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
     */
    protected bool $_isGlobal = false;

    /**
     * The event list object.
     *
     * @var uim.cake.events.EventList|null
     */
    protected $_eventList;

    /**
     * Enables automatic adding of events to the event list object if it is present.
     *
     */
    protected bool $_trackEvents = false;

    /**
     * Returns the globally available instance of a Cake\events.EventManager
     * this is used for dispatching events attached from outside the scope
     * other managers were created. Usually for creating hook systems or inter-class
     * communication
     *
     * If called with the first parameter, it will be set as the globally available instance
     *
     * @param uim.cake.events.EventManager|null $manager Event manager instance.
     * @return uim.cake.events.EventManager The global event manager
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


    function on($eventKey, $options = [], ?callable $callable = null) {
        if ($eventKey instanceof IEventListener) {
            _attachSubscriber($eventKey);

            return this;
        }

        $argCount = func_num_args();
        if ($argCount == 2) {
            _listeners[$eventKey][static::$defaultPriority][] = [
                "callable": $options,
            ];

            return this;
        }

        $priority = $options["priority"] ?? static::$defaultPriority;
        _listeners[$eventKey][$priority][] = [
            "callable": $callable,
        ];

        return this;
    }

    /**
     * Auxiliary function to attach all implemented callbacks of a Cake\events.IEventListener class instance
     * as individual methods on this manager
     *
     * @param uim.cake.events.IEventListener $subscriber Event listener.
     */
    protected void _attachSubscriber(IEventListener $subscriber): void
    {
        foreach ($subscriber.implementedEvents() as $eventKey: $function) {
            $options = [];
            $method = $function;
            if (is_array($function) && isset($function["callable"])) {
                [$method, $options] = _extractCallable($function, $subscriber);
            } elseif (is_array($function) && is_numeric(key($function))) {
                foreach ($function as $f) {
                    [$method, $options] = _extractCallable($f, $subscriber);
                    this.on($eventKey, $options, $method);
                }
                continue;
            }
            if (is_string($method)) {
                $method = [$subscriber, $function];
            }
            this.on($eventKey, $options, $method);
        }
    }

    /**
     * Auxiliary function to extract and return a PHP callback type out of the callable definition
     * from the return value of the `implementedEvents()` method on a {@link uim.cake.events.IEventListener}
     *
     * @param array $function the array taken from a handler definition for an event
     * @param uim.cake.events.IEventListener $object The handler object
     * @return array
     */
    protected function _extractCallable(array $function, IEventListener $object): array
    {
        /** @var callable $method */
        $method = $function["callable"];
        $options = $function;
        unset($options["callable"]);
        if (is_string($method)) {
            /** @var callable $method */
            $method = [$object, $method];
        }

        return [$method, $options];
    }


    function off($eventKey, $callable = null) {
        if ($eventKey instanceof IEventListener) {
            _detachSubscriber($eventKey);

            return this;
        }

        if (!is_string($eventKey)) {
            if (!is_callable($eventKey)) {
                throw new CakeException(
                    "First argument of EventManager::off() must be " ~
                    " string or IEventListener instance or callable."
                );
            }

            foreach (array_keys(_listeners) as $name) {
                this.off($name, $eventKey);
            }

            return this;
        }

        if ($callable instanceof IEventListener) {
            _detachSubscriber($callable, $eventKey);

            return this;
        }

        if ($callable == null) {
            unset(_listeners[$eventKey]);

            return this;
        }

        if (empty(_listeners[$eventKey])) {
            return this;
        }

        foreach (_listeners[$eventKey] as $priority: $callables) {
            foreach ($callables as $k: $callback) {
                if ($callback["callable"] == $callable) {
                    unset(_listeners[$eventKey][$priority][$k]);
                    break;
                }
            }
        }

        return this;
    }

    /**
     * Auxiliary function to help detach all listeners provided by an object implementing IEventListener
     *
     * @param uim.cake.events.IEventListener $subscriber the subscriber to be detached
     * @param string|null $eventKey optional event key name to unsubscribe the listener from
     */
    protected void _detachSubscriber(IEventListener $subscriber, ?string $eventKey = null): void
    {
        $events = $subscriber.implementedEvents();
        if (!empty($eventKey) && empty($events[$eventKey])) {
            return;
        }
        if (!empty($eventKey)) {
            $events = [$eventKey: $events[$eventKey]];
        }
        foreach ($events as $key: $function) {
            if (is_array($function)) {
                if (is_numeric(key($function))) {
                    foreach ($function as $handler) {
                        $handler = $handler["callable"] ?? $handler;
                        this.off($key, [$subscriber, $handler]);
                    }
                    continue;
                }
                $function = $function["callable"];
            }
            this.off($key, [$subscriber, $function]);
        }
    }


    function dispatch($event): EventInterface
    {
        if (is_string($event)) {
            $event = new Event($event);
        }

        $listeners = this.listeners($event.getName());

        if (_trackEvents) {
            this.addEventToList($event);
        }

        if (!_isGlobal && static::instance().isTrackingEvents()) {
            static::instance().addEventToList($event);
        }

        if (empty($listeners)) {
            return $event;
        }

        foreach ($listeners as $listener) {
            if ($event.isStopped()) {
                break;
            }
            $result = _callListener($listener["callable"], $event);
            if ($result == false) {
                $event.stopPropagation();
            }
            if ($result != null) {
                $event.setResult($result);
            }
        }

        return $event;
    }

    /**
     * Calls a listener.
     *
     * @param callable $listener The listener to trigger.
     * @param uim.cake.events.IEvent $event Event instance.
     * @return mixed The result of the $listener function.
     */
    protected function _callListener(callable $listener, IEvent $event) {
        $data = (array)$event.getData();

        return $listener($event, ...array_values($data));
    }


    function listeners(string $eventKey): array
    {
        $localListeners = [];
        if (!_isGlobal) {
            $localListeners = this.prioritisedListeners($eventKey);
            $localListeners = empty($localListeners) ? [] : $localListeners;
        }
        $globalListeners = static::instance().prioritisedListeners($eventKey);
        $globalListeners = empty($globalListeners) ? [] : $globalListeners;

        $priorities = array_merge(array_keys($globalListeners), array_keys($localListeners));
        $priorities = array_unique($priorities);
        asort($priorities);

        $result = [];
        foreach ($priorities as $priority) {
            if (isset($globalListeners[$priority])) {
                $result = array_merge($result, $globalListeners[$priority]);
            }
            if (isset($localListeners[$priority])) {
                $result = array_merge($result, $localListeners[$priority]);
            }
        }

        return $result;
    }

    /**
     * Returns the listeners for the specified event key indexed by priority
     *
     * @param string $eventKey Event key.
     */
    array prioritisedListeners(string $eventKey): array
    {
        if (empty(_listeners[$eventKey])) {
            return [];
        }

        return _listeners[$eventKey];
    }

    /**
     * Returns the listeners matching a specified pattern
     *
     * @param string $eventKeyPattern Pattern to match.
     */
    array matchingListeners(string $eventKeyPattern): array
    {
        $matchPattern = "/" ~ preg_quote($eventKeyPattern, "/") ~ "/";

        return array_intersect_key(
            _listeners,
            array_flip(
                preg_grep($matchPattern, array_keys(_listeners), 0)
            )
        );
    }

    /**
     * Returns the event list.
     *
     * @return uim.cake.events.EventList|null
     */
    function getEventList(): ?EventList
    {
        return _eventList;
    }

    /**
     * Adds an event to the list if the event list object is present.
     *
     * @param uim.cake.events.IEvent $event An event to add to the list.
     * @return this
     */
    function addEventToList(IEvent $event) {
        if (_eventList) {
            _eventList.add($event);
        }

        return this;
    }

    /**
     * Enables / disables event tracking at runtime.
     *
     * @param bool $enabled True or false to enable / disable it.
     * @return this
     */
    function trackEvents(bool $enabled) {
        _trackEvents = $enabled;

        return this;
    }

    /**
     * Returns whether this manager is set up to track events
     *
     */
    bool isTrackingEvents(): bool
    {
        return _trackEvents && _eventList;
    }

    /**
     * Enables the listing of dispatched events.
     *
     * @param uim.cake.events.EventList $eventList The event list object to use.
     * @return this
     */
    function setEventList(EventList $eventList) {
        _eventList = $eventList;
        _trackEvents = true;

        return this;
    }

    /**
     * Disables the listing of dispatched events.
     *
     * @return this
     */
    function unsetEventList() {
        _eventList = null;
        _trackEvents = false;

        return this;
    }

    /**
     * Debug friendly object properties.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        $properties = get_object_vars(this);
        $properties["_generalManager"] = "(object) EventManager";
        $properties["_listeners"] = [];
        foreach (_listeners as $key: $priorities) {
            $listenerCount = 0;
            foreach ($priorities as $listeners) {
                $listenerCount += count($listeners);
            }
            $properties["_listeners"][$key] = $listenerCount ~ " listener(s)";
        }
        if (_eventList) {
            $count = count(_eventList);
            for ($i = 0; $i < $count; $i++) {
                $event = _eventList[$i];
                try {
                    $subject = $event.getSubject();
                    $properties["_dispatchedEvents"][] = $event.getName() ~ " with subject " ~ get_class($subject);
                } catch (CakeException $e) {
                    $properties["_dispatchedEvents"][] = $event.getName() ~ " with no subject";
                }
            }
        } else {
            $properties["_dispatchedEvents"] = null;
        }
        unset($properties["_eventList"]);

        return $properties;
    }
}
