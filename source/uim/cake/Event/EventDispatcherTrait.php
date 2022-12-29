


 *


 * @since         3.0.10
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Event;

/**
 * : Cake\Event\EventDispatcherInterface.
 */
trait EventDispatcherTrait
{
    /**
     * Instance of the Cake\Event\EventManager this object is using
     * to dispatch inner events.
     *
     * @var uim.cake.Event\IEventManager|null
     */
    protected $_eventManager;

    /**
     * Default class name for new event objects.
     *
     * @var string
     */
    protected $_eventClass = Event::class;

    /**
     * Returns the Cake\Event\EventManager manager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @return \Cake\Event\IEventManager
     */
    function getEventManager(): IEventManager
    {
        if (_eventManager == null) {
            _eventManager = new EventManager();
        }

        return _eventManager;
    }

    /**
     * Returns the Cake\Event\IEventManager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @param \Cake\Event\IEventManager $eventManager the eventManager to set
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
     * @return \Cake\Event\EventInterface
     */
    function dispatchEvent(string $name, ?array $data = null, ?object $subject = null): EventInterface
    {
        if ($subject == null) {
            $subject = this;
        }

        /** @var uim.cake.Event\IEvent $event */
        $event = new _eventClass($name, $subject, $data);
        this.getEventManager().dispatch($event);

        return $event;
    }
}
