module uim.baklava.core;

use League\Container\IDefinitionContainer;

/**
 * Interface for the Dependency Injection Container in CakePHP applications
 *
 * This interface : the PSR-11 container interface and adds
 * methods to add services and service providers to the container.
 *
 * The methods defined in this interface use the conventions provided
 * by league/container as that is the library that CakePHP uses.
 *
 * @experimental This interface is not final and can have additional
 *   methods and parameters added in future minor releases.
 */
interface IContainer : IDefinitionContainer {
}
