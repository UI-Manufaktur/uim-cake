


 *



  */
module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;
import uim.cake.View\StringTemplate;
use DateTimeInterface;
use InvalidArgumentException;

/**
 * Input widget class for generating a calendar year select box.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone calendar year select boxes.
 */
class YearWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "val": null,
        "min": null,
        "max": null,
        "order": "desc",
        "templateVars": [],
    ];

    /**
     * Select box widget.
     *
     * @var uim.cake.View\Widget\SelectBoxWidget
     */
    protected $_select;

    /**
     * Constructor
     *
     * @param uim.cake.View\StringTemplate $templates Templates list.
     * @param uim.cake.View\Widget\SelectBoxWidget $selectBox Selectbox widget instance.
     */
    public this(StringTemplate $templates, SelectBoxWidget $selectBox) {
        _select = $selectBox;
        _templates = $templates;
    }

    /**
     * Renders a year select box.
     *
     * @param array<string, mixed> $data Data to render with.
     * @param uim.cake.View\Form\ContextInterface $context The current form context.
     * @return string A generated select box.
     */
    function render(array $data, ContextInterface $context): string
    {
        $data += this.mergeDefaults($data, $context);

        if (empty($data["min"])) {
            $data["min"] = date("Y", strtotime("-5 years"));
        }

        if (empty($data["max"])) {
            $data["max"] = date("Y", strtotime("+5 years"));
        }

        $data["min"] = (int)$data["min"];
        $data["max"] = (int)$data["max"];

        if ($data["val"] instanceof DateTimeInterface) {
            $data["val"] = $data["val"].format("Y");
        }

        if (!empty($data["val"])) {
            $data["min"] = min((int)$data["val"], $data["min"]);
            $data["max"] = max((int)$data["val"], $data["max"]);
        }

        if ($data["max"] < $data["min"]) {
            throw new InvalidArgumentException("Max year cannot be less than min year");
        }

        if ($data["order"] == "desc") {
            $data["options"] = range($data["max"], $data["min"]);
        } else {
            $data["options"] = range($data["min"], $data["max"]);
        }
        $data["options"] = array_combine($data["options"], $data["options"]);

        unset($data["order"], $data["min"], $data["max"]);

        return _select.render($data, $context);
    }
}
