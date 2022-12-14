



 */module uim.cake.TestSuite\Constraint;

import uim.cake.events.EventManager;
use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * EventFired constraint
 *
 * @internal
 */
class EventFired : Constraint
{
    /**
     * Array of fired events
     *
     * @var uim.cake.events.EventManager
     */
    protected _eventManager;

    /**
     * Constructor
     *
     * @param uim.cake.events.EventManager $eventManager Event manager to check
     */
    this(EventManager $eventManager) {
        _eventManager = $eventManager;

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
     */
    bool matches($other) {
        $list = _eventManager.getEventList();

        return $list == null ? false : $list.hasEvent($other);
    }

    /**
     * Assertion message string
     */
    string toString() {
        return "was fired";
    }
}
