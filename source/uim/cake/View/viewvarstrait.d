

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c), Cake Software Foundation, Inc. (https://cakefoundation.org)


  */module uim.cake.View;

import uim.cake.events.IEventDispatcher;

/**
 * Provides the set() method for collecting template context.
 *
 * Once collected context data can be passed to another object.
 * This is done in Controller, TemplateTask and View for example.
 */
trait ViewVarsTrait
{
    /**
     * The view builder instance being used.
     *
     * @var uim.cake.View\ViewBuilder|null
     */
    protected $_viewBuilder;

    /**
     * Get the view builder being used.
     *
     * @return uim.cake.View\ViewBuilder
     */
    function viewBuilder(): ViewBuilder
    {
        if (!isset(_viewBuilder)) {
            _viewBuilder = new ViewBuilder();
        }

        return _viewBuilder;
    }

    /**
     * Constructs the view class instance based on the current configuration.
     *
     * @param string|null $viewClass Optional namespaced class name of the View class to instantiate.
     * @return uim.cake.View\View
     * @throws uim.cake.View\exceptions.MissingViewException If view class was not found.
     */
    function createView(?string $viewClass = null): View
    {
        $builder = this.viewBuilder();
        if ($viewClass) {
            $builder.setClassName($viewClass);
        }

        foreach (["name", "plugin"] as $prop) {
            if (isset(this.{$prop})) {
                $method = "set" ~ ucfirst($prop);
                $builder.{$method}(this.{$prop});
            }
        }

        /** @psalm-suppress RedundantPropertyInitializationCheck */
        return $builder.build(
            [],
            this.request ?? null,
            this.response ?? null,
            this instanceof IEventDispatcher ? this.getEventManager() : null
        );
    }

    /**
     * Saves a variable or an associative array of variables for use inside a template.
     *
     * @param array|string aName A string or an array of data.
     * @param mixed $value Value in case $name is a string (which then works as the key).
     *   Unused if $name is an associative array, otherwise serves as the values to $name"s keys.
     * @return this
     */
    function set($name, $value = null) {
        if (is_array($name)) {
            if (is_array($value)) {
                $data = array_combine($name, $value);
            } else {
                $data = $name;
            }
        } else {
            $data = [$name: $value];
        }
        this.viewBuilder().setVars($data);

        return this;
    }
}
