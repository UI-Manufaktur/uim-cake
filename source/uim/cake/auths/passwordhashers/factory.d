/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/module uim.cake.auths.passwordhashers.factory;

@safe:
import uim.cake

// Builds password hashing objects
class PasswordHasherFactory {
    /**
     * Returns password hasher object out of a hasher name or a configuration array
     *
     * @param array<string, mixed>|string myPasswordHasher Name of the password hasher or an array with
     * at least the key `className` set to the name of the class to use
     * @return uim.cake.Auth\AbstractPasswordHasher Password hasher instance
     * @throws \RuntimeException If password hasher class not found or
     *   it does not extend {@link uim.cake.Auth\AbstractPasswordHasher}
     */
    static AbstractPasswordHasher build(myPasswordHasher) {
        myConfig = [];
        if (is_string(myPasswordHasher)) {
            myClass = myPasswordHasher;
        } else {
            myClass = myPasswordHasher["className"];
            myConfig = myPasswordHasher;
            unset(myConfig["className"]);
        }

        myClassName = App::className(myClass, "Auth", "PasswordHasher");
        if (myClassName is null) {
            throw new RuntimeException(sprintf("Password hasher class "%s" was not found.", myClass));
        }

        myHasher = new myClassName(myConfig);
        if (!(myHasher instanceof AbstractPasswordHasher)) {
            throw new RuntimeException("Password hasher must extend AbstractPasswordHasher class.");
        }

        return myHasher;
    }
}
