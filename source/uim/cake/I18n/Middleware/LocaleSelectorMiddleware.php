

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.3.0
  */
module uim.cake.I18n\Middleware;

import uim.cake.I18n\I18n;
use Locale;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;

/**
 * Sets the runtime default locale for the request based on the
 * Accept-Language header. The default will only be set if it
 * matches the list of passed valid locales.
 */
class LocaleSelectorMiddleware : IMiddleware
{
    /**
     * List of valid locales for the request
     *
     * @var array
     */
    protected $locales = [];

    /**
     * Constructor.
     *
     * @param array $locales A list of accepted locales, or ["*"] to accept any
     *   locale header value.
     */
    this(array $locales = []) {
        this.locales = $locales;
    }

    /**
     * Set locale based on request headers.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        $locale = Locale::acceptFromHttp($request.getHeaderLine("Accept-Language"));
        if (!$locale) {
            return $handler.handle($request);
        }
        if (this.locales != ["*"]) {
            $locale = Locale::lookup(this.locales, $locale, true);
        }
        if ($locale || this.locales == ["*"]) {
            I18n::setLocale($locale);
        }

        return $handler.handle($request);
    }
}
