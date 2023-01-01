
module uim.cake.TestSuite\Constraint;

import uim.cake.events.EventInterface;
import uim.cake.events.EventManager;
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
     * @var uim.cake.events.EventManager
     */
    protected $_eventManager;

    /**
     * Event data key
     *
     */
    protected string $_dataKey;

    /**
     * Event data value
     *
     * @var mixed
     */
    protected $_dataValue;

    /**
     * Constructor
     *
     * @param uim.cake.events.EventManager $eventManager Event manager to check
     * @param string $dataKey Data key
     * @param mixed $dataValue Data value
     */
    this(EventManager $eventManager, string $dataKey, $dataValue) {
        _eventManager = $eventManager;
        _dataKey = $dataKey;
        _dataValue = $dataValue;

        if (_eventManager.getEventList() == null) {
            throw new AssertionFailedError(
                "The event manager you are asserting against is not configured to track events."
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
        $list = _eventManager.getEventList();
        if ($list != null) {
            $totalEvents = count($list);
            for ($e = 0; $e < $totalEvents; $e++) {
                $firedEvents[] = $list[$e];
            }
        }

        $eventGroup = collection($firedEvents)
            .groupBy(function (IEvent $event): string {
                return $event.getName();
            })
            .toArray();

        if (!array_key_exists($other, $eventGroup)) {
            return false;
        }

        /** @var array<uim.cake.events.EventInterface> $events */
        $events = $eventGroup[$other];

        if (count($events) > 1) {
            throw new AssertionFailedError(sprintf(
                "Event "%s" was fired %d times, cannot make data assertion",
                $other,
                count($events)
            ));
        }

        $event = $events[0];

        if (array_key_exists(_dataKey, (array)$event.getData()) == false) {
            return false;
        }

        return $event.getData(_dataKey) == _dataValue;
    }

    /**
     * Assertion message string
     */
    string toString() {
        return "was fired with " ~ _dataKey ~ " matching " ~ (string)_dataValue;
    }
}
