module uim.baklava.events\Decorator;

import uim.baklava.core.Exception\CakeException;
import uim.baklava.events\IEvent;
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

    auto __invoke() {
        $args = func_get_args();
        if (!this.canTrigger($args[0])) {
            return false;
        }

        return this._call($args);
    }

    /**
     * Checks if the event is triggered for this listener.
     *
     * @param \Cake\Event\IEvent myEvent Event object.
     * @return bool
     */
    function canTrigger(IEvent myEvent): bool
    {
        if (!isset(this._options['allowedSubject'])) {
            throw new RuntimeException(self::class . ' Missing subject filter options!');
        }
        if (is_string(this._options['allowedSubject'])) {
            this._options['allowedSubject'] = [this._options['allowedSubject']];
        }

        try {
            $subject = myEvent.getSubject();
        } catch (CakeException $e) {
            return false;
        }

        return in_array(get_class($subject), this._options['allowedSubject'], true);
    }
}
