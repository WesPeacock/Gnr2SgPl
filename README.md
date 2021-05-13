# General to Singular/Plural Crossreference Convert
### Introduction

This repo contains scripts to convert Cross References from General Entry Level Collections to Unidirectional Singular/Plural pairs.

The Daasanach import process (mistakenly) imported Singular/Plural cross references as "General" Entry/Sense Pairs (type 11). They should be pairs of Unidirectional cross references (type 16) where the "Plural" points from the singular to the plural and the "Singular" cross reference is from the plural to singular.

Correcting these entries is done in two steps. In the first, the General cross references that are candidates for change are listed as a an XML file. After the XML file is reviewed, and false positives have been flagged, a second process reads the XML file and corrects the cross references.

#### About this Document

This document is written in Markdown format. It's hosted on *github.com*. The github site that it's hosted on will display it in a formatted version.

If you're looking at it another way and you're seeing unformatted text, there are good Markdown editors available for a Windows and Linux. An free on-line editor is available at https://stackedit.io/ 

This README was copied from the ExampleNumbers README and may not have all the extraneous details corrected.

### Preparation

#### Infrastructure

The scripts in this repo require Linux **bash** and a properly configured **perl** system. These requirements are fulfilled if you follow the instructions here: [**Set up a Linux terminal**](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/b-set-up-a-linux-terminal).  Those instructions tell you how to set up a **WSL** terminal on Windows 10. That page also tells you how to navigate Windows directories from within **WSL**. (**WSL** is the **W**indows **S**ubsystem for **L**inux)

The instructions are part of the SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site.

Create or choose a working directory. It should be empty.

#### Prepare the database

The FLEx database needs to have the pertinent *General*, *Plural* and *Singular* cross reference types defined. Do a project backup and copy it to the working directory. Using a **Zip** archiver, extract the .**fwdata** file from the backup.

Using the FLEx filtering facilities, select all the entries that have a *General* cross reference and are *Singular* or *Plural* nouns. Export those using *File|Filtered Lexicon|LIFT*. Copy the LIFT file into the working directory.

#### Prepare to run the scripts

Instructions for how to download files from *github* are available from SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site, at: [How to download Perl scripts from GitHub](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/c-how-to-download-perl-scripts-from-github).

Download the following following scripts and files from [this repository](https://github.com/WesPeacock/Gnr2SgPl) on *github*:

* **GnrSgPl.ini**
* **GnrSgPl.pl**
* **GnrSgPl.sh** --ignore for now
* **FixSgPl.pl**
* **FixSgPl.sh** --ignore for now
* **README.md**

Move the downloaded files into the working directory.

Edit the **GnrSgPl.ini** file and choose values for the following lines:

```ini
PluralRelationName=Plural
SingularRelationName=Singular
GeneralRelationName=General
SgPlFieldName=Valency
LiftFile=lift.lift
LogFile=Gnr2SgPl.log
```
Names of the items are on the right hand side of the equals sign. Don't put any spaces before or after the name.

Note that the names of the fields in FLEx are not necessarily what is displayed by FLEx. When a field is created and later renamed, it maintains its original name. The new name is stored in an attribute called the *label*. For example, the Daasanach field currently named **Number** was created as **Valency**. Here's how that information is stored in the FWdata file:

```xml
<CustomField class="LexEntry" helpString="This field gives the entry number i.e. sg/pl" label="Number" name="Valency" type="String" wsSelector="-1" />
```

The original name is used in the LIFT file as well and can be retrieved from it.

As in the example above, you have to use the original name, not the current label.

#### Run the scripts

Navigate to the working directory within **WSL**.

There should be a copy the *.fwbackup* file from the location you noted when you created it, in the working directory.

In **WSL**, type:
	**dos2unix** **\***
This converts the script and control file line endings.

In **WSL**, type:

​	**./Gnr2SgPl.pl** 

That script produces a log file with a list of all the entries that would be changed by running **FixSgPl.pl**. The user should edit the log file and flag entries that shouldn't be changed.

The log file entries are XML entries, each starting with a *\<pair* tag. You can change the tag to get the **FixSgPl.pl** script to ignore an entry.

Run the script first with the *simple* option, Fix those and then run again on all the remaining options.

##### Options for Gnr2SgPl.pl & FixSgPl.pl perl scripts

* *\-\-simple* **Gnr2SgPl.pl** only. Select only cross-refs where there's only one cross-ref for the record.
* *\-\-debug* Just process a few records.
* *\-\-checkini* Just check the ini file and stop.
* *--gnrdmp*  For debugging. Display the raw record containing a list of all the General cross-refs.
*  *\-\-sgpldmp* For debugging. Display the raw records containing a list of all the Singular \& Plural cross-refs.

#### Run FLEx to check your results

You can run FLEx and restore the project from the backup to verify that the Examples are numbered.

### Issues

The shell scripts are not working well. You can copy the **fwdata** file to the working directory and run the perl scripts on it there.


***

This repository was initialized with scripts from the NumberExample repo.