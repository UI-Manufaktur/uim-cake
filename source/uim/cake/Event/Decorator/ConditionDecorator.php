

/**
 * CakePHP : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Event\Decorator;

import uim.cake.Event\IEvent;
use RuntimeException;

/**
 * Event Condition Decorator
 *
 * Use this decorator to allow your event listener to only
 * be invoked if the `if` and/or `unless` conditions pass.
 */
class ConditionDecorator : AbstractDecorator
{

    auto __invoke() {
        $args = func_get_args();
        if (!this.canTrigger($args[0])) {
            return;
        }

        return this._call($args);
    }

    /**
     * Checks if the event is triggered for this listener.
     *
     * @param \Cake\Event\IEvent myEvent Event object.
     * @return bool
     */
    bool canTrigger(IEvent myEvent) {
        $if = this._evaluateCondition('if', myEvent);
        $unless = this._evaluateCondition('unless', myEvent);

        return $if && !$unless;
    }

    /**
     * Evaluates the filter conditions
     *
     * @param string $condition Condition type
     * @param \Cake\Event\IEvent myEvent Event object
     * @return bool
     */
    protected bool _evaluateCondition(string $condition, IEvent myEvent) {
        if (!isset(this._options[$condition])) {
            return $condition !== 'unless';
        }
        if (!is_callable(this._options[$condition])) {
            throw new RuntimeException(self::class . ' the `' . $condition . '` condition is not a callable!');
        }

        return (bool)this._options[$condition](myEvent);
    }
}
