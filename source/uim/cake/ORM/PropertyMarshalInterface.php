


 *


 * @since         3.4.0
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
     * @param uim.cake.ORM\Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> $options The options array used in the marshalling call.
     * @return array A map of `[property: callable]` of additional properties to marshal.
     */
    function buildMarshalMap(Marshaller $marshaller, array $map, array $options): array;
}
