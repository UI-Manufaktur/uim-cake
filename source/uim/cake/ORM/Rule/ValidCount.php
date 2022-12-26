


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.2.9
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Rule;

import uim.cake.Datasource\EntityInterface;
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
     * @var string
     */
    protected $_field;

    /**
     * Constructor.
     *
     * @param string $field The field to check the count on.
     */
    public this(string $field) {
        _field = $field;
    }

    /**
     * Performs the count check
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity from where to extract the fields.
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
