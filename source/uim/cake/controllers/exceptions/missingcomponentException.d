/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.controllers\Exception;

@safe:
import uim.cake;

// Used when a component cannot be found.
class MissingComponentException : CakeException {
    protected string _messageTemplate = "Component class %s could not be found.";
}
