module uim.baklava.controller\Exception;

/**
 * Auth Security exception - used when SecurityComponent detects any issue with the current request
 */
class AuthSecurityException : SecurityException
{
    /**
     * Security Exception type
     *
     * @var string
     */
    protected $_type = 'auth';
}
