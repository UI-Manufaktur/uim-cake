


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Routing\Route;

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
    function match(array $url, array $context = []): ?string
    {
        if (empty(_compiledRoute)) {
            this.compile();
        }

        if (isset($url['_entity'])) {
            $entity = $url['_entity'];
            _checkEntity($entity);

            foreach (this.keys as $field) {
                if (!isset($url[$field]) && isset($entity[$field])) {
                    $url[$field] = $entity[$field];
                }
            }
        }

        return parent::match($url, $context);
    }

    /**
     * Checks that we really deal with an entity object
     *
     * @throws \RuntimeException
     * @param \ArrayAccess|array $entity Entity value from the URL options
     * @return void
     */
    protected function _checkEntity($entity): void
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
