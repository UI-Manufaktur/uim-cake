module uim.cake.Event;

/**
 * Objects implementing this interface can emit events.
 *
 * Objects with this interface can trigger events, and have
 * an event manager retrieved from them.
 *
 * The {@link \Cake\Event\EventDispatcherTrait} lets you easily implement
 * this interface.
 */
interface IEventDispatcher
{
    /**
     * Wrapper for creating and dispatching events.
     *
     * Returns a dispatched event.
     *
     * @param string myName Name of the event.
     * @param array|null myData Any value you wish to be transported with this event to
     * it can be read by listeners.
     * @param object|null $subject The object that this event applies to
     * (this by default).
     * @return \Cake\Event\IEvent
     */
    function dispatchEvent(string myName, ?array myData = null, ?object $subject = null): IEvent;

    /**
     * Sets the Cake\Event\EventManager manager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @param \Cake\Event\IEventManager myEventManager the eventManager to set
     * @return this
     */
    auto setEventManager(IEventManager myEventManager);

    /**
     * Returns the Cake\Event\EventManager manager instance for this object.
     *
     * @return \Cake\Event\IEventManager
     */
    auto getEventManager(): IEventManager;
}
