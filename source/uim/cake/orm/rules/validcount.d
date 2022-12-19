/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cakem.Rule;

@safe:
import uim.cake;

/**
 * Validates the count of associated records.
 */
class ValidCount
{
    /**
     * The field to check
     */
    protected string $_field;

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
