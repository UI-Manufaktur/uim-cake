/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.https\Exception;

/**
 * Not Implemented Exception - used when an API method is not implemented
 */
class NotImplementedException : HttpException
{

    protected _messageTemplate = "%s is not implemented.";


    protected _defaultCode = 501;
}
