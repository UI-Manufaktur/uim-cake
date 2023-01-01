


 *


 * @since         3.0.7
  */module uim.cake.Event;

/**
 * Objects implementing this interface can emit events.
 *
 * Objects with this interface can trigger events, and have
 * an event manager retrieved from them.
 *
 * The {@link uim.cake.events.EventDispatcherTrait} lets you easily implement
 * this interface.
 */
interface EventDispatcherInterface
{
    /**
     * Wrapper for creating and dispatching events.
     *
     * Returns a dispatched event.
     *
     * @param string aName Name of the event.
     * @param array|null $data Any value you wish to be transported with this event to
     * it can be read by listeners.
     * @param object|null $subject The object that this event applies to
     * (this by default).
     * @return uim.cake.events.EventInterface
     */
    function dispatchEvent(string aName, ?array $data = null, ?object $subject = null): EventInterface;

    /**
     * Sets the Cake\events.EventManager manager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @param uim.cake.events.IEventManager $eventManager the eventManager to set
     * @return this
     */
    function setEventManager(IEventManager $eventManager);

    /**
     * Returns the Cake\events.EventManager manager instance for this object.
     *
     * @return uim.cake.events.IEventManager
     */
    function getEventManager(): IEventManager;
}