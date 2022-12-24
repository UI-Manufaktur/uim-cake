<?php
declare(strict_types=1);

/**
 * CakePHP : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Event\Decorator;

use Cake\Event\EventInterface;
use RuntimeException;

/**
 * Event Condition Decorator
 *
 * Use this decorator to allow your event listener to only
 * be invoked if the `if` and/or `unless` conditions pass.
 */
class ConditionDecorator : AbstractDecorator
{
    /**
     * @inheritDoc
     */
    function __invoke()
    {
        $args = func_get_args();
        if (!this.canTrigger($args[0])) {
            return;
        }

        return _call($args);
    }

    /**
     * Checks if the event is triggered for this listener.
     *
     * @param \Cake\Event\IEvent $event Event object.
     * @return bool
     */
    function canTrigger(IEvent $event): bool
    {
        $if = _evaluateCondition('if', $event);
        $unless = _evaluateCondition('unless', $event);

        return $if && !$unless;
    }

    /**
     * Evaluates the filter conditions
     *
     * @param string $condition Condition type
     * @param \Cake\Event\IEvent $event Event object
     * @return bool
     */
    protected function _evaluateCondition(string $condition, IEvent $event): bool
    {
        if (!isset(_options[$condition])) {
            return $condition != 'unless';
        }
        if (!is_callable(_options[$condition])) {
            throw new RuntimeException(self::class . ' the `' . $condition . '` condition is not a callable!');
        }

        return (bool)_options[$condition]($event);
    }
}
