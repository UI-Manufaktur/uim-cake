

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         3.2.9
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakem.Rule;

import uim.cake.datasources\IEntity;
import uim.cake.validations\Validation;
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
     * @param string myField The field to check the count on.
     */
    this(string myField) {
        this._field = myField;
    }

    /**
     * Performs the count check
     *
     * @param \Cake\Datasource\IEntity $entity The entity from where to extract the fields.
     * @param array<string, mixed> myOptions Options passed to the check.
     * @return bool True if successful, else false.
     */
    bool __invoke(IEntity $entity, array myOptions) {
        myValue = $entity.{this._field};
        if (!is_array(myValue) && !myValue instanceof Countable) {
            return false;
        }

        return Validation::comparison(count(myValue), myOptions["operator"], myOptions["count"]);
    }
}
