


 *


 * @since         3.2.9
  */
module uim.cake.orm.Rule;

import uim.cake.datasources.EntityInterface;
import uim.cake.Validation\Validation;
use Countable;

/**
 * Validates the count of associated records.
 */
class ValidCount
{
    /**
     * The field to check
     *
     */
    protected string $_field;

    /**
     * Constructor.
     *
     * @param string $field The field to check the count on.
     */
    this(string $field) {
        _field = $field;
    }

    /**
     * Performs the count check
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity from where to extract the fields.
     * @param array<string, mixed> $options Options passed to the check.
     * @return bool True if successful, else false.
     */
    function __invoke(EntityInterface $entity, array $options): bool
    {
        $value = $entity.{_field};
        if (!is_array($value) && !$value instanceof Countable) {
            return false;
        }

        return Validation::comparison(count($value), $options["operator"], $options["count"]);
    }
}
