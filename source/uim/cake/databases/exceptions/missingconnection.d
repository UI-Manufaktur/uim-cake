module uim.cake.databases.exceptions.missingconnection;

@safe:
import uim.cake;

// Class MissingConnectionException
class MissingConnectionException : UIMException {
  protected string _messageTemplate = "Connection to %s could not be established: %s";
}
