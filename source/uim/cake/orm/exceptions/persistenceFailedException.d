/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.orm.Exception;

import uim.cake.core.exceptions\CakeException;
import uim.cake.datasources\IEntity;
import uim.cake.utilities.Hash;
use Throwable;

// Used when a strict save or delete fails
class PersistenceFailedException : CakeException
{
    /**
     * The entity on which the persistence operation failed
     *
     * @var \Cake\Datasource\IEntity
     */
    protected _entity;


    protected _messageTemplate = "Entity %s failure.";

    /**
     * Constructor.
     *
     * @param \Cake\Datasource\IEntity $entity The entity on which the persistence operation failed
     * @param array<string>|string myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(IEntity $entity, myMessage, Nullable!int $code = null, ?Throwable $previous = null) {
        _entity = $entity;
        if (is_array(myMessage)) {
            myErrors = [];
            foreach (Hash::flatten($entity.getErrors()) as myField: myError) {
                myErrors[] = myField . ": "" . myError . """;
            }
            if (myErrors) {
                myMessage[] = implode(", ", myErrors);
                _messageTemplate = "Entity %s failure. Found the following errors (%s).";
            }
        }
        super.this(myMessage, $code, $previous);
    }

    /**
     * Get the passed in entity
     *
     * @return \Cake\Datasource\IEntity
     */
    auto getEntity(): IEntity
    {
        return _entity;
    }
}
