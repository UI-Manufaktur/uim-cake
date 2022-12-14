/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Form;

import uim.cake.collections.Collection;
import uim.datasources.IEntity;
import uim.cake.Form\Form;
import uim.cake.http.ServerRequest;
use RuntimeException;

/**
 * Factory for getting form context instance based on provided data.
 */
class ContextFactory
{
    /**
     * Context providers.
     *
     * @var array<string, array>
     */
    protected $providers = null;

    /**
     * Constructor.
     *
     * @param array $providers Array of provider callables. Each element should
     *   be of form `["type": "a-string", "callable": ..]`
     */
    this(array $providers = null) {
        foreach ($providers as $provider) {
            this.addProvider($provider["type"], $provider["callable"]);
        }
    }

    /**
     * Create factory instance with providers "array", "form" and "orm".
     *
     * @param array $providers Array of provider callables. Each element should
     *   be of form `["type": "a-string", "callable": ..]`
     * @return static
     */
    static function createWithDefaults(array $providers = null) {
        $providers = [
            [
                "type": "orm",
                "callable": function (myServerRequest, $data) {
                    if ($data["entity"] instanceof IEntity) {
                        return new EntityContext($data);
                    }
                    if (isset($data["table"])) {
                        return new EntityContext($data);
                    }
                    if (is_iterable($data["entity"])) {
                        $pass = (new Collection($data["entity"])).first() != null;
                        if ($pass) {
                            return new EntityContext($data);
                        } else {
                            return new NullContext($data);
                        }
                    }
                },
            ],
            [
                "type": "form",
                "callable": function (myServerRequest, $data) {
                    if ($data["entity"] instanceof Form) {
                        return new FormContext($data);
                    }
                },
            ],
            [
                "type": "array",
                "callable": function (myServerRequest, $data) {
                    if (is_array($data["entity"]) && isset($data["entity"]["schema"])) {
                        return new ArrayContext($data["entity"]);
                    }
                },
            ],
            [
                "type": "null",
                "callable": function (myServerRequest, $data) {
                    if ($data["entity"] == null) {
                        return new NullContext($data);
                    }
                },
            ],
        ] + $providers;

        return new static($providers);
    }

    /**
     * Add a new context type.
     *
     * Form context types allow FormHelper to interact with
     * data providers that come from outside UIM. For example
     * if you wanted to use an alternative ORM like Doctrine you could
     * create and connect a new context class to allow FormHelper to
     * read metadata from doctrine.
     *
     * @param string $type The type of context. This key
     *   can be used to overwrite existing providers.
     * @param callable $check A callable that returns an object
     *   when the form context is the correct type.
     * @return this
     */
    function addProvider(string $type, callable $check) {
        this.providers = [$type: ["type": $type, "callable": $check]]
            + this.providers;

        return this;
    }

    /**
     * Find the matching context for the data.
     *
     * If no type can be matched a NullContext will be returned.
     *
     * @param uim.cake.http.ServerRequest myServerRequest Request instance.
     * @param array<string, mixed> $data The data to get a context provider for.
     * @return uim.cake.views\Form\IContext Context provider.
     * @throws \RuntimeException When a context instance cannot be generated for given entity.
     */
    function get(ServerRequest myServerRequest, array $data = null): IContext
    {
        $data += ["entity": null];

        foreach (this.providers as $provider) {
            $check = $provider["callable"];
            $context = $check(myServerRequest, $data);
            if ($context) {
                break;
            }
        }

        if (!isset($context)) {
            throw new RuntimeException(sprintf(
                "No context provider found for value of type `%s`."
                ~ " Use `null` as 1st argument of FormHelper::create() to create a context-less form.",
                getTypeName($data["entity"])
            ));
        }

        return $context;
    }
}
