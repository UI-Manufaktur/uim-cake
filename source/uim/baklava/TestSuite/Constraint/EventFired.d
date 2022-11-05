

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.2.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint;

import uim.baklava.events\EventManager;
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
     * @var \Cake\Event\EventManager
     */
    protected $_eventManager;

    /**
     * Constructor
     *
     * @param \Cake\Event\EventManager myEventManager Event manager to check
     */
    this(EventManager myEventManager) {
        this._eventManager = myEventManager;

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
     */
    function matches($other): bool
    {
        $list = this._eventManager.getEventList();

        return $list === null ? false : $list.hasEvent($other);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        return 'was fired';
    }
}