module uim.cake.routings.Route;

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
     * If a routing key is defined in both `$url` and the entity, the value defined
     * in `$url` will be preferred.
     *
     * @param array $url Array of parameters to convert to a string.
     * @param array $context An array of the current request context.
     *   Contains information such as the current host, scheme, port, and base
     *   directory.
     * @return string|null Either a string URL or null.
     */
    Nullable!string match(array $url, array $context = null) {
        if (empty(_compiledRoute)) {
            this.compile();
        }

        if (isset($url["_entity"])) {
            $entity = $url["_entity"];
            _checkEntity($entity);

            foreach (this.keys as $field) {
                if (!isset($url[$field]) && isset($entity[$field])) {
                    $url[$field] = $entity[$field];
                }
            }
        }

        return super.match($url, $context);
    }

    /**
     * Checks that we really deal with an entity object
     *
     * @throws \RuntimeException
     * @param \ArrayAccess|array $entity Entity value from the URL options
     */
    protected void _checkEntity($entity) {
        if (!$entity instanceof ArrayAccess && !is_array($entity)) {
            throw new RuntimeException(sprintf(
                "Route `%s` expects the URL option `_entity` to be an array or object implementing \ArrayAccess, "
                ~ "but `%s` passed.",
                this.template,
                getTypeName($entity)
            ));
        }
    }
}
