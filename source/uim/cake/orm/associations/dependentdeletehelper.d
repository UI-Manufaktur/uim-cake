/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.associations.dependentdeletehelper;

@safe:
import uim.cake;

/**
 * Helper class for cascading deletes in associations.
 *
 * @internal
 */
class DependentDeleteHelper
{
    /**
     * Cascade a delete to remove dependent records.
     *
     * This method does nothing if the association is not dependent.
     *
     * @param uim.cake.orm.Association $association The association callbacks are being cascaded on.
     * @param uim.cake.Datasource\IEntity $entity The entity that started the cascaded delete.
     * @param array<string, mixed> $options The options for the original delete.
     * @return bool Success.
     */
    function cascadeDelete(Association $association, IEntity $entity, array $options = []): bool
    {
        if (!$association.getDependent()) {
            return true;
        }
        $table = $association.getTarget();
        /** @psalm-suppress InvalidArgument */
        $foreignKey = array_map([$association, "aliasField"], (array)$association.getForeignKey());
        $bindingKey = (array)$association.getBindingKey();
        $bindingValue = $entity.extract($bindingKey);
        if (in_array(null, $bindingValue, true)) {
            return true;
        }
        $conditions = array_combine($foreignKey, $bindingValue);

        if ($association.getCascadeCallbacks()) {
            foreach ($association.find().where($conditions).all().toList() as $related) {
                $success = $table.delete($related, $options);
                if (!$success) {
                    return false;
                }
            }

            return true;
        }

        $association.deleteAll($conditions);

        return true;
    }
}
