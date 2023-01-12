/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.events.Decorator;

import uim.cake.events.IEvent;
use RuntimeException;

/**
 * Event Condition Decorator
 *
 * Use this decorator to allow your event listener to only
 * be invoked if the `if` and/or `unless` conditions pass.
 */
class ConditionDecorator : AbstractDecorator
{

    function __invoke() {
        $args = func_get_args();
        if (!this.canTrigger($args[0])) {
            return;
        }

        return _call($args);
    }

    /**
     * Checks if the event is triggered for this listener.
     *
     * @param uim.cake.events.IEvent $event Event object.
     */
    bool canTrigger(IEvent $event) {
        $if = _evaluateCondition("if", $event);
        $unless = _evaluateCondition("unless", $event);

        return $if && !$unless;
    }

    /**
     * Evaluates the filter conditions
     *
     * @param string $condition Condition type
     * @param uim.cake.events.IEvent $event Event object
     */
    protected bool _evaluateCondition(string $condition, IEvent $event) {
        if (!isset(_options[$condition])) {
            return $condition != "unless";
        }
        if (!is_callable(_options[$condition])) {
            throw new RuntimeException(self::class ~ " the `" ~ $condition ~ "` condition is not a callable!");
        }

        return (bool)_options[$condition]($event);
    }
}
