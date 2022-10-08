

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.10
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Event;

/**
 * : Cake\Event\IEventDispatcher.
 */
trait EventDispatcherTrait
{
    /**
     * Instance of the Cake\Event\EventManager this object is using
     * to dispatch inner events.
     *
     * @var \Cake\Event\IEventManager|null
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
    auto getEventManager(): IEventManager
    {
        if (this._eventManager === null) {
            this._eventManager = new EventManager();
        }

        return this._eventManager;
    }

    /**
     * Returns the Cake\Event\IEventManager instance for this object.
     *
     * You can use this instance to register any new listeners or callbacks to the
     * object events, or create your own events and trigger them at will.
     *
     * @param \Cake\Event\IEventManager myEventManager the eventManager to set
     * @return this
     */
    auto setEventManager(IEventManager myEventManager) {
        this._eventManager = myEventManager;

        return this;
    }

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
    function dispatchEvent(string myName, ?array myData = null, ?object $subject = null): IEvent
    {
        if ($subject === null) {
            $subject = this;
        }

        /** @var \Cake\Event\IEvent myEvent */
        myEvent = new this._eventClass(myName, $subject, myData);
        this.getEventManager().dispatch(myEvent);

        return myEvent;
    }
}
