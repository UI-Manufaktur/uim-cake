module uim.cake.core.exceptions;

@safe:
import uim.cake;

// Exception raised when a plugin could not be found
class MissingPluginException : CakeException {
  protected string _messageTemplate = "Plugin %s could not be found.";
}
