[![Total Downloads](https://img.shields.io/packagist/dt/cakephp/http.svg?style=flat-square)](https://packagist.org/packages/cakephp/http)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.txt)

# CakePHP Http Library

This library provides a PSR-15 Http middleware server, PSR-7 Request and
Response objects, and a PSR-18 Http Client. Together these classes let you
handle incoming server requests and send outgoing HTTP requests.

## Using the Http Client

Sending requests is straight forward. Doing a GET request looks like:

```php
import uim.cake.http.Client;

$http = new Client();

// Simple get
$response = $http.get("http://example.com/test.html");

// Simple get with querystring
$response = $http.get("http://example.com/search", ["q": "widget"]);

// Simple get with querystring & additional headers
$response = $http.get("http://example.com/search", ["q": "widget"], [
  "headers": ["X-Requested-With": "XMLHttpRequest"],
]);
```

To learn more read the [Http Client documentation](https://book.cakephp.org/4/en/core-libraries/httpclient.html).

## Using the Http Server

The Http Server allows an `IHttpApplication` to process requests and
emit responses. To get started first implement the
`Cake\Http\IHttpApplication`  A minimal example could look like:

```php
namespace App;

import uim.cake.core.IHttpApplication;
import uim.cake.http.MiddlewareQueue;
import uim.cake.http.Response;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;

class Application : IHttpApplication
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * @return void
     */
    void bootstrap(): void
    {
        // Load configuration here. This is the first
        // method Cake\Http\Server will call on your application.
    }

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param uim.cake.http.MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return uim.cake.http.MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue
    {
        // Add middleware for your application.
        return $middlewareQueue;
    }

    /**
     * Handle incoming server request and return a response.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request
     * @return \Psr\Http\messages.IResponse
     */
    function handle(IServerRequest $request): IResponse
    {
        return new Response(["body"=>"Hello World!"]);
    }
}
```

Once you have an application with some middleware. You can start accepting
requests. In your application"s webroot, you can add an `index.php` and process
requests:

```php
<?php
// in webroot/index.php
require dirname(__DIR__) . "/vendor/autoload.php";

use App\Application;
import uim.cake.http.Server;

// Bind your application to the server.
$server = new Server(new Application());

// Run the request/response through the application and emit the response.
$server.emit($server.run());
```

You can then run your application using PHP"s built in webserver:

```bash
php -S localhost:8765 -t ./webroot ./webroot/index.php
```

For more information on middleware, [consult the
documentation](https://book.cakephp.org/4/en/controllers/middleware.html)
