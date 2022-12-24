

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database\Expression;

import uim.cake.Database\IExpression;
import uim.cake.Database\ValueBinder;
use Closure;

/**
 * String expression with collation.
 */
class StringExpression : IExpression
{
    /**
     * @var string
     */
    protected $string;

    /**
     * @var string
     */
    protected $collation;

    /**
     * @param string $string String value
     * @param string $collation String collation
     */
    public this(string $string, string $collation)
    {
        this.string = $string;
        this.collation = $collation;
    }

    /**
     * Sets the string collation.
     *
     * @param string $collation String collation
     * @return void
     */
    function setCollation(string $collation): void
    {
        this.collation = $collation;
    }

    /**
     * Returns the string collation.
     *
     * @return string
     */
    function getCollation(): string
    {
        return this.collation;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $placeholder = $binder.placeholder('c');
        $binder.bind($placeholder, this.string, 'string');

        return $placeholder . ' COLLATE ' . this.collation;
    }

    /**
     * @inheritDoc
     */
    public O traverse(this O)(Closure $callback)
    {
        return this;
    }
}
