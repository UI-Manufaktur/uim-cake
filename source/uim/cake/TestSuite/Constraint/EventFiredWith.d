
module uim.cake.TestSuite\Constraint;

import uim.cake.Event\IEvent;
import uim.cake.Event\EventManager;
use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * EventFiredWith constraint
 *
 * @internal
 */
class EventFiredWith : Constraint
{
    /**
     * Array of fired events
     *
     * @var \Cake\Event\EventManager
     */
    protected $_eventManager;

    /**
     * Event data key
     *
     * @var string
     */
    protected $_dataKey;

    /**
     * Event data value
     *
     * @var mixed
     */
    protected $_dataValue;

    /**
     * Constructor
     *
     * @param \Cake\Event\EventManager myEventManager Event manager to check
     * @param string myDataKey Data key
     * @param mixed myDataValue Data value
     */
    this(EventManager myEventManager, string myDataKey, myDataValue) {
        this._eventManager = myEventManager;
        this._dataKey = myDataKey;
        this._dataValue = myDataValue;

        if (this._eventManager.getEventList() === null) {
            throw new AssertionFailedError(
                'The event manager you are asserting against is not configured to track events.'
            );
        }
    }

    /**
     * Checks if event is in fired array
     *
     * @param mixed $other Constraint check
     * @return bool
     * @throws \PHPUnit\Framework\AssertionFailedError
     */
    function matches($other): bool
    {
        $firedEvents = [];
        $list = this._eventManager.getEventList();
        if ($list !== null) {
            $totalEvents = count($list);
            for ($e = 0; $e < $totalEvents; $e++) {
                $firedEvents[] = $list[$e];
            }
        }

        myEventGroup = collection($firedEvents)
            .groupBy(function (IEvent myEvent): string {
                return myEvent.getName();
            })
            .toArray();

        if (!array_key_exists($other, myEventGroup)) {
            return false;
        }

        /** @var array<\Cake\Event\IEvent> myEvents */
        myEvents = myEventGroup[$other];

        if (count(myEvents) > 1) {
            throw new AssertionFailedError(sprintf(
                'Event "%s" was fired %d times, cannot make data assertion',
                $other,
                count(myEvents)
            ));
        }

        myEvent = myEvents[0];

        if (array_key_exists(this._dataKey, (array)myEvent.getData()) === false) {
            return false;
        }

        return myEvent.getData(this._dataKey) === this._dataValue;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    string toString() {
        return 'was fired with ' . this._dataKey . ' matching ' . (string)this._dataValue;
    }
}
