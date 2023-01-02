module uim.cake.core;

use League\Container\DefinitionIContainer;

/**
 * Interface for the Dependency Injection Container in CakePHP applications
 *
 * This interface : the PSR-11 container interface and adds
 * methods to add services and service providers to the container.
 *
 * The methods defined in this interface use the conventions provided
 * by league/container as that is the library that CakePHP uses.
 */
interface IContainer : DefinitionIContainer
{
}
