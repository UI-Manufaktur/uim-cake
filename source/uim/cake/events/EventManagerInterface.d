module uim.baklava.events;

/**
 * Interface IEventManager
 */
interface IEventManager
{
    /**
     * Adds a new listener to an event.
     *
     * A variadic interface to add listeners that emulates jQuery.on().
     *
     * Binding an IEventListener:
     *
     * ```
     * myEventManager.on($listener);
     * ```
     *
     * Binding with no options:
     *
     * ```
     * myEventManager.on('Model.beforeSave', $callable);
     * ```
     *
     * Binding with options:
     *
     * ```
     * myEventManager.on('Model.beforeSave', ['priority' => 90], $callable);
     * ```
     *
     * @param \Cake\Event\IEventListener|string myEventKey The event unique identifier name
     * with which the callback will be associated. If myEventKey is an instance of
     * Cake\Event\IEventListener its events will be bound using the `implementedEvents()` methods.
     *
     * @param callable|array myOptions Either an array of options or the callable you wish to
     * bind to myEventKey. If an array of options, the `priority` key can be used to define the order.
     * Priorities are treated as queues. Lower values are called before higher ones, and multiple attachments
     * added to the same priority queue will be treated in the order of insertion.
     *
     * @param callable|null $callable The callable function you want invoked.
     * @return this
     * @throws \InvalidArgumentException When event key is missing or callable is not an
     *   instance of Cake\Event\IEventListener.
     */
    function on(myEventKey, myOptions = [], ?callable $callable = null);

    /**
     * Remove a listener from the active listeners.
     *
     * Remove a IEventListener entirely:
     *
     * ```
     * $manager.off($listener);
     * ```
     *
     * Remove all listeners for a given event:
     *
     * ```
     * $manager.off('My.event');
     * ```
     *
     * Remove a specific listener:
     *
     * ```
     * $manager.off('My.event', $callback);
     * ```
     *
     * Remove a callback from all events:
     *
     * ```
     * $manager.off($callback);
     * ```
     *
     * @param \Cake\Event\IEventListener|callable|string myEventKey The event unique identifier name
     *   with which the callback has been associated, or the $listener you want to remove.
     * @param \Cake\Event\IEventListener|callable|null $callable The callback you want to detach.
     * @return this
     */
    function off(myEventKey, $callable = null);

    /**
     * Dispatches a new event to all configured listeners
     *
     * @param \Cake\Event\IEvent|string myEvent The event key name or instance of IEvent.
     * @return \Cake\Event\IEvent
     * @triggers myEvent
     */
    function dispatch(myEvent): IEvent;

    /**
     * Returns a list of all listeners for an eventKey in the order they should be called
     *
     * @param string myEventKey Event key.
     * @return array
     */
    function listeners(string myEventKey): array;
}
