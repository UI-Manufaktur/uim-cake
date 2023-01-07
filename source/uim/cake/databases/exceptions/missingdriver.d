module uim.cake.databases.exceptions.missingdriver;

@safe:
import uim.cake;

// Class MissingDriverException
class MissingDriverException : UIMException {

    protected _messageTemplate = "Could not find driver `%s` for connection `%s`.";
}
