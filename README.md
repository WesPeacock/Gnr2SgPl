# General to Singular/Plural Crossreference Convert
### Introduction

This repo contains scripts to convert Cross References from General Entry Level Collections to Unidirectional Singular/Plural pairs.

The Daasanach import process (mistakenly) imported Singular/Plural cross references as "General" Entry/Sense Pairs (type 11). They should be pairs of Unidirectional cross references (type 16) where the "Plural" points from the singular to the plural and the "Singular" cross reference is from the plural to singular.

#### About this Document

This document is written in Markdown format. It's hosted on *github.com*. The github site that it's hosted on will display it in a formatted version.

If you're looking at it another way and you're seeing unformatted text, there are good Markdown editors available for a Windows and Linux. An free on-line editor is available at https://stackedit.io/ 

This README was copied from the ExampleNumbers README and may not have all the extraneous details corrected.

### Preparation

#### Infrastructure

The scripts in this repo require Linux **bash** and a properly configured **perl** system. These requirements are fulfilled if you follow the instructions here: [**Set up a Linux terminal**](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/b-set-up-a-linux-terminal).  Those instructions tell you how to set up a **WSL** terminal on Windows 10. That page also tells you how to navigate Windows directories from within **WSL**. (**WSL** is the **W**indows **S**ubsystem for **L**inux)

The instructions are part of the SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site.

#### Prepare the database

The FLEx database needs to have the pertinent General, Plural and Singular cross reference types defined. Do a project backup and copy that to the working directory.

#### Prepare to run the scripts

Create or choose a working directory. It should be empty.

Instructions for how to download files from *github* are available from SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site, at: [How to download Perl scripts from GitHub](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/c-how-to-download-perl-scripts-from-github).

***
This section needs Corrections:

- filenames converted.
- documentation of *LIFT* file creation and moving to the working directory.
  - documentation of getting the Number field name from the *LIFT* file.

Download the following following scripts and files from this repository on *github*:

* **NumberExamples.ini**
* **NumberExamples.pl**
* **NumberExamples.sh**
* **README.md**

Move the downloaded files into the working directory.

If you used the something other than *Example Number*  for the custom *Example Number*, edit the **NumberExamples.ini** file and change the following line:

​		NumberFieldname=Example Number

Put the name you used on the right hand side of the equals sign. Don't put any spaces before or after the name.

Navigate to the working directory within **WSL**.

In **WSL**, type:
	**dos2unix** **\***
This converts the script and control file line endings.

Copy the *.fwbackup* file from the location you noted when you created it, into the working directory.

In **WSL**, type:

​	**./NumberExamples.sh** 

That script will extract the *.fwdata* file from the backup. It then funs the **NumberExamples.pl** script to number the examples in the custom field

You can run FLEx and restore the project from the backup to verify that the Examples are numbered.

### Issues

Probably.






***

This repository was initialized with scripts from the NumberExample repo.
