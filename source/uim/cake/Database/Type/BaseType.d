module uim.cake.database.Type;

import uim.cake.database.IDriver;
import uim.cake.database.TypeInterface;
use PDO;

/**
 * Base type class.
 */
abstract class BaseType : TypeInterface
{
    /**
     * Identifier name for this type
     *
     * @var string|null
     */
    protected $_name;

    /**
     * Constructor
     *
     * @param string|null myName The name identifying this type
     */
    this(?string myName = null) {
        this._name = myName;
    }


    string getName() {
        return this._name;
    }


    string getBaseType() {
        return this._name;
    }


    function toStatement(myValue, IDriver myDriver) {
        if (myValue === null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_STR;
    }


    function newId() {
        return null;
    }
}
