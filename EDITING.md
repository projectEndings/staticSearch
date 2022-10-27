# Editing Configuration XML Files

The configuration file is an XML document which tells the Generator where to find your site, and what search features you would like to include.

A configuration file can be edited with any text editor. Editing will be easier if you use an XML-aware editor that checks the XML syntax for you, and easier again if a schema-aware XML editor is configured to validate the XML file against the configuration file schema.

Support for two schema-aware editors is provided: Oxygen and Emacs.

## Oxygen framework

The staticSearch framework can be installed either as add-on inside Oxygen or as files on the file system in a location where Oxygen can find them.

### Installing as add-on Oxygen framework

Follow the instructions in the Oxygen manual at https://www.oxygenxml.com/doc/ug-editor/topics/installing-and-updating-add-ons.html

The staticSearch framework update site URL is https://raw.githubusercontent.com/tgraham-antenna/staticSearch/framework/add-on.xml

Note that Oxygen will require you to restart the editor after installing the add-on framework.

### Installing a ZIP archive to Oxygen `frameworks` directory

1. Download the ZIP archive from the latest release on the 'Releases' page.
2. Extract the folder in the ZIP archive to the Oxygen `frameworks` directory.
 - On Windows, this is `C:\Program Files\Oxygen XML Editor 25\frameworks`, or something similar.
 - If you don't have permission to copy the folder to the `frameworks` directory, then you can use an alternative location as described below.
3. Restart Oxygen.

### Installing a ZIP archive to an alternative frameworks location

If you don't have permission to modify the Oxygen installation – for example, if Oxygen is installed on Windows under `C:\Program Files\` and you are not an Administrator – you can set Oxygen to also use an alternative frameworks location.

1. Click on the "Download ZIP" button on this project's main page to download the files.
2. Extract the folder in the ZIP archive to a folder where you can create the new folder.
3. In your Oxygen preferences, add the staticSearch folder as an alternative frameworks location.
 - See https://www.oxygenxml.com/doc/ug-editor/topics/framework-location.html
4. Restart Oxygen.

### Using the Oxygen framework

When you open a configuration file – where the document element is `config` in the staticSearch namespace – Oxygen will automatically validate the document against the Relax NG schema.

## Emacs

Clone the repository or download and unzip a release then add the location of the `schema\schemas.xml` file to the `rng-schema-locating-files` variable in your `.emacs` file.
