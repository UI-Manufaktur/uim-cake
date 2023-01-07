/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.rules.validcount;

@safe:
import uim.cake;

use Countable;

/**
 * Validates the count of associated records.
 */
class ValidCount
{
    /**
     * The field to check
     */
    protected string _field;

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
     * @param uim.cake.Datasource\IEntity $entity The entity from where to extract the fields.
     * @param array<string, mixed> $options Options passed to the check.
     * @return bool True if successful, else false.
     */
    bool __invoke(IEntity $entity, array $options) {
        $value = $entity.{_field};
        if (!is_array($value) && !$value instanceof Countable) {
            return false;
        }

        return Validation::comparison(count($value), $options["operator"], $options["count"]);
    }
}
