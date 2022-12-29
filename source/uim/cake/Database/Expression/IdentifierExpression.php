
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * Represents a single identifier name in the database.
 *
 * Identifier values are unsafe with user supplied data.
 * Values will be quoted when identifier quoting is enabled.
 *
 * @see uim.cake.Database\Query::identifier()
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
    this(string $identifier, ?string $collation = null) {
        _identifier = $identifier;
        this.collation = $collation;
    }

    /**
     * Sets the identifier this expression represents
     *
     * @param string $identifier The identifier
     * @return void
     */
    void setIdentifier(string $identifier): void
    {
        _identifier = $identifier;
    }

    /**
     * Returns the identifier this expression represents
     *
     * @return string
     */
    string getIdentifier(): string
    {
        return _identifier;
    }

    /**
     * Sets the collation.
     *
     * @param string $collation Identifier collation
     * @return void
     */
    void setCollation(string $collation): void
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


    function sql(ValueBinder $binder): string
    {
        $sql = _identifier;
        if (this.collation) {
            $sql .= " COLLATE " . this.collation;
        }

        return $sql;
    }


    O traverse(this O)(Closure $callback) {
        return this;
    }
}
