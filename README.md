# Example Numbering
### Introduction

This repo contains scripts to number the examples within a sense in a FLEx Lexical database.

FLEx keeps the example sentences as an ordered list under the sense in which they occur. You can re-order the list by moving the examples up and down within the sense, but it doesn't keep track of the numbering of the examples in the list. These scripts allow you to assign numbers to the examples based on their order within the list in which they occur.

#### About this Document

This document is written in Markdown format. It's hosted on *github.com*. The github site that it's hosted on will display it in a formatted version.

If you're looking at it another way and you're seeing unformatted text, there are good Markdown editors available for a Windows and Linux. An free on-line editor is available at https://stackedit.io/ 

### Preparation

#### Infrastructure

The scripts in this repo require Linux **bash** and a properly configured **perl** system. These requirements are fulfilled if you follow the instructions here: [**Set up a Linux terminal**](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/b-set-up-a-linux-terminal).  Those instructions tell you how to set up a **WSL** terminal on Windows 10. That page also tells you how to navigate Windows directories from within **WSL**. (**WSL** is the **W**indows **S**ubsystem for **L**inux)

The instructions are part of the SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site.

#### Prepare the database

The FLEx database needs to have a custom field to hold the example number.

* Choose the **Lexicon** function
* In the menu choose **Tools|Configure|Custom Fields** to open the Custom Fields dialogue box.
* Select the **Add** button and enter the following information:
  * Choose a name for the *Example Number* field.
    * If you choose "*Example Number*", the scripts will automatically find it.
    * If you choose a name other than *Example Number*, note the name you have used.
  * On the **Location** drop-down Menu choose *Example*.
  * In the **Description** enter a meaningful description. This field is ignored by the scripts.
  * On the **Type** drop-down Menu choose *Number*.
  * Click **OK**.
* Each Example sentence will have a new field with the name *Example Number*, or whatever other name you chose above. Each one will be initially given the number 0. The scripts will change this number.
* The scripts that assign example numbers, normally run on a Project Backup. So, create one:
  * In the menu choose **File|Project Management|Backup this Project...**
  * The **Comment** line will be included in the backup file name.
  * Note the directory you choose to save the backup in. You will later copy the *.fwbackup* file from there into another working directory.
* Exit the FLEx program.

#### Prepare to run the scripts

Create or choose a working directory. It should be empty.

Instructions for how to download files from *github* are available from SIL Dictionary and Lexical Services **Importing SFM to FLEx: Best Practices** site, at: [How to download Perl scripts from GitHub](https://sites.google.com/sil.org/importing-sfm-to-flex/workflow/i-set-up-infrastructure/c-how-to-download-perl-scripts-from-github).

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

#### Backup and Send/Receive

This process assumes that the database is in a FLEx backup or a zip file. If your database is being used with Send/Receive, then you need special care using backup.

#### Special characters in the Example Number field name

FLEx prohibits punctuation in the name of the *Example Number* Custom field. It will not accept *Numéro d'exemple* because of the apostrophe.

However, the **perl ** script may also have problems with *Numéro de exemple,* (i.e., with no apostrophe). The accented e, *é* in *Numéro* can be legally represented in Unicode in two different (NFC and NFD). FLEx keeps proper track internally, but the name in the *.ini* file must be the same as what's in the FLEx *.fwdata* file that's in the compressed *.fwbackup* file.

In cases where there's no ambiguity e.g. *Aklatɔ Asʋ́n* (*ʋ́* has no Unicode NFC representation) the scripts seem to handle it well.

#### The Numbering is not permanent

FLEx doesn't know about the Example Numberin, so If you re-order or delete or create examples, the Numbers will no longer be in order. You can re-run the script.






***

This repository was initialized with Var2Form scripts the Subentry Promotion repo as a template for processing a .fwdata file within a FLEx backup/zip file.

The scripts were originally written and tested with Nkonya language test database, but there's nothing special about that database with regards to this process.