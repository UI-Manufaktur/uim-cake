/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.views.Exception;

@safe:
import uim.cake;;

// Used when a template file for a cell cannot be found.
class MissingCellTemplateException : MissingTemplateException {
    protected string myName;

    protected string myType = "Cell template";

    /**
     * Constructor
     *
     * @param string myName The Cell name that is missing a view.
     * @param string myfile The view filename.
     * @param array<string> myPaths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(
        string myName,
        string myfile,
        array myPaths = null,
        Nullable!int $code = null,
        ?Throwable $previous = null
    ) {
        this.name = myName;

        super.this(myfile, myPaths, $code, $previous);
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     * @psalm-return array{name: string, file: string, paths: array}
     */
    array getAttributes() {
        return [
            "name": this.name,
            "file": this.file,
            "paths": this.paths,
        ];
    }
}
