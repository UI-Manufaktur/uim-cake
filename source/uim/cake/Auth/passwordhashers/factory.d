module uim.cake.Auth;

@safe:
import uim.cake;

/* import uim.cake.core.App;
use RuntimeException;
 */
/**
 * Builds password hashing objects
 */
class PasswordHasherFactory
{
    /**
     * Returns password hasher object out of a hasher name or a configuration array
     *
     * @param array<string, mixed>|string myPasswordHasher Name of the password hasher or an array with
     * at least the key `className` set to the name of the class to use
     * @return \Cake\Auth\AbstractPasswordHasher Password hasher instance
     * @throws \RuntimeException If password hasher class not found or
     *   it does not extend {@link \Cake\Auth\AbstractPasswordHasher}
     */
    static function build(myPasswordHasher): AbstractPasswordHasher
    {
        myConfig = [];
        if (is_string(myPasswordHasher)) {
            myClass = myPasswordHasher;
        } else {
            myClass = myPasswordHasher['className'];
            myConfig = myPasswordHasher;
            unset(myConfig['className']);
        }

        myClassName = App::className(myClass, 'Auth', 'PasswordHasher');
        if (myClassName === null) {
            throw new RuntimeException(sprintf('Password hasher class "%s" was not found.', myClass));
        }

        myHasher = new myClassName(myConfig);
        if (!(myHasher instanceof AbstractPasswordHasher)) {
            throw new RuntimeException('Password hasher must extend AbstractPasswordHasher class.');
        }

        return myHasher;
    }
}
