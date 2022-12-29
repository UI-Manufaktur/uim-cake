module uim.cake.orm.associations;

import uim.cake.datasources\IEntity;
import uim.cake.orm.associations;

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
     * @param uim.cake.ORM\Association $association The association callbacks are being cascaded on.
     * @param uim.cake.Datasource\IEntity $entity The entity that started the cascaded delete.
     * @param array<string, mixed> myOptions The options for the original delete.
     * @return bool Success.
     */
    bool cascadeDelete(Association $association, IEntity $entity, array myOptions = []) {
        if (!$association.getDependent()) {
            return true;
        }
        myTable = $association.getTarget();
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
                $success = myTable.delete($related, myOptions);
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
