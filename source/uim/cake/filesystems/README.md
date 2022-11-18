[![Total Downloads](https://img.shields.io/packagist/dt/UIM/filesystem.svg?style=flat-square)](https://packagist.org/packages/UIM/filesystem)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.txt)

# This package has been deprecated.

## UIM Filesystem Library

The Folder and File utilities are convenience classes to help you read from and write/append to files; list files within a folder and other common directory related tasks.

## Basic Usage

Create a folder instance and search for all the `.php` files within it:

```php
import uim.cake.filesystems\Folder;

$dir = new Folder("/path/to/folder");
myfiles = $dir.find(".*\.php");
```

Now you can loop through the files and read from or write/append to the contents or simply delete the file:

```php
foreach (myfiles as myfile) {
    myfile = new File($dir.pwd() . DIRECTORY_SEPARATOR . myfile);
    myContentss = myfile.read();
    // myfile.write("I am overwriting the contents of this file");
    // myfile.append("I am adding to the bottom of this file.");
    // myfile.delete(); // I am deleting this file
    myfile.close(); // Be sure to close the file when you"re done
}
```

## Documentation

Please make sure you check the [official
documentation](https://book.UIM.org/4/en/core-libraries/file-folder.html)
