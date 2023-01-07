/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.exceptions;

@safe:
import uim.cake;

// Exception raised when a plugin could not be found
class MissingPluginException : UIMException {
  protected string _messageTemplate = "Plugin %s could not be found.";
}
