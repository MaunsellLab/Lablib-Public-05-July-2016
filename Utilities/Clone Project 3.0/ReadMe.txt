
clone project folder


This folder contains clone project (version 0.71 Tiger compatible).  The only files installed are those listed below.


clone project  -- Applescript Application file to duplicate and rename project folder

ProgBar        -- ProgBar - 0.2 display progress bar for user feedback when AppleScript is running 
                  http://www.versiontracker.com/dyn/moreinfo/macosx/24347
                  http://spork.tjmahaffey.com/spork/index.php?cont_incl=ProgBar.php

ReadMe.txt     -- this file


You may place this folder anywhere. The /Applications folder is recommended.

This Applescript will take any standard XCode project (tested on versions 1.5 (OSX 10.3.9) and 2.0 (OS X 10.4.1) and produce an exact copy but with a new name for the project and different prefix for the names of the source code files.  It assumes that the original project 
has a source code file names with a consistent legal prefix.  Certain prefixes are not allowed due to the fact that they create 
ambiguity in the code for the search and replace routines (eg. prefix LL which is used for LabLib frameworks or NS which is used by Cocoa).  The reserved prefixes are {"NS", "NSS", "VBL", "VBLC", "LL", "CC", "GG", "PB", "PBX", "PBXF", "PBXV", "PBXB", "IT", "ITC", "BO", "BOO", "BOOL"}.  If your original project uses one of these prefixes, it is not clonable and clone project will abort. Clone project will ask for an alternate prefix if you choose one of the reserved prefixes.  A prefix can be of any length of two or more characters in the alphabet. Numbers are not allowed.  prefixes longer than 5 characters are not recommended. 

While this program can clone any project, it was created with the idea of cloning LabLib plugin projects as it's primary use. This is what it was tested on and there is no guarantees implied or otherwise that it will work on any other type of project though it should do so.  To enable the new project to recognize automatically all changes, it was necessary to alter the project's package file using shell scripts. It is possible that future versions of Xcode could break these shell scripts.  
