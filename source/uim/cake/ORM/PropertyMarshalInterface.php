


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM;

/**
 * Behaviors implementing this interface can participate in entity marshalling.
 *
 * This enables behaviors to define behavior for how the properties they provide/manage
 * should be marshalled.
 */
interface PropertyMarshalInterface
{
    /**
     * Build a set of properties that should be included in the marshalling process.
     *
     * @param \Cake\ORM\Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> $options The options array used in the marshalling call.
     * @return array A map of `[property: callable]` of additional properties to marshal.
     */
    function buildMarshalMap(Marshaller $marshaller, array $map, array $options): array;
}
