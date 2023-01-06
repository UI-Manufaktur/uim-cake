module uim.cake.http.exceptions;

/**
 * Not Implemented Exception - used when an API method is not implemented
 */
class NotImplementedException : HttpException {

    protected _messageTemplate = "%s is not implemented.";


    protected _defaultCode = 501;
}
