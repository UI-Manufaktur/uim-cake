/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.containers.container;

@safe:
import uim.cake;
  
use League\Container\Container as LeagueContainer;

/**
 * Dependency Injection container
 *
 * Based on the container out of League\Container
 */
class Container : LeagueContainer, IContainer {
}
