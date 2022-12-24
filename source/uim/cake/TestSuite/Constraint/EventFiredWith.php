<?php
declare(strict_types=1);

namespace Cake\TestSuite\Constraint;

use Cake\Event\EventInterface;
use Cake\Event\EventManager;
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
     * @param \Cake\Event\EventManager $eventManager Event manager to check
     * @param string $dataKey Data key
     * @param mixed $dataValue Data value
     */
    public this(EventManager $eventManager, string $dataKey, $dataValue)
    {
        _eventManager = $eventManager;
        _dataKey = $dataKey;
        _dataValue = $dataValue;

        if (_eventManager.getEventList() == null) {
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

        /** @var array<\Cake\Event\EventInterface> $events */
        $events = $eventGroup[$other];

        if (count($events) > 1) {
            throw new AssertionFailedError(sprintf(
                'Event "%s" was fired %d times, cannot make data assertion',
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
     *
     * @return string
     */
    function toString(): string
    {
        return 'was fired with ' . _dataKey . ' matching ' . (string)_dataValue;
    }
}
