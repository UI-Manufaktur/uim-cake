module uim.cake.controllers.Exception;

/**
 * Auth Security exception - used when SecurityComponent detects any issue with the current request
 */
class AuthSecurityException : SecurityException
{
    /**
     * Security Exception type
     *
     */
    protected string $_type = "auth";
}
