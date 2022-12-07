module uim.cake.views.forms;

@safe:
import uim.cake;

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
    protected $providers = [];

    /**
     * Constructor.
     *
     * @param array $providers Array of provider callables. Each element should
     *   be of form `["type" => "a-string", "callable" => ..]`
     */
    this(array $providers = []) {
        foreach ($providers as $provider) {
            this.addProvider($provider["type"], $provider["callable"]);
        }
    }

    /**
     * Create factory instance with providers "array", "form" and "orm".
     *
     * @param array $providers Array of provider callables. Each element should
     *   be of form `["type" => "a-string", "callable" => ..]`
     * @return static
     */
    static function createWithDefaults(array $providers = []) {
        $providers = [
            [
                "type" => "orm",
                "callable" => function (myRequest, myData) {
                    if (myData["entity"] instanceof IEntity) {
                        return new EntityContext(myData);
                    }
                    if (isset(myData["table"])) {
                        return new EntityContext(myData);
                    }
                    if (is_iterable(myData["entity"])) {
                        $pass = (new Collection(myData["entity"])).first() !== null;
                        if ($pass) {
                            return new EntityContext(myData);
                        } else {
                            return new NullContext(myData);
                        }
                    }
                },
            ],
            [
                "type" => "form",
                "callable" => function (myRequest, myData) {
                    if (myData["entity"] instanceof Form) {
                        return new FormContext(myData);
                    }
                },
            ],
            [
                "type" => "array",
                "callable" => function (myRequest, myData) {
                    if (is_array(myData["entity"]) && isset(myData["entity"]["schema"])) {
                        return new ArrayContext(myData["entity"]);
                    }
                },
            ],
            [
                "type" => "null",
                "callable" => function (myRequest, myData) {
                    if (myData["entity"] == null) {
                        return new NullContext(myData);
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
     * @param string myType The type of context. This key
     *   can be used to overwrite existing providers.
     * @param callable $check A callable that returns an object
     *   when the form context is the correct type.
     * @return this
     */
    function addProvider(string myType, callable $check) {
        this.providers = [myType => ["type" => myType, "callable" => $check]]
            + this.providers;

        return this;
    }

    /**
     * Find the matching context for the data.
     *
     * If no type can be matched a NullContext will be returned.
     *
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     * @param array<string, mixed> myData The data to get a context provider for.
     * @return \Cake\View\Form\IContext Context provider.
     * @throws \RuntimeException When a context instance cannot be generated for given entity.
     */
    auto get(ServerRequest myRequest, array myData = []): IContext
    {
        myData += ["entity" => null];

        foreach (this.providers as $provider) {
            $check = $provider["callable"];
            $context = $check(myRequest, myData);
            if ($context) {
                break;
            }
        }

        if (!isset($context)) {
            throw new RuntimeException(sprintf(
                "No context provider found for value of type `%s`."
                . " Use `null` as 1st argument of FormHelper::create() to create a context-less form.",
                getTypeName(myData["entity"])
            ));
        }

        return $context;
    }
}
