


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Association;

import uim.cake.Datasource\EntityInterface;
import uim.cake.ORM\Association;

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
     * @param \Cake\ORM\Association $association The association callbacks are being cascaded on.
     * @param \Cake\Datasource\EntityInterface $entity The entity that started the cascaded delete.
     * @param array<string, mixed> $options The options for the original delete.
     * @return bool Success.
     */
    function cascadeDelete(Association $association, EntityInterface $entity, array $options = []): bool
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
