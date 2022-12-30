


 *


 * @since         3.0.10
  */
module uim.cake.Event;

/**
 * : Cake\events.EventDispatcherInterface.
 */
trait EventDispatcherTrait
{
    /**
     * Instance of the Cake\events.EventManager this object is using
     * to dispatch inner events.
     *
     * @var uim.cake.events.IEventManager|null
     */
    protected $_eventManager;

    /**
     * Default class name for new event objects.
     *
     */
    protected string $_eventClass = Event::class;

    /**
     * Returns the Cake\events.EventManager manager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @return uim.cake.events.IEventManager
     */
    function getEventManager(): IEventManager
    {
        if (_eventManager == null) {
            _eventManager = new EventManager();
        }

        return _eventManager;
    }

    /**
     * Returns the Cake\events.IEventManager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @param uim.cake.events.IEventManager $eventManager the eventManager to set
     * @return this
     */
    function setEventManager(IEventManager $eventManager) {
        _eventManager = $eventManager;

        return this;
    }

    /**
     * Wrapper for creating and dispatching events.
     *
     * Returns a dispatched event.
     *
     * @param string $name Name of the event.
     * @param array|null $data Any value you wish to be transported with this event to
     * it can be read by listeners.
     * @param object|null $subject The object that this event applies to
     * (this by default).
     * @return uim.cake.events.EventInterface
     */
    function dispatchEvent(string $name, ?array $data = null, ?object $subject = null): EventInterface
    {
        if ($subject == null) {
            $subject = this;
        }

        /** @var uim.cake.events.IEvent $event */
        $event = new _eventClass($name, $subject, $data);
        this.getEventManager().dispatch($event);

        return $event;
    }
}
