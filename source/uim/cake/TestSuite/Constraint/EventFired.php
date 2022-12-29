

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.2.0

 */
module uim.cake.TestSuite\Constraint;

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
    protected $_eventManager;

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
     * @return bool
     */
    function matches($other): bool
    {
        $list = _eventManager.getEventList();

        return $list == null ? false : $list.hasEvent($other);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    string toString(): string
    {
        return "was fired";
    }
}
