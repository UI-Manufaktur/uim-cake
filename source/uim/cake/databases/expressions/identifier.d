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
 * @see uim.cake.databases.Query::identifier()
 */
class IdentifierExpression : IExpression
{
    /**
     * Holds the identifier string
     */
    protected string _identifier;

    /**
     */
    protected Nullable!string collation;

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
     */
    void setIdentifier(string $identifier) {
        _identifier = $identifier;
    }

    /**
     * Returns the identifier this expression represents
     */
    string getIdentifier() {
        return _identifier;
    }

    /**
     * Sets the collation.
     *
     * @param string $collation Identifier collation
     */
    void setCollation(string $collation) {
        this.collation = $collation;
    }

    /**
     * Returns the collation.
     *
     */
    Nullable!string getCollation()
    {
        return this.collation;
    }


    string sql(ValueBinder aBinder) {
        $sql = _identifier;
        if (this.collation) {
            $sql .= " COLLATE " ~ this.collation;
        }

        return $sql;
    }


    O traverse(this O)(Closure $callback) {
        return this;
    }
}
