

import uim.cake.I18n\I18n;

// Backwards compatibility alias for custom translation messages loaders which return a Package instance.
// phpcs:disable
if (!class_exists('Aura\Intl\Package')) {
    class_alias('Cake\I18n\Package', 'Aura\Intl\Package');
}
// phpcs:enable

if (!function_exists('__')) {
    /**
     * Returns a translated string if one is found; Otherwise, the submitted message.
     *
     * @param string $singular Text to translate.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string The translated text.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__
     */
    string __(string $singular, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator().translate($singular, $args);
    }

}

if (!function_exists('__n')) {
    /**
     * Returns correct plural form of message identified by $singular and $plural for count myCount.
     * Some languages have more than one form for plural messages dependent on the count.
     *
     * @param string $singular Singular text to translate.
     * @param string $plural Plural text.
     * @param int myCount Count.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Plural form of translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__n
     */
    string __n(string $singular, string $plural, int myCount, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator().translate(
            $plural,
            ['_count' => myCount, '_singular' => $singular] + $args
        );
    }

}

if (!function_exists('__d')) {
    /**
     * Allows you to override the current domain for a single message lookup.
     *
     * @param string $domain Domain.
     * @param string $msg String to translate.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__d
     */
    string __d(string $domain, string $msg, ...$args)
    {
        if (!$msg) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator($domain).translate($msg, $args);
    }

}

if (!function_exists('__dn')) {
    /**
     * Allows you to override the current domain for a single plural message lookup.
     * Returns correct plural form of message identified by $singular and $plural for count myCount
     * from domain $domain.
     *
     * @param string $domain Domain.
     * @param string $singular Singular string to translate.
     * @param string $plural Plural.
     * @param int myCount Count.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Plural form of translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__dn
     */
    string __dn(string $domain, string $singular, string $plural, int myCount, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator($domain).translate(
            $plural,
            ['_count' => myCount, '_singular' => $singular] + $args
        );
    }

}

if (!function_exists('__x')) {
    /**
     * Returns a translated string if one is found; Otherwise, the submitted message.
     * The context is a unique identifier for the translations string that makes it unique
     * within the same domain.
     *
     * @param string $context Context of the text.
     * @param string $singular Text to translate.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__x
     */
    string __x(string $context, string $singular, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator().translate($singular, ['_context' => $context] + $args);
    }

}

if (!function_exists('__xn')) {
    /**
     * Returns correct plural form of message identified by $singular and $plural for count myCount.
     * Some languages have more than one form for plural messages dependent on the count.
     * The context is a unique identifier for the translations string that makes it unique
     * within the same domain.
     *
     * @param string $context Context of the text.
     * @param string $singular Singular text to translate.
     * @param string $plural Plural text.
     * @param int myCount Count.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Plural form of translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__xn
     */
    string __xn(string $context, string $singular, string $plural, int myCount, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator().translate(
            $plural,
            ['_count' => myCount, '_singular' => $singular, '_context' => $context] + $args
        );
    }

}

if (!function_exists('__dx')) {
    /**
     * Allows you to override the current domain for a single message lookup.
     * The context is a unique identifier for the translations string that makes it unique
     * within the same domain.
     *
     * @param string $domain Domain.
     * @param string $context Context of the text.
     * @param string $msg String to translate.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__dx
     */
    string __dx(string $domain, string $context, string $msg, ...$args)
    {
        if (!$msg) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator($domain).translate(
            $msg,
            ['_context' => $context] + $args
        );
    }

}

if (!function_exists('__dxn')) {
    /**
     * Returns correct plural form of message identified by $singular and $plural for count myCount.
     * Allows you to override the current domain for a single message lookup.
     * The context is a unique identifier for the translations string that makes it unique
     * within the same domain.
     *
     * @param string $domain Domain.
     * @param string $context Context of the text.
     * @param string $singular Singular text to translate.
     * @param string $plural Plural text.
     * @param int myCount Count.
     * @param mixed ...$args Array with arguments or multiple arguments in function.
     * @return string Plural form of translated string.
     * @link https://book.cakephp.org/4/en/core-libraries/global-constants-and-functions.html#__dxn
     */
    string __dxn(string $domain, string $context, string $singular, string $plural, int myCount, ...$args)
    {
        if (!$singular) {
            return '';
        }
        if (isset($args[0]) && is_array($args[0])) {
            $args = $args[0];
        }

        return I18n::getTranslator($domain).translate(
            $plural,
            ['_count' => myCount, '_singular' => $singular, '_context' => $context] + $args
        );
    }

}
