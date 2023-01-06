module uim.cake.datasources.exceptions.miisingmodel;

@safe:
import uim.cake;

// Used when a model cannot be found.
class MissingModelException : CakeException {
  protected string _messageTemplate = "Model class '%s' of type '%s' could not be found.";
}