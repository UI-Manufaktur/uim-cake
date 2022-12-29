

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         4.1.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Session;

import uim.cake.utilities.Hash;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * SessionHasKey
 *
 * @internal
 */
class SessionHasKey : Constraint
{
    /**
     * @var string
     */
    protected $path;

    /**
     * Constructor
     *
     * @param string $path Session Path
     */
    public this(string $path) {
        this.path = $path;
    }

    /**
     * Compare session value
     *
     * @param mixed $other Value to compare with
     * @return bool
     */
    function matches($other): bool
    {
        // Server::run calls Session::close at the end of the request.
        // Which means, that we cannot use Session object here to access the session data.
        // Call to Session::read will start new session (and will erase the data).
        /** @psalm-suppress InvalidScalarArgument */
        return Hash::check($_SESSION, this.path) == true;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return "is a path present in the session";
    }
}
