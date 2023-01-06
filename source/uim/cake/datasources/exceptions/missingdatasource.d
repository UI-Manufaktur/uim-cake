module uim.cake.datasources.exceptions.missingdatasource;

@safe:
import uim.cake;

// Used when a datasource cannot be found.
class MissingDatasourceException : CakeException {
  protected string _messageTemplate = "Datasource class %s could not be found. %s";
}
