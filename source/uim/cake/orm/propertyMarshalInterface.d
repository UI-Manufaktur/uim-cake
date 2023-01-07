/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.orm;

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
     * @param uim.cake.orm.Marshaller $marshaller The marhshaller of the table the behavior is attached to.
     * @param array $map The property map being built.
     * @param array<string, mixed> $options The options array used in the marshalling call.
     * @return array A map of `[property: callable]` of additional properties to marshal.
     */
    array buildMarshalMap(Marshaller $marshaller, array $map, array $options);
}
