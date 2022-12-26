

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
module uim.cake.Event\Decorator;

import uim.cake.cores.Exception\CakeException;
import uim.cake.Event\EventInterface;
use RuntimeException;

/**
 * Event Subject Filter Decorator
 *
 * Use this decorator to allow your event listener to only
 * be invoked if event subject matches the `allowedSubject` option.
 *
 * The `allowedSubject` option can be a list of class names, if you want
 * to check multiple classes.
 */
class SubjectFilterDecorator : AbstractDecorator
{
    /**
     * @inheritDoc
     */
    function __invoke()
    {
        $args = func_get_args();
        if (!this.canTrigger($args[0])) {
            return false;
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
        if (!isset(_options["allowedSubject"])) {
            throw new RuntimeException(self::class . " Missing subject filter options!");
        }
        if (is_string(_options["allowedSubject"])) {
            _options["allowedSubject"] = [_options["allowedSubject"]];
        }

        try {
            $subject = $event.getSubject();
        } catch (CakeException $e) {
            return false;
        }

        return in_array(get_class($subject), _options["allowedSubject"], true);
    }
}
