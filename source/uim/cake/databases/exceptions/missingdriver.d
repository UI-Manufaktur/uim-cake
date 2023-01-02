module uim.cake.databases.exceptions.missingdriver;

@safe:
import uim.cake;

// Class MissingDriverException
class MissingDriverException : CakeException {

    protected $_messageTemplate = "Could not find driver `%s` for connection `%s`.";
}
