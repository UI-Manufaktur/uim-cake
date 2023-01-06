/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.views.exceptions.missingview;

@safe:
import uim.cake;

// Used when a view class file cannot be found.
class MissingViewException : CakeException {
  protected string _messageTemplate = "View class '%s' is missing.";
}
