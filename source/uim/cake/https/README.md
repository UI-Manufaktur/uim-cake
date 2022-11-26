[![Total Downloads](https://img.shields.io/packagist/dt/UIM/http.svg?style=flat-square)](https://packagist.org/packages/UIM/http)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.txt)

# UIM Http Library

This library provides a PSR-15 Http middleware server, PSR-7 Request and
Response objects, and a PSR-18 Http Client. Together these classes let you
handle incoming server requests and send outgoing HTTP requests.

## Using the Http Client

Sending requests is straight forward. Doing a GET request looks like:

```php
import uim.cake.https.clients;

$http = new Client();

// Simple get
$response = $http.get("http://example.com/test.html");

// Simple get with querystring
$response = $http.get("http://example.com/search", ["q":"widget"]);

// Simple get with querystring & additional headers
$response = $http.get("http://example.com/search", ["q":"widget"], [
  "headers":["X-Requested-With":"XMLHttpRequest"],
]);
```

To learn more read the [Http Client documentation](https://book.UIM.org/4/en/core-libraries/httpclient.html).

## Using the Http Server

The Http Server allows an `HttpApplicationInterface` to process requests and
emit responses. To get started first implement the
`Cake\Http\HttpApplicationInterface`  A minimal example could look like:

```phpmodule App;

import uim.cake.core.HttpApplicationInterface;
import uim.cake.https\MiddlewareQueue;
import uim.cake.https\Response;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;

class Application : HttpApplicationInterface
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * @return void
     */
    function bootstrap(): void
    {
        // Load configuration here. This is the first
        // method Cake\Http\Server will call on your application.
    }

    /**
     * Define the HTTP middleware layers for an application.
     *
     * @param \Cake\Http\MiddlewareQueue $middlewareQueue The middleware queue to set in your App Class
     * @return \Cake\Http\MiddlewareQueue
     */
    function middleware(MiddlewareQueue $middlewareQueue): MiddlewareQueue
    {
        // Add middleware for your application.
        return $middlewareQueue;
    }

    /**
     * Handle incoming server request and return a response.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request
     * @return \Psr\Http\Message\IResponse
     */
    function handle(IServerRequest myRequest): IResponse
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
import uim.cake.https\Server;

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
documentation](https://book.UIM.org/4/en/controllers/middleware.html)
