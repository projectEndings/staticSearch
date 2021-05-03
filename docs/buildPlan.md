# BUILD PLAN (July 29, 2019)

NOTE: THIS IS OBSOLETE AND NEEDS TO BE UPDATED.

While the base functionality of the XSLT processing stage is now complete,
the code itself is a bit unruly and long. I think we should split this into
multiple modules and steps for clarity's sake, and also for good reporting
in the long run.

## FILE: build.xml

This the root build, which calls the rest of the rest of the builds.

PROPERTIES:

config: The configuration file
verbose: Whether or not to be verbose (overrides the verbosity parameter in the XSLT)

## FILE: `buildConfig.xml`

Description: The buildConfig.xml file gets the configuration file from the user or, otherwise, creates one for them. 
Default: all


### TASK: `all`

Depends: getConfigFile, validateConfigFile, createConfigXsl, createConfigAnt

This task is the base "driver" task, which processes the entirety of the config stuff

### TASK: `getConfigFile`

Description: The getConfigFile task checks to see whether or not a configuration file can be provided.
If one has already been provided via the command line, then this build is happy and just moves on. Otherwise,
it asks the user whether or not they meant to provide one and opens a file chooser for them to select it. If 
both of the above result in nothing, then it helps a user create a base one.


IF the configuration file has been provided as a property (either explicitly or via the command line)
THEN do nothing other than say "Yes, config file has been provided."

IF the configuration file HAS NOT been provided
THEN create dialog which asks: Do you have a config file already". This will be a radio button thing with TWO options which boil down to "YES or NO"
    IF "yes"
    THEN open a file chooser window and get the user to select the configuration file
    OTHERWISE call `makeConfigFile`


### TASK: `makeConfigFile`

Description: The makeConfigFile task is only run when a user has neither a) provided a configuration file 
as a command line property nor b) Selected one in the getConfigFile file chooser. It helps create a basic configuration file 
with the minimum components necessary. TODO: Figure out what are the minimum components necessary for a valid config file

What it needs to get:

COLLECTION DIRECTORY: The directory that contains all of the source files to be run through the search processing
RECURSE (Yes/No): Whether or not the directory should be recursed (i.e. is it flat?)
SEARCH PAGE: The page in which the XHTML5 search input should be injected
+++


### TASK: `validateConfigFile`

Description: This validates the config file to ensure that the config is syntatically valid, which means:

* The configuration file is well-formed XML
* The configuration file is valid against the RNG schema
* The configuration file is valid against the Schematron schema

(Note: I would like to be able to validate the XPath expressions, but I'm not sure if that's possible.)

Note that this DOES NOT check whether or not the files exist. That happens in the next build. 

### TASK: `rationalizeConfig`

Description: This task converts a minimal config into a rationalized form of the configuration file, such that all of the default options
are added to the configuration if they haven't been overridden by the basic config).

#### STEPS:

1. Run config against <xmlvalidate> to ensure it's properly formed
1. Run config against the RNG using Jing
1. Run config against the Schematron


### TASK: `makeConfigAnt`

Description: This task creates the properties and filesets to be passed to the rest of the processes. 

### TASK: `makeConfigXslt`

Description: This task creates the small set of XSLT templates necessary for running the documents through the tokenization process

## FILE: buildSearch.xml

This build does the full search engine creation

### TASK: checkProps

This target checks all of the properties--files, configurations, et cetera--and makes sure everything is available.

Check each property that we expect (baseDir, collectionDir, stopwordsFile) is available using the <available> task.

### TASK: checkCollection

This target check the collection XHTML and first validates to ensure they are proper XML and then runs the process through a diagnostics
suite that outlines if there are any problems or things that can be fixed up in the document collection.

#### STEPS:

1. Run the collection fileset against the <xmlvalidate> to ensure that they are well-formed
1. Take the collection fileset and run against the XHTML Static Search diagnostics suite to 
flag any potential problems, et cetera. DECISION: Should this return a formatted report or should it
just report messages to sdout and bail on any egregious errors?

### TASK: tokenize

This target preprocesses the document collection using XSLT. The preprocessing XSLT does the following things:
    1. Deletes all body//* that have been marked as inlines or elements to delete, which are thus not necessary for the tokenization process. It also adds a number of attributes
to the documents (@data-staticSearch-weight, @data-staticSearch-context) and cleans up some strings that might end up being problematic in the final search output
    1. It then takes those results and transforms them such that all "word tokens" are turned into custom elements called `<span data-staticSearch-token="true">` elements in preparation for the stemming step.

### Task: stem

This target takes the collection of documents with `<span data-staticSearch-token="true">` and adds the stemmed equivalent as another attribute. It runs it through the specific stemming process declared by the `$stemmerFile` and `$stemmerTemplateName | $stemmerFunctionName`. These templates/functions must always take in a single input string and return an output string.


### Task: json

This target takes the stemmed tokens from the previous step and converts them into JSON documents

### Task: report

This creates the final output search report, which gives statistics and other helpful bits of information
(like number of tokenizes strings, et cetera). We should probably make the output placement of this file configurable.



