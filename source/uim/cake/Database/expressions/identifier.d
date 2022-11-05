module uim.baklava.databases.expressions;

import uim.baklava.databases.IExpression;
import uim.baklava.databases.ValueBinder;
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
     * @param string myIdentifier The identifier this expression represents
     * @param string|null $collation The identifier collation
     */
    this(string myIdentifier, ?string $collation = null) {
        this._identifier = myIdentifier;
        this.collation = $collation;
    }

    /**
     * Sets the identifier this expression represents
     *
     * @param string myIdentifier The identifier
     * @return void
     */
    auto setIdentifier(string myIdentifier): void
    {
        this._identifier = myIdentifier;
    }

    /**
     * Returns the identifier this expression represents
     *
     * @return string
     */
    auto getIdentifier(): string
    {
        return this._identifier;
    }

    /**
     * Sets the collation.
     *
     * @param string $collation Identifier collation
     * @return void
     */
    auto setCollation(string $collation): void
    {
        this.collation = $collation;
    }

    /**
     * Returns the collation.
     *
     * @return string|null
     */
    string getCollation() {
        return this.collation;
    }


    function sql(ValueBinder $binder): string
    {
        mySql = this._identifier;
        if (this.collation) {
            mySql .= ' COLLATE ' . this.collation;
        }

        return mySql;
    }


    function traverse(Closure $callback) {
        return this;
    }
}
