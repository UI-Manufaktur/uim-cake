module uim.baklava.routings\Route;

use ArrayAccess;
use RuntimeException;

/**
 * Matches entities to routes
 *
 * This route will match by entity and map its fields to the URL pattern by
 * comparing the field names with the template vars. This makes it easy and
 * convenient to change routes globally.
 */
class EntityRoute : Route
{
    /**
     * Match by entity and map its fields to the URL pattern by comparing the
     * field names with the template vars.
     *
     * If a routing key is defined in both `myUrl` and the entity, the value defined
     * in `myUrl` will be preferred.
     *
     * @param array myUrl Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL or null.
     */
    function match(array myUrl, array $context = []): Nullable!string
    {
        if (empty(this._compiledRoute)) {
            this.compile();
        }

        if (isset(myUrl['_entity'])) {
            $entity = myUrl['_entity'];
            this._checkEntity($entity);

            foreach (this.keys as myField) {
                if (!isset(myUrl[myField]) && isset($entity[myField])) {
                    myUrl[myField] = $entity[myField];
                }
            }
        }

        return super.match(myUrl, $context);
    }

    /**
     * Checks that we really deal with an entity object
     *
     * @throws \RuntimeException
     * @param \ArrayAccess|array $entity Entity value from the URL options
     * @return void
     */
    protected auto _checkEntity($entity): void
    {
        if (!$entity instanceof ArrayAccess && !is_array($entity)) {
            throw new RuntimeException(sprintf(
                'Route `%s` expects the URL option `_entity` to be an array or object implementing \ArrayAccess, '
                . 'but `%s` passed.',
                this.template,
                getTypeName($entity)
            ));
        }
    }
}
