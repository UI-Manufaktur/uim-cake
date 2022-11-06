module uim.cakeews.widgets;

import uim.cakeews.forms\IContext;
import uim.cakeews\StringTemplate;

/**
 * Basic input class.
 *
 * This input class can be used to render basic simple
 * input elements like hidden, text, email, tel and other
 * types.
 */
class BasicWidget : WidgetInterface
{
    /**
     * StringTemplate instance.
     *
     * @var \Cake\View\StringTemplate
     */
    protected $_templates;

    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        'name' => '',
        'val' => null,
        'type' => 'text',
        'escape' => true,
        'templateVars' => [],
    ];

    /**
     * Constructor.
     *
     * @param \Cake\View\StringTemplate myTemplates Templates list.
     */
    this(StringTemplate myTemplates) {
        this._templates = myTemplates;
    }

    /**
     * Render a text widget or other simple widget like email/tel/number.
     *
     * This method accepts a number of keys:
     *
     * - `name` The name attribute.
     * - `val` The value attribute.
     * - `escape` Set to false to disable escaping on all attributes.
     *
     * Any other keys provided in myData will be converted into HTML attributes.
     *
     * @param array<string, mixed> myData The data to build an input with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string
     */
    function render(array myData, IContext $context): string
    {
        myData = this.mergeDefaults(myData, $context);

        myData['value'] = myData['val'];
        unset(myData['val']);
        if (myData['value'] === false) {
            // explicitly convert to 0 to avoid empty string which is marshaled as null
            myData['value'] = '0';
        }

        myFieldName = myData['fieldName'] ?? null;
        if (myFieldName) {
            if (myData['type'] === 'number' && !isset(myData['step'])) {
                myData = this.setStep(myData, $context, myFieldName);
            }

            myTypesWithMaxLength = ['text', 'email', 'tel', 'url', 'search'];
            if (
                !array_key_exists('maxlength', myData)
                && in_array(myData['type'], myTypesWithMaxLength, true)
            ) {
                myData = this.setMaxLength(myData, $context, myFieldName);
            }
        }

        return this._templates.format('input', [
            'name' => myData['name'],
            'type' => myData['type'],
            'templateVars' => myData['templateVars'],
            'attrs' => this._templates.formatAttributes(
                myData,
                ['name', 'type']
            ),
        ]);
    }

    /**
     * Merge default values with supplied data.
     *
     * @param array<string, mixed> myData Data array
     * @param \Cake\View\Form\IContext $context Context instance.
     * @return array<string, mixed> Updated data array.
     */
    protected auto mergeDefaults(array myData, IContext $context): array
    {
        myData += this.defaults;

        if (isset(myData['fieldName']) && !array_key_exists('required', myData)) {
            myData = this.setRequired(myData, $context, myData['fieldName']);
        }

        return myData;
    }

    /**
     * Set value for "required" attribute if applicable.
     *
     * @param array<string, mixed> myData Data array
     * @param \Cake\View\Form\IContext $context Context instance.
     * @param string myFieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected auto setRequired(array myData, IContext $context, string myFieldName): array
    {
        if (
            empty(myData['disabled'])
            && (
                (isset(myData['type'])
                    && myData['type'] !== 'hidden'
                )
                || !isset(myData['type'])
            )
            && $context.isRequired(myFieldName)
        ) {
            myData['required'] = true;
        }

        return myData;
    }

    /**
     * Set value for "maxlength" attribute if applicable.
     *
     * @param array<string, mixed> myData Data array
     * @param \Cake\View\Form\IContext $context Context instance.
     * @param string myFieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected auto setMaxLength(array myData, IContext $context, string myFieldName): array
    {
        $maxLength = $context.getMaxLength(myFieldName);
        if ($maxLength !== null) {
            myData['maxlength'] = min($maxLength, 100000);
        }

        return myData;
    }

    /**
     * Set value for "step" attribute if applicable.
     *
     * @param array<string, mixed> myData Data array
     * @param \Cake\View\Form\IContext $context Context instance.
     * @param string myFieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected auto setStep(array myData, IContext $context, string myFieldName): array
    {
        $dbType = $context.type(myFieldName);
        myFieldDef = $context.attributes(myFieldName);

        if ($dbType === 'decimal' && isset(myFieldDef['precision'])) {
            $decimalPlaces = myFieldDef['precision'];
            myData['step'] = sprintf('%.' . $decimalPlaces . 'F', pow(10, -1 * $decimalPlaces));
        } elseif ($dbType === 'float') {
            myData['step'] = 'any';
        }

        return myData;
    }


    function secureFields(array myData): array
    {
        if (!isset(myData['name']) || myData['name'] == "") {
            return [];
        }

        return [myData['name']];
    }
}
