<?php
declare(strict_types=1);

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
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Database\Expression;

use Cake\Database\IExpression;
use Cake\Database\ValueBinder;
use Closure;

/**
 * Represents a single identifier name in the database.
 *
 * Identifier values are unsafe with user supplied data.
 * Values will be quoted when identifier quoting is enabled.
 *
 * @see \Cake\Database\Query::identifier()
 */
class IdentifierExpression : IExpression
{
    /**
     * Holds the identifier string
     *
     * @var string
     */
    protected $_identifier;

    /**
     * @var string|null
     */
    protected $collation;

    /**
     * Constructor
     *
     * @param string $identifier The identifier this expression represents
     * @param string|null $collation The identifier collation
     */
    public this(string $identifier, ?string $collation = null)
    {
        _identifier = $identifier;
        this.collation = $collation;
    }

    /**
     * Sets the identifier this expression represents
     *
     * @param string $identifier The identifier
     * @return void
     */
    function setIdentifier(string $identifier): void
    {
        _identifier = $identifier;
    }

    /**
     * Returns the identifier this expression represents
     *
     * @return string
     */
    function getIdentifier(): string
    {
        return _identifier;
    }

    /**
     * Sets the collation.
     *
     * @param string $collation Identifier collation
     * @return void
     */
    function setCollation(string $collation): void
    {
        this.collation = $collation;
    }

    /**
     * Returns the collation.
     *
     * @return string|null
     */
    function getCollation(): ?string
    {
        return this.collation;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $sql = _identifier;
        if (this.collation) {
            $sql .= ' COLLATE ' . this.collation;
        }

        return $sql;
    }

    /**
     * @inheritDoc
     */
    public O traverse(this O)(Closure $callback)
    {
        return this;
    }
}
