/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Widget;

/**
 * Form "widget" for creating labels that contain their input.
 *
 * Generally this element is used by other widgets,
 * and FormHelper itself.
 */
class NestingLabelWidget : LabelWidget
{
    /**
     * The template to use.
     */
    protected string _labelTemplate = "nestingLabel";
}
