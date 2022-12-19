module uim.cake.datasources.exceptions;

@safe:
import uim.cake;

// Exception raised when requested page number does not exist.
class PageOutOfBoundsException : CakeException {
    protected string _messageTemplate = "Page number %s could not be found.";
}
