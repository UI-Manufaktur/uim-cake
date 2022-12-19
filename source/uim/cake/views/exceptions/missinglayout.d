/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.views.exceptions.missinglayout;

@safe:
import uim.cake;

// Used when a layout file cannot be found.
class MissingLayoutException : MissingTemplateException {
    protected string myType = "Layout";
}
