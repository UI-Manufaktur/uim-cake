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
 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Http;

use Psr\Http\Message\UriInterface;
use UnexpectedValueException;

/**
 * The base and webroot properties have piggybacked on the Uri for
 * a long time. To preserve backwards compatibility and avoid dynamic
 * property errors in PHP 8.2 we use this implementation that decorates
 * the Uri from Laminas
 *
 * This class is an internal implementation workaround that will be removed in 5.x
 *
 * @internal
 */
class Uri : UriInterface
{
    /**
     * @var string
     */
    private $base = '';

    /**
     * @var string
     */
    private $webroot = '';

    /**
     * @var \Psr\Http\Message\UriInterface
     */
    private $uri;

    /**
     * Constructor
     *
     * @param \Psr\Http\Message\UriInterface $uri Uri instance to decorate
     * @param string $base The base path.
     * @param string $webroot The webroot path.
     */
    public this(UriInterface $uri, string $base, string $webroot)
    {
        this.uri = $uri;
        this.base = $base;
        this.webroot = $webroot;
    }

    /**
     * Backwards compatibility shim for previously dynamic properties.
     *
     * @param string $name The attribute to read.
     * @return mixed
     */
    function __get(string $name)
    {
        if ($name == 'base' || $name == 'webroot') {
            return this.{$name};
        }
        throw new UnexpectedValueException("Undefined property via __get('{$name}')");
    }

    /**
     * Get the decorated URI
     *
     * @return \Psr\Http\Message\UriInterface
     */
    function getUri(): UriInterface
    {
        return this.uri;
    }

    /**
     * Get the application base path.
     *
     * @return string
     */
    function getBase(): string
    {
        return this.base;
    }

    /**
     * Get the application webroot path.
     *
     * @return string
     */
    function getWebroot(): string
    {
        return this.webroot;
    }

    /**
     * @inheritDoc
     */
    function getScheme()
    {
        return this.uri->getScheme();
    }

    /**
     * @inheritDoc
     */
    function getAuthority()
    {
        return this.uri->getAuthority();
    }

    /**
     * @inheritDoc
     */
    function getUserInfo()
    {
        return this.uri->getUserInfo();
    }

    /**
     * @inheritDoc
     */
    function getHost()
    {
        return this.uri->getHost();
    }

    /**
     * @inheritDoc
     */
    function getPort()
    {
        return this.uri->getPort();
    }

    /**
     * @inheritDoc
     */
    function getPath()
    {
        return this.uri->getPath();
    }

    /**
     * @inheritDoc
     */
    function getQuery()
    {
        return this.uri->getQuery();
    }

    /**
     * @inheritDoc
     */
    function getFragment()
    {
        return this.uri->getFragment();
    }

    /**
     * @inheritDoc
     */
    function withScheme($scheme)
    {
        $new = clone this;
        $new->uri = this.uri->withScheme($scheme);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withUserInfo($user, $password = null)
    {
        $new = clone this;
        $new->uri = this.uri->withUserInfo($user, $password);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withHost($host)
    {
        $new = clone this;
        $new->uri = this.uri->withHost($host);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withPort($port)
    {
        $new = clone this;
        $new->uri = this.uri->withPort($port);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withPath($path)
    {
        $new = clone this;
        $new->uri = this.uri->withPath($path);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withQuery($query)
    {
        $new = clone this;
        $new->uri = this.uri->withQuery($query);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function withFragment($fragment)
    {
        $new = clone this;
        $new->uri = this.uri->withFragment($fragment);

        return $new;
    }

    /**
     * @inheritDoc
     */
    function __toString()
    {
        return this.uri->__toString();
    }
}
