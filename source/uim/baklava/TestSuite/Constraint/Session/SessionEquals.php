

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.7.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Session;

import uim.baklava.utikities.Hash;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * SessionEquals
 *
 * @internal
 */
class SessionEquals : Constraint
{
    /**
     * @var string
     */
    protected myPath;

    /**
     * Constructor
     *
     * @param string myPath Session Path
     */
    this(string myPath) {
        this.path = myPath;
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
        return Hash::get($_SESSION, this.path) === $other;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('is in session path \'%s\'', this.path);
    }
}
