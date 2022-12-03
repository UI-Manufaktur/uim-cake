module uim.cakeews.exceptions;

@safe:
import uim.cake;

// Used when an element file cannot be found.
class MissingElementException : MissingTemplateException {
  protected string myType = "Element";
}
